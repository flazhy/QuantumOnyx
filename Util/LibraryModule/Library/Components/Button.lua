local ButtonModule = {}

function ButtonModule.Attach(Funcs, Context)
	local Creator = Context.Creator
	local UISettings = Context.UISettings
	local RegisterKeyLocked = Context.RegisterKeyLocked
	local CircleClick = Context.CircleClick
	local Mouse = Context.Mouse
	local InnerSection = Context.InnerSection
	local RegisterThemeElement = Context.RegisterThemeElement
	local ThemeColor = Context.ThemeColor
	local CheckCondition = Context.CheckCondition or Context.CheckCondition
	local DummyObj = Context.DummyObj or Context.DummyObj
	local RegisterElement = Context.RegisterElement
	local RegisterTranslatable = Context.RegisterTranslatable
	local MakeTextConstraint = Context.MakeTextConstraint

	function Funcs:AddButton(Title, Callback, Locked, Condition, LiteAllowed)
		if not CheckCondition(Condition) then return DummyObj end
		Callback = Callback or function() end

		local MainButton = Creator("TextButton", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -25, 0, 32),
			AutoButtonColor = false,
			Text = "",
			ClipsDescendants = true,
			Parent = InnerSection,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Creator("TextLabel", {
					Name = "ButtonLabel",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -36, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(210, 210, 220),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = false,
					TextScaled = true,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 3,
					["Children"] = { MakeTextConstraint(15, 8) }
				}),
				Creator("TextLabel", {
					Name = "Arrow",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
					Font = Enum.Font.GothamBold,
					Text = "›",
					TextColor3 = Color3.fromRGB(192, 132, 252),
					TextScaled = true,
					ZIndex = 3,
				}),
			}
		})

		if RegisterElement then RegisterElement(MainButton, Title) end
		local Arrow = MainButton:FindFirstChild("Arrow")
		local ButtonLabel = MainButton:FindFirstChild("ButtonLabel")
		if RegisterTranslatable then RegisterTranslatable(ButtonLabel, Title) end

		MainButton.MouseEnter:Connect(function()
			UISettings:Tween(MainButton, { BackgroundTransparency = 0.28 }, 0.2, Enum.EasingStyle.Quint)
			UISettings:Tween(ButtonLabel, { TextColor3 = Color3.fromRGB(235, 235, 245) }, 0.2)
			UISettings:Tween(Arrow, { Position = UDim2.new(1, -9, 0.5, 0), TextColor3 = Color3.fromRGB(216, 180, 254) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)

		MainButton.MouseLeave:Connect(function()
			UISettings:Tween(MainButton, { BackgroundTransparency = 0.4 }, 0.25, Enum.EasingStyle.Quint)
			UISettings:Tween(ButtonLabel, { TextColor3 = Color3.fromRGB(210, 210, 220) }, 0.25)
			UISettings:Tween(Arrow, { Position = UDim2.new(1, -12, 0.5, 0), TextColor3 = Color3.fromRGB(192, 132, 252) }, 0.25, Enum.EasingStyle.Quint)
		end)

		MainButton.MouseButton1Click:Connect(function()
			CircleClick(MainButton, Mouse.X, Mouse.Y)
			UISettings:Tween(Arrow, { Position = UDim2.new(1, -6, 0.5, 0) }, 0.1, Enum.EasingStyle.Quart)
			task.delay(0.1, function()
				UISettings:Tween(Arrow, { Position = UDim2.new(1, -9, 0.5, 0) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end)
			Callback()
		end)

		RegisterKeyLocked(MainButton, Locked)
	end

	Funcs.addButton = Funcs.AddButton; Funcs.AddButton = Funcs.AddButton
end

return ButtonModule
