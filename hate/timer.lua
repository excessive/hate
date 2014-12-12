local current_folder = (...):gsub('%.[^%.]+$', '') .. "."

local timer = {}

local last = 0

function timer.init()
end

function timer.step()
	last = 0
end

function timer.getDelta()
	return 0
end

function timer.sleep(seconds)
end

function timer.getAverageDelta()
	return 0
end

function timer.getTime()
	return 0
end

function timer.getFPS()
	return 0
end

return timer
