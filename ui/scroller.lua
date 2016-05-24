--./ui/scroller.lua
require 'utils.common'
require 'utils.scroll_impl1'
require 'utils.stack'

function rolling_bar(barcol,linecol)
    barcol = barcol or ccc4(24,19,19,255)
    linecol= linecol
    local line = CCLayerColor:create(linecol or ccc4(255,255,255,0))
    local bar  = CCLayerColor:create(barcol)

    line:changeWidth(4)
    bar:changeWidth(3)
    line:addChild(bar)
    line:setVisible(false)
    bar:setVisible(false)

    return{
        line = line,
        bar = bar,
        _lineH = 0,
        _barH  = 0,
        _totalH= 0,
        setLineOpacity = function(self,opacity)
            self.line:setOpacity(opacity)
        end,
        setBarOpacity = function(self,opacity)
            self.bar:setOpacity(opacity)
        end,
        addTo = function(self,parent,x,y)
            parent:addChild(self.line)
            self.line:setPosition(x,y)
            self.line:changeHeight(parent:getContentSize().height)
            self._lineH = parent:getContentSize().height
        end,
        setHeight = function(self,totalh)
            self._totalH = totalh and totalh > 0 and totalh or 1
            self._barH = math.pow(self._lineH,2)/totalh
            self.bar:changeHeight(self._barH)
            self.bar:setPositionY(self._lineH - self._barH)
        end,
        rolling = function(self,pos)
            if self._barH >= self._lineH then return end
            local moveh = pos/self._totalH*self._lineH
            self.bar:setPositionY(self._lineH - self._barH - moveh)
        end,
        show = function(self)
            if self._barH >= self._lineH then return end
            self.line:setVisible(true)
            self.bar:setVisible(true)
        end,
        hide = function(self)
            self.line:setVisible(false)
            self.bar:setVisible(false)
        end,
    }

end

function __initList(_sort_dict, scrollType, space)
    local ret = {}
    local th,te = 0,0
	local space = space or 0
    local i = 0
    for index=1,_sort_dict:getElementCount() do
        local _node = _sort_dict:getAt( index )
        local size = getBoundingBox( _node ).size
        _node:setVisible(false)
        if scrollType==TL_SCROLL_TYPE_UP_DOWN then
            te = te + size.height + space
        else
            te = te + size.width + space
        end
        table.insert(ret,{head=th,tend=te,node=_node,index=i+1})
        th = te
        i = i + 1
    end
    return ret
end

function getScrollableVisibleSetting(scrollType)
    local lastPos = 0
    local list = {}
    local _head , _tend
    local headLine,tendLine

    local function changeHead(head)
        if not head then return end
        head.node:setVisible(true)
        _head = head
        if head.tend<=headLine then
            head.node:setVisible(false)
            return changeHead(list[head.index+1])
        end
        if head.head>headLine then
            return changeHead(list[head.index-1])
        end
    end

    local function changeTend(tend)
        if not tend then return end
        _tend = tend
        if tend.index < _head.index then
            return changeTend(list[tend.index+1])
        end
        tend.node:setVisible(true)
        if tend.head>=tendLine then
            tend.node:setVisible(false)
            return changeTend(list[tend.index-1])
        end
        if tend.tend<tendLine then
            return changeTend(list[tend.index+1])
        end
    end

    local function getTotal()
        local c = 0 
        for _,v in pairs(list) do
            if v.node:isVisible() then
                c = c +1
            end
        end
        return c
    end

    return {
    resetPos = function(self)
        lastPos = 0
    end,
    init = function(self,scroller)
        local size = getBoundingBox( scroller.frame ).size
        if scrollType == TL_SCROLL_TYPE_UP_DOWN then
            headLine= lastPos
            tendLine= headLine + size.height
        else
            headLine= -lastPos
            tendLine= headLine + size.width
        end
        list = __initList(scroller.sort_dict,scrollType, scroller.space)
        if not list[1] then return end
        _head = list[1]
        _tend = list[1]
        changeHead(_head)
        changeTend(_tend)
    end,
    roll = function(self,pos)
        local npos
        if scrollType == TL_SCROLL_TYPE_UP_DOWN then
            npos = pos - lastPos 
        elseif scrollType == TL_SCROLL_TYPE_LEFT_RIGHT then
            npos = lastPos - pos 
        elseif scrollType == TL_SCROLL_TYPE_FREE then
            npos = 0
        end
        lastPos = pos
        if not list[1] then return end
        if npos == 0 then return end
        headLine= headLine + npos
        tendLine= tendLine + npos
        changeHead(_head)
        changeTend(_tend)
    end,
    }
