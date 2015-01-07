local current_folder = (...):gsub('%.[^%.]+$', '') .. "."

local ffi = require "ffi"
local sdl = require(current_folder .. "sdl2")
local opengl = require(current_folder .. "opengl")

local flags

local hate = {}

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
			local e = e.edit
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

function hate.run()
	local config = hate.config

	hate.load(arg)

	if config.window then
		local window = hate.state.window
		local ctx = hate.state.gl_context

		local start = sdl.getTicks()
		local previous = start / 1000
		while hate.state.running do
			hate.timer.step()

			hate.update(hate.timer.getDelta())

			if config.window then
				gl.ClearColor(255, 0, 255, 255)
				gl.Clear(bit.bor(tonumber(GL.COLOR_BUFFER_BIT), tonumber(GL.DEPTH_BUFFER_BIT)))

				hate.draw()

				sdl.GL_SwapWindow(window)
			end

			if config.timer then
				if config.window and config.window.delay then
					if config.window.delay >= 0.001 then
						hate.timer.sleep(config.window.delay)
					end
				elseif config.window then
					hate.timer.sleep(0.001)
				end
			end

			-- print(hate.timer.getFPS())

			hate.event.pump()
		end

		sdl.GL_MakeCurrent(window, nil)
		sdl.GL_DeleteContext(ctx)
		sdl.destroyWindow(window)
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

	pcall(function() require "conf" end)

	local config = {
		name       = "hate",
		window = {
			width   = 854,
			height  = 480,
			vsync   = true,
			delay   = 0.001
		},
		filesystem = true,
		timer      = true
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
		if flags.gl3 then
			sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3)
			sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 3)
			sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, sdl.GL_CONTEXT_PROFILE_CORE)
		end

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

		if flags.gl_debug then
			print(string.format("OpenGL %s on %s", version, renderer))
		end

		hate.state.window = window
		hate.state.gl_context = ctx
	end

	local main, msg = pcall(function() require "main" end)

	if msg then
		print(msg)
	end

	hate.run()

	return 0
end

return hate
