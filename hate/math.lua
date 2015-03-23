local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local cpml = require(current_folder .. "cpml")

local math = {}

-- CPML's functions have the same semantics as LOVE here - no extra work needed
function math.linearToGamma(...)
	return cpml.color.linear_to_gamma(...)
end

function math.gammaToLinear(...)
	return cpml.color.gamma_to_linear(...)
end

return math
