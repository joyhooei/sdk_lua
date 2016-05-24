
function test_shader( scene )
    test_gray( scene, 100, 100 )
    test_normal( scene, 100, 250 )
    test_stroke( scene, 100, 400 )

    test_change_color( scene, 250, 100 )
    test_mosaics_sharpen_fuzzy_laplacian( scene, 250, 250 )

    test_HDR( scene, 400, 100 )
    test_mosaics_sharpen_fuzzy_gaussian( scene, 400, 250 )

    test_relief( scene, 550, 100 )
    test_mosaics_sharpen_fuzzy_smooth( scene, 550, 250 )

    test_mosaics_box( scene, 700, 100 )
    test_mosaics_round( scene, 700, 250 )

    TLFontTex:setFontOriginSize( 16 )
    TLFontTex:setFontConfigFile( 'config/hzb(2500).ini' )
    TLFontTex:setParseRichTextHandler( parseRichTextMark )
    TLFontTex:sharedTLFontTex():createFontTexture()

    local layerColor = CCLayerColor:create( ccc4( 255,255,255, 200 ), 400, 240 )
    layerColor:setPosition( 200, 120 )
    layerColor:setAnchorPoint( CCPoint( 0.5, 0.5 ) )
    scene:addChild( layerColor )

    local size = layerColor:getContentSize()

    local layerC = CCLayerColor:create( ccc4( 255,0,0, 255 ), 10, 10 )
    layerC:setPosition( 395, 235 )
    layerC:setAnchorPoint( CCPoint( 0.5, 0.5 ) )
    scene:addChild( layerC )

    local node = CCNode:create()
    node:setPosition( 400, 240 )
    scene:addChild( node )
end

