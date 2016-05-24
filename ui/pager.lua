--./ui/pager.lua
require 'ui.scroller'
require 'utils.table'

function update_pager_buttons(container, pagecount, current_page, frameOn, frameOff)
    local c = container:getChildrenCount()
    if c>pagecount then
        -- remove
        for i=c-1,pagecount,-1 do
            getChildNode(container, i):removeFromParentAndCleanup(true)
        end
    elseif c<pagecount then
        -- add
        for i=c,pagecount-1 do
            container:addChild(CCSprite:createWithSpriteFrame(frameOn))
        end
    end

    local size = 0
    for i=0,container:getChildrenCount()-1 do
        size = size + getChildNode(container, i):getContentSize().width
    end

    local offset = -size/2
    for i=0,container:getChildrenCount()-1 do
        local node = toSprite(getChildNode(container, i))
        if i==current_page then
            node:setDisplayFrame(frameOn)
        else
            node:setDisplayFrame(frameOff)
        end
        node:setPositionX(offset + node:getContentSize().width/2)
        offset = offset + node:getContentSize().width
    end
end

-- pager
function pager(pWin, name, scrollType, button_space, callfunc)
    local currentpage = 0  -- 从0开始

    button_space = button_space or 0
    -- 不实现 TL_SCROLL_TYPE_NONE
    assert(scrollType~=TL_SCROLL_TYPE_NONE, 'invalid scrollType'..tostring(scrollType))

    -- 初始化window
    local frame = assert(toFrame(pWin:GetNode():getChildByName(name)),
                         string.format('not found child frame %s from %s', name, pWin:GetNode():getInstanceName()))

    local win = TLWindow:createWindow(frame, TL_WINDOW_SCROLL)
    pWin:AddChildWindow(win)

    -- 创建clip和容器node
    local box = CCRectMake(frame.mcBoundingBox.origin.x, frame.mcBoundingBox.origin.y, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height)

    -- 内容容器
    --if scrollType==TL_SCROLL_TYPE_UP_DOWN then
    --    box.origin.x = box.origin.x + button_space
    --    box.size.width = box.size.width - button_space
    --else
    --    box.origin.y = box.origin.y + button_space
    --    box.size.height = box.size.height - button_space
    --end

    local clipframe = MCFrame:createWithBox(box)
    clipframe:setClipRegion(box)
    frame:addChild(clipframe)

    local contentnode = CCNode:create()
    clipframe:addChild(contentnode)

    -- 分页按钮容器
    local button_container = CCNode:create()
    frame:addChild(button_container)

    if scrollType==TL_SCROLL_TYPE_UP_DOWN then
        button_container:setPositionX(frame.mcBoundingBox.origin.x+button_space/2)
    else
        button_container:setPositionY(frame.mcBoundingBox.origin.y+button_space/2)
    end

    local pagerobj = init_scrollable(win, clipframe, contentnode, scrollType)
    pagerobj.parent = pWin
    pagerobj.w_scale = 1
    pagerobj.h_scale = 1
    pagerobj.callfunc = callfunc

    function pagerobj.touchend(_)
        -- 遍历子节点，寻找最接近的目标
        local self = pagerobj
        local pp = self.impl:free_scroll_target()
        local ps = {}
        for i=1,self.contentnode:getChildrenCount() do
            local pagenode = getChildNode(self.contentnode, i-1)
            local bb = getBoundingBox(pagenode)

            local p
            if scrollType == TL_SCROLL_TYPE_UP_DOWN then
                p = -pagenode:getPositionY()
                if self.h_scale ~= 1 then p = p - bb.size.height * self.h_scale end
            else
                p = -pagenode:getPositionX()
                if self.w_scale ~= 1 then p = p - bb.size.width * self.w_scale end
            end
            table.insert(ps, math.abs(p-pp))
        end
        local mini, minv = table.min(ps)
        self:scroll_page(
            setbound(mini and mini-1 or 0,
                     math.max(0, currentpage-1),
                     math.min(self:pagecount()-1, currentpage+1)
                    )
        )
    end

    -- 计算内容边界
    local box = frame.mcBoundingBox
    local top
    local left
    if scrollType==TL_SCROLL_TYPE_UP_DOWN then
        -- top
        top = box.origin.y+box.size.height
    else
        left = box.origin.x
    end

	local frameOn = MCLoader:sharedMCLoader():loadSpriteFrame( 'Nui_0020_14.png' );
    frameOn:retain()
	local frameOff = MCLoader:sharedMCLoader():loadSpriteFrame( 'Nui_0020_15.png' );
    frameOff:retain()
    function pagerobj:updatepage(i)
        currentpage = i
        update_pager_buttons(button_container, self:pagecount(), currentpage, frameOn, frameOff)
    end

    function pagerobj:jump_page(i)
        assert(i<self.contentnode:getChildrenCount(), 'invalid page index')
        local pagenode = getChildNode(self.contentnode, i)
        local bb = getBoundingBox(pagenode)
        local p
        local bb = getBoundingBox(pagenode)
        if scrollType == TL_SCROLL_TYPE_UP_DOWN then
            p = -pagenode:getPositionY()
            if self.h_scale ~= 1 then p = p - bb.size.height end
        else
            p = -pagenode:getPositionX()
            if self.w_scale ~= 1 then p = p - bb.size.width end
        end
        self.impl:stop_animation()
        self.impl:reset_position(p) -- 重置状态
        self.impl:set_position(p)   -- 设置position
        self:updatepage(i)
        if self.callfunc then self.callfunc() end
    end

    function pagerobj:scroll_page(i)
        assert(i<self.contentnode:getChildrenCount(), 'invalid page index')
        local pagenode = getChildNode(self.contentnode, i)
        local bb = getBoundingBox(pagenode)
        local p
        if scrollType == TL_SCROLL_TYPE_UP_DOWN then
            p = -pagenode:getPositionY()
            if self.h_scale ~= 1 then p = p - bb.size.height end
        else
            p = -pagenode:getPositionX()
            if self.w_scale ~= 1 then p = p - bb.size.width end
        end
        self:scrollto(p)
        self:updatepage(i)
        if self.callfunc then self.callfunc() end

    end

    function pagerobj:pagecount()
        local count = contentnode:getChildrenCount()
        if self.w_scale ~= 1 or self.h_scale ~= 1 then count = count - 1 end
        return count
    end
    function pagerobj:currentpage()
        return currentpage
    end
    -- pager 接口
    function pagerobj:newpage( relayout, w_scale, h_scale )
        self.w_scale = w_scale or 1
        self.h_scale = h_scale or 1
        local box = copy_rect( frame.mcBoundingBox )
        box.size.width = box.size.width * self.w_scale
        box.size.height = box.size.height * self.h_scale
        box.origin.x = -box.size.width * 0.5
        box.origin.y = -box.size.height * 0.5
        local pagenode = MCFrame:createWithBox(box)
        local win = TLWindow:createWindow(pagenode)
        self:append(win, relayout)
        self:updatepage(currentpage)
        return win
    end
    -- get page
    function pagerobj:getpage(i)
        return toTLWindow(self.window:GetChildWindow():objectAtIndex(i))
    end

    -- overwrite remove
    local super_removeall = pagerobj.removeall
    function pagerobj:removeall()
        super_removeall(self)
        self:updatepage(0)
    end
    local super_remove = pagerobj.remove
    function pagerobj:remove(page)
        super_remove(self, page)
        if currentpage>self:pagecount()-1 then
            currentpage = self:pagecount()-1
        end
        self:updatepage(currentpage)
    end
    return pagerobj
end
