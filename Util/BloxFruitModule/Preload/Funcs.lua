local FuncsModule = {}

function FuncsModule.Init(Context)
	Context = Context or {}
	local Settings = Context.Settings or (getgenv and getgenv().Settings) or _G.Settings or {}
	local Module = Context.Module or (getgenv and getgenv().Module) or _G.Module or {}
	local Tween = Context.Tween or (Module and Module.TweenManager)

	local Funcs = {}

	function Funcs:CreateToggle(Section, Label, Key, Default, Options)
		Options = Options or {}
		if Options.global then Settings[Key] = Default end
		Module.FunctionDisplayNames = Module.FunctionDisplayNames or {}
		Module.FunctionDisplayNames[Key] = Label
		local SaveKey = (Options.save ~= false) and Key or nil
		return Section:addToggle(Label, Default, function(Value)
			if Options.global then Settings[Key] = Value end
			Settings[Key] = Value
			if Value then
				if Module.Functions and Module.Functions[Key] and Module.Functions[Key].Start then
					Module.Functions[Key].Start()
				end
				if Module.Loops and Module.Loops[Key] and Module.Loops[Key].Start then
					Module.Loops[Key].Start()
				end
			else
				if Module.Functions and Module.Functions[Key] and Module.Functions[Key].Stop then
					Module.Functions[Key].Stop()
				elseif Module.Functions and Module.Functions[Key] then
					Module.Functions[Key].Running = false
				end
				if Module.Loops and Module.Loops[Key] and Module.Loops[Key].Stop then
					Module.Loops[Key].Stop()
				elseif Module.Loops and Module.Loops[Key] then
					Module.Loops[Key].Running = false
				end
				if Module.ActiveFunction == Key then
					Module.ActiveFunction = nil
				end
				if Options.stop ~= false then
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
			if type(Options.callback) == "function" then
				Options.callback(Value)
			end
		end, Options.locked, Options.description, SaveKey)
	end

	function Funcs:CreateDropdown(Section, Name, Key, Default, Options, Config, MultiMode)
		Config = Config or {}
		if Config.global then Settings[Key] = Default end
		local SaveKey = (Config.save ~= false) and Key or nil
		return Section:addDropdown(Name, Default, Options, function(Value)
			if Config.global then Settings[Key] = Value end
			Settings[Key] = Value
			if type(Config.callback) == "function" then
				Config.callback(Value)
			end
		end, Config.locked, MultiMode, SaveKey)
	end

	function Funcs:CreateSlider(Section, Label, Key, Min, Max, Default, Options)
		Options = Options or {}
		if Options.global then Settings[Key] = Default end
		local SaveKey = (Options.save ~= false) and Key or nil
		return Section:addSlider(Label, Min, Max, Default, function(Value)
			if Options.global then Settings[Key] = Value end
			Settings[Key] = Value
			if type(Options.callback) == "function" then
				Options.callback(Value)
			end
		end, Options.locked, Options.step, SaveKey)
	end

	function Funcs:CreateTextbox(Section, Label, Key, Options)
		Options = Options or {}
		if Options.global then Settings[Key] = Options.default or "" end
		local SaveKey = (Options.save ~= false) and Key or nil
		return Section:addTextbox(Label, function(Value)
			if Options.global then Settings[Key] = Value end
			Settings[Key] = Value
			if type(Options.callback) == "function" then
				Options.callback(Value)
			end
		end, Options.confirmText, SaveKey)
	end

	return Funcs
end

setmetatable(FuncsModule, {
	__call = function(_, Context)
		return FuncsModule.Init(Context)
	end
})

if getgenv then getgenv().FuncsModule = FuncsModule end
_G.FuncsModule = FuncsModule

return FuncsModule
