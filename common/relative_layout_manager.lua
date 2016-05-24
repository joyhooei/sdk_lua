-- Filename      : ./win32_client/common/relative_layout_manager.lua
-- Description   :
-- Last modified : 2016-03-31 14:05

--- 相对布局模块manager

local relative_layout = require 'common.relative_layout'
local all_rl_module_obj = {}

--- createRelativeLayoutModule
-- 创建相对布局模块
-- @param name 相对布局名称
-- @param rl_info 相对布局info
-- @return rl_obj
-- @usage createRelativeLayoutModule( 'name', rl_info )
-- @see relative_layout.rl_info
function createRelativeLayoutModule( name, rl_info )
    if all_rl_module_obj[ name ] then
        CCLuaLog( string.format( 'exist rl_obj named "%s", it would be destroy!', name ) )
        all_rl_module_obj[ name ]:destroy()
    end

    local rl_obj = relative_layout.new( rl_info )
    -- rl_obj:open( open_call_back )

    all_rl_module_obj[ name ] = rl_obj

    return rl_obj, name
end

function openRelativeLayoutModule( name, rl_info, open_call_back )
    local rl_obj, name = createRelativeLayoutModule( name, rl_info )

    rl_obj:open( open_call_back )

    return rl_obj, name
end

--- closeRelativeLayoutModule
-- 关闭相对布局模块，播放离场动画
-- @param name 相对布局名称
-- @param close_call_back 离场动画回调
-- @usage closeRelativeLayoutModule( 'name', function() dosomething end )
function closeRelativeLayoutModule( name, close_call_back )
    local module_obj = all_rl_module_obj[ name ]
    if module_obj then
        all_rl_module_obj[ name ] = nil
        module_obj:close( close_call_back )
    else
        if close_call_back then close_call_back() end
    end
end

--- destroyRelativeLayoutModule
-- 销毁相对布局模块
-- @param name 相对布局名称
-- @usage destroyRelativeLayoutModule( 'name' )
function destroyRelativeLayoutModule( name )
    local module_obj = all_rl_module_obj[ name ]
    if module_obj then
        all_rl_module_obj[ name ] = nil
        module_obj:destroy()
    end
end

--- getRelativeLayoutModule
-- 获取相对布局模块
-- @param name 相对布局名称
-- @return rl_obj
-- @usage  getRelativeLayoutModule( 'name' )
function getRelativeLayoutModule( name )
    return all_rl_module_obj[ name ]
end

signal.listen( 'SYSTEM_PURGE_SCENE', function()
    for _, module_obj in pairs( all_rl_module_obj ) do
        module_obj:destroy()
    end
    all_rl_module_obj = {}
end)
