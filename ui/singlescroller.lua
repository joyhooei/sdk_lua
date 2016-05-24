--./ui/singlescroller.lua
require 'utils.CCNodeExtend'

-- 单页滚动控件
rolepos = {{0, 0, 1, 3}, {-200, -90, 0.7,2}, {200, -90, 0.7,1}}
roleposR = {{0, 0, 1, 3}, {-200, -90, 0.7,1}, {200, -90, 0.7,2}}

function getNodePos(obj, picNode, index)
	local picHeight = getBoundingBox(picNode).size.height * rolepos[index][3]
	local mknode = obj.mknode[index]
    if index == 1 then
        return mknode:getPositionX(), mknode:getPositionY() + (picHeight/2 - mknode:getContentSize().height/2) - 120
    elseif index == 2 then
        return mknode:getPositionX(), mknode:getPositionY() + (picHeight/2 - mknode:getContentSize().height/2) - 100
    elseif index == 3 then
        return mknode:getPositionX(), mknode:getPositionY() + (picHeight/2 - mknode:getContentSize().height/2) - 100
    end
end

function refreshPos(obj, index, shownode)
	local nodecur = getChildNode(shownode, 0);
	if nodecur:isVisible() then
		rolepos[index][1], rolepos[index][2] = getNodePos(obj,nodecur, index) 
		shownode:setPositionX( rolepos[index][1] )		
		shownode:setPositionY( rolepos[index][2] )		
		shownode:setScale(rolepos[index][3])
		shownode:setZOrder(rolepos[index][4])
		unCommonSchedule(obj.timehandle[index])
		shownode:setVisible(true)
	end
end

