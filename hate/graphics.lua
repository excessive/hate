local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local sdl = require(current_folder .. "sdl2")

local graphics = {}

function graphics.clear(color, depth)
	local mask = 0
	if color == nil or color then
		mask = bit.bor(mask, tonumber(GL.COLOR_BUFFER_BIT))
	end
	if depth then
		mask = bit.bor(mask, tonumber(GL.DEPTH_BUFFER_BIT))
	end
	gl.Clear(mask)
end

function graphics.getBackgroundColor()
	return graphics._background_color or { 0, 0, 0, 0 }
end

function graphics.setBackgroundColor(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4] or 255
	end
	gl.ClearColor(r, g, b, a)
end

function graphics.present()
	sdl.GL_SwapWindow(graphics._state.window)
end

function graphics.origin()
	-- TODO
end

function graphics.reset()
	gl.ClearColor(0, 0, 0, 255)
end

return graphics
