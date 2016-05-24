-- ./launch/device_win32.lua
local luaj = require 'utils.luaj'

local device_base_obj = require 'launch.device_base'
local __device_android = class( 'device_android', device_base_obj )
function __device_android:ctor()
    device_base_obj.ctor( self )

    -- android sdk logo
    for _, t in ipairs( { "png", "jpg" } ) do
        local fullName = CCFileUtils:sharedFileUtils():fullPathForFilename( string.format( "platformLogo.%s", t ) )
        if CCFileUtils:sharedFileUtils():isFileExist( fullName ) then
            table.insert( self.logo_list, {
                fileName = fullName,
                duration = 2,
            })

            break
        end
    end
end

function __device_android:init()
    device_base_obj.init( self )

    TLWindowManager:SharedTLWindowManager():setKeyBackClickedHandler( function()
        g_sdk_login_obj:doQuit()
    end)
end

local has_destory_quit_status = false

function __device_android:doQuit()
    if has_destory_quit_status then
        return
    end

    has_destory_quit_status = true

    -- 返回键退出游戏窗口
    local quit_win = nil
    local quit_mc = nil

    local function __destroy_quit_window__()
        if not (toCCNode(quit_mc) and toTLWindow(quit_win)) then return end
        has_destory_quit_status = false

        CCLuaLog( 'quit_win : ' .. tostring( quit_win ) )
        CCLuaLog( 'quit_mc : ' .. tostring( quit_mc ) )
        if toTLWindow( quit_win ) then
            quit_mc:removeFromParentAndCleanup( true )
            TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( quit_win )
        end

        quit_win = nil
        quit_mc = nil
    end

    addPurgeSceneCallBackFunc(__destroy_quit_window__)

    require 'ui.controls'

    if toTLWindow( quit_win ) then return __destroy_quit_window__() end

    -- 
    quit_win, quit_mc = topwindow( 'lollogin/login_parts/parts1', nil, all_scene_layers[layer_type_system] )
    quit_win:SetIsVisible( true )
    TLWindowManager:SharedTLWindowManager():SetSystemWindow( quit_win )

    local mc_btn_confirm = createMovieClipWithName( 'lollogin/login_button/button_100' )
    mc_btn_confirm:getChildByName( 'wenben' ):addChild( MCLoader:sharedMCLoader():loadSpriteAsync( '5word_011_4.png' ) )
    mc_btn_confirm:setScale( 0.8 )
    local node_btn_confirm = CCNode:create()
    node_btn_confirm:addChild(mc_btn_confirm)
    quit_mc:getChildByName( 'queding' ):addChild( node_btn_confirm )
    anim_button( quit_win, 'queding', function()
        schedule_once( function()
            __destroy_quit_window__()
            g_device_obj:remove_all_notification()
            g_device_obj:push_notification('push1')
            g_device_obj:push_notification('push2')
            g_device_obj:push_notification('push3')
            g_device_obj:push_notification('push4')
            quitApplication()
        end, 'PAUSE')
    end, node_btn_confirm )

    local mc_btn_cancel = createMovieClipWithName( 'lollogin/login_button/button_100' )
    mc_btn_cancel:getChildByName( 'wenben' ):addChild( MCLoader:sharedMCLoader():loadSpriteAsync( '5word_010_26.png' ) )
    mc_btn_cancel:setScale( 0.8 )
    local node_btn_cancel = CCNode:create()
    node_btn_cancel:addChild(mc_btn_cancel)
    quit_mc:getChildByName( 'quxiao' ):addChild( node_btn_cancel )
    anim_button( quit_win, 'quxiao', function() schedule_once( __destroy_quit_window__ ) end, node_btn_cancel )

    local tips_label = label( quit_win, 'xinxi', 28, CCImage.kAlignCenter )
    tips_label:set_rich_string( '是否退出游戏' )
end

function __device_android:run()
    self:playCGMp4()

    device_base_obj.run( self )
end

function __device_android:getUniqueDeviceID()
    return getMAC() or getIMEI()
end

function __device_android:listenYaoYiYao( yyy_func )
    register_platform_callback( "YAOYIYAO", yyy_func )

    assert( luaj.callStaticMethod( "org/yy/poem", "listenYaoYiYao", nil, "()V" ) )
end

function __device_android:unlistenYaoYiYao()
    assert( luaj.callStaticMethod( "org/yy/poem", "unlistenYaoYiYao", nil, "()V" ) )
end

return __device_android
