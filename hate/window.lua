local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local sdl = require(current_folder .. "sdl2")
local ffi = require "ffi"
local window = {}

-- TODO: EVERYTHING
-- Note: you almost definitely want graphics.getDimensions, not this!
function window.getDimensions()
   local w, h = ffi.new("int[1]"), ffi.new("int[1]")
   sdl.getWindowSize(window._state.window, w, h)

   return tonumber(w[0]), tonumber(h[0])
end

function window.getWidth()
   return select(1, window.getDimensions())
end

function window.getHeight()
   return select(2, window.getDimensions())
end

return window