end

function init_scrollable(win, frame, contentnode, scrollType, isIMPL, space, arcParam)
    -- 滚动控件对象
    local scroller = {
        frame = frame,
        contentnode = CCNodeExtend.extend( contentnode ),
        window = win,
        rollbar= nil,
        contentWidth = 0,
        contentHeight = 0,
        impl = nil, -- 滚动算法实现
        reachendCall = nil,
        sort_dict = stack.new(), -- 排序用的字典	
		record_pos = {},--记录初始坐标	
		setArcScroller = nil,
		space =0, --间隔
        scroll_enable = true,
        is_valid = true,
        scrollType = scrollType,
    }

    scroller.contentnode:registerScriptHandler(function(evt)
        if evt == 'exit' then
            scroller.is_valid = false
            scroller:stop()
        end
    end)

	if not space then space = 0 end
	scroller.space = space

    local vsetting = getScrollableVisibleSetting(scrollType)

    -- 添加元素到滚动区域的末尾
    function scroller:append(childWin, relayout)
        local mc_node = nil
        if tolua.type(childWin)=='TLWindow' then
            mc_node = childWin:GetNode()
            contentnode:addChild(mc_node)
            win:AddChildWindow(childWin)
            -- note:如果先调用AddChildWindow再调用addChild会导致断言失败崩溃
        else
            mc_node = childWin
            contentnode:addChild(mc_node)
        end

        self.sort_dict:push( mc_node )

        if relayout then
            self:layout()
        end
    end

    -- 插入元素到滚动区域中的指定位置
    -- 接口中的index的有效范围为 1~count, C的惯例
    -- 已有元素:  1, 2
    -- 有效的insert index: 1, 2, 3   其中为3时表示插入到末尾,与append一样
    function scroller:insert(childWin, index, relayout)
        local mc_node = nil
        if tolua.type(childWin) == 'TLWindow' then
            mc_node = childWin:GetNode()
            contentnode:addChild(mc_node)
            win:AddChildWindow(childWin)
        else
            mc_node = childWin
            contentnode:addChild(mc_node)
        end

        self.sort_dict:insert( index, mc_node )

        if relayout then
            self:layout()
        end
    end

    function scroller:scrollEnable( enable )
        self.scroll_enable = enable
    end

    -- 计算内容边界
    local box = frame.mcBoundingBox
    local top
    local left
    if scrollType==TL_SCROLL_TYPE_UP_DOWN then
        -- top
        top = box.origin.y+box.size.height
        scroller.rollbar = rolling_bar(ccc4(246,100,4,255),ccc4(24,19,19,255))
        local node = scroller.window:GetNode()
        local size = node:getContentSize()
        scroller.rollbar:addTo(node,size.width*0.5-4,-size.height*0.5)
    elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
        left = box.origin.x
    else
        top = box.origin.y+box.size.height
        left = box.origin.x
    end

    function scroller:setScrollerSize(width, height)
        frame.mcBoundingBox.size.width = width
        frame.mcBoundingBox.size.height = height
        frame.mcBoundingBox.origin.x = -frame.mcBoundingBox.size.width * 0.5
        frame.mcBoundingBox.origin.y = -frame.mcBoundingBox.size.height * 0.5
        frame.mcOriginBoundingBox = frame.mcBoundingBox

        box = frame.mcBoundingBox
        if scrollType==TL_SCROLL_TYPE_UP_DOWN then
            -- top
            top = box.origin.y+box.size.height
            local size = frame.mcBoundingBox.size
            scroller.rollbar._lineH = size.height
            scroller.rollbar.line:setPosition(size.width*0.5-4, -size.height*0.5)
        elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
            left = box.origin.x
        else
            top = box.origin.y+box.size.height
            left = box.origin.x
        end

        self:updateVertexUniforms()
        if self.render_node then
            self.render_node:setRenderSize(frame.mcBoundingBox.size)
        end
    end

    -- 内容区域大小变更，通知滚动算法
    function scroller:setContentSize(w, h)
        self.contentWidth = w
        self.contentHeight = h
        self.impl:set_range(self:get_range())
    end

    function scroller:get_range()
        if scrollType==TL_SCROLL_TYPE_UP_DOWN then
            local max = self.contentHeight-box.size.height
            return 0, max>0 and max or 0
        elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
            local min = box.size.width-self.contentWidth
            return min<0 and min or 0, 0
        else
            local max = self.contentHeight-box.size.height
            local min = box.size.width-self.contentWidth
            return min<0 and min or 0, max>0 and max or 0
        end
    end

	function scroller:setPosition(pos)
		scroller.impl.setPosition(pos)
		scroller.impl:set_position(pos)--设置控件窗口当前位置
	end

	function scroller:getPosition()
		return scroller.impl.getPosition()
	end

	
    -- 重新布局元素并重新计算宽高
    function scroller:layout( pos )
        local w = 0
        local h = 0
        -- init w, h with space
        if scrollType == TL_SCROLL_TYPE_UP_DOWN then
            h = space * 0.5
        elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
            w = space * 0.5
        else
            w = space * 0.5
            h = space * 0.5
        end

        for i=1,self.sort_dict:getElementCount() do
            local node = self.sort_dict:getAt( i )
            local bb = getBoundingBox(node)
            if scrollType == TL_SCROLL_TYPE_UP_DOWN then
                local offsetY = top - h - (bb.size.height+bb.origin.y)
                node:setPositionY(offsetY)
                self.record_pos[node] = offsetY
                h = h + bb.size.height + space
                w = math.max(w, bb.size.width)
            elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
                local offsetX = left + w - bb.origin.x
                node:setPositionX(offsetX)
                self.record_pos[node] = offsetX
                w = w + bb.size.width  + space
                h = math.max(h, bb.size.height)
            else
                node:setPositionY(0)
                node:setPositionX(0)
                h = h + bb.size.height + space
                w = w + bb.size.width + space
           end
        end

        -- fix w, h with space
        if scrollType == TL_SCROLL_TYPE_UP_DOWN then
            h = h - space * 0.5
        elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
            w = w - space * 0.5
        else
            w = w - space * 0.5
            h = h - space * 0.5
        end

        self:setContentSize(w, h)
        if self.rollbar then
            self.rollbar:setHeight(self.contentHeight)
        end
        vsetting:init(self)
		if arcParam then
			self.setArcScroller()
		end

        if pos then self:setPosition( pos ) end
    end

    function scroller:getViewNodes()
        local offset    = contentnode:getPositionY()
        local viewItems = {}

        local bottomRange = box.origin.y
        local topRange    = box.origin.y + box.size.height
        local started     = false
        for i=1,self.sort_dict:getElementCount() do
            local node = self.sort_dict:getAt( i )
            local nodeOffsetY = self.record_pos[node]
            local realOffsetY = nodeOffsetY + offset
            local nodeBox     = getBoundingBox(node)
            -- TOFIX: space * 0.5 ?
            local topY        = realOffsetY + nodeBox.origin.y + nodeBox.size.height + space * 0.5
            local bottomY     = realOffsetY + nodeBox.origin.y - space * 0.5
            if topY > bottomRange and topY < topRange or 
                bottomY > bottomRange and bottomY < topRange then
                table.insert(viewItems, node)
                started = true
            else
                if started then
                    break      -- ended
                end
            end
        end
        return viewItems
    end

	--设置弧形
	function scroller.setArcScroller(pos)
		local k = arcParam.k or 0--400
		local b = arcParam.b or 0--230
		local pos = pos or 0
        for i=1,self.sort_dict:getElementCount() do
            local node = self.sort_dict:getAt( i )
			if node:isVisible() then
				local origin_y = scroller.record_pos[node]
				local y = origin_y + pos
				local x
				--斜线
				--[[if y > 0 then
					x = ( y ) - b
				else
					x = -y - b
				end--]]
				--抛物线
				x = y*y/k - b
				node:setPosition( x, y )
			end
		end
	end

    -- 移除元素的接口
    function scroller:removeall()
        self:stop()
        self:setContentSize(0,0)

        win:RemoveAllChildWindow()
        contentnode:removeAllChildrenWithCleanup(true)

        self.sort_dict:clear()
		self.record_pos = {}
        self.next_item_index = 1

        if scrollType==TL_SCROLL_TYPE_UP_DOWN then
            self.contentnode:setPositionY(0)
        else
            self.contentnode:setPositionX(0)
        end
        vsetting:resetPos()
    end

    -- 从指定位置删除删除元素,或者删除指定窗口
    function scroller:remove(childWin, relayout)
        local scroll_to_offset = self:getPosition()
        if type(childWin)=='number' then
            childWin = getChildWindow(win, childWin)
            CCLuaLog('!!暂未实现使用number作为参数删除节点的功能!可能会出错!')
        end
        local mc_node = nil
        if tolua.type(childWin)=='TLWindow' then
            mc_node = childWin:GetNode()
            contentnode:removeChild(mc_node, true)
            win:RemoveChildWindow(childWin)
        else
            mc_node = childWin
            contentnode:removeChild(mc_node, true)
        end
        self.sort_dict:pop( mc_node )
		self.record_pos[mc_node] = nil

        if relayout then
            self:layout()
            self:scrollto( scroll_to_offset )
        end
    end
    function scroller:removeNodeByIndex( index, relayout )
        local node = getChildNode( contentnode, index )
        if node ~= nil then self:remove( node, relayout ) end
    end
    -- 滚动算法实现，并实现必要的接口
    local impl
    --isIMPL = isIMPL and isIMPL or true
    if scrollType==TL_SCROLL_TYPE_UP_DOWN then
        impl = scroll_impl()
        function impl:set_position(pos)
			if not arcParam then
				contentnode:setPositionY(pos)
			end
            scroller.rollbar:rolling(pos)
            vsetting:roll(pos)
			if arcParam then
				scroller.setArcScroller(pos)
			end
            if scroller.reachendCall and pos>(scroller.contentHeight-box.size.height) then
                scroller.reachendCall(scroller)
            end
            --执行回调
            if scroller.callback then
                scroller.callback()
            end
        end
    elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
        impl = scroll_impl()
        function impl:set_position(pos)
			if not arcParam then
				contentnode:setPositionX(pos)
			end
            vsetting:roll(pos)
			if arcParam then
				scroller.setArcScroller(pos)
			end
            if scroller.reachendCall and pos>(box.size.width-scroller.contentWidth) then
                scroller.reachendCall(scroller)
            end
            --执行回调
            if scroller.callback then
                scroller.callback()
            end
        end
    elseif scrollType==TL_SCROLL_TYPE_FREE then
        impl = scroll_impl()
        function impl:set_position(pos)
            local limit_x = ( scroller.contentWidth - scroller.frame.mcBoundingBox.size.width ) * 0.5
            if limit_x < 0 then limit_x = 0 end
            local limit_y = ( scroller.contentHeight - scroller.frame.mcBoundingBox.size.height ) * 0.5
            if limit_y < 0 then limit_y = 0 end

            local mv_x = pos.x
            if mv_x > limit_x then mv_x = limit_x end
            if mv_x < -limit_x then mv_x = -limit_x end

            local mv_y = pos.y
            if mv_y > limit_y then mv_y = limit_y end
            if mv_y < -limit_y then mv_y = -limit_y end

            contentnode:setPosition( mv_x, mv_y )
            --vsetting:roll(pos)
            --执行回调
            if scroller.callback then
                scroller.callback()
            end
        end
    end

    scroller.impl = impl

    local animationtimer
    function impl:start_animation()
        if not animationtimer then
            animationtimer = CCDirector:sharedDirector():getPauseScheduler():scheduleScriptFunc(impl.update, 0, false)
            animationtimerMgr.add(animationtimer)
        end
    end

    function scroller:stop()
        self.contentnode:removeAllTween()
        if animationtimer then
            CCDirector:sharedDirector():getPauseScheduler():unscheduleScriptEntry(animationtimer)
            animationtimerMgr.delete(animationtimer)
            animationtimer = nil
            if scroller.rollbar then
                scroller.rollbar:hide()
            end
        end
    end

    function impl:stop_animation()
        scroller:stop()
    end

    function scroller.touchbegin(p)
        if not scroller.scroll_enable then return end
        if scroller.sort_dict:getElementCount() == 0 then return end
        if scrollType == TL_SCROLL_TYPE_FREE then
            scroller:stop()
            scroller.c_offset_x, scroller.c_offset_y = scroller.contentnode:getPosition()
            impl.mousedownpoint = p
        else
            impl.touchbegin(p)
        end
    end
    function scroller.touchend(p)
        if not scroller.scroll_enable or not impl.mousedownpoint then return end
        if scrollType == TL_SCROLL_TYPE_FREE then
            local limit_x = ( scroller.contentWidth - scroller.frame.mcBoundingBox.size.width ) * 0.5
            if limit_x < 0 then limit_x = 0 end
            local limit_y = ( scroller.contentHeight - scroller.frame.mcBoundingBox.size.height ) * 0.5
            if limit_y < 0 then limit_y = 0 end

            local mv_x = p.x - impl.mousedownpoint.x
            if mv_x > limit_x then mv_x = limit_x end
            if mv_x < -limit_x then mv_x = -limit_x end

            local mv_y = p.y - impl.mousedownpoint.y
            if mv_y > limit_y then mv_y = limit_y end
            if mv_y < -limit_y then mv_y = -limit_y end

            local target_x = scroller.c_offset_x + mv_x
            local target_y = scroller.c_offset_y + mv_y
            impl:set_position( { x = target_x, y = target_y } )

            impl.mousedownpoint = nil
        else
            impl.touchend(p)
        end
    end

	--注册回调
	function scroller:registerCallback(func)
		self.callback = func
	end

    function scroller.touchmove(p)
        if not scroller.scroll_enable or not impl.mousedownpoint then return end

        if scrollType == TL_SCROLL_TYPE_FREE then
            local limit_x = ( scroller.contentWidth - scroller.frame.mcBoundingBox.size.width ) * 0.5
            if limit_x < 0 then limit_x = 0 end
            local limit_y = ( scroller.contentHeight - scroller.frame.mcBoundingBox.size.height ) * 0.5
            if limit_y < 0 then limit_y = 0 end

            local mv_x = p.x - impl.mousedownpoint.x
            if mv_x > limit_x then mv_x = limit_x end
            if mv_x < -limit_x then mv_x = -limit_x end

            local mv_y = p.y - impl.mousedownpoint.y
            if mv_y > limit_y then mv_y = limit_y end
            if mv_y < -limit_y then mv_y = -limit_y end

            local target_x = scroller.c_offset_x + mv_x
            local target_y = scroller.c_offset_y + mv_y
            impl:set_position( { x = target_x, y = target_y } )
        else
            if scroller.rollbar then
                scroller.rollbar:show()
            end
            impl.touchmove(p)
        end
    end

    local winManager = TLWindowManager:SharedTLWindowManager()
    if scrollType==TL_SCROLL_TYPE_UP_DOWN then
        win:RegisterEvent(TL_EVENT_BUTTON_DOWN, function()
            scroller.touchbegin(winManager:getLastPointY())
        end)

        win:RegisterEvent(TL_EVENT_BUTTON_UP, function()
            scroller.touchend(winManager:getLastPointY())
        end)

        win:RegisterEvent(TL_EVENT_BUTTON_RELEASE, function()
            scroller.touchend(winManager:getLastPointY())
        end)

        win:RegisterEvent(TL_EVENT_MOUSE_MOVE, function()
            scroller.touchmove(winManager:getLastPointY())
        end)
    elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
        win:RegisterEvent(TL_EVENT_BUTTON_DOWN, function()
            scroller.touchbegin(winManager:getLastPointX())
        end)

        win:RegisterEvent(TL_EVENT_BUTTON_UP, function()
            scroller.touchend(winManager:getLastPointX())
        end)

        win:RegisterEvent(TL_EVENT_BUTTON_RELEASE, function()
            scroller.touchend(winManager:getLastPointX())
        end)

        win:RegisterEvent(TL_EVENT_MOUSE_MOVE, function()
            scroller.touchmove(winManager:getLastPointX())
        end)
    elseif scrollType==TL_SCROLL_TYPE_FREE then
        win:RegisterEvent(TL_EVENT_BUTTON_DOWN, function()
            scroller.touchbegin(winManager:getLastPoint())
        end)

        win:RegisterEvent(TL_EVENT_BUTTON_UP, function()
            scroller.touchend(winManager:getLastPoint())
        end)

        win:RegisterEvent(TL_EVENT_BUTTON_RELEASE, function()
            scroller.touchend(winManager:getLastPoint())
        end)

        win:RegisterEvent(TL_EVENT_MOUSE_MOVE, function()
            scroller.touchmove(winManager:getLastPoint())
        end)
    end
    function scroller:scrollto_min()
        local min,_ = self:get_range()
        self:scrollto(min)
    end
    function scroller:scrollto_max()
        local _,max = self:get_range()
        self:scrollto(max)
    end
    function scroller:scrollto(p)
        if not self.is_valid then return end

        if scrollType == TL_SCROLL_TYPE_FREE then
            local limit_x = ( scroller.contentWidth - scroller.frame.mcBoundingBox.size.width ) * 0.5
            if limit_x < 0 then limit_x = 0 end
            local limit_y = ( scroller.contentHeight - scroller.frame.mcBoundingBox.size.height ) * 0.5
            if limit_y < 0 then limit_y = 0 end

            local mv_x = p.x
            if mv_x > limit_x then mv_x = limit_x end
            if mv_x < -limit_x then mv_x = -limit_x end

            local mv_y = p.y
            if mv_y > limit_y then mv_y = limit_y end
            if mv_y < -limit_y then mv_y = -limit_y end

            local x, y = self.contentnode:getPosition()
            self.contentnode:tweenFromToOnce( EXPO_OUT, NODE_PRO_X, 0, 0.5, x, mv_x )
            self.contentnode:tweenFromToOnce( EXPO_OUT, NODE_PRO_Y, 0, 0.5, y, mv_y )
        else
            impl:start_animation()
            impl.scrollto(p)
        end
    end

    local toRenderNode = toRenderNode or function() return false end
    local function getUniformsRateValue( offset, length )
        return math.min(1, (offset / math.max(1,length)))
    end
    function scroller:updateVertexUniforms()
        if not self.is_use_vertex_alpha then return end

        if not self.render_node then return end

        local xsr, xer, ysr, yer
        local size = frame.mcBoundingBox.size
        if scrollType==TL_SCROLL_TYPE_UP_DOWN then
            xsr ,xer = 0.0, 1.0
            ysr = getUniformsRateValue(self.front_offset, size.height)
            yer = 1 - getUniformsRateValue(self.back_offset, size.height)
        elseif scrollType==TL_SCROLL_TYPE_LEFT_RIGHT then
            ysr ,yer = 0.0, 1.0
            xsr = getUniformsRateValue(self.front_offset, size.width)
            xer = 1 - getUniformsRateValue(self.back_offset, size.width)
        else
            xsr = getUniformsRateValue(self.front_offset, size.width)
            xer = 1 - getUniformsRateValue(self.back_offset, size.width)
            ysr = getUniformsRateValue(self.front_offset, size.height)
            yer = 1 - getUniformsRateValue(self.back_offset, size.height)
        end

        self.render_node:setCustomUniforms( xsr, xer, (1- yer), (1 - ysr) )        -- flippedY
    end

    function scroller:useVertexAlpha( is_use_vertex_alpha, front_offset, back_offset )
        self.is_use_vertex_alpha = is_use_vertex_alpha
        self.front_offset        = front_offset
        self.back_offset         = back_offset
        if is_use_vertex_alpha then
        --if false then
            self:updateVertexUniforms()
            if self.render_node then
                self.render_node:setShaderProgramName('position_texture_color_multi_transparent')
                self.render_node:setUseRender( true )
            end
        else
            if self.render_node then
                self.render_node:setUseRender( false )
            end
        end
    end

    return scroller
