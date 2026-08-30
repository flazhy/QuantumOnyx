local DropdownModule = {}

function DropdownModule.Attach(Funcs, Context)
	local Creator, UISettings, RegisterKeyLocked, CircleClick, Mouse, InnerSection, RegisterThemeElement, ThemeColor, CheckCondition, DummyObj, F, SaveSystem, ToggleRegistry, ScreenGui, CreateAccentBar = Context.Creator, Context.UISettings, Context.RegisterKeyLocked, Context.CircleClick, Context.Mouse, Context.InnerSection, Context.RegisterThemeElement, Context.ThemeColor, Context.CheckCondition, Context.DummyObj, Context.F, Context.SaveSystem, Context.ToggleRegistry, Context.ScreenGui, Context.CreateAccentBar

	function Funcs:addDropdown(Title, Default, Options, Callback, Locked, MultiMode, SaveKey, Condition, LiteAllowed)
		if not CheckCondition(Condition) then return DummyObj end
		Default = Default or 1
		Options = Options or {}
		Callback = Callback or function() end

		if SaveKey then SaveSystem:RegisterKey(SaveKey) end
		if SaveKey then
			if not Locked or F.HasKeyAccess() then
				local saved = SaveSystem:Get(SaveKey, nil)
				if saved ~= nil then Default = saved end
			end
		end
		local SelectedIndices = {}
		local FilteredOptions = {}

		local function AddIndex(i)
			if not table.find(SelectedIndices, i) then table.insert(SelectedIndices, i) end
		end
		local function RemoveIndex(i)
			for k, v in ipairs(SelectedIndices) do
				if v == i then
					table.remove(SelectedIndices, k); return
				end
			end
		end
		local function SelectedValues()
			local t = {}
			for _, i in ipairs(SelectedIndices) do t[#t + 1] = Options[i] end
			return t
		end
		local function FormatSelection(selected, limit)
			limit = limit or 2
			if #selected == 0 then
				return "None"
			elseif #selected <= limit then
				return table.concat(selected, ", ")
			else
				local shown = {}
				for i = 1, limit do shown[i] = selected[i] end
				return table.concat(shown, ", ") .. "  +" .. (#selected - limit)
			end
		end
		local function InitializeSelection()
			local function SetAdd(val)
				if #Options < 1 then return end
				local idx = type(val) == "number" and math.clamp(val, 1, #Options) or
				type(val) == "string" and table.find(Options, val)
				if idx then AddIndex(idx) end
			end
			if MultiMode then
				if typeof(Default) == "table" then
					for _, v in ipairs(Default) do SetAdd(v) end
				else
					SetAdd(Default)
				end
				if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
			else
				SetAdd(Default)
				if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
			end
		end
		InitializeSelection()

		local DropdownFrame = Creator("Frame", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -25, 0, 32),
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
		}, DropdownFrame)

		RegisterElement(DropdownFrame, Title)

		local DropTitle = Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -95, 1, 0),
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(220, 220, 230),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Title,
			TextWrapped = false,
			TextScaled = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 3,
			["Children"] = { MakeTextConstraint(15, 8) }
		}, DropdownFrame)

		local SelectedBox = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 12, 18),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -90, 0.5, -11),
			Size = UDim2.new(0, 68, 0, 22),
			ZIndex = 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
				Creator("UIStroke",
				{
					Color = Color3.fromRGB(192, 132, 252),
					Transparency = 0.75,
					Thickness = 1,
					ApplyStrokeMode =
					Enum.ApplyStrokeMode.Border
				}),
			}
		}, DropdownFrame)

		local SelectedText = Creator("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.new(0, 6, 0, 0),
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(192, 132, 252),
			TextScaled = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = MultiMode and FormatSelection(SelectedValues(), 2) or
			(Options[SelectedIndices[1]] or "None"),
			ZIndex = 4,
			["Children"] = { MakeTextConstraint(13, 10) }
		}, SelectedBox)

		local DropIcon = Creator("ImageButton", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Image = "rbxassetid://95968409641902",
			ImageColor3 = Color3.fromRGB(192, 132, 252),
			ZIndex = 3,
		}, DropdownFrame)

		local Blocker = Creator("Frame", {
			Visible = false,
			Active = true,
			BackgroundTransparency = 0.6,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 9,
		}, Body)

		local DialogBackground = Creator("Frame", {
			Visible = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0.18,
			Size = UDim2.new(0, 250, 0, 0),
			BackgroundColor3 = Color3.fromRGB(14, 14, 20),
			ZIndex = 10,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 10) }),
				Creator("UIStroke",
				{ Color = Color3.fromRGB(192, 132, 252), Transparency = 0.72, Thickness = 1 }),
			}
		}, Body)

		Creator("TextLabel", {
			Size = UDim2.new(1, -40, 0, 20),
			Position = UDim2.new(0, 12, 0, 8),
			BackgroundTransparency = 1,
			Text = Title,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(220, 220, 230),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 11,
		}, DialogBackground)

		local DDCloseButton = Creator("TextButton", {
			Text = "×",
			TextColor3 = Color3.fromRGB(192, 132, 252),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(1, -28, 0, 5),
			BackgroundColor3 = Color3.fromRGB(192, 132, 252),
			BackgroundTransparency = 0.88,
			AutoButtonColor = false,
			ZIndex = 12,
			["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(0, 5) }) }
		}, DialogBackground)

		local DDSearchBox = Creator("TextBox", {
			Text = "",
			PlaceholderText = "Search Options...",
			PlaceholderColor3 = Color3.fromRGB(120, 100, 150),
			Size = UDim2.new(1, -16, 0, 26),
			Position = UDim2.new(0, 8, 0, 34),
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(220, 220, 230),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(10, 10, 16),
			BackgroundTransparency = 0.1,
			ClearTextOnFocus = true,
			ZIndex = 11,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Creator("UIStroke",
				{
					Color = Color3.fromRGB(192, 132, 252),
					Transparency = 0.78,
					Thickness = 1,
					ApplyStrokeMode =
					Enum.ApplyStrokeMode.Border
				}),
				Creator("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
			}
		}, DialogBackground)

		local DDScrollFrame = Creator("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, -70),
			Position = UDim2.new(0, 4, 0, 66),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 0,
			ScrollBarImageTransparency = 1,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
			BackgroundTransparency = 1,
			Active = true,
			ZIndex = 11,
			["Children"] = {
				Creator("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
				Creator("UIPadding",
				{
					PaddingLeft = UDim.new(0, 2),
					PaddingRight = UDim.new(0, 2),
					PaddingTop = UDim.new(0, 2),
					PaddingBottom =
					UDim.new(0, 4)
				}),
			}
		}, DialogBackground)

		local DialogFinalSize = UDim2.new(0, 250, 0, 230)

		local function GetRelativePosition(instance, relativeTo)
			local absPos = instance.AbsolutePosition
			local relAbsPos = relativeTo.AbsolutePosition
			return UDim2.new(0, absPos.X - relAbsPos.X, 0, absPos.Y - relAbsPos.Y)
		end

		local function CloseDialog()
			local iconPos = GetRelativePosition(DropIcon, Body)
			local iconSize = DropIcon.AbsoluteSize
			UISettings:Tween(DialogBackground,
			{ Position = iconPos, Size = UDim2.new(0, iconSize.X, 0, iconSize.Y) }, 0.25,
			Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			UISettings:Tween(DropIcon, { Rotation = 0 }, 0.25, Enum.EasingStyle.Quint)
			UISettings:Tween(GlowStroke, { Transparency = 1 }, 0.3)
			task.delay(0.25, function()
			DialogBackground.Visible = false
			Blocker.Visible = false
		end)
	end

	local function RefreshOptions(SearchText)
		for _, c in ipairs(DDScrollFrame:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		FilteredOptions = {}
		for i, val in ipairs(Options) do
			if not SearchText or SearchText == "" or string.find(string.lower(val), string.lower(SearchText), 1, true) then
				table.insert(FilteredOptions, { index = i, value = val })
			end
		end
		for order, data in ipairs(FilteredOptions) do
			local i, val = data.index, data.value
			local isSelected = table.find(SelectedIndices, i) ~= nil
			local Item = Creator("Frame", {
				Name = "Item_" .. i,
				BackgroundColor3 = Color3.fromRGB(22, 22, 32),
				BackgroundTransparency = isSelected and 0.3 or 0.55,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = order,
				ZIndex = 12,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Creator("UIStroke",
					{
						Color = Color3.fromRGB(192, 132, 252),
						Transparency = isSelected and 0.55 or
						0.90,
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					}),
				}
			}, DDScrollFrame)

			local SelPip = Creator("Frame", {
				BackgroundColor3 = Color3.fromRGB(192, 132, 252),
				BackgroundTransparency = isSelected and 0 or 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 6, 0.5, 0),
				Size = UDim2.new(0, 3, 0, 14),
				ZIndex = 13,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Creator("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(216, 180, 254)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246)),
						}),
						Rotation = 90,
					}),
				}
			}, Item)

			local ItemLabel = Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 16, 0, 0),
				Size = UDim2.new(1, -24, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = val,
				TextSize = 12,
				TextColor3 = isSelected and Color3.fromRGB(216, 180, 254) or
				Color3.fromRGB(190, 190, 205),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 13,
			}, Item)

			local CheckMark
			if MultiMode then
				CheckMark = Creator("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
					Font = Enum.Font.GothamBold,
					Text = isSelected and "★" or "",
					TextSize = 11,
					TextColor3 = Color3.fromRGB(192, 132, 252),
					ZIndex = 13,
				}, Item)
			end

			local ItemBtn = Creator("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				ZIndex = 14,
			}, Item)

			ItemBtn.MouseEnter:Connect(function()
			UISettings:Tween(Item, { BackgroundTransparency = 0.35 }, 0.15)
			UISettings:Tween(ItemLabel, { TextColor3 = Color3.fromRGB(230, 220, 255) }, 0.15)
		end)
		ItemBtn.MouseLeave:Connect(function()
		local sel = table.find(SelectedIndices, i) ~= nil
		UISettings:Tween(Item, { BackgroundTransparency = sel and 0.3 or 0.55 }, 0.15)
		UISettings:Tween(ItemLabel,
		{ TextColor3 = sel and Color3.fromRGB(216, 180, 254) or Color3.fromRGB(190, 190, 205) },
		0.15)
	end)

	ItemBtn.MouseButton1Click:Connect(function()
	CircleClick(Item, Mouse.X, Mouse.Y)
	if MultiMode then
		local nowSelected
		if table.find(SelectedIndices, i) then
			RemoveIndex(i); nowSelected = false
		else
			AddIndex(i); nowSelected = true
		end
		UISettings:Tween(SelPip, { BackgroundTransparency = nowSelected and 0 or 1 }, 0.2)
		UISettings:Tween(Item, { BackgroundTransparency = nowSelected and 0.3 or 0.55 }, 0.2)
		UISettings:Tween(ItemLabel,
		{
			TextColor3 = nowSelected and Color3.fromRGB(216, 180, 254) or
			Color3.fromRGB(190, 190, 205)
		}, 0.2)
		if CheckMark then CheckMark.Text = nowSelected and "✓" or "" end
		local selected = SelectedValues()
		SelectedText.Text = FormatSelection(selected, 2)
		if SaveKey and (not Locked or F.HasKeyAccess()) then SaveSystem:ElementSave(SaveKey, selected) end
		Callback(selected)
	else
		table.clear(SelectedIndices)
		table.insert(SelectedIndices, i)
		SelectedText.Text = Options[i]
		if SaveKey and (not Locked or F.HasKeyAccess()) then
			SaveSystem:ElementSave(SaveKey,
			Options[i])
		end
		Callback(Options[i])
		CloseDialog()
	end
end)
end
if MultiMode then
	SelectedText.Text = FormatSelection(SelectedValues(), 2)
