-- ./launch/device_base.lua
require 'utils.class'
require 'utils.protobuf'
require 'utils.shaders'
require 'utils.common'
require 'utils.richMark'
require 'config.push_notification_config'

local __device_base = class( 'device_base' )
function __device_base:ctor()
    self.logo_list = {}
    self.affair_list = {
        function()  -- 初始化 shader
            require 'utils.shaders'
            initCustomShaders()
        end,
        function()  -- 初始化富文本
            require 'utils.richMark'
            TLFontTex:setFontOriginSize( GameSettings.font_size )
            TLFontTex:setFontName( ( getPlatform() == 'android' or getPlatform() == 'win32' ) and GameSettings.font_name_android or GameSettings.font_name )
            --TLFontTex:setEdgeSize( GameSettings.edge_size )
            TLFontTex:setParseRichTextHandler( parseRichTextMark )

            TLFontTex:sharedTLFontTex():initFontTexture( GameSettings.color_tex_file, GameSettings.color_tex_row, GameSettings.color_tex_col, GameSettings.color_shader )
        end,
    }

    signal.listen( 'SYSTEM_ENTER_BACKGROUND', function()
        self:remove_all_notification()
        self:push_notification('push1')
        self:push_notification('push2')
        self:push_notification('push3')
        self:push_notification('push4')
    end)
    signal.listen( 'SYSTEM_ENTER_FOREGROUND', function()
        self:remove_all_notification()
    end)
end

function __device_base:push_notification(index)
    local push_config = {
        ['push1'] = function() 
            local push1_isUnAvailable = SystemConfig.getPushNotification1()
            local push1 = all_push_notification_list['push1']

            if not push1_isUnAvailable then
                for i, pushinfo in ipairs(push1.noti_list or {}) do
                    createLocalNotification(tostring('0'),tostring(pushinfo.hour),tostring(pushinfo.miniutes),tostring(pushinfo.second),tostring(pushinfo.content),tostring(pushinfo.key),tostring(pushinfo.type))
                end
            else
                for i, pushinfo in ipairs(push1.noti_list or {}) do
                    releaseLocalNotification(tostring(pushinfo.key))
                end
            end
        end,
        ['push2'] = function()
            local push2_isUnAvailable = SystemConfig.getPushNotification2()
            local push2 = all_push_notification_list['push2']

            if not push2_isUnAvailable then
                for i, pushinfo in ipairs(push2.noti_list or {}) do
                    createLocalNotification(tostring('0'),tostring(pushinfo.hour),tostring(pushinfo.miniutes),tostring(pushinfo.second),tostring(pushinfo.content),tostring(pushinfo.key),tostring(pushinfo.type))
                end
            else
                for i, pushinfo in ipairs(push2.noti_list or {}) do
                    releaseLocalNotification(tostring(pushinfo.key)) 
                end
            end
        end,
        ['push3'] = function() 
            if g_player and g_player.loterry_hero_rest_free_count_C and g_cdtimes.loterry_hero_cd_C then
                if g_player.loterry_hero_rest_free_count_C <= 0 then
                elseif g_cdtimes.loterry_hero_cd_C <= 0 then
                else
                    local current_time = os.time()
                    local free_time = {}
                    free_time.hour, free_time.min, free_time.sec = getHourMinSecondByOSTime(g_cdtimes.loterry_hero_cd_C+current_time)
                    free_time.day = os.date("%d",current_time+g_cdtimes.loterry_hero_cd_C)-os.date("%d",current_time)

                    local push3 = all_push_notification_list['push3']
                    local push3_isUnAvailable = SystemConfig.getPushNotification3() 

                    if not push3_isUnAvailable then
                        for i, pushinfo in ipairs(push3.noti_list or {}) do
                            createLocalNotification(tostring(free_time.day),tostring(free_time.hour),tostring(free_time.min),tostring(free_time.sec),tostring(pushinfo.content),tostring(pushinfo.key),tostring(pushinfo.type))
                        end
                    else
                        for i, pushinfo in ipairs(push3.noti_list or {}) do
                            releaseLocalNotification(tostring(pushinfo.key)) 
                        end
                    end
                end
            end
        end,
        ['push4'] = function() 
            if g_player and g_player.spmax and g_player.sp then
                local sp_poor = g_player.spmax - g_player.sp 
                -- 当体力未满时
                if sp_poor > 0 then
                    local cdtime = g_cdtimes[ 'resume_sp_cd' ]
                    local delay_time = ( sp_poor - 1 ) * 6 * 60 + cdtime

                    local current_time = os.time()
                    local free_time = {}
                    free_time.hour, free_time.min, free_time.sec = getHourMinSecondByOSTime(current_time+delay_time)
                    free_time.day = os.date("%d",current_time+delay_time)-os.date("%d",current_time)

                    local push4 = all_push_notification_list['push4']
                    local push4_isUnAvailable = SystemConfig.getPushNotification4() 
                    if not push4_isUnAvailable then
                        for i, pushinfo in ipairs(push4.noti_list or {}) do
                            createLocalNotification(tostring('0'),tostring(free_time.hour),tostring(free_time.min),tostring(free_time.sec),tostring(pushinfo.content),tostring(pushinfo.key),tostring(pushinfo.type))
                        end
                    else
                        for i, pushinfo in ipairs(push4.noti_list or {}) do
                            releaseLocalNotification(tostring(pushinfo.key)) 
                        end
                    end
                end
            end
        end,
    }

    if push_config[index] then
        push_config[index]()
    end