end

-- scrollable
function scrollable(pWin, name, scrollType, space, arcParam)
    -- 不实现 TL_SCROLL_TYPE_NONE
    assert(scrollType~=TL_SCROLL_TYPE_NONE, 'invalid scrollType'..tostring(scrollType))

    -- 初始化window
    local frame = assert( toFrame( pWin:GetNode():getChildByName( name ) ), string.format( 'not found child frame %s from %s', name, pWin:GetNode():getInstanceName() ) )

    local scroller, win = scrollableByFrame( frame, scrollType, space, arcParam )
    pWin:AddChildWindow( win )

    return scroller
end

function scrollableByFrame( frame, scrollType, space, arcParam )
    local win = TLWindow:createWindow( frame, TL_WINDOW_SCROLL )
    frame:setClipRegion( frame.mcBoundingBox )

    local content_node = CCNode:create()
    local render_node = TLRenderNode:create( content_node, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height)
    render_node:addChild( content_node )
    frame:addChild( render_node )

    local scroller = init_scrollable( win, frame, content_node, scrollType, nil, space, arcParam )
    scroller.render_node = render_node

    return scroller, win
end

--多列滚动区
function overloadMultiScroller( obj )
    function obj:setgap(x,y)
        self.xgap = x or self.xgap
        self.ygap = y or self.ygap
    end

    function obj:append(childWin, relayout, single_row)
        local childNode = childWin:GetNode()
        local childBox = getBoundingBox(childNode)
        local box = obj.frame.mcBoundingBox

        --[[
        childBox.size.width = childBox.size.width + self.xgap
        childBox.size.height= childBox.size.height+ self.ygap
        childBox.origin.x = -childBox.size.width / 2
        childBox.origin.y = -childBox.size.height / 2
        --]]

        local new_row, new_col
        if obj.scrollType == TL_SCROLL_TYPE_UP_DOWN then
            if single_row then
                new_row = MCFrame:createWithBox(childBox)
                new_row:addChild(childNode)
                self.contentnode:addChild(new_row)
                childNode:setPositionX(box.origin.x - childBox.origin.x + self.xgap)
            else
                -- 取最后一个子节点，看是否满了两个
                local last_row, last_row_size
                if self.contentnode:getChildrenCount() > 0 then
                    last_row = getChildNode(self.contentnode, self.contentnode:getChildrenCount() - 1)
                    last_row_size = last_row:getContentSize()
                end
                local left_padding = 0
                if last_row and last_row_size.width + childBox.size.width <= box.size.width then
                    left_padding = last_row_size.width + self.xgap / 2
                    last_row:addChild(childNode)
                    last_row:setContentSize(CCSizeMake(last_row_size.width + childBox.size.width + self.xgap, last_row_size.height))
                else
                    -- new row
                    left_padding = self.xgap / 2
                    local temp_width = childBox.size.width + self.xgap
                    local temp_height = childBox.size.height + self.ygap
                    local new_child_box = CCRect( -temp_width*0.5, -temp_height*0.5, temp_width, temp_height )
                    new_row = MCFrame:createWithBox(new_child_box)
                    new_row:addChild(childNode)
                    self.contentnode:addChild(new_row)
                end
                childNode:setPositionX(left_padding + box.origin.x - childBox.origin.x)
            end
        elseif obj.scrollType == TL_SCROLL_TYPE_LEFT_RIGHT then
            -- 取最后一个子节点，看是否满了两个
            local last_col, last_col_size
            if self.contentnode:getChildrenCount() > 0 then
                last_col = getChildNode(self.contentnode, self.contentnode:getChildrenCount() - 1)
                last_col_size = last_col:getContentSize()
            end
            if last_col and last_col_size.height + childBox.size.height <= box.size.height then
                last_col:addChild(childNode)
                last_col:setContentSize( CCSizeMake( last_col_size.width, last_col_size.height + childBox.size.height + self.ygap ) )

                childNode:setPositionY(box.size.height/2 - last_col_size.height - childBox.size.height/2)
            else
                -- new col
                local temp_width = childBox.size.width + self.xgap
                local temp_height = childBox.size.height + self.ygap
                local new_child_box = CCRect( -temp_width*0.5, -temp_height*0.5, temp_width, temp_height )
                new_col = MCFrame:createWithBox(new_child_box)
                new_col:addChild(childNode)
                self.contentnode:addChild(new_col)

                childNode:setPositionY(box.size.height/2 - childBox.size.height/2)
            end
        else
        end
        self.window:AddChildWindow(childWin)

        if new_row then
            self.sort_dict:push( new_row )
        end

        if new_col then
            self.sort_dict:push( new_col )
        end

        if relayout then
            self:layout()
        end
    end

    return obj
