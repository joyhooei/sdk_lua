-- Filename      : ./common/layout_helper.lua
-- Description   :
-- Last modified : 2016-04-12 16:44

--- 一些做UI的时候要用到的通用的办法
-- @author colin

--- fillSprite2Frame
-- 自动填充
-- @param sprite 要缩放的精灵
-- @param p_frame 要填充的父节点
-- @param[opt=width] fill_direction 填充的方向，width/height
-- @usage fillSprite2Frame( sprite, frame, 'height' )
function fillSprite2Frame( sprite, p_frame, fill_direction )
    if not toCCNode( p_frame ) then return end

    if fill_direction == 'height' then
        sprite:setScale( p_frame.mcBoundingBox.size.height / sprite:getContentSize().height )
    else
        sprite:setScale( p_frame.mcBoundingBox.size.width / sprite:getContentSize().width )
    end
end

--- fillMC2Frame
-- 自动填充
-- @param mc 要缩放的 MovieClip
-- @param p_frame 要填充的父节点
-- @param[opt=width] fill_direction 填充的方向，width/height
-- @usage fillMC2Frame( mc, frame, 'height' )
function fillMC2Frame( mc, p_frame, fill_direction )
    if not toCCNode( p_frame ) then return end

    if fill_direction == 'height' then
        mc:setScale( p_frame.mcBoundingBox.size.height / mc.mcBoundingBox.size.height )
    else
        mc:setScale( p_frame.mcBoundingBox.size.width / mc.mcBoundingBox.size.width )
    end
end

--- createCountDownLabel
-- 创建倒计时文本，自销毁schedule_circle
-- @param frame 要创建倒计时文本的frame
-- @param[opt] font_size 字号
-- @param alignment 对齐方式
-- @param get_cd_func 取cd的方法，function() return cd end
-- @param count_func 每秒重设文本的方法，function() return str end
-- @param end_func 计时为0的时候做的事情
-- @return lbl_cd 倒计时文本
-- @return schedule_handle 倒计时句柄
-- @usage createCountDownLabel( frame, 24, CCImage.kAlignLeft, function() return cd end, funciton() return str end, function() dosomething() end )
function createCountDownLabel( frame, font_size, alignment, get_cd_func, count_func, end_func )
    local lbl_cd = init_label( frame, font_size, alignment )

    local schedule_handle
    schedule_handle = schedule_circle( 1, function()
        if not toCCNode( lbl_cd.node ) then return unCommonSchedule( schedule_handle ) end

        lbl_cd:set_rich_string( count_func() )

        if end_func and get_cd_func() == 0 then
            end_func()
        end
    end , nil, true )

    return lbl_cd, schedule_handle
end

local function initAnimButtonWithBox( mcname, onclick, scale )
    local mc_real = createMovieClipWithName( mcname )
    local frame = MCFrame:createWithBox( mc_real.mcBoundingBox )
    frame:addChild( mc_real )
    frame:setScale( scale or 1 )
    local win = TLWindow:createWindow( frame )

    local animbtn = init_anim_button( win, onclick, mc_real )
    return {
        mc = mc_real,
        frame = frame,
        win = win,
        btn = animbtn,
    }
end

local function initAnimButtonWithPic( picname, onclick, scale )
    local sprite     = MCLoader:sharedMCLoader():loadSprite( picname )
    local frame_real = MCFrame:createWithBox( getBoundingBox( sprite ) )
    local frame_lbl  = MCFrame:createWithBox( getBoundingBox( sprite ) )
    frame_lbl:setInstanceName( 'wenben' )
    local frame      = MCFrame:createWithBox( getBoundingBox( sprite ) )

    frame_real:addChild( sprite )
    frame_real:addChild( frame_lbl )
    frame:addChild( frame_real )
    frame:setScale( scale or 1 )
    local win = TLWindow:createWindow( frame )

    local animbtn = init_anim_button( win, onclick, frame_real )
    return {
        mc = frame_real,
        frame = frame,
        win = win,
        btn = animbtn,
    }
end

