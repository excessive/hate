local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local sdl = require(current_folder .. "sdl2")
local ffi = require "ffi"

local graphics = {}

local function validate_shader(shader)
	local int = ffi.new("GLint[1]")
	gl.glGetShaderiv(shader, gl.GL_INFO_LOG_LENGTH, int)
	local length = int[0]
	if length <= 0 then
		return
	end
	gl.glGetShaderiv(shader, gl.GL_COMPILE_STATUS, int)
	local success = int[0]
	if success == gl.GL_TRUE then
		return
	end
	local buffer = ffi.new("char[?]", length)
	gl.glGetShaderInfoLog(shader, length, int, buffer)
	error(ffi.string(buffer))
end

local function load_shader(src, type)
	local shader = gl.glCreateShader(type)
	if shader == 0 then
		error("glGetError: " .. tonumber(gl.glGetError()))
	end
	local src = ffi.new("char[?]", #src, src)
	local srcs = ffi.new("const char*[1]", src)
	gl.glShaderSource(shader, 1, srcs, nil)
	gl.glCompileShader(shader)
	validate_shader(shader)
	return shader
end

-- local vs = load_shader(vs_src, gl.GL_VERTEX_SHADER)
-- local fs = load_shader(fs_src, gl.GL_FRAGMENT_SHADER)
--
-- local prog = gl.glCreateProgram()

-- gl.glAttachShader(prog, vs)
-- gl.glAttachShader(prog, fs)
-- gl.glLinkProgram(prog)
-- gl.glUseProgram(prog)

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
	gl.ClearColor(r / 255, g / 255, b / 255, a / 255)
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

local function elements_for_mode(buffer_type)
	local t = {
		[GL.TRIANGLES] = 3,
		[GL.TRIANGLE_STRIP] = 1,
		[GL.LINES] = 2,
		[GL.POINTS] = 1
	}
	assert(t[buffer_type])
	return t[buffer_type]
end

local function submit_buffer(buffer_type, mode, data, count)
	local handle = ffi.new("GLuint[1]")
	gl.GenBuffers(1, handle)
	ffi.gc(handle, function(h) gl.DeleteBuffers(1, h) end)
	gl.BindBuffer(buffer_type, handle[0])
	gl.BufferData(buffer_type, ffi.sizeof(data), data, GL.STATIC_DRAW)
	return {
		buffer_type = buffer_type,
		count  = count,
		mode   = mode,
		handle = handle
	}
end

function graphics.circle(mode, x, y, radius, segments)
	segments = segments or 32
	local vertices = {}
	local count = (segments+2) * 2
	local data = ffi.new("float[?]", count)

	-- center of fan
	data[0] = x
	data[1] = y

	for i=0, segments do
		local angle = (i / segments) * math.pi * 2
		local px = x + math.cos(angle) * radius
		local py = y + math.sin(angle) * radius

		data[(i*2)+2] = px
		data[(i*2)+3] = py
	end

	local buf = submit_buffer(GL.ARRAY_BUFFER, GL.TRIANGLE_FAN, data, count)
	local vao = ffi.new("GLuint[1]")
	assert(gl.GetError() == GL.NO_ERROR)
	-- gl.GenVertexArrays(1, vao)
	-- gl.BindVertexArray(vao[0])
	gl.BindBuffer(buf.buffer_type, buf.handle[0])
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, GL.FLOAT, GL.FALSE, 0, ffi.cast("void*", 0))
	gl.DrawArrays(buf.mode, 0, buf.count)
	-- gl.DeleteVertexArrays(1, vao)
end

function graphics.present()
	sdl.GL_SwapWindow(graphics._state.window)
end

function graphics.newShader(pixelcode, vertexcode)
	-- TODO
end

function graphics.setShader(shader)
	if shader == nil then
		shader = graphics._internal_shader
	end
	if shader ~= graphics._active_shader then
		graphics._active_shader = shader
		gl.UseProgram(shader._program)
	end
end

function graphics.origin()
	-- TODO
end

function graphics.reset()
	gl.ClearColor(0, 0, 0, 255)
end

return graphics
