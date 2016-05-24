-- ./login/boot_check_server_list.lua

local __boot_check_server_list = class( 'bc_server_list', __boot_check_base )
function __boot_check_server_list:ctor( boot_win )
    __boot_check_base.ctor( self, boot_win )
end

function __boot_check_server_list:execute( call_back_func )
    self.check_state = 'check_success'
    if true then return call_back_func() end

    local account = PlayerConfig.getAccountName()

    registerHTTPNetMsg( NetMsgID.REGION_LIST, 'poem.RequestRegionList', 'poem.RegionList' )
    sendHTTPNetMsg( NetMsgID.REGION_LIST, { sdkType = GetSdkTypeLua(), username = account, deviceInfo = g_device_obj:getDeviceInfo() }, function( recv_tbl )
        g_server_list = recv_tbl.regions
        pdump( 'g_server_list', g_server_list )

        if g_server_list == nil or #g_server_list == 0 then
            self.check_state = 'check_failed'
        else
            self.check_state = 'check_success'
        end
        call_back_func()
    end, function( msg_id, http_code, error_code, error_msg )
        self.check_state = 'check_failed'
        call_back_func()
    end)
end

return __boot_check_server_list