end

function __device_base:remove_all_notification()
    releaseAllLocalNotification()
end

function __device_base:doQuit() end

function __device_base:init()
    -- 文件的搜索路径
    self:setSearchPath()

    -- 根据不同的设备设置分辨率
    local width, height, policy, scale = self:getDesignSize()
    CCEGLView:sharedOpenGLView():setDesignResolutionSize( width, height, policy or kResolutionShowAll );

    -- 创建 movie clip 的方法
    createMovieClipWithName = self:getMovieClipCreateFunc()

    -- 这里的 sdk type 使用包真实的 sdk type
    setProjectNickname( GetSdkTypeLua() .. '_' .. GameSettings.nickname )

    -- 
    local winSize = CCDirector:sharedDirector():getWinSize()
    --CCDirector:sharedDirector():setDisplayStats( true )

    -- 
    MCLoader:sharedMCLoader():loadIndexFile( 'mc/anim.index', 'mc/frames.index' )

    protobuf.register( getFileData( 'config/poem.pb' ) )
    protobuf.register( getFileData( 'config/config.pb' ) )

    -- 初始化自定义的 shader	
    --initCustomShaders()  -- init in async

    TLHttpClient:sharedHttpClient():setDefaultURL( GameSettings.HTTP_URL )

    -- 根节点
    self.root_scene_node = TLRunningScene:create()

    --self:initSceneLayers()

	-- 声音
    set_music_volume( SystemConfig.getBGVolume() )
	set_effect_volume( SystemConfig.getEffectVolume() )
	set_music_mute( SystemConfig.getBGMusic() )
	set_effect_mute( SystemConfig.getSoundEffect() )
	set_music_mute( true )
	set_effect_mute( true )

    if SystemConfig.getWakeLock() then CCLuaLog( 'wake_lock : acquireWakeLock' ) acquireWakeLock() end

    -- 屏幕点击并拖动的光效
    local scene_par_handle, scene_par_node = nil, nil
    local scene_par_o_x, scene_par_o_y = 0, 0
    TLWindowManager:SharedTLWindowManager():setTouchBeganHandler( function( x, y )
        require 'utils.effect'

        -- 如果出现意外情况的话，就在这里停掉
        if scene_par_node then scene_par_node:stopInfiniteLoop() end

        -- 
        -- local seInfo = { resourceId = 'particle/ui_dianji', loop = -1, scaleX = 1, scaleY = 1, schedule_type = 'PAUSE' }
        -- scene_par_o_x, scene_par_o_y = x, y
        -- scene_par_handle, scene_par_node = playEffect_SE( seInfo, { x = x, y = y }, self.root_scene_node, 1, 1, function() end )
    end)

    TLWindowManager:SharedTLWindowManager():setTouchMovedHandler( function( x, y )
        local offset_x, offset_y = x - scene_par_o_x, y - scene_par_o_y
        if scene_par_node then scene_par_node:SetPosition( offset_x, offset_y ) end
    end)

    TLWindowManager:SharedTLWindowManager():setTouchEndedHandler( function( x, y )
        if scene_par_node then scene_par_node:stopInfiniteLoop() end
        scene_par_handle = nil
        scene_par_node = nil
    end)

    -- 我把这个功能移到了 TLWindow 里面了
    -- 也就是说，每一个 input text 都可以有不一样的 check input text 的实现
    -- 而不是现在这样，大家共用同一个
    --TLWindowManager:SharedTLWindowManager():setCheckInputTextHandler( function( text )
    --    require 'config.ignore_char'
    --    if table.hasValue( all_ignore_char, text ) then return true end
    --    return false
    --end)

    -- set lua collect pace
    collectgarbage( 'setpause', 100 )
    collectgarbage( 'setstepmul', 5000 )

    -- 
    self.root_scene_node:setScale( scale )
    CCDirector:sharedDirector():runWithScene( self.root_scene_node )
end

function __device_base:playCGMp4()
    --if SystemConfig.getCGPlay() then
    --    SystemConfig.setCGPlay( false )

    --    local real_path = AssetsManager:sharedAssetsManager():getRealPath( 'music/cg.mp4' )
    --    local full_path = CCFileUtils:sharedFileUtils():fullPathForFilename( real_path );
    --    playMedia( full_path )
    --end
end

function __device_base:run()
    self:initSceneLayers()

    require 'login.boot'
    openBootWin( true )
