-- Filename      : ./win32_client/common/message_box_module.lua
-- Description   :
-- Last modified : 2016-04-25 17:49

local mb_width = 500
local pop_window_creator = require 'common.pop_window_creator'

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

local message_box_module = class( 'message_box_module', pop_window_creator )

function message_box_module:open( open_call_back, title, content_list, bottom_list, is_show_close_button, is_show_content_background, click_blank_close )
    self:setTitleString( title )
    self:setContentList( content_list )
    self:setBottomList( bottom_list )
    self:setCloseButtonIsShow( is_show_close_button )
    self:setContentBackgroundShow( is_show_content_background )
    self:setClickBlankClose( click_blank_close )

    pop_window_creator.open( self, open_call_back )
end

function openMessageBox( title, desc, mb_type, mb_process )
    local function mb_call_back( mb_code, cb_tbl )
        local process_func = mb_process[mb_code]
        if process_func then cb_tbl = process_func( cb_tbl ) end
        return cb_tbl
    end

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

                    frame:addChild( node_str )
                    return win, frame, mb_width, real_size.height
                end
            end
        end,
    }
    content_list = mb_call_back( 'CONTENT_LIST', content_list )

    local mb_obj
    local bottom_list = {
        function()
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
        end,
    }

    local is_show_close_button       = mb_process[ 'MB_CLOSE_BTN' ]
    local is_show_content_background = mb_process[ 'MB_CONTENT_BACKGROUND' ] ~= false
    local click_blank_close          = mb_process[ 'MB_CLICK_BLANK_CLOSE' ] ~= false

    -- require 'common.pop_window_manager'
    -- mb_obj = openModulePopWindow( 'common.message_box_module', nil, title, content_list, bottom_list, is_show_close_button, is_show_content_background, click_blank_close )

    mb_obj = message_box_module.new()
    mb_obj:open( nil, title, content_list, bottom_list, is_show_close_button, is_show_content_background, click_blank_close )

    return mb_obj
end

function testMessageBox()
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

return message_box_module
