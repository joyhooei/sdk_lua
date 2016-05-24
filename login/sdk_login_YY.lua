-- ./login/sdk_login_YY.lua

local sdk_login_base_obj = require 'login.sdk_login_base'
local __sdk_login_YY = class( 'sdk_login_YY', sdk_login_base_obj )
function __sdk_login_YY:ctor()
    sdk_login_base_obj.ctor( self )

    register_platform_callback( "SDK_LOGIN_SUCCESS", function(json)
        local u = cjson.decode(json)
        CCLuaLog(string.format('token:%s, userID:%s', u.token, u.userID))
        CCLuaLog("lua onLoginSuccess:" .. json);
        sdk_login_base_obj.doLogin( self, u.token, u.userID, u.channelID )
    end)
    register_platform_callback( "SDK_LOGIN_FAILED", function( json ) end )
    register_platform_callback( "SDK_LOGOUT", function( json ) self:doLogout() end )
    register_platform_callback( "SDK_PAY_SUCCESS", function( json ) end )
    register_platform_callback( "SDK_PAY_FAIL", function( json ) end )
    register_platform_callback( "SDK_EXIT", function( json ) g_device_obj:doQuit() end )
end

function __sdk_login_YY:openLoginWindow()
    require 'common.pop_window_manager'
    openModulePopWindow( 'gamecommon.login_mb_module', nil )

    if g_boot_win and toTLWindow( g_boot_win.item_win ) then g_boot_win.item_win:SetIsEnable( true ) end
end

function __sdk_login_YY:openRegisterWindow()
    require 'common.pop_window_manager'
    openModulePopWindow( 'gamecommon.register_mb_module', nil )

    if g_boot_win and toTLWindow( g_boot_win.item_win ) then g_boot_win.item_win:SetIsEnable( true ) end
end

-- loginUin  : account
-- sessionid : password
function __sdk_login_YY:doLogin( loginUin, sessionid, channel_id )
    -- 登录需要使用到的协议
    registerHTTPNetMsg( NetMsgID.SDK_CHECK_LOGIN, 'poem.SDKLoginRequest', 'poem.HTTPLoginResponse', nil, { lock_name = 'SDK_CHECK_LOGIN' } )

    local channel = getMetaData( 'CHANNEL' )
    if channel_id and channel_id ~= '' then channel = channel_id end

    local send_tbl = {
        sdkType = GetSdkTypeLua(),
        channel = channel,
        sessionId = sessionid,
        uin = loginUin,
        deviceId = get_device_id(),
        --featureCode = '',
        deviceInfo = g_device_obj:getDeviceInfo(),
    }

    sendHTTPNetMsg( NetMsgID.SDK_CHECK_LOGIN, send_tbl, function( recv_tbl, error_code )
        g_sdk_extra    = recv_tbl.extra
        g_verify_code  = recv_tbl.verify_code
        g_user_id      = recv_tbl.userID
        g_sdk_username = recv_tbl.sdk_username

        CCLuaLog( 'g_sdk_extra   : ' .. tostring( g_sdk_extra    ) )
        CCLuaLog( 'g_verify_code : ' .. tostring( g_verify_code  ) )
        CCLuaLog( 'g_user_id     : ' .. tostring( g_user_id      ) )
        CCLuaLog( 'g_sdk_username: ' .. tostring( g_sdk_username ) )
        CCLuaLog( 'error_code    : ' .. tostring( error_code ) )

        -- 保存账号信息
        sdk_login_base_obj.doLogin( self, loginUin, sessionid )

        -- 登录成功抛出信号
        setLoginState( true )
        signal.fire( 'SDK_LOGIN_STATE_CHANGE' )
    end, function()  end )
end

