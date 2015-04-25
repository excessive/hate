# HATE

It's not LÖVE.

HATE (capitalize it however you like, or put one of those umlauts in, I don't care) is an implementation of LÖVE's API in LuaJIT using FFI bindings. There's a strong chance that I will be diverging with the graphics module as my philosophy doesn't quite match slime's, but in general it should be compatible.

It's not nearly ready for use by anyone - so either help me implement more APIs or go use LÖVE!

[![Build Status](https://travis-ci.org/excessive/hate.svg)](https://travis-ci.org/excessive/hate)

# Dependencies

* PhysFS 2.0+
* SDL 2.0.3+
* OpenAL
* Freetype
* LuaJIT 2.0+

OpenGL 2.1+ or ES 2.0+ support is *required* to run HATE.

For Windows users, all dependencies can be downloaded from [releases](https://github.com/excessive/hate/releases).

# Installation

One does not simply install HATE. Really, please don't, it doesn't work like that.

# Usage

Drop the hate folder and init.lua into your LÖVE project and run `luajit init.lua`

# Contributing

Send pull requests my way, file bugs, and test everything you can! I especially appreciate contributions for audio, threading and tests.

See STATUS.md for APIs in dire need of implementation.
