-- ./launch/show_logo.lua

function showLogo( logo_index, call_back_func )
    local logo_info = g_device_obj.logo_list[logo_index]
    if not logo_info then return call_back_func() end

    require 'utils.CCNodeExtend'
    local logo_sprite = CCNodeExtend.extend( MCLoader:sharedMCLoader():loadSprite( logo_info.fileName ) )
    logo_sprite:setPosition( g_device_obj:getCenterPos() )
    g_device_obj.root_scene_node:addChild( logo_sprite, logo_index )

    logo_sprite:tweenFromToOnce( LINEAR_IN, NODE_PRO_NULL, 0, logo_info.duration, 0, 0, function()
        showLogo( logo_index + 1, call_back_func )
    end)
end

function asyncAffair( affair_index, call_back_func )
    local affair_func = g_device_obj.affair_list[affair_index]
    if not affair_func then return call_back_func() end

    affair_func()

    schedule_once_time( 0.017, function()
        asyncAffair( affair_index + 1, call_back_func )
    end)
end

local show_logo_flag = false
local async_affair_flag = false
function showLogoAndAsyncAffairList( call_back_func )
    show_logo_flag = false
    async_affair_flag = false

    local function __real_cb__()
        if show_logo_flag and async_affair_flag then
            if call_back_func then call_back_func() end
            show_logo_flag = false
            async_affair_flag = false
        end
    end

    -- 
    showLogo( 1, function()
        show_logo_flag = true
        __real_cb__()
    end)

    -- 
    asyncAffair( 1, function()
        async_affair_flag = true
        __real_cb__()
    end)
end
