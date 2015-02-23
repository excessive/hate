local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local sdl = require(current_folder .. "sdl2")
local ffi = require "ffi"
local cpml = require(current_folder .. "cpml")

local graphics = {}

local function validate_shader(shader)
	local int = ffi.new("GLint[1]")
	gl.GetShaderiv(shader, GL.INFO_LOG_LENGTH, int)
	local length = int[0]
	if length <= 0 then
		return
	end
	gl.GetShaderiv(shader, GL.COMPILE_STATUS, int)
	local success = int[0]
	if success == GL.TRUE then
		return
	end
	local buffer = ffi.new("char[?]", length)
	gl.GetShaderInfoLog(shader, length, int, buffer)
	error(ffi.string(buffer))
end

local function load_shader(src, type)
	local shader = gl.CreateShader(type)
	if shader == 0 then
		error("glGetError: " .. tonumber(gl.GetError()))
	end
	local src = ffi.new("char[?]", #src, src)
	local srcs = ffi.new("const char*[1]", src)
	gl.ShaderSource(shader, 1, srcs, nil)
	gl.CompileShader(shader)
	validate_shader(shader)
	return shader
end

-- local vs = load_shader(vs_src, GL.VERTEX_SHADER)
-- local fs = load_shader(fs_src, GL.FRAGMENT_SHADER)
--
-- local prog = gl.CreateProgram()

-- gl.AttachShader(prog, vs)
-- gl.AttachShader(prog, fs)
-- gl.LinkProgram(prog)
-- gl.UseProgram(prog)

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
	local w, h = ffi.new("int[1]"), ffi.new("int[1]")
	sdl.GL_GetDrawableSize(graphics._state.window, w, h)

	return tonumber(w[0]), tonumber(h[0])
end

function graphics.getWidth()
	return select(1, graphics.getDimensions())
end

function graphics.getHeight()
	return select(2, graphics.getDimensions())
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

local function send_uniform(shader, name, data, is_int)
	-- just a number, ez
	-- this should probably just use the *v stuff, so it doesn't need its own codepath.
	if type(data) == "number" then
		local loc = gl.GetUniformLocation(shader, name)
		local send = is_int and gl.Uniform1f or gl.Uniform1i
		send(loc, data)
	end
	-- it's either a vector or matrix type
	-- TODO: Uniform arrays
	if type(data) == "table" then
		if type(data[1]) == "table" then
			-- matrix
			-- we support any matrix between 2x2 and 4x4 as long as it makes sense.
			assert(#data >= 2 and #data <= 4, "Unsupported column size for matrix: " .. #data .. ", must be between 2 and 4.")
			assert(#data[1] == #data[2] == #data[3] == #data[4], "All rows in a matrix must be the same size.")
			assert(#data[1] >= 2 and #data[1] <= 4, "Unsupported row size for matrix: " .. #data[1] .. ", must be between 2 and 4.")
			local mtype = #data == #data[1] and tostring(#data) or tostring(#data) .. "x" .. tostring(#data[1])
			local fn = "UniformMatrix" .. mtype .. "fv"
			gl[fn](loc, count, GL.FALSE, data)
		else
			-- vector
			assert(#data >= 2 and #data <= 4, "Unsupported size for vector type: " .. #data .. ", must be between 2 and 4.")
			local fn = "Uniform" .. tostring(#data) .. "fv"
			gl[fn](loc, count, data)
		end
	end
end

function graphics.push()
	local stack = graphics._state.matrix_stack
	if #stack == 0 then
		table.insert(stack, cpml.mat4())
	else
		table.insert(stack, stack[#stack]:clone())
	end
end

function graphics.pop()
	local stack = graphics._state.matrix_stack
	table.remove(stack)
end

function graphics.translate(x, y)
	local stack = graphics._state.matrix_stack
	stack[#stack] = stack[#stack]:translate(cpml.vec3(x, y, 0))
end

function graphics.rotate(r)
	local stack = graphics._state.matrix_stack
	stack[#stack] = stack[#stack]:rotate(r, cpml.vec3(0, 0, 1))
end

function graphics.scale(x, y)
	stack[#stack] = stack[#stack]:scale(cpml.vec3(x, y, 1))
end

function graphics.origin()
	stack[#stack] = stack[#stack]:identity()
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
