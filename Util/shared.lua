local Shared = {}
local _state = {}
local Threader = {}
Threader.ActiveThreads = {}

function Threader.Start(name, func)
	Threader.Stop(name)
	Threader.ActiveThreads[name] = true

	task.spawn(function()
		while Threader.ActiveThreads[name] do
			local ok, err = pcall(func)
			if not ok then
				warn(("[Thread:%s] %s"):format(name, err))
			end
			task.wait()
		end
	end)
end

function Threader.Stop(name)
	Threader.ActiveThreads[name] = nil
end

function Threader.IsRunning(name)
	return Threader.ActiveThreads[name] ~= nil
end


function Shared.Get(key)
	return _state[key]
end

function Shared.Set(key, value)
	_state[key] = value
end

Shared.Threader = Threader
return Shared
