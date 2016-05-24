--./utils/purge.lua
require 'utils.signal'

function purge_scene()
    signal.fire( 'SYSTEM_PURGE_SCENE' )

    releaseCommonSHandlers()        -- 移除 common 下的所有 schedule handler
    if stopAllScroller then stopAllScroller() end               -- 停止所有滚动条时钟

    -- 移除所有的 tween 
    TLTweenManager:sharedTLTweenManager():removeAllTween();

    if g_boot_win then g_boot_win.is_valid = false end

    -- 清理所有的窗口
	TLWindowManager:SharedTLWindowManager():DestroyAllModuleWindow();
end

function purge_network()
    -- purge net receiver
    CNetReceiver:SharedNetReceiver():Reset()
    CNetSender:SharedNetSender():CloseSocket( NWTS_CLOSED )
    TLHttpClient:sharedHttpClient():setResetHttpClient()
end

--[[
function purge_textures()
	CCTexFontConfig:sharedTexFontConfig():EnterBackground();
    CCSpriteFrameCache:purgeSharedSpriteFrameCache()
    CCTextureCache:purgeSharedTextureCache()
end
--]]
