
function treectrl( win, name, ygap )
    local fontSize = 24
    local obj = {}
    obj.scroller = scrollable( win, name, TL_SCROLL_TYPE_UP_DOWN, ygap or 0 )

    local root_frame = obj.scroller.frame

    obj.rootItems = {}
    obj.nextRootItemHandle = 1
    function obj:insertRootItem( itemText, alignment, expand_call_back_func )
        local item = {}
        alignment = alignment or CCImage.kAlignBottomLeft
        item.expand = false

        item.childItems = {}
        item.nextChildItemIndex = 1

        -- 
        --item.sprite1 =  MCLoader:sharedMCLoader():loadSprite('Nui_0004_88.png')
        --item.sprite1:setScale(fontSize / getBoundingBox(item.sprite1).size.height)
        --item.sprite2 = MCLoader:sharedMCLoader():loadSprite( 'UI_00226_2.png' )
        --local size = getBoundingBox(item.sprite1).size
        local size = {
            width  = 0,
            height = 0,
        }

        item.child_offset = size.width

        local width = root_frame.mcBoundingBox.size.width-- * 0.95
        
        -- lable and height
        local text_width = width - size.width
        local text_height = size.height
        local height = size.height
        local textLabel = TLLabelRichTex:create( itemText or ' ', fontSize, CCSize( text_width, text_height ) )
        local size_real = textLabel:getRealSize()
        size_real.width = text_width
        textLabel:setContentSize(size_real)
        
        local height = size_real.height + 2

        item.origin_box = CCRect( -width * 0.5, -height * 0.5, width, height )
        item.max_box = CCRect( -width * 0.5, -height * 0.5, width, height )

        item.rootFrame = MCFrame:createWithBox( item.origin_box )
        item.rootWin = TLWindow:createWindow( item.rootFrame )

        -- 
        item.frame = MCFrame:createWithBox( item.origin_box )
        item.rootFrame:addChild( item.frame )

        --[[
        local layerColor_1 = CCLayerColor:create( ccc4( 0, 0, 0, 255), width, height )
        item.frame:addChild( layerColor_1 )
        layerColor_1:setPosition( -width * 0.5, -height * 0.5 )

        local layerColor = CCLayerColor:create( ccc4( 255, 255, 255, 128 ), width - 2, height - 2)
        item.frame:addChild( layerColor )
        layerColor:setPosition( -width * 0.5 + 1, -height * 0.5 + 1 )
        --]]

        item.win = TLWindow:createWindow( item.frame )
        item.rootWin:AddChildWindow( item.win )
        init_simple_button( item.win, function()
            item.expand = not item.expand

            -- layout
            self.onClickHandle = item.handle
            self:layout()
        end)

        local x = ( size.width - item.origin_box.size.width ) * 0.5
        local y = 0
        --item.sprite1:setPosition( x, y )
        --item.sprite2:setPosition( x, y )

        --item.frame:addChild( item.sprite1 )
        --item.frame:addChild( item.sprite2 )

        item.frame:addChild( textLabel )
        textLabel:setPosition( size.width / 2, y )
        textLabel:setAlignment( alignment )
        textLabel:setRichString( itemText or '' )

        self.scroller:append( item.rootWin )

        function item:layout()
            -- 根据标记显示隐藏对应的 sprite
            --self.sprite1:setVisible( not self.expand )
            --self.sprite2:setVisible( self.expand )
            
            -- 点击块的上边缘
            local _tmp_p = self.rootFrame:getPositionY() + self.rootFrame.mcBoundingBox.size.height / 2

            -- 重置 root frame 的 bounding box
            if self.expand then
                self.rootFrame.mcBoundingBox.size.height = self.max_box.size.height
                self.rootFrame.mcBoundingBox.origin.y = -self.max_box.size.height * 0.5

                -- 如果是点击块的话判断下边缘是否不可见
                if self.handle and self.handle == obj.onClickHandle then
                    -- 点击块的下边缘
                    _tmp_p = _tmp_p - self.rootFrame.mcBoundingBox.size.height
                    local x = -(root_frame.mcBoundingBox.size.height / 2) - _tmp_p - obj.scroller:getPosition()
                    if x > 0 then
                        obj.scroller:setPosition(obj.scroller:getPosition() + x)
                    end
                end
            else
                self.rootFrame.mcBoundingBox.size.height = self.origin_box.size.height
                self.rootFrame.mcBoundingBox.origin.y = -self.origin_box.size.height * 0.5
            end
            self.rootFrame.mcOriginBoundingBox = self.rootFrame.mcBoundingBox
            self.rootFrame:setContentSize( self.rootFrame.mcBoundingBox.size )

            -- 
            local y = self.expand and ( self.max_box.size.height - self.origin_box.size.height ) * 0.5 or 0
            self.frame:setPositionY( y )

            for i=1,self.nextChildItemIndex-1 do
                local childItem = self.childItems[i]
                if childItem ~= nil then
                    childItem.textLabel:setVisible( self.expand )
                    if self.expand then
                        y = y - childItem.realSize.height
                        childItem.textLabel:setPositionY( y )
                    end
                end
            end

            if expand_call_back_func then expand_call_back_func( self ) end
        end

        -- 返回句柄
        local handle = self.nextRootItemHandle
        self.nextRootItemHandle = self.nextRootItemHandle + 1
        self.rootItems[handle] = item
        item.handle = handle

        return handle
    end

    function obj:insertRootItemEx( width, height, request_tex_url )
        local item = {}
        item.child_offset = 0
        item.expand = false

        item.childItems = {}
        item.nextChildItemIndex = 1

        width = width > root_frame.mcBoundingBox.size.width and root_frame.mcBoundingBox.size.width or width

        item.origin_box = CCRect( -width * 0.5, -height * 0.5, width, height )
        item.max_box = CCRect( -width * 0.5, -height * 0.5, width, height )

        item.rootFrame = MCFrame:createWithBox( item.origin_box )
        item.rootWin = TLWindow:createWindow( item.rootFrame )

        -- 
        item.frame = MCFrame:createWithBox( item.origin_box )
        item.rootFrame:addChild( item.frame )

        item.win = TLWindow:createWindow( item.frame )
        item.rootWin:AddChildWindow( item.win )
        init_simple_button( item.win, function()
            item.expand = not item.expand

            -- layout
            self.onClickHandle = item.handle
            self:layout()
        end)

        -- 可写路径
        local parts = request_tex_url:split( '/' )
        local tex_file_name = parts[#parts]
        local tex_full_path = get_external_path() .. tex_file_name

        -- 如果本地已经存在的话，就直接加载
        if CCFileUtils:sharedFileUtils():checkFileExists( tex_full_path, 0 ) then
            local sprite = MCLoader:sharedMCLoader():loadSprite( tex_file_name )
            item.frame:addChild( sprite )
        else
            local node_loading = createMovieClipWithName('60057/60057_10')
            node_loading:play(0, -1, -1)
            item.frame:addChild( node_loading )

            item.frame:retain()

            if not g_allBroadCastInfos.picPath then g_allBroadCastInfos.picPath = {} end
            if not g_allBroadCastInfos.picPath[request_tex_url] then
                g_allBroadCastInfos.picPath[request_tex_url] = {}
                table.insert(g_allBroadCastInfos.picPath[request_tex_url], item.frame)

                TLHttpClient:sharedHttpClient():requestFile( request_tex_url, '', function( content_data, http_code, error_code, error_msg )
                    if table.len(g_allBroadCastInfos or {}) <= 0 then return end
                    if not toTLWindow(item.win) then return end
                    if http_code == 404 then 
                        for k, frame in pairs(g_allBroadCastInfos.picPath[request_tex_url]) do
                            if not toCCNode(frame) then return end
                            frame:release()
                            g_allBroadCastInfos.picPath[request_tex_url][k] = nil
                        end
                        return
                    end
                    local file = assert( io.open( tex_full_path, 'wb' ), 'file open failed ' .. tex_full_path )
                    file:write( content_data )
                    file:close()

                    schedule_once( function()
                        if g_allBroadCastInfos.picPath then
                            for k, frame in pairs(g_allBroadCastInfos.picPath[request_tex_url] or {}) do
                                if not toCCNode(frame) then return end
                                if frame:retainCount() > 1 then
                                    frame:removeAllChildrenWithCleanup(true)
                                    local sprite = MCLoader:sharedMCLoader():loadSpriteAsync( tex_file_name )
                                    frame:addChild( sprite )
                                end
                                frame:release()
                                g_allBroadCastInfos.picPath[request_tex_url][k] = nil
                            end
                        end
                    end)
                end)
            else
                table.insert(g_allBroadCastInfos.picPath[request_tex_url], item.frame)
            end
        end

        self.scroller:append( item.rootWin )

        function item:layout()
            -- 点击块的上边缘
            local _tmp_p = self.rootFrame:getPositionY() + self.rootFrame.mcBoundingBox.size.height / 2

            -- 重置 root frame 的 bounding box
            if self.expand then
                self.rootFrame.mcBoundingBox.size.height = self.max_box.size.height
                self.rootFrame.mcBoundingBox.origin.y = -self.max_box.size.height * 0.5

                -- 如果是点击块的话判断下边缘是否不可见
                if self.handle and self.handle == obj.onClickHandle then
                    -- 点击块的下边缘
                    _tmp_p = _tmp_p - self.rootFrame.mcBoundingBox.size.height
                    local x = -(root_frame.mcBoundingBox.size.height / 2) - _tmp_p - obj.scroller:getPosition()
                    if x > 0 then
                        obj.scroller:setPosition(obj.scroller:getPosition() + x)
                    end
                end
            else
                self.rootFrame.mcBoundingBox.size.height = self.origin_box.size.height
                self.rootFrame.mcBoundingBox.origin.y = -self.origin_box.size.height * 0.5
            end
            self.rootFrame.mcOriginBoundingBox = self.rootFrame.mcBoundingBox
            self.rootFrame:setContentSize( self.rootFrame.mcBoundingBox.size )

            -- 
            local y = self.expand and ( self.max_box.size.height - self.origin_box.size.height ) * 0.5 or 0
            self.frame:setPositionY( y )

            for i=1,self.nextChildItemIndex-1 do
                local childItem = self.childItems[i]
                if childItem ~= nil then
                    childItem.textLabel:setVisible( self.expand )
                    if self.expand then
                        y = y - childItem.realSize.height
                        childItem.textLabel:setPositionY( y )
                    end
                end
            end
        end

        -- 返回句柄
        local handle = self.nextRootItemHandle
        self.nextRootItemHandle = self.nextRootItemHandle + 1
        self.rootItems[handle] = item
        item.handle = handle

        return handle
    end

    function obj:insertChildItem( handle, itemText, layout, width, height, alignment )
        alignment = alignment or CCImage.kAlignBottomLeft
        local rootItem = self.rootItems[handle]
        if rootItem == nil then return end

        local childItem = {}
        local text_width = width or (rootItem.origin_box.size.width - rootItem.child_offset)
        local text_height = height or rootItem.origin_box.size.height
        childItem.textLabel = TLLabelRichTex:create( '', fontSize, CCSize( text_width, text_height ) )
        childItem.textLabel:setAlignment( alignment )

        local y = -rootItem.max_box.size.height
        childItem.textLabel:setPosition( rootItem.child_offset / 2, y )
        childItem.textLabel:setRichString( itemText or '' )
        childItem.realSize = childItem.textLabel:getRealSize()

        rootItem.max_box.size.height = rootItem.max_box.size.height + childItem.realSize.height
        rootItem.max_box.origin.y = -rootItem.max_box.size.height * 0.5

        rootItem.childItems[rootItem.nextChildItemIndex] = childItem
        rootItem.nextChildItemIndex = rootItem.nextChildItemIndex + 1

        rootItem.rootFrame:addChild( childItem.textLabel )

        if layout then self:layout() end

        return childItem
    end

    function obj:removeChildItem( )
    end

    function obj:clean()
        obj.rootItems = {}
        obj.scroller:removeall()
        obj.nextRootItemHandle = 1
    end

    function obj:layout()
        for _,item in pairs( self.rootItems or {} ) do
            item:layout()
        end

        self.scroller:layout()
    end

    return obj
end

local test_tree_ctrl = nil
function testTreeCtrl()
    if test_tree_ctrl == nil or toTLWindow( test_tree_ctrl.win ) == nil then
        test_tree_ctrl = createTestTreeCtrl()
    end
    test_tree_ctrl:open()
end

function createTestTreeCtrl()
    local obj = {}

    obj.win = topwindow( 'UI/game_windows/w16_2' )
    button( obj.win, 'fanhui', function() obj.win:SetIsVisible( false ) end )

    local tree = treectrl( obj.win, 'gundong' )

    local handle1 = tree:insertRootItem( _YYTEXT('雨霖铃') )
    tree:insertChildItem( handle1, _YYTEXT('寒蝉凄切,对长亭晚,骤雨初歇.') )
    tree:insertChildItem( handle1, _YYTEXT('都门帐饮无绪,留恋处,兰舟催发.') )
    tree:insertChildItem( handle1, _YYTEXT('执手想看泪眼,竟无语凝噎.') )
    tree:insertChildItem( handle1, _YYTEXT('念去去,千里烟波,暮霭沉沉楚天阔.') )
    tree:insertChildItem( handle1, _YYTEXT('自古多情伤离别,更那堪冷落清秋节!') )
    tree:insertChildItem( handle1, _YYTEXT('今宵酒醒何处,杨柳岸晓风残月.') )
    tree:insertChildItem( handle1, _YYTEXT('此去经年,应是良辰好景虚设.') )
    tree:insertChildItem( handle1, _YYTEXT('便纵有千种风情,更与何人说.') )

    local handle2 = tree:insertRootItem( _YYTEXT('声声慢') )
    tree:insertChildItem( handle2, _YYTEXT('寻寻觅觅,冷冷清清,凄凄惨惨戚戚.') )
    tree:insertChildItem( handle2, _YYTEXT('乍暖还寒时候,最难将息.') )
    tree:insertChildItem( handle2, _YYTEXT('三杯两盏淡酒,怎敌他,晚来风急?') )
    tree:insertChildItem( handle2, _YYTEXT('雁过也,正伤心,却是旧时相识.') )
    tree:insertChildItem( handle2, _YYTEXT('满地黄花堆积,憔悴损,如今有谁堪摘?') )
    tree:insertChildItem( handle2, _YYTEXT('守着窗儿,独自怎生得黑?') )
    tree:insertChildItem( handle2, _YYTEXT('梧桐更兼细雨,到黄昏,点点滴滴.') )
    tree:insertChildItem( handle2, _YYTEXT('这次第,怎一个愁字了得!') )

    local handle3 = tree:insertRootItem( _YYTEXT('念奴娇-赤壁怀古') )
    tree:insertChildItem( handle3, _YYTEXT('大江东去,浪淘尽,千古风流人物.') )
    tree:insertChildItem( handle3, _YYTEXT('故垒西边,人道是,三国周郎赤壁.') )
    tree:insertChildItem( handle3, _YYTEXT('乱石穿空,惊涛拍岸,卷起千堆雪.') )
    tree:insertChildItem( handle3, _YYTEXT('江山如画,一时多少豪杰.') )
    tree:insertChildItem( handle3, _YYTEXT('遥想公瑾当年,小乔初嫁了,雄姿英发.') )
    tree:insertChildItem( handle3, _YYTEXT('羽扇纶巾,谈笑间,樯橹灰飞烟灭.') )
    tree:insertChildItem( handle3, _YYTEXT('故国神游,多情应笑我,早生华发.') )
    tree:insertChildItem( handle3, _YYTEXT('人生如梦,一樽还酹江月.') )

    -- layout
    tree:layout()

    function obj:open()
        self.win:SetIsVisible( true )
        TLWindowManager:SharedTLWindowManager():MoveToTop( self.win )
    end

    return obj
end
