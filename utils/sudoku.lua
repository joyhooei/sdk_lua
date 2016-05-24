-- ./utils/sudoku.lua

local function create_sprite( info )
    local sprite = MCLoader:sharedMCLoader():loadSprite( info.file_name )
    sprite:setFlipX( info.flip_x or false )
    sprite:setFlipY( info.flip_y or false )
    sprite:setScaleX( info.scale_x or 1 )
    sprite:setScaleY( info.scale_y or 1 )
    return sprite
end

function createSudoku( index, width, height, batch_node, offset_x, offset_y )
    require 'gamecommon.sudoku_style'

    offset_x = offset_x or 0
    offset_y = offset_y or 0

    -- 
    local s_info = __sudoku_style__[index]
    if not s_info then return end

    local ret_sudoku = { left_width = nil, right_width = nil, top_height = nil, bottom_height = nil, offset_x = offset_x, offset_y = offset_y }

    -- 
    if batch_node then
        ret_sudoku.batch_node = batch_node
    else
        local tex = MCLoader:sharedMCLoader():loadTexture( s_info.texture_file )
        if not tex then
            CCLuaLog('                                    ')
            CCLuaLog('====================================')
            CCLuaLog('******error:sudoku_style index:'..tostring(index))
            CCLuaLog('====================================')
            CCLuaLog(debug.traceback())
            CCLuaLog('                                    ')
            index = 1
            s_info = __sudoku_style__[index]
            tex = MCLoader:sharedMCLoader():loadTexture( s_info.texture_file )
        end
        ret_sudoku.batch_node = CCSpriteBatchNode:createWithTexture( tex )
    end

    if ret_sudoku.batch_node.setCascadeOpacityEnabled then
        ret_sudoku.batch_node:setCascadeOpacityEnabled( true )
    end

    -- 
    if s_info.top_left then
        local sprite = create_sprite( s_info.top_left )
        ret_sudoku.batch_node:addChild( sprite )

        local size = sprite:getContentSize()
        size.width  = (s_info.top_left or {}).scale_x and size.width  * ((s_info.top_left or {}).scale_x or 1) or size.width 
        size.height = (s_info.top_left or {}).scale_y and size.height * ((s_info.top_left or {}).scale_y or 1) or size.height
        width = (s_info.top_left or {}).scale_x and size.width * 2 or width

        ret_sudoku.top_left_origin_x = -width * 0.5 + size.width * 0.5 + offset_x
        ret_sudoku.top_left_origin_y = height * 0.5 - size.height * 0.5 + offset_y

        ret_sudoku.left_width = size.width
        ret_sudoku.top_height = size.height
        ret_sudoku.top_left_sprite = sprite

        sprite:setPosition( ret_sudoku.top_left_origin_x, ret_sudoku.top_left_origin_y )
    end

    if s_info.top_right then
        local sprite = create_sprite( s_info.top_right )
        ret_sudoku.batch_node:addChild( sprite )

        local size = sprite:getContentSize()
        size.width  = (s_info.top_right or {}).scale_x and size.width  * ((s_info.top_right or {}).scale_x or 1) or size.width 
        size.height = (s_info.top_right or {}).scale_y and size.height * ((s_info.top_right or {}).scale_y or 1) or size.height

        ret_sudoku.top_right_origin_x = width * 0.5 - size.width * 0.5 + offset_x
        ret_sudoku.top_right_origin_y = height * 0.5 - size.height * 0.5 + offset_y

        ret_sudoku.right_width = size.width
        ret_sudoku.top_height = size.height
        ret_sudoku.top_right_sprite = sprite

        sprite:setPosition( ret_sudoku.top_right_origin_x, ret_sudoku.top_right_origin_y )
    end

    if s_info.bottom_left then
        local sprite = create_sprite( s_info.bottom_left )
        ret_sudoku.batch_node:addChild( sprite )

        local size = sprite:getContentSize()
        size.width  = (s_info.bottom_left or {}).scale_x and size.width  * ((s_info.bottom_left or {}).scale_x or 1) or size.width 
        size.height = (s_info.bottom_left or {}).scale_y and size.height * ((s_info.bottom_left or {}).scale_y or 1) or size.height

        ret_sudoku.bottom_left_origin_x = -width * 0.5 + size.width * 0.5 + offset_x
        ret_sudoku.bottom_left_origin_y = -height * 0.5 + size.height * 0.5 + offset_y

        ret_sudoku.left_width = size.width
        ret_sudoku.bottom_height = size.height
        ret_sudoku.bottom_left_sprite = sprite

        sprite:setPosition( ret_sudoku.bottom_left_origin_x, ret_sudoku.bottom_left_origin_y )
    end

    if s_info.bottom_right then
        local sprite = create_sprite( s_info.bottom_right )
        ret_sudoku.batch_node:addChild( sprite )

        local size = sprite:getContentSize()
        size.width  = (s_info.bottom_right or {}).scale_x and size.width  * ((s_info.bottom_right or {}).scale_x or 1) or size.width 
        size.height = (s_info.bottom_right or {}).scale_y and size.height * ((s_info.bottom_right or {}).scale_y or 1) or size.height

        ret_sudoku.bottom_right_origin_x = width * 0.5 - size.width * 0.5 + offset_x
        ret_sudoku.bottom_right_origin_y = -height * 0.5 + size.height * 0.5 + offset_y

        ret_sudoku.right_width = size.width
        ret_sudoku.bottom_height = size.height
        ret_sudoku.bottom_right_sprite = sprite

        sprite:setPosition( ret_sudoku.bottom_right_origin_x, ret_sudoku.bottom_right_origin_y )
    end

    local width_temp = width - ( ret_sudoku.left_width or 0 ) - ( ret_sudoku.right_width or 0 )
    local height_temp = height - ( ret_sudoku.top_height or 0 ) - ( ret_sudoku.bottom_height or 0 )
    local y_offset_temp = - (( ret_sudoku.top_height or 0 ) - ( ret_sudoku.bottom_height or 0 )) / 2

    -- 上 下
    if width_temp > 0 then
        if s_info.top then
            local sprite = create_sprite( s_info.top )
            ret_sudoku.batch_node:addChild( sprite )

            local size = sprite:getContentSize()
            size.width  = (s_info.top or {}).scale_x and (size.width  * ((s_info.top or {}).scale_x or 1)) or size.width 
            size.height = (s_info.top or {}).scale_y and (size.height * ((s_info.top or {}).scale_y or 1)) or size.height

            if ret_sudoku.right_width == nil and ret_sudoku.left_width == nil then
                width_temp = size.width
                height_temp = height_temp - size.height
                ret_sudoku.top_height = size.height
            end

            sprite:setScaleX( width_temp / (size.width / ((s_info.top or {}).scale_x or 1)))

            ret_sudoku.top_origin_x = offset_x
            ret_sudoku.top_origin_y = height * 0.5 - size.height * 0.5 + offset_y

            ret_sudoku.top_sprite = sprite

            sprite:setPosition( ret_sudoku.top_origin_x, ret_sudoku.top_origin_y )
        end

        if s_info.bottom then
            local sprite = create_sprite( s_info.bottom )
            ret_sudoku.batch_node:addChild( sprite )

            local size = sprite:getContentSize()
            size.width  = (s_info.bottom or {}).scale_x and (size.width  * ((s_info.bottom or {}).scale_x or 1)) or size.width 
            size.height = (s_info.bottom or {}).scale_y and (size.height * ((s_info.bottom or {}).scale_y or 1)) or size.height

            if ret_sudoku.right_width == nil and ret_sudoku.left_width == nil then
                width_temp = size.width
                height_temp = height_temp - size.height
                ret_sudoku.bottom_height = size.height
            end

            sprite:setScaleX( width_temp / (size.width / ((s_info.bottom or {}).scale_x or 1)))

            ret_sudoku.bottom_origin_x = offset_x
            ret_sudoku.bottom_origin_y = -height * 0.5 + size.height * 0.5 + offset_y

            ret_sudoku.bottom_sprite = sprite

            sprite:setPosition( ret_sudoku.bottom_origin_x, ret_sudoku.bottom_origin_y )
        end
    end

    -- 左右
    if height_temp > 0 then
        if s_info.left then
            local sprite = create_sprite( s_info.left )
            ret_sudoku.batch_node:addChild( sprite )

            local size = sprite:getContentSize()
            size.width  = (s_info.left or {}).scale_x and size.width  * ((s_info.left or {}).scale_x or 1) or size.width 
            size.height = (s_info.left or {}).scale_y and size.height * ((s_info.left or {}).scale_y or 1) or size.height

            if ret_sudoku.top_height == nil and ret_sudoku.bottom_height == nil then
                height_temp = size.height
                width_temp = width_temp - size.width
                ret_sudoku.left_width = size.width
            end

            sprite:setScaleY( height_temp / (size.height / ((s_info.left or {}).scale_y or 1)))

            ret_sudoku.left_origin_x = -width * 0.5 + size.width * 0.5 + offset_x
            ret_sudoku.left_origin_y = y_offset_temp + offset_y

            ret_sudoku.left_sprite = sprite

            sprite:setPosition( ret_sudoku.left_origin_x, ret_sudoku.left_origin_y )
        end

        if s_info.right then
            local sprite = create_sprite( s_info.right )
            ret_sudoku.batch_node:addChild( sprite )

            local size = sprite:getContentSize()
            size.width  = (s_info.right or {}).scale_x and size.width  * ((s_info.right or {}).scale_x or 1) or size.width 
            size.height = (s_info.right or {}).scale_y and size.height * ((s_info.right or {}).scale_y or 1) or size.height

            if ret_sudoku.top_height == nil and ret_sudoku.bottom_height == nil then
                height_temp = size.height
                width_temp = width_temp - size.width
                ret_sudoku.right_width = size.width
            end

            sprite:setScaleY( height_temp / (size.height / ((s_info.right or {}).scale_y or 1)))

            ret_sudoku.right_origin_x = width * 0.5 - size.width * 0.5 + offset_x
            ret_sudoku.right_origin_y = y_offset_temp + offset_y

            ret_sudoku.right_sprite = sprite

            sprite:setPosition( ret_sudoku.right_origin_x, ret_sudoku.right_origin_y )
        end
    end

    -- 中间
    if ( width_temp > 0 or height_temp > 0 ) and s_info.center then
        local sprite = create_sprite( s_info.center )
        ret_sudoku.batch_node:addChild( sprite )

        ret_sudoku.center_origin_x = ( ( ret_sudoku.left_width or 0 ) - ( ret_sudoku.right_width or 0 ) ) * 0.5 * ((s_info.center or {}).scale_x or 1) + offset_x
        ret_sudoku.center_origin_y = ( ( ret_sudoku.bottom_height or 0 ) - ( ret_sudoku.top_height or 0 ) ) * 0.5 * ((s_info.center or {}).scale_y or 1) + offset_y
        sprite:setPosition( ret_sudoku.center_origin_x, ret_sudoku.center_origin_y )

        local size = sprite:getContentSize()
        size.width  = (s_info.center or {}).scale_x and size.width  * ((s_info.center or {}).scale_x or 1) or size.width 
        size.height = (s_info.center or {}).scale_y and size.height * ((s_info.center or {}).scale_y or 1) or size.height

        sprite:setScaleX( width_temp  / (size.width  / ((s_info.center or {}).scale_x or 1)))
        sprite:setScaleY( height_temp / (size.height / ((s_info.center or {}).scale_y or 1)))

        ret_sudoku.center_sprite = sprite
    end

    function ret_sudoku:remove()
        if not batch_node then return self.batch_node:removeFromParentAndCleanup( true ) end
        if self.top_left_sprite then self.top_left_sprite:removeFromParentAndCleanup( true ) end
        if self.top_right_sprite then self.top_right_sprite:removeFromParentAndCleanup( true ) end
        if self.bottom_left_sprite then self.bottom_left_sprite:removeFromParentAndCleanup( true ) end
        if self.bottom_right_sprite then self.bottom_right_sprite:removeFromParentAndCleanup( true ) end
        if self.top_sprite then self.top_sprite:removeFromParentAndCleanup( true ) end
        if self.bottom_sprite then self.bottom_sprite:removeFromParentAndCleanup( true ) end
        if self.left_sprite then self.left_sprite:removeFromParentAndCleanup( true ) end
        if self.right_sprite then self.right_sprite:removeFromParentAndCleanup( true ) end
        if self.center_sprite then self.center_sprite:removeFromParentAndCleanup( true ) end
    end

    function ret_sudoku:setPosition( x, y )
        --if batch_node then return batch_node:setPosition( x, y ) end
        if self.top_left_sprite then self.top_left_sprite:setPosition( x + self.top_left_origin_x, y + self.top_left_origin_y ) end
        if self.top_right_sprite then self.top_right_sprite:setPosition( x + self.top_right_origin_x, y + self.top_right_origin_y ) end
        if self.bottom_left_sprite then self.bottom_left_sprite:setPosition( x + self.bottom_left_origin_x, y + self.bottom_left_origin_y ) end
        if self.bottom_right_sprite then self.bottom_right_sprite:setPosition( x + self.bottom_right_origin_x, y + self.bottom_right_origin_y ) end
        if self.top_sprite then self.top_sprite:setPosition( x + self.top_origin_x, y + self.top_origin_y ) end
        if self.bottom_sprite then self.bottom_sprite:setPosition( x + self.bottom_origin_x, y + self.bottom_origin_y ) end
        if self.left_sprite then self.left_sprite:setPosition( x + self.left_origin_x, y + self.left_origin_y ) end
        if self.right_sprite then self.right_sprite:setPosition( x + self.right_origin_x, y + self.right_origin_y ) end
        if self.center_sprite then self.center_sprite:setPosition( x + self.center_origin_x, y + self.center_origin_y ) end
    end

    -- 
    return ret_sudoku
