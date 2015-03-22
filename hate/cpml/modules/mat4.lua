-- double 4x4, 1-based, column major
-- local matrix = {}

local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local constants = require(current_folder .. "constants")
local vec3 = require(current_folder .. "vec3")

local mat4 = {}
mat4.__index = mat4
setmetatable(mat4, mat4)

-- from https://github.com/davidm/lua-matrix/blob/master/lua/matrix.lua
-- Multiply two matrices; m1 columns must be equal to m2 rows
-- e.g. #m1[1] == #m2
local function matrix_mult_nxn(m1, m2)
	local mtx = {}
	for i = 1, #m1 do
		mtx[i] = {}
		for j = 1, #m2[1] do
			local num = m1[i][1] * m2[1][j]
			for n = 2, #m1[1] do
				num = num + m1[i][n] * m2[n][j]
			end
			mtx[i][j] = num
		end
	end
	return mtx
end

function mat4:__call(v)
	local m = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	}
	if type(v) == "table" and #v == 16 then
		for i=1,16 do
			m[i] = v[i]
		end
	elseif type(v) == "table" and #v == 9 then
		m[1], m[2], m[3] = v[1], v[2], v[3]
		m[5], m[6], m[7] = v[4], v[5], v[6]
		m[9], m[10], m[11] = v[7], v[8], v[9]
		m[16] = 1
	elseif type(v) == "table" and type(v[1]) == "table" then
		local idx = 1
		for i=1, 4 do
			for j=1, 4 do
				m[idx] = v[i][j]
				idx = idx + 1
			end
		end
	end

	-- Look in mat4 for metamethods
	setmetatable(m, mat4)

	return m
end

function mat4:__eq(b)
	local abs = math.abs
	for i=1, 16 do
		if abs(self[i] - b[i]) > constants.FLT_EPSILON then
			return false
		end
	end
	return true
end

function mat4:__tostring()
	local str = "[ "
	for i, v in ipairs(self) do
		str = str .. string.format("%2.5f", v)
		if i < #self then
			str = str .. ", "
		end
	end
	str = str .. " ]"
	return str
end

function mat4:ortho(left, right, top, bottom, near, far)
	local out = mat4()
	out[1] = 2 / (right - left)
	out[6] = 2 / (top - bottom)
	out[11] = -2 / (far - near)
	out[13] = -((right + left) / (right - left))
	out[14] = -((top + bottom) / (top - bottom))
	out[15] = -((far + near) / (far - near))
	out[16] = 1
	return out
end

function mat4:perspective(fovy, aspect, near, far)
	assert(aspect ~= 0)
	assert(near ~= far)

	local t = math.tan(fovy / 2)
	local result = mat4(
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0
	)

	result[1] = 1 / (aspect * t)
	result[6] = 1 / t
	result[11] = - (far + near) / (far - near)
	result[12] = - 1
	result[15] = - (2 * far * near) / (far - near)

	return result
end

function mat4:translate(t)
	local m = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		t.x, t.y, t.z, 1
	}
	return mat4(m) * mat4(self)
end

function mat4:scale(s)
	local m = {
		s.x, 0, 0, 0,
		0, s.y, 0, 0,
		0, 0, s.z, 0,
		0, 0, 0, 1
	}
	return mat4(m) * mat4(self)
end

local function len(v)
	return math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
end

function mat4:rotate(angle, axis)
	if type(angle) == "table" then
		angle, axis = angle:to_axis_angle()
	end
	local l = len(axis)
	if l == 0 then
		return self
	end
	local x, y, z = axis[1] / l, axis[2] / l, axis[3] / l
	local c = math.cos(angle)
	local s = math.sin(angle)
	local m = {
		x*x*(1-c)+c, y*x*(1-c)+z*s, x*z*(1-c)-y*s, 0,
		x*y*(1-c)-z*s, y*y*(1-c)+c, y*z*(1-c)+x*s, 0,
		x*z*(1-c)+y*s, y*z*(1-c)-x*s, z*z*(1-c)+c, 0,
		0, 0, 0, 1,
	}
	return mat4(m) * mat4(self)
end