-- TODO useless
function __sdk_login_YY:selectRole(roles, enter_func)
    TLWindowManager:SharedTLWindowManager():unlockScreen( "login_server" )
    registerHTTPNetMsg( NetMsgID.CHOOSE_ROLE, 'poem.HTTPChooseRoleRequest', 'poem.HTTPChooseRoleResponse', nil, { lock_name = 'CHOOSE_ROLE' } )

    if #(roles or {}) <= 0 then
        if enter_func then enter_func( {} ) end
        return
    end

    if #roles == 1 then
        sendHTTPNetMsg( NetMsgID.CHOOSE_ROLE, {regionID = g_server_id, roleID = roles[1].id}, function( recv_tbl )
            if enter_func then enter_func( recv_tbl ) end
        end)
        return
    end

    local obj = {}
    local winSize = getDeviceScreenLogicSize()

    local pFrame = MCFrame:createWithBox( CCRect( -winSize.width * 0.5, -winSize.height * 0.5, winSize.width, winSize.height ) )
    all_scene_layers[layer_type_fight_ui]:addChild( pFrame, 2 )
    local pWin = init_top_window( pFrame )

    local node_gray = CCLayerColor:create(ccc4(0, 0, 0, 200), winSize.width, winSize.height + 300)
    node_gray:setPosition(winSize.width / -2, winSize.height / -2)
    pFrame:addChild(node_gray, -1000)

    local mc = createMovieClipWithName( 'lollogin/UI/login_parts/parts1000_1' )
    local win = TLWindow:createWindow( mc )
    pFrame:addChild( mc )
    pWin:AddChildWindow( win )

    init_simple_button( pWin, function() schedule_once(function() obj:destroy() end ) end )
    simple_button( win, 'guanbi', function() schedule_once(function() obj:destroy() end ) end )

    local container = multi_scroller( win, 'quyu', TL_SCROLL_TYPE_UP_DOWN, 0, 0 )
    local width_server_list = getBoundingBox( mc:getChildByName( 'quyu' ) ).size.width


    for index, role_info in ipairs( roles or {} ) do
        local item_mc = createMovieClipWithName( 'lollogin/UI/login_parts/parts1000' )
        item_mc:setScale( ( container.frame.mcBoundingBox.size.width / 2 ) / item_mc.mcBoundingBox.size.width )
        local item_win = TLWindow:createWindow( item_mc )

        require 'win.General.views'
        local vip_str = getVipFormatStr(role_info.vip)

        label( item_win, 'name', 24, CCImage.kAlignCenter):set_rich_string( role_info.name )
        label( item_win, 'VIP', 24, CCImage.kAlignLeft):set_rich_string( vip_str )
        label( item_win, 'lv', 24, CCImage.kAlignLeft):set_rich_string( 'Lv.' .. tostring( role_info.level ) )
        label( item_win, 'fu', 24, CCImage.kAlignCenter):set_rich_string( table.hasKey(role_info, 'last_region_name') and role_info.last_region_name or self.server_name )

        local sprite_hero_icon = MCLoader:sharedMCLoader():loadSprite('icon/' .. C_ITEMS[role_info.iconID].iconid .. '.png')
        local sprite_hero_bg = MCLoader:sharedMCLoader():loadSprite('icon/' .. C_ITEMS[900001].iconid .. '.png')

        local _hero_box_ = item_mc:getChildByName('touxiang')
        _hero_box_:addChild(sprite_hero_icon)
        _hero_box_:addChild(sprite_hero_bg)

        init_simple_button(item_win, function()
            pWin:SetIsEnable(false)

            sendHTTPNetMsg( NetMsgID.CHOOSE_ROLE, {regionID = g_server_id, roleID = role_info.entityID}, function( recv_tbl )
                schedule_once(function()
                    obj:destroy(function() if enter_func then enter_func( recv_tbl ) end end)
                end)
            end)
        end)

        container:append( item_win )
    end
    container:layout()

    function obj:open(func)
        pWin:SetIsVisible( true )
        playTopwinOpenAnim(pFrame, 'SCALE', func)
    end

    function obj.destroy( obj, func )
        if toTLWindow( pWin ) then pWin:SetIsEnable( false ) end
        playTopwinCloseAnim(pFrame, 'SCALE', function()
            if toCCNode( pFrame ) then pFrame:removeFromParentAndCleanup( true ) end
            if toTLWindow( pWin ) then TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( pWin ) end
            if func then func() end
            if toTLWindow( self.item_win ) then self.item_win:SetIsEnable( true ) end
        end)
    end

    obj:open()
end

