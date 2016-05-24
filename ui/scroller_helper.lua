-- ./ui/scroller_helper.lua
require 'ui.scroller'

-------------------------------------------------------------------------------------------------------------------------------------
__scroller_helper = class( 'scroller_helper' )
function __scroller_helper:ctor( container )
    self.container = container
end

function __scroller_helper:append( childWin, relayout )
    self.container:append( childWin, relayout )
end

function __scroller_helper:insert( childWin, index, relayout )
    self.container:insert( childWin, index, relayout )
end

function __scroller_helper:scrollEnable( enable )
    self.container:scrollEnable( enable )
end

function __scroller_helper:layout()
    self.container:layout()
end

function __scroller_helper:removeall()
    self.container:removeall()
end

function __scroller_helper:stop()
    self.container:stop()
end

-------------------------------------------------------------------------------------------------------------------------------------
local __anim_style__ = {
    ['LEFT_RIGHT'] = {
        enter_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.enter_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = -scroller_helper_self.offset_x + node_anim_info.origin_x
            local to = node_anim_info.origin_x
            node_anim_info.node:setPositionX( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_X, delay, duration, from, to, call_back_func )
        end,
        exit_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.exit_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = node_anim_info.origin_x
            local to = scroller_helper_self.offset_x + node_anim_info.origin_x
            node_anim_info.node:setPositionX( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_X, delay, duration, from, to, call_back_func )
        end,
    },
    ['RIGHT_LEFT'] = {
        enter_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.enter_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = scroller_helper_self.offset_x + node_anim_info.origin_x
            local to = node_anim_info.origin_x
            node_anim_info.node:setPositionX( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_X, delay, duration, from, to, call_back_func )
        end,
        exit_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.exit_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = node_anim_info.origin_x
            local to = scroller_helper_self.offset_x + node_anim_info.origin_x
            node_anim_info.node:setPositionX( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_X, delay, duration, from, to, call_back_func )
        end,
    },
    ['TOP_BOTTOM'] = {
        enter_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.enter_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = scroller_helper_self.offset_y + node_anim_info.origin_y
            local to = node_anim_info.origin_y
            node_anim_info.node:setPositionY( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_Y, delay, duration, from, to, call_back_func )
        end,
        exit_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.exit_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = node_anim_info.origin_y
            local to = -scroller_helper_self.offset_y + node_anim_info.origin_y
            node_anim_info.node:setPositionY( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_Y, delay, duration, from, to, call_back_func )
        end,
    },
    ['BOTTOM_TOP'] = {
        enter_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.enter_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = -scroller_helper_self.offset_y + node_anim_info.origin_y
            local to = node_anim_info.origin_y
            node_anim_info.node:setPositionY( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_Y, delay, duration, from, to, call_back_func )
        end,
        exit_func = function( scroller_helper_self, node_anim_info, index, call_back_func )
            local ease_id = node_anim_info.anim_info.exit_ease_id or LINEAR_IN
            local delay = ( node_anim_info.anim_info.delay or 0.1 ) * index
            local duration = scroller_helper_self.duration
            local from = node_anim_info.origin_y
            local to = -scroller_helper_self.offset_y + node_anim_info.origin_y
            node_anim_info.node:setPositionY( from )
            node_anim_info.node:tweenFromToOnce( ease_id, NODE_PRO_Y, delay, duration, from, to, call_back_func )
        end,
    },
}
__scroller_helper_anim_layout_removeall = class( 'scroller_helper_anim_layout_removeall', __scroller_helper )
function __scroller_helper_anim_layout_removeall:ctor( container, duration, offset_x, offset_y, max_exit_count, auto_inc )
    __scroller_helper.ctor( self, container )

    self.duration = duration
    self.offset_x = offset_x
    self.offset_y = offset_y

    self.max_exit_count = max_exit_count or 5

    self.total_node_count = 0
    self.cur_max_batch_index = 1
    self.auto_inc = auto_inc
    self.anim_nodes = {}
end

