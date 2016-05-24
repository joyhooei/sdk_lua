-- ./common/message_box.lua
require 'utils.CCNodeExtend'

local mb_info = {
    layer_type = layer_type_mask,                                               -- 所在层
    z_order = 0,                                                                -- z order
    modal_window_flag = false,                                                  -- 是否是模态窗口
    click_blank_close = true,                                                   -- 是否点击空白关闭
    mb_process = {
        ['MB_TITLE'] = function() return win, frame, width, height end,         -- 创建 title
        ['MB_CONTENT'] = function() return win, frame, width, height end,       -- 创建 content
        ['MB_BOTTOM'] = function() return win, frame, width, height end,        -- 创建 bottom
        ['MB_INIT'] = function( mb_obj ) end,                                   -- 初始化
        ['MB_SHOW_ANIM'] = function( mb_obj, cb ) end,                          -- 出现的动画
        ['MB_CLOSE_ANIM'] = function( mb_obj, cb ) end,                         -- 消失的动画
        ['MB_CLOSE'] = function( mb_obj ) end,                                  -- 销毁
    },
    show_anim_cb = function() end,                                              -- 出现的动画结束后的回调
}

mb_index = mb_index or 1
function createMessageBox( mb_info )
    mb_index = mb_index + 1
    local win, frame = create_frame_top_window_by_size( all_scene_layers[mb_info.layer_type], nil, mb_info.z_order, nil, string.format( 'mb_name_%d', mb_index ) )

    if mb_info.modal_window_flag then TLWindowManager:SharedTLWindowManager():SetModalWindow( win, true ) end

    -- message box 的外观，window 可有可没有，但 node 就一定要有
    local mb_real_width, mb_real_height = 0, 0

    -- title win & frame
    local title_win, title_frame, title_width, title_height = mb_info.mb_process['MB_TITLE']()
    if title_frame then
        if mb_real_width < ( title_width or title_frame.mcBoundingBox.size.width ) then mb_real_width = ( title_width or title_frame.mcBoundingBox.size.width ) end
        title_height = title_height or title_frame.mcBoundingBox.size.height
        mb_real_height = mb_real_height + title_height or title_frame.mcBoundingBox.size.height
    end

    -- content win & frame
    local content_win, content_frame, content_width, content_height = mb_info.mb_process['MB_CONTENT']()
    if mb_real_width < ( content_width or content_frame.mcBoundingBox.size.width ) then mb_real_width = ( content_width or content_frame.mcBoundingBox.size.width ) end
    content_height = content_height or content_frame.mcBoundingBox.size.height
    mb_real_height = mb_real_height + content_height

    -- bottom win & frame
    local bottom_win, bottom_frame, bottom_width, bottom_height = mb_info.mb_process['MB_BOTTOM']()
    if bottom_frame then
        if mb_real_width < ( bottom_width or bottom_frame.mcBoundingBox.size.width ) then mb_real_width = ( bottom_width or bottom_frame.mcBoundingBox.size.width ) end
        bottom_height = bottom_height or bottom_frame.mcBoundingBox.size.height
        mb_real_height = mb_real_height + bottom_height
    end

    -- 真正响应事件的区域，其他的空白区域，可以做成点击空白关闭
    local mb_frame = CCNodeExtend.extend( MCFrame:createWithBox( CCRect( -mb_real_width * 0.5, -mb_real_height * 0.5, mb_real_width, mb_real_height ) ) )
    frame:addChild( mb_frame )

    local color_layer = CCLayerColor:create( ccc4( 0, 0, 0, 180 ), frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height )
    frame:addChild( color_layer, -1 )
    color_layer:setPosition( frame.mcBoundingBox.size.width/-2, frame.mcBoundingBox.size.height/-2 )

    local mb_win = TLWindow:createWindow( mb_frame )
    mb_win:SetWindowName( 'mb_win' )
    win:AddChildWindow( mb_win )

    -- content_frame 被 title_frame 和 bottom_frame 盖住
    if title_frame then
        local title_x, title_y = 0, ( mb_real_height - ( title_height or 0 ) ) * 0.5
        title_frame:setPosition( title_x, title_y )
        mb_frame:addChild( title_frame, 1 )
    end

    local content_x, content_y = 0, mb_real_height * 0.5 - ( title_height or 0 ) - ( content_height or 0 ) * 0.5
    content_frame:setPosition( content_x, content_y )
    mb_frame:addChild( content_frame )

    if bottom_frame then
        local bottom_x, bottom_y = 0, ( ( bottom_height or 0 ) - mb_real_height ) * 0.5
        bottom_frame:setPosition( bottom_x, bottom_y )
        mb_frame:addChild( bottom_frame, 1 )
    end

    -- 事件将会优先响应 title_win 和 bottom_win
    if content_win then mb_win:AddChildWindow( content_win ) end
    if title_win then mb_win:AddChildWindow( title_win ) end
    if bottom_win then mb_win:AddChildWindow( bottom_win ) end

    -- 
    local ret_msg_box_obj = {
        win = win,
        frame = frame,
        mb_win = mb_win,
        mb_frame = mb_frame,
        title_height = title_height,
        content_height = content_height,
        bottom_height = bottom_height,
    }

    -- click event
    if mb_info.click_blank_close then
        init_simple_button( win, function()
            ret_msg_box_obj:close()
        end)
    end

    function ret_msg_box_obj:close()
        mb_info.mb_process['MB_CLOSE']( self )
        mb_info.mb_process['MB_CLOSE_ANIM']( self, function() self:destroy() end )
    end

    -- purge scene signal
    local purge_scene_signal_func = function() ret_msg_box_obj:destroy() end
    signal.listen( 'SYSTEM_PURGE_SCENE', purge_scene_signal_func )

    local is_alive = true
    function ret_msg_box_obj:destroy()
        is_alive = false
        signal.unlisten( 'SYSTEM_PURGE_SCENE', purge_scene_signal_func )

        if toCCNode( frame ) then frame:removeFromParentAndCleanup( true ) end
        if toTLWindow( win ) then TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( win ) end

        schedule_frames( 5, removeUnusedTextures )
    end

    function ret_msg_box_obj:isAlive()
        return is_alive
    end

    -- 创建完后，给一个初始化的机会
    mb_info.mb_process['MB_INIT']( ret_msg_box_obj )
    mb_frame:setVisible( false )
    -- 延迟一帧播出现动画，因为pop_window_base的open中使用到mb_info,需要先return
    mb_frame:tweenFromToOnce( LINEAR_IN, NODE_PRO_CUSTOM, 0, 1/24, 0, 1, function()
        mb_info.mb_process['MB_SHOW_ANIM']( ret_msg_box_obj, mb_info.show_anim_cb )

        -- 延迟一帧显示，就不会感觉到屏幕在闪
        mb_frame:tweenFromToOnce( LINEAR_IN, NODE_PRO_CUSTOM, 0, 1/24, 0, 1, function()
            mb_frame:setVisible( true )
        end, function() end )
    end, function() end )

    -- 
    return ret_msg_box_obj
