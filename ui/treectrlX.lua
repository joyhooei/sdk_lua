require 'ui.controls'

-- style, 风格 
function treectrlX( win, name, style )
    local obj = {}

    -- 设置style 默认值
    style = style or {}
    style.sprite1 = 'UI/game_flash/button048'
    style.sprite2 = 'UI/game_flash/button048'
    style.

    obj.scroller = scrollable( win, name, TL_SCROLL_TYPE_UP_DOWN )

    local root_frame = obj.scroller.frame

    obj.rootItems = {}
    obj.nextRootItemHandle = 1
    function obj:insertRootItem( itemText )
        local item = {}
        item.expand = true

        item.childItems = {}
        item.nextChildItemIndex = 1

        -- 
        item.sprite1 = createFlashResource(style.sprite1) --MCLoader:sharedMCLoader():loadSprite( 'UI_00226_1.png' )
        item.sprite2 = createFlashResource(style.sprite2) -- MCLoader:sharedMCLoader():loadSprite( 'UI_00226_2.png' )
        local size = item.sprite1:getContentSize()

        item.child_offset = size.width

        local width = root_frame.mcBoundingBox.size.width
        local height = size.height
        item.origin_box = CCRect( -width * 0.5, -height * 0.5, width, height )
        item.max_box = CCRect( -width * 0.5, -height * 0.5, width, height )

        item.rootFrame = MCFrame:createWithBox( item.origin_box )
        item.rootWin = TLWindow:createWindow( item.rootFrame )

        -- 
        item.frame = MCFrame:createWithBox( item.origin_box )
        item.rootFrame:addChild( item.frame )

        local layerColor = CCLayerColor:create( ccc4( 0, 0, 0, 128 ), width, height - 2 )
        item.frame:addChild( layerColor )

        layerColor:setPosition( -width * 0.5, -height * 0.5 )

        item.win = TLWindow:createWindow( item.frame )
        item.rootWin:AddChildWindow( item.win )
        init_simple_button( item.win, function()
            item.expand = not item.expand

            -- layout
            self:layout()
        end)

        local x = ( size.width - item.origin_box.size.width ) * 0.5
        local y = 0
        item.sprite1:setPosition( x, y )
        item.sprite2:setPosition( x, y )

        item.frame:addChild( item.sprite1 )
        item.frame:addChild( item.sprite2 )

        local text_width = width - size.width
        local text_height = size.height
        --local textLabel = CCLabelTexFont:labelWithString( '', 18, CCSize( text_width, text_height ) )
        local textLabel = TLLabelRichTex:create( '', 18, CCSize( text_width, text_height ) )
        item.frame:addChild( textLabel )
        textLabel:setPosition( size.width, y )
        textLabel:setAlignment( CCImage.kAlignBottomLeft )
        textLabel:setRichString( '[color=255;234;0]' .. itemText or '' )

        self.scroller:append( item.rootWin )

        function item:layout()
            -- 根据标记显示隐藏对应的 sprite
            self.sprite1:setVisible( not self.expand )
            self.sprite2:setVisible( self.expand )

            -- 重置 root frame 的 bounding box
            if self.expand then
                self.rootFrame.mcBoundingBox.size.height = self.max_box.size.height
                self.rootFrame.mcBoundingBox.origin.y = -self.max_box.size.height * 0.5
            else
                self.rootFrame.mcBoundingBox.size.height = self.origin_box.size.height
                self.rootFrame.mcBoundingBox.origin.y = -self.origin_box.size.height * 0.5
            end
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

        return handle
    end

    function obj:insertChildItem( handle, itemText, layout )
        local rootItem = self.rootItems[handle]
        if rootItem == nil then return end

        local childItem = {}
        local text_width = rootItem.origin_box.size.width
        local text_height = rootItem.origin_box.size.height
        --childItem.textLabel = CCLabelTexFont:labelWithString( '', 16, CCSize( text_width, text_height ) )
        childItem.textLabel = TLLabelRichTex:create( '', 16, CCSize( text_width, text_height ) )
        childItem.textLabel:setAlignment( CCImage.kAlignBottomLeft )

        local y = -rootItem.max_box.size.height
        childItem.textLabel:setPosition( rootItem.child_offset, y )
        childItem.textLabel:setRichString( itemText or '' )
        --childItem.realSize = childItem.textLabel:getRealSize()
        childItem.realSize = childItem.textLabel:getContentSize()

        rootItem.max_box.size.height = rootItem.max_box.size.height + childItem.realSize.height
        rootItem.max_box.origin.y = -rootItem.max_box.size.height * 0.5

        rootItem.childItems[rootItem.nextChildItemIndex] = childItem
        rootItem.nextChildItemIndex = rootItem.nextChildItemIndex + 1

        rootItem.rootFrame:addChild( childItem.textLabel )

        if layout then self:layout() end
    end

    function obj:removeChildItem( )
    end

    function obj:layout()
        for _,item in pairs( self.rootItems or {} ) do
            item:layout()
        end

        self.scroller:layout()
    end

    return obj
end
--[[
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
-]]