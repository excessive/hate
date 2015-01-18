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
	graphics._background_color = { r, g, b, a }
	gl.ClearColor(r, g, b, a)
end

function graphics.getColor()
	return graphics._color or { 0, 0, 0, 0 }
end

function graphics.setColor(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4] or 255
	end
	graphics._color = { r, g, b, a }

	-- this should update the default shader with _color
end

function graphics.getDimensions()
	return graphics.getWidth(), graphics.getHeight()
end

function graphics.getWidth()
	-- TODO
end

function graphics.getHeight()
	-- TODO
end

function graphics.isWireframe()
	return graphics._wireframe and true or false
end

function graphics.setWireframe(enable)
	graphics._wireframe = enable and true or false
	gl.PolygonMode(GL.FRONT_AND_BACK, enable and GL_LINE or GL_FILL)
end

function graphics.setStencil(stencilfn)
	if stencilfn then
		-- gl.Enable(GL.STENCIL_TEST)
		-- write to stencil buffer using stencilfn
		-- etc
	else
		-- gl.Disable(GL.STENCIL_TEST)
	end
end

-- should do the same thing as setStencil, but, well, inverted.
function graphics.setInvertedStencil(stencilfn)

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
