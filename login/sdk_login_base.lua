-- ./login/sdk_login_base.lua

local __sdk_login_base = class( 'sdk_login_base' )
function __sdk_login_base:ctor()
    require 'utils.netmessage'
    registerNetMsg( NetMsgID.SDK_PAY_RESULT, nil, nil, function()
        if self.pay_call_back then self.pay_call_back() end
    end)
end
function __sdk_login_base:openLoginWindow() end
function __sdk_login_base:openRegisterWindow() end
function __sdk_login_base:doLogin( account, password )
    -- 在这里，仅仅是保存
    local last_server_id = PlayerConfig.getLastLoginServerID()
    local last_server_name = getServerNameByServerID( last_server_id )

    PlayerConfig.setAccountName( account or '' )
    PlayerConfig.setPassword( password or '' )
    -- PlayerConfig.setLastLoginServerID( server_id or 0 )
    -- PlayerConfig.setLastLoginServerName( server_name or '' )
    PlayerConfig.setLastLoginServerID2( last_server_id or 0 )
    PlayerConfig.setLastLoginServerName2( last_server_name or '' )

    PlayerConfig.flush()
end
function __sdk_login_base:doRegister( account, password ) end
function __sdk_login_base:doLogout()
    purge_network()
    purge_scene()

    -- 释放 UI 贴图
    for _,tex_2d in pairs( g_ui_tex_2d or {} ) do tex_2d:release() end
    g_ui_tex_2d = {}

    openBootWin( false )

    schedule_frames( 3, function() removeUnusedTextures( true ) end )
end

function __sdk_login_base:selectRole( roles, enter_func )
end

function __sdk_login_base:doQuit()   -- 退出
    g_device_obj:doQuit()
end

function __sdk_login_base:submitExtendData(send_type)
end

function __sdk_login_base:openPlatform() end                       --打開社區
function __sdk_login_base:hasPlatform() return false end           --是否有社區方法
function __sdk_login_base:hasLogout() return false end           --是否有登出

function __sdk_login_base:openPay( info, call_back_func ) end

return __sdk_login_base