function __scroller_helper_anim_layout_removeall:_insert_anim_node( childWin, anim_info )
    if not anim_info then return end
    local _anim_info = table.copy(anim_info) --FIXME 浅拷贝

    _anim_info.batch_index = anim_info.batch_index and anim_info.batch_index or self.cur_max_batch_index
    if _anim_info.batch_index > self.cur_max_batch_index then self.cur_max_batch_index = _anim_info.batch_index end

    if self.auto_inc then self.cur_max_batch_index = self.cur_max_batch_index + 1 end

    if self.anim_nodes[_anim_info.batch_index] == nil then self.anim_nodes[_anim_info.batch_index] ={} end

    local node = ( ( tolua.type( childWin ) == 'TLWindow' ) and childWin:GetNode() or childWin )
    local node_info = { node = CCNodeExtend.extend( node ), anim_info = _anim_info, }
    table.insert( self.anim_nodes[_anim_info.batch_index], node_info )
    self.total_node_count = self.total_node_count + 1

end

function __scroller_helper_anim_layout_removeall:append( childWin, relayout, anim_info )
    self.container:append( childWin, relayout )

    local index = self.container.sort_dict:getElementCount()
    self:_insert_anim_node( childWin, anim_info )
end

function __scroller_helper_anim_layout_removeall:insert( childWin, index, relayout, anim_info )
    self.container:insert( childWin, index, relayout )

    self:_insert_anim_node( childWin, anim_info )
end

function __scroller_helper_anim_layout_removeall:layout( call_back_func, pos )
    self.container:layout( pos )

    local function __layout_end()
        if call_back_func then call_back_func() end
    end

    if self.total_node_count <= 0 then return __layout_end() end

    local counter = 0
    for _,v in ipairs( self.anim_nodes ) do
        for _,node_anim_info in ipairs( v ) do
            if node_anim_info.node:isVisible() then counter = counter + 1 end
        end
    end

    local enter_index = 1
    for i,v in ipairs( self.anim_nodes ) do
        local flag = false
        for j,node_anim_info in ipairs( v ) do
            node_anim_info.origin_x, node_anim_info.origin_y = node_anim_info.node:getPosition()              -- 每次 layout 后，都重新保存一下
            if node_anim_info.node:isVisible() then
                local temp_enter_func = node_anim_info.anim_info.enter_func or __anim_style__[node_anim_info.anim_info.anim_style].enter_func
                temp_enter_func( self, node_anim_info, enter_index, function()
                    counter = counter - 1
                    if counter <= 0 then
                        __layout_end()
                    end
                end)

                flag = true
            end
        end

        if flag then enter_index = enter_index + 1 end
    end
end

function __scroller_helper_anim_layout_removeall:layout2()
    self.container:layout()
    for i,v in ipairs( self.anim_nodes ) do
        for j,node_anim_info in ipairs( v ) do
            if not node_anim_info.origin_x then
                node_anim_info.origin_x, node_anim_info.origin_y = node_anim_info.node:getPosition()
            end
        end
    end
end

function __scroller_helper_anim_layout_removeall:removeall( call_back_func )
    local counter = 0
    local function __real_remove_all()
        self.total_node_count = 0
        self.anim_nodes = {}
        self.cur_max_batch_index = 1

        self.container:removeall()

        if call_back_func then call_back_func() end
    end

    if self.total_node_count <= 0 then return __real_remove_all() end

    for _,v in ipairs( self.anim_nodes ) do
        for _,node_anim_info in ipairs( v ) do
            if node_anim_info.node:isVisible() then counter = counter + 1 end
        end
    end

    local exit_index = 1
    for i,v in ipairs( self.anim_nodes ) do
        local flag = false
        for j,node_anim_info in ipairs( v ) do
            if node_anim_info.node:isVisible() then
                local temp_exit_func = node_anim_info.anim_info.exit_func or __anim_style__[node_anim_info.anim_info.anim_style].exit_func
                temp_exit_func( self, node_anim_info, exit_index, function()
                    counter = counter - 1
                    if counter <= 0 then
                        __real_remove_all()
                    end
                end)

                flag = true
            end
        end

        if flag then exit_index = exit_index + 1 end
    end
end