else
	SelectedText.Text = Options[SelectedIndices[1]] or "None"
end
end

local function OpenDialog()
	DDSearchBox.Text = ""
	RefreshOptions()
	local iconPos = GetRelativePosition(DropIcon, Body)
	local iconSize = DropIcon.AbsoluteSize
	DialogBackground.Position = iconPos
	DialogBackground.Size = UDim2.new(0, iconSize.X, 0, iconSize.Y)
	DialogBackground.Visible = true
	Blocker.Visible = true
	UISettings:Tween(DialogBackground,
	{ Position = UDim2.new(0.5, 0, 0.5, 0), Size = DialogFinalSize }, 0.32, Enum.EasingStyle
	.Quint, Enum.EasingDirection.Out)
	UISettings:Tween(DropIcon, { Rotation = 180 }, 0.25, Enum.EasingStyle.Quint)
	UISettings:Tween(GlowStroke, { Transparency = 0.40 }, 0.2)
end

DDSearchBox:GetPropertyChangedSignal("Text"):Connect(function() RefreshOptions(DDSearchBox.Text) end)
DropIcon.MouseButton1Click:Connect(OpenDialog)
DDCloseButton.MouseButton1Click:Connect(CloseDialog)
Blocker.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then CloseDialog() end
end)
Callback(MultiMode and SelectedValues() or Options[SelectedIndices[1]] or "None")
if Locked and SaveKey then
	table.insert(ToggleRegistry, {
		saveKey = SaveKey,
		UpdateFn = function()
		table.clear(SelectedIndices)
		local function SetAdd(val)
			if #Options < 1 then return end
			local idx = type(val) == "number" and math.clamp(val, 1, #Options)
			or type(val) == "string" and table.find(Options, val)
			if idx then AddIndex(idx) end
		end
		if F.HasKeyAccess() then
			local saved = SaveSystem:Get(SaveKey, nil)
			if MultiMode then
				if typeof(saved) == "table" then
					for _, v in ipairs(saved) do SetAdd(v) end
				end
				if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
				SelectedText.Text = FormatSelection(SelectedValues(), 2)
				Callback(SelectedValues())
			else
				local idx = saved and table.find(Options, saved)
				if idx then AddIndex(idx) else SetAdd(Default) end
				if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
				SelectedText.Text = Options[SelectedIndices[1]] or "None"
				Callback(Options[SelectedIndices[1]] or "None")
			end
		else
			if MultiMode then
				if typeof(Default) == "table" then
					for _, v in ipairs(Default) do SetAdd(v) end
				else
					SetAdd(Default)
				end
				if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
				SelectedText.Text = FormatSelection(SelectedValues(), 2)
				Callback(SelectedValues())
			else
				SetAdd(Default)
				if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
				SelectedText.Text = Options[SelectedIndices[1]] or "None"
				Callback(Options[SelectedIndices[1]] or "None")
			end
		end
	end
})
end

if SaveKey then
	SaveSystem:RegisterControl(SaveKey, {
		Type = "Dropdown",
		Default = Default,
		Set = function(val, fireCb)
		if MultiMode then
			table.clear(SelectedIndices)
			if type(val) == "table" then
				for _, item in ipairs(val) do
					local idx = table.find(Options, item)
					if idx then AddIndex(idx) end
				end
			end
			SelectedText.Text = FormatSelection(SelectedValues(), 2)
			if fireCb ~= false then pcall(Callback, SelectedValues()) end
		else
			table.clear(SelectedIndices)
			local idx = (type(val) == "string" and table.find(Options, val)) or (type(val) == "number" and val)
			if idx and Options[idx] then
				table.insert(SelectedIndices, idx)
				SelectedText.Text = Options[idx]
				if fireCb ~= false then pcall(Callback, Options[idx]) end
			end
		end
	end,
	Get = function() return MultiMode and SelectedValues() or (Options[SelectedIndices[1]] or "None") end,
})
end

RegisterKeyLocked(DropdownFrame, Locked)
RegisterTranslatable(DropTitle, Title)
return {
	Clear = function()
	for _, v in ipairs(DDScrollFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
	SelectedIndices = {}
	FilteredOptions = {}
	SelectedText.Text = "None"
	Callback(MultiMode and {} or "None")
end,
Refresh = function(_, NewOptions)
NewOptions = NewOptions or {}
Options = NewOptions
local prev = SelectedValues()
table.clear(SelectedIndices)
local function ReAdd(val)
	if val then
		local idx = table.find(Options, val)
		if idx then AddIndex(idx) end
	end
end
if MultiMode then
	for _, v in ipairs(prev) do ReAdd(v) end
	if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
else
	ReAdd(prev[1])
	if #SelectedIndices == 0 and #Options > 0 then AddIndex(1) end
end
SelectedText.Text = MultiMode and FormatSelection(SelectedValues(), 2) or
(Options[SelectedIndices[1]] or "None")
RefreshOptions(DDSearchBox.Text)
end,
}
end

Funcs.AddDropdown = Funcs.addDropdown
end

return DropdownModule
