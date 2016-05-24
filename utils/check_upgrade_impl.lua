--./utils/check_upgrade_impl.lua

local function md5_file_path( md5, url )
    local ext = get_extension( url )
    local dir = string.sub( md5, 1, 2 )
    return dir, dir .. '/' .. string.sub( md5, 3 ) .. ( ext and '.' .. ext or '' )
end

-- 
--[[
check_info = {
    failed_cb = function() end,                                                         -- 更新失败回调
    update_cb = function( downloaded_size, total_size ) end,                            -- 更新下载进度回调
    prepare_cb = function( downloaded_size, total_size, real_download_cb ) end,         -- 准备开始更新下载回调
    big_upgrade_cb = function() end,                                                    -- 大版本更新回调
}
--]]
local __check_upgrade = class( 'check_upgrade' )
function __check_upgrade:ctor( check_info )
    local temp = getIncrementalFileSuffix()
    if getPlatform() == 'ios' and temp == 'hm' then
        temp = 'hmios'
    end

    self.file_list_url = string.format( '%s%d_%s.list', GameSettings.upgrade_url, game_version, temp )
    self.check_info = check_info or {}
end

function __check_upgrade:checkUpgrade()
    -- 先初始化路径
    if not self:initExternalPath() then return self:upgradeFailedCallback( '请插入 SD 卡后，再点击屏幕重试！' ) end
    -- 获取文件列表
    self:getUpgradeFileList()
end

-- 更新失败回调
function __check_upgrade:upgradeFailedCallback( reason )
    self.check_info.failed_cb( reason )
end

-- 更新完成回调
-- 'no_need_to_update', 'update_complete'
function __check_upgrade:upgradeCompleteCallback( complete_type, check_upgrade_response )
    -- 如果是更新完成的话，，然后写 file list
    if complete_type == 'update_complete' then
        -- 先更新进度条
        self:updateProgressCallback()

        -- 写 file list
        local file_data = {
            pkg_version = getPackageVersion(),
            version = check_upgrade_response.versionId,
            version_name = check_upgrade_response.versionName,
            config_version = check_upgrade_response.config_version,
            files = {},
        }

        -- 
        local delta = {}
        local old_file_list = load_file_list()
        for _,file_info in ipairs( old_file_list.files ) do
            if file_info.size > 0 then
                delta[file_info.url] = file_info
            else
                delta[file_info.url] = nil
            end
        end

        for _,file_info in ipairs( check_upgrade_response.files ) do
            if file_info.size > 0 then
                delta[file_info.url] = { url = file_info.url, md5 = file_info.md5, size = file_info.size, where = 'INTERNAL', }
            else
                delta[file_info.url] = nil
            end
        end

        for _,file_info in pairs( delta ) do
            table.insert( file_data.files, file_info )
        end

        write_file_list( file_data )

        game_version = check_upgrade_response.versionId
        game_version_name = check_upgrade_response.versionName
    end

    -- 
    self.check_info.complete_cb( complete_type )
end

-- 更新进度回调
function __check_upgrade:updateProgressCallback()
    self.check_info.update_cb( self.downloaded_size, self.total_size )
end

-- 准备下载回调
function __check_upgrade:prepareDownloadCallback( call_back_func )
    -- 更新一下进度条，然后准备开始下载
    self:updateProgressCallback()
    -- 如果确定要下载的话，就直接调用 call_back_func 开始下载
    self.check_info.prepare_cb( self.downloaded_size, self.total_size, call_back_func )
end

