
-- 默认的解析 value 的方法，直接返回一个 table
local function defaultParseValue( value )
    local text = 'return {' .. value .. '}'
    local fn = loadstring( text )
    return ( fn ~= nil ) and fn() or {}
end

local function mark_color( richLabel, value, parse_value )
    local arg = parse_value( value )
    if arg.r ~= nil and type( arg.r ) == 'number' then richLabel:setFontColorR( arg.r ) end
    if arg.g ~= nil and type( arg.g ) == 'number' then richLabel:setFontColorG( arg.g ) end
    if arg.b ~= nil and type( arg.b ) == 'number' then richLabel:setFontColorB( arg.b ) end
    if arg.a ~= nil and type( arg.a ) == 'number' then richLabel:setFontColorA( arg.a ) end
end

local marks = {
    tab = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            if arg.num ~= nil then
                richLabel:moveOffsetX( arg.num, arg.flag )
            end
        end,
        parse_value_func = defaultParseValue,
    },
    color = {
        mark_func = function( richLabel, value, parse_value ) mark_color( richLabel, value, parse_value ) end,
        parse_value_func = defaultParseValue,
    },
    colorF = {
        mark_func = function( richLabel, value, parse_value ) mark_color( richLabel, value, parse_value ) end,
        parse_value_func = function( value )
            local temp = value:split( ';' )
            return { r = tonumber( temp[1] ), g = tonumber( temp[2] ), b = tonumber( temp[3] ), a = tonumber( temp[4] ), }
        end,
    },
    icon = {
        mark_func = function( richLabel, value, parse_value ) end,
        parse_value_func = defaultParseValue,
    },
    sprite = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            if arg.fileName ~= nil then
                local sprite = MCLoader:sharedMCLoader():loadSprite( arg.fileName )

                local size = sprite:getContentSize()
                local width = arg.width or size.width
                local height = arg.height or size.height

                if arg.scale ~= nil then
                    sprite:setScale( arg.scale )
                    width = width * arg.scale
                    height = height * arg.scale
                end

                if arg.rotate ~= nil then
                    sprite:setRotation( arg.rotate )
                end

                if arg.flipX ~= nil then
                    sprite:setFlipX(arg.flipX)
                end

                if arg.flipY ~= nil then
                    sprite:setFlipY(arg.flipY)
                end

                richLabel:appendSpriteToCurrentLine( sprite, width, height, arg.offsetX or 0, arg.layout ~= 0 )
            end
        end,
        parse_value_func = defaultParseValue,
    },
	endl = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            local count = 1
            if arg.num ~= nil and type( arg.num ) == 'number' then count = arg.num end
            for i=1,count do richLabel:appendLine( true ) end
        end,
        parse_value_func = defaultParseValue,
    },
    button = {
        mark_func = function( richLabel, value, parse_value )
            local win = richLabel:getWindow()
            if toTLWindow( win ) == nil then return end

            local arg = parse_value( value )

            if arg.click_func ~= nil then
                richLabel:setCurrentNodeHandler( function( sprite )
                    --CCLuaLog( 'sprite = ' .. tostring( sprite ) )
                    local btnWin = TLWindow:createWindow( sprite )
                    win:AddChildWindow( btnWin )

                    init_simple_button( btnWin, function()
                        arg.click_func( arg.args )
                    end)
                end)
            else
                richLabel:clearCurrentNodeHandler()
            end
        end,
        parse_value_func = defaultParseValue,
    },
    movieclip = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            if arg.mcName ~= nil then
                local mc = createMovieClipWithName( arg.mcName )
                local width = arg.width or mc.mcBoundingBox.size.width
                local height = arg.height or mc.mcBoundingBox.size.height

                richLabel:appendSpriteToCurrentLine( mc, width, height, width * 0.5, arg.layout ~= 0 )

                if arg.init_func then arg.init_func( mc ) end
            end
        end,
        parse_value_func = defaultParseValue,
    },
    colorindex = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            if arg.colorIndex then
                richLabel:setColorIndex( arg.colorIndex )
            end
        end,
        parse_value_func = defaultParseValue,
    },
    frame = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            local width  = arg.width  or 4
            local height = arg.height or 4

            local frame = MCFrame:createWithBox(CCRect(width / -2, height / -2, width, height))

            richLabel:appendSpriteToCurrentLine( frame, width, height, width * 0.5, arg.layout ~= 0 )

            if arg.init_func then arg.init_func( frame ) end
        end,
        parse_value_func = defaultParseValue,
    },
    fontsize = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            if arg then
                richLabel:setFontSize( arg )
            end
        end,
        parse_value_func = tonumber,
    },
    shadow = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            richLabel:setEnableShadow( arg.enable )

            if arg.shadow_blur then richLabel:setShadowBlur( arg.shadow_blur ) end
            if arg.r and type( arg.r ) == 'number' then richLabel:setShadowColorR( arg.r ) end
            if arg.g and type( arg.g ) == 'number' then richLabel:setShadowColorG( arg.g ) end
            if arg.b and type( arg.b ) == 'number' then richLabel:setShadowColorB( arg.b ) end
            if arg.a and type( arg.a ) == 'number' then richLabel:setShadowColorA( arg.a ) end
        end,
        parse_value_func = defaultParseValue,
    },
    stroke = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )
            richLabel:setEnableStroke( arg.enable )

            if arg.stroke_width then richLabel:setStrokeWidth( arg.stroke_width ) end
        end,
        parse_value_func = defaultParseValue,
    },
    SS = {
        mark_func = function( richLabel, value, parse_value )
            local arg = parse_value( value )

            richLabel:setEnableShadow( arg.shadow )
            richLabel:setEnableStroke( arg.stroke )

            if arg.shadow_blur then richLabel:setShadowBlur( arg.shadow_blur ) end
            if arg.r and type( arg.r ) == 'number' then richLabel:setShadowColorR( arg.r ) end
            if arg.g and type( arg.g ) == 'number' then richLabel:setShadowColorG( arg.g ) end
            if arg.b and type( arg.b ) == 'number' then richLabel:setShadowColorB( arg.b ) end
            if arg.a and type( arg.a ) == 'number' then richLabel:setShadowColorA( arg.a ) end
        end,
        parse_value_func = defaultParseValue,
    },
}

function parseRichTextMark( mark, value, richLabel )
    if mark == nil or value == nil or richLabel == nil then return end

    local m = marks[mark]
    if m ~= nil then
        m.mark_func( richLabel, value, m.parse_value_func )
    end
end

function addRichTextMark( mark, mark_func, parse_value_func )
    marks[mark] = {
        mark_func = mark_func,
        parse_value_func = parse_value_func or defaultParseValue,
    }
end
