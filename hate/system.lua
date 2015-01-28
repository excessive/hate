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

function system.openURL(path)
   local osname = hate.system.getOS()
   local cmds = {
      ["Windows"] = "start \"\"",
      ["OS X"]    = "open",
      ["Linux"]   = "xdg-open"
   }
   if path:sub(1, 7) == "file://" then
      cmds["Windows"] = "explorer"
      -- Windows-ify
      if osname == "Windows" then
         path = path:sub(8):gsub("/", "\\")
      end
   end
   if not cmds[osname] then
      print("What /are/ birds?")
      return
   end
   local cmdstr = cmds[osname] .. " \"%s\""
   -- print(cmdstr, path)
   os.execute(cmdstr:format(path))
end

return system
