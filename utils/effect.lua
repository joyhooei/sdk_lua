--./utils/effect.lua
require 'utils.signal'

all_playing_effects = {}

local nextEffectHandle = 0
local function getNextEffectHandle()
    nextEffectHandle = nextEffectHandle + 1
    return nextEffectHandle;
end

local particleMath = 'particle/'    -- 粒子特效的前缀

-- 播放粒子特效
function playParticleEffect_SE( seInfo, position, parentNode, scaleX, zOrder, cb, rmcb )
    local parent_node = parentNode or all_scene_layers[layer_type_ui]

    local node = CCNode:create()
    node:setPosition( position.x, position.y )
    parent_node:addChild( node, zOrder or 1 )

    local res = seInfo.resourceId:sub( particleMath:len() + 1 ) -- 获得粒子的名称
	local loop = (seInfo.loop == 0 and 1) or seInfo.loop -- 对与循环来说, 一直都是0 与 1 次循环是一样的 
    local par = ParticleSystemManager:sharedParticleSystemManager():createWithNameLua( node, 0, 0, res, loop, seInfo.schedule_type ~= 'PAUSE' and true or false );
    par:setScaleX( seInfo.scaleX * scaleX )
    par:setScaleY( seInfo.scaleY )

    local handle = getNextEffectHandle()
    all_playing_effects[handle] = { node = node, rmcb = rmcb }

    par:registerPlayEndCallbackHandler( function()
        if cb then cb() end
        stopEffect( handle )
    end)

    return handle, par
end

-- 播放动画帧特效
function playFrameEffect_SE( seInfo, position, parentNode, scaleX, zOrder, cb, rmcb )
    if seInfo.resourceId == 0 then return nil end

    local mcEffect = TLModel:createWithName( seInfo.resourceId, true )
    if mcEffect == nil then return CCLuaLog( 'can not load effect : ' .. tostring( seInfo.resourceId ) ) end

    local parent_node = parentNode or all_scene_layers[layer_type_ui]

    local node = CCNode:create()
    node:setPosition( position.x, position.y )  
    parent_node:addChild( node, zOrder or 1 )

    mcEffect:setScaleX( seInfo.scaleX * scaleX)
    mcEffect:setScaleY( seInfo.scaleY )
    node:addChild( mcEffect )
    
    local handle = getNextEffectHandle()
    all_playing_effects[handle] = { node = node, rmcb = rmcb }

    mcEffect:RegisterPlayEndCallbackHandler( function()
        if cb then cb() end
        stopEffect( handle )
    end)
    mcEffect:play( 0, -1, seInfo.loop )

    return handle, mcEffect
end

--- 播放特效
-- @param setInfo 例子 {resourceId='60016/60016_2', scaleX=1, scaleY=1, loop=0}
-- @param position 例子 {x=100, y=100}
-- @param parentNode 粒子特效的父节点
-- @param scaleX X缩放, 因为scaleX 经常会用到, 因此单独提出来(比如对特效进行镜像)
-- @param zOrder 显示层次
-- @param cb     特效结束时的回调函数
function playEffect_SE( seInfo, position, parentNode, scaleX, zOrder, cb, rmcb )
    -- 播放粒子特效
    if seInfo.resourceId:sub( 1, particleMath:len() ) == particleMath then return playParticleEffect_SE( seInfo, position, parentNode, scaleX, zOrder, cb, rmcb ) end

    -- 播放帧特效
    return playFrameEffect_SE( seInfo, position, parentNode, scaleX, zOrder, cb, rmcb )
end

function playEffectOnce( effect_name, parent_node, call_back_func )
    return playEffect_SE( { resourceId = effect_name, loop = 0, scaleX = 1, scaleY = 1 }, { x = 0, y = 0 }, parent_node, 1, 1, call_back_func )
end

function playEffectCircle( effect_name, parent_node, call_back_func )
    return playEffect_SE( { resourceId = effect_name, loop = -1, scaleX = 1, scaleY = 1 }, { x = 0, y = 0 }, parent_node, 1, 1, call_back_func )
end

function stopEffect( handle )
    local effect_info = all_playing_effects[handle]
    if not effect_info then return end

    all_playing_effects[handle] = nil

    if effect_info.rmcb then effect_info.rmcb() end
    if toCCNode( effect_info.node ) then effect_info.node:removeFromParentAndCleanup( true ) end
end

signal.listen( 'SYSTEM_PURGE_SCENE', function()
    all_playing_effects = {}
end)