function __sdk_login_YY:doRegister( account, password )
    local function __real_register__( binding_quick_register_account )
        local send_tbl = {
            username = account,
            password = password,
            imsi = get_device_id(),
            sdkType = GetSdkTypeLua(),
            channel = getMetaData('CHANNEL'),
            --featureCode=getMetaData('OPGameSDK_GAME_KEY'),
            deviceInfo = g_device_obj:getDeviceInfo(),
            origin_username = binding_quick_register_account and PlayerConfig.getQuickRegisterAccountName() or nil,
            origin_password = binding_quick_register_account and PlayerConfig.getQuickRegisterPassword() or nil,
        }

        registerHTTPNetMsg( NetMsgID.CREATE_USER, 'poem.RegisterRequest', 'poem.HTTPLoginResponse', nil, { lock_name = 'CREATE_USER' } )
        sendHTTPNetMsg( NetMsgID.CREATE_USER, send_tbl, function( recv_tbl )
            -- 如果是绑定的话，就把原来的清掉
            if binding_quick_register_account then
                PlayerConfig.setQuickRegister( false )
                PlayerConfig.setQuickRegisterAccountName( '' )
                PlayerConfig.setQuickRegisterPassword( '' )
            end

            self:doLogin( account, password )
        -- end, function() sdk_login_base_obj:openRegisterWindow() end )
        end, function() end )
    end

    -- 是否已经有快速注册的账号，如果有的话
    if not PlayerConfig.getQuickRegister() then
        __real_register__( false )
    else
        require 'common.message_box_module'
        openMessageBox( _YYTEXT('账号绑定'), _YYTEXT('[colorindex:colorIndex=0]检测到您有一个[colorindex:colorIndex=3]快速进入[colorindex:colorIndex=0]的角色[endl:num=1]是否继续该角色的进度进行游戏?[endl:num=1]继续后角色将[colorindex:colorIndex=5]与新账号绑定[colorindex:colorIndex=0]!'), 'MB_OKCANCEL', {
            ['TITLE_STYLE'] = function( title_info )
                title_info.font_size = 40
                return title_info
            end,
            ['BTN_STYLE'] = function( button_info )
                for _,b_info in ipairs( button_info ) do
                    b_info.font_size = 30
                    if b_info.btn_code == 'MB_OK' then
                        b_info.text = '绑定账号'
                    else
                        b_info.text = '创建新账号'
                    end
                end
                return button_info
            end,
            ['MB_OK'] = function()
                __real_register__( true )
            end,
            ['MB_CANCEL'] = function()
                __real_register__( false )
            end,
        })
    end
end

function __sdk_login_YY:doQuickRegister( server_id )
    local function __real_quick_register__()
        local send_tbl = {
            sdkType = GetSdkTypeLua(),
            channel = getMetaData('CHANNEL'),
            deviceInfo = g_device_obj:getDeviceInfo(),
        }

        registerHTTPNetMsg( NetMsgID.AUTO_REGISTER, 'poem.AutoRegisterRequest', 'poem.AutoRegisterResponse', nil, { lock_name = 'QUICK_CREATE_USER' } )
        sendHTTPNetMsg( NetMsgID.AUTO_REGISTER, send_tbl, function( recv_tbl )
            g_sdk_username = recv_tbl.sdk_username

            -- 记下快速注册的账号和密码，用于绑定
            PlayerConfig.setQuickRegister( true )
            PlayerConfig.setQuickRegisterAccountName( recv_tbl.username )
            PlayerConfig.setQuickRegisterPassword( recv_tbl.password )

            self:doLogin( account, password )
        -- end, function() sdk_login_base_obj:openRegisterWindow() end )
        end, function() end )
    end

    -- 如果已经有一个登陆过的账号的话，就提示
    local quick_register_account_name = PlayerConfig.getAccountName() or ''
    if quick_register_account_name == '' then
        __real_quick_register__()
    else
        require 'common.message_box_module'
        openMessageBox( _YYTEXT('快速进入'), _YYTEXT('[colorindex:colorIndex=3]快速进入[colorindex:colorIndex=0]将创建一个新的账号[colorindex:colorIndex=5]代替[colorindex:colorIndex=0]现有账号进入游戏！[colorindex:colorIndex=5]请牢记[colorindex:colorIndex=0]原账号和密码！'), 'MB_OKCANCEL', {
            ['TITLE_STYLE'] = function( title_info )
                title_info.font_size = 40
                return title_info
            end,
            ['BTN_STYLE'] = function( button_info )
                for _,b_info in ipairs( button_info ) do
                    b_info.font_size = 35
                    if b_info.btn_code == 'MB_OK' then
                        b_info.text = '继续创建'
                    else
                        b_info.text = '取  消'
                    end
                end
                return button_info
            end,
            ['MB_OK'] = function()
                __real_quick_register__()
            end,
        })
    end
end

function __sdk_login_YY:doLogout()
    sdk_login_base_obj.doLogout( self )
end

--发送支付请求
function __sdk_login_YY:openPay( info, callback )
    sendNetMsg( NetMsgID.SDK_PAY_START, { sdkType = GetSdkTypeLua(), goodsid = info.goodsid }, function( rsp )
        self.pay_call_back = function()
            if callback then callback( { success = true, data = info.goodsid } ) end
        end
    end)
end

return __sdk_login_YY

