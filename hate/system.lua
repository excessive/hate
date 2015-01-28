local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local sdl = require(current_folder .. "sdl2")
local ffi = require "ffi"

local system = {}

function system.getClipboardText()
   if sdl.hasClipboardText() then
      return ffi.string(sdl.getClipboardText())
   end
end

function system.setClipboardText(text)
   sdl.setClipboardText(text)
end

function system.getOS()
   return ffi.string(sdl.getPlatform())
end

function system.getPowerInfo()
   local percent, seconds = ffi.new("int[1]"), ffi.new("int[1]")
   local state = sdl.getPowerInfo(percent, seconds)
   local states = {
      [tonumber(sdl.POWERSTATE_UNKNOWN)] = "unknown",
      [tonumber(sdl.POWERSTATE_ON_BATTERY)] = "battery",
      [tonumber(sdl.POWERSTATE_NO_BATTERY)] = "nobattery",
      [tonumber(sdl.POWERSTATE_CHARGING)] = "charging",
      [tonumber(sdl.POWERSTATE_CHARGED)] = "charged"
   }
   return states[tonumber(state)],
          percent[0] >= 0 and percent[0] or nil,
          seconds[0] >= 0 and seconds[0] or nil
end

function system.getProcessorCount()
   return tonumber(sdl.getCPUCount())
end

-- TODO: fix this thing
-- YOU THOUGHT YOU COULD OPEN A URL, BUT IT WAS ME, YOUR SAVE FOLDER!
function system.openURL(todo)
   url = url or ""

   local osname = love.system.getOS()
   local path = love.filesystem.getSaveDirectory() .. "/" .. url
   local cmdstr

   if osname == "Windows" then
      cmdstr = "Explorer %s"
      url = url:gsub("/", "\\")
      -- HATE doesn't support fusing... yet.
      -- if love.filesystem.isFused() then
      --    path = "%appdata%\\"
      -- else
      path = "%appdata%\\HATE\\"
      -- end
      path = path..love.filesystem.getIdentity() .. "\\" .. url
   elseif osname == "OS X" then
      cmdstr = "open -R \"%s\""
   elseif osname == "Linux" then
      cmdstr = "xdg-open \"%s\""
   end

   if cmdstr then
      os.execute(cmdstr:format(path))
   end
end


return system
