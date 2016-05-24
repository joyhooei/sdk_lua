-- ./common/guide_manager.lua

all_guide_data = { }

guide_manager = {
    all_saved_guide_type = {},
    guide_win = nil,
    guide_frame = nil,
}

function guide_manager:startGuide( guide_type, guide_index )
    if self:isSavedGuideType( guide_type ) then return end

    if self.guide_type then return end

    local guide_type_data = all_guide_data[guide_type]
    if not guide_type_data then return end

    guide_index = guide_index or 1
    local guide_data = guide_type_data[guide_index]
    if not guide_data then return end

    self.guide_type = guide_type
    self.guide_type_data = guide_type_data
    self.cur_guide_index = guide_index
    self.guide_data = guide_data

    self:openGuideWindow( guide_data )
end

function guide_manager:endGuide( next_guide_immediate )
    local guide_type = self.guide_type
    local next_guide_index = self.cur_guide_index + 1

    -- 如果还有后续的引导的话，在下一帧触发
    -- 没有的话，就保存状态
    if self.guide_type_data[next_guide_index] then
        if next_guide_immediate then
            TLWindowManager:SharedTLWindowManager():lockScreen( 'NEXT_GUIDE_LOCK' )
            schedule_once( function()
                self:startGuide( guide_type, next_guide_index )
                TLWindowManager:SharedTLWindowManager():unlockScreen( 'NEXT_GUIDE_LOCK' )
            end)
        end
    else
        self:saveGuide( guide_type )
    end

    -- 清理
    self:cancelGuide()

    return guide_type, next_guide_index
end

function guide_manager:cancelGuide()
    -- 如果使用了蒙黑的话，就要取消蒙黑
    if self.guide_data and self.guide_data.screen_color then
        TLMaskLayer:sharedTLMaskLayer():resetMaskLayer()
    end

    self:closeGuideWindow()

    -- 
    self.guide_type = nil
    self.guide_type_data = nil
    self.cur_guide_index = nil
    self.guide_data = nil
end

function guide_manager:onResponseGuideType( msg_tbl )
    self.all_saved_guide_type = {}

    for _,guide_type in ipairs( msg_tbl.guide_types or {} ) do
        self.all_saved_guide_type[guide_type] = 1
    end
end


function guide_manager:isSavedGuideType( guide_type )
    if not g_player or g_player.skip_guide then return true end

    return self.all_saved_guide_type[guide_type] and true or false
end

function guide_manager:saveGuideLocal( guide_type )
    self.all_saved_guide_type[guide_type] = 1
end

function guide_manager:saveGuide( guide_type )
    self:saveGuideLocal( guide_type )

    -- 引导不需要保存，这里往往是需要该引导与对应的一个操作同时保存
    -- 这个对应的操作，会在请求服务器的时候，把这个guide_type一同发送给服务器处理的
    if self.guide_data and self.guide_data.do_not_save then return end

    registerNetMsg( NetMsgID.GUIDE_TYPE_END, 'poem.guideEnd', nil, nil, nil, true )
    sendNetMsg( NetMsgID.GUIDE_TYPE_END, { guide_type = guide_type } )
end

local content_type = {
    ['force'] = function( self, v, index )
        local force_win, force_frame, force_rect = v.init_force_frame()

        local x = force_rect.origin.x + force_rect.size.width / 2 - self.guide_frame.mcBoundingBox.size.width / 2
        local y = force_rect.origin.y + force_rect.size.height / 2 - self.guide_frame.mcBoundingBox.size.height / 2
        force_frame:setPosition( x, y )
        self.guide_frame:addChild( force_frame )

        if force_win then
            force_win:SetWindowName( string.format( 'force_window_%d', index ) )
            self.guide_win:AddChildWindow( force_win )
        end

        return force_rect
    end,
    ['func'] = function( self, v, index )
        local node = v.call_func()
        self.guide_frame:addChild( node )
    end,
}

function guide_manager:openGuideWindow( guide_data )
    if not toTLWindow( self.guide_win ) then
        self.guide_win, self.guide_frame = create_frame_top_window_by_size( all_scene_layers[layer_type_mask], nil, nil, nil, 'guide_window' )
    end

    self.guide_win:SetIsVisible( true )
    TLWindowManager:SharedTLWindowManager():SetGuideWindow( self.guide_win )

    -- 焦点区域
    local force_rect_list = {}
    for i,v in ipairs( guide_data.contents or {} ) do
        local ret_val = content_type[v.c_type]( self, v, i )
        if v.c_type == 'force' then table.insert( force_rect_list, ret_val ) end
    end

    if guide_data.screen_color then
        TLMaskLayer:sharedTLMaskLayer():resetMaskLayer()
        TLMaskLayer:sharedTLMaskLayer():setIsMaskScene( true )

        -- 蒙黑使用的颜色
        local r = guide_data.screen_color[1] or 0
        local g = guide_data.screen_color[2] or 0
        local b = guide_data.screen_color[3] or 0
        local a = guide_data.screen_color[4] or 0.8
        TLMaskLayer:sharedTLMaskLayer():setMaskColor( r, g, b, a )

        -- 最多两个蒙黑的区域
        if force_rect_list[1] then TLMaskLayer:sharedTLMaskLayer():appendHighlightRect( force_rect_list[1] ) end
        if force_rect_list[2] then TLMaskLayer:sharedTLMaskLayer():appendHighlightRect2( force_rect_list[2] ) end
    end
