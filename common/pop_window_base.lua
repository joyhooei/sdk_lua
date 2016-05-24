-- ./utils/pop_window_base.lua
require 'utils.class'

local pop_window_base = class( 'pop_window_base' )
function pop_window_base:ctor()
    self.mb_info = {
        layer_type = layer_type_fight_ui,                                           -- 所在层
        z_order = 2,                                                                -- z order
        modal_window_flag = false,                                                  -- 是否是模态窗口
        click_blank_close = true,                                                   -- 是否点击空白关闭
        mb_process = {
            ['MB_TITLE'] = function() return self:createTitle() end,                -- 创建 title
            ['MB_CONTENT'] = function() return self:createContent() end,            -- 创建 content
            ['MB_BOTTOM'] = function() return self:createBottom() end,              -- 创建 bottom
            ['MB_INIT'] = function( mb_obj ) self:init( mb_obj ) end,               -- 初始化
            ['MB_SHOW_ANIM'] = function( mb_obj, cb ) self:playShowAnim( cb ) end,  -- 出现的动画
            ['MB_CLOSE_ANIM'] = function( mb_obj, cb ) self:playCloseAnim( cb ) end,-- 消失的动画
            ['MB_CLOSE'] = function( mb_obj ) self:onClose() end,                   -- 销毁
        },
        show_anim_cb = function()                                                   -- 出现的动画结束后的回调
            self:onOpenCallback()

            if self.extern_open_cb then
                self.extern_open_cb()
            end
        end,
    }

    -- 外部传递进来的 open callback
    -- 内部的，使用 pop_window_base:onOpenCallback 
    self.extern_open_cb = nil
    self.extern_close_cb = nil
end

function pop_window_base:open( open_call_back )
    self.extern_open_cb = open_call_back

    -- 
    require 'common.message_box'
    self.mb_obj = createMessageBox( self.mb_info )
end

function pop_window_base:onOpenCallback()
end

function pop_window_base:createTitle() end
function pop_window_base:createContent() end
function pop_window_base:createBottom() end
function pop_window_base:init() end                                     -- 初始化，在调用了 createTitle, createContent, createBottom 后，才会被调用
function pop_window_base:onClose() end                                  -- 清理，message_box 的 click_blank_close 属性，可以在点击空白的时候，自动的销毁
function pop_window_base:close( close_cb )                              -- 拿到一个 pop_window_obj，想要主动的 close，就使用这个方式，这个方法最终会调用到 pop_window_base:onClose()
    self.extern_close_cb = close_cb

    self.mb_obj:close()
end
function pop_window_base:isAlive() return self.mb_obj:isAlive() end   -- msg box 是否活跃
function pop_window_base:destroy()                                      -- 主动销毁，没有机会被调用到 CloseAnim [MB_CLOSE]，所以需要主动调用 self:onClose() 进行清理
    self:onClose()
    self.mb_obj:destroy()
end

function pop_window_base:playShowAnim( cb )
    local anim_sequence = {
        { node_anim_config['POP_WIN_SCALE_1'], node_anim_config['POP_WIN_ALPHA_1'] },
        { node_anim_config['POP_WIN_SCALE_2'] },
    }
    self.mb_obj.mb_frame:doAnimations( 1, anim_sequence, cb )
end

function pop_window_base:playCloseAnim( cb )
    local anim_sequence = {
        { node_anim_config['POP_WIN_SCALE_1'], node_anim_config['POP_WIN_ALPHA_2'] },
    }
    self.mb_obj.mb_frame:doAnimations( 1, anim_sequence, function()
        if self.extern_close_cb then self.extern_close_cb() end
        self.extern_close_cb = nil

        if cb then cb() end
    end)
end

return pop_window_base
