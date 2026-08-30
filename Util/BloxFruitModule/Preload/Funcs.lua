local FuncsModule = {}

function FuncsModule.Init(context)
	context = context or {}
	local Settings = context.Settings or (getgenv and getgenv().Settings) or _G.Settings or {}
	local Module = context.Module or (getgenv and getgenv().Module) or _G.Module or {}
	local Tween = context.Tween or (Module and Module.TweenManager)

	local Funcs = {}

	function Funcs:CreateToggle(section, label, key, default, options)
		options = options or {}
		if options.global then Settings[key] = default end
		Module.FunctionDisplayNames = Module.FunctionDisplayNames or {}
		Module.FunctionDisplayNames[key] = label
		local saveKey = (options.save ~= false) and key or nil
		return section:addToggle(label, default, function(value)
			if options.global then Settings[key] = value end
			Settings[key] = value
			if value then
				if Module.Functions and Module.Functions[key] and Module.Functions[key].Start then
					Module.Functions[key].Start()
				end
				if Module.Loops and Module.Loops[key] and Module.Loops[key].Start then
					Module.Loops[key].Start()
				end
			else
				if Module.Functions and Module.Functions[key] and Module.Functions[key].Stop then
					Module.Functions[key].Stop()
				elseif Module.Functions and Module.Functions[key] then
					Module.Functions[key].Running = false
				end
				if Module.Loops and Module.Loops[key] and Module.Loops[key].Stop then
					Module.Loops[key].Stop()
				elseif Module.Loops and Module.Loops[key] then
					Module.Loops[key].Running = false
				end
				if Module.ActiveFunction == key then
					Module.ActiveFunction = nil
				end
				if options.stop ~= false then
					if Tween and Tween.StopTween then
						Tween:StopTween()
					end
					if not (Settings.AutoSharkAnchor or Settings.AutoFindLeviatan or Settings.AutoSailbacktoTiki or Settings.AutoSail) then
						if Tween and Tween.StopBoatTween then
							Tween:StopBoatTween()
						end
					end
				end
			end
			if type(options.callback) == "function" then
				options.callback(value)
			end
		end, options.locked, options.description, saveKey)
	end

	function Funcs:CreateDropdown(tab, name, key, default, options, config, multimode)
		config = config or {}
		if config.global then Settings[key] = default end
		local saveKey = (config.save ~= false) and key or nil
		return tab:addDropdown(name, default, options, function(value)
			if config.global then Settings[key] = value end
			Settings[key] = value
			if type(config.callback) == "function" then
				config.callback(value)
			end
		end, config.locked, multimode, saveKey)
	end

	function Funcs:CreateSlider(section, label, key, min, max, default, options)
		options = options or {}
		if options.global then Settings[key] = default end
		local saveKey = (options.save ~= false) and key or nil
		return section:addSlider(label, min, max, default, function(value)
			if options.global then Settings[key] = value end
			Settings[key] = value
			if type(options.callback) == "function" then
				options.callback(value)
			end
		end, options.locked, options.step, saveKey)
	end

	function Funcs:CreateTextbox(section, label, key, options)
		options = options or {}
		if options.global then Settings[key] = options.default or "" end
		local saveKey = (options.save ~= false) and key or nil
		return section:addTextbox(label, function(value)
			if options.global then Settings[key] = value end
			Settings[key] = value
			if type(options.callback) == "function" then
				options.callback(value)
			end
		end, options.confirmText, saveKey)
	end

	return Funcs
end

setmetatable(FuncsModule, {
	__call = function(_, context)
		return FuncsModule.Init(context)
	end
})

return FuncsModule
