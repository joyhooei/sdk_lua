-- ./ui/tab_ctrl.lua
require 'ui.scroller'

function create_tab_ctrl( style_index, width )
    local ts_info = __tab_style__[style_index]

    local box = CCRect( -width / 2, -ts_info.height / 2, width, ts_info.height )
    local frame = MCFrame:createWithBox( box )

    local win = TLWindow:createWindow( frame, TL_WINDOW_SCROLL )

    -- 创建 clip 和容器node
    -- 扩大上半部分的裁剪区
    local _box_clipRgn = CCRect(-frame.mcBoundingBox.size.width * 0.5, -frame.mcBoundingBox.size.height * 0.5, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height * 2)
    frame:setClipRegion( _box_clipRgn )
    local contentnode = CCNode:create()
    frame:addChild( contentnode )

    local t_ctrl = init_scrollable( win, frame, contentnode, TL_SCROLL_TYPE_LEFT_RIGHT )
    local frame_leftPlaceHolder = MCFrame:createWithBox(CCRect(-ts_info.border * 0.5, -ts_info.height * 0.5, ts_info.border, ts_info.height))
    t_ctrl:append(frame_leftPlaceHolder)


    local all_tabs = {}
    local _all_tabs_group = selectbox_group()
    function _all_tabs_group:onchange(currtab)
        for _, boxinfo in table.orderIter(self._boxes or {}, function(a, b) return a.value.box.index > b.value.box.index end) do
            contentnode:reorderChild(boxinfo.box.node, boxinfo.box == currtab and 1 or 0)

            --setNodeColor(boxinfo.box.node, (boxinfo.box == currtab) and ccc3(255, 255, 255) or ccc3(120, 120, 120))
        end
    end

    function t_ctrl:setCurSel( index , argv)
        _all_tabs_group:setcurrent(index, argv)
    end

    function t_ctrl:addTab( normal_text_sprite, sel_text_sprite, onclick, tagname)
        local normal_width = ts_info.normal_info.width * ts_info.normal_info.scale - ts_info.width_amend * 2
        local normal_height = ts_info.normal_info.height * ts_info.normal_info.scale

        local normal_box = CCRect( -normal_width / 2, -normal_height / 2, normal_width, normal_height )
        local tab_frame = MCFrame:createWithBox( normal_box )
        local item_win = TLWindow:createWindow( tab_frame )
        local _item_obj = __window_control.new( item_win )

        local left_sprite = MCLoader:sharedMCLoader():loadSprite( ts_info.normal_info.left )
        local left_width_normal = left_sprite:getContentSize().width * ts_info.normal_info.scale
        left_sprite:setScale( ts_info.normal_info.scale )
        local left_x = ( left_width_normal - ts_info.normal_info.width ) * 0.5
        left_sprite:setPosition( left_x, 0 )
        tab_frame:addChild( left_sprite )

        local right_sprite = MCLoader:sharedMCLoader():loadSprite( ts_info.normal_info.right )
        local right_width_normal = right_sprite:getContentSize().width * ts_info.normal_info.scale
        right_sprite:setScale( ts_info.normal_info.scale )
        local right_x = ( ts_info.normal_info.width - right_width_normal ) * 0.5
        right_sprite:setPosition( right_x, 0 )
        tab_frame:addChild( right_sprite )

        local center_sprite = MCLoader:sharedMCLoader():loadSprite( ts_info.normal_info.center )
        local center_width_normal = center_sprite:getContentSize().width * ts_info.normal_info.scale
        local cs_width = ts_info.normal_info.width - left_width_normal - right_width_normal
        local center_x = left_width_normal - ts_info.normal_info.width * 0.5 + cs_width * 0.5
        center_sprite:setPosition( center_x, 0 )
        center_sprite:setScaleX( cs_width / center_width_normal )
        center_sprite:setScaleY( ts_info.normal_info.scale )
        tab_frame:addChild( center_sprite )

        local cs_width_add = ts_info.normal_info.width - ( left_width_normal + right_width_normal ) * 0.5

        -- 
        local sprite_shadow = MCLoader:sharedMCLoader():loadSpriteAsyncCallback(ts_info.shadow, function(shadow)
            shadow:setFlipY(true)
            shadow:setScaleX( normal_width / shadow:getContentSize().width )
            local apos_of_frame = frame:convertToWorldSpace(CCPoint(0, 0))
            local apos_of_tabframe = tab_frame:convertToWorldSpace(CCPoint(0, 0))
            shadow:setPositionY(apos_of_frame.y - ts_info.height * 0.5 - apos_of_tabframe.y + shadow:getContentSize().height * 0.5) --FIXME
            if _item_obj.checked then shadow:setVisible(false) end
        end)
        tab_frame:addChild(sprite_shadow)
        sprite_shadow:setVisible(false)

        local text_sprite = MCLoader:sharedMCLoader():loadSprite( normal_text_sprite )
        text_sprite:setScale( ts_info.normal_info.scale )
        tab_frame:addChild( text_sprite )

        local node_tip = CCNode:create()
        tab_frame:addChild( node_tip )
        if ts_info.tipPos then node_tip:setPosition( normal_width * 0.5 + ts_info.tipPos.x, normal_height * 0.5 + ts_info.tipPos.y ) end

        function _item_obj:setCheckState(checked)
            if self.checked == checked then return end
            self.checked = checked

            sprite_shadow:setVisible( not self.checked )
            node_tip:setVisible( not self.checked )

            if self.checked == true then
                local left_sel_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( ts_info.selected_info.left )
                left_sprite:setScale( ts_info.selected_info.scale )
                left_sprite:setDisplayFrame( left_sel_sprite_frame )

                local right_sel_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( ts_info.selected_info.right )
                right_sprite:setScale( ts_info.selected_info.scale )
                right_sprite:setDisplayFrame( right_sel_sprite_frame )

                local left_sel_width = left_sprite:getContentSize().width * ts_info.selected_info.scale
                local right_sel_width = right_sprite:getContentSize().width * ts_info.selected_info.scale

                local center_sel_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( ts_info.selected_info.center )
                center_sprite:setDisplayFrame( center_sel_sprite_frame )
                local center_sel_width = center_sprite:getContentSize().width * ts_info.selected_info.scale
                local cs_width_sel = cs_width_add - left_sel_width * 0.5 - right_sel_width * 0.5
                center_sprite:setScaleX( cs_width_sel / center_sel_width )
                center_sprite:setScaleY( ts_info.selected_info.scale )
                local center_x_sel = left_x + left_sel_width * 0.5 + cs_width_sel * 0.5
                center_sprite:setPosition( center_x_sel, 0 )

                local sel_text_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( sel_text_sprite )
                text_sprite:setDisplayFrame( sel_text_sprite_frame )
                text_sprite:setScale( ts_info.selected_info.scale )
            else
                local left_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( ts_info.normal_info.left )
                left_sprite:setScale( ts_info.normal_info.scale )
                left_sprite:setDisplayFrame( left_sprite_frame )

                local right_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( ts_info.normal_info.right )
                right_sprite:setScale( ts_info.normal_info.scale )
                right_sprite:setDisplayFrame( right_sprite_frame )

                local center_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( ts_info.normal_info.center )
                center_sprite:setPosition( center_x, 0 )
                center_sprite:setScaleX( cs_width / center_width_normal )
                center_sprite:setScaleY( ts_info.normal_info.scale )
                center_sprite:setDisplayFrame( center_sprite_frame )

                local normal_text_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( normal_text_sprite )
                text_sprite:setDisplayFrame( normal_text_sprite_frame )
                text_sprite:setScale( ts_info.normal_info.scale )
            end

            if self.onchange then self:onchange() end
        end
        _item_obj:addEventEffect(nil, function() _item_obj:setCheckState(true) end)
        _item_obj:addEventEffect(nil, function() play_effect('music/bgm_button.mp3') end)
        _item_obj:useAnimEffect(tab_frame)

        local _tagname = tagname or table.len(_all_tabs_group._boxes) + 1
        _item_obj.onchange = onclick
        _item_obj.index = table.len(_all_tabs_group._boxes) + 1
        _all_tabs_group:add(_tagname, _item_obj)

        self:append( item_win )
        if ts_info.width_amend ~= 0 then
            local frame_leftPlaceHolder = MCFrame:createWithBox(CCRect(-ts_info.width_amend * 0.5, -ts_info.height * 0.5, ts_info.width_amend, ts_info.height))
            self:append(frame_leftPlaceHolder)
        end

        return {
            index    = _tagname,
            node_tip = node_tip,
            tab_btn  = _item_obj,
        }
    end

    return {
        win = win,
        frame = frame,
        t_ctrl = t_ctrl,
        tab_group = _all_tabs_group,
        width = width,
        height = ts_info.height,
    }
