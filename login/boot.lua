--./login/boot.lua
require 'utils.common'
require 'ui.controls'
require 'utils.netmessage'
require 'gamecommon.boot_ui'

---------------------------------------------------------------------------------------------------------------------------
-- check_state : 'not_started', 'checking', 'check_failed', 'check_success'
---------------------------------------------------------------------------------------------------------------------------
__boot_check_base = class( 'boot_check_base' )
function __boot_check_base:ctor( boot_win )
    self.boot_win = boot_win
    self.check_state = 'not_started'
end

function __boot_check_base:execute( call_back_func )
    self.check_state = 'check_success'
    call_back_func()
end

function __boot_check_base:handleError()
end
---------------------------------------------------------------------------------------------------------------------------

-- 需要完成以下的检查，才可以登录或者注册
function openBootWin( is_show_login )
    -- test here
    --[=[
    require 'win.welcome.welcome_module'
    openWelcomeModule()
    --[[--]=]

    if not g_boot_win or not toTLWindow( g_boot_win.win ) or g_boot_win.win:retainCount() <= 2 then
        -- 播放登录的背景音乐
        set_music( 'music/jingle_title.mp3', true )

        g_boot_win = createBootWin()
        g_boot_win:open( is_show_login )
    end
    --]]
end

function destroyBootWin()
    if g_boot_win and toTLWindow( g_boot_win.win ) and g_boot_win.win:retainCount() > 2 then g_boot_win:destroy() end

    require 'common.pop_window_manager'
    -- 如果登录注册窗口打开了，销毁
    closeModulePopWindow( 'gamecommon.login_mb_module' )
    closeModulePopWindow( 'gamecommon.register_mb_module' )

    -- 如果改名界面打开了，销毁
    closeModulePopWindow( 'gamecommon.actor_name_module' )

    -- 如果选择服务器列表窗口打开了，销毁
    closeModulePopWindow( 'gamecommon.server_list_module' )

    g_boot_win = nil
end

local login_state = false
function getLoginState() return login_state end
function setLoginState( state ) login_state = state end
signal.listen( 'SYSTEM_PURGE_SCENE', function()
    setLoginState( false )
end )