-- Set mat4 to identity mat4. Tested OK
function mat4:identity()
	local out = mat4()
	for i=1, 16, 5 do
		out[i] = 1
	end
	return out
end

function mat4:clone()
	return mat4(self)
end

-- Inverse of matrix. Tested OK
function mat4:invert()
	local out = mat4()

	out[1] =  self[6]  * self[11] * self[16] -
		self[6]  * self[12] * self[15] -
		self[10] * self[7]  * self[16] +
		self[10] * self[8]  * self[15] +
		self[14] * self[7]  * self[12] -
		self[14] * self[8]  * self[11]

	out[5] = -self[5]  * self[11] * self[16] +
		self[5]  * self[12] * self[15] +
		self[9]  * self[7]  * self[16] -
		self[9]  * self[8]  * self[15] -
		self[13] * self[7]  * self[12] +
		self[13] * self[8]  * self[11]

	out[9] =  self[5]  * self[10] * self[16] -
		self[5]  * self[12] * self[14] -
		self[9]  * self[6]  * self[16] +
		self[9]  * self[8]  * self[14] +
		self[13] * self[6]  * self[12] -
		self[13] * self[8]  * self[10]

	out[13] = -self[5]  * self[10] * self[15] +
		self[5]  * self[11] * self[14] +
		self[9]  * self[6]  * self[15] -
		self[9]  * self[7]  * self[14] -
		self[13] * self[6]  * self[11] +
		self[13] * self[7]  * self[10]

	out[2] = -self[2]  * self[11] * self[16] +
		self[2]  * self[12] * self[15] +
		self[10] * self[3]  * self[16] -
		self[10] * self[4]  * self[15] -
		self[14] * self[3]  * self[12] +
		self[14] * self[4]  * self[11]

	out[6] =  self[1]  * self[11] * self[16] -
		self[1]  * self[12] * self[15] -
		self[9]  * self[3] * self[16] +
		self[9]  * self[4] * self[15] +
		self[13] * self[3] * self[12] -
		self[13] * self[4] * self[11]

	out[10] = -self[1]  * self[10] * self[16] +
		self[1]  * self[12] * self[14] +
		self[9]  * self[2]  * self[16] -
		self[9]  * self[4]  * self[14] -
		self[13] * self[2]  * self[12] +
		self[13] * self[4]  * self[10]

	out[14] = self[1]  * self[10] * self[15] -
		self[1]  * self[11] * self[14] -
		self[9]  * self[2] * self[15] +
		self[9]  * self[3] * self[14] +
		self[13] * self[2] * self[11] -
		self[13] * self[3] * self[10]

	out[3] = self[2]  * self[7] * self[16] -
		self[2]  * self[8] * self[15] -
		self[6]  * self[3] * self[16] +
		self[6]  * self[4] * self[15] +
		self[14] * self[3] * self[8] -
		self[14] * self[4] * self[7]

	out[7] = -self[1]  * self[7] * self[16] +
		self[1]  * self[8] * self[15] +
		self[5]  * self[3] * self[16] -
		self[5]  * self[4] * self[15] -
		self[13] * self[3] * self[8] +
		self[13] * self[4] * self[7]

	out[11] = self[1]  * self[6] * self[16] -
		self[1]  * self[8] * self[14] -
		self[5]  * self[2] * self[16] +
		self[5]  * self[4] * self[14] +
		self[13] * self[2] * self[8] -
		self[13] * self[4] * self[6]

	out[15] = -self[1]  * self[6] * self[15] +
		self[1]  * self[7] * self[14] +
		self[5]  * self[2] * self[15] -
		self[5]  * self[3] * self[14] -
		self[13] * self[2] * self[7] +
		self[13] * self[3] * self[6]

	out[4] = -self[2]  * self[7] * self[12] +
		self[2]  * self[8] * self[11] +
		self[6]  * self[3] * self[12] -
		self[6]  * self[4] * self[11] -
		self[10] * self[3] * self[8] +
		self[10] * self[4] * self[7]

	out[8] = self[1] * self[7] * self[12] -
		self[1] * self[8] * self[11] -
		self[5] * self[3] * self[12] +
		self[5] * self[4] * self[11] +
		self[9] * self[3] * self[8] -
		self[9] * self[4] * self[7]

	out[12] = -self[1] * self[6] * self[12] +
		self[1] * self[8] * self[10] +
		self[5] * self[2] * self[12] -
		self[5] * self[4] * self[10] -
		self[9] * self[2] * self[8] +
		self[9] * self[4] * self[6]

	out[16] = self[1] * self[6] * self[11] -
		self[1] * self[7] * self[10] -
		self[5] * self[2] * self[11] +
		self[5] * self[3] * self[10] +
		self[9] * self[2] * self[7] -
		self[9] * self[3] * self[6]

	local det = self[1] * out[1] + self[2] * out[5] + self[3] * out[9] + self[4] * out[13]

	if det == 0 then return self end

	det = 1.0 / det

	for i = 1, 16 do
		out[i] = out[i] * det
	end

	return out