end


-- 
layer_type_ui                   = 1
layer_type_fight_ui             = 2
layer_type_mask                 = 3
layer_type_system               = 4
layer_type_top                  = 5
all_scene_layers = all_scene_layers or { }
function __device_base:initSceneLayers()
    local c_x, c_y = self:getCenterPos()

    all_scene_layers[layer_type_ui] = TLWindowManager:SharedTLWindowManager()
    all_scene_layers[layer_type_ui]:setPosition( c_x, c_y )
    self.root_scene_node:addChild( all_scene_layers[layer_type_ui] )

    all_scene_layers[layer_type_fight_ui] = CCLayer:create()
    all_scene_layers[layer_type_fight_ui]:setPosition( c_x, c_y )
    self.root_scene_node:addChild( all_scene_layers[layer_type_fight_ui] )

    all_scene_layers[layer_type_mask] = TLMaskLayer:sharedTLMaskLayer()
    all_scene_layers[layer_type_mask]:setPosition( c_x, c_y )
    self.root_scene_node:addChild( all_scene_layers[layer_type_mask] )

    all_scene_layers[layer_type_system] = CCLayer:create()
    all_scene_layers[layer_type_system]:setPosition( c_x, c_y )
    self.root_scene_node:addChild( all_scene_layers[layer_type_system] )

    all_scene_layers[layer_type_top] = CCLayer:create()
    all_scene_layers[layer_type_top]:setPosition( c_x, c_y )
    self.root_scene_node:addChild( all_scene_layers[layer_type_top] )

    self.root_scene_node:scheduleUpdateWithPriorityLua( function( dt )
        if g_cur_time then
            local speed = CCDirector:sharedDirector():getSpeed()
            g_cur_time = g_cur_time + dt / speed
        end
    end, 0)
end

function __device_base:getCenterPos()
    local winSize = CCDirector:sharedDirector():getWinSize()
    return winSize.width / 2, winSize.height / 2
end

function __device_base:setSearchPath()
    AssetsManager:sharedAssetsManager():addSearchPath( '' )
    AssetsManager:sharedAssetsManager():addSearchPath( 'images/' )
    AssetsManager:sharedAssetsManager():addSearchPath( 'images/word/' )
    AssetsManager:sharedAssetsManager():addSearchPath( 'images/icon/' )
    AssetsManager:sharedAssetsManager():addSearchPath( 'images/body/' )
    AssetsManager:sharedAssetsManager():addSearchPath( 'images/giftbag/' )
    AssetsManager:sharedAssetsManager():addSearchPath( 'particles/textures/' )
    AssetsManager:sharedAssetsManager():addSearchPath( 'mc/' )
end

function __device_base:getDesignSize()
    local d_width, d_height = 1136, 760

    local frame_size = CCEGLView:sharedOpenGLView():getFrameSize()

    local scale_width = frame_size.width / d_width
    local scale_height = frame_size.height / d_height
    if scale_width < scale_height then scale_width = scale_height end

    -- 在这里，不对高宽进行拉伸
    return frame_size.width, frame_size.height, kResolutionShowAll, scale_width
end

function __device_base:getMovieClipCreateFunc()
    return function( mcName, async ) return MovieClip:createWithName( mcName, async ) end
end

function __device_base:initBootCheckList( boot_check_name )
    local file_list = load_file_list()

    for _,file_info in ipairs( file_list.files or {} ) do
        if string.find( file_info.url, 'login/boot_check' ) and get_extension( file_info.url ) == 'lua' then
            local require_file_name = string.gsub( strip_extension( file_info.url ), '/', '.' )
            table.insert( boot_check_name, require_file_name )
        end
    end
end

-- 获得设备的信息
function __device_base:getDeviceInfo()
    return {
        os = getPlatform(),
        osVersion = getOSVersion(),
        resolution = getResolution(),
        IMEI = getIMEI(), --android  level2
        UDID = getUUID(), 
        MAC = getMAC(),   --android  level1
        UA = getUA(),
        clientVersion = tostring(game_version),
		idfa = getidfa(), --ios
		deviceUniqueID = g_device_obj:getUniqueDeviceID(),
        appid = tostring(getMetaData('reyun_appid') or ''),
    }
end

function __device_base:getUniqueDeviceID()
end

function __device_base:requireSDK()
    local sdk_login_file = string.format( 'login.sdk_login_%s', GetSdkTypeLua() )
    package.loaded[sdk_login_file] = nil
    local err, tbl = xpcall( function() return require( sdk_login_file ) end, function() end )
    if err then return tbl end

    -- require default one for platform
    sdk_login_file = string.format( 'login.sdk_login_%s', getPlatform() )
    package.loaded[sdk_login_file] = nil
    return require( sdk_login_file )
end

function __device_base:listenYaoYiYao( yyy_func )
end

function __device_base:unlistenYaoYiYao()
end

return __device_base
