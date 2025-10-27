
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/Util/Library.lua"))()
local Shared = loadstring(game:HttpGet("https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/Util/shared.lua"))()

local helper = {}

local SaveManager = (Library and Library.SaveManager) or {
	Get = function(_, key, default)
		return Shared.Get(key) or default
	end,
	Set = function(_, key, value)
		Shared.Set(key, value)
	end
}

function helper.CreateToggle(section, label, key, default, options)
	options = options or {}
	local saved = SaveManager:Get(key, default)
	local desc = options.desc or options.description
	Shared.Set(key, saved)

	section:addToggle(label, saved, function(value)
		if options.save ~= false then
			SaveManager:Set(key, value)
		end

		Shared.Set(key, value)

		if typeof(options.callback) == "function" then
			task.spawn(options.callback, value)
		end
	end, desc)
end

function helper.CreateDropdown(tab, name, key, default, options, config)
	local saved = SaveManager:Get(key, default)
	local dropdown = tab:addDropdown(name, saved or default, options, function(value)
		SaveManager:Set(key, value)
		Shared.Set(key, value)

		if config and typeof(config.callback) == "function" then
			task.spawn(config.callback, value)
		end
	end)

	Shared.Set(key, saved)
	return dropdown
end

return helper
