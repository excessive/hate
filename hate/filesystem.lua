local current_folder = (...):gsub('%.[^%.]+$', '') .. "."

local ffi = require "ffi"
local physfs = require(current_folder .. "physfs")

local filesystem = {}

-- TODO:
-- File
-- FileData
-- and everything using __NOPE__:

local __NOPE__ = function(...)
	error("not implemented :(")
end

filesystem.createDirectory = __NOPE__
filesystem.getAppdataDirectory = __NOPE__
filesystem.getIdentity = __NOPE__
filesystem.getUserDirectory = __NOPE__
filesystem.lines = __NOPE__
filesystem.load = __NOPE__
filesystem.newFile = __NOPE__
filesystem.newFileData = __NOPE__
filesystem.setIdentity = __NOPE__
filesystem.setSource = __NOPE__

function filesystem.init(path, name)
	assert(type(path) == "string", "hate.filesystem.init accepts one parameter of type 'string'")
	local status = physfs.init(path)

	if status ~= 1 then
		return false
	end

	physfs.setSaneConfig("HATE", name, "zip", 0, 0);

	status = physfs.mount(".", "", 0)

	return status ~= 0
end

function filesystem.deinit()
	physfs.deinit()
end

function filesystem.mount(archive, mountpoint, append)
	local status = physfs.mount(filesystem.getSaveDirectory() .. "/" .. archive, mountpoint, append and append or 0)
	return status ~= 0
end

-- ...this /might/ happen to return "."
function filesystem.getWorkingDirectory()
	return ffi.string(physfs.getRealDir("/"))
end

-- untested!
function filesystem.unmount(path)
	local abs_path = filesystem.getSaveDirectory() .. "/" .. path
	assert(filesystem.exists(path), "The file \"" .. path .. "\") does not exist.")
	physfs.removeFromSearchPath(filesystem.getSaveDirectory() .. "/" .. path)
end

function filesystem.getDirectoryItems(path, callback)
	local files = {}
	local list, i = physfs.enumerateFiles("/"), 0
	while list[i] ~= nil do
		if type(callback) == "function" then
			callback(ffi.string(list[i]))
		else
			table.insert(files, ffi.string(list[i]))
		end
		i = i + 1
	end
	physfs.freeList(list)
	return files
end

function filesystem.getLastModified(path)
	assert(filesystem.exists(path), "The file \"" .. path .. "\") does not exist.")
	return tonumber(physfs.getLastModTime(path))
end

function filesystem.getSize(path)
	assert(type(path) == "string", "hate.filesystem.getSize accepts one parameter of type 'string'")
	local f = physfs.openRead(path)
	return tonumber(physfs.fileLength(f))
end

function filesystem.getSaveDirectory()
	return physfs.getWriteDir()
end

function filesystem.remove(path)
	assert(filesystem.exists(path), "The file \"" .. path .. "\") does not exist.")
	return physfs.delete(path) ~= 0
end

function filesystem.read(path, length)
	assert(type(path) == "string", "hate.filesystem.read requires argument #1 to be of type 'string'")
	if length ~= nil then
		assert(type(length) == "number", "hate.filesystem.read requires argument #2 to be of type 'number'")
	end
	assert(filesystem.exists(path), "The file \"" .. path .. "\") does not exist.")
	local f = physfs.openRead(path)
	local bytes = length or tonumber(physfs.fileLength(f))
	local buf = ffi.new("unsigned char[?]", bytes)
	local read = tonumber(physfs.read(f, buf, 1, bytes))

	physfs.close(f)

	return ffi.string(buf, bytes)
end

function filesystem.append(path, data)
	local f = physfs.openAppend(path)
	local bytes = string.len(data)
	physfs.write(f, data, 1, bytes)
	physfs.close(f)
end

function filesystem.write(path, data)
	local f = physfs.openWrite(path)
	local bytes = string.len(data)
	physfs.write(f, data, 1, bytes)
	physfs.close(f)
end

function filesystem.exists(path)
	assert(type(path) == "string", "hate.filesystem.exists accepts one parameter of type 'string'")
	return physfs.exists(path) ~= 0
end

function filesystem.isFile(path)
	assert(type(path) == "string", "hate.filesystem.isFile accepts one parameter of type 'string'")
	return physfs.exists(path) ~= 0 and physfs.isDirectory(path) == 0
end

function filesystem.isDirectory(path)
	assert(type(path) == "string", "hate.filesystem.isDirectory accepts one parameter of type 'string'")
	return physfs.exists(path) ~= 0 and physfs.isDirectory(path) ~= 0
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

-- we don't even have a facility for fusing, so this can only be false.
-- this is only here for LOVE compatibility.
function filesystem.isFused()
	return false
end

return filesystem
