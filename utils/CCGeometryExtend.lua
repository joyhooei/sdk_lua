--./cocos2dx/CCGeometryExtend.lua
require 'utils.class'

local cc_point = CCPoint
local cc_size = CCSize
local cc_rect = CCRect
local get_bounding_box = getBoundingBox

getBoundingBox = function( ... )
    return CCRectExtend.extend( get_bounding_box( ... ) )
end

CCRect = function( ... )
    return CCRectExtend.extend( cc_rect( ... ) )
end

CCRectExtend = class( 'CCRectExtend' )
--CCRectExtend.__index = CCRectExtend

function CCRectExtend.extend( target )
    local t = tolua.getpeer( target )
    if t and t.is_valid then
        return target
    end

    t = {
        --rect_ref = target,
        x = target.origin.x,
        y = target.origin.y,
        width = target.size.width,
        height = target.size.height,
    }

    tolua.setpeer( target, t )

    setmetatable( t, CCRectExtend )

    return target
end

function CCRectExtend.__index( t_rect, k_rect )
    if k_rect == 'size' then
        local ret_size = cc_size( t_rect.width, t_rect.height )
        local vs = {}
        tolua.setpeer( ret_size, vs )
        setmetatable( vs, {
            __newindex = function( t_size, k_size, v_size )
                if k_size == 'width' then
                    t_size.width = v_size
                    t_rect.width = v_size
                    --t_rect.rect_ref.size.width = v_size
                end
                if k_size == 'height' then
                    t_size.height = v_size
                    t_rect.height = v_size
                    --t_rect.rect_ref.size.height = v_size
                end
            end,
        })
        return ret_size
    end
    if k_rect == 'origin' then
        local ret_point = cc_point( t_rect.x, t_rect.y )
        local vp = {}
        tolua.setpeer( ret_point, vp )
        setmetatable( vp, {
            __newindex = function( t_point, k_point, v_point )
                if k_size == 'x' then
                    t_point.x = v_point
                    t_rect.x = v_point
                    --t_rect.rect_ref.origin.x = v_point
                end
                if k_size == 'y' then
                    t_point.y = v_point
                    t_rect.y = v_point
                    --t_rect.rect_ref.origin.y = v_point
                end
            end,
        })
        return ret_point
    end
end

function CCRectExtend.__newindex( t_rect, k_rect, v_rect )
    if k_rect == 'size' then
        t_rect.width = v_rect.width
        t_rect.height = v_rect.height
        --t_rect.rect_ref.size.width = v_rect.width
        --t_rect.rect_ref.size.height = v_rect.height

        local vs = {}
        tolua.setpeer( v_rect, vs )
        setmetatable( vs, {
            __newindex = function( t_size, k_size, v_size )
                if k_size == 'width' then
                    t_size.width = v_size
                    t_rect.width = v_size
                    --t_rect.rect_ref.size.width = v_size
                end
                if k_size == 'height' then
                    t_size.height = v_size
                    t_rect.height = v_size
                    --t_rect.rect_ref.size.height = v_size
                end
            end,
        })
    end

    if k_rect == 'origin' then
        t_rect.x = v_rect.x
        t_rect.y = v_rect.y
        --t_rect.rect_ref.origin.x = v_rect.x
        --t_rect.rect_ref.origin.y = v_rect.y

        local vp = {}
        tolua.setpeer( v_rect, vp )
        setmetatable( vp, {
            __newindex = function( t_point, k_point, v_point )
                if k_point == 'x' then
                    t_point.x = v_point
                    t_rect.x = v_point
                    --t_rect.rect_ref.origin.x = v_point
                end
                if k_point == 'y' then
                    t_point.y = v_point
                    t_rect.y = v_point
                    --t_rect.rect_ref.origin.y = v_point
                end
            end,
        })
    end
end

