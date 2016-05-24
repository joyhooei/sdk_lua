-- Filename      : ./win32_client/common/relative_layout.lua
-- Description   :
-- Last modified : 2016-03-31 14:05

----------------------------------------
--- 相对于节点的相对布局layout
-- @author colin
----------------------------------------

require 'utils.class'
require 'utils.CCNodeExtend'

local winSize = getWinRealSize()

--- enum_relative_layout_align
-- 相对布局layout对齐枚举
-- @param top_left
-- @param top
-- @param top_right
-- @param left
-- @param center
-- @param right
-- @param bottom_left
-- @param bottom
-- @param bottom_right
-- @table enum_relative_layout_align
local relative_layout_align = {
    'top_left'   , 'top'   , 'top_right'   ,
    'left'       , 'center', 'right'       ,
    'bottom_left', 'bottom', 'bottom_right',
}
enum_relative_layout_align = table.k2v( relative_layout_align, 0 )

--- getRelativePositon
-- 根据对齐方式取得子节点相对于父节点的位置偏移
-- @param child_node 子节点
-- @param parent_node 父节点
-- @param enum_alignment 枚举于enum_relative_layout_align
-- @return x 子节点的x位置
-- @return y 子节点的y位置
-- @usage local x, y = getRelativePositon( child_node, parent_node, enum_relative_layout_align.top )
-- @see enum_relative_layout_align
local function getRelativePositon( child_node, parent_node, enum_alignment )
    local dest_positon_x, dest_positon_y = 0, 0

    local width_child, height_child = child_node.mcBoundingBox.size.width, child_node.mcBoundingBox.size.height
    local width_parent, height_parent = parent_node.mcBoundingBox.size.width, parent_node.mcBoundingBox.size.height
    local align_type = relative_layout_align[ enum_alignment ]

    if string.find( align_type, 'left' ) then dest_positon_x = ( width_child - width_parent ) / 2 end
    if string.find( align_type, 'right' ) then dest_positon_x = ( width_parent - width_child ) / 2 end
    if string.find( align_type, 'top' ) then dest_positon_y = ( height_parent - height_child ) / 2 end
    if string.find( align_type, 'bottom' ) then dest_positon_y = ( height_child - height_parent ) / 2 end

    return dest_positon_x, dest_positon_y
end

--- getRelativePositonBaseScreen
-- 根据对齐方式取得子节点相对于屏幕的位置偏移
-- @param child_node 子节点
-- @param enum_alignment 枚举于enum_relative_layout_align
-- @return x 子节点的x位置
-- @return y 子节点的y位置
-- @usage local x, y = getRelativePositonBaseScreen( child_node, enum_relative_layout_align.top )
-- @see enum_relative_layout_align
local function getRelativePositonBaseScreen( child_node, enum_alignment )
    local dest_positon_x, dest_positon_y = 0, 0

    local width_child, height_child = child_node.mcBoundingBox.size.width, child_node.mcBoundingBox.size.height
    local align_type = relative_layout_align[ enum_alignment ]

    local win_width, win_height = winSize.width, winSize.height

    if string.find( align_type, 'left' ) then dest_positon_x = ( width_child - win_width ) / 2 end
    if string.find( align_type, 'right' ) then dest_positon_x = ( win_width - width_child ) / 2 end
    if string.find( align_type, 'top' ) then dest_positon_y = ( win_height - height_child ) / 2 end
    if string.find( align_type, 'bottom' ) then dest_positon_y = ( height_child - win_height ) / 2 end

    return dest_positon_x, dest_positon_y
end

--- 相对布局rl_info的默认内容
-- @param[opt] RL_PARENT_NODE 父节点
-- @param[opt] RL_PARENT_WIN 父响应窗口
-- @param[opt=1] RL_ORDER zOrder
-- @param[opt=enum_relative_layout_align.top] RL_ALIGN 对齐方式
-- @param[opt] RL_INIT 额外的初始化方法 RL_INIT = function( rl_obj ) dosomething end,
-- @param RL_CONTENT 创建内容的方法 RL_CONTENT = function( rl_obj ) return mc, win end
-- @param[opt=0] RL_X_OFFSET X 方向的偏移
-- @param[opt=0] RL_Y_OFFSET Y 方向的偏移
-- @param[opt] RL_OPEN_CB open的回调
-- @table rl_info
-- @see enum_relative_layout_align
local default_rl_info = {
    RL_PARENT_NODE    = nil,                            -- 父节点
    RL_PARENT_WIN     = nil,                            -- 父相应窗口
    RL_ORDER          = 1,                              -- zOrder
    RL_ALIGN          = enum_relative_layout_align.top, -- 对其方式，参见 enum_relative_layout_align
    RL_INIT           = function( rl_obj ) end,         -- 额外的初始化方法 RL_INIT = function( rl_obj ) dosomething end,
    RL_CONTENT        = function( rl_obj ) end,         -- 创建内容的方法 RL_CONTENT = function( rl_obj ) return mc, win end
    RL_X_OFFSET       = 0,                              -- X 方向的偏移
    RL_Y_OFFSET       = 0,                              -- Y 方向的偏移
    RL_OPEN_CB        = nil,                            -- open的回调
}

local relative_layout_module = class( 'relative_layout_module' )
function relative_layout_module:ctor( rl_info )
    self.rl_info = clone( default_rl_info )
    table.update( self.rl_info, rl_info )

    self.show_anim_list  = {}
    self.close_anim_list = {}
    self.guide_items     = {}
end

function relative_layout_module:init()
    self:createContent()
    self:onLayout()

    -- 额外的init机会
    self.rl_info.RL_INIT( self )
end

-- 创建内容
function relative_layout_module:createContent()
    self.mc, self.win = self.rl_info.RL_CONTENT( self )
    CCNodeExtend.extend( self.mc )
    self.is_alive = true
