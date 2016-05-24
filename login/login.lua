-- ./login/login.lua
require 'utils.common'
require 'win.main'

---------------------------------------------------------------------------------------------------------------------------
-- 修改主角的名字 ---------------------------------------------------------------------------------------------------------
-- @ see gamecommon.actor_name_module
--[=[
local actor_name_window = nil
function openActorNameWindow( feature_code )
    destroyBootWin()

    ---- IOS 在这里才播放 mp4，这是为了避免被 sdk 的初始化界面挡住
    --if getPlatform() == 'ios' then g_device_obj:playCGMp4() end

    -- 因为我们的假战斗消耗的内存比较多，所以如果当前可用内存少于100m的话，就直接跳过
    --[[
    if GameSettings.skip_cg_fight or tonumber( getAvailMemory() ) < 100 then
        set_music( 'music/jingle_title.mp3', true )
        if not actor_name_window or not toTLWindow( actor_name_window.win ) then actor_name_window = createActorNameWindow() end
        actor_name_window:open( feature_code )
    else
        playStoryFight( '1first', function()
            removeUnusedTextures( true )

            pause_music()

            playCG( '60721/60721_2', nil, false, function()
                resume_music()
                playCG( '60721/60721_1', 'music/60721_music1.mp3', true, function()
                    set_music( 'music/jingle_title.mp3', true )
                    if not actor_name_window or not toTLWindow( actor_name_window.win ) then actor_name_window = createActorNameWindow() end
                    actor_name_window:open( feature_code )
                end)
            end)
        end)
    end
    --]]
end

function openChanegeActorNameWindow( send_tbl, feature_code )
    destroyBootWin()

    set_music( 'music/jingle_title.mp3', true )
    if not actor_name_window or not toTLWindow( actor_name_window.win ) then actor_name_window = createChangeActorNameWindow( send_tbl ) end
    actor_name_window:open( feature_code )
end
--]=]

local cg_window, cg_mc = nil, nil
function playCG( mcName, sound, can_skip, call_back_func )
    if toTLWindow( cg_window ) then
        cg_mc:removeFromParentAndCleanup( true )
        TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( cg_window )
    end

    -- 
    if sound then set_music( sound ) end

    cg_window, cg_mc = topwindow( 'NUI/ngame_windows/l3_1', nil, all_scene_layers[layer_type_fight_ui], 100, 'cartoon_window' )
    cg_window:SetIsVisible( true )
    TLWindowManager:SharedTLWindowManager():MoveToTop( cg_window )
    TLWindowManager:SharedTLWindowManager():SetModalWindow( cg_window, true )

    local function __clear__()
        if toTLWindow( cg_window ) then
            cg_mc:removeFromParentAndCleanup( true )
            TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( cg_window )
        end
    end
    addPurgeSceneCallBackFunc( __clear__, true )

    local close_flag = false
    local function __close__()
        if close_flag then return end
        close_flag = true

        schedule_once( function()
            __clear__()
            if call_back_func then call_back_func() end
        end)
    end

    if can_skip then
        local mc_skip = MCLoader:sharedMCLoader():loadSpriteAsync( 'tiaoguo.png' )
        cg_mc:getChildByName( 'tiaoguo' ):addChild( mc_skip )
        anim_button( cg_window, 'tiaoguo', __close__, mc_skip )
    end

    local temp_mc = createMovieClipWithName( mcName )
    temp_mc:setResetKeyframe( true )
    cg_mc:getChildByName( 'wenben2' ):addChild( temp_mc )

    temp_mc:RegisterPlayEndCallbackHandler( __close__ )
    temp_mc:play( 0, -1 )
end

