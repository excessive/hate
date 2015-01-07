local current_folder = (...):gsub('%.[^%.]+$', '') .. "."

local ffi = require "ffi"
local physfs = require(current_folder .. "physfs")

local filesystem = {}

function filesystem.init(path, name)
	assert(type(path) == "string", "hate.filesystem.init accepts one parameter of type 'string'")
	local status = physfs.init(path)

	if status ~= 1 then
		return status
	end

	status = physfs.mount("./", "", 0)

	physfs.setSaneConfig("HATE", name, "zip", 0, 0);
	--physfs.setWriteDir("");
	print(physfs.getWriteDir())

	return status
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
	return files
end

function filesystem.getSize(path)
	assert(type(path) == "string", "hate.filesystem.getSize accepts one parameter of type 'string'")
	local f = physfs.openRead(path)
	return tonumber(physfs.fileLength(f))
end

function filesystem.getSaveDirectory()
	return physfs.getWriteDir()
end

function filesystem.read(path, length)
	assert(type(path) == "string", "hate.filesystem.read requires argument #1 to be of type 'string'")
	if length ~= nil then
		assert(type(length) == "number", "hate.filesystem.read requires argument #2 to be of type 'number'")
	end
	assert(filesystem.exists(path), "The file \"" .. path .. "\") does not exist.")
	local f = physfs.openRead(path)
	local bytes = tonumber(physfs.fileLength(f))
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