end

function guide_manager:closeGuideWindow()
    if toTLWindow( self.guide_win ) then
        TLWindowManager:SharedTLWindowManager():SetGuideWindow()
        self.guide_win:SetIsVisible( false )
    end
end

function guide_manager:getForceNodeOffset( force_node, relative_point )
    local box = getBoundingBox( force_node )
    local pos = force_node:convertToWorldSpace( CCPoint( 0, 0 ) )

    local shrink_x = box.size.width * 0.2
    local shrink_y = box.size.height * 0.2

    local relative_point_func = {
        ['left'] = function()
            return pos.x - box.size.width - self.guide_frame.mcBoundingBox.size.width / 2 + shrink_x, pos.y - self.guide_frame.mcBoundingBox.size.height / 2
        end,
        ['top'] = function()
            return pos.x - self.guide_frame.mcBoundingBox.size.width / 2, pos.y + box.size.height - self.guide_frame.mcBoundingBox.size.height / 2 - shrink_y
        end,
        ['bottom'] = function()
            return pos.x - self.guide_frame.mcBoundingBox.size.width / 2, pos.y - box.size.height - self.guide_frame.mcBoundingBox.size.height / 2 + shrink_y
        end,
        ['center'] = function()
            return pos.x - self.guide_frame.mcBoundingBox.size.width / 2, pos.y - self.guide_frame.mcBoundingBox.size.height / 2
        end,
    }

    return relative_point_func[relative_point]()
end

function guide_manager:getForceRect( btn_info )
    local box = getBoundingBox( btn_info.node )

    local pos = btn_info.node:convertToWorldSpace( CCPoint( 0, 0 ) )
    pos.x = pos.x - box.size.width * 0.5
    pos.y = pos.y - box.size.height * 0.5

    return CCRect( pos.x, pos.y, box.size.width, box.size.height )
end

function guide_manager:createForceFrame( btn_info, win_flag )
    local box = getBoundingBox( btn_info.node )

    local box_width = math.abs( box.size.width )
    local box_height = math.abs( box.size.height )
    local box_x = -box_width * 0.5
    local box_y = -box_height * 0.5
    local force_box = CCRect( box_x, box_y, box_width, box_height )
    local force_frame = MCFrame:createWithBox( force_box )

    local pos = btn_info.node:convertToWorldSpace( CCPoint( 0, 0 ) )
    pos.x = pos.x - box.size.width * 0.5
    pos.y = pos.y - box.size.height * 0.5
    local ret_rect = CCRect( pos.x, pos.y, box.size.width, box.size.height )

    local force_win = TLWindow:createWindow( force_frame, win_flag or TL_WINDOW_UNIVARSAL )
    init_simple_button( force_win, function()
        local lock_name = 'GUIDE_MANAGER_' .. self.guide_type .. '_' .. self.cur_guide_index
        TLWindowManager:SharedTLWindowManager():lockScreen( lock_name )
        local guide_type, next_guide_index = self:endGuide( false )
        btn_info.onClickFunc( function()
            self:startGuide( guide_type, next_guide_index )
            TLWindowManager:SharedTLWindowManager():unlockScreen( lock_name )
        end)
    end)

    return force_win, force_frame, ret_rect
end

function guide_manager:createDropDragFrame( node )
    local box = getBoundingBox( node )
    local dd_frame = MCFrame:createWithBox( box )

    local pos = node:convertToWorldSpace( CCPoint( 0, 0 ) )
    pos.x = pos.x - box.size.width * 0.5
    pos.y = pos.y - box.size.height * 0.5
    local ret_rect = CCRect( pos.x, pos.y, box.size.width, box.size.height )

    local dd_win = TLWindow:createWindow( dd_frame, TL_WINDOW_DRAG_DROP )

    local x = ret_rect.origin.x + ret_rect.size.width / 2 - self.guide_frame.mcBoundingBox.size.width / 2
    local y = ret_rect.origin.y + ret_rect.size.height / 2 - self.guide_frame.mcBoundingBox.size.height / 2
    dd_frame:setPosition( x, y )

    self.guide_frame:addChild( dd_frame )
    self.guide_win:AddChildWindow( dd_win )

    return init_dragdropstandard( dd_win, TL_WINDOW_DRAG_DROP )
end

signal.listen( 'SYSTEM_PURGE_SCENE', function()
    guide_manager:cancelGuide()

    guide_manager.all_saved_guide_type = {}
    guide_manager.guide_win = nil
    guide_manager.guide_frame = nil
end)