end

-- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl#L317
-- Note: GLM calls the view matrix "model"
function mat4.project(obj, view, projection, viewport)
	local position = { obj.x, obj.y, obj.z, 1 }

	position = view:transpose() * position
	position = projection:transpose() * position

	position[1] = position[1] / position[4] * 0.5 + 0.5
	position[2] = position[2] / position[4] * 0.5 + 0.5
	position[3] = position[3] / position[4] * 0.5 + 0.5
	position[4] = position[4] / position[4] * 0.5 + 0.5

	position[1] = position[1] * viewport[3] + viewport[1]
	position[2] = position[2] * viewport[4] + viewport[2]

	return vec3(position[1], position[2], position[3])
end

-- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl#L338
-- Note: GLM calls the view matrix "model"
function mat4.unproject(win, view, projection, viewport)
	local inverse = (projection:transpose() * view:transpose()):invert()
	local position = { win.x, win.y, win.z, 1 }
	position[1] = (position[1] - viewport[1]) / viewport[3]
	position[2] = (position[2] - viewport[2]) / viewport[4]

	position[1] = position[1] * 2 - 1
	position[2] = position[2] * 2 - 1
	position[3] = position[3] * 2 - 1
	position[4] = position[4] * 2 - 1

	position = inverse * position

	position[1] = position[1] / position[4]
	position[2] = position[2] / position[4]
	position[3] = position[3] / position[4]
	position[4] = position[4] / position[4]

	return vec3(position[1], position[2], position[3])
end

function mat4:look_at(eye, center, up)
	local forward = (center - eye):normalize()
	local side = forward:cross(up):normalize()
	local new_up = side:cross(forward):normalize()

	local view = mat4()
	view[1]	= side.x
	view[5]	= side.y
	view[9]	= side.z

	view[2]	= new_up.x
	view[6]	= new_up.y
	view[10]= new_up.z

	view[3]	= -forward.x
	view[7]	= -forward.y
	view[11]= -forward.z

	view[16]= 1

	-- Fix 1u offset
	local new_eye = eye + forward

	local out = mat4():translate(-new_eye) * view
	return out * self
end


function mat4:transpose()
	local m = {
		self[1], self[5], self[9], self[13],
		self[2], self[6], self[10], self[14],
		self[3], self[7], self[11], self[15],
		self[4], self[8], self[12], self[16]
	}
	return mat4(m)
end

function mat4:__unm()
	return self:invert()
end

-- Multiply mat4 by a mat4. Tested OK
function mat4:__mul(m)
	if #m == 4 then
		local tmp = matrix_mult_nxn(self:to_vec4s(), { {m[1]}, {m[2]}, {m[3]}, {m[4]} })
		local v = {}
		for i=1, 4 do
			v[i] = tmp[i][1]
		end
		return v
	end

	local out = mat4()
	for i=0, 12, 4 do
		for j=1, 4 do
			out[i+j] = m[j] * self[i+1] + m[j+4] * self[i+2] + m[j+8] * self[i+3] + m[j+12] * self[i+4]
		end
	end
	return out
end

function mat4:to_vec4s()
	return {
		{ self[1], self[2], self[3], self[4] },
		{ self[5], self[6], self[7], self[8] },
		{ self[9], self[10], self[11], self[12] },
		{ self[13], self[14], self[15], self[16] }
	}
end

return mat4
