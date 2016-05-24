-- ./login/boot_check_upgrade.lua

local function createBackground( height )
    local tex = MCLoader:sharedMCLoader():loadTexture( 'mc/5NgameUI_010.png' )
    local batch_node = CCSpriteBatchNode:createWithTexture( tex )

    local top_sprite = MCLoader:sharedMCLoader():loadSprite( '5ui_010_7.png' )
    top_sprite:setFlipY( true )
    batch_node:addChild( top_sprite )

    local title_size = top_sprite:getContentSize()
    top_sprite:setPosition( 0, ( height - title_size.height ) * 0.5 )

    local center_height = height - title_size.height
    local offset_y = height * 0.5 - title_size.height

    local __create_center_sprite__ = nil
    __create_center_sprite__ = function( c_height )
        if c_height <= 0 then return end

        local center_sprite = MCLoader:sharedMCLoader():loadSprite( '5ui_010_8.png' )
        local center_size = center_sprite:getContentSize()
        center_sprite:setPosition( 0, offset_y - center_size.height * 0.5 )
        batch_node:addChild( center_sprite )

        offset_y = offset_y - center_size.height
        __create_center_sprite__( c_height - center_size.height )
    end
    __create_center_sprite__( center_height )

    local bottom_sprite = MCLoader:sharedMCLoader():loadSprite( '5ui_010_7.png' )
    local bottom_size = bottom_sprite:getContentSize()
    bottom_sprite:setPosition( 0, offset_y - bottom_size.height * 0.5 )
    batch_node:addChild( bottom_sprite )

    local node = CCNode:create()
    node:addChild( batch_node )

    local winSize = getWinRealSize()
    local layer_color = CCLayerColor:create( ccc4( 0, 0, 0, 255 * 0.8 ), winSize.width, winSize.height )
    layer_color:setPosition( -winSize.width * 0.5, -winSize.height * 0.5 )
    node:addChild( layer_color, -1 )

    return node
end

local function createBootLoadingProgressBar( width )
    local progress_obj = {}

    local sudoku_type = 'progress'
    local width, height = width or 638, 30
    require 'utils.sudoku'
    local sudoku_shadow = createSudoku( sudoku_type, width, height )
    local sudoku_pregress = createSudoku( sudoku_type, width, height )

    progress_obj.frame = MCFrame:createWithBox( CCRect( width / -2, height / -2, width, height ) )

    local node_progress = CCNode:create()
    local node_shadow = CCNode:create()
    progress_obj.frame:addChild( node_progress, 1 )
    progress_obj.frame:addChild( node_shadow, -1 )
    node_shadow:setPosition( -3, -6 )

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
    render_progress:setCustomUniforms( 109 / 255, 107 / 255, 245 / 255, 255 / 255 )

    function progress_obj:setPercent( per )
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

