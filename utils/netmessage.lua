--./utils/netmessage.lua

-- 网络协议
local net_msg_info = {}

-- 当前连接使用的 IP 和端口
local server_ip = nil
local server_port = nil

-- 锁屏和解锁的方法
local lock_scene_func = nil
local unlock_scene_func = nil
local clear_all_lock_scene_func = nil
local handle_socket_disconnected_func = nil
-- 超时回调函数
local time_out_handle = nil
local time_out_interval = 15
local time_out_lock_info = nil
local time_out_call_back_func = nil
local time_out_clean_call_back_func = nil
-- 
local listen_msg_id_call_back_func = {}

--[[
-- debug write send & recv msg id
local debug_file_name = CCFileUtils:sharedFileUtils():getWritablePath() .. 'send_recv_msg_id.txt'
CCLuaLog( 'debug_file_name : ' .. tostring( debug_file_name ) )
local debug_msg_file = io.open( debug_file_name, 'a' )
local pretty = require 'utils.pretty'
debug_msg_file:write( '\n\n' )
debug_msg_file:write( '========================================================================================================\n' )
debug_msg_file:write( '==== ' .. os.date( '%c', os.time() ) .. ' =========================================\n' )
debug_msg_file:write( '========================================================================================================\n\n' )
debug_msg_file:flush()
local function __write_msg_id__( msg_id, is_send, tbl )
    debug_msg_file:write( string.format( '==== [%s] : %d ==============================================\n', is_send and 'send' or 'recv', msg_id ) )
    debug_msg_file:write( pretty.write( tbl ) )
    debug_msg_file:write( '\n\n' )
    debug_msg_file:flush()
end
--]]
local function __write_msg_id__( msg_id, is_send, tbl )
end

-- 
local function decode_msg( msg_id, msg_content, len )
    local nm_info = net_msg_info[msg_id]
    if not nm_info then return {} end
    if not nm_info.decode_proto then return {} end
    return protobuf.decode( nm_info.decode_proto, msg_content, len )
end

-- return msg, len, lock_info, recv_func, err
local function encode_msg( msg_id, msg_tbl )
    if not msg_id then return nil, nil, nil, nil, 1 end

    local nm_info = net_msg_info[msg_id]
    if not nm_info then return nil, nil, nil, nil, 2 end

    local lock_info = nm_info.lock_info

    if not msg_tbl then return nil, nil, lock_info, nm_info.recv_func, 3 end
    if not nm_info.encode_proto then return nil, nil, lock_info, nm_info.recv_func, 4 end

    local msg = protobuf.encode( nm_info.encode_proto, msg_tbl )
    if msg then
        return msg, #msg, lock_info, nm_info.recv_func, 5
    else
        return nil, nil, lock_info, nm_info.recv_func, 6
    end
end

local lock_name_list = {}

-- 发送前处理的函数
local function sendNetMsgPreviousFunc( lock_info )
    if lock_info and lock_info.flag then
        return
    end

    if lock_info then
        table.insert(lock_name_list,lock_info.lock_name)
    end

    -- 锁屏
    time_out_lock_info = lock_info
    if lock_info and lock_info.lock_name and lock_scene_func then lock_scene_func( lock_info ) end

    -- 设置超时
    if time_out_handle then unCommonSchedule( time_out_handle ) end
    time_out_handle = schedule_once_time( time_out_interval, function()
        time_out_handle = nil

        -- 超时处理函数
        if time_out_call_back_func then time_out_call_back_func() end
    end)
end

-- 接收到后处理的函数
local function recvNetMsgAfterFunc( lock_info )
    if lock_info and lock_info.flag then
        return
    end

    if lock_info then
        for k, v in pairs(lock_name_list) do
            if v == lock_info.lock_name then
                table.remove(lock_name_list,k)
            end
        end
    end

    if table.isEmpty(lock_name_list) then
        -- 超时
        if time_out_handle then
            unCommonSchedule( time_out_handle )
            time_out_handle = nil
        end
    end

    if lock_info and lock_info.lock_name and unlock_scene_func then unlock_scene_func( lock_info ) end
    time_out_lock_info = nil

    if time_out_clean_call_back_func then time_out_clean_call_back_func() end
