local ToggleModule = {}

function ToggleModule.Attach(Funcs, Context)
	local Creator, UISettings, RegisterKeyLocked, CircleClick, Mouse, InnerSection, RegisterThemeElement, ThemeColor, CheckCondition, DummyObj, F, SaveSystem, ToggleRegistry, CreateAccentBar = Context.Creator, Context.UISettings, Context.RegisterKeyLocked, Context.CircleClick, Context.Mouse, Context.InnerSection, Context.RegisterThemeElement, Context.ThemeColor, Context.CheckCondition, Context.DummyObj, Context.F, Context.SaveSystem, Context.ToggleRegistry, Context.CreateAccentBar

	function Funcs:addToggle(Title, Default, Callback, Locked, Description, SaveKey, Condition, SubToggles, LiteAllowed)
		if not CheckCondition(Condition) then return DummyObj end
		Callback = Callback or function() end
		Default = Default or false

		if SaveKey then SaveSystem:RegisterKey(SaveKey) end
		if SaveKey then
			if (not Locked or F.HasKeyAccess()) and not IsFullLocked() then
				local saved = SaveSystem:Get(SaveKey, nil)
				if saved ~= nil then
					Default = saved
				end
			end
		end

		local Description, DescriptionHeight = Util.DescMetrics(Description, Enum.Font.Gotham, 11, 150)
		local frameHeight = DescriptionHeight > 0 and (28 + DescriptionHeight) or 32

		local ToggleFrame = Creator("TextButton", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.4,
			Size = UDim2.new(1, -25, 0, frameHeight),
			Position = UDim2.new(0, 0, 0, 0),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(0, 6) }) }
		}, InnerSection)

		RegisterElement(ToggleFrame, Title)

		local BGFrame = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			Position = UDim2.new(1, -50, 0.5, -9),
			Size = UDim2.new(0, 36, 0, 18),
			BorderSizePixel = 0,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(100, 100, 100),
					Transparency = 0.8,
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}
		}, ToggleFrame)

		local SlideButton = Creator("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(14, 14),
			Position = Default and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			Image = "http://www.roblox.com/asset/?id=12266946128",
			ImageTransparency = Default and 0 or 0.5,
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
		}, BGFrame)

		local SlideGradient = Creator("UIGradient", {
			Color = ThemeColor("Lit"),
			Rotation = 90,
		}, SlideButton)
		SlideGradient.Enabled = Default
		RegisterLitGradient(SlideGradient)
		local ToggleTitle = Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 4),
			Size = UDim2.new(1, -66, 0, 20),
			Font = Enum.Font.GothamBold,
			Text = Title,
			TextColor3 = Default and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(180, 180, 180),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			TextScaled = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			["Children"] = { MakeTextConstraint(14, 8) }
		}, ToggleFrame)
		RegisterTranslatable(ToggleTitle, Title)
		if DescriptionHeight > 0 then
			local DescLabel = Creator("TextLabel", {
				Name = "DescLabel",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 22),
				Size = UDim2.new(1, -60, 0, DescriptionHeight),
				Font = Enum.Font.Gotham,
				Text = Description,
				TextColor3 = Color3.fromRGB(130, 130, 145),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				TextSize = 11,
				ZIndex = 2,
			}, ToggleFrame)
			RegisterTranslatable(DescLabel, Description)
		end
		local ToggleState = (Locked and not F.HasKeyAccess()) and false or Default
		local SubFrames = {}

		local function UpdateSubVisibility()
			for _, subData in ipairs(SubFrames) do
				if subData.Optional then
					subData.Frame.Visible = ToggleState
				end
				if subData.SetInteractable then
					subData.SetInteractable(ToggleState)
				end
			end
		end

		local function UpdateToggle()
			UISettings:Tween(SlideButton, {
				Position = ToggleState and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				ImageTransparency = ToggleState and 0 or 0.5,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
			}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			SlideGradient.Enabled = ToggleState
			UISettings:Tween(ToggleTitle, {
				TextColor3 = ToggleState and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(120, 120, 120)
			}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			if SaveKey and (not Locked or F.HasKeyAccess()) then
				SaveSystem:ElementSave(SaveKey, ToggleState)
			end
			Callback(ToggleState)
			UpdateSubVisibility()
		end

		if SaveKey then
			SaveSystem:RegisterControl(SaveKey, {
				Type = "Toggle",
				Default = Default,
				Set = function(state, fireCb)
				ToggleState = state == true
				UISettings:Tween(SlideButton, {
					Position = ToggleState and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
					ImageTransparency = ToggleState and 0 or 0.5,
					ImageColor3 = Color3.fromRGB(255, 255, 255),
				}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				SlideGradient.Enabled = ToggleState
				UISettings:Tween(ToggleTitle, {
					TextColor3 = ToggleState and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(120, 120, 120)
				}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				UpdateSubVisibility()
				if fireCb ~= false then
					pcall(Callback, ToggleState)
				end
			end,
			Get = function() return ToggleState end,
		})
	end

	UpdateToggle()

	ToggleFrame.Activated:Connect(function()
	CircleClick(ToggleFrame, Mouse.X, Mouse.Y)
	ToggleState = not ToggleState
	UpdateToggle()
end)

if Locked and SaveKey then
	table.insert(ToggleRegistry, {
		saveKey = SaveKey,
		UpdateFn = function()
		if F.HasKeyAccess() then
			local saved = SaveSystem:Get(SaveKey, nil)
			ToggleState = saved ~= nil and saved or Default
			UpdateToggle()
		end
	end
})
end
RegisterKeyLocked(ToggleFrame, Locked)

if type(SubToggles) == "table" then
	local originName = SaveKey or Title:lower():gsub("%s+", "")
	for idx, subConfig in ipairs(SubToggles) do
		local subTitle = subConfig.Title or subConfig[1] or "Sub Toggle"
		local subDefault = subConfig.Default or subConfig[2] or false
		local subCallback = subConfig.Callback or subConfig[3] or function() end
		local subSaveKey = subConfig.SaveKey or subConfig.SaveKey or (originName .. "_sub" .. idx)
		local isOptional = subConfig.Optional == true

		SaveSystem:RegisterKey(subSaveKey)
		if (not Locked or F.HasKeyAccess()) and not IsFullLocked() then
			local saved = SaveSystem:Get(subSaveKey, nil)
			if saved ~= nil then subDefault = saved end
		end

		local SubFrame = Creator("TextButton", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.48,
			Size = UDim2.new(1, -38, 0, 28),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Active = ToggleState,
			Visible = not isOptional or ToggleState,
			ClipsDescendants = true,
			["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(0, 6) }) }
		}, InnerSection)

		RegisterElement(SubFrame, subTitle .. " (" .. Title .. ")")

		local SubBG = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 12, 12),
			Position = UDim2.new(1, -40, 0.5, -8),
			Size = UDim2.new(0, 30, 0, 16),
			BorderSizePixel = 0,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(100, 100, 100),
					Transparency = 0.8,
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}
		}, SubFrame)

		local SubStroke = SubBG.UIStroke

		local SubSlide = Creator("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(12, 12),
			Position = subDefault and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			Image = "http://www.roblox.com/asset/?id=12266946128",
			ImageTransparency = subDefault and 0 or 0.5,
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
		}, SubBG)

		local SubGradient = Creator("UIGradient", {
			Color = ThemeColor("Lit"),
			Rotation = 90,
		}, SubSlide)
		SubGradient.Enabled = subDefault
		RegisterLitGradient(SubGradient)

		local SubTitleLabel = Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -54, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = subTitle,
			TextColor3 = subDefault and Color3.fromRGB(205, 205, 210) or Color3.fromRGB(145, 145, 150),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			TextScaled = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			["Children"] = { MakeTextConstraint(13, 8) }
		}, SubFrame)

		RegisterTranslatable(SubTitleLabel, subTitle)

		local subState = subDefault
		local function UpdateSub()
			UISettings:Tween(SubSlide, {
				Position = subState and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				ImageTransparency = subState and 0 or 0.5,
			}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			SubGradient.Enabled = subState
			UISettings:Tween(SubTitleLabel, {
				TextColor3 = subState and Color3.fromRGB(205, 205, 210) or Color3.fromRGB(145, 145, 150)
			}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			UISettings:Tween(SubFrame, {
				BackgroundTransparency = subState and 0.35 or 0.48
			}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			if (not Locked or F.HasKeyAccess()) then
				SaveSystem:ElementSave(subSaveKey, subState)
			end
			subCallback(subState)
		end

		if subSaveKey then
			SaveSystem:RegisterControl(subSaveKey, {
				Type = "SubToggle",
				Default = subConfig.Default or subConfig[2] or false,
				Set = function(state, fireCb)
				subState = state == true
				UISettings:Tween(SubSlide, {
					Position = subState and UDim2.new(0, 16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
					ImageTransparency = subState and 0 or 0.5,
				}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				SubGradient.Enabled = subState
				UISettings:Tween(SubTitleLabel, {
					TextColor3 = subState and Color3.fromRGB(205, 205, 210) or Color3.fromRGB(145, 145, 150)
				}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				UISettings:Tween(SubFrame, {
					BackgroundTransparency = subState and 0.35 or 0.48
				}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				if fireCb ~= false then
					pcall(subCallback, subState)
				end
			end,
			Get = function() return subState end,
		})
	end

	local function SetInteractable(enabled)
		SubFrame.Active = enabled
		UISettings:Tween(SubFrame, {
			BackgroundTransparency = enabled and (subState and 0.35 or 0.48) or 0.75
		}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		UISettings:Tween(SubTitleLabel, {
			TextTransparency = enabled and 0 or 0.6,
			TextColor3 = enabled and (subState and Color3.fromRGB(205, 205, 210) or Color3.fromRGB(145, 145, 150)) or Color3.fromRGB(100, 100, 105)
		}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		UISettings:Tween(SubBG, {
			BackgroundTransparency = enabled and 0 or 0.65
		}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		UISettings:Tween(SubSlide, {
			ImageTransparency = enabled and (subState and 0 or 0.5) or 0.75
		}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		UISettings:Tween(SubStroke, {
			Transparency = enabled and 0.8 or 0.9
		}, 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end

	SubFrame.Activated:Connect(function()
	if not ToggleState then return end
	CircleClick(SubFrame, Mouse.X, Mouse.Y)
	subState = not subState
	UpdateSub()
end)

UpdateSub()
SetInteractable(ToggleState)
table.insert(SubFrames, { Frame = SubFrame, Optional = isOptional, SetInteractable = SetInteractable })
end
end

return {
	Update = function(state)
	ToggleState = state
	UpdateToggle()
end,
Get = function() return ToggleState end,
Frame = ToggleFrame,
}
end

Funcs.AddToggle = Funcs.addToggle
end

return ToggleModule