function single_scrollable(parentwin, name, setduration)
	
    local delay = 0		-- 动画延迟
    local duration = setduration or 1 -- 动画时间
	--local tweens = {}
    local playTipCount = 1
    
    -- 初始化window
    local frame = assert(toFrame(parentwin:GetNode():getChildByName(name)), string.format('not found child frame %s from %s', name, parentwin:GetNode():getInstanceName()))
    local win = TLWindow:createWindow(frame, TL_WINDOW_SCROLL)
    parentwin:AddChildWindow(win)
    --frame:setClipRegion(frame.mcBoundingBox)
	--
	local contentnode = win:GetNode()
	local isPlay = false

    -- 滚动控件对象
    local scroller = {
		frame = frame,
        contentnode = contentnode,
        window = win,
        parent = parentwin,
        lastMousePosition = 0,
        sort_dict = {}, 
        currentIndex = 0,
		nodeposCount = 0,
		timehandle = {},
		mknode = {},
		posOffset = {},
    }

    -- 添加元素到滚动区域的末尾
    function scroller:append(obj)
        local mc_node = CCNodeExtend.extend( CCNode:create() )
        if tolua.type(obj.viewWin)=='TLWindow' then
            mc_node:addChild(obj.viewWin:GetNode())
            self.contentnode:addChild(mc_node)
            win:AddChildWindow(obj.viewWin)
        else
            mc_node:addChild(obj.viewWin)
            self.contentnode:addChild(mc_node)
        end
        obj.mc_node = mc_node

		local indexNode = #self.sort_dict+1
		if self.currentIndex == 0 then
			self.currentIndex = self.currentIndex+1
		end

        if indexNode == 1 then 
			if obj.setInfoFunc ~= nil then
				obj.setInfoFunc(obj.heroID)
			end
			self.frame:setClipRegion(self.frame.mcBoundingBox)
		end
		mc_node:setVisible(true) 	
		local nodecur = getChildNode(mc_node, 0);
		nodecur:setVisible(true)
		--FIXME: 以后有更好的方法在替换
		self.timehandle[indexNode] = schedule_circle(0.001, refreshPos,self, indexNode, mc_node)
		self.sort_dict[indexNode] = obj
		if indexNode == 1 then
			getChildNode(self.sort_dict[indexNode].mc_node, 0):setColor(ccc3(255,255,255))
			getChildNode(self.sort_dict[indexNode].mc_node, 0):setOpacity(255)
		else
			getChildNode(self.sort_dict[indexNode].mc_node, 0):setColor(ccc3(127,127,127))
			getChildNode(self.sort_dict[indexNode].mc_node, 0):setOpacity(240)
		end
	end

    -- 计算内容边界
    local box = getBoundingBox(win:GetNode())
    local left = box.origin.x

    -- 移除元素的接口
    function scroller:removeall()
        self:stop()

        win:RemoveAllChildWindow()
        contentnode:removeAllChildrenWithCleanup(true)

        self.sort_dict = {}
		self.currentIndex = 0
    end

	-- 停止定时器
	function scroller:stop()
		if self.timehandle then
			for i, handle in pairs(self.timehandle) do
				unCommonSchedule(handle)
				self.timehandle[i] = nil
			end
		end
	end

	-- 播放滚动动画    
    function scroller:play(ci, ni, left)
		if not isPlay and #self.sort_dict > 1 then			
			-- 取得要做动画的两个控件
			isPlay = true
			local next = 0
			local roleposTmp = nil
			if ci > ni then
				next = -1
				roleposTmp = roleposR
			else
				next = 1
				roleposTmp = rolepos
			end

			if ni > #self.sort_dict then ni = 1 end		
			if ni < 1 then ni = #self.sort_dict end		
			self.currentIndex = ni

			--CCLuaLog('ci:' .. tostring(ci)..'ni:'..tostring(ni)..'nextIndex:'..tostring(nextIndex))

			local newIndexT = {}
			local index = self.currentIndex
			for i = 1, #rolepos do
				newIndexT[i] = index
				index = index + 1
				if index > #rolepos then
					index = 1
				end
				--CCLuaLog('newIndexT:' .. tostring(newIndexT[i]))
			end
			
			-- 开始做动画
			for i = 1, #rolepos do
				roleposTmp[newIndexT[i]][1], roleposTmp[newIndexT[i]][2] = getNodePos(self, getChildNode(self.sort_dict[i].mc_node, 0), newIndexT[i])
				if newIndexT[i] == 1 then 
					roleposTmp[newIndexT[i]][1] = roleposTmp[newIndexT[i]][1] + self.posOffset[i]
				end

                local node = self.sort_dict[i].mc_node
                local x,y = node:getPosition()
                local scale = node:getScale()
                node:tweenFromToOnce( LINEAR_INOUT, NODE_PRO_X, delay, duration, x, roleposTmp[newIndexT[i]][1] )
                node:tweenFromToOnce( LINEAR_INOUT, NODE_PRO_Y, delay, duration, y, roleposTmp[newIndexT[i]][2] )
                node:tweenFromToOnce( LINEAR_INOUT, NODE_PRO_SCALE, delay, duration, scale, roleposTmp[newIndexT[i]][3], function() isPlay = false end )

				self.sort_dict[i].mc_node:setZOrder(roleposTmp[newIndexT[i]][4])
				if newIndexT[i] == 1 then
					getChildNode(self.sort_dict[i].mc_node, 0):setColor(ccc3(255,255,255))
					getChildNode(self.sort_dict[i].mc_node, 0):setOpacity(255)
				else
					getChildNode(self.sort_dict[i].mc_node, 0):setColor(ccc3(127,127,127))
					getChildNode(self.sort_dict[i].mc_node, 0):setOpacity(240)
				end
			end

			local showObj = self.sort_dict[ni]
			if showObj.setInfoFunc ~= nil then
				local heroID = showObj.heroID
				showObj.setInfoFunc(heroID)
			end
		end
	end
        
    -- 播放下一个
    function scroller:playNext()
		self:play(self.currentIndex, self.currentIndex + 1, false)
		--CCLuaLog('playNext' .. tostring(self.currentIndex))
    end
    
    -- 播放下上个
    function scroller:playPrev()	
		self:play(self.currentIndex, self.currentIndex - 1, true)
		--CCLuaLog('playPrev' .. tostring(self.currentIndex))
    end

	-- 开始拖拽
    function scroller.touchbegin(p)
		scroller.lastMousePosition = p
    end
    
    -- 结束拖拽
    function scroller.touchend(p)
		if scroller.lastMousePosition ~= p then
			playTipCount = playTipCount + 1

			--CCLuaLog('lastMousePosition :' .. tostring(scroller.lastMousePosition)..'p:'..tostring(p))
			if p < scroller.lastMousePosition then			
				scroller:playNext()
			else 
				scroller:playPrev()
			end			
		end
	end
    
    -- 注册鼠标事件
    local winManager = TLWindowManager:SharedTLWindowManager()    
    win:RegisterEvent(TL_EVENT_BUTTON_DOWN, function() scroller.touchbegin(winManager:getLastPointX()) end)
    win:RegisterEvent(TL_EVENT_BUTTON_UP, function() scroller.touchend(winManager:getLastPointX()) end)
    win:RegisterEvent(TL_EVENT_BUTTON_RELEASE, function() scroller.touchend(winManager:getLastPointX()) end)    

	return scroller
end