end

function setLockSceneFunc( lock_func, unlock_func, clear_all_func, socket_disconnected_func )
    lock_scene_func = lock_func
    unlock_scene_func = unlock_func
    clear_all_lock_scene_func = clear_all_func
    handle_socket_disconnected_func = socket_disconnected_func
end

function setTimeOutCallbackFunc( interval, time_out_func, time_out_clean_func )
    time_out_interval = interval
    time_out_call_back_func = time_out_func
    time_out_clean_call_back_func = time_out_clean_func
end

function resetTimeOut( is_cancel )
    if is_cancel then
        -- 超时
        if time_out_handle then
            unCommonSchedule( time_out_handle )
            time_out_handle = nil
        end

        if time_out_lock_info and unlock_scene_func then unlock_scene_func( time_out_lock_info ) end
        time_out_lock_info = nil
    else
        -- 设置超时
        if time_out_handle then unCommonSchedule( time_out_handle ) end
        time_out_handle = schedule_once_time( time_out_interval, function()
            time_out_handle = nil

            -- 超时处理函数
            if time_out_call_back_func then time_out_call_back_func() end
        end)
    end
end

function registerHTTPNetMsg( msg_id, encode_proto, decode_proto, recv_func, lock_info )
    net_msg_info[msg_id] = {
        encode_proto = encode_proto,
        decode_proto = decode_proto,
        lock_info = lock_info,
        recv_func = recv_func,
    }
end