end

--[==[
local message_cb_type = {
    'MB_LAYER',
    'MB_ORDER',
    'MB_MODAL',              -- 是否模态
    'MB_CLICK_BLANK_CLOSE',  -- 是否点击空白关闭
    'CONTENT_LIST',
    'MB_SHOW_ANIM_CB',       -- open_cb
    'MB_CLOSE',              -- close_cb
    'MB_CLOSE_BTN',          -- 是否显示关闭按钮, 接收一个关闭方法
    'MB_CONTENT_BACKGROUND', -- 是否显示内容区白底
    -- 'MB_CONTENT',
    -- 'MB_SHOW_ANIM',
    -- 'MB_CLOSE_ANIM',
    -- 'MB_TITLE',
    -- 'MB_BOTTOM',
    -- 'MB_INIT',
}
local message_button_skin = 'xjl_2UI_zjm/xjl_parts/button1'
local message_box_type = {
    [ 'MB_OK' ] = function( call_back_func )
        local button_info = {
            {
                text = 'OK',
                btn_mc_name = message_button_skin,
                btn_code = 'MB_OK',
                onclick = function( mb_obj ) end,
            },
        }

        return call_back_func( 'BTN_STYLE', button_info )
    end,
    [ 'MB_OKCANCEL' ] = function( call_back_func )
        local button_info = {
            {
                text = 'OK',
                btn_mc_name = message_button_skin,
                btn_code = 'MB_OK',
                onclick = function( mb_obj ) end,
            },
            {
                text = 'CANCEL',
                btn_mc_name = message_button_skin,
                btn_code = 'MB_CANCEL',
                onclick = function( mb_obj ) mb_obj:close() end,
            },
        }

        return call_back_func( 'BTN_STYLE', button_info )
    end,
}

local function message_content_creator( create_funcs )
    if #create_funcs == 1 then return create_funcs[1]() end

    local tmp_height = 0

    local ret_frame  = MCFrame:createWithBox( CCRect( -2, -2, 4, 4 ) )
    local ret_win    = TLWindow:createWindow( ret_frame )
    local ret_width  = 0
    local ret_height = 0

    local to_add_objs = {}
    for index, create_func in ipairs( create_funcs ) do
        local win, frame, width, height = create_func()

        if ( win and frame ) then
            width  = width or frame.mcBoundingBox.size.width
            height = height or frame.mcBoundingBox.size.height

            table.insert( to_add_objs, {
                win = win,
                frame = frame,
                width = width,
                height = height,
                offset_y = -height/2 - tmp_height
            } )

            tmp_height = tmp_height + height
            ret_width = math.max( ret_width, width )
            ret_height = ret_height + height
        end
    end

    ret_frame.mcBoundingBox.size.width = ret_width
    ret_frame.mcBoundingBox.size.height = ret_height
    ret_frame.mcBoundingBox.origin.x = ret_frame.mcBoundingBox.size.width / -2
    ret_frame.mcBoundingBox.origin.y = ret_frame.mcBoundingBox.size.height / -2
    ret_frame.mcOriginBoundingBox = ret_frame.mcBoundingBox
    for index, obj in ipairs( to_add_objs ) do
        ret_frame:addChild( obj.frame, 1 )
        ret_win:AddChildWindow( obj.win  )
        obj.frame:setPositionY( obj.offset_y + ret_height / 2 )
    end

    return ret_win, ret_frame, ret_width, ret_height
end

--- openMessageBox
-- 通用messagebox
-- @param[opt] title 标题
-- @param desc message内容
-- @param mb_type 按钮风格@see message_box_type
-- @param mb_process 其他自定义内容 @see testMessageBox
-- @return mb_obj
-- @usage openMessageBox( 'title', 'something' )
function __openMessageBox( title, desc, mb_type, mb_process )
    mb_process = mb_process or {}
    local padding1 = 17 -- 左右间隔
    local padding2 = 20 -- 上下间隔
    local mb_width = 500 -- 默认的msg_box宽度

    local function mb_call_back( mb_code, cb_tbl )
        local process_func = mb_process[mb_code]
        if process_func then cb_tbl = process_func( cb_tbl ) end
        return cb_tbl
    end

    local mb_info = { mb_process = {}, }
    local mb_obj

    mb_info.layer_type                    = mb_call_back( 'MB_LAYER', layer_type_fight_ui )
    mb_info.z_order                       = mb_call_back( 'MB_ORDER', 2 )
    mb_info.modal_window_flag             = mb_call_back( 'MB_MODAL', true )
    mb_info.click_blank_close             = mb_call_back( 'MB_CLICK_BLANK_CLOSE', true )

    local content_list = {
        function()
            if desc then
                local h = 100
                local node_str = TLLabelRichTex:create( desc or '', 24, CCSize( mb_width, h ), CCImage.kAlignCenter )

                local real_size = node_str:getRealSize()
                real_size.height = math.max( h, real_size.height )
                real_size.width = mb_width
                node_str:setContentSize( real_size )
                node_str:adjustLayout()

                local limit_height = 300
                if real_size.height > limit_height then
                    local frame = MCFrame:createWithBox( CCRect( mb_width/-2, limit_height/-2, mb_width, limit_height ) )
                    local win = TLWindow:createWindow( frame )

                    init_simple_button( win, function() showFloatTip( 'aaa' ) end )

                    local frame_scrlloer = MCFrame:createWithBox( frame.mcBoundingBox )
                    frame:addChild( frame_scrlloer )
                    frame_scrlloer:setInstanceName( 'frame_scrlloer' )
                    require 'ui.scroller'
                    local scroller = scrollable( win, 'frame_scrlloer', TL_SCROLL_TYPE_UP_DOWN, 0 )

                    scroller:append( node_str, true )


                    return win, frame, mb_width, limit_height
                else
                    local frame = MCFrame:createWithBox( CCRect( mb_width/-2, real_size.height/-2, mb_width, real_size.height ) )
                    local win = TLWindow:createWindow( frame )

                    -- local color_layer = CCLayerColor:create( ccc4( 0, 0, 0, 180 ), frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height )
                    -- frame:addChild( color_layer, -1 )
                    -- color_layer:setPosition( frame.mcBoundingBox.size.width/-2, frame.mcBoundingBox.size.height/-2 )

                    frame:addChild( node_str )

                    return win, frame, mb_width, real_size.height
                end
            end
        end,
    }
    content_list = mb_call_back( 'CONTENT_LIST', content_list )

    mb_info.mb_process[ 'MB_CONTENT' ]    = function() return message_content_creator( content_list ) end

    mb_info.show_anim_cb                  = mb_process[ 'MB_SHOW_ANIM_CB' ] or function() end
    mb_info.mb_process[ 'MB_CLOSE' ]      = mb_process[ 'MB_CLOSE' ] or function() end

    mb_info.mb_process[ 'MB_SHOW_ANIM' ]  = function( mb_obj, cb )
        local anim_sequence = {
            { node_anim_config['POP_WIN_SCALE_1'], node_anim_config['POP_WIN_ALPHA_1'] },
            { node_anim_config['POP_WIN_SCALE_2'] },
        }
        mb_obj.mb_frame:doAnimations( 1, anim_sequence, cb )
    end
    mb_info.mb_process[ 'MB_CLOSE_ANIM' ] = function( mb_obj, cb )
        local anim_sequence = {
            { node_anim_config['POP_WIN_SCALE_1'], node_anim_config['POP_WIN_ALPHA_2'] },
        }
        mb_obj.mb_frame:doAnimations( 1, anim_sequence, cb )
    end
    mb_info.mb_process[ 'MB_TITLE' ] = function()
        if not title then return end

        local font_size = 30
        local title_height = font_size + padding2 / 2
        local frame = MCFrame:createWithBox( CCRect( mb_width/-2, title_height/-2, mb_width, title_height ) )
        local frame_title = MCFrame:createWithBox( CCRect( mb_width/-2, font_size/-2, mb_width, font_size ) )
        frame:addChild( frame_title, 1 )
        frame_title:setPositionY( padding2 / 4 )

        local lbl_title = init_label( frame_title, font_size, CCImage.kAlignBottom )
        lbl_title:set_rich_string( title or '', TL_RICH_STRING_FLAG_ONE_LINE )

        return win, frame, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height
    end
    mb_info.mb_process[ 'MB_BOTTOM' ] = function()
        if message_box_type[ mb_type ] then
            local h = 60

            local frame = MCFrame:createWithBox( CCRect( mb_width/-2, h/-2, mb_width, h ) )
            local win = TLWindow:createWindow( frame )

            local button_info = message_box_type[mb_type]( mb_call_back )

            local max_height = h
            local obj_btns = {}

            for index, info in ipairs( button_info ) do
                local obj_btn = addAnimBtnToNode( info.btn_mc_name, function()
                    if mb_process[ info.btn_code ] then mb_process[ info.btn_code ]( mb_obj )
                    elseif info.onclick then info.onclick( mb_obj )
                    end
                end, info.text )
                obj_btn.frame:setScale( info.scale or 1 )

                max_height = math.max( max_height, obj_btn.frame.mcBoundingBox.size.height + 20 )
                table.insert( obj_btns, obj_btn )
            end

            frame.mcBoundingBox.size.height = max_height
            frame.mcBoundingBox.origin.y = frame.mcBoundingBox.size.height / -2
            frame.mcOriginBoundingBox = frame.mcBoundingBox

            for index, obj_btn in ipairs( obj_btns ) do
                frame:addChild( obj_btn.frame )
                win:AddChildWindow( obj_btn.win )

                obj_btn.frame:setPositionX( frame.mcBoundingBox.size.width / ( #obj_btns + 1 ) * index - 0.5 * frame.mcBoundingBox.size.width )
            end

            return win, frame, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height
        end
    end
    mb_info.mb_process[ 'MB_INIT' ] = function( mb_obj )
        -- 上下左右加了padding，把所有内容包了起来
        mb_obj.mb_frame.mcBoundingBox.size.width = mb_obj.mb_frame.mcBoundingBox.size.width + padding1 * 2
        mb_obj.mb_frame.mcBoundingBox.size.height = mb_obj.mb_frame.mcBoundingBox.size.height + padding2 * 2
        mb_obj.mb_frame.mcBoundingBox.origin.x = -mb_obj.mb_frame.mcBoundingBox.size.width/2
        mb_obj.mb_frame.mcBoundingBox.origin.y = -mb_obj.mb_frame.mcBoundingBox.size.height/2
        mb_obj.mb_frame.mcOriginBoundingBox = mb_obj.mb_frame.mcBoundingBox

        addSudokuToFrame( 'msg_box_1', mb_obj.mb_frame, nil, nil, nil, -3 )
        addPopWindowPattern( mb_obj.mb_frame, -2 )

        if title and ( mb_process[ 'MB_CONTENT_BACKGROUND' ] ~= false ) then
            -- TODO 做做标题的效果
            local w_sudoku = mb_obj.mb_frame.mcBoundingBox.size.width - padding1 * 2
            local h_sudoku = mb_obj.mb_frame.mcBoundingBox.size.height - mb_obj.title_height - padding2 * 2
            local sudoku = createSudoku( 'msg_box_2', w_sudoku, h_sudoku )
            mb_obj.mb_frame:addChild( sudoku.batch_node, -1 )
            sudoku.batch_node:setPositionY( mb_obj.title_height/-2 )
        end

        -- 关闭按钮
        if mb_process[ 'MB_CLOSE_BTN' ] then
            local frame_close = MCFrame:createWithBox( CCRect( -30, -30, 60, 60 ) )
            mb_obj.mb_frame:addChild( frame_close )
            frame_close:setPosition( mb_obj.mb_frame.mcBoundingBox.size.width/2-15, mb_obj.mb_frame.mcBoundingBox.size.height/2-15 )


            addAnimBtnToNode( 'xjl_2UI_zjm/xjl_parts/parts_32', function() mb_process[ 'MB_CLOSE_BTN' ]( mb_obj ) end, nil, frame_close, mb_obj.win, true )
        end
    end

    mb_obj = createMessageBox( mb_info )

    return mb_obj
end

function __testMessageBox()
    require 'common.pop_window_creator'
    return openMessageBox(
    '[SS:shadow=true,stroke=true]test_title',
    '[SS:shadow=true,stroke=true]test_content\ntest_content\ntest_content\ntest_content\ntest_content\ntest_content\ntest_content\ntest_content\ntest_content\ntest_content\n',
    'MB_OK',
    {
        ---[[
        CONTENT_LIST = function( content_list )
            table.insert( content_list, function()
                local mc = createMovieClipWithName( 'xjl_4UI_bg/xjl_parts/parts_30' )
                local win = TLWindow:createWindow( mc )

                local color_layer = CCLayerColor:create( ccc4( 0, 0, 0, 180 ), mc.mcBoundingBox.size.width, mc.mcBoundingBox.size.height )
                mc:addChild( color_layer, -1 )
                color_layer:setPosition( mc.mcBoundingBox.size.width/-2, mc.mcBoundingBox.size.height/-2 )

                return win, mc, mc.mcBoundingBox.size.width, mc.mcBoundingBox.size.height
            end )

            return content_list
        end,
        --]]
        -- MB_CLICK_BLANK_CLOSE = function() return false end,
        -- MB_MODAL = function() return false end,
        MB_CLOSE_BTN = function( mb_obj )
            mb_obj:close()
        end,
        MB_OK = function( mb_obj )
            showFloatTip( 'test_button' )
        end,
        MB_SHOW_ANIM_CB = function()
            showFloatTip( 'open_cb' )
        end,
        MB_CLOSE = function()
            showFloatTip( 'close_cb' )
        end,
        -- MB_CONTENT_BACKGROUND = false,
    } )
end
--]==]
