-- ./ui/controls_impl.lua
require 'utils.class'
require 'utils.CCNodeExtend'

local MAX_DISTANCE = 20
local winManager = TLWindowManager:SharedTLWindowManager()

__window_control = class( 'window_control' )
function __window_control:ctor( c_win, node_extend )
    self.c_win = c_win
    self.enabled = true
    self.node = node_extend and CCNodeExtend.extend( c_win:GetNode() ) or c_win:GetNode()
    self.release_cb = {}
    self.down_cb = {}
    self.up_cb = {}
    self.disable_cb = {}

    -- event
    self.down_point = nil

    local function __button_release__()
        for _,cb in ipairs( self.enabled and self.release_cb or {} ) do cb() end
        self.down_point = nil
    end

    self.c_win:RegisterEvent( TL_EVENT_BUTTON_DOWN, function()
        self.down_point = winManager:getLastPoint()
        for _,cb in ipairs( self.enabled and self.down_cb or {} ) do cb() end
    end)
    self.c_win:RegisterEvent( TL_EVENT_BUTTON_UP, function()
        if self:_is_up_event_valid() then
            for _,cb in ipairs( self.enabled and self.up_cb or self.disable_cb ) do cb() end
        else
            __button_release__()
        end
        self.down_point = nil
    end)
    self.c_win:RegisterEvent( TL_EVENT_BUTTON_RELEASE, function()
        __button_release__()
    end)
end

function __window_control:_is_up_event_valid()
    -- 不是在这个控件按下的话，不响应
    if not self.down_point then return false end

    -- 在这个控件按下，但距离按下的位置太远的话，也不响应
    local p = winManager:getLastPoint()
    if math.abs( p.x - self.down_point.x ) > MAX_DISTANCE or math.abs( p.y - self.down_point.y ) > MAX_DISTANCE then return false end

    return true
end

function __window_control:enable( b )
    self.enabled = b

    -- 'ShaderPositionTextureColor'  在 cocos2dx 内部定义的，所有的 CCSprite 默认的
    -- 'position_texture_color_gray' 在 shaders.lua 定义的，变灰
    local shader_name = b and 'ShaderPositionTextureColor' or 'position_texture_color_gray'
    local shader_program = CCShaderCache:sharedShaderCache():programForKey( shader_name )
    setNodeShaderProgram( self.node, shader_program )
end

function __window_control:addEventEffect( down_event_cb, up_event_cb, release_event_cb, disable_up_cb )
    if down_event_cb then table.insert( self.down_cb, down_event_cb ) end
    if up_event_cb then table.insert( self.up_cb, up_event_cb ) end
    if release_event_cb then table.insert( self.release_cb, release_event_cb ) end
    if disable_up_cb then table.insert( self.disable_cb, disable_up_cb ) end
end

function __window_control:useAnimEffect(subnode)
    if subnode ~= nil then
        subnode = CCNodeExtend.extend( subnode )

        -- anim button
        self:addEventEffect(function()
            subnode:tweenFromToOnce( ELASTIC_OUT, NODE_PRO_SCALE, 0, 0.4, 1, 0.9)
        end,
        function()
            subnode:removeAllTween()
            subnode:tweenFromToOnce( ELASTIC_OUT, NODE_PRO_SCALE, 0, 0.4, 0.9, 1)
        end,
        function()
            subnode:removeAllTween()
            subnode:tweenFromToOnce( ELASTIC_OUT, NODE_PRO_SCALE, 0, 0.4, 0.9, 1)
        end)
    end
end