-- test normal
function test_normal( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test gray
function test_gray( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_gray' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test change color
function test_change_color( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_change_color' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    local count,max_count = 0,10
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )

        count = count + 1
        if count > max_count then
            count = 0

            local r = math.random()
            local g = math.random()
            local b = math.random()
            local a = math.random()

            -- set color
            shader_program:setCustomUniforms( r, g, b, a )
        end
    end)
end

-- test HDR
function test_HDR( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_HDR' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test relief
function test_relief( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_relief' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    -- set texture size
    local texSize = sprite1:getTexture():getContentSize()
    shader_program:setCustomUniforms( texSize.width, texSize.height, 0, 0 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test mosaics box
function test_mosaics_box( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_mosaics_box' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    -- set texture size
    local texSize = sprite1:getTexture():getContentSize()
    shader_program:setCustomUniforms( texSize.width, texSize.height, 8, 8 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test mosaics round
function test_mosaics_round( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_mosaics_round' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    -- set texture size
    local texSize = sprite1:getTexture():getContentSize()
    shader_program:setCustomUniforms( texSize.width, texSize.height, 16, 16 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test mosaics sharpen fuzzy smooth
function test_mosaics_sharpen_fuzzy_smooth( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_sharpen_fuzzy_smooth' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    -- set texture size
    local texSize = sprite1:getTexture():getContentSize()
    shader_program:setCustomUniforms( texSize.width, texSize.height, 16, 16 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test mosaics sharpen fuzzy gaussian
function test_mosaics_sharpen_fuzzy_gaussian( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_sharpen_fuzzy_gaussian' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    -- set texture size
    local texSize = sprite1:getTexture():getContentSize()
    shader_program:setCustomUniforms( texSize.width, texSize.height, 16, 16 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test mosaics sharpen fuzzy laplacian
function test_mosaics_sharpen_fuzzy_laplacian( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_sharpen_fuzzy_laplacian' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    -- set texture size
    local texSize = sprite1:getTexture():getContentSize()
    shader_program:setCustomUniforms( texSize.width, texSize.height, 16, 16 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

-- test mosaics sharpen fuzzy stroke
function test_stroke( scene_node, x, y )
    local size = CCDirector:sharedDirector():getWinSize()

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_stroke' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite1:setAnchorPoint( CCPoint( 1, 0 ) )
    sprite1:setShaderProgram( shader_program )
    sprite_node:addChild( sprite1 )

    local sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite2:setAnchorPoint( CCPoint( 0, 0 ) )
    sprite2:setShaderProgram( shader_program )
    sprite2:setFlipX( true )
    sprite_node:addChild( sprite2 )

    local sprite3 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite3:setAnchorPoint( CCPoint( 1, 1 ) )
    sprite3:setShaderProgram( shader_program )
    sprite3:setFlipY( true )
    sprite_node:addChild( sprite3 )

    local sprite4 = MCLoader:sharedMCLoader():loadSprite( 'UI_0083.png' )
    sprite4:setAnchorPoint( CCPoint( 0, 1 ) )
    sprite4:setShaderProgram( shader_program )
    sprite4:setFlipX( true )
    sprite4:setFlipY( true )
    sprite_node:addChild( sprite4 )

    -- set texture size
    local texSize = sprite1:getTexture():getContentSize()
    shader_program:setCustomUniforms( texSize.width, texSize.height, 16, 16 )

    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )

    local rotate = 0
    schedule_circle( 0.03, function()
        rotate = rotate + 1
        sprite_node:setRotation( rotate )
    end)
end

function test_change_color_ex( scene_node, x, y, color )
    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_change_color_ex' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( 'xiaoqiao.png' )
    sprite1:setShaderProgram( shader_program )
    sprite1:setCustomUniforms( color.r, color.g, color.b, color.a )
    sprite1:setScale( 0.5 )

    sprite_node:addChild( sprite1 )
    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )
end

function test_texture_flow( scene_node, tex, x, y, time, su, sv )
    su = su or 0
    sv = sv or 0

    local sprite_node = CCNode:create()

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_texture_flow' )

    local sprite1 = MCLoader:sharedMCLoader():loadSprite( tex )
    sprite1:setShaderProgram( shader_program )

    local tu,tv = 0,0
    schedule_circle( time, function()
        tu = tu + su
        tv = tv + sv
        sprite1:setCustomUniforms( tu, tv, 0, 0 )
    end)

    sprite_node:addChild( sprite1 )
    sprite_node:setPosition( x, y )
    scene_node:addChild( sprite_node )
end

function test_outer_glow( scene_node, size )
    -- 外发光测试
    local layer_color = CCLayerColor:create( ccc4( 68, 88, 40, 255 ), size.width, size.height )
    scene_node:addChild( layer_color )

    -- src 
    local sprite = loadIcon( 200042, 'body' )
    sprite:setPosition( size.width / 2, size.height / 4 )
    scene_node:addChild( sprite )

    -- glow 
    require 'utils.CCNodeExtend'
    local sprite_1 = CCNodeExtend.extend( loadIcon( 200042, 'body' ) )
    local r, g, b, param = 1.0, 1.0, 0.33, 3.5
    sprite_1:outerGlow( true, r, g, b, param )
    sprite_1:setPosition( size.width / 2, size.height * 0.75 )
    scene_node:addChild( sprite_1 )
end

function test_zoomblur( scene_node, x, y )
    -- 测试径向模糊
    require 'utils.CCNodeExtend'
    local sprite = CCNodeExtend.extend( MCLoader:sharedMCLoader():loadSprite( '10011_5.png' ) )
    sprite:setPosition( x, y )
    scene_node:addChild( sprite )

    local shader_program = CCShaderCache:sharedShaderCache():programForKey( 'position_texture_color_zoomblur' )
    sprite:setShaderProgram( shader_program )
    sprite:setCustomUniforms( 0.5, 0.5, 0.2, 0.0 )

    sprite:tweenFromTo( LINEAR_IN, NODE_PRO_SCALE, 0, 0.3, 0.3, 1, 1.5, -1, function() end )
end