function __check_upgrade:getUpgradeFileList()
    CCLuaLog( 'self.file_list_url : ' .. tostring( self.file_list_url ) )
    TLHttpClient:sharedHttpClient():requestFile( self.file_list_url, '', function( content_data, http_code, error_code, error_msg )
        if http_code ~= 200 then return self:upgradeFailedCallback( '更新失败，请重试！' ) end
        local check_upgrade_response = protobuf.decode( 'poem.CheckUpgradeResponse', content_data, #content_data )
        -- 更新失败
        if not check_upgrade_response then return self:upgradeFailedCallback( '更新失败，请重试！' ) end
        -- 大版本更新
        if check_upgrade_response.isbigupgrade then return self.check_info.big_upgrade_cb() end
        -- 需要更新

        -- 远程版本号低于本地版本号，更新失败
        --if check_upgrade_response.versionId < game_version then return self:upgradeFailedCallback( '更新失败，请重试！' ) end

        -- 服务器版本号, 服务器版本号和本地版本号不匹配
        if check_upgrade_response.versionId and check_upgrade_response.versionId ~= game_version then
            -- IOS 下载过程中设置为非 idle 避免下载过程中锁定导致下载中断
            if getPlatform() == 'ios' and idleTimerDisabled ~= nil then CCLuaLog( 'idleTimerDisabled : ' .. tostring( idleTimerDisabled( true ) ) ) end
            -- 没有需要更新的文件列表
            if not check_upgrade_response.files then return self:upgradeCompleteCallback( 'no_need_to_update' ) end
            -- 开始更新
            self:startDownload( check_upgrade_response )
        else
            self:upgradeCompleteCallback( 'no_need_to_update' )
        end
    end)
end

function __check_upgrade:initExternalPath()
    local storage = SystemConfig.getStorage()
    if storage == 'system' then return true end
    if storage == 'sdcard' then
        local sdcard = getSDCardPath()
        if sdcard~='' then
            lfs.mkdir(sdcard)
            return true
        else
            CCLuaLog('storage:'..storage)
            return false
        end
    else
        -- 确定使用sd卡还是系统内存，第一次确定后不再修改
        local sdcard = getSDCardPath()

        local assetsManager = AssetsManager:sharedAssetsManager()

        if sdcard~='' then
            lfs.mkdir(sdcard)
            SystemConfig.setStorage('sdcard')
            if assetsManager.setExternalType then
                assetsManager:setExternalType(EXTERNAL_SDCARD)
            end
        else
            SystemConfig.setStorage('system')
            if assetsManager.setExternalType then
                assetsManager:setExternalType(EXTERNAL_SYSTEM)
            end
        end
        SystemConfig.flush()
        return true
    end
end

-- 计算出总的大小和真正需要下载的大小
function __check_upgrade:startDownload( check_upgrade_response )
    local external_path = get_external_path()

    self.total_size = 0         -- 总的大小
    self.downloaded_size = 0    -- 已经下载的大小
    local need_count = 0        -- 需要下载的文件的数量

    local download_list = {}
    for i,file_info in ipairs( check_upgrade_response.files ) do
        if file_info.size > 0 then
            self.total_size = self.total_size + file_info.size

            -- 先看看包里面是否有这个文件，再看看包外面是否有这个文件
            local dir, path = md5_file_path( file_info.md5, file_info.url )
            if CCFileUtils:sharedFileUtils():checkFileExists( path, file_info.size ) or CCFileUtils:sharedFileUtils():checkFileExists( external_path .. path, file_info.size ) then
                self.downloaded_size = self.downloaded_size + file_info.size
            else
                -- 如果包里面和包外面都没有的话，就下载吧
                need_count = need_count + 1

                file_info.dir = external_path .. dir
                file_info.path = path

                table.insert( download_list, file_info )
            end
        end
    end

    -- 没有需要下载的文件
    if #download_list == 0 then return self:upgradeCompleteCallback( 'update_complete', check_upgrade_response ) end

    -- 准备开始下载
    local failed_count = 0      -- 更新失败的文件数量
    local download_count = 0    -- 已经下载的文件数量
    self:prepareDownloadCallback( function()
        local cur_index = 10
        local __request_file = nil
        __request_file = function( index )
            local file_info = download_list[index]
            if not file_info then return end

            lfs.mkdir( file_info.dir )

            local download_url = GameSettings.upgrade_url .. file_info.path
            local save_to = external_path .. file_info.path
            TLHttpClient:sharedHttpClient():requestFile( download_url, save_to, function( content_data, http_code, error_code, error_msg )
                -- 写入的大小不正确
                if http_code ~= 200 or not CCFileUtils:sharedFileUtils():checkFileExists( save_to, file_info.size ) then failed_count = failed_count + 1 end

                -- 下载的文件数量
                download_count = download_count + 1
                self.downloaded_size = self.downloaded_size + file_info.size

                -- 更新进度条
                self:updateProgressCallback()

                -- 更新完成
                if download_count == need_count then
                    if failed_count > 0 then
                        self:upgradeFailedCallback( string.format( '有 %d 个文件更新失败，请重试！', failed_count ) )
                    else
                        self:upgradeCompleteCallback( 'update_complete', check_upgrade_response )
                    end
                end

                -- 請求下一個文件
                cur_index = cur_index + 1
                __request_file( cur_index )
            end)
        end

        -- 最多并行下载十个文件
        for i = 1,10 do __request_file( i ) end
    end)
end

return __check_upgrade
