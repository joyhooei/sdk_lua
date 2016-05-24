-- ./ui/gallery_pager.lua
require 'utils.stack'
require 'utils.scroll_impl1'

function gallery_pager( win, name, scroll_type, page_percent, call_func )
    local frame = assert( toFrame( win:GetNode():getChildByName( name ) ), string.format( 'not found child frame %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( frame, TL_WINDOW_SCROLL )
    win:AddChildWindow( c_win )

    local pager_obj = {
        child_nodes = stack.new(),
        scroll_unit = ( page_percent or 1 ) * ( scroll_type == TL_SCROLL_TYPE_UP_DOWN and frame.mcBoundingBox.size.height or frame.mcBoundingBox.size.width ),            -- 翻一页的高度或者宽度，相对于 frame 的高宽
        currentpage = 0,
        call_func = call_func,
    }

    -- 创建clip和容器node
    local box = copy_rect( frame.mcBoundingBox )
    local clipframe = MCFrame:createWithBox( box )
    clipframe:setClipRegion( box )
    frame:addChild( clipframe )

    local contentnode = CCNode:create()
    clipframe:addChild( contentnode )

    local button_container = CCNode:create()
    frame:addChild( button_container )

    pager_obj.impl = scroll_impl()
    if scroll_type == TL_SCROLL_TYPE_UP_DOWN then
        button_container:setPositionX( frame.mcBoundingBox.origin.x )
        function pager_obj.impl:set_position( pos )
            contentnode:setPositionY( pos )

            if pager_obj.call_func then pager_obj.call_func() end
        end
    else
        button_container:setPositionY(frame.mcBoundingBox.origin.y )
        function pager_obj.impl:set_position( pos )
            contentnode:setPositionX( pos )

            if pager_obj.call_func then pager_obj.call_func() end
        end
    end

    local animationtimer
    function pager_obj.impl:start_animation()
        if not animationtimer then
            animationtimer = CCDirector:sharedDirector():getPauseScheduler():scheduleScriptFunc( pager_obj.impl.update, 0, false )
            animationtimerMgr.add(animationtimer)
        end
    end
    function pager_obj.impl:stop_animation() pager_obj:stop() end

    function pager_obj:stop()
        if animationtimer then
            CCDirector:sharedDirector():getPauseScheduler():unscheduleScriptEntry( animationtimer )
            animationtimerMgr.delete(animationtimer)
            animationtimer = nil
        end
    end

    local winManager = TLWindowManager:SharedTLWindowManager()
    c_win:RegisterEvent( TL_EVENT_BUTTON_DOWN, function() pager_obj:touchbegin( winManager:getLastPoint() ) end )
    c_win:RegisterEvent( TL_EVENT_BUTTON_UP, function() pager_obj:touchend( winManager:getLastPoint() ) end )
    c_win:RegisterEvent( TL_EVENT_BUTTON_RELEASE, function() pager_obj:touchend( winManager:getLastPoint() ) end )
    c_win:RegisterEvent( TL_EVENT_MOUSE_MOVE, function() pager_obj:touchmove( winManager:getLastPoint() ) end )

    function pager_obj:touchbegin( point ) self.impl.touchbegin( ( scroll_type == TL_SCROLL_TYPE_UP_DOWN and point.y or point.x ) ) end
    function pager_obj:touchmove( point ) self.impl.touchmove( ( scroll_type == TL_SCROLL_TYPE_UP_DOWN and point.y or point.x ) ) end
    function pager_obj:touchend( point )
        local pp = self.impl:free_scroll_target()
        local ps = {}

        for i=1,self.child_nodes:getElementCount() do
            local page_node = self.child_nodes:getAt( i )
            local p = ( scroll_type == TL_SCROLL_TYPE_UP_DOWN and page_node:getPositionY() or page_node:getPositionX() )
            table.insert( ps, math.abs( -p - pp ) )
        end

        local mini, minv = table.min( ps )
        local page_index = setbound( mini and mini - 1 or 0, math.max( 0, self.currentpage - 1 ), math.min( self:pagecount() - 1, self.currentpage + 1 ) )
        self:scrollpage( page_index )
    end

	function pager_obj:getPosition() return self.impl.getPosition() end
    function pager_obj:append( node, relayout ) self:insert( node, -1, relayout ) end
    function pager_obj:insert( node, index, relayout )
        contentnode:addChild( node )

        self.child_nodes:insert( index, node )

        if relayout then self:layout() end
    end
    function pager_obj:remove( node, relayout )
        contentnode:removeChild( node, true )
        self.child_nodes:pop( node )

        local scroll_to_offset = self:getPosition()
        if relayout then
            self:layout()
            self:scrollto( scroll_to_offset )
        end
    end
    function pager_obj:removeall()
        contentnode:removeAllChildrenWithCleanup( true )
        self.child_nodes:clear()
        self:setContentSize( 0, 0 )
        self:stop()

        if scroll_type == TL_SCROLL_TYPE_UP_DOWN then
            contentnode:setPositionY( 0 )
        else
            contentnode:setPositionX( 0 )
        end

        self:updatepage( 0 )
    end
    function pager_obj:pagecount() return contentnode:getChildrenCount() end
    function pager_obj:jumppage( index )
        local page_node = getChildNode( contentnode, index )
        local p = scroll_type == TL_SCROLL_TYPE_UP_DOWN and -page_node:getPositionY() or -page_node:getPositionX()
        self.impl:stop_animation()
        self.impl:reset_position( p ) -- 重置状态
        self.impl:set_position( p )   -- 设置position
        self:updatepage( index )
    end
    function pager_obj:scrollto( p )
        self.impl:start_animation()
        self.impl.scrollto( p )
    end
    function pager_obj:scrollpage( index )
        local page_node = getChildNode( contentnode, index )
        self:scrollto( scroll_type == TL_SCROLL_TYPE_UP_DOWN and -page_node:getPositionY() or -page_node:getPositionX() )
        self:updatepage( index )
        if self.callfunc then self.callfunc() end
    end

	local frameOn = MCLoader:sharedMCLoader():loadSpriteFrame( 'Nui_0020_14.png' );
    frameOn:retain()
	local frameOff = MCLoader:sharedMCLoader():loadSpriteFrame( 'Nui_0020_15.png' );
    frameOff:retain()
    function pager_obj:updatepage( index )
        self.currentpage = index
        --update_pager_buttons( button_container, self:pagecount(), currentpage, frameOn, frameOff )
    end
    function pager_obj:layout()
        for i=1,self.child_nodes:getElementCount() do
            local node = self.child_nodes:getAt( i )
            if scroll_type == TL_SCROLL_TYPE_UP_DOWN then
                local offset_y = ( i - 1 ) * self.scroll_unit
                node:setPositionY( offset_y )
            elseif scroll_type == TL_SCROLL_TYPE_LEFT_RIGHT then
                local offset_x = ( i - 1 ) * self.scroll_unit
                node:setPositionX( offset_x )
            end
        end

        -- 
        local temp = self.scroll_unit * self.child_nodes:getElementCount()

        local min_range, max_range = 0, 0
        if scroll_type == TL_SCROLL_TYPE_UP_DOWN then
            local max = box.size.height * page_percent - temp
            max_range = max > 0 and max or 0
            min_range = 0
        elseif scroll_type == TL_SCROLL_TYPE_LEFT_RIGHT then
            local min = box.size.width * page_percent - temp
            min_range = min < 0 and min or 0
            max_range = 0
        end
        self.impl:set_range( min_range, max_range )
    end

    return pager_obj
end

