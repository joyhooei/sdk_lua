-- ./login/sdk_login_ios.lua
local luaoc = require 'utils.luaoc'

local sdk_login_yy_obj = require 'login.sdk_login_YY'
local __sdk_login_ios = class( 'sdk_login_ios', sdk_login_yy_obj )
function __sdk_login_ios:ctor()
    sdk_login_yy_obj.ctor( self )

    register_platform_callback( "SDK_LOGOUT", function( json ) sdk_login_yy_obj.doLogout( self ) end )
end

function __sdk_login_ios:openLoginWindow( server_id )
    self.server_id = server_id
    local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "login", payload )
    if not ok then
        CCLuaLog( 'call [SDKLoginUtilsForIOS login] failed.' )
    end
end

--发送支付请求
function __sdk_login_ios:openPay( payload, callback )
    CCLuaLog( 'send Msg SDK_PAY_START with sdktype = ' .. getSdkTypeName() )
    -- 支付初始的地方
    sendNetMsg( NetMsgID.SDK_PAY_START, { sdkType = getSdkTypeName(), goodsid = payload.goodsid }, function( rsp )
        self.pay_call_back = function()
            if callback then callback( { success = true, data = payload.goodsid } ) end
        end

        payload.server_id = self.server_id
        payload.entityID = g_player.entityID
        payload.serialNo = rsp.serialNo

        local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "purchase", payload )
        if not ok then
            CCLuaLog( 'call [SDKLoginUtilsForIOS purchase] failed.' )
        end
    end)
end

--打開社區
function __sdk_login_ios:openPlatform()
    local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "platform", {} )
    if not ok then
        CCLuaLog( 'call [SDKLoginUtilsForIOS platform] failed.' )
    end
end

--是否有社區
local platform_sdks = { 'ITOOLS_IOS', 'AS_IOS', 'HM_IOS', 'LE8_IOS', 'PP_IOS', 'TB_IOS', 'XY_IOS' }
function __sdk_login_ios:hasPlatform()
    local sdk_type_feature_name = getSdkTypeFeatureName()
    if platform_sdks[sdk_type_feature_name] then return true end
    return false
end

function __sdk_login_ios:doLogout()
    -- TODO：仿 android 的做法
    -- luaj.callStaticMethod( "org/weilan/poem", "accountLogout", nil, "()V" )
end

return __sdk_login_ios
