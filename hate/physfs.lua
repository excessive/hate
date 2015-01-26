local ffi = require "ffi"
local cdef = ffi.cdef([[
typedef unsigned char PHYSFS_uint8;
typedef signed char PHYSFS_sint8;
typedef unsigned short PHYSFS_uint16;
typedef signed short PHYSFS_sint16;
typedef unsigned int PHYSFS_uint32;
typedef signed int PHYSFS_sint32;
typedef unsigned long long PHYSFS_uint64;
typedef signed long long PHYSFS_sint64;

typedef struct PHYSFS_File
{
	void *opaque;
} PHYSFS_File;

typedef struct PHYSFS_ArchiveInfo
{
	const char *extension;
	const char *description;
	const char *author;
	const char *url;
} PHYSFS_ArchiveInfo;

typedef struct PHYSFS_Version
{
	PHYSFS_uint8 major;
	PHYSFS_uint8 minor;
	PHYSFS_uint8 patch;
} PHYSFS_Version;

int PHYSFS_init(const char *argv0);
int PHYSFS_deinit(void);

PHYSFS_File *PHYSFS_openAppend(const char *filename);
PHYSFS_File *PHYSFS_openRead(const char *filename);
PHYSFS_File *PHYSFS_openWrite(const char *filename);

int PHYSFS_close(PHYSFS_File *handle);
int PHYSFS_exists(const char *fname);
int PHYSFS_seek(PHYSFS_File *handle, PHYSFS_uint64 pos);
int PHYSFS_flush(PHYSFS_File *handle);
int PHYSFS_eof(PHYSFS_File *handle);
int PHYSFS_delete(const char *filename);
PHYSFS_sint64 PHYSFS_tell(PHYSFS_File *handle);
PHYSFS_sint64 PHYSFS_write(PHYSFS_File *handle, const void *buffer, PHYSFS_uint32 objSize, PHYSFS_uint32 objCount);

int PHYSFS_mkdir(const char *dirName);
int PHYSFS_mount(const char *newDir, const char *mountPoint, int appendToPath);

char **PHYSFS_enumerateFiles(const char *dir);
const char *PHYSFS_getBaseDir(void);

char **PHYSFS_getSearchPath(void);
int PHYSFS_addToSearchPath(const char *newDir, int appendToPath);
int PHYSFS_removeFromSearchPath(const char *oldDir);

char **PHYSFS_getCdRomDirs(void);
const char *PHYSFS_getDirSeparator(void);
const char *PHYSFS_getLastError(void);
const char *PHYSFS_getMountPoint(const char *dir);
const char *PHYSFS_getRealDir(const char *filename);
const char *PHYSFS_getUserDir(void);
const char *PHYSFS_getWriteDir(void);

const PHYSFS_ArchiveInfo **PHYSFS_supportedArchiveTypes(void);

int PHYSFS_isDirectory(const char *fname);
int PHYSFS_isInit(void);
int PHYSFS_isSymbolicLink(const char *fname);

int PHYSFS_setBuffer(PHYSFS_File *handle, PHYSFS_uint64 bufsize);
int PHYSFS_setSaneConfig(const char *organization, const char *appName, const char *archiveExt, int includeCdRoms, int archivesFirst);
int PHYSFS_setWriteDir(const char *newDir);
int PHYSFS_symbolicLinksPermitted(void);


PHYSFS_sint64 PHYSFS_fileLength(PHYSFS_File *handle);
PHYSFS_sint64 PHYSFS_getLastModTime(const char *filename);
PHYSFS_sint64 PHYSFS_read(PHYSFS_File *handle, void *buffer, PHYSFS_uint32 objSize, PHYSFS_uint32 objCount);

void PHYSFS_freeList(void *listVar);
void PHYSFS_getLinkedVersion(PHYSFS_Version *ver);
void PHYSFS_permitSymbolicLinks(int allow);
]])

local C = ffi.load(ffi.os == "Windows" and "bin/physfs" or "physfs")
local physfs = { C = C }

local function register(luafuncname, funcname, is_string)
	local symexists, msg = pcall(function()
		local sym = C[funcname]
	end)
	if not symexists then
		error("Symbol " .. funcname .. " not found. Something is really, really wrong.")
	end
	-- kill the need to use ffi.string on several functions, for convenience.
	if is_string then
		physfs[luafuncname] = function(...)
			local r = C[funcname](...)
			return ffi.string(r)
		end
	else
		physfs[luafuncname] = C[funcname]
	end
end

register("init", "PHYSFS_init")
register("deinit", "PHYSFS_deinit")

register("openAppend", "PHYSFS_openAppend")
register("openRead", "PHYSFS_openRead")
register("openWrite", "PHYSFS_openWrite")

register("close", "PHYSFS_close")
register("exists", "PHYSFS_exists")
register("seek", "PHYSFS_seek")
register("flush", "PHYSFS_flush")
register("eof", "PHYSFS_eof")
register("delete", "PHYSFS_delete")
register("tell", "PHYSFS_tell")
register("write", "PHYSFS_write")

register("mkdir", "PHYSFS_mkdir")
register("mount", "PHYSFS_mount")

register("enumerateFiles", "PHYSFS_enumerateFiles")
register("getBaseDir", "PHYSFS_getBaseDir", true)

register("getSearchPath", "PHYSFS_getSearchPath")
register("addToSearchPath", "PHYSFS_addToSearchPath")
register("removeFromSearchPath", "PHYSFS_removeFromSearchPath")

register("getCdRomDirs", "PHYSFS_getCdRomDirs")
register("getDirSeparator", "PHYSFS_getDirSeparator", true)
register("getLastError", "PHYSFS_getLastError", true)
register("getMountPoint", "PHYSFS_getMountPoint", true)
register("getRealDir", "PHYSFS_getRealDir", true)
register("getUserDir", "PHYSFS_getUserDir", true)
register("getWriteDir", "PHYSFS_getWriteDir", true)

register("supportedArchiveTypes", "PHYSFS_supportedArchiveTypes")

register("isDirectory", "PHYSFS_isDirectory")
register("isInit", "PHYSFS_isInit")
register("isSymbolicLink", "PHYSFS_isSymbolicLink")

register("setBuffer", "PHYSFS_setBuffer")
register("setSaneConfig", "PHYSFS_setSaneConfig")
register("setWriteDir", "PHYSFS_setWriteDir")
register("symbolicLinksPermitted", "PHYSFS_symbolicLinksPermitted")


register("fileLength", "PHYSFS_fileLength")
register("getLastModTime", "PHYSFS_getLastModTime")
register("read", "PHYSFS_read")

register("freeList", "PHYSFS_freeList")
register("getLinkedVersion", "PHYSFS_getLinkedVersion")
register("permitSymbolicLinks", "PHYSFS_permitSymbolicLinks")

return physfs
