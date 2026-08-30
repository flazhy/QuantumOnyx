local ButtonGridModule = {}

function ButtonGridModule.Attach(Funcs, Context)
	local Creator, UISettings, RegisterKeyLocked, CircleClick, Mouse, InnerSection, RegisterThemeElement, ThemeColor, CheckCondition, DummyObj, F = Context.Creator, Context.UISettings, Context.RegisterKeyLocked, Context.CircleClick, Context.Mouse, Context.InnerSection, Context.RegisterThemeElement, Context.ThemeColor, Context.CheckCondition, Context.DummyObj, Context.F

	function Funcs:addButtonGrid(Title, Buttons)
		Buttons = Buttons or {}

		local rows = math.ceil(#Buttons / 3)
		local totalH = 8 + ((Title and Title ~= "") and 26 or 0) + (rows * 26 + math.max(rows - 1, 0) * 4) +
		8

		local GridFrame = Creator("Frame", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -25, 0, totalH),
			ClipsDescendants = true,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			}
		}, InnerSection)

		RegisterElement(GridFrame, Title or "ButtonGrid")

		if Title and Title ~= "" then
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 8),
				Size = UDim2.new(1, -20, 0, 20),
				Font = Enum.Font.GothamBold,
				Text = Title,
				TextColor3 = Color3.fromRGB(210, 200, 230),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
			}, GridFrame)
		end

		for idx, btnData in ipairs(Buttons) do
			local col = (idx - 1) % 3
			local row = math.floor((idx - 1) / 3)
			local isLocked = btnData.Locked == true

			local Btn = Creator("TextButton", {
				BackgroundColor3 = isLocked and Color3.fromRGB(30, 18, 50) or Color3.fromRGB(55, 28, 100),
				BackgroundTransparency = isLocked and 0.55 or 0.30,
				BorderSizePixel = 0,
				Position = UDim2.new(col / 3, col == 0 and 10 or 2, 0,
				8 + ((Title and Title ~= "") and 26 or 0) + row * 30),
				Size = UDim2.new(1 / 3, col == 0 and -12 or col == 2 and -12 or -4, 0, 26),
				AutoButtonColor = false,
				ClipsDescendants = true,
				Text = "",
				ZIndex = 3,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 3) }),
					Creator("TextLabel", {
						Name = "BtnLabel",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, isLocked and -18 or -4, 1, 0),
						Position = UDim2.new(0, 2, 0, 0),
						Font = Enum.Font.GothamBold,
						Text = btnData.Label or ("Button " .. idx),
						TextColor3 = isLocked and Color3.fromRGB(130, 110, 160) or
						Color3.fromRGB(210, 185, 255),
						TextScaled = true,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 4,
						["Children"] = {
							MakeTextConstraint(12, 8)
						}
					}),
				}
			}, GridFrame)

			if isLocked then
				Creator("ImageLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -4, 0.5, 0),
					Size = UDim2.new(0, 10, 0, 10),
					Image = "rbxassetid://7733992528",
					ImageColor3 = Color3.fromRGB(140, 110, 190),
					ImageTransparency = 0.3,
					ZIndex = 5,
				}, Btn)
			end
			local label = Btn:FindFirstChild("BtnLabel")
			if isLocked then
				Btn.MouseButton1Click:Connect(function()
				CircleClick(Btn, Mouse.X, Mouse.Y)
				if typeof(btnData.LockedCallback) == "function" then
					btnData.LockedCallback()
				else
					Library.Notification:Notify({
						Title = "Locked",
						Description = (btnData.Label or "This button") .. " is currently Locked.",
					}, { Time = 2 })
				end
			end)
		else
			Btn.MouseEnter:Connect(function()
			UISettings:Tween(Btn, { BackgroundTransparency = 0.10 }, 0.15, Enum.EasingStyle.Quint)
			if label then
				UISettings:Tween(label, { TextColor3 = Color3.fromRGB(235, 220, 255) }, 0.15)
			end
		end)
		Btn.MouseLeave:Connect(function()
		UISettings:Tween(Btn, { BackgroundTransparency = 0.30 }, 0.20, Enum.EasingStyle.Quint)
		if label then
			UISettings:Tween(label, { TextColor3 = Color3.fromRGB(210, 185, 255) }, 0.20)
		end
	end)
	Btn.MouseButton1Click:Connect(function()
	CircleClick(Btn, Mouse.X, Mouse.Y)
	if typeof(btnData.Callback) == "function" then
		btnData.Callback()
	end
end)
end
end
return GridFrame
end

Funcs.AddButtonGrid = Funcs.addButtonGrid
end

return ButtonGridModule
