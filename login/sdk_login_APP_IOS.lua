-- ./login/sdk_login_APP_IOS.lua
require 'utils.signal'
local luaoc = require 'utils.luaoc'

local sdk_login_yy_obj = require 'login.sdk_login_YY'
local __sdk_login_APP_IOS = class( 'sdk_login_APP_IOS', sdk_login_yy_obj )

function __sdk_login_APP_IOS:ctor()
    sdk_login_yy_obj.ctor( self )

    register_platform_callback( 'CB_ITUNES_IAP_VALIDATION', function( json )
        CCLuaLog('CB_ITUNES_IAP_VALIDATION: ' .. json)
        local payload = cjson.decode(json)
        receipt_validation(payload)
    end)
end

function receipt_validation( payload )
    -- 验证付费凭证，如果成功删除本地记录，交易完成
    registerNetMsg( NetMsgID.ITUNES_IAP_VALIDATION, 'poem.iTunesStoreReceiptRequest', 'poem.iTunesStoreReceiptResponse' )
    sendNetMsg( NetMsgID.ITUNES_IAP_VALIDATION, { receipt = payload.receipt }, function( rsp )
        local params = { entityID = g_player.entityID, transaction_id = rsp.transaction_id }
        if rsp.successed then
            local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "deleteReceipt", params )
            if not ok then
                CCLuaLog( 'call [SDKLoginUtilsForIOS deleteReceipt] failed.' )
            end
        end
    end)
end

signal.listen( 'FIRST_ENTER_SCENE', function()
    CCLuaLog( '>>> FIRST_ENTER_SCENE' )
    local payload = { entityID = g_player.entityID }
    local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "afterLogin", payload )
    if not ok then
        CCLuaLog( 'call [SDKLoginUtilsForIOS afterLogin] failed.' )
    end
end)

--发送支付请求
function __sdk_login_APP_IOS:openPay( info, callback )
    CCLuaLog( 'send Msg SDK_PAY_START with sdktype = ' .. getSdkTypeName() )

    local payload = { entityID = g_player.entityID }
    local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "afterLogin", payload )
    if not ok then
        CCLuaLog( 'call [SDKLoginUtilsForIOS afterLogin] failed.' )
    end

    -- 支付初始的地方
    sendNetMsg( NetMsgID.SDK_PAY_START, { sdkType = getSdkTypeName(), goodsid = info.goodsid }, function( rsp )
        local serialNo = rsp.serialNo

        local payload = {
            transaction_id = serialNo,
            product_id = info.goodsid,
            product_name = info.name,
            entityID = g_player.entityID,
            amount = info.amount,
            worldID = self.server_id
        }
        local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "purchase", payload )
        if not ok then
            CCLuaLog( 'call [SDKLoginUtilsForIOS purchase] failed.' )
        end
    end)
end

function __sdk_login_APP_IOS:onRegisterSuccess( payload )
    local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "onRegister", { username = payload.user_name } )
    if not ok then
        CCLuaLog( 'call [SDKLoginUtilsForIOS onRegister] failed.' )
    end
end

function __sdk_login_APP_IOS:onLoginSuccess( payload )
    local ok, ret = luaoc.callStaticMethod( "SDKLoginUtilsForIOS", "onLogin", { username = payload.user_name } )
    if not ok then
        CCLuaLog( 'call [SDKLoginUtilsForIOS onLogin] failed.' )
    end
end

return __sdk_login_APP_IOS
