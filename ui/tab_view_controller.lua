--=====================
-- Tab view Controller
--=====================
--
-- Container with tab bar with associated view.
-- When clicking a tab, it's view will appeara(if is accessible).
-- Will call different life cycle function of the tab at proper time.
--
-- Life cycle of view:
--   * onCreate        will provide a pview represent content area of this tab,
--                     pview is a CCNode itself
--                     pview.win is the window associated with this node
--   * onDestroy       must take a callback function as parameter,
--                     and call it after destroy is complete

_C_BASE_TAB_VIEW_CONTROLLER_ = class('_C_BASE_TAB_VIEW_CONTROLLER_')

function _C_BASE_TAB_VIEW_CONTROLLER_:ctor(...)
    local params = {...}
    local self = params[1]

    -- tab ctrl
    self.tab_win = params[2]
    self.tab_frame = self.tab_win:GetNode()
    local size_tab = getBoundingBox(self.tab_frame).size
    self.tab = create_tab_ctrl(1, size_tab.width)
    self.tab.frame:setPositionY(size_tab.height * -0.5 + self.tab.frame.mcBoundingBox.size.height * 0.5)
    self.tab_win:AddChildWindow(self.tab.win)

    -- view ctrl
    self.view = params[3]:GetNode()
    self.view.win = params[3]
    local size_view = getBoundingBox(self.view).size
end

function _C_BASE_TAB_VIEW_CONTROLLER_:fillTab(index)
    if self.cur_index == nil then
        self.view:removeAllChildrenWithCleanup(true)
        self.view.win:RemoveAllChildWindow()

        self.cur_index = index
        self.views[self.cur_index]:onCreate(self.tabs[self.cur_index], self.view)
    else
        self.tab_win:SetIsEnable(false)
        self.views[self.cur_index]:onDestroy(function()
            self.view:removeAllChildrenWithCleanup(true)
            self.view.win:RemoveAllChildWindow()

            self.cur_index = index
            self.views[self.cur_index]:onCreate(self.tabs[self.cur_index], self.view)
            self.tab_win:SetIsEnable(true)
        end)
    end
end

function _C_BASE_TAB_VIEW_CONTROLLER_:addTab(normal_state_pic, taped_state_pic, life_cycle)
    local is_first = false
    if not self.max_index then is_first = true end

    if is_first then
        self.max_index = 1
        self.views = {}
        self.tabs  = {}
    else
        self.max_index = self.max_index + 1
    end

    self.views[self.max_index] = life_cycle

    local this_index = self.max_index
    local tab = self.tab.t_ctrl:addTab(normal_state_pic, taped_state_pic, function()
        self:fillTab(this_index)
    end)
    self.tabs[self.max_index] = tab
end

function _C_BASE_TAB_VIEW_CONTROLLER_:init(default_index)
    self.tab.t_ctrl:layout()
    self.tab.t_ctrl:setCurSel(default_index or 1)
    self.cur_index = default_index or 1
end

function _C_BASE_TAB_VIEW_CONTROLLER_:destroy(callback)
    self.views[self.cur_index]:onDestroy(function()
        callback()
    end)
end

function createTabViewController(tab_win, view_win)
    local tvc = _C_BASE_TAB_VIEW_CONTROLLER_:new(tab_win, view_win)
    return tvc
end

--[[ demo of tab view controller
--  newUI_mall.lua
--]]
