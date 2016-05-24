-- ./ui/controls.lua
require 'ui.controls_impl'

-- top window
function init_top_window( node, win_flags, win_name )
    local win = TLWindow:createWindow( node, win_flags or TL_WINDOW_UNIVARSAL )
    win:SetWindowName( win_name or '' )

    TLWindowManager:SharedTLWindowManager():AddModuleWindow( win )

    return win, node
end

function topwindow( mc_name, win_flags, layer_node, z_order, win_name )
    local mc = createMovieClipWithName( mc_name )

    if layer_node ~= nil then layer_node:addChild( mc, z_order or 0 ) end

    return init_top_window( mc, win_flags, win_name )
end

function create_frame_top_window_by_size( layer_node, size, z_order, win_flags, win_name )
    -- 父节点一定要指定
    if not layer_node then return end

    -- 
    size = size or CCDirector:sharedDirector():getWinSize()
    local box = CCRect( -size.width / 2, -size.height / 2, size.width, size.height )
    local frame = MCFrame:createWithBox( box )
    layer_node:addChild( frame, z_order or 0 )

    return init_top_window( frame, win_flags, win_name )
end

-- simple button
function init_simple_button( c_win, onclick, node_extend )
    local obj = __window_control.new( c_win, node_extend )
    obj.onclick = onclick

    -- onclick
    obj:addEventEffect( nil, function() if obj.onclick then obj:onclick() end end )

    -- sound
    obj:addEventEffect( nil, function() play_effect( 'music/bgm_button.mp3' ) end )

    return obj
end

