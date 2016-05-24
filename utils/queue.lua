--queue.lua
require 'utils.class'

queue = class( 'Queue' )
function queue:ctor(list)
    self.element = list or {}
end

function queue:clear()
    self.element = {}
end

function queue:push( obj )
    self:pop( obj )             -- 确保是唯一的
    table.insert(self.element, obj)
end

function queue:pop( obj )
    for i, v in ipairs( self.element or {} ) do
        if v == obj then
            table.remove(self.element, i)
            break
        end
    end
end

function queue:popTop()
    if #self.element <= 0 then
        return nil
    end
    return table.remove(self.element, 1)
end

function queue:insert( index, obj )
    if index > #self.element or index <= 0 then return self:push( obj ) end
    table.insert(self.element, index, obj)
end

function queue:remove( index)
    return table.remove(self.element, index)
end

function queue:getAt( index )
    return self.element[index]
end

function queue:getElementCount()
    return #self.element
end

function queue:dump()
    CCLuaLog( 'queue dump:' )
    CCLuaLog( '----------------------------------------------------------------------' )
    for i,v in ipairs( self.element or {} ) do
        pdump( 'queue i = ' .. i, v )
    end
    CCLuaLog( '----------------------------------------------------------------------' )
end