function checkUpgrade( boot_win, upgrade_call_back_func )
    if not GameSettings.is_check_upgrade then
        game_version = '0'          -- 这是让服务器不判断版本

        return upgrade_call_back_func( true )
    end

    -- 初始化进度条
    local progress_obj = createBootLoadingProgressBar()
    progress_obj.frame:setVisible( false )
    progress_obj.frame:setPosition( 0, -200 )
    boot_win.frame:addChild( progress_obj.frame )
    progress_obj:setPercent( 0 )

    local upgrade_win = TLWindow:createWindow( progress_obj.frame )
    boot_win.win:AddChildWindow( upgrade_win )

    -- local mc_upgrade = createMovieClipWithName( 'xjl_1UI_dl/xjl_parts/parts_2_1' )
    -- mc_upgrade:setPosition( 0, -450 )
    -- mc_upgrade:setVisible( false )
    -- boot_win.frame:addChild( mc_upgrade )

    -- local upgrade_win = TLWindow:createWindow( mc_upgrade )
    -- boot_win.win:AddChildWindow( upgrade_win )

    -- local progress = progressBar_FromWin( upgrade_win, 'lodingnan', 'ui_002_3x.png', 0, 1 )
    -- local progress_label = label( upgrade_win, 'fuwuqi', nil, CCImage.kAlignCenter )
    -- local progress_arrow = MCLoader:sharedMCLoader():loadSprite( 'ui_001x.png' )
    -- local progress_arrow_bg = mc_upgrade:getChildByName('lodingnan2')
    -- progress_arrow_bg:addChild(progress_arrow)
    -- progress.setValue( 0 )

    -- 更新过程显示的粒子效果
    -- local progress_arrow_par_handle, progress_arrow_par_node = nil, nil

    -- 更新失败
    local function __upgrade_failed__( reason )
        if reason then
            --openMessageBox( _YYTEXT( '更新失败' ), reason, 'MB_OK' )
            openMessageBox_lite( _YYTEXT( '更新失败' ), reason, 'MB_OK' )
        end

        upgrade_call_back_func( false )
    end

    -- 
    local check_info = {
        failed_cb = function( reason ) __upgrade_failed__( reason ) end,
        update_cb = function( downloaded_size, total_size )
            if toTLWindow( upgrade_win ) then
                progress_obj:setPercent( downloaded_size / total_size )
                progress_obj:setProgressLabel( string.format( _YYTEXT( '加载资源 %.2fM/%.2fM' ), downloaded_size/1024/1024, total_size/1024/1024 ) )
                -- local clip_width = progress.setValue( downloaded_size / total_size )
                -- progress_label:set_rich_string( string.format( _YYTEXT( '加载资源 %.2fM/%.2fM' ), downloaded_size/1024/1024, total_size/1024/1024 ) )
                -- progress_arrow_bg:setPositionX( clip_width - progress.frame.mcBoundingBox.size.width/2 )
            end
        end,
        prepare_cb = function( downloaded_size, total_size, real_download_cb )
            --TLWindowManager:SharedTLWindowManager():SetLockScreenWindow( mb_obj.win )
            openMessageBox_lite( '', _YYTEXT( '发现新资源,确认是否开始加载?' ), 'MB_OKCANCEL', {
            --openMessageBox( '', _YYTEXT( '发现新资源,确认是否开始加载?' ), 'MB_OKCANCEL', {
                ['MB_OK'] = function()
                    schedule_once_time( 0.1, function()
                        -- 創建進度條粒子
                        -- progress_arrow_par_handle, progress_arrow_par_node = playEffect_SE( { resourceId = 'particle/ui_zenliang', loop = -1, scaleX = 1, scaleY = 1 }, { x = 70, y = 32 }, progress_arrow, 1, 1 )
                        -- mc_upgrade:setVisible( true )
                        progress_obj.frame:setVisible( true )
                        real_download_cb()
                    end)
                end,
                ['MB_CANCEL'] = function() upgrade_call_back_func( false ) end,
            })
        end,
        big_upgrade_cb = function( reason, url ) __upgrade_failed__( reason ) end,
        complete_cb = function( complete_type )
            CCLuaLog( '更新完成 : ' .. tostring( complete_type ) )

            -- 如果不是经过下载文件完成的话，直接返回就可以了
            if complete_type ~= 'update_complete' then return upgrade_call_back_func( true ) end

            -- 给个提示更新完成，但不需要按钮关闭
            local winSize = getWinRealSize()

            local text_width = 400
            local text_height = 200

            require 'utils.CCNodeExtend'
            local box = CCRect( -text_width / 2, -text_height / 2, text_width, text_height )
            local frame = CCNodeExtend.extend( MCFrame:createWithBox( box ) )
            frame:setPosition( winSize.width / 2, winSize.height / 2 )
            all_scene_layers[layer_type_mask]:addChild( frame )

            frame:addChild( createBackground( text_height ) , -1 )

            local text_label = TLLabelRichTex:create( '', 24, CCSize( text_width - 40, text_height - 40 ), CCImage.kAlignCenter )
            text_label:setPositionY( -10 )
            text_label:setRichString( _YYTEXT( '正在重新加载资源，请稍后...' ), TL_RICH_STRING_FLAG_ONE_LINE )
            frame:addChild( text_label )

            schedule_once_time( 0.1, function()
                -- 强制清理贴图
                removeUnusedTextures( true )

                -- 这是为了让进度条有个刷新显示的机会
                assert( AssetsManager:sharedAssetsManager():Load(), "assets index load failed" )
                MCLoader:sharedMCLoader():loadIndexFile( "mc/anim.index", "mc/frames.index" )

                -- 所有已经被加载过的，全部重新加载
                local loaded_files = {}
                for k,v in pairs( package.loaded ) do
                    local p1, p2 = string.find( k, 'utils.' )
                    if p1 == 1 and p2 == 6 then table.insert( loaded_files, k ) end

                    local p1, p2 = string.find( k, 'config.' )
                    if p1 == 1 and p2 == 7 then table.insert( loaded_files, k ) end

                    local p1, p2 = string.find( k, 'ui.' )
                    if p1 == 1 and p2 == 3 then table.insert( loaded_files, k ) end

                    local p1, p2 = string.find( k, 'win.' )
                    if p1 == 1 and p2 == 4 then table.insert( loaded_files, k ) end

                    local p1, p2 = string.find( k, 'autoload.' )
                    if p1 == 1 and p2 == 9 then table.insert( loaded_files, k ) end

                    local p1, p2 = string.find( k, 'launch.' )
                    if p1 == 1 and p2 == 7 then table.insert( loaded_files, k ) end

                    local p1, p2 = string.find( k, 'login.' )
                    if p1 == 1 and p2 == 6 then table.insert( loaded_files, k ) end
                end

                for _,file_name in ipairs( loaded_files ) do package.loaded[file_name] = nil end

                require 'config.GameSettings'
                require 'utils.CCGeometryExtend'
                require 'utils.protobuf'
                require 'utils.common'
                require 'utils.userconfig'
                require 'utils.shaders'
                require 'utils.richMark'
                require 'utils.enums'
                require 'ui.controls'
                require 'utils.table'
                require 'utils.effect'
                require 'win.message_box'
                require 'utils.netmessage'

                protobuf.register( getFileData( 'config/poem.pb' ) )
                protobuf.register( getFileData( 'config/config.pb' ) )

                g_device_obj = require( string.format( 'launch.device_%s', getPlatform() ) ).new()
                -- 重新加載 sdk_login_file
                g_sdk_login_obj = g_device_obj:requireSDK().new()

                -- 
                updateReloadShaders()

                -- 下一幀才返回吧，顺便把提示窗口关闭
                schedule_once( function()
                    -- 移除增量时候的粒子效果
                    if toTLWindow( upgrade_win ) then
                        -- if toCCNode( progress_arrow_par_node ) then progress_arrow_par_node:stopInfiniteLoop() end
                        -- mc_upgrade:setVisible( false )
                        progress_obj.frame:setVisible( false )
                    end
                    -- progress_arrow_par_node = nil
                    -- progress_arrow_par_handle = nil

                    -- 增量更新完成后，还需要拉取服务器列表以及检查配置更新，所以在这里就等这两个都完成了，才清理
                    upgrade_call_back_func( true, function()
                        frame:tweenFromToOnce( LINEAR_IN, NODE_PRO_CUSTOM, 0, 0.1, 1, 0, function() frame:removeFromParentAndCleanup( true ) end, function( value )
                            frame:setScale( value )
                            setNodeAlphaLua( frame, 255 * value )
                        end)
                    end)
                end)
            end)
        end,
    }

    local check_upgrade = require( 'utils.check_upgrade_impl' ).new( check_info )
    check_upgrade:checkUpgrade()
end

