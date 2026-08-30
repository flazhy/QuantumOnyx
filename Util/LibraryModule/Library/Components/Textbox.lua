local TextboxModule = {}

function TextboxModule.Attach(Funcs, Context)
	local Creator, UISettings, RegisterKeyLocked, CircleClick, Mouse, InnerSection, RegisterThemeElement, ThemeColor, CheckCondition, DummyObj, F, SaveSystem, CreateAccentBar = Context.Creator, Context.UISettings, Context.RegisterKeyLocked, Context.CircleClick, Context.Mouse, Context.InnerSection, Context.RegisterThemeElement, Context.ThemeColor, Context.CheckCondition, Context.DummyObj, Context.F, Context.SaveSystem, Context.CreateAccentBar

	function Funcs:addTextbox(titleText, Callback, AdjustableTitle, SaveKey, Condition, LiteAllowed)
		if not CheckCondition(Condition) then return DummyObj end
		Callback = Callback or function() end
		if SaveKey then SaveSystem:RegisterKey(SaveKey) end
		local savedText = SaveKey and SaveSystem:Get(SaveKey, "") or ""

		local TextBoxFrame = Creator("Frame", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -25, 0, 96),
			ClipsDescendants = true,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}
		}, InnerSection)
		RegisterElement(TextBoxFrame, titleText or "Textbox")

		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 6),
			Size = UDim2.new(1, -20, 0, 20),
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(220, 220, 230),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = titleText or "Textbox",
			TextWrapped = false,
			TextScaled = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 3,
			["Children"] = { MakeTextConstraint(15, 8) }
		}, TextBoxFrame)

		Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(110, 55, 190),
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 10, 0, 30),
			Size = UDim2.new(1, -20, 0, 1),
			ZIndex = 3,
		}, TextBoxFrame)

		local InputPill = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 10, 16),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 10, 0, 38),
			Size = UDim2.new(1, -20, 0, 24),
			ClipsDescendants = true,
			ZIndex = 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			}
		}, TextBoxFrame)

		local InputStroke = Creator("UIStroke", {
			Color = Color3.fromRGB(110, 55, 190),
			Transparency = 0.78,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, InputPill)

		local TextBox = Creator("TextBox", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -18, 1, 0),
			Font = Enum.Font.GothamSemibold,
			TextColor3 = Color3.fromRGB(210, 195, 255),
			PlaceholderColor3 = Color3.fromRGB(110, 85, 150),
			PlaceholderText = titleText or "Enter here...",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = savedText,
			ClearTextOnFocus = false,
			ZIndex = 4,
		}, InputPill)

		local ButtonHolder = Creator("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 70),
			Size = UDim2.new(1, -20, 0, 20),
			ZIndex = 3,
			["Children"] = {
				Creator("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 6),
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}
		}, TextBoxFrame)

		local ClearBtn = Creator("TextButton", {
			BackgroundColor3 = Color3.fromRGB(110, 55, 190),
			BackgroundTransparency = 0.84,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(0, 54, 0, 20),
			Text = "Clear",
			TextColor3 = Color3.fromRGB(170, 120, 240),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			AutoButtonColor = false,
			ZIndex = 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(110, 55, 190),
					Transparency = 0.72,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				}),
			}
		}, ButtonHolder)

		local JoinBtn = Creator("TextButton", {
			BackgroundColor3 = Color3.fromRGB(110, 55, 190),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.new(0, 60, 0, 20),
			Text = AdjustableTitle or "Confirm",
			TextColor3 = Color3.fromRGB(200, 170, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			AutoButtonColor = false,
			ZIndex = 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(110, 55, 190),
					Transparency = 0.60,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				}),
			}
		}, ButtonHolder)

		TextBox.Focused:Connect(function()
		UISettings:Tween(InputStroke, { Transparency = 0.42 }, 0.2)
		UISettings:Tween(InputPill, { BackgroundTransparency = 0.0 }, 0.2)
	end)
	TextBox.FocusLost:Connect(function()
	UISettings:Tween(InputStroke, { Transparency = 0.78 }, 0.28)
	UISettings:Tween(InputPill, { BackgroundTransparency = 0.1 }, 0.28)
end)
ClearBtn.MouseEnter:Connect(function()
UISettings:Tween(ClearBtn, { BackgroundTransparency = 0.60 }, 0.15)
end)
ClearBtn.MouseLeave:Connect(function()
UISettings:Tween(ClearBtn, { BackgroundTransparency = 0.84 }, 0.2)
end)
JoinBtn.MouseEnter:Connect(function()
UISettings:Tween(JoinBtn, { BackgroundTransparency = 0.25 }, 0.15)
end)
JoinBtn.MouseLeave:Connect(function()
UISettings:Tween(JoinBtn, { BackgroundTransparency = 0.45 }, 0.2)
end)
ClearBtn.MouseButton1Click:Connect(function()
CircleClick(ClearBtn, Mouse.X, Mouse.Y)
TextBox.Text = ""
if SaveKey then SaveSystem:ElementSave(SaveKey, "") end
TextBox:CaptureFocus()
end)
JoinBtn.MouseButton1Click:Connect(function()
CircleClick(JoinBtn, Mouse.X, Mouse.Y)
if TextBox.Text ~= "" then
	if SaveKey then SaveSystem:ElementSave(SaveKey, TextBox.Text) end
	Callback(TextBox.Text)
end
end)
TextBox.FocusLost:Connect(function(enterPressed)
if enterPressed and TextBox.Text ~= "" then
	if SaveKey then SaveSystem:ElementSave(SaveKey, TextBox.Text) end
	Callback(TextBox.Text)
end
end)

if savedText ~= "" then
	task.defer(function()
	Callback(savedText)
end)
end

if SaveKey then
	SaveSystem:RegisterControl(SaveKey, {
		Type = "Textbox",
		Default = "",
		Set = function(text, fireCb)
		text = tostring(text or "")
		TextBox.Text = text
		if fireCb ~= false then pcall(Callback, text) end
	end,
	Get = function() return TextBox.Text end,
})
end

return {
	TextBox = TextBox,
	Clear = ClearBtn,
	Join = JoinBtn,
	Frame = TextBoxFrame,
	SetText = function(_, text) TextBox.Text = text or "" end,
	GetText = function() return TextBox.Text end,
}
end

Funcs.AddTextbox = Funcs.addTextbox
end

return TextboxModule