--[[
function destroyActorNameWindow()
    if actor_name_window and toTLWindow( actor_name_window.win ) then
        TLWindowManager:SharedTLWindowManager():RemoveModuleWindow( actor_name_window.win )
    end
    actor_name_window = nil
end

function createActorNameWindow()
    local win, mc = topwindow( 'lollogin/UI/login_parts/parts3_3' )
    local obj = { win = win }
    local max_input_limit = 14
    local nameinput = text_input( win, 'mingzi', nil, nil, 28, TL_RICH_STRING_FLAG_ONE_LINE )
    nameinput:setAlignment( CCImage.kAlignLeft )
    nameinput:setMaxLength( max_input_limit )
    nameinput:setInputMode( TL_INPUT_TEXT_MODEL_CHINAANDENGLISH_ONLY )

    local winSize = getDeviceScreenLogicSize()
    local node_gray = CCLayerColor:create( ccc4( 0, 0, 0, 200 ), winSize.width, winSize.height )
    node_gray:setPosition( -winSize.width * 0.5, -winSize.height * 0.5 )
    mc:getChildByName( 'menghei' ):addChild( node_gray, -100 )

    -- 
    local current_sex = 1
    local current_school = 1
    local randomNames = {}
    local function setDefaultRandomNames()
        if #randomNames == 0 then
            registerNetMsg( NetMsgID.RANDOM_ACTOR_NAME, 'poem.RandomNameRequest', 'poem.RandomNameResponse', nil, { lock_name = 'random_actor_name' } )
            sendNetMsg( NetMsgID.RANDOM_ACTOR_NAME, { sex = current_sex }, function( recv_tbl )
                randomNames = #recv_tbl.names > 0 and recv_tbl.names or recv_tbl.namefemales
                nameinput:setinput( table.pop( randomNames ) )
            end)
        else  
            nameinput:setinput( table.pop( randomNames ) )
        end
    end

    local mc_btn_node_random = MCLoader:sharedMCLoader():loadSprite( 'word_005_1x.png' )
    mc:getChildByName( 'anniu1' ):addChild( mc_btn_node_random )
    anim_button( win, 'anniu1', function()
        setDefaultRandomNames()
    end, mc_btn_node_random )

    local mc_btn_node_confirm = createMovieClipWithName( 'lollogin/UI/login_button/button100_1' )
    mc:getChildByName( 'anniu2' ):addChild( mc_btn_node_confirm )
    local confirm_label = init_label( mc_btn_node_confirm:getChildByName( 'wenben' ), 28, CCImage.kAlignCenter )
    confirm_label:set_rich_string( '[sprite:fileName="word/Nword_0001_2.png"]' )
    anim_button( win, 'anniu2', function()
        local nameplayer = nameinput:getinput()
        local icon_id = C_INITPLAYER[current_school].bodyID

        registerNetMsg( NetMsgID.NEW_ACTOR, 'poem.CreateRoleRequest', 'poem.CreateRoleResponse', nil, { lock_name = 'NEW_ACTOR' } )
        sendNetMsg( NetMsgID.NEW_ACTOR,{ name = nameplayer, sex = current_sex, school = current_school, iconID = icon_id }, function( ret_tbl )
            if ret_tbl.roles ~= nil and ret_tbl.roleId ~= nil then
                schedule_once( function()
                    destroyActorNameWindow()
                    destroyBootWin()
                    schedule_frames( 3, function() removeUnusedTextures( true ) end )
                end)
            end

            enter_with_current_role( ret_tbl.roleId, obj.feature_code )
        end)
    end,mc_btn_node_confirm)

    function obj:open( feature_code )
        win:SetIsVisible( true )
        self.feature_code = feature_code

        setDefaultRandomNames()

        playTopwinOpenAnim(mc, 'SCALE')
    end

    return obj
end

function createChangeActorNameWindow( send_tbl )
    local win, mc = topwindow( 'lollogin/UI/login_parts/parts3_3' )
    local obj = { win = win }
    local max_input_limit = 14
    local nameinput = text_input( win, 'mingzi', nil, nil, 28, TL_RICH_STRING_FLAG_ONE_LINE )
    nameinput:setAlignment( CCImage.kAlignLeft )
    nameinput:setMaxLength( max_input_limit )
    nameinput:setInputMode( TL_INPUT_TEXT_MODEL_CHINAANDENGLISH_ONLY )

    local winSize = getDeviceScreenLogicSize()
    local node_gray = CCLayerColor:create( ccc4( 0, 0, 0, 200 ), winSize.width, winSize.height )
    node_gray:setPosition( -winSize.width * 0.5, -winSize.height * 0.5 )
    mc:getChildByName( 'menghei' ):addChild( node_gray, -100 )

    -- 
    local current_sex = 1
    local current_school = 1
    local randomNames = {}
    local function setDefaultRandomNames()
        if #randomNames == 0 then
            registerNetMsg( NetMsgID.RANDOM_ACTOR_NAME, 'poem.RandomNameRequest', 'poem.RandomNameResponse', nil, { lock_name = 'random_actor_name' } )
            sendNetMsg( NetMsgID.RANDOM_ACTOR_NAME, { sex = current_sex }, function( recv_tbl )
                randomNames = #recv_tbl.names > 0 and recv_tbl.names or recv_tbl.namefemales
                nameinput:setinput( table.pop( randomNames ) )
            end)
        else  
            nameinput:setinput( table.pop( randomNames ) )
        end
    end

    local mc_btn_node_random = MCLoader:sharedMCLoader():loadSprite( 'word_005_1x.png' )
    mc:getChildByName( 'anniu1' ):addChild( mc_btn_node_random )
    anim_button( win, 'anniu1', function()
        setDefaultRandomNames()
    end, mc_btn_node_random )

    local mc_btn_node_confirm = createMovieClipWithName( 'lollogin/UI/login_button/button100_1' )
    mc:getChildByName( 'anniu2' ):addChild( mc_btn_node_confirm )
    local confirm_label = init_label( mc_btn_node_confirm:getChildByName( 'wenben' ), 28, CCImage.kAlignCenter )
    confirm_label:set_rich_string( '[sprite:fileName="word/Nword_0001_2.png"]' )
    anim_button( win, 'anniu2', function()
        local nameplayer = nameinput:getinput()
        local icon_id = C_INITPLAYER[current_school].bodyID

        registerNetMsg( NetMsgID.ALTER_ACTOR_NAME, 'poem.AlterNameRequest', nil, nil, { lock_name = 'ALTER_ACTOR_NAME' } )
        local _send_tbl_ = {
            userID = send_tbl.userID,
            verify_code = send_tbl.verify_code,
            entityID = send_tbl.entityID,
            name = nameplayer,
        }
        sendNetMsg( NetMsgID.ALTER_ACTOR_NAME, _send_tbl_, function()-- ret_tbl )
            schedule_once( function()
                destroyActorNameWindow()
                destroyBootWin()
                schedule_frames( 3, function() removeUnusedTextures( true ) end )
            end)
            enter_with_current_role( send_tbl.entityID, obj.feature_code )
        end)
    end,mc_btn_node_confirm)

    function obj:open( feature_code )
        win:SetIsVisible( true )
        self.feature_code = feature_code

        setDefaultRandomNames()

        playTopwinOpenAnim(mc, 'SCALE')
    end

    return obj
end
--]]
---------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------
-- 进入场景
function enter_with_current_role( sel_role_id, feature_code )
    g_role_id = sel_role_id

    -- 打开进度条，进度条跑完后，才打开主界面
    local welcome_loading = nil
    welcome_loading = (require 'gamecommon.welcome_loading').new( function()
        welcome_loading = nil
        -- 切换场景背景音乐
        set_music( 'music/BM_Field_Master.mp3', true )

        ---- 第一次剧情引导，直接进入冒险界面
        --local doForceGuide, guideType = needForceGuideOfFirstStory( 100111, false )
        --if doForceGuide then
        --    TLWindowManager:SharedTLWindowManager():lockScreen( 'FIRST_ENTER_SCENE' )
        --    sendNetMsg( NetMsgID.STAR_PACKS_INFO, nil, function( rsp ) checkWorldJouneryStarRewardRecvAble() end )
        --    signal.fire( 'FIRST_ENTER_SCENE' )
        --    sendNetMsg( NetMsgID.GUIDE_TYPE_END, { guide_type = '11' } )
        --    return openWorldJouneryMapWin( { nowTarget = nil, openCallBack = function()
        --        TLWindowManager:SharedTLWindowManager():unlockScreen( 'FIRST_ENTER_SCENE' )
        --        doNewPlayerForceGuide( guideType )
        --    end })
        --end



        --require 'win.WorldJounery.utils'
        --if not checkSectionPassed(100211) then
        --    return openWorldJouneryMapWin( { nowTarget = nil, openCallBack = function()
        --        if checkSectionExisted( 100111 ) then
        --            local doForceGuide, guideType = needForceGuide()
        --            if doForceGuide then
        --                doNewPlayerForceGuide( guideType )
        --            else
        --                openNoticeWin( function() checkOffLineBPChange() end )
        --            end
        --        end
        --    end })
        --end

        -- 正常进入
        -- backToHomePage()
        require 'win.welcome.welcome_module'
        openWelcomeModule()
    end)

    -- 清理登录资源
    schedule_once( function()
        destroyBootWin()

        schedule_frames( 5, function() removeUnusedTextures( true ) end )
    end)

    signal.fire( 'SYSTEM_ENTER_SCENE_BEFORE' )

    -- 发送进入场景消息
    registerNetMsg( NetMsgID.ENTER_SCENE, 'poem.EnterRequest', 'poem.EnterResponse' )
    sendNetMsg( NetMsgID.ENTER_SCENE, { entityID = sel_role_id, featureCode = feature_code, clientVersion = tostring( game_version ), deviceInfo = g_device_obj:getDeviceInfo() }, function( recv_tbl )
        g_cur_time = recv_tbl.time       -- 全局时间初始化
        g_enter_response = recv_tbl
        g_campaign_sequence = recv_tbl.campaign_sequence

        signal.fire( 'SYSTEM_ENTER_SCENE_AFTER' )
    end)
