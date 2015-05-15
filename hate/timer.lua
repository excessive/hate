local current_folder = (...):gsub('%.[^%.]+$', '') .. "."
local sdl = require(current_folder .. "sdl2")

local timer = {}

local last
local last_delta = 0
local average_delta = 0
local delta_list = {}

function timer.init()
	timer.step()
end

function timer.step()
	local now = tonumber(sdl.getPerformanceCounter())

	if not last then
		last = now
	end

	local freq = tonumber(sdl.getPerformanceFrequency())

	local delta = (now - last) / freq

	table.insert(
		delta_list,
		{ delta, now }
	)

	-- we only want to average everything from the last second
	local first_delta = (now - delta_list[1][2]) / freq
	if first_delta > 1 then
		table.remove(delta_list, 1)

		local average = 0
		for i=1,#delta_list do
			average = average + delta_list[i][1]
		end
		average = (average / #delta_list)

		average_delta = average
	else
		-- the average will be trash for the first second - so don't use it.
		average_delta = delta
	end

	-- print(average_delta)

	last_delta = delta_list[#delta_list][1]

	last = now
end

function timer.getDelta()
	return tonumber(last_delta)
end

function timer.sleep(seconds)
	sdl.delay(seconds * 1000)
end

function timer.getAverageDelta()
	return tonumber(average_delta)
end

function timer.getTime()
	return tonumber(last / sdl.getPerformanceFrequency())
end

function timer.getFPS()
	return math.ceil(1 / average_delta * 100) / 100
end

return timer
