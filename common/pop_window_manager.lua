-- ./utils/pop_window_manager.lua

local all_pop_module_obj = {}

function openModulePopWindow( module_name, open_cb, ... )
    if not all_pop_module_obj[module_name] then
        all_pop_module_obj[module_name] = require(module_name).new( ... )
    end

    all_pop_module_obj[module_name]:open( open_cb, ... )

    return all_pop_module_obj[module_name]
end

function closeModulePopWindow( module_name, close_cb )
    local module_obj = all_pop_module_obj[module_name]
    if module_obj and module_obj:isAlive() then
        all_pop_module_obj[module_name] = nil
        module_obj:close( close_cb )
    else
        if close_cb then close_cb() end
    end
end

function destroyModulePopWindow( module_name )
    local module_obj = all_pop_module_obj[module_name]
    if module_obj then
        all_pop_module_obj[module_name] = nil
        module_obj:destroy()
    end
end

function getModulePopWindow( module_name )
    return all_pop_module_obj[module_name]
end

signal.listen( 'SYSTEM_PURGE_SCENE', function()
    for _, module_obj in pairs( all_pop_module_obj ) do
        module_obj:destroy()
    end
    all_pop_module_obj = {}
end)