end

-- 多列 滚动条
function multi_scroller(pWin, name, scrollType,xgap,ygap)
    CCLuaLog('创建create new multi scroller '..name)
    local obj = scrollable(pWin, name, scrollType)
    obj.xgap = xgap or 0
    obj.ygap = ygap or 0

    return overloadMultiScroller( obj )
end

function multi_scroller_by_frame( frame, scrollType, xgap, ygap )
    local obj, win = scrollableByFrame( frame, scrollType, nil, nil )
    obj.xgap = xgap or 0
    obj.ygap = ygap or 0

    overloadMultiScroller( obj )

    return obj, win
end

--- createTableView
-- 用于创建自偏移重设内容的滚动区
-- @param scroller 已经初始化的scroller
-- @param create_func 创建滚动项的办法 包含obj.win, obj.frame
-- @param update_func update滚动项的办法
-- @param data 有序的数据，用于更新滚动项
-- @usage createTableView( scroller, function() return { updateInfo = function( obj, data ) end, frame = frame, win = win } end, data, 10 )
function createTableView( scroller, create_func, update_func, data )
    scroller:removeall()

    local group_volume             -- 一组的数量
    local group_count              -- 组的数量
    local direction                -- 增长方向 endwise/纵向
    local init_position_offset = 0 -- 初始化时得到的位置偏移
    local last_offset          = 0 -- 最后一次的相对偏移，以行或列为单位
    local cur_offset           = 0 -- 当前的相对偏移，以行或列为单位

    local width      = scroller.frame.mcBoundingBox.size.width  -- 容器的宽
    local height     = scroller.frame.mcBoundingBox.size.height -- 容器的高
    local col_width  = 0                                        -- 列宽
    local row_height = 0                                        -- 行高

    local all_obj   = {} -- 
    local positions = {} -- 

    local num_load          -- 即将加载的数量
    local a_big_num = 11111 -- 一个好大好大的数

    for index = 1, a_big_num do
        local obj = create_func()
        table.insert( all_obj, obj )

        local frame = MCFrame:createWithBox( obj.frame.mcBoundingBox )
        local win   = TLWindow:createWindow( frame )
        scroller:append( win, true )

        local p_frame = frame:convertToWorldSpace( CCPoint( 0, 0) )
        local p_offset = scroller.frame:convertToNodeSpace( p_frame )

        positions[ index ] = p_offset

        if col_width == 0 then col_width = scroller.contentWidth end
        if row_height == 0 then row_height = scroller.contentHeight end

        if col_width < scroller.contentWidth then
            -- 说明在横向发展
            direction = 'broadwise'
            if not group_volume then group_volume = index - 1 end
        end

        if row_height < scroller.contentHeight then
            -- 说明在纵向发展
            direction = 'endwise'
            if not group_volume then group_volume = index - 1 end
        end

        if not num_load then
            if direction == 'endwise' then
                local gounp_need_load = math.ceil( height / row_height ) + 1
                num_load = gounp_need_load * group_volume
            elseif direction == 'broadwise' then
                local gounp_need_load = math.ceil( width / col_width ) + 1
                num_load = gounp_need_load * group_volume
            end
        end

        -- CCLuaLog( 'index' .. tostring(index) )
        if index == num_load then break end
    end
    scroller:removeall()

    -- 
    group_count = math.floor( #data / group_volume ) + ( ( #data % group_volume == 0 ) and 0 or 1 )
    if direction == 'endwise' then
        height = group_count * row_height
        init_position_offset = ( scroller.frame.mcBoundingBox.size.height - height ) / 2
    else
        width = group_count * col_width
        init_position_offset = ( scroller.frame.mcBoundingBox.size.width - width ) / 2
    end

    local frame = MCFrame:createWithBox( CCRect( width/-2, height/-2, width, height ) )
    local win   = TLWindow:createWindow( frame )
    scroller:append( win, true )

    for index, obj in ipairs( all_obj ) do
        frame:addChild( obj.frame )
        win:AddChildWindow( obj.win )
    end

    -- local color_layer = CCLayerColor:create( ccc4( 0, 0, 0, 180 ), width, height )
    -- color_layer:setPosition( width/-2, height/-2 )
    -- frame:addChild( color_layer, -10 )

    -- 取得绝对位置
    local function getPosition( index )
        local relative_interval = math.floor( ( index - 1 ) / group_volume )
        local relative_position = index % group_volume
        if relative_position == 0 then relative_position = group_volume end

        if direction == 'endwise' then
            return positions[ relative_position ].x,
                   positions[ relative_position ].y - init_position_offset - relative_interval * row_height
        else
            return positions[ relative_position ].x + init_position_offset + relative_interval * col_width,
                   positions[ relative_position ].y
        end
    end

    -- 取得绝对data
    local function getData( index )
        return data[ index ]
    end

    local function resetObj( index )
        local relative_index = index % num_load
        if relative_index == 0 then relative_index = num_load end

        local data = getData( index )
        if data then
            -- all_obj[ relative_index ]:updateInfo( data )
            update_func( all_obj[ relative_index ], data )
            all_obj[ relative_index ].frame:setPosition( getPosition( index ) )

            all_obj[ relative_index ].win:SetIsVisible( true )
        else
            all_obj[ relative_index ].win:SetIsVisible( false )
        end
        all_obj[ relative_index ].index = index      -- add a index flag
    end

    local function resetEffectedObj( offset )
        local _begin = cur_offset * group_volume + 1
        local _end   = _begin + num_load - 1
        if offset > 0 then
            for index = _end - group_volume * math.abs( offset ) + 1, _end do resetObj( index ) end
        else
            for index = _begin, _begin + group_volume * math.abs( offset ) - 1 do resetObj( index ) end
        end
    end

    local function resetAllObj()
        local _begin = cur_offset * group_volume + 1
        local _end   = _begin + num_load - 1

        for index = _begin, _end do
            resetObj( index )
        end
    end

    resetAllObj()

    scroller:registerCallback(function()
        local scroller_position = scroller:getPosition()

        if direction == 'endwise' then
            cur_offset = math.floor( scroller_position / row_height )
            if cur_offset < 0 then return end

            if last_offset ~= cur_offset then
                resetEffectedObj( cur_offset - last_offset )
                last_offset = cur_offset
            end
        else
            cur_offset = math.floor( -scroller_position / col_width )
            if cur_offset < 0 then return end

            if last_offset ~= cur_offset then
                resetEffectedObj( cur_offset - last_offset )
                last_offset = cur_offset
            end
        end
    end)

    return {
        scroller    = scroller   ,
        getPosition = getPosition,
        all_obj     = all_obj    ,
    }
end