end

-- 根据rl_info.RL_ALIGN进行布局
function relative_layout_module:onLayout()
    local x_offset = self.rl_info.RL_X_OFFSET or 0
    local y_offset = self.rl_info.RL_Y_OFFSET or 0

    local function layoutToParent()
        -- 放到父节点目的地去
        self.mc_parent:addChild( self.mc, self.rl_info.RL_ORDER )
        self.dest_positon_x, self.dest_positon_y = getRelativePositon( self.mc, self.mc_parent, self.rl_info.RL_ALIGN )
        self.mc:setPosition( self.dest_positon_x + x_offset, self.dest_positon_y + y_offset )

        if toTLWindow( self.rl_info.RL_PARENT_WIN ) then
            if toTLWindow( self.win ) then
                self.rl_info.RL_PARENT_WIN:AddChildWindow( self.win )
            end
        end
    end

    local function layoutToScreen()
        -- 放到屏幕目的地去
        self.mc_parent:addChild( self.mc, self.rl_info.RL_ORDER )
        self.dest_positon_x, self.dest_positon_y = getRelativePositonBaseScreen( self.mc, self.rl_info.RL_ALIGN )
        self.mc:setPosition( self.dest_positon_x + x_offset, self.dest_positon_y + y_offset )

        if toTLWindow( self.win ) then
            TLWindowManager:SharedTLWindowManager():AddModuleWindow( self.win )
        end
    end

    if self.rl_info.RL_PARENT_NODE then
        -- 如果有传入父节点，使用父节点作为相对布局停靠
        self.mc_parent = self.rl_info.RL_PARENT_NODE
        layoutToParent()
    elseif self.rl_info.RL_PARENT_WIN then
        -- 如果有传入父窗口，使用父窗口作为相对布局停靠
        self.mc_parent = self.rl_info.RL_PARENT_WIN:GetNode()
        layoutToParent()
    else
        -- 使用屏幕作为相对布局停靠
        self.mc_parent = all_scene_layers[ layer_type_fight_ui ]
        layoutToScreen()
    end
end

-- 注册入场动画
function relative_layout_module:addShowAnim( mc, anim_sequence )
    self.show_anim_list[CCNodeExtend.extend(mc)] = anim_sequence

    -- 避免需要播入场动画的元件在原地闪一下
    mc:setVisible( false )
end

-- 注册离场动画
function relative_layout_module:addCloseAnim( mc, anim_sequence )
    self.close_anim_list[CCNodeExtend.extend(mc)] = anim_sequence
end

-- 播放所有注册的入场动画，并在播放完毕的时候调用回调
function relative_layout_module:playShowAnim( open_call_back )
    local count = table.len( self.show_anim_list )
    if count == 0 then
        if open_call_back then open_call_back() end
    end

    for mc, anim_sequence in pairs( self.show_anim_list ) do
        -- 有入场动画的mc会被隐藏，一帧后设置可见
        mc:tweenFromToOnce( LINEAR_IN, NODE_PRO_CUSTOM, 0, 1/24, 0, 1, function() mc:setVisible( true ) end, function() end )

        mc:doAnimations( 1, anim_sequence, function()
            count = count - 1
            if count == 0 then if open_call_back then open_call_back() end end
        end )
    end
end

-- 播放所有注册的离场动画，并在播放完毕的时候调用回调
function relative_layout_module:playCloseAnim( close_call_back )
    local count = table.len( self.close_anim_list )
    if count == 0 then
        self.mc:doAnimations( 1, { { node_anim_config[ 'RL_DELAY' ] } }, function()
            -- 一帧后再做
            if close_call_back then close_call_back() end
        end )
    end

    for mc, anim_sequence in pairs( self.close_anim_list ) do
        mc:doAnimations( 1, anim_sequence, function()
            count = count - 1
            if count == 0 then if close_call_back then close_call_back() end end
        end )
    end
end

-- 初始化并打开，调用init & playCloseAnim， 并传入open_call_back
function relative_layout_module:open( open_call_back )
    self:init()

    self:playShowAnim( function()
        self:onOpenCallback()

        if open_call_back then open_call_back() end
    end )
end

-- 出现动画回调，在open的时候回调
function relative_layout_module:onOpenCallback() if self.rl_info.RL_OPEN_CB then self.rl_info.RL_OPEN_CB() end end

-- 关闭，最终会调到destroy
function relative_layout_module:close( close_call_back )
    self:playCloseAnim( function()
        if close_call_back then close_call_back() end

        self:destroy()
    end )
end

-- 清理，在destroy的时候被调用
function relative_layout_module:onClose() end

-- 销毁，不多说了
function relative_layout_module:destroy()
    if toCCNode( self.mc ) then self.mc:removeFromParentAndCleanup( true ) end
    if toTLWindow( self.rl_info.RL_PARENT_WIN ) then
        -- 如果有父窗口，从父窗口移除self.win
        if toTLWindow( self.win ) then self.rl_info.RL_PARENT_WIN:RemoveAllChildWindow( self.win ) end
    elseif toTLWindow( self.win ) then
        -- 否则从moduleWindow中移除self.win
        TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( self.win )
    end

    self:onClose()
    schedule_frames( 5, removeUnusedTextures )

    self.is_alive = false
end

function relative_layout_module:isAlive() return self.is_alive end

-- 开始引导的入口
function relative_layout_module:startModuleGuide()
    -- guide_manager:startGuide( 'xxx' )
end

function relative_layout_module:setGuideNodeItem( name, item )
    self.guide_items[ name ] = item
end

-- 获得引导节点的方法
function relative_layout_module:getGuideNodeItem( name )
    return self.guide_items[ name ]
end

return relative_layout_module
