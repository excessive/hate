local current_folder = (...):gsub('%.[^%.]+$', '') .. "."

local ffi = require "ffi"
local physfs = require(current_folder .. "physfs")

local filesystem = {}

function filesystem.init(path)
	assert(type(path) == "string", "hate.filesystem.init accepts one parameter of type 'string'")
	return physfs.init(path) ~= 0
end

function filesystem.exists(path)
	assert(type(path) == "string", "hate.filesystem.exists accepts one parameter of type 'string'")
	return physfs.exists(path) ~= 0
end

function filesystem.setSymlinksEnabled(value)
	assert(type(value) == "boolean", "hate.filesystem.setSymlinksEnabled accepts one parameter of type 'boolean'")
	physfs.permitSymbolicLinks(value and 1 or 0)
end

function filesystem.areSymlinksEnabled()
	return physfs.symbolicLinksPermitted() ~= 0
end

function filesystem.isSymlink(path)
	assert(type(path) == "string", "hate.filesystem.isSymlink accepts one parameter of type 'string'")
	return physfs.isSymbolicLink(path) ~= 0
end

return filesystem
