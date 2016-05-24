--./utils/signal.lua
-- 实现通用监听模式

require 'utils.table'

local _listeners = {}

signal = {}

function signal.listen( key, callback, order )
    if _listeners[key] == nil then _listeners[key] = {} end

    --table.insert( _listeners[key], callback )
    _listeners[key][callback] = order or 0

    return callback
end

function signal.unlisten( key, callback )
    if not _listeners[key] then return end

    _listeners[key][callback] = nil
end

function signal.fire(key, ...)
    if not _listeners[key] then return end
    for cb, _ in table.orderIter( _listeners[key] or {}, function(a,b)
        return a.value > b.value
    end) do
        cb(...)
    end
end

