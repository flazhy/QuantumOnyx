local SliderModule = {}

function SliderModule.Attach(Funcs, Context)
	local Creator, UISettings, RegisterKeyLocked, CircleClick, Mouse, InnerSection, RegisterThemeElement, ThemeColor, CheckCondition, DummyObj, F, SaveSystem, ToggleRegistry, UIS, CreateAccentBar = Context.Creator, Context.UISettings, Context.RegisterKeyLocked, Context.CircleClick, Context.Mouse, Context.InnerSection, Context.RegisterThemeElement, Context.ThemeColor, Context.CheckCondition, Context.DummyObj, Context.F, Context.SaveSystem, Context.ToggleRegistry, Context.UIS, Context.CreateAccentBar

	function Funcs:addSlider(slider_title, Min, Max, Default, Callback, Locked, Step, SaveKey, Condition, LiteAllowed)
		if not CheckCondition(Condition) then return DummyObj end
		Callback = Callback or function() end
		Min = Min or 0
		Max = Max or 100
		Step = Step or 1

		if SaveKey then SaveSystem:RegisterKey(SaveKey) end
		if SaveKey then
			if not Locked or F.HasKeyAccess() then
				local saved = SaveSystem:Get(SaveKey, nil)
				if saved ~= nil then Default = saved end
			end
		end

		Default = math.clamp(Default or Min, Min, Max)
		local decimal = select(2, tostring(Step):find("%.")) and #tostring(Step) - tostring(Step):find("%.") or
		0
		local formatString = "%." .. decimal .. "f"

		local function round(val)
			return math.floor(val / Step + 0.5) * Step
		end

		local SliderFrame = Creator("Frame", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.4,
			Size = UDim2.new(1, -25, 0, 54),
			Position = UDim2.new(0, 0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			}
		}, InnerSection)

		local GlowStroke = Creator("UIStroke", {
			Color = Color3.fromRGB(192, 132, 252),
			Transparency = 1,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, SliderFrame)

		local SliderTitle = Creator("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -70, 0, 18),
			Position = UDim2.new(0, 12, 0, 8),
			Font = Enum.Font.GothamBold,
			Text = slider_title,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(220, 220, 230),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			TextScaled = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 3,
			["Children"] = { MakeTextConstraint(15, 8) }
		}, SliderFrame)

		RegisterTranslatable(SliderTitle, slider_title)
		RegisterElement(SliderFrame, slider_title)

		local ValueCount = Creator("TextBox", {
			BackgroundColor3 = Color3.fromRGB(12, 12, 18),
			BackgroundTransparency = 0.2,
			Position = UDim2.new(1, -56, 0, 6),
			Size = UDim2.new(0, 46, 0, 20),
			Font = Enum.Font.GothamBold,
			Text = string.format(formatString, Default),
			TextSize = 12,
			TextColor3 = Color3.fromRGB(192, 132, 252),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ClipsDescendants = true,
			ClearTextOnFocus = false,
			ZIndex = 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
				Creator("UIStroke",
				{
					Color = Color3.fromRGB(192, 132, 252),
					Transparency = 0.72,
					Thickness = 1,
					ApplyStrokeMode =
					Enum.ApplyStrokeMode.Border
				}),
			}
		}, SliderFrame)

		local BGSlider = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 10, 16),
			BackgroundTransparency = 0.1,
			Position = UDim2.new(0, 12, 0, 34),
			Size = UDim2.new(1, -24, 0, 10),
			ZIndex = 2,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke",
				{
					Color = Color3.fromRGB(192, 132, 252),
					Transparency = 0.82,
					Thickness = 1,
					ApplyStrokeMode =
					Enum.ApplyStrokeMode.Border
				}),
			}
		}, SliderFrame)

		local sliderFillGrad = Creator("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(216, 180, 254)),
			}),
			Rotation = 0,
		})
		RegisterButtonGradient(sliderFillGrad)

		local SliderFill = Creator("Frame", {
			BackgroundTransparency = 0,
			Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0),
			ZIndex = 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				sliderFillGrad,
			}
		}, BGSlider)

		local Thumb = Creator("Frame", {
			Name = "Thumb",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new((Default - Min) / (Max - Min), 0, 0.5, 0),
			Size = UDim2.new(0, 13, 0, 13),
			ZIndex = 5,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke",
				{
					Color = Color3.fromRGB(192, 132, 252),
					Transparency = 0.3,
					Thickness = 1.5,
					ApplyStrokeMode =
					Enum.ApplyStrokeMode.Border
				}),
				Creator("Frame", {
					BackgroundColor3 = Color3.fromRGB(192, 132, 252),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 5, 0, 5),
					ZIndex = 6,
					["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(1, 0) }) }
				}),
			}
		}, BGSlider)

		local dragging = false

		local function SetSlider(value)
			local ratio = (value - Min) / (Max - Min)
			SliderFill:TweenSize(UDim2.new(ratio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint,
			0.15, true)
			UISettings:Tween(Thumb, { Position = UDim2.new(ratio, 0, 0.5, 0) }, 0.15, Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out)
			ValueCount.Text = string.format(formatString, value)
			if SaveKey and (not Locked or F.HasKeyAccess()) then SaveSystem:ElementSave(SaveKey, value) end
			Callback(value)
		end

		local function LiveSlider(x)
			local rel = math.clamp((x - BGSlider.AbsolutePosition.X) / BGSlider.AbsoluteSize.X, 0, 1)
			SetSlider(round(Min + (Max - Min) * rel))
		end

		SetSlider(Default)

		local activeDragInput = nil

		local function BeginDrag(input)
			if activeDragInput ~= nil then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				activeDragInput = input
				LiveSlider(input.Position.X)
				UISettings:Tween(GlowStroke, { Transparency = 0.45 }, 0.15)
				UISettings:Tween(Thumb, { Size = UDim2.new(0, 15, 0, 15) }, 0.15, Enum.EasingStyle.Back,
				Enum.EasingDirection.Out)
			end
		end

		BGSlider.InputBegan:Connect(BeginDrag)
		Thumb.InputBegan:Connect(BeginDrag)
		SliderFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			local relY = input.Position.Y - SliderFrame.AbsolutePosition.Y
			if relY >= 28 then BeginDrag(input) end
		end
	end)
	UIS.InputChanged:Connect(function(input)
	if not dragging or not activeDragInput then return end
	if input == activeDragInput or (activeDragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
		LiveSlider(input.Position.X)
	end
end)
UIS.InputEnded:Connect(function(input)
if input == activeDragInput then
	dragging = false
	activeDragInput = nil
	UISettings:Tween(GlowStroke, { Transparency = 1 }, 0.3)
	UISettings:Tween(Thumb, { Size = UDim2.new(0, 13, 0, 13) }, 0.2, Enum.EasingStyle.Quint)
end
end)

ValueCount.FocusLost:Connect(function()
local val = tonumber(ValueCount.Text)
if val then
	SetSlider(round(math.clamp(val, Min, Max)))
else
	SetSlider(Default)
end
end)

if SaveKey then
	SaveSystem:RegisterControl(SaveKey, {
		Type = "Slider",
		Default = Default,
		Set = function(val, fireCb)
		val = tonumber(val) or Default
		val = math.clamp(val, Min, Max)
		local ratio = (val - Min) / (Max - Min)
		SliderFill:TweenSize(UDim2.new(ratio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.15, true)
		UISettings:Tween(Thumb, { Position = UDim2.new(ratio, 0, 0.5, 0) }, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		ValueCount.Text = string.format(formatString, val)
		if fireCb ~= false then pcall(Callback, val) end
	end,
	Get = function() return tonumber(ValueCount.Text) or Default end,
})
end

if Locked and SaveKey then
	table.insert(ToggleRegistry, {
		saveKey = SaveKey,
		UpdateFn = function()
		if F.HasKeyAccess() then
			local saved = SaveSystem:Get(SaveKey, nil)
			SetSlider(math.clamp(saved ~= nil and saved or Default, Min, Max))
		else
			SetSlider(Default)
		end
	end
})
end
RegisterKeyLocked(SliderFrame, Locked)
end

Funcs.AddSlider = Funcs.addSlider
end

return SliderModule
