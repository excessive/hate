#!/usr/bin/env luajit

package.path = package.path .. ";./?/init.lua"

hate = require "hate"

return hate.init()