function simple_button( win, name, onclick, node_extend )
    local node = assert( win:GetNode():getChildByName( name ), string.format( 'not found child movieclip %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( node )
	c_win:SetWindowName( name )
    win:AddChildWindow( c_win )

    return init_simple_button( c_win, onclick, node_extend )
end

-- button
function init_button( c_win, onclick )
    local obj = init_simple_button( c_win, onclick )
    obj.mc = toMovieClip( obj.node )

    obj.NORMAL_FRAME = 0
    obj.DOWN_FRAME = 1

    function obj:updateStyle( normal_frame, down_frame )
        self.NORMAL_FRAME = normal_frame
        self.DOWN_FRAME = down_frame
        self.mc:play( self.NORMAL_FRAME, 0 )
    end

    -- 
    obj:addEventEffect( function()
        obj.mc:play( obj.DOWN_FRAME, 0 )
    end,function()
        obj.mc:play( obj.NORMAL_FRAME, 0 )
    end,function()
        obj.mc:play( obj.NORMAL_FRAME, 0 )
    end)

    return obj
end

function button( win, name, onclick )
    local node = assert( win:GetNode():getChildByName( name ), string.format( 'not found child node %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( node )
    win:AddChildWindow( c_win )

    return init_button( c_win, onclick )
end

function init_anim_button( c_win, onclick, anim_sub_node)
    local obj = init_simple_button( c_win, onclick )

    obj:useAnimEffect(anim_sub_node)

    return obj
end

function anim_button( win, name, onclick, anim_sub_node )
    local node = assert( win:GetNode():getChildByName( name ), string.format( 'not found child node %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( node )
    win:AddChildWindow( c_win )

    return init_anim_button( c_win, onclick, anim_sub_node )
end

function initAnimButtonWithBox(mcname, onclick, scale)
    local mc_real = createMovieClipWithName(mcname)
    local mc = MCFrame:createWithBox(mc_real.mcBoundingBox)
    mc:addChild(mc_real)
    mc:setScale(scale or 1)
    local win = TLWindow:createWindow(mc)

    local animbtn = init_anim_button(win, onclick, mc_real)
    return {
        mc_real = mc_real,
        mc = mc,
        win = win,
        btn = animbtn,
    }
end

-- check box
function init_simple_check_box( c_win, checked, onchange )
    local obj = __window_control.new( c_win, node_extend )

    obj.onchange = onchange
    obj.checked = checked

    function obj:setCheckState( checked )
        self.checked = checked
        if self.onchange then self:onchange() end
    end

    -- 
    obj:addEventEffect( nil, function() obj:setCheckState( not obj.checked ) end )

    -- sound
    obj:addEventEffect( nil, function() play_effect( 'music/bgm_button.mp3' ) end )

    return obj
end

-- check box
function init_check_box( c_win, checked, onchange )
    local obj = init_simple_check_box( c_win, checked, onchange )
    obj.mc = toMovieClip( obj.node )

    obj.unchecked_frame = 0
    obj.checked_frame = 1

    local super_setCheckState = obj.setCheckState
    function obj:setCheckState( checked )
        super_setCheckState( self, checked )
        self.mc:play( self.checked and self.checked_frame or self.unchecked_frame, 0 )
    end

    obj:setCheckState( checked or false )

    return obj
end

function check_box( win, name, checked, onchange )
    local mc = assert( win:GetNode():getChildByName( name ), string.format( 'not found child movieclip %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( mc )
    win:AddChildWindow( c_win )

    return init_check_box( c_win, checked, onchange )
end

-- select box
function init_simple_select_box( c_win, checked, onchange )
    local obj = __window_control.new( c_win, node_extend )

    obj.onchange = onchange
    obj.checked = checked

    function obj:setCheckState( checked )
        self.checked = checked
        if self.onchange then self:onchange() end
    end

    -- always set true
    obj:addEventEffect( nil, function() obj:setCheckState( true ) end )

    -- sound
    obj:addEventEffect( nil, function() play_effect( 'music/bgm_button.mp3' ) end )

    return obj
end

function init_select_box( c_win, checked, onchange )
    local obj = init_simple_select_box( c_win, checked, onchange )
    obj.mc = toMovieClip( obj.node )

    obj.unchecked_frame = 0
    obj.checked_frame = 1

    local super_setCheckState = obj.setCheckState
    function obj:setCheckState( checked )
        super_setCheckState( self, checked )
        self.mc:play( self.checked and self.checked_frame or self.unchecked_frame, 0 )
    end

    obj:setCheckState( checked or false )

    return obj
end

function simple_select_box(win, name, checked, onchange)
    local mc = assert( win:GetNode():getChildByName( name ), string.format( 'not found child movieclip %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( mc )
    win:AddChildWindow( c_win )

    return init_simple_select_box( c_win, checked, onchange )
end

function select_box( win, name, checked, onchange )
    local mc = assert( win:GetNode():getChildByName( name ), string.format( 'not found child movieclip %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( mc )
    win:AddChildWindow( c_win )

    return init_select_box( c_win, checked, onchange )
end

function selectbox_group()
    local obj = {
        _current = nil,
        _boxes = {},
        onchange = nil,
    }

    function obj:add( key, box )
        local b_key = ( box ~= nil and key or ( #self._boxes + 1 ) )
        box = box or key
        box.b_key = b_key

        local b_val = {
            box = box,
            super_onchange = box.onchange,
        }

        self._boxes[b_key] = b_val

        -- 重写 onchange 事件
        function box:onchange()
            if self.checked then obj:setcurrent( self.b_key ) end
        end
    end

    function obj:clear()
        -- 恢复为原始的 onchange，这个是否有必要呢，我现在也有点疑问
        for _,b_val in pairs( self._boxes or {} ) do
            b_val.box.onchange = b_val.super_onchange
        end
        self._current = nil
        self._boxes = {}
    end

    function obj:getcurrent() return self._current end

    function obj:setcurrent( b_key , argv)
        local b_val = self._boxes[b_key]
        if self._current ~= b_val then
            -- 把当前选中的，重置为没有选中的状态
            if self._current ~= nil then self._current.box:setCheckState( false ) end

            -- 重新记录下当前选中的，这个逻辑顺序很重要，直接影响到 setCheckState
            -- 因为在 setCheckState( true ) 里面，会调用 setcurrent
            -- 先记录下当前选中的，就可以在 setcurrent 的第一个判断的时候，就没法进来了
            self._current = b_val

            if self._current ~= nil then
                -- 把当前选中的，设置为选中状态
                self._current.box:setCheckState( true )

                -- 调用 select box 原始的 onchange 事件，如果存在的话
                if self._current.super_onchange ~= nil then
                    self._current.super_onchange( self._current.box , argv)
                end

                -- 调用 select group 的 onchange 事件，如果存在的话
                if self.onchange ~= nil then self:onchange( self._current.box ) end
            end
        end
    end

    return obj
end

-- text input
function init_text_input( c_win, is_pwd, onchange )
    local obj = __window_control.new( c_win )
    obj.onchange = onchange

    c_win:RegisterEvent( TL_EVENT_ENCHANGED, function() if obj.onchange then obj:onchange() end end )

    function obj:setinput( text ) self.c_win:setText( text or '' ) end
    function obj:getinput() return self.c_win:getText() end
    function obj:setTextColor( color ) self.c_win:setTextColor( color or ccc3( 255, 255, 255 ) ) end
    function obj:setPlaceHolder( text ) self.c_win:setPlaceHolder( text or '' ) end
    function obj:setPlaceHolderColor( color ) self.c_win:setPlaceHolderColor( color or ccc3( 255, 255, 255 ) ) end
    function obj:setFontSize( font_size ) self.c_win:setFontSize( font_size or 22 ) end
    function obj:setPlaceFontSize( font_size ) self.c_win:setPlaceFontSize( font_size or 22 ) end
    function obj:setRichFlag( rich_flag ) self.c_win:setRichFlag( rich_flag or TL_RICH_STRING_FLAG_AUTO_WRAP ) end
    function obj:setAlignment( alignment ) self.c_win:setAlignment( alignment or CCImage.kAlignLeft ) end
    function obj:setInputMode( input_model ) self.c_win:setInputMode( input_model or TL_INPUT_TEXT_MODEL_CHINAANDENGLISH_ONLY ) end
    function obj:setMaxLength( max_length ) self.c_win:setMaxLength( max_length or 999 ) end
    function obj:setInputFlag( input_flag ) self.c_win:setInputFlag( input_flag or TL_INPUT_FLAG_NORMAL ) end
    function obj:setReturnType( return_type ) self.c_win:setReturnType( return_type or TL_RETURN_TYPE_DEFAULT ) end
    function obj:setKeyboardWillShow( func )
        self.c_win:setKeyboardWillShowHandler( function( begin_x, begin_y, begin_width, begin_height, end_x, end_y, end_width, end_height, duration )
            if func then func( begin_x, begin_y, begin_width, begin_height, end_x, end_y, end_width, end_height, duration ) end
        end)
    end
    function obj:setKeyboardWillHide( func )
        self.c_win:setKeyboardWillHideHandler( function( begin_x, begin_y, begin_width, begin_height, end_x, end_y, end_width, end_height, duration )
            if func then func( begin_x, begin_y, begin_width, begin_height, end_x, end_y, end_width, end_height, duration ) end
        end)
    end
    function obj:getRealSize() return self.c_win:getRealSize() end
    function obj:setIsPwd( is_pwd )
        c_win:setInputFlag( is_pwd and TL_INPUT_FLAG_PASSWORD or TL_INPUT_FLAG_NORMAL )         -- 密码还是明文
    end

    -- 
    obj:setIsPwd( is_pwd )

    return obj
end

function text_input( win, name, is_pwd, onchange, font_size, rich_string_flag )
    local node = assert( win:GetNode():getChildByName( name ), string.format( 'not found child %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( node, TL_WINDOW_INPUT )
    win:AddChildWindow( c_win )

    local obj = init_text_input( c_win, is_pwd, onchange )
    obj:setTextColor( ccc3( 0, 0, 0 ) )
    if font_size then obj:setFontSize( font_size ) end
    if rich_string_flag then obj:setRichFlag( rich_string_flag ) end

    return obj
end

-- label
function init_label( node, font_size, alignment )
    local obj = {}

    if node:getNodeType() == ND_FRAME then
        local n = TLLabelRichTex:create( '', font_size or 24, toFrame( node ).mcBoundingBox.size )
        obj.frame = node
        node:addChild( n )
        node = n
    else
        assert( node:getNodeType() == ND_TTFRICHTEXT or node:getNodeType() == ND_TTFTEXT, 'invalid text node' .. node:getNodeType() )
        node = toTLRichTex( node )      
        if font_size then node:setFontSize( font_size ) end
    end

    obj.node = node

    function obj:set_rich_string( s, flag ) node:setRichString( '[SS:shadow=true,stroke=true]' .. s or '', flag or TL_RICH_STRING_FLAG_ONE_LINE ) end
    function obj:get_rich_string() return node:getRichString() end
    function obj:get_real_size() return node:getRealSize() end
    function obj:set_alignment( alignment ) node:setAlignment( alignment or CCImage.kAlignLeft ) end
    function obj:set_fond_size( fondSize ) return node:setFontSize( fondSize or 24 ) end

    if alignment ~= nil then obj:set_alignment( alignment ) end

    return obj
end

function label( win, name, font_size, alignment )
    local node = assert( win:GetNode():getChildByName( name ), string.format( 'not found child %s from %s', name, win:GetNode():getInstanceName() ) )
    return init_label( node, font_size, alignment )
end

-- prop label
function prop_label( win, name, key, convert, font_size, alignment )
    convert = convert or tostring

    local lbl = label( win, name, font_size, alignment )
    lbl:set_rich_string( convert( g_player[key] ) )

    local fn
    fn = function( val )
        if toTLWindow( win ) == nil then
            unlisten_me( key, fn )
        else
            lbl:set_rich_string( convert( val ) )
        end
    end

    listen_me( key, fn )
    return function() unlisten_me( key, fn ) end, lbl
end

function mul_prop_label( win, name, key_list, convert, font_size, alignment )
    local lbl = label( win, name, font_size, alignment )

    local function get_key_value()
        local ret_value = {}
        for _,key_name in ipairs( key_list or {} ) do
            ret_value[key_name] = g_player[key_name] or 0
        end
        return ret_value
    end

    convert = convert or tostring
    lbl:set_rich_string( convert( get_key_value() ) )

    local fn = nil

    local function unlisten_func()
        for _,key_name in ipairs( key_list or {} ) do
            unlisten_me( key_name, fn )
        end
    end

    fn = function( val )
        if toTLWindow( win ) == nil then
            unlisten_func()
        else
            lbl:set_rich_string( convert( get_key_value() ) )
        end
    end

    for _,key_name in ipairs( key_list or {} ) do
        listen_me( key_name, fn )
    end

    return unlisten_func, lbl
end

-- progress bar
function init_progress_bar( node, min, max )
    -- 保证 max - min > 0
    if max <= min then max = min + 0.01 end

    local origin_box = getBoundingBox( node )
    local pb = {
        min = min,
        max = max,
        all_sub_bars = {},
    }

    function pb:addSubBar( tex, init_value, is_flip )
        local sub_bar = { node_extend = false }

        -- 创建一个新的 MCFrame，并作为 node 的子节点
        local clip_region = copy_rect( origin_box )
        local child_frame = MCFrame:createWithBox( clip_region )
        node:addChild( child_frame )

        -- 添加进度条的颜色贴图
        local sprite = MCLoader:sharedMCLoader():loadSprite( tex )
        sub_bar.sprite = sprite
        child_frame:addChild( sprite )

        -- 缩放以适应 child_frame
        local size = sprite:getContentSize()
        sprite:setScaleX( child_frame.mcBoundingBox.size.width / size.width )
        sprite:setScaleY( child_frame.mcBoundingBox.size.height / size.height )

        -- 
        function sub_bar:setPercent( percent )
            if is_flip then
                local _w = child_frame.mcBoundingBox.size.width * percent
                local _h = child_frame.mcBoundingBox.size.height
                local _x = child_frame.mcBoundingBox.origin.x + ( child_frame.mcBoundingBox.size.width - _w )
                local _y = child_frame.mcBoundingBox.origin.y
                clip_region = CCRect(_x, _y, _w, _h)
            else
                local _w = child_frame.mcBoundingBox.size.width * percent
                local _h = child_frame.mcBoundingBox.size.height
                local _x = child_frame.mcBoundingBox.origin.x
                local _y = child_frame.mcBoundingBox.origin.y
                clip_region = CCRect(_x, _y, _w, _h)
            end
            child_frame:setClipRegion( clip_region )
        end

        function sub_bar:setValue( value )
            value = math.max( min, math.min( max, value ) )
            local percent = ( value - min ) / ( max - min )
            self:setPercent( percent )
        end

        -- 扩展的 CCNode 
        function sub_bar:_nodeExtend()
            if not self.node_extend then
                self.node_extend = true
                CCNodeExtend.extend( child_frame )
            end
        end

        -- 通过改变 alpha 来实现 blink
        function sub_bar:alphaBlink( enable, blink_time, alpha_min, alpha_max )
            self:_nodeExtend()

            if self.blink_handle1 then
                child_frame:removeTween( self.blink_handle1 )
                self.blink_handle1 = nil
            end
            if self.blink_handle2 then
                child_frame:removeTween( self.blink_handle2 )
                self.blink_handle2 = nil
            end

            if enable then
                blink_time = blink_time or 0.5
                alpha_min = alpha_min or 0
                alpha_max = alpha_max or 255

                local delay_1 = 0
                local duration_1 = blink_time
                local interval_1 = blink_time
                self.blink_handle1 = child_frame:tweenFromTo( LINEAR_IN, NODE_PRO_ALPHA, delay_1, duration_1, interval_1, alpha_min, alpha_max, -1 )

                local delay_2 = blink_time
                local duration_2 = blink_time
                local interval_2 = blink_time
                self.blink_handle2 = child_frame:tweenFromTo( LINEAR_IN, NODE_PRO_ALPHA, delay_2, duration_2, interval_2, alpha_max, alpha_min, -1 )
            end
        end

        
        -- 循环滚动
        -- @param: oldpercent    初始百分比
        -- @param: newpercent    最终百分比
        -- @param: loop          移动次数 最小为1
        -- @param: oncecallfunc  每次100%后的回调
        -- @param: finalcallfunc 结束后的回调
        function sub_bar:moveLoop(oldpercent, newpercent, loop, fullcallfunc, finalcallfunc)
            local target = CCNodeExtend.extend( sprite )
            target:removeAllTween()

            --if self.moveLoopHandles then
            --    for i, handle in ipairs(self.moveLoopHandles) do
            --        target:removeTween(handle)
            --    end
            --end
            local _oldpercent = oldpercent or 0
            local _newpercent = newpercent or 0
            local _loop       = loop or 0
            
            if _oldpercent < 0 then _oldpercent = 0 end
            if _newpercent > 1 then _newpercent = 1 end
            --if newpercent <= oldpercent then _newpercent = _oldpercent + 0.01 end

            --define actions
            local _W = child_frame.mcBoundingBox.size.width
            local _oldPos = (_oldpercent - 1) * _W
            local _newPos = (_newpercent - 1) * _W
            local _delay = 0
            local v = 1   -- 100%/1s
            local _duration = 0
            local actions = {}
            if _loop == 1 then
                local pos1 = _oldPos
                local pos2 = _newPos
                _duration = (1 - _oldpercent)
                actions[1] = {
                    START_POS = pos1,
                    FINAL_POS = pos2,
                    DELAY     = _delay,
                    DURATION  = 1,
                    callfunc  = finalcallfunc,
                }
            elseif _loop > 1 then
                for i = 1, _loop do
                    --第一次
                    if i == 1 then
                        local pos1 = _oldPos
                        local pos2 = 0
                        _duration = (1 - _oldpercent)
                        actions[i] = {
                            START_POS = pos1,
                            FINAL_POS = pos2,
                            DELAY     = _delay,
                            DURATION  = _duration,
                            callfunc  = fullcallfunc,
                        }
                    --最后一次
                    elseif i == _loop then
                        local pos1 = -_W
                        local pos2 = _newPos
                        _duration = _newpercent
                        actions[i] = {
                            START_POS = pos1,
                            FINAL_POS = pos2,
                            DELAY     = _delay,
                            DURATION  = _duration,
                            callfunc  = finalcallfunc,
                        }
                    --其他
                    else
                        local pos1 = -_W
                        local pos2 = 0 
                        _duration = 1
                        actions[i] = {
                            START_POS = pos1,
                            FINAL_POS = pos2,
                            DELAY     = _delay,
                            DURATION  = _duration,
                            callfunc  = fullcallfunc,
                        }
                    end
                    _delay = _delay + _duration
                end
            end

            child_frame:setClipRegion(child_frame.mcBoundingBox)
            target:setPositionX(_oldPos)
            for i, action in ipairs(actions) do
                target:tweenFromTo(LINEAR_IN, NODE_PRO_X, action.DELAY, action.DURATION, 0, action.START_POS, action.FINAL_POS, 0, function()
                    if action.callfunc then action.callfunc() end
                end)
            end

            --用于外部停止动画
            return target
        end


        sub_bar:setValue( init_value or 0 )

        -- 
        table.insert( self.all_sub_bars, sub_bar )

        -- 返回的是索引
        return #self.all_sub_bars
    end

    function pb:setPercent( percent, sub_index )
        sub_index = sub_index or 1

        local sub_bar = self.all_sub_bars[sub_index]
        if sub_bar then sub_bar:setPercent( percent ) end
    end

    function pb:setValue( value, sub_index )
        value = math.max( min, math.min( max, value ) )
        local percent = ( value - min ) / ( max - min )

        self:setPercent( percent, sub_index )
    end

    function pb:alphaBlink( enable, sub_index, blink_time, alpha_min, alpha_max )
        sub_index = sub_index or 1

        local sub_bar = self.all_sub_bars[sub_index]
        if sub_bar then sub_bar:alphaBlink( enable, blink_time, alpha_min, alpha_max ) end
    end

    function pb:moveOnce(sub_index, oldpercent, newpercent, finalcallfunc)
        sub_index = sub_index or 1
        local sub_bar = self.all_sub_bars[sub_index]
        if sub_bar then sub_bar:moveLoop(oldpercent, newpercent, 1, nil, finalcallfunc) end
    end

    function pb:moveLoop(sub_index, oldpercent, newpercent, loop, oncecallfunc, finalcallfunc)
        sub_index = sub_index or 1
        local sub_bar = self.all_sub_bars[sub_index]
        if sub_bar then return sub_bar:moveLoop(oldpercent, newpercent, loop, oncecallfunc, finalcallfunc) end
    end

    return pb
end

function progress_bar( win, name, tex, min, max )
    local node = assert( win:GetNode():getChildByName( name ), string.format( 'not found child %s from %s', name, win:GetNode():getInstanceName() ) )

    local pro_bar = init_progress_bar( node, min, max )
    pro_bar:addSubBar( tex )

    return pro_bar
end

-- tab button
function init_tab_button( c_win, onclick )
    local obj = init_simple_button( c_win, onclick )

    obj:useAnimEffect()

    return obj
end

function init_seek_bar( win, onchange )
    local mc = win:GetNode()
    local point = mc:getChildByName('point')
    local bar = mc:getChildByName('bar')
	local progReg = mc:getChildByName('tufie')
	local progHead = MCLoader:sharedMCLoader():loadSprite('ui_001043_6.png')
	local progNode = MCLoader:sharedMCLoader():loadSprite('ui_001043_7.png')
	progReg:addChild(progHead)	
	progReg:addChild(progNode)	

	local pointSize = point:getContentSize()
	local progHeadSize = progHead:getContentSize()
	local progSize = progNode:getContentSize()

    local btn = {
        movieclip = mc,
        window = win,
        onchange = onchange,
    }
    local winManager = TLWindowManager:SharedTLWindowManager()
    local bar_width = bar:getContentSize().width
	--转换成世界坐标
	local worldPoint = bar:convertToWorldSpace(CCPoint(bar:getPositionX(),bar:getPositionY()))
    local position_min = bar:getPositionX()-bar_width/2+progHeadSize.width
    local position_max = bar:getPositionX()+bar_width/2
	local positionWidth = position_max - position_min
    local position = position_min
	local lastPoint
	local maxNum = 10
	local currentNum = 0
	local step = bar_width/maxNum

	--设置位置
    local function set_position(p)
        if p < position_min then
            p = position_min
        elseif p > position_max then	
            p = position_max
        end
        if p~=position then
            position = p
            point:setPositionX(position-(pointSize.width*0.5-20))
			progNode:setScaleX((position-position_min)/progSize.width)
			if btn.onchange  then
				btn:onchange(currentNum)
                --btn:onchange((position-position_min)/bar_width)
            end
        end
    end

	--校正下标
	local function checkIndex(p)
        if p < position_min then
            p = position_min
        elseif p > position_max then	
            p = position_max
        end
		--校正
		currentNum = math.floor(((p-position_min)/positionWidth)*maxNum)
	end

	--按钮响应
	local function onButton(unit)
		if unit > 0 and currentNum >= maxNum then
			return
		end
		if unit < 0 and currentNum <= 0 then
			return
		end
		--位置变化
		currentNum = currentNum+unit   
		p = position_min + (currentNum/maxNum*positionWidth)
		set_position(p)
	end

	--按钮点击
	local lBtn = button(win, 'zuo', function() onButton(-1) end)
	local rBtn = button(win, 'you', function() onButton(1) end)

    -- 初始化位置0
	progNode:setAnchorPoint( CCPoint( 0, progNode:getAnchorPoint().y ))
	progHead:setPositionX(position_min)
	progNode:setPositionX(position_min+progHeadSize.width*0.5)
    set_position(position_min)

    win:RegisterEvent(TL_EVENT_BUTTON_DOWN, function(...)
		local curPoint = winManager:getLastPointX()
		if curPoint ~= lastPoint then 	
			local p = curPoint - worldPoint.x
			checkIndex(p)		
			set_position(p) 
			lastPoint = curPoint
		end
    end)	
    win:RegisterEvent(TL_EVENT_MOUSE_MOVE, function(...)
        if lastPoint==nil then
            return
        end
        local p = winManager:getLastPointX()
		local site = position + (p - lastPoint)
		checkIndex(site)			
        set_position(site)
        lastPoint = p
    end)

    -- 设置 0 到 1 的浮点数
    function btn:set_percent(f)
        set_position(position_min + f*bar_width)
    end

    -- 获取 0 到 1 的浮点数
    function btn:get_percent()
        return (point:getPositionX()-position_min)/bar_width
    end

	function btn:set_step(stepnum) --设置步长 
		step = bar_width/stepnum
		maxNum = stepnum
		currentNum = 0
	end

	function btn:get_step() --获得步长
		return step
	end
	--获取最大值
	function btn:getMaxNum()
		return maxNum
	end
    return btn
end

function seek_bar( win, name, onchange )
    local node = assert( win:GetNode():getChildByName( name ), string.format( 'not found child movieclip %s from %s', name, win:GetNode():getInstanceName() ) )
    local c_win = TLWindow:createWindow( node )
    win:AddChildWindow( c_win )

    return init_seek_bar( c_win, onchange )
end

function progressBar_FromWin(win, name, tex, min, max)
    return progressBar_FromParentNode( win:GetNode(), name, tex, min, max )
end

function progressBar_FromParentNode( parentNode, name, tex, min, max )
    local node = assert( parentNode:getChildByName(name), string.format( 'not found child %s from %s', name, parentNode:getInstanceName() ) )
    if node:getNodeType() == ND_FRAME then
        return progressBar_FromMCFrame( toFrame( node ), tex, min, max )
    else
        return nil
    end
end

function progressBar_FromMCFrame( frame, tex, min, max )
    frame:setClipRegion( frame.mcBoundingBox )
    frame:setAnchorPoint( CCPoint( 0, 0 ) )

    local sprite = MCLoader:sharedMCLoader():loadSprite( tex )
    frame:addChild( sprite )

    local size = sprite:getContentSize()
    local scaleX = frame.mcBoundingBox.size.width / size.width
    local scaleY = frame.mcBoundingBox.size.height / size.height
    sprite:setScaleX( scaleX )
    sprite:setScaleY( scaleY )

    local clip_x = frame.mcBoundingBox.origin.x
    local clip_y = frame.mcBoundingBox.origin.y
    local clip_width = frame.mcBoundingBox.size.width
    local clip_height = frame.mcBoundingBox.size.height
    return {
        frame = frame,
        setValue = function( value )
            local temp = ( value - min ) / ( max - min )
            local width = frame.mcBoundingBox.size.width * temp

            if width <= 0.0 then
                width = 0.0
            end

            if width > frame.mcBoundingBox.size.width then
                width = frame.mcBoundingBox.size.width
            end

            clip_width = width
            frame:setClipRegion( CCRect( clip_x, clip_y, clip_width, clip_height ) )

            return clip_width
        end,
        setPercent = function(p)
            -- 0 <= p <= 1
            clip_width = frame.mcBoundingBox.size.width * p
            frame:setClipRegion( CCRect( clip_x, clip_y, clip_width, clip_height ) )

            return clip_width
        end,
    }
end

function create_extended_button( win, name, btn_mc_name, text_file, onclick )
    local frame = toFrame( win:GetNode():getChildByName( name ) )

    local btn_node = CCNode:create()
    frame:addChild( btn_node )

    local btn_mc = createMovieClipWithName( btn_mc_name )
    btn_node:addChild( btn_mc )

    if text_file then btn_mc:getChildByName( 'wenben' ):addChild( MCLoader:sharedMCLoader():loadSpriteAsync( text_file ) ) end

    btn_node:setScale( frame.mcBoundingBox.size.width / btn_mc.mcBoundingBox.size.width )

    return anim_button( win, name, onclick, btn_mc ), btn_mc
end

-- b_tex : 背景贴图， b_tex_1, b_tex_2
-- c_tex : 颜色贴图
-- f_tex : 前景贴图， f_tex_1, f_tex_2
function createBatchProgress( batch_node, x, y, width, b_tex_1, b_tex_2, c_tex, f_tex_1, f_tex_2, valid_width_amend )
    local ret_progress_obj = {}

    -- 背景底
    local left_sprite_b = MCLoader:sharedMCLoader():loadSprite( b_tex_1 )
    local left_size_b = left_sprite_b:getContentSize()
    left_sprite_b:setPosition( x + ( left_size_b.width - width ) * 0.5, y )
    batch_node:addChild( left_sprite_b )

    local right_sprite_b = MCLoader:sharedMCLoader():loadSprite( b_tex_1 )
    right_sprite_b:setFlipX( true )
    right_sprite_b:setPosition( x + ( width - left_size_b.width ) * 0.5, y )
    batch_node:addChild( right_sprite_b )

    local center_sprite_b = MCLoader:sharedMCLoader():loadSprite( b_tex_2 )
    center_sprite_b:setScaleX( ( width - left_size_b.width * 2 ) / center_sprite_b:getContentSize().width )
    center_sprite_b:setPosition( x, y )
    batch_node:addChild( center_sprite_b )

    -- 进度条颜色
    local c_sprite = MCLoader:sharedMCLoader():loadSprite( c_tex )
    local c_size = c_sprite:getContentSize()
    c_sprite:setPosition( x, y )
    batch_node:addChild( c_sprite )

    -- 前景
    local left_sprite_f, right_sprite_f, center_sprite_f = nil, nil, nil
    if f_tex_1 then
        left_sprite_f = MCLoader:sharedMCLoader():loadSprite( f_tex_1 )
        local left_size_f = left_sprite_f:getContentSize()
        left_sprite_f:setPosition( x + ( left_size_f.width - width ) * 0.5, y )
        batch_node:addChild( left_sprite_f )

        right_sprite_f = MCLoader:sharedMCLoader():loadSprite( f_tex_1 )
        right_sprite_f:setFlipX( true )
        right_sprite_f:setPosition( x + ( width - left_size_f.width ) * 0.5, y )
        batch_node:addChild( right_sprite_f )
    end

    if f_tex_2 then
        center_sprite_f = MCLoader:sharedMCLoader():loadSprite( f_tex_2 )
        center_sprite_f:setScaleX( ( width - left_size_f.width * 2 ) / center_sprite_f:getContentSize().width )
        center_sprite_f:setPosition( x, y )
        batch_node:addChild( center_sprite_f )
    end

    -- 
    local c_width = width - valid_width_amend or 9
    function ret_progress_obj:setPercent( percent )
        if percent > 1 then percent = 1 end
        if percent < 0 then percent = 0 end

        local temp_width = c_width * percent
        local c_scale_x = temp_width / c_size.width
        c_sprite:setScaleX( c_scale_x )

        local c_x = x - c_width * 0.5 + temp_width * 0.5 + 0.2
        c_sprite:setPosition( c_x, y )
    end

    function ret_progress_obj:remove()
        left_sprite_b:removeFromParentAndCleanup( true )
        right_sprite_b:removeFromParentAndCleanup( true )
        center_sprite_b:removeFromParentAndCleanup( true )
        c_sprite:removeFromParentAndCleanup( true )
        if left_sprite_f then left_sprite_f:removeFromParentAndCleanup( true ) end
        if right_sprite_f then right_sprite_f:removeFromParentAndCleanup( true ) end
        if center_sprite_f then center_sprite_f:removeFromParentAndCleanup( true ) end
    end

    return ret_progress_obj
end
