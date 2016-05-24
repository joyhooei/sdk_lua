-- ./utils/pop_window_module.lua

---- 一定需要重载的方法有：
--function pop_window_module:createContent() return win, frame, width, height end           -- 创建窗体的内容节点
--function pop_window_module:init() end                                                     -- 初始化窗体的控件以及数据等
--
---- 可选的重载方法有：
--function pop_window_module:createTitle() return win, frame, width, height end             -- 创建窗体的 title ( 如果有的话 )
--function pop_window_module:createBottom() return win, frame, width, height end            -- 创建窗体的 bottom ( 如果有的话 )
--function pop_window_module:playShowAnim( cb ) cb() end                                    -- 窗体的出现动画
--function pop_window_module:playCloseAnim( cb ) cb() end                                   -- 窗体的关闭动画
--function pop_window_module:onClose( cb ) cb() end                                         -- 窗体在关闭时候，清理的
--function pop_window_module:onOpenCallback() end                                           -- 窗体打开后的回调
--function pop_window_module:getDataFromServer( cb ) cb() end                               -- 从服务器拉取数据
--function pop_window_module:startModuleGuide() end                                         -- 如果窗体有可能触发引导的话，从这里开始
--function pop_window_module:getGuideNodeItem( name ) return self.guide_items[name] end     -- 获取窗体引导的节点项

local pop_base = require 'common.pop_window_base'
local pop_window_module = class( 'pop_window_module', pop_base )
function pop_window_module:ctor()
    pop_base.ctor( self )

    -- 引导
    -- self.guide_items['xxx'] = {
    --      node = node,
    --      onClickFunc = function( guide_cb ) end,
    -- }
    self.guide_items = {}
end

function pop_window_module:open( open_call_back )
    -- 如果需要从服务器拉取数据的，就等数据回来后，才真的打开
    self:getDataFromServer( function()
        pop_base.open( self, open_call_back )
    end)
end

-- 在打开的回调里，触发当前模块的引导
function pop_window_module:onOpenCallback()
    pop_base.onOpenCallback( self )

    self:startModuleGuide()
end

function pop_window_module:getDataFromServer( call_back_func )
    call_back_func()
end

-- 从当前模块开始的引导，在这里触发
function pop_window_module:startModuleGuide()
    -- guide_manager:startGuide( 'xxx' )
end

function pop_window_module:getGuideNodeItem( name )
    return self.guide_items[name]
end

return pop_window_module