end

function addSudokuToFrame( index, frame, batch_node, offset_x, offset_y, z_order )
    local sudoku = createSudoku( index, frame.mcBoundingBox.size.width, frame.mcBoundingBox.size.height, batch_node, offset_x, offset_y )
    frame:addChild( sudoku.batch_node, z_order or -1 )

    return sudoku
end

function resetSudokuColor( sudoku, color )
    if sudoku.batch_node.setCascadeColorEnabled then
        sudoku.batch_node:setCascadeColorEnabled( true )

        sudoku.batch_node:setColor( color )
    end
end

function createBatchSudoku( index, frame, batch_node )
    local box = frame.mcBoundingBox
    local x, y = frame:getPosition()

    return createSudoku( index, box.size.width, box.size.height, batch_node, x, y )
end

function test_sudoku( scene, x, y )
    local sudoku = createSudoku( 3, 200, 200 )
    sudoku.batch_node:setPosition( x, y )
    scene:addChild( sudoku.batch_node )
end

--[[
function test_batch_sudoku( scene, x, y )
    local mc = createMovieClipWithName( 'NUI/ngame_parts/parts1_13' )
    mc:setPosition( x, y )
    scene:addChild( mc )

    local sudoku_batch_node = nil
    local parent_node = nil
    for i=1,4 do
        local frame = toFrame( mc:getChildByName( 'di' .. i ) )
        parent_node = frame:getParent()

        sudoku_batch_node = createBatchSudoku( 7, frame, sudoku_batch_node ).batch_node
    end
    if sudoku_batch_node then parent_node:addChild( sudoku_batch_node, -1 ) end

end

--]]
