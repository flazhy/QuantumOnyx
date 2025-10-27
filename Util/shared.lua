local Shared = {}
local Storage = setmetatable({}, { __mode = "kv" })

function Shared.Get(key)
	return Storage[key]
end

function Shared.Set(key, val)
	Storage[key] = val
end

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
	return Threader.ActiveThreads[name] == true
end

Shared.Threader = Threader
return Shared