end

function enter_with_server_id( server_id )
    -- if true then return enter_with_current_role() end

    TLWindowManager:SharedTLWindowManager():lockScreen( 'NetMsgID.ENTER_REGION' )
    registerHTTPNetMsg( NetMsgID.ENTER_REGION, 'poem.HTTPChooseRegionRequest', 'poem.HTTPChooseRegionResponse' )
    local send_tbl = { regionID = server_id }
    sendHTTPNetMsg( NetMsgID.ENTER_REGION, send_tbl, function( recv_tbl )
        TLWindowManager:SharedTLWindowManager():unlockScreen( 'NetMsgID.ENTER_REGION' )
        -- local verify_code = recv_tbl.verify_code
        -- local entityID    = recv_tbl.roleID

        TLWindowManager:SharedTLWindowManager():lockScreen( 'try_connect_server' )
        try_connect_server( recv_tbl.world.ip, recv_tbl.world.port, function( conn )
            TLWindowManager:SharedTLWindowManager():unlockScreen( 'try_connect_server' )
            registerNetMsg( NetMsgID.LOGIN_WORLD, 'poem.LoginWorldRequest', 'poem.LoginWorldResponse', nil, { lock_name = 'LOGIN_WORLD' } )
            local _send_tbl_ = { userID = g_user_id, verify_code = g_verify_code, }-- entityID = entityID }
            sendNetMsg( NetMsgID.LOGIN_WORLD, _send_tbl_, function( ret_tbl )
                -- 登陆到游戏内时保存一次服务器id
                local server_name = getServerNameByServerID( server_id )
                local last_server_id = PlayerConfig.getLastLoginServerID()
                local last_server_name = getServerNameByServerID( last_server_id )

                PlayerConfig.setLastLoginServerID( server_id or 0 )
                PlayerConfig.setLastLoginServerName( server_name or '' )
                PlayerConfig.setLastLoginServerID2( last_server_id or 0 )
                PlayerConfig.setLastLoginServerName2( last_server_name or '' )

                PlayerConfig.flush()

                if ( not table.hasKey(ret_tbl, 'roles' )) or #(ret_tbl.roles or {}) == 0 then
                    --判断是否是新号
                    require 'common.pop_window_manager'
                    openModulePopWindow( 'gamecommon.actor_name_module' )
                elseif ret_tbl.need_rename then
                    -- TODO
                    --判断是否需要改名
                    _send_tbl_.entityID = ret_tbl.roles[1].id
                    openChanegeActorNameWindow( _send_tbl_ )
                else
                    -- 直接进入
                    enter_with_current_role( ret_tbl.roles[1].id, nil )
                end

                -- 进行心跳推送
                -- self:sendHeartBeatMessage()

            end )
        end )
    end,
    function()
        TLWindowManager:SharedTLWindowManager():unlockScreen( 'NetMsgID.ENTER_REGION' )
    end )
end
