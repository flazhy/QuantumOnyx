local Shared = loadstring(game:HttpGet(('https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/Util/shared.lua')))()
local helper = {}

function helper.CreateToggle(section, label, key, default, options)
	options = options or {}
	local saved = Library.SaveManager:Get(key, default)
	local desc = options.desc or options.description

	section:addToggle(label, saved, function(value)
		if options.save ~= false then
			Library.SaveManager:Set(key, value)
		end

		Shared.Set(key, value)

		local callback = options.callback
		if typeof(callback) == "function" then
			callback(value)
		end
	end, desc)
end

function helper.CreateDropdown(tab, name, key, default, options, config)
	local saved = Library.SaveManager:Get(key, default)
	local dropdown = tab:addDropdown(name, (saved or default), options, function(value)
		Library.SaveManager:Set(key, value)
		Shared.Set(key, value)
		if config and config.callback then
			config.callback(value)
		end
	end)
	Shared.Set(key, saved)
	return dropdown
end

return helper
