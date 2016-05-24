--./utils/table.lua
-- 取最小值
function table.min(t)
    local minv
    local mini
    for i,v in pairs(t) do
        if not minv or v<minv then
            minv = v
            mini = i
        end
    end
    return mini, minv
end

function table.clear(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

-- table.update(t, t1, t2...) 把 t1 t2 等的key复制到t中
function table.update (t,...)
    for i = 1,select('#',...) do
        for k,v in pairs(select(i,...)) do
            t[k] = v
        end
    end
    return t
end

-- 浅拷贝
function table.copy(tab)
    return table.update({}, tab)
end

-- 判断是否空表
function table.isEmpty(tab)
    --[[
    for _,_ in pairs(tab) do
        return false
    end
    return true
    --]]
    return next(tab) == nil
end

-- key变value，value变key
function table.k2v(tab)   --直接转换，慎用
    local ret = {}
    for k,v in pairs(tab or {}) do
        ret[v] = k
    end
    return ret
end

-- 主动触发protobuf的magic method
function table.expand(tab)
    pcall(function()
        return tab.id
    end)
    return tab
end

function table.unproto(tab)
    tab = table.expand(tab)
    return setmetatable(tab, {})
end

function table.hasKey(proto,key)
    local tab = table.expand(proto)
    return rawget(tab,key) ~= nil
end

-- 定义全局空表
table.empty = setmetatable({}, {
    __newindex = function(...)
    end,
    __eq = function(tab1,empty)
        return type(tab1) == "table" and table.isEmpty(tab1) or false
    end
})

function toString(tab, lookup_tab)
    lookup_tab = lookup_tab or {}
    if type(tab) == "string" then
        return string.format("\"%s\"",tab)
    elseif type(tab) == "number" then
        return tostring(tab)
    elseif type(tab) == "table" then
        if lookup_tab[tab]  then
            return lookup_tab[tab]
        end
        lookup_tab[tab] = tostring(tab)
        local con = {}
        for k,v in pairs(tab) do
            table.insert(con,string.format("[%s]=%s",toString(k, lookup_tab),toString(v, lookup_tab)))
        end
        return #con > 0 and "{\n"..table.concat(con,",\n").."\n}" or "{}"
    else
        return tostring(tab)
    end
end

function table.orderIter(tab,cmp)
    --cmp方法比较时用 .key .value 获取table的key ,value
    --默认按key值大小排序
    local i = 0
    local ta = {}
    local cmp = cmp or function(a,b)
        return a.key < b.key
    end
    table.foreach(tab,function(k,v) return table.insert(ta,{key=k,value=v})end)
    table.sort(ta,cmp)
    return function()
        i = i + 1
        if i > #ta then return end
        return ta[i].key,ta[i].value
    end
end

function table.specialSort(tab,cmp)
    local ta = {}
    table.foreach(tab,function(k,v) 
        v.id = k
        table.insert(ta,v) 
        return 
    end)
    table.sort(ta,cmp)
    return ta
end

function table.filter(list, func)
    local selected = {}
    for _,i in ipairs(list) do
        if func(i) then
            table.insert(selected, i)
        end
    end
    return selected
end

function table.find(list, func)
    for _, item in ipairs(list) do
        if func(item) then
            return item
        end
    end
end

function table.index(list, func)
    for idx, item in ipairs(list) do
        if func(item) then
            return idx
        end
    end
end

-- pop最后一个值，table.insert的逆操作
function table.pop(tbl)
    if #tbl>0 then
        local o = tbl[#tbl]
        tbl[#tbl] = nil
        return o
    else
        return nil
    end
end

function table.len(ta)
    local len = 0
    for _,_ in pairs(ta) do
        len = len + 1
    end
    return len
end

function table.zip(t1, t2)
    local r = {}
    for idx, v1 in ipairs(t1) do
        local v2 = t2[idx]
        r[v1] = v2
    end
    return r
end

function table.hasValue(tb, value)
	for _, v in pairs(tb) do
		if v == value then
			return _, true
		end
	end
end

function table.hasKeyWord(tb, value)
	for key, v in pairs(tb) do
		if key == value then
			return v, true
		end
	end

	return false
end

-- declare local variables
--// exportstring( string )
--// returns a "Lua" portable version of the string
local function exportstring( s )
    return string.format("%q", s)
end

--// The Save Function
function table.save(  tbl,filename )
    local charS,charE = "   ","\n"
    local file,err = io.open( filename, "wb" )
    if err then return err end

    -- initiate variables for save procedure
    local tables,lookup = { tbl },{ [tbl] = 1 }
    file:write( "return {"..charE )

    for idx,t in ipairs( tables ) do
        file:write( "-- Table: {"..idx.."}"..charE )
        file:write( "{"..charE )
        local thandled = {}

        for i,v in ipairs( t ) do
            thandled[i] = true
            local stype = type( v )
            -- only handle value
            if stype == "table" then
                if not lookup[v] then
                    table.insert( tables, v )
                    lookup[v] = #tables
                end
                file:write( charS.."{"..lookup[v].."},"..charE )
            elseif stype == "string" then
                file:write(  charS..exportstring( v )..","..charE )
            elseif stype == "number" then
                file:write(  charS..tostring( v )..","..charE )
            end
        end

        for i,v in pairs( t ) do
            -- escape handled values
            if (not thandled[i]) then

                local str = ""
                local stype = type( i )
                -- handle index
                if stype == "table" then
                    if not lookup[i] then
                        table.insert( tables,i )
                        lookup[i] = #tables
                    end
                    str = charS.."[{"..lookup[i].."}]="
                elseif stype == "string" then
                    str = charS.."["..exportstring( i ).."]="
                elseif stype == "number" then
                    str = charS.."["..tostring( i ).."]="
                end

                if str ~= "" then
                    stype = type( v )
                    -- handle value
                    if stype == "table" then
                        if not lookup[v] then
                            table.insert( tables,v )
                            lookup[v] = #tables
                        end
                        file:write( str.."{"..lookup[v].."},"..charE )
                    elseif stype == "string" then
                        file:write( str..exportstring( v )..","..charE )
                    elseif stype == "number" then
                        file:write( str..tostring( v )..","..charE )
                    end
                end
            end
        end
        file:write( "},"..charE )
    end
    file:write( "}" )
    file:close()
end

--// The Load Function
function table.load( sfile )
    local ftables,err = loadfile( sfile )
    if err then return _,err end
    local tables = ftables()
    for idx = 1,#tables do
        local tolinki = {}
        for i,v in pairs( tables[idx] ) do
            if type( v ) == "table" then
                tables[idx][i] = tables[v[1]]
            end
            if type( i ) == "table" and tables[i[1]] then
                table.insert( tolinki,{ i,tables[i[1]] } )
            end
        end
        -- link indices
        for _,v in ipairs( tolinki ) do
            tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
        end
    end
    return tables[1]
end