--- addAnimBtnToNode
-- 创建一个按钮，并添加到指定节点
-- @param mc_path 按钮元件/按钮图片的路径
-- @param onclick 按钮的响应事件
-- @param[opt] btn_label 按钮上要显示的文字
-- @param[opt] p_node 指定的父节点
-- @param[opt] p_win 指定的父响应区域
-- @param[opt] autoadjust 是否根据p_node宽度自动适配，width/height
-- @return btn_obj
-- @usage addAnimBtnToNode( 'xxx', function() end, nil, nil, nil, nil )
function addAnimBtnToNode( mc_path, onclick, btn_label, p_node, p_win, autoadjust )
    local file_extension_name = get_extension( mc_path )
    local obj_btn
    if file_extension_name == 'png' or file_extension_name == 'jpg' then
        obj_btn = initAnimButtonWithPic( mc_path, onclick )
    else
        obj_btn = initAnimButtonWithBox( mc_path, onclick )
    end

    local node_lbl = obj_btn.mc:getChildByName( 'wenben' )
    if not toCCNode( node_lbl ) then
        node_lbl = MCFrame:createWithBox( CCRect( -50, -20, 100, 40 ) )
        obj_btn.mc:addChild( node_lbl )
        node_lbl:setInstanceName( 'wenben' )
    end
    obj_btn.lbl_btn = init_label( obj_btn.mc:getChildByName( 'wenben' ), nil, CCImage.kAlignCenter )

    if autoadjust then
        fillMC2Frame( obj_btn.frame, toFrame( p_node ), autoadjust )
    end

    if toCCNode( p_node ) then p_node:addChild( obj_btn.frame ) end
    if toTLWindow( p_win ) then p_win:AddChildWindow( obj_btn.win ) end

    function obj_btn.setBtnLbl( obj_btn, btn_label )
        --self.mc:getChildByName( 'wenben' ):removeAllChildrenWithCleanup( true )
        --init_label( self.mc:getChildByName( 'wenben' ), nil, CCImage.kAlignCenter):set_rich_string( btn_label )
        obj_btn.lbl_btn:set_rich_string( btn_label )
    end

    function obj_btn:setVisible( is_visible )
        self.frame:setVisible( is_visible )
        self.win:SetIsVisible( is_visible )
    end

    function obj_btn:enable( is_enable )
        self.btn:enable( is_enable )
    end

    local node_to_play = obj_btn.mc
    if toMovieClip( obj_btn.mc:getChildByName( 'ditu' ) ) then
        node_to_play = toMovieClip( obj_btn.mc:getChildByName( 'ditu' ) )
    end
    function obj_btn:play( ... )
        node_to_play:play( ... )
    end

    function obj_btn:showBtnShadow( b )
        toMovieClip( obj_btn.mc:getChildByName( 'yinying' ) ):play( b and 1 or 0, 0 )
    end

    --[[
    function obj_btn:createARedPoint( listen_properties, updatefunc )
        if not obj_btn.red_p then
            obj_btn.red_p = createARedPoint( listen_properties, updatefunc )
            obj_btn.red_p.frame:setScale( 1 / ( obj_btn.scale_btn or 1 ) )

            local pnode = obj_btn.mc:getChildByName( 'N' )
            if not pnode then
                pnode = MCFrame:createWithBox( CCRect( -2, -2, 4, 4) )
                pnode:setInstanceName( 'N' )
                obj_btn.mc:addChild( pnode )
                local _w = obj_btn.mc.mcBoundingBox.size.width
                local _h = obj_btn.mc.mcBoundingBox.size.height
                pnode:setPosition( _w/2 - 20, _h/2 - 20 )
            end
            pnode:addChild( obj_btn.red_p.frame )
        end
    end
    --]]

    if btn_label then obj_btn:setBtnLbl( btn_label ) end

    return obj_btn
end

--- addAnimBtnToNodeEx
-- 创建一个按钮，并添加到指定节点
-- @param mc_path 按钮元件/按钮图片的路径
-- @param onclick 按钮的响应事件
-- @param btn_label 按钮上要显示的图片
-- @param[opt] p_node 指定的父节点
-- @param[opt] p_win 指定的父响应区域
-- @param[opt] autoadjust 是否根据p_node宽度自动适配，width/height
-- @return btn_obj
-- @usage addAnimBtnToNodeEx( 'xxx', function() end, 'xxx.png', nil, nil, nil )
function addAnimBtnToNodeEx( mc_path, onclick, btn_label, p_node, p_win, autoadjust )
    return addAnimBtnToNode( mc_path, onclick, string.format( '[sprite:fileName="%s"]', btn_label ), p_node, p_win, autoadjust )
end

--- formatTimeStr
-- 格式化cd时间为[%d天] [%02d:]%02d:%02d的格式
-- @param cd cd时间
-- @return 倒计时字符串
-- @usage formatTimeStr( 100 )
function formatTimeStr( cd )
    local d, h, m, s = getDayHourMinSecondByTime( cd )
    if d > 0 then return string.format( _YYTEXT( '%d天' ), d ) end
    local h_str = h > 0 and string.format( '%02d:', h ) or ''
    return h_str .. string.format( '%02d:%02d', m, s )
end

