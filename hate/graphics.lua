local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local sdl = require(current_folder .. "sdl2")
local ffi = require "ffi"
local cpml = require(current_folder .. "cpml")

local graphics = {}

local function load_shader(src, type)
	local function validate(shader)
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
	local shader = gl.CreateShader(type)
	if shader == 0 then
		error("glGetError: " .. tonumber(gl.GetError()))
	end
	local src = ffi.new("char[?]", #src, src)
	local srcs = ffi.new("const char*[1]", src)
	gl.ShaderSource(shader, 1, srcs, nil)
	gl.CompileShader(shader)
	validate(shader)
	return {
		handle = shader,
		type = type
	}
end

local function assemble_program(...)
	local shaders = {...}

	local prog = gl.CreateProgram()
	for _, shader in ipairs(shaders) do
		gl.AttachShader(prog, shader.handle)
	end
	gl.LinkProgram(prog)
	gl.UseProgram(prog)

	return {
		handle = prog
	}
end

function graphics.clear(color, depth)
	local w, h = graphics.getDimensions()
	gl.Viewport(0, 0, w, h)

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
	return graphics._wireframe.enable and true or false
end

function graphics.setWireframe(enable)
	graphics._wireframe.enable = enable and true or false
	gl.PolygonMode(GL.FRONT_AND_BACK, enable and GL.LINE or GL.FILL)
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

function graphics.push(which)
	local stack = graphics._state.stack
	assert(#stack < 64, "Stack overflow - your stack is too deep, did you forget to pop?")
	if #stack == 0 then
		table.insert(stack, {
			matrix = cpml.mat4(),
			color = { 255, 255, 255, 255 },
			active_shader = graphics._active_shader,
			wireframe = graphics._wireframe
		})
	else
		local top = stack[#stack]
		local new = {
			matrix = top.matrix:clone(),
			color  = top.color,
			active_shader = top.active_shader,
			wireframe = top.wireframe
		}
		if which == "all" then
			new.color = { top.color[1], top.color[2], top.color[3], top.color[4] }
			new.active_shader = { handle = top.active_shader.handle }
			new.wireframe = { enable = top.wireframe.enable }
		end
		table.insert(stack, new)
	end
	graphics._state.stack_top = stack[#stack]
end

function graphics.pop()
	local stack = graphics._state.stack
	assert(#stack > 1, "Stack underflow - you've popped more than you pushed!")
	table.remove(stack)

	local top = stack[#stack]
	graphics._state.stack_top = top
	graphics.setShader(top.active_shader)
	graphics.setColor(top.color)
	graphics.setWireframe(top.wireframe.enable)
end

function graphics.translate(x, y)
	local top = graphics._state.stack_top
	top.matrix = top.matrix:translate(cpml.vec3(x, y, 0))
end

function graphics.rotate(r)
	assert(type(r) == "number")
	local top = graphics._state.stack_top
	top.matrix = top.matrix:rotate(r, { 0, 0, 1 })
end

function graphics.scale(x, y)
	local top = graphics._state.stack_top
	top.matrix = top.matrix:scale(cpml.vec3(x, y, 1))
end

function graphics.origin()
	local top = graphics._state.stack_top
	top.matrix = top.matrix:identity()
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
		data[(i*2)+2] = x + math.cos(angle) * radius
		data[(i*2)+3] = y + math.sin(angle) * radius
	end

	-- gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)

	local buf = submit_buffer(GL.ARRAY_BUFFER, GL.TRIANGLE_FAN, data, count)
	local vao = ffi.new("GLuint[1]")
	assert(gl.GetError() == GL.NO_ERROR)
	local shader = graphics._active_shader.handle
	local modelview = graphics._state.stack_top.matrix
	local w, h = graphics.getDimensions()
	local projection = cpml.mat4():ortho(0, w, 0, h, -100, 100)
	local mvp = modelview * projection
	local mat_f  = ffi.new("float[?]", 16)
	for i = 1, 16 do
		mat_f[i-1] = modelview[i]
	end
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "HATE_ModelViewMatrix"), 1, false, mat_f)
	for i = 1, 16 do
		mat_f[i-1] = projection[i]
	end
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "HATE_ProjectionMatrix"), 1, false, mat_f)
	for i = 1, 16 do
		mat_f[i-1] = mvp[i]
	end
	gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "HATE_ModelViewProjectionMatrix"), 1, false, mat_f)
	gl.BindBuffer(buf.buffer_type, buf.handle[0])
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, GL.FLOAT, GL.FALSE, 0, ffi.cast("void*", 0))
	gl.DrawArrays(buf.mode, 0, buf.count / 2)
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

-- todo: different depth functions, range, clear depth
function graphics.setDepthTest(enable)
	if enable ~= nil and graphics._state.depth_test ~= enable then
		if enable then
			gl.Enable(GL.DEPTH_TEST)
		else
			gl.Disable(GL.DEPTH_TEST)
		end
	end
