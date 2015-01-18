# HATE

It's not LÖVE.

HATE (capitalize it however you like, or put one of those umlauts in, I don't care) is an implementation of LÖVE's API in LuaJIT using FFI bindings. There's a strong chance that I will be diverging with the graphics module as my philosophy doesn't quite match slime's, but in general it should be compatible.

It's not nearly ready for use by anyone - so either help me implement more APIs or go use LÖVE!

# Dependencies

* physfs
* sdl2
* openal
* freetype
* luajit 2.0+

# Installation

No need for such things. Really, please don't, it doesn't work like that.

# Usage

Drop the hate folder and init.lua into your LÖVE project and run `luajit init.lua`

This is completely untested on Windows, but should technically work. So it's probably broken.
