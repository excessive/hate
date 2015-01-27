local current_folder = (...):gsub('%.[^%.]+$', '') .. "."

local ffi = require "ffi"
local sdl = require(current_folder .. "sdl2")
local opengl = require(current_folder .. "opengl")

local flags

local hate = {
	_LICENSE = "HATE is distributed under the terms of the MIT license. See LICENSE.md.",
	_URL = "https://github.com/excessive/hate",
	_VERSION_MAJOR = 0,
	_VERSION_MINOR = 0,
	_VERSION_REVISION = 1,
	_VERSION_CODENAME = "Tsubasa",
	_DESCRIPTION = "It's not LÖVE."
}

hate._VERSION = string.format(
	"%d.%d.%d",
	hate._VERSION_MAJOR,
	hate._VERSION_MINOR,
	hate._VERSION_REVISION
)

-- Set a global so that libs like lcore can detect hate.
-- (granted, most things will also have the "hate" global)
FULL_OF_HATE = hate._VERSION

local function handle_events()
	local window = hate.state.window

	local event = ffi.new("SDL_Event[?]", 1)
	sdl.pollEvent(event)
	event = event[0]

	-- No event, we're done here.
	if event.type == 0 then
		return
	end

	local function sym2str(sym)
		-- 0x20-0x7E are ASCII printable characters
		if sym >= 0x20 and sym < 0x7E then
			return string.char(sym)
		end

		local specials = {
			[13] = "return",
			[27] = "escape",
			[8] = "backspace",
			[9] = "tab",
		}

		if specials[sym] then
			return specials[sym]
		end

		print(string.format("Unhandled key %d, returning the key code.", sym))

		return sym
	end

	local handlers = {
		[sdl.QUIT] = function()
			hate.quit()
		end,
		[sdl.TEXTINPUT] = function(event)
			local e = event.text
			local t = ffi.string(e.text)
			hate.textinput(t)
		end,
		[sdl.KEYDOWN] = function(event)
			local e = event.key
			local key = sym2str(e.keysym.sym)
			-- e.repeat conflicts with the repeat keyword.
			hate.keypressed(key, e["repeat"])

			-- escape to quit by default.
			if key == "escape" then
				hate.event.quit()
			end
		end,
		[sdl.KEYUP] = function(event)
			local e = event.key
			local key = sym2str(e.keysym.sym)
			hate.keyreleased(key)
		end,
		[sdl.TEXTEDITING] = function(event)
			local e = event.edit
			-- TODO
		end,
		[sdl.MOUSEMOTION] = function(event) end,
		-- resize, minimize, etc.
		[sdl.WINDOWEVENT] = function(event) end,
		[sdl.MOUSEBUTTONDOWN] = function(event)
			local e = event.button
			print(e.x, e.y)
		end,
		[sdl.MOUSEBUTTONUP] = function(event)
			local e = event.button
			print(e.x, e.y)
		end,
	}

	if handlers[event.type] then
		handlers[event.type](event)
		return
	end

	print(string.format("Unhandled event type: %s", event.type))
end

function hate.getVersion()
	return hate._VERSION_MAJOR, hate._VERSION_MINOR, hate._VERSION_REVISION, hate._VERSION_CODENAME, "HATE"
end

function hate.run()
	-- TODO: remove this.
	local config = hate.config

	--[[
	if hate.math then
		hate.math.setRandomSeed(os.time())

		-- first few randoms aren't good, throw them out.
		for i=1,3 do hate.math.random() end
	end
	--]]

	hate.load(arg)

	if hate.window then
		-- We don't want the first frame's dt to include time taken by hate.load.
		if hate.timer then hate.timer.step() end

		local dt = 0

		while true do
			hate.event.pump()
			if not hate.state.running then
				break
			end

			-- Update dt, as we'll be passing it to update
			if hate.timer then
				hate.timer.step()
				dt = hate.timer.getDelta()
			end

			-- Call update and draw
			if hate.update then hate.update(dt) end -- will pass 0 if hate.timer is disabled

			if hate.window and hate.graphics --[[and hate.window.isCreated()]] then
				hate.graphics.clear()
				hate.graphics.origin()
				if hate.draw then hate.draw() end
				hate.graphics.present()
			end

			if hate.timer then
				if hate.window and config.window.delay then
					if config.window.delay >= 0.001 then
						hate.timer.sleep(config.window.delay)
					end
				elseif hate.window then
					hate.timer.sleep(0.001)
				end
			end
		end

		sdl.GL_MakeCurrent(hate.state.window, nil)
		sdl.GL_DeleteContext(hate.state.gl_context)
		sdl.destroyWindow(hate.state.window)
	end

	hate.quit()
end