end

function testTabCtrl( scene, x, y )
    require 'ui.controls'
    local winSize = CCDirector:sharedDirector():getWinSize()
    local r_box = CCRect( -winSize.width / 2, -winSize.height / 2, winSize.width, winSize.height )
    local root_frame = MCFrame:createWithBox( r_box )
    local root_win = topwindowByNode( root_frame )
    root_win:SetIsVisible( true )

    -- 
    local style_index = 1

    local tab = create_tab_ctrl( style_index, 500 )
    root_win:AddChildWindow( tab.win )

    tab.t_ctrl:addTab( 'word/Nword_0006_5.png', 'word/Nword_0006_2.png', function() CCLuaLog( '111111111111111111111111111111111111' ) end )
    tab.t_ctrl:addTab( 'word/Nword_0006_4.png', 'word/Nword_0006_1.png', function() CCLuaLog( '222222222222222222222222222222222222' ) end )
    tab.t_ctrl:layout()

end

function create_new_tab_ctrl(tab_info, pnode, pwin)
    tab_info = tab_info or {}

    local normal_state_pic   = tab_info.normal_state_pic   or '5ui_0013.png'
    local selected_state_pic = tab_info.selected_state_pic or '5ui_0013_1.png'
    local bottom_pic         = tab_info.bottom_pic         or '5ui_0013_2.png'
    local scale_normal       = tab_info.scale_normal       or 1
    local scale_sel          = tab_info.scale_sel          or 1
    local width_amend        = tab_info.width_amend        or 0
    local width_border       = tab_info.width_border       or 20
    local height             = (toCCNode(pnode) and getBoundingBox(pnode).size.height) or tab_info.height or 49
    local width              = (toCCNode(pnode) and getBoundingBox(pnode).size.width)  or tab_info.width  or 640
    local tip_offset_x       = tab_info.tip_offset_x       or 10
    local tip_offset_y       = tab_info.tip_offset_y       or 10

    local box = CCRect(-width / 2, -height / 2, width, height)
    local frame = MCFrame:createWithBox(box)
    local win = TLWindow:createWindow(frame, TL_WINDOW_SCROLL)

    -- 创建 clip 和容器node
    -- 扩大上半部分的裁剪区
    local _box_clipRgn = CCRect(-frame.mcBoundingBox.size.width * 0.5, -frame.mcBoundingBox.size.height * 0.5, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height * 2)
    frame:setClipRegion(_box_clipRgn)
    local contentnode = CCNode:create()
    frame:addChild(contentnode)

    local t_ctrl = init_scrollable(win, frame, contentnode, TL_SCROLL_TYPE_LEFT_RIGHT)
    t_ctrl:scrollEnable(false)
    local frame_leftPlaceHolder = MCFrame:createWithBox(CCRect(-width_border * 0.5, -height * 0.5, width_border, height))
    t_ctrl:append(frame_leftPlaceHolder)

    local all_tabs = {}
    local _all_tabs_group = selectbox_group()
    function _all_tabs_group:onchange(currtab)
        for _, boxinfo in table.orderIter(self._boxes or {},
            function(a, b)
                return a.value.box.index > b.value.box.index
            end) do
            contentnode:reorderChild(boxinfo.box.node, boxinfo.box == currtab and 1 or 0)
        end
    end

    local super_removeall = t_ctrl.removeall
    t_ctrl.removeall = function(...)
        all_tabs = {}
        _all_tabs_group:clear()
        super_removeall(...)

        local frame_leftPlaceHolder = MCFrame:createWithBox(CCRect(-width_border * 0.5, -height * 0.5, width_border, height))
        t_ctrl:append(frame_leftPlaceHolder)
    end

    function t_ctrl:setCurSel(index , argv)
        _all_tabs_group:setcurrent(index, argv)
    end

    function t_ctrl:addTab( normal_text_sprite, sel_text_sprite, onclick, tagname, enable_func )
        local normal_sprite = MCLoader:sharedMCLoader():loadSprite(normal_state_pic)
        local normal_width  = normal_sprite:getContentSize().width  * scale_normal
        local normal_height = normal_sprite:getContentSize().height * scale_normal
        normal_sprite:setScale(scale_normal)

        local normal_box = CCRect(-normal_width / 2, -height / 2, normal_width, height)
        local tab_frame = MCFrame:createWithBox(normal_box)
        local item_win = TLWindow:createWindow(tab_frame)
        local _item_obj = __window_control.new(item_win)

        tab_frame:addChild( normal_sprite )
        normal_sprite:setPositionY((normal_sprite:getContentSize().height * scale_normal - height) / 2)

        local text_sprite = MCLoader:sharedMCLoader():loadSprite(normal_text_sprite)
        tab_frame:addChild(text_sprite)
        text_sprite:setScale(scale_normal)
        text_sprite:setPositionY(normal_sprite:getPositionY())

        local node_tip = CCNode:create()
        tab_frame:addChild( node_tip )
        node_tip:setPosition(normal_width/2 - tip_offset_x, normal_height - height/2 - tip_offset_y)

        function _item_obj:setCheckState(checked)
            if not toTLWindow(item_win) then return end
            if self.checked == checked then return end

            if checked and enable_func and not enable_func() then return end

            self.checked = checked

            node_tip:setVisible(not self.checked)

            if self.checked == true then
                local sel_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame(selected_state_pic)
                normal_sprite:setDisplayFrame(sel_sprite_frame)
                normal_sprite:setScale(scale_sel)
                normal_sprite:setPositionY((normal_sprite:getContentSize().height * scale_sel - height) / 2)

                local sel_text_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( sel_text_sprite )
                text_sprite:setDisplayFrame( sel_text_sprite_frame )
                text_sprite:setScale(scale_sel)
            else
                local normal_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame(normal_state_pic)
                normal_sprite:setDisplayFrame(normal_sprite_frame)
                normal_sprite:setScale(scale_normal)
                normal_sprite:setPositionY((normal_sprite:getContentSize().height * scale_normal - height) / 2)

                local normal_text_sprite_frame = MCLoader:sharedMCLoader():loadSpriteFrame( normal_text_sprite )
                text_sprite:setDisplayFrame( normal_text_sprite_frame )
                text_sprite:setScale(scale_normal)
            end
            text_sprite:setPositionY(normal_sprite:getPositionY())

            if self.onchange then self:onchange() end
        end
        _item_obj:addEventEffect(nil, function() _item_obj:setCheckState(true) end)
        _item_obj:addEventEffect(nil, function() play_effect('music/bgm_button.mp3') end)
        --_item_obj:useAnimEffect(tab_frame)

        local _tagname = tagname or table.len(_all_tabs_group._boxes) + 1
        _item_obj.onchange = onclick
        _item_obj.index = table.len(_all_tabs_group._boxes) + 1
        _all_tabs_group:add(_tagname, _item_obj)

        self:append(item_win)

        local frame_leftPlaceHolder = MCFrame:createWithBox(CCRect(-width_amend * 0.5, -height * 0.5, width_amend, height))
        self:append(frame_leftPlaceHolder)

        return {
            frame = tab_frame,
            index    = _tagname,
            node_tip = node_tip,
            tab_btn  = _item_obj,
        }
    end

    if toCCNode(pnode) then
        pnode:addChild(frame)
        frame:setPositionY((frame.mcBoundingBox.size.height - getBoundingBox(pnode).size.height) / 2)

        local bottom_bar = MCLoader:sharedMCLoader():loadSprite('5ui_0013_2.png')
        frame:addChild(bottom_bar)
        bottom_bar:setScaleX(getBoundingBox(frame).size.width / bottom_bar:getContentSize().width)
        bottom_bar:setPositionY((bottom_bar:getContentSize().height - getBoundingBox(frame).size.height) / 2)
    end

    if toTLWindow(pwin) then
        pwin:AddChildWindow(win)
    end

    return {
        win = win,
        frame = frame,
        t_ctrl = t_ctrl,
        tab_group = _all_tabs_group,
        width = width,
        height = height,
    }
end

function tabContainer()
    local tab_container = {
        tab_objs        = {},
        name_2_index    = {},
        cur_sel         = nil,
    }

    function tab_container:add( tab_obj, on_sel, on_change, tab_name )
        table.insert( self.tab_objs, {
            tab_obj   = tab_obj,
            on_sel    = on_sel,
            on_change = on_change,
        } )
        tab_name = tab_name or #self.tab_objs
        self.name_2_index[ tab_name ] = #self.tab_objs
    end

    function tab_container:setCurSel( sel_index )
        if self.cur_sel == sel_index then return end
        self.cur_sel = sel_index

        for index, tab_obj in ipairs( self.tab_objs ) do
            local sel_flag = sel_index == index

            tab_obj.on_change( sel_flag )

            if sel_flag then tab_obj.on_sel() end
        end
    end

    return tab_container
end
