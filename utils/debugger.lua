--./utils/debugger.lua

--HOOK_FILE = nil
--HOOK_LINE = 0
HOOK_FILE = nil
HOOK_LINE = 0

local log
if CCLuaLog then
    log = CCLuaLog
else
    log = print
end
pretty = require 'utils.pretty'
function pdump(name, t)
    log(name)
    local res = pretty.write(t)
    log(res)
end

function pdumpFile(fileName, t)
	local f = io.open(fileName, "wb+")
    if f == nil then return end
	local res = pretty.write(t)
    f:write(res)
    f:close()
    f = nil
end

function dump_point(msg, p)
    log(string.format('%s: {x=%f, y=%f}', msg, p.x, p.y))
end

function dump_rect(msg, r)
    log(string.format('%s: {x=%f, y=%f, width=%f, height=%f}', msg, r.origin.x, r.origin.y, r.size.width, r.size.height))
end

function callhook (event, line)	
	s = debug.getinfo(3, "Sl");	
	if s == nil or s.source ~= HOOK_FILE or s.currentline ~= HOOK_LINE then
		return;
	end
		
	prefix = "[" .. HOOK_FILE .. ":" .. HOOK_LINE .. "] "
	CCLuaLog(prefix .. "stack begin")
	for i=3,20 do
		s = debug.getinfo(i, "Sl");
		if s == nil then
			break;
		end
		CCLuaLog(prefix .. s.source .. " :" .. s.currentline)
	end
	CCLuaLog(prefix .. "stack end")
end

if HOOK_FILE ~= nil and HOOK_LINE ~= 0 then
	debug.sethook(callhook, "c")
end

function profilerFunction(prefix)
	local startProfiler = false

	if prefix == nil then
		debug.sethook()
		return
	end
	
	local lastEvent = "return"
	local lastTick
	function profilerCallback(event, line)
		if startProfiler == false then
			return
		end

		if event == "call" then
			if lastEvent == "return" then
				startProfilerCallback()
				lastEvent = "call"
			else
				CCLuaLog("profiler warn")
			end
		elseif event == "return" then
			if lastEvent == "call" then
				endProfilerCallback()
				lastEvent = "return"
			else
				CCLuaLog("profiler warn")
			end
		elseif event == "tail call" then
		elseif event == "line" then
		elseif event == "count" then
		end
	end

	function startProfilerCallback(event, line)		
		lastTick = os.clock()

		CCLuaLog("")
		CCLuaLog("[" .. prefix .. "][startProfilerCallback] start " .. "cost ")
		local s = debug.getinfo(3, "Sl");	
		for i=3,20 do
			s = debug.getinfo(i, "Sl");
			if s == nil then
				break;
			end
			CCLuaLog("" .. s.source .. " :" .. s.currentline)
		end
		CCLuaLog("[" .. prefix .. "][startProfilerCallback] end")
		CCLuaLog("")
	end

	function endProfilerCallback(event, line)
		CCLuaLog("")
		CCLuaLog("[" .. prefix .. "][endProfilerCallback] start " .. "cost " .. (os.clock() - lastTick))
		local s = debug.getinfo(3, "Sl");	
		for i=3,20 do
			s = debug.getinfo(i, "Sl");
			if s == nil then
				break;
			end
			CCLuaLog("" .. s.source .. " :" .. s.currentline)
		end
		CCLuaLog("[" .. prefix .. "][endProfilerCallback] end")
		CCLuaLog("")
	end

	debug.sethook(profilerCallback, "cr")
	startProfiler = true
end
