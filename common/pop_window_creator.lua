-- Filename      : ./win32_client/common/pop_window_creator.lua
-- Description   :
-- Last modified : 2016-04-25 16:51

local pop_window_module = require 'common.pop_window_module'
local padding1 = 17 -- 左右间隔
local padding2 = 20 -- 上下间隔
local mb_width = 500

local function contents_creator( create_funcs )
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

local pop_window_creator = class( 'pop_window_creator', pop_window_module )

function pop_window_creator:ctor()
    pop_window_module.ctor( self )
    self.str_title               = nil -- 标题文本，option
    self.show_close_btn          = nil -- 显示关闭按钮
    self.show_content_background = nil -- 显示内容区域的白色底纹
    self.content_list            = {}  -- content create funcs
    self.bottom_list             = {}
    self.unlisten_list           = {}
    self.unlisten_me_list           = {}
end

local scene_module_base = require 'win.scene_module_base'
function pop_window_creator:listen( ... )
    return scene_module_base.listen( self, ... )
end

function pop_window_creator:listen_me( ... )
    return scene_module_base.listen_me( self, ... )
end

function pop_window_creator:cleanListened( ... )
    return scene_module_base.cleanListened( self, ... )
end

function pop_window_creator:createTitle()
    if not self.str_title then return end

    local font_size = 30
    local title_height = font_size + padding2 / 2
    local frame = MCFrame:createWithBox( CCRect( mb_width/-2, title_height/-2, mb_width, title_height ) )
    local frame_title = MCFrame:createWithBox( CCRect( mb_width/-2, font_size/-2, mb_width, font_size ) )
    frame:addChild( frame_title, 1 )
    frame_title:setPositionY( padding2 / 4 )

    local lbl_title = init_label( frame_title, font_size, CCImage.kAlignBottom )
    lbl_title:set_rich_string( self.str_title or '', TL_RICH_STRING_FLAG_ONE_LINE )

    return nil, frame, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height
end

function pop_window_creator:createContent()
    return contents_creator( self.content_list )
end

function pop_window_creator:createBottom()
    return contents_creator( self.bottom_list )
end

function pop_window_creator:setCommonBg( mb_obj )
    -- 上下左右加了padding，把所有内容包了起来
    mb_obj.mb_frame.mcBoundingBox.size.width = mb_obj.mb_frame.mcBoundingBox.size.width + padding1 * 2
    mb_obj.mb_frame.mcBoundingBox.size.height = mb_obj.mb_frame.mcBoundingBox.size.height + padding2 * 2
    mb_obj.mb_frame.mcBoundingBox.origin.x = -mb_obj.mb_frame.mcBoundingBox.size.width/2
    mb_obj.mb_frame.mcBoundingBox.origin.y = -mb_obj.mb_frame.mcBoundingBox.size.height/2
    mb_obj.mb_frame.mcOriginBoundingBox = mb_obj.mb_frame.mcBoundingBox

    addSudokuToFrame( 'msg_box_1', mb_obj.mb_frame, nil, nil, nil, -3 )
    addPopWindowPattern( mb_obj.mb_frame, -2 )

    -- 内容的白色底
    if self.show_content_background then
        local w_sudoku = mb_obj.mb_frame.mcBoundingBox.size.width - padding1 * 2
        local h_sudoku = mb_obj.mb_frame.mcBoundingBox.size.height - mb_obj.title_height - padding2 * 2
        local sudoku = createSudoku( 'msg_box_2', w_sudoku, h_sudoku )
        mb_obj.mb_frame:addChild( sudoku.batch_node, -1 )
        sudoku.batch_node:setPositionY( mb_obj.title_height/-2 )
    end

    -- 关闭按钮
    if self.show_close_btn then
        local frame_close = MCFrame:createWithBox( CCRect( -30, -30, 60, 60 ) )
        mb_obj.mb_frame:addChild( frame_close )
        frame_close:setPosition( mb_obj.mb_frame.mcBoundingBox.size.width/2-15, mb_obj.mb_frame.mcBoundingBox.size.height/2-15 )


        addAnimBtnToNode( 'xjl_2UI_zjm/xjl_parts/parts_32', function() self:close() end, nil, frame_close, mb_obj.win, true )
    end
end

function pop_window_creator:init( mb_obj )
    self:setCommonBg( mb_obj )
end

function pop_window_creator:setTitleString( str_title )
    self.str_title = str_title
end

function pop_window_creator:setCloseButtonIsShow( is_show )
    self.show_close_btn = is_show
end

function pop_window_creator:setContentBackgroundShow( is_show )
    self.show_content_background = is_show
end

function pop_window_creator:setClickBlankClose( bool )
    self.mb_info.click_blank_close = bool
end

function pop_window_creator:appendContent( content_func )
    table.insert( self.content_list, content_func )
end

function pop_window_creator:setContentList( content_list )
    self.content_list = content_list
end

function pop_window_creator:setBottomList( bottom_list )
    self.bottom_list = bottom_list
end

function pop_window_creator:close( ... )
    self:cleanListened()
    pop_window_module.close( self, ... )
end

function pop_window_creator:open( open_call_back )
    pop_window_module.open( self, open_call_back )
end

-- EX
-- local pop_window_creator = require 'common.pop_window_creator'
-- local test = class( 'test', pop_window_creator )

-- function test:ctor()
    -- pop_window_creator.ctor( self )

    -- self:setTitleString( 'title' )
    -- self:setCloseButtonIsShow( true )
    -- self:setContentBackgroundShow( true )

    -- self:appendContent( function()
        -- return self:createPart()
    -- end )
-- end

-- function test:createPart()
    -- local width, height = 200, 200
    -- local frame = MCFrame:createWithBox( CCRect( width/-2, height/-2, width, height ) )
    -- local win = TLWindow:createWindow( frame )

    -- return win, frame, width, height
-- end

-- return test

return pop_window_creator
