-- ./launch/device_ios.lua

local device_base_obj = require 'launch.device_base'
local __device_ios = class( 'device_ios', device_base_obj )
function __device_ios:ctor()
    device_base_obj.ctor( self )
end

function __device_ios:init()
    device_base_obj.init( self )
end

function __device_ios:getUniqueDeviceID()
    if getMAC() and getMAC() ~= "" then
        return getMAC()  
    else
        return getidfa()
    end
end

return __device_ios