function createBootWin()
    local win, frame = create_frame_top_window_by_size( all_scene_layers[layer_type_ui] )
    CCNodeExtend.extend( frame )
    local obj = { win = win, frame = frame, boot_check_finish = false, is_valid = true }

    -- 背景
    local bg_mc = createBootBackground()
    frame:addChild( bg_mc )

    -- 当前的版本
    local assetsManager = AssetsManager:sharedAssetsManager()
    game_version = getVersion()
    game_version_name = assetsManager:getVersionName()

    local function get_version_text()
        return string.format( 'v%s', game_version_name )
    end

    local ver_width, ver_height = 200, 30
    local ver_box = CCRect( -ver_width*0.5, -ver_height*0.5, 200, 30 )
    local ver_frame = MCFrame:createWithBox( ver_box )
    ver_frame:setPosition( frame.mcBoundingBox.size.width / 2 + 120, 30 - frame.mcBoundingBox.size.height / 2 )
    frame:addChild( ver_frame )

    local version_label = TLLabelRichTex:create( get_version_text(), 22, CCSize( ver_width, ver_height ), CCImage.kAlignLeft )
    ver_frame:addChild( version_label )

    local ver_win = TLWindow:createWindow( ver_frame )
    win:AddChildWindow( ver_win )

    local counter = 5
    init_simple_button( ver_win, function()
        counter = counter - 1
        CCLuaLog( 'counter : ' .. tostring( counter ) )
        if counter <= 0 then
            version_label:setRichString( get_version_text() )
        end
    end)

    -- 任何一个失败，都会重新检查一遍
    init_simple_button( win, function() if not obj.boot_check_finish then obj:do_boot_check() end end)

    require 'common.relative_layout_manager'
    require 'gamecommon.node_anim_config'

    function obj:open( is_show_login )
        self.is_show_login = is_show_login

        win:SetIsVisible( true )
        self:do_boot_check()
    end

    function obj:destroy()
        -- TODO
        self.is_valid = false
        TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( win )
        schedule_frames( 5, function() removeUnusedTextures( true ) end )
    end

    function obj:initLogin()
        self.boot_check_finish = true

        if not toTLWindow( win ) then return end

        if self.hasInited then return end
        self.hasInited = true

        require 'login.login'
        initBootWindow( self )

        --[[
        -- 部分恶心的SDK的切换账号
        if getPlatform() == 'android' then
            local luaj = require 'utils.luaj'
            assert(luaj.callStaticMethod("org/yy/poem", "doLogoutListener", nil, "()V"))
        end
        --]]
    end

    function obj:showLoading()
        TLWindowManager:SharedTLWindowManager():lockScreen( 'boot_loading' )

        if not toCCNode( self.mc_loading ) then
            -- TODO
            -- self.mc_loading = createMovieClipWithName('60057/60057_3')
            -- self.mc_loading:play(0, -1, -1)
            -- frame:addChild( self.mc_loading )
        end

        -- self.mc_loading:setVisible( true )
    end

    function obj:hideLoading()
        if toCCNode( self.mc_loading ) then self.mc_loading:removeFromParentAndCleanup( true ) end
        self.mc_loading = nil

        TLWindowManager:SharedTLWindowManager():unlockScreen( 'boot_loading' )
    end

    function obj:init_boot_check_list()
        self.boot_check_list = {}
        self.boot_check_name = {}
        g_device_obj:initBootCheckList( self.boot_check_name )
    end

    function obj:is_all_boot_check_success()
        for _,check_obj in ipairs( self.boot_check_list ) do
            if check_obj.check_state ~= 'check_success' then return false end
        end
        return true
    end

    function obj:is_all_boot_check_done()
        for _,check_obj in ipairs( self.boot_check_list ) do
            if check_obj.check_state ~= 'check_success' and check_obj.check_state ~= 'check_failed' then return false end
        end
        return true
    end

    function obj:do_boot_check()
        -- 先把菊花张开
        self:showLoading()

        -- 
        local function __check_version_fix__( call_back_func )
            -- 不需要检查增量的话，就不需要 fix
            if not GameSettings.is_check_upgrade then return call_back_func() end

            local version_fix_url = string.format( '%sfix_%d.lua', GameSettings.upgrade_url, game_version )
            CCLuaLog( 'version_fix_url : ' .. tostring( version_fix_url ) )

            local external_path = get_external_path()
            local save_to = string.format( '%s/fix_%d.lua', external_path, game_version )
            CCLuaLog( 'external_path : ' .. tostring( external_path ) )

            TLHttpClient:sharedHttpClient():requestFile( version_fix_url, save_to, function( content_data, http_code, error_code, error_msg )
                if http_code == 200 then
                    pcall( function()
                        local version_fix = string.format( '%s/fix_%d', external_path, game_version )
                        CCLuaLog( version_fix )
                        require( version_fix )
                    end)
                end

                -- 不管有没有这个文件，都执行回调
                call_back_func()
            end)
        end

        -- 在增量更新前，检查版本的修正代码
        __check_version_fix__( function()
            if not self.is_valid then return end

            -- 开始检查更新
            require 'login.check_upgrade'
            -- 增量更新完成后，还需要拉取服务器列表以及检查配置更新
            -- 所以在这里的 cb ，目前只在增量更新完成后才不等于 nil，然后等服务器列表和配置增量都完成了，才回调清理
            checkUpgrade( self, function( upgrade_flag, cb )
                if not self.is_valid then return end

                version_label:setRichString( get_version_text() )

                -- 更新完成，就开始做其他的检查，比如拉取最新的服务器列表以及增量的配置等等
                if upgrade_flag then
                    -- 在增量更新结束后，要重新检查一下修正代码
                    __check_version_fix__( function()
                        if not self.is_valid then return end

                        -- 在开始之前，new 一个对象出来
                        self.boot_check_list = {}
                        for _, file_name in ipairs( self.boot_check_name ) do table.insert( self.boot_check_list, require ( file_name ).new( self ) ) end

                        local function __check_cb__()
                            if not self.is_valid then return end

                            -- 是否所有都已经完成了
                            if self:is_all_boot_check_done() then
                                -- 把菊花收起来
                                self:hideLoading()

                                if cb then cb() end

                                local err_check_obj = nil
                                for _, check_obj in ipairs( self.boot_check_list ) do
                                    if check_obj.check_state == 'check_failed' then
                                        err_check_obj = check_obj

                                        break
                                    end
                                end

                                -- 如果有错误的话，就显示出来
                                if err_check_obj then return err_check_obj:handleError() end

                                -- 初始化登录
                                self:initLogin()
                            end
                        end

                        -- 如果没有需要检查的，就直接初始化登陆
                        if #self.boot_check_list == 0 then
                            -- 把菊花收起来
                            self:hideLoading()

                            if cb then cb() end

                            -- 初始化登录
                            self:initLogin()
                        else
                            for _, check_obj in ipairs( self.boot_check_list ) do
                                check_obj.check_state = 'checking'
                                check_obj:execute( __check_cb__ )
                            end
                        end
                    end)
                else
                    -- 更新失败也要把菊花收起来
                    self:hideLoading()

                    if cb then cb() end
                end
            end)
        end)
    end

    obj:init_boot_check_list()

    return obj
end


