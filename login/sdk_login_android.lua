-- ./login/sdk_login_UC.lua
local luaj = require 'utils.luaj'

local sdk_login_yy_obj = require 'login.sdk_login_YY'
local __sdk_login_android = class( 'sdk_login_YY_android', sdk_login_yy_obj )
function __sdk_login_android:ctor()
    sdk_login_yy_obj.ctor( self )

    -- 看sdk是否支持登录/社区/支付 { login = true, community = true, pay = true }
    local ok, s = luaj.callStaticMethod("org/yy/poem", "querySDKFeature", nil, "()Ljava/lang/String;")
    assert( ok, 'querySDKFeature failed' )
    self.feature = cjson.decode( s )

    register_platform_callback( "SDK_LOGOUT", function( json ) sdk_login_yy_obj.doLogout( self ) end )
end

function __sdk_login_android:openLoginWindow( server_id, arg )
    self.server_id = server_id
    if self.feature.login then
        assert( luaj.callStaticMethod( "org/yy/poem", "accountLogin", { arg or '' }, "(Ljava/lang/String;)V" ) )
    else
        sdk_login_yy_obj.openLoginWindow( self, server_id )
    end
end

--发送支付请求
function __sdk_login_android:openPay( info, callback )
    if not self.feature.pay then return showFloatTip( _YYTEXT( '充值功能尚未开启' ) ) end

    CCLuaLog( 'send Msg SDK_PAY_START with sdktype = '.. getSdkTypeName() )
    -- 支付初始的地方
    sendNetMsg( NetMsgID.SDK_PAY_START, { sdkType = getSdkTypeName(), goodsid = info.goodsid }, function( rsp )
        local serialNo = rsp.serialNo 
        self.pay_call_back = function()
            if callback then callback( { success = true, data = info.goodsid } ) end
        end

        local sig = '(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;)V'
        local callBackInfo = string.format( '%d_%d_%s', self.server_id, g_player.entityID, rsp.serialNo )
        local roleInfo = {
            id = g_player.entityID,
            name = g_player.name,
            faction = '',
            vip = g_player.vip,
            level = g_player.level,
            serverID = self.server_id,
            raw_username = g_sdk_username,
        }

        if g_sdk_extra then roleInfo.extra = g_sdk_extra end

        local args = { info.goodsid, info.name, serialNo, info.amount, callBackInfo, cjson.encode(roleInfo) }

        assert( luaj.callStaticMethod( "org/yy/poem", "pay", args, sig ) )
    end)
end

--打開社區
function __sdk_login_android:openPlatform()
    if self.feature.community then
        assert( luaj.callStaticMethod( "org/yy/poem", "enterPlatform", nil, "()V" ) )
    end
end

--是否有社區
function __sdk_login_android:hasPlatform()
    return self.feature.community
end

--是否要登出
function __sdk_login_android:hasLogout()
    return self.feature.logout
end

function __sdk_login_android:submitExtendData( send_type )
    local roleId = g_player.entityID
    local roleName = g_player.name
    local roleLevel = g_player.level
    local zoneId = self.server_id 
    local zoneName = getServerNameByServerID( zoneId )
    local balance = g_player.gold
    local vip = g_player.vip
    local partyName = '无帮派'
    if g_player.factionID and g_player.factionID > 0 then
        partyName = g_player.factionID
    end

    local json_type = nil

    local info = {
        state = send_type,                   -- type
        id = roleId,                      -- roleId
        name = roleName,                    -- roleName
        level = roleLevel,                   -- roleLevel
        serverID = zoneId,                      -- zoneId
        serverName = zoneName,                    -- zoneName
        gold = balance,                     -- balance
        vip = vip,                         -- vip 
        factionName = partyName                    -- partyName 
    }

    local sig = "(Ljava/lang/String;)V"
    assert( luaj.callStaticMethod( "org/yy/poem", "submitExtendData", { cjson.encode( info ) }, sig ) )
end

--退出
function __sdk_login_android:doQuit()
    luaj.callStaticMethod( "org/yy/poem", "quitConfirm", nil, "()V" )
end

function __sdk_login_android:doLogout()
    luaj.callStaticMethod( "org/yy/poem", "accountLogout", nil, "()V" )
end

return __sdk_login_android
