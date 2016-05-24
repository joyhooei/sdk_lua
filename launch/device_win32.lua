-- ./launch/device_win32.lua

local device_base_obj = require 'launch.device_base'
local __device_win32 = class( 'device_win32', device_base_obj )
function __device_win32:ctor()
    device_base_obj.ctor( self )
end

function __device_win32:push_notification(index)
end

function __device_win32:remove_all_notification()
end

function __device_win32:init()
    device_base_obj.init( self )

    -- 
    useConsole()
end

function __device_win32:initBootCheckList( boot_check_name )
    for file_name in lfs.dir( './login/' ) do
        if string.find( file_name, 'boot_check' ) and get_extension( file_name ) == 'lua' then
            local require_file_name = 'login' .. '.' .. strip_extension( file_name )
            table.insert( boot_check_name, require_file_name )
        end
    end
end

return __device_win32