function sendHTTPNetMsg( msg_id, msg_tbl, call_back_func, err_call_back_func )
    local msg,len,lock_info,recv_func = encode_msg( msg_id, msg_tbl )

    __write_msg_id__( msg_id, true, msg_tbl )

    -- 发送前处理一下
    sendNetMsgPreviousFunc( lock_info )

    -- 
    TLHttpClient:sharedHttpClient():sendMsg( msg_id, function( msg_content, http_code, error_code, error_msg )
        if http_code ~= 200 then
            __write_msg_id__( msg_id, false, { http_code = http_code, error_code = error_code, error_msg = error_msg } )

            -- 重连 session 的时候，如果失败了，不需要处理 error code，如果需要处理的话，由 err_call_back_func 自己处理
            if msg_id ~= NetMsgID.SESSION_RECONNECT then handleHttpErrorCode( msg_id, http_code, error_code, error_msg ) end

            if err_call_back_func then err_call_back_func( msg_id, http_code, error_code, error_msg ) end
        else
            local ret_tbl = decode_msg( msg_id, msg_content, #msg_content )
            __write_msg_id__( msg_id, false, ret_tbl )
            if recv_func ~= nil then recv_func( ret_tbl ) end

            if call_back_func then call_back_func( ret_tbl ) end
        end

        -- 接收后处理一下
        recvNetMsgAfterFunc( lock_info )
    end, '', '', msg, len )
end

function sendHTTPNetMsgEx( url, content_type, msg_data, call_back_func )
    TLHttpClient:sharedHttpClient():sendMsg( -1, function( msg_content, http_code, error_code, error_msg )
        CCLuaLog( string.format( 'sendHTTPNetMsgEx url : %s | http_code : %s | error_code : %s | error_msg : %s', tostring( url ), tostring( http_code ), tostring( error_code ), tostring( error_msg ) ) )
        if call_back_func then call_back_func( msg_content, http_code, error_code, error_msg ) end
    end, url, content_type, msg_data, #msg_data )
end

-- 所有需要消耗的都不重新发送
function registerNetMsg( msg_id, encode_proto, decode_proto, recv_func, lock_info, need_resend )
    net_msg_info[msg_id] = {
        encode_proto = encode_proto,
        decode_proto = decode_proto,
        lock_info = lock_info
    }

    local origin_recv_func = recv_func
    recv_func = function( ret_tbl )
        __write_msg_id__( msg_id, false, ret_tbl )

        if origin_recv_func then origin_recv_func( ret_tbl ) end
    end

    if recv_func then
        CNetReceiver:SharedNetReceiver():RegisterMsgProcessFuncPtr( msg_id, function( msg )
            local ret_tbl = decode_msg( msg_id, msg:GetContentData(), msg:GetContentLength() )
            recv_func( ret_tbl )

            -- 对 msg id 的监听
            for listen_msg_cb,_ in pairs( listen_msg_id_call_back_func ) do listen_msg_cb( msg_id ) end
        end)
    end

    -- 所有需要消耗的都不重新发送
    if need_resend and CNetSender:SharedNetSender().appendResendMsgID then
        CNetSender:SharedNetSender():appendResendMsgID( msg_id )
    end
end

function sendNetMsg( msg_id, msg_tbl, call_back_func )
    local msg,len,lock_info,_,err = encode_msg( msg_id, msg_tbl )

    if lock_info and lock_info.init then
        lock_info:init(msg_tbl)
    end

    __write_msg_id__( msg_id, true, msg_tbl )

    -- 发送前处理一下
    sendNetMsgPreviousFunc( lock_info )

    -- send
    CNetSender:SharedNetSender():NewNetMsgAndSend( msg_id, msg, len or 0, function( msg )
        local ret_tbl = decode_msg( msg_id, msg:GetContentData(), msg:GetContentLength() )

        if call_back_func then call_back_func( ret_tbl ) end

        -- 接收后处理一下
        recvNetMsgAfterFunc( lock_info )

        -- 对 msg id 的监听
        for listen_msg_cb,_ in pairs( listen_msg_id_call_back_func ) do listen_msg_cb( msg_id ) end
    end)
end

function reconnectionClearMsgIDS( all_clear_msg_ids )
    for _,msg_id in ipairs( all_clear_msg_ids or {} ) do
        local _,_,lock_info,_,_ = encode_msg( msg_id, nil )
        if lock_info then recvNetMsgAfterFunc( lock_info ) end
    end
end

function listenMsgID( call_back_func )
    listen_msg_id_call_back_func[call_back_func] = 1
end

function unlistenMsgID( call_back_func )
    listen_msg_id_call_back_func[call_back_func] = nil
end

function try_connect_server( ip, port, call_back_func )
    -- 先把上一次的关闭
    if CNetSender:SharedNetSender():getSocketStatus() == NWTS_CONNECTED then
        CNetSender:SharedNetSender():CloseSocket( NWTS_CLOSED )
    end

    -- 保存当前连接的 IP 和端口
    server_ip = ip
    server_port = port

    -- 注册连接成功后的回调
    CNetReceiver:SharedNetReceiver():RegisterMsgErrorFuncPtr( NWTC_SOCKET_CONNECT_SUCCESS, function()
        CNetReceiver:SharedNetReceiver():RegisterMsgErrorFuncPtr( NWTC_SOCKET_CONNECT_SUCCESS, function() end )

        call_back_func()
    end)

    CNetSender:SharedNetSender():Connect( ip, port )
end

function initHandleDefaultError( msg )
    local msg_id = msg:GetMsgID()
    local err_code = msg:GetMsgCode()
    local err_str = msg:GetContentStr()

    local real_msg_id = getRealMsgID( msg_id )

    -- 解锁
    local nm_info = net_msg_info[real_msg_id]
    if nm_info and nm_info.lock_info then
        recvNetMsgAfterFunc( nm_info.lock_info )
    end

    CCLuaLog( string.format( ' msg_id = %s\n real_msg_id = %s\n err_code = %s\n err_str = %s', tostring( msg_id ), tostring( real_msg_id ), tostring( err_code ), tostring( err_str ) ) )
    if g_welcome_loading_obj then
        g_welcome_loading_obj:cancel()
    end

    if g_request_fight_loading_obj then
        g_request_fight_loading_obj:cancel()
    end
end

function handleDefaultError( msg )
    initHandleDefaultError(msg)

    local msg_id = msg:GetMsgID()
    local err_code = msg:GetMsgCode()
    local err_str = msg:GetContentStr()
    local real_msg_id = getRealMsgID( msg_id )
    openErrorByErrorCode( err_code, real_msg_id, err_str )
end

function handleSocketDisconnected( err_code, msg_id, reason )
    CCLuaLog( string.format( ' err_code : %s\n msg_id : %s\n reason : %s', tostring( err_code ), tostring( msg_id ), tostring( reason ) ) )
    if time_out_handle then
        unCommonSchedule( time_out_handle )
        time_out_handle = nil
    end

    schedule_once( function()
        if handle_socket_disconnected_func then handle_socket_disconnected_func() end

        if clear_all_lock_scene_func then clear_all_lock_scene_func() end
        TLWindowManager:SharedTLWindowManager():clearAllLock()

        lock_name_list = {}

        if err_code then openErrorByErrorCode( err_code, msg_id, reason ) end
    end, 'PAUSE' )
end

function handleHttpErrorCode( msg_id, http_code, error_code, error_msg )
    if http_code == 500 then CCLuaLog( 'http code : 500 ( 服务器报错 ! )' ) end
    CCLuaLog( string.format( 'handleHttpErrorCode msg_id : %s | http_code : %s | error_code : %s | error_msg : %s', tostring( msg_id ), tostring( http_code ), tostring( error_code ), tostring( error_msg ) ) )

    local err_code = tonumber( error_code )
    if err_code then openErrorByErrorCode( err_code, msg_id, error_msg ) end
end

function openErrorByErrorCode( errorCode, msgId, reason )
    require 'config.errcode'
    -- require 'win.message_box'
    -- require 'win.General.floatTips'
    local errInfo = errcodes[errorCode]
    if not reason or #reason == 0 then
        reason = errInfo and errInfo.tips or ''
    end

    CCLuaLog( '------------------ error ------------------' )
    CCLuaLog( '------------------ error ------------------' )
    CCLuaLog( string.format( 'errorCode : (%s)', tostring( errorCode ) ) )
    CCLuaLog( string.format( 'msgId     : (%s)', tostring( msgId ) ) )
    CCLuaLog( string.format( 'reason    : (%s)', tostring( reason ) ) )

    require 'gamecommon.floatTips'
    if reason and reason ~= '' then
        showFloatTip( reason )
    else
        showFloatTip( string.format( _YYTEXT('网络错误，错误代码：(%s:%s)'), tostring( errorCode ), tostring( msgId ) ) )
    end

    --[[
    if errInfo ~= nil then
        local __handle_type__ = {
            [__ERROR_CODE_STYLE__.WARNNING_WIN] = function()
                openMessageBox( '', reason, 'MB_OK', {
                    MB_LAYER = function()
                        return layer_type_mask
                    end,
                    MB_LAYERORDER = function()
                        return 5001
                    end,
                })
            end,

            [__ERROR_CODE_STYLE__.FLOAT_STRING] = function()
                require 'win.General.floatTips'
                showFloatTip(reason)
            end,
        }
        -- 288 是服务器定义的要飘字的消息id
        if msgId == 288 then errInfo.errorType = __ERROR_CODE_STYLE__.FLOAT_STRING end
        __handle_type__[errInfo.errorType or __ERROR_CODE_STYLE__.WARNNING_WIN]()
    else
        showFloatTip( string.format( 'Undeclared error code : [%s(%s)]', tostring( errorCode ), tostring(msgId) ) )
    end
    --]]
end


