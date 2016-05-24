require 'config.GameSettings'
require 'config.game_label'
require 'utils.CCGeometryExtend'
require 'utils.common'
require 'utils.userconfig'

-- 默认的，创建 movie clip 的方法
function createMovieClipWithName( mcName, async ) return MovieClip:createWithName( mcName, async ) end

g_device_obj = require( string.format( 'launch.device_%s', getPlatform() ) ).new()

function main()
    math.randomseed( os.time() )

    g_device_obj:init()

    -- show logo & init rich/shader
    require 'launch.show_logo'
    showLogoAndAsyncAffairList( function()
        -- test demo
        local test_path = CCFileUtils:sharedFileUtils():fullPathForFilename( 'script/test.lua' )
        if CCFileUtils:sharedFileUtils():isFileExist( test_path ) then
            require "script.test"
            CCLuaLog( 'test_is_valid : ' .. tostring( test_is_valid ) )
            if test_is_valid then
                -- 在这里，是为了让 TLWindowManager 响应触屏事件
                g_device_obj:initSceneLayers()

                return test()
            end
            package.loaded["script.test"] = nil
        end

        -- 初始化全局的 SDK 对象
        g_sdk_login_obj = g_device_obj:requireSDK().new()

        g_device_obj:run()
    end)

    -- 一些特殊的 log 的输出
    require 'utils.signal'
    signal.listen( 'SYSTEM_PURGE_SCENE', function() startScheduleLog() end )
    startScheduleLog()

    -- 监听网络状态的改变
    g_net_word_type = getNetworkTypeName()
    CCLuaLog( 'g_net_word_type : ' .. tostring( g_net_word_type ) )

    -- 注册监听函数
    register_platform_callback( 'CB_REACHABILITY_CHANGED', function()
        g_net_word_type = getNetworkTypeName()

        -- 如果没有进入游戏，也没有网络的话，就直接回到登录界面
        if not g_sdk_username and ( not g_net_word_type or g_net_word_type == '' ) then return handleSocketDisconnected( 11 ) end

        -- 如果玩家已经进入场景了，就尝试重连
        if g_net_word_type and g_net_word_type ~= '' then
            if g_sdk_username then tryReconnection() end
        end
    end)
end

function startScheduleLog()
    if GameSettings.schedule_log then
        require 'utils.common'
        -- 如果有的话，先停掉上一次的
        if g_schedule_log_handle then unCommonSchedule( g_schedule_log_handle ) g_schedule_log_handle = nil end
        -- 每十秒打印一次
        g_schedule_log_handle = schedule_circle( 10, function()
            -- 当前所有的锁品
            TLWindowManager:SharedTLWindowManager():screenLockLog()
            -- 当前系统可用内存
            CCLuaLog( string.format( 'avail memory : %f MB', tonumber( getAvailMemory() ) ) )
            -- 当前无限循环的 schedule handle 数量
            CCLuaLog( string.format( 'running circle schedule count : %d', getAllCircleHandleCount() ) )
            -- 当前内存使用情况
            dumpall()
        end)
    end
end

-- called by AppDelegate
function enterBackground()
    signal.fire( 'SYSTEM_ENTER_BACKGROUND' )

    pause_music()

    if SystemConfig.getWakeLock() then CCLuaLog( 'wake_lock : releaseWakeLock' ) releaseWakeLock() end
end

function enterForeground()
    if SystemConfig.getWakeLock() then CCLuaLog( 'wake_lock : acquireWakeLock' ) acquireWakeLock() end

    resume_music()

    signal.fire( 'SYSTEM_ENTER_FOREGROUND' )
end

-- 
local additional_msg = {}
function appendAdditionalLog( add_type, log_msg ) additional_msg[add_type] = log_msg end
function reportError(msg, callback)
    local server_id = g_player and PlayerConfig.getLastLoginServerID() or '未登录'    -------- 服务器 ID
    local server_name = g_player and getServerNameByServerID( server_id ) or '未登录' -------- 服务器名
    local account_name = PlayerConfig.getAccountName()  -------------------------------------- 账号
    local actor_name = g_player and g_player.name or '' -------------------------------------- 角色名
    local entity_id = g_player and g_player.entityID or 0 ------------------------------------ entity id
    local level = g_player and g_player.level or 0 ------------------------------------------- level
    local version = game_version_name and game_version_name or AssetsManager:sharedAssetsManager():getVersionName() -- 版本号
    local pkg_version = getPackageVersion()
    local sdk_type_name = GetSdkTypeLua() --------------------------------------------------- sdk type
    local platform = getPlatform() ----------------------------------------------------------- platform
    local deviceUniqueID = g_device_obj:getUniqueDeviceID() ---------------------------------- 设备ID

    local detail_msg = ''
    detail_msg = detail_msg .. string.format( '-- server id         : %s\n', tostring( server_id ) )
    detail_msg = detail_msg .. string.format( '-- server name       : %s\n', tostring( server_name ) )
    detail_msg = detail_msg .. string.format( '-- version           : %s\n', tostring( version ) )
    detail_msg = detail_msg .. string.format( '-- pkg version       : %s\n', tostring( pkg_version ) )
    detail_msg = detail_msg .. string.format( '-- SDK               : %s\n', tostring( sdk_type_name ) )
    detail_msg = detail_msg .. string.format( '-- account           : %s\n', tostring( account_name ) )
    detail_msg = detail_msg .. string.format( '-- actor             : %s\n', tostring( actor_name ) )
    detail_msg = detail_msg .. string.format( '-- entity id         : %s\n', tostring( entity_id ) )
    detail_msg = detail_msg .. string.format( '-- level             : %s\n', tostring( level ) )
    detail_msg = detail_msg .. string.format( '-- platform          : %s\n', tostring( platform ) )
    detail_msg = detail_msg .. string.format( '-- device uniqueID   : %s\n', tostring( deviceUniqueID ) )

    local additinal_msg_tips = {}
    for k, v in pairs( additional_msg ) do
        table.insert(additinal_msg_tips, string.format( '-- %s  : %s\n', tostring( k ), tostring( v ) ))
    end
    detail_msg = detail_msg .. table.concat(additinal_msg_tips, '')

    local tb_text = '----------------------------------------\n' .. detail_msg
    tb_text = tb_text .. 'LUA ERROR: ' .. tostring(msg) .. '\n'
    tb_text = tb_text .. debug.traceback() .. '\n'
    tb_text = tb_text .. '----------------------------------------\n'

    -- 在 ios 或者 android 上，才会把错误上报
    local platform = getPlatform()
    if platform == 'ios' or platform == 'android' then
        require 'utils.netmessage'
        sendHTTPNetMsgEx( GameSettings.error_report_url, '', tb_text, callback)
    end

    return tb_text
end

function __G__TRACKBACK__( msg )
    local tb_text = reportError( msg , function()
        require 'win.message_box'
        openMessageBox( '程序报错', '程序报错，请重新登录', 'MB_OK', {
            MB_OK = function() quitApplication() end,
            MB_INIT = function( mb_obj ) TLWindowManager:SharedTLWindowManager():SetSystemWindow( mb_obj.win ) end,
        })
    end)
    CCLuaLog( tb_text )
end

xpcall( main,  __G__TRACKBACK__ )
