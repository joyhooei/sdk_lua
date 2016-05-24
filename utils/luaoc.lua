-- lua 调用 Objective-C

local luaoc = {}

function luaoc.callStaticMethod(className, methodName, args)
    if CCLuaObjcBridge then
        return CCLuaObjcBridge.callStaticMethod(className, methodName, args)
    else
        CCLuaLog('>>> CCLuaObjcBridge not support yet.')
    end
end

return luaoc