end

	local GLSL_VERSION = "#version 120"

	local GLSL_SYNTAX = [[
#define lowp
#define mediump
#define highp
#define number float
#define Image sampler2D
#define extern uniform
#define Texel texture2D
#pragma optionNV(strict on)]]

	local GLSL_UNIFORMS = [[
#define TransformMatrix HATE_ModelViewMatrix
#define ProjectionMatrix HATE_ProjectionMatrix
#define TransformProjectionMatrix HATE_ModelViewProjectionMatrix

#define NormalMatrix gl_NormalMatrix

uniform mat4 HATE_ModelViewMatrix;
uniform mat4 HATE_ProjectionMatrix;
uniform mat4 HATE_ModelViewProjectionMatrix;

//uniform sampler2D _tex0_;
//uniform vec4 love_ScreenSize;]]

	local GLSL_VERTEX = {
		HEADER = [[
#define VERTEX

#define VertexPosition gl_Vertex
#define VertexTexCoord gl_MultiTexCoord0
#define VertexColor gl_Color

#define VaryingTexCoord gl_TexCoord[0]
#define VaryingColor gl_FrontColor

// #if defined(GL_ARB_draw_instanced)
//	#extension GL_ARB_draw_instanced : enable
//	#define love_InstanceID gl_InstanceIDARB
// #else
//	attribute float love_PseudoInstanceID;
//	int love_InstanceID = int(love_PseudoInstanceID);
// #endif
]],

		FOOTER = [[
void main() {
	VaryingTexCoord = VertexTexCoord;
	VaryingColor = VertexColor;
	gl_Position = position(TransformProjectionMatrix, VertexPosition);
}]],
	}

	local GLSL_PIXEL = {
		HEADER = [[
#define PIXEL

#define VaryingTexCoord gl_TexCoord[0]
#define VaryingColor gl_Color

#define love_Canvases gl_FragData]],

		FOOTER = [[
void main() {
	// fix crashing issue in OSX when _tex0_ is unused within effect()
	//float dummy = Texel(_tex0_, vec2(.5)).r;

	// See Shader::checkSetScreenParams in Shader.cpp.
	// exists to fix x/y when using canvases
	//vec2 pixelcoord = vec2(gl_FragCoord.x, (gl_FragCoord.y * love_ScreenSize.z) + love_ScreenSize.w);

	gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	//gl_FragColor = effect(VaryingColor, _tex0_, VaryingTexCoord.st, pixelcoord);
}]],

		FOOTER_MULTI_CANVAS = [[
void main() {
	// fix crashing issue in OSX when _tex0_ is unused within effect()
	float dummy = Texel(_tex0_, vec2(.5)).r;

	// See Shader::checkSetScreenParams in Shader.cpp.
	vec2 pixelcoord = vec2(gl_FragCoord.x, (gl_FragCoord.y * love_ScreenSize.z) + love_ScreenSize.w);

	effects(VaryingColor, _tex0_, VaryingTexCoord.st, pixelcoord);
}]],
	}

local table_concat = table.concat
local function createVertexCode(vertexcode)
	local vertexcodes = {
		GLSL_VERSION,
		GLSL_SYNTAX, GLSL_VERTEX.HEADER, GLSL_UNIFORMS,
		"#line 0",
		vertexcode,
		GLSL_VERTEX.FOOTER,
	}
	return table_concat(vertexcodes, "\n")
end

local function createPixelCode(pixelcode, is_multicanvas)
	local pixelcodes = {
		GLSL_VERSION,
		GLSL_SYNTAX, GLSL_PIXEL.HEADER, GLSL_UNIFORMS,
		"#line 0",
		pixelcode,
		is_multicanvas and GLSL_PIXEL.FOOTER_MULTI_CANVAS or GLSL_PIXEL.FOOTER,
	}
	return table_concat(pixelcodes, "\n")
end

local function isVertexCode(code)
	return code:match("vec4%s+position%s*%(") ~= nil
end

local function isPixelCode(code)
	if code:match("vec4%s+effect%s*%(") then
		return true
	elseif code:match("void%s+effects%s*%(") then
		-- function for rendering to multiple canvases simultaneously
		return true, true
	else
		return false
	end
end

function graphics.newShader(pixelcode, vertexcode)
	local vs
	local fs = load_shader(createPixelCode(pixelcode, false), GL.FRAGMENT_SHADER)
	if vertexcode then
		vs = load_shader(createVertexCode(vertexcode), GL.VERTEX_SHADER)
	end
	if not vertexcode and isVertexCode(pixelcode) then
		vs = load_shader(createVertexCode(pixelcode), GL.VERTEX_SHADER)
	end
	return assemble_program(vs, fs)
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

local default =
[===[
#ifdef VERTEX
vec4 position(mat4 transform_proj, vec4 vertpos) {
	return transform_proj * vertpos;
}
#endif

#ifdef PIXEL
vec4 effect(lowp vec4 vcolor, Image tex, vec2 texcoord, vec2 pixcoord) {
	return Texel(tex, texcoord) * vcolor;
}
#endif
]===]

function graphics.init()
	if graphics._state.config.window.srgb then
		gl.Enable(GL.FRAMEBUFFER_SRGB)
	end
	graphics._state.stack = {}
	graphics._internal_shader = graphics.newShader(default)
	graphics._active_shader = graphics._internal_shader
	graphics._wireframe = {}
	graphics.setWireframe(false)
	graphics.push("all")
end

return graphics
