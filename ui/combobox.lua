-- ./ui/combobox.lua
require 'utils.CCNodeExtend'

local function updateBoundingBox( box1, box2 )
    box1.size.width = box2.size.width
    box1.size.height = box2.size.height
    box1.origin.x = box2.origin.x
    box1.origin.y = box2.origin.y
end

function combobox( win, name, mcName, mcItemName, bg, sel_change )
    local obj = { sel_change = sel_change }

    local frame = assert( toFrame( win:GetNode():getChildByName( name ) ),
                         string.format( 'not found child frame %s from %s', name, win:GetNode():getInstanceName() ) )

    local origin_box = copy_rect( frame.mcBoundingBox )
    frame:setClipRegion( origin_box )

    local need_expand = false
    local src_y = 0
    local target_y = 0

    -- 
    local mcMain = createMovieClipWithName( mcName )
    mcMain:setAutoClear( false )
    frame:addChild( mcMain )
    local cb_win = TLWindow:createWindow( mcMain )
    win:AddChildWindow( cb_win )

    local main_label = label( cb_win, 'zi', nil, CCImage.kAlignCenter )

    -- 
    local drop_down_list_box = copy_rect( origin_box )
    local bg_frame = CCNodeExtend.extend( MCFrame:createWithBox( drop_down_list_box ) )
    frame:addChild( bg_frame, -1 )

    local function expand( is_expand )
        frame:setClipRegion( is_expand and drop_down_list_box or origin_box )
        updateBoundingBox( mcMain.mcBoundingBox, is_expand and drop_down_list_box or origin_box )

        CCLuaLog( 'src_y = ' .. tostring( src_y ) )
        CCLuaLog( 'target_y = ' .. tostring( target_y ) )
        bg_frame:tweenFromToOnce( LINEAR_IN, NODE_PRO_Y, 0, 0.15, src_y, target_y )

        local temp_y = src_y
        src_y = target_y
        target_y = temp_y
    end

    -- 
    init_button( cb_win, function()
        need_expand = not need_expand
        expand( need_expand )
    end)

    -- background
    local left = MCLoader:sharedMCLoader():loadSpriteAsync( bg.mc_left )
    bg_frame:addChild( left )
    local right = MCLoader:sharedMCLoader():loadSpriteAsync( bg.mc_left )
    right:setScaleX( -1 )
    bg_frame:addChild( right )
    local bottom = MCLoader:sharedMCLoader():loadSpriteAsync( bg.mc_bottom )
    bg_frame:addChild( bottom )
    local left_bottom = MCLoader:sharedMCLoader():loadSpriteAsync( bg.mc_left_bottom )
    bg_frame:addChild( left_bottom )
    local right_bottom = MCLoader:sharedMCLoader():loadSpriteAsync( bg.mc_left_bottom )
    right_bottom:setScaleX( -1 )
    bg_frame:addChild( right_bottom )

    -- 用于 layout
    local left_width = left:getContentSize().width
    local left_height = left:getContentSize().height
    local bottom_width = bottom:getContentSize().width
    local bottom_height = bottom:getContentSize().height
    local left_bottom_width = left_bottom:getContentSize().width
    local left_bottom_height = left_bottom:getContentSize().height
    local item_width = origin_box.size.width
    local item_height = nil

    local next_item_index = 1
    local all_items = {}

    local cur_sel = 1
    local is_first = true

    local all_item_box = {}
    local items_group = selectbox_group()
    function items_group:onchange( box )
        cur_sel = box.index

        main_label:set_rich_string( box.info.text )

        if not is_first then
            need_expand = false
            expand( need_expand )
        end
        is_first = false

        if obj.sel_change then obj:sel_change( box ) end
    end

    function obj:setCurSel( index )
        items_group:setCurSel( index )
    end

    function obj:addItem( info, layout )
        local item = createMovieClipWithName( mcItemName )
        item:setAutoClear( false )
        bg_frame:addChild( item )

        --item_width = item.mcBoundingBox.size.width
        item_height = item.mcBoundingBox.size.height

        local item_win = TLWindow:createWindow( item )
        cb_win:AddChildWindow( item_win )

        local selbox = select_box( item_win, 'qiezhen', false )
        info.index = next_item_index
        selbox.info = info
        all_items[next_item_index] = item
        all_item_box[next_item_index] = selbox
        next_item_index = next_item_index + 1
        items_group:add( selbox )

        local item_text_label = label( item_win, 'sucaiwenzi', nil, CCImage.kAlignCenter )
        item_text_label:set_rich_string( info.text )

        if layout then self:layout() end
    end

    local layer_color = nil
    function obj:layout()
        drop_down_list_box.size.width = origin_box.size.width
        drop_down_list_box.size.height = origin_box.size.height
        drop_down_list_box.origin.x = origin_box.origin.x
        drop_down_list_box.origin.y = origin_box.origin.y
        is_expand = false

        local item_count = #all_items
        if item_count > 0 then
            local temp_width = item_width
            local temp_height = item_count * item_height + bottom_height

            bg_frame.mcBoundingBox.size.width = temp_width
            bg_frame.mcBoundingBox.size.height = temp_height
            bg_frame.mcBoundingBox.origin.x = -temp_width / 2
            bg_frame.mcBoundingBox.origin.y = -temp_height / 2

            if layer_color ~= nil then layer_color:removeFromParentAndCleanup( true ) end
            local c_width = temp_width - 2 * left_width
            local c_height = temp_height - bottom_height
            layer_color = CCLayerColor:create( ccc4( 0, 0, 0, 178 ), c_width, c_height )
            bg_frame:addChild( layer_color, -100 )
            layer_color:setPosition( -c_width / 2, bottom_height - temp_height / 2 )

            drop_down_list_box.size.width = temp_width
            drop_down_list_box.size.height = origin_box.size.height + temp_height
            drop_down_list_box.origin.x = -drop_down_list_box.size.width / 2
            drop_down_list_box.origin.y = origin_box.origin.y - temp_height

            local y = temp_height / 2 - item_height / 2
            for i=1,item_count do
                all_items[i]:setPositionY( y )
                y = y - item_height
            end

            local x = ( left_width - item_width ) / 2

            -- 左边 右边
            local left_real_height = temp_height - bottom_height
            local left_y = temp_height / 2 - left_real_height / 2
            left:setPosition( x, left_y )
            left:setScaleY( left_real_height / left_height )
            right:setPosition( -x, left_y )
            right:setScaleY( left_real_height / left_height )

            -- 左下 右下
            local bottom_y = left_bottom_height / 2 - temp_height / 2
            left_bottom:setPosition( x, bottom_y )
            right_bottom:setPosition( -x, bottom_y )

            -- 下
            bottom:setPositionY( bottom_y )
            bottom:setScaleX( item_width / bottom_width )
        end

        src_y = origin_box.size.height / 2 + bg_frame.mcBoundingBox.size.height / 2
        target_y = -src_y
        bg_frame:setPositionY( src_y )

        items_group:change( cur_sel )
    end

    return obj
end
