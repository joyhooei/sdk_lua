-- ./utils/entity.lua
require 'utils.signal'

--全局变量
--g_verify_code          = nil
g_userID                = nil -- 当前登录用户ID
g_player                = nil -- 当前玩家
g_pets                  = {}  -- 宠物数据 pet         = hero
g_equs                  = {}

-- 主角属性事件
function listen_me( key, callback ) return signal.listen( '_me_' .. key, callback ) end
function unlisten_me( key, callback ) return signal.unlisten( '_me_' .. key, callback ) end
function fire_me( key, value ) signal.fire( '_me_' .. key, value ) end

g_cdtimes = setmetatable( { update = {} }, {
    __index = function( t, k )
        if not t.update[k] then return g_player[k] or 0 end

        local dt = os.time() - t.update[k]
        return g_player[k] and ( g_player[k] - dt ) or 0
    end,
    __newindex = function()
        CCLuaLog( 'don\'t change g_cdtimes directly' )
    end
})

function listen_cd( attr_name )
    listen_me( attr_name, function()
        g_cdtimes.update[attr_name] = os.time()
    end)
end

