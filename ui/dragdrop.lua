--./ui/dragdrop.lua
-- drop drag stand
function dragdropstandard(pWin, name, flags)
	local ddMC = assert(pWin:GetNode():getChildByName(name), string.format('not found child movieclip %s from %s', name, pWin:GetNode():getInstanceName()))
    local ddWin = TLWindow:createWindow( ddMC, flags )
    pWin:AddChildWindow( ddWin )

    return init_dragdropstandard( ddWin, flags )
end

function init_dragdropstandard( ddWin, flags )
	local dragdrop = {
		node = ddWin:GetNode(),
		movieclip = toMovieClip( ddWin:GetNode() ),
		window = ddWin,
		ondragstart = nil,
		ondragcancel = nil,
		ondrop = nil,
		scale = 1,
	}

    -- draggable
	if bit.band(flags, TL_WINDOW_FLAG_TOUCH_OFF_DROP_DRAG) ~= 0 then
		ddWin:RegisterEvent(TL_EVENT_DROP_DRAG_START, function(helper)
			if dragdrop.ondragstart then
				return dragdrop:ondragstart(helper)
			end
		end)

		ddWin:RegisterEvent(TL_EVENT_DROP_DRAG_CANCEL, function(helper)
			if dragdrop.ondragcancel then
				return dragdrop:ondragcancel(helper)
			end
		end)
	end

    -- droppable
	if bit.band(flags, TL_WINDOW_FLAG_RECEIVE_DROP_DRAG) ~= 0 then
		ddWin:RegisterEvent(TL_EVENT_DROP_DRAG_RECEIVE, function(helper)
			if dragdrop.ondrop then
				return dragdrop:ondrop(helper)
			end
		end)
	end

	return dragdrop
end

function draggable(pWin, name)
	local flags = bit.bor( TL_WINDOW_UNIVARSAL, TL_WINDOW_FLAG_TOUCH_OFF_DROP_DRAG );
	return dragdropstandard(pWin, name, flags)
end

function droppable(pWin, name)
	local flags = bit.bor( TL_WINDOW_UNIVARSAL, TL_WINDOW_FLAG_RECEIVE_DROP_DRAG );
	return dragdropstandard(pWin, name, flags)
end

-- draggable && droppable
function dragdrop(pWin, name)
	return dragdropstandard(pWin, name, TL_WINDOW_DRAG_DROP)
end

--[[ example
local dd = dragdrop(pWin, name)
dd.movieclip:addChild(loadIcon(xx, xxx))
function dd:ondragstart(_, helper)
    helper:AppendShow(loadIcon(xx, xx))
end
function dd:ondragcancel(_, helper)
end
function dd:ondrop(_, helper)
end
--]]