function hate.init()
	flags = {
		gl3 = false
	}

	for _, v in ipairs(arg) do
		for k, _ in pairs(flags) do
			if v == "--" .. k then
				flags[k] = true
			end
		end
	end

	local callbacks = {
		"load", "quit", "conf",
		"keypressed", "keyreleased",
		"textinput"
	}

	for _, v in ipairs(callbacks) do
		local __NULL__ = function() end
		hate[v] = __NULL__
	end

	hate.event = {}
	hate.event.pump = handle_events
	hate.event.quit = function()
		hate.state.running = false
	end

	pcall(require, "conf")

	local config = {
		name       = "hate",
		window = {
			width   = 854,
			height  = 480,
			vsync   = true,
			delay   = 0.001
		},
		filesystem = true,
		timer      = true,
		graphics   = {
			-- TODO: debug context + multiple attempts at creating contexts
			debug   = true,
			gl      = {
				{ 3, 3 },
				{ 2, 1 }
			}
		}
	}

	hate.conf(config)
	hate.config = config

	hate.state = {}
	hate.state.running = true

	sdl.init(sdl.INIT_EVERYTHING)

	if config.timer then
		hate.timer = require(current_folder .. "timer")
		hate.timer.init()
	end

	if config.filesystem then
		hate.filesystem = require(current_folder .. "filesystem")
		hate.filesystem.init(arg[0], hate.config.name)
	end

	if config.window then
		-- FIXME
		if flags.gl3 then
			sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3)
			sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 3)
			sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, sdl.GL_CONTEXT_PROFILE_CORE)
		end
		sdl.GL_SetAttribute(sdl.GL_CONTEXT_FLAGS, sdl.GL_CONTEXT_DEBUG_FLAG)

		local window_flags = tonumber(sdl.WINDOW_OPENGL)

		if config.window.resizable then
			window_flags = bit.bor(window_flags, tonumber(sdl.WINDOW_RESIZABLE))
		end

		if config.window.vsync then
			window_flags = bit.bor(window_flags, tonumber(sdl.RENDERER_PRESENTVSYNC))
		end

		local window = sdl.createWindow(hate.config.name,
			sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED,
			hate.config.window.width, hate.config.window.height,
			window_flags
		)
		local ctx = sdl.GL_CreateContext(window)

		assert(window)
		assert(ctx)

		sdl.GL_MakeCurrent(window, ctx)

		opengl.loader = function(fn)
			local ptr = sdl.GL_GetProcAddress(fn)
			if flags.gl_debug then
				print(string.format("Loaded GL function: %s (%s)", fn, tostring(ptr)))
			end
			return ptr
		end
		opengl:import()

		local version = ffi.string(gl.GetString(GL.VERSION))
		local renderer = ffi.string(gl.GetString(GL.RENDERER))

		if true then
			local gl_debug_source_string = {
				[GL.DEBUG_SOURCE_API_ARB] = "API",
				[GL.DEBUG_SOURCE_WINDOW_SYSTEM_ARB] = "WINDOW_SYSTEM",
				[GL.DEBUG_SOURCE_SHADER_COMPILER_ARB] = "SHADER_COMPILER",
				[GL.DEBUG_SOURCE_THIRD_PARTY_ARB] = "THIRD_PARTY",
				[GL.DEBUG_SOURCE_APPLICATION_ARB] = "APPLICATION",
				[GL.DEBUG_SOURCE_OTHER_ARB] = "OTHER"
			}

			local gl_debug_type_string = {
				[GL.DEBUG_TYPE_ERROR_ARB] = "ERROR",
				[GL.DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB] = "DEPRECATED_BEHAVIOR",
				[GL.DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB] = "UNDEFINED_BEHAVIOR",
				[GL.DEBUG_TYPE_PORTABILITY_ARB] = "PORTABILITY",
				[GL.DEBUG_TYPE_PERFORMANCE_ARB] = "PERFORMANCE",
				[GL.DEBUG_TYPE_OTHER_ARB] = "OTHER"
			}

			local gl_debug_severity_string = {
				[GL.DEBUG_SEVERITY_HIGH_ARB] = "HIGH",
				[GL.DEBUG_SEVERITY_MEDIUM_ARB] = "MEDIUM",
				[GL.DEBUG_SEVERITY_LOW_ARB] = "LOW"
			}

			if (gl.DebugMessageCallbackARB) then
				local debug_data = ffi.new("void *")

				gl.DebugMessageCallbackARB(function(source, type, id, severity, length, message, userParam)
					print(string.format("GL DEBUG source: %s type: %s id: %s severity: %s message: %q",
					gl_debug_source_string[source],
					gl_debug_type_string[type],
					tonumber(id),
					gl_debug_severity_string[severity],
					ffi.string(message)))
				end, debug_data)
			end
		end

		if flags.gl_debug then
			print(string.format("OpenGL %s on %s", version, renderer))
		end

		hate.state.window = window
		hate.state.gl_context = ctx

		hate.graphics = require(current_folder .. "graphics")
		hate.graphics._state = hate.state

		-- TODO
		hate.window = {}
	end

	local main, msg = pcall(function() require "main" end)

	if msg then
		print(msg)
	end

	hate.run()

	return 0
end

return hate
