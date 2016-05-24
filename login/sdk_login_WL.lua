-- ./login/sdk_login_YY.lua
local luaj = require 'utils.luaj'

local sdk_login_base_obj = require 'login.sdk_login_base'
local base_class = require 'login.sdk_login_android'
local __sdk_login_WL = class( 'sdk_login_WL', base_class )
function __sdk_login_WL:ctor()
    base_class.ctor(self)
end

function __sdk_login_WL:doRegister( account, password )
    local function __real_register__( binding_quick_register_account )
        local send_tbl = {
            username = account,
            password = password,
            imsi = get_device_id(),
            sdkType = getSdkTypeName(),
            channel = getMetaData('CHANNEL'),
            --featureCode=getMetaData('OPGameSDK_GAME_KEY'),
            deviceInfo = g_device_obj:getDeviceInfo(),
            origin_username = binding_quick_register_account and PlayerConfig.getQuickRegisterAccountName() or nil,
            origin_password = binding_quick_register_account and PlayerConfig.getQuickRegisterPassword() or nil,
        }

        registerHTTPNetMsg( NetMsgID.CREATE_USER, 'poem.RegisterRequest', 'poem.RegisterResponse', nil, { lock_name = 'CREATE_USER' } )
        sendHTTPNetMsg( NetMsgID.CREATE_USER, send_tbl, function( recv_tbl )
            -- 如果是绑定的话，就把原来的清掉
            if binding_quick_register_account then
                PlayerConfig.setQuickRegister( false )
                PlayerConfig.setQuickRegisterAccountName( '' )
                PlayerConfig.setQuickRegisterPassword( '' )
            end

            g_sdk_username = recv_tbl.sdk_username 

            sdk_login_base_obj.doLogin( self, account, password )
        end, function() openRegisterWindow() end )
    end

    -- 是否已经有快速注册的账号，如果有的话
    if not PlayerConfig.getQuickRegister() then
        __real_register__( false )
    else
        openMessageBox( _YYTEXT('账号绑定'), _YYTEXT('[colorindex:colorIndex=0]检测到您有一个[colorindex:colorIndex=3]快速进入[colorindex:colorIndex=0]的角色[endl:num=1]是否继续该角色的进度进行游戏?[endl:num=1]继续后角色将[colorindex:colorIndex=5]与新账号绑定[colorindex:colorIndex=0]!'), 'MB_OKCANCEL', {
            ['TITLE_STYLE'] = function( title_info )
                title_info.font_size = 40
                return title_info
            end,
            ['BTN_STYLE'] = function( button_info )
                for _,b_info in ipairs( button_info ) do
                    b_info.font_size = 35
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

function __sdk_login_WL:doQuickRegister()
    local function __real_quick_register__()
        local send_tbl = {
            sdkType = getSdkTypeName(),
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

            self:doLogin( recv_tbl.username, recv_tbl.password )
        end, function() openRegisterWindow() end )
    end

    -- 如果已经有一个登陆过的账号的话，就提示
    local quick_register_account_name = PlayerConfig.getAccountName() or ''
    if quick_register_account_name == '' then
        __real_quick_register__()
    else
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

function __sdk_login_WL:doLogin( account, password )
    -- 登录需要使用到的协议
    registerHTTPNetMsg( NetMsgID.LOGIN, 'poem.HTTPLoginRequest', 'poem.HTTPLoginResponse', nil, { lock_name = 'LOGIN' } )

    local send_tbl = {
        username = account,
        password = password,
        version = game_version,
        sdkType = getSdkTypeName(),
        --featureCode = '',
        deviceInfo = g_device_obj:getDeviceInfo(),
    }
    sendHTTPNetMsg( NetMsgID.LOGIN, send_tbl, function( recv_tbl, error_code )
        TLWindowManager:SharedTLWindowManager():lockScreen( "login_server" )
        g_verify_code = recv_tbl.verify_code
        g_user_id = recv_tbl.userID
        g_sdk_username = recv_tbl.sdk_username

        sdk_login_base_obj.doLogin( self, account, password )

        try_connect_server( recv_tbl.world.ip, recv_tbl.world.port, function( conn )
            TLWindowManager:SharedTLWindowManager():unlockScreen( "login_server" )
            registerNetMsg( NetMsgID.LOGIN_WORLD, 'poem.LoginWorldRequest', 'poem.LoginWorldResponse' )
            sendNetMsg( NetMsgID.LOGIN_WORLD, { userID = recv_tbl.userID, verify_code = recv_tbl.verify_code, }, function( ret_tbl )
                -- 登陆到游戏内时保存一次服务器id
                if ret_tbl.roles and #ret_tbl.roles == 0 then               --判断是否是新号
                    openActorNameWindow()
                else
                    enter_with_current_role( ret_tbl.roles[1].id, nil )          -- 直接进入
                end

                -- 进行心跳推送
                self:sendHeartBeatMessage()

            end)
        end)
    end, function()
        TLWindowManager:SharedTLWindowManager():unlockScreen( "login_server" )
        openLoginWindow()
    end )
end

return __sdk_login_WL