function addPopWindowPattern( frame, z_order )
    local sprite_bl = MCLoader:sharedMCLoader():loadSprite( 'ui_0003_9.png' )
    local sprite_br = MCLoader:sharedMCLoader():loadSprite( 'ui_0003_9.png' )
    local sprite_tl = MCLoader:sharedMCLoader():loadSprite( 'ui_0003_9.png' )
    local sprite_tr = MCLoader:sharedMCLoader():loadSprite( 'ui_0003_9.png' )

    sprite_br:setScaleX( -1 )
    sprite_tl:setScaleY( -1 )
    sprite_tr:setScale( -1 )

    local w_s = sprite_bl:getContentSize().width
    local h_s = sprite_bl:getContentSize().height
    local w_f = frame.mcBoundingBox.size.width
    local h_f = frame.mcBoundingBox.size.height

    frame:addChild( sprite_bl, z_order or -1 )
    frame:addChild( sprite_br, z_order or -1 )
    frame:addChild( sprite_tl, z_order or -1 )
    frame:addChild( sprite_tr, z_order or -1 )
    sprite_bl:setPosition(  (w_s-w_f)/2 + 7, (h_s-h_f)/2  + 5 )
    sprite_br:setPosition( -(w_s-w_f)/2 - 7, (h_s-h_f)/2  + 5 )
    sprite_tl:setPosition(  (w_s-w_f)/2 + 7, -(h_s-h_f)/2 - 5 )
    sprite_tr:setPosition( -(w_s-w_f)/2 - 7, -(h_s-h_f)/2 - 5 )
end

function addColorBgToFrame( frame, color, z_order )
    color = color or ccc4( 0, 0, 0, 180 )
    local width, height = frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height
    local color_layer = CCLayerColor:create( ccc4( color.r, color.g, color.b, color.a ), width, height )
    color_layer:setPosition( width/-2, height/-2 )
    frame:addChild( color_layer, z_order or -10 )

    return color_layer
end


function createProgressBar( sudoku_type, width, height, color1, color2 )
    color1 = color1 or ccc4( 89, 74, 251, 255 )
    local progress_obj = {}

    local width, height = width or 638, height or 30
    require 'utils.sudoku'
    local sudoku_shadow = createSudoku( sudoku_type, width, height )
    local sudoku_pregress = createSudoku( sudoku_type, width, height )

    progress_obj.frame = MCFrame:createWithBox( CCRect( width / -2, height / -2, width, height ) )

    local node_progress = CCNode:create()
    local node_shadow = CCNode:create()
    progress_obj.frame:addChild( node_progress, 1 )
    progress_obj.frame:addChild( node_shadow, -1 )
    node_shadow:setPosition( -3, -2 )

    -- shadow
    local render_shadow = TLRenderNode:create( sudoku_shadow.batch_node, width, height )
    render_shadow:setUseRender( true )
    render_shadow:addChild( sudoku_shadow.batch_node )
    node_shadow:addChild( render_shadow )
    render_shadow:setShaderProgramName('position_texture_color_progress')
    render_shadow:setCustomUniforms( 0 / 255, 0 / 255, 0 / 255, 100 / 255 )
    render_shadow:setCustomUniformsEx( 1, 0, 0, 0 )

    -- progress
    local render_progress = TLRenderNode:create( sudoku_pregress.batch_node, width, height )
    render_progress:setUseRender( true )
    render_progress:addChild( sudoku_pregress.batch_node )
    node_progress:addChild( render_progress, 1 )
    render_progress:setShaderProgramName('position_texture_color_progress')
    -- render_progress:setCustomUniforms( 109 / 255, 107 / 255, 245 / 255, 255 / 255 )
    render_progress:setCustomUniforms( color1.r / 255, color1.g / 255, color1.b / 255, color1.a / 255 )

    function progress_obj:setPercent( per )
        per = math.max( 0, math.min( per, 1 ) )
        render_progress:setCustomUniformsEx( per, 0, 0, 0 )
    end

    function progress_obj:setProgressLabel( str )
       if not self.lbl_progress then
           local lbl_frame = MCFrame:createWithBox( CCRect( height / -2, -100, height, 200) )
           lbl_frame:setInstanceName( 'progress_label' )
           self.frame:addChild( lbl_frame, 2 )

           self.lbl_progress = init_label( lbl_frame, nil, CCImage.kAlignCenter )
       end

       self.lbl_progress:set_rich_string( str )
    end

    return progress_obj
end

function createFrame( w, h, name, p_farme, x, y )
    local frame = MCFrame:createWithBox( CCRect( w/-2, h/-2, w, h) )

    if name then frame:setInstanceName( name ) end
    if x then frame:setPositionX( x ) end
    if y then frame:setPositionY( y ) end
    if p_farme then p_farme:addChild( frame ) end

    return frame
end

function getCostString( cost_type, cost_value, cost_id )
    require 'win.item.common'
    local icon = ITEM_TYPE_INFO[ cost_type ]:getIconPic( cost_id )
    return string.format( '[sprite:fileName="%s", sacle=0.3] %d ', icon, cost_value )
end
