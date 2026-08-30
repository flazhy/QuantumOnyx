local Core = nil
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
local Mouse = (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:GetMouse()) or { X = 0, Y = 0 }

local Notification = {
	GUI = nil,
	Container = nil,
	ActiveMessages = {}
}

function Notification.Init(CoreMod)
	Core = CoreMod or Core
	local Util = Core.Util
	local Creator = Util.Create

	if not Notification.GUI then
		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = Util.RandomName()
		ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ScreenGui.ResetOnSpawn = false
		Util.Protect(ScreenGui)

		Notification.GUI = ScreenGui
		Notification.Container = Creator("Frame", {
			Name = "NotificationContainer",
			Parent = ScreenGui,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -20, 1, -20),
			AnchorPoint = Vector2.new(1, 1),
			Size = UDim2.new(0, 320, 1, -40),
			Children = {
				Creator("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 10)
				})
			}
		})
	end
end

function Notification:Notify(NofDebug, MiddleDebug)
	if not self.GUI then
		Notification.Init(Core)
	end
	assert(self.GUI, "Notification GUI not initialized. Call :Init() first.")
	NofDebug = NofDebug or {}
	MiddleDebug = MiddleDebug or {}

	local Util = Core.Util
	local Tw = Core.Tween
	local Creator = Util.Create
	local ThemeColor = Core.Theme.Color

	local Title = NofDebug.Title or "Notification"
	local Description = NofDebug.Description or ""
	local DisplayTime = MiddleDebug.Time or 5

	local RawButtons = NofDebug.Buttons or NofDebug.Button
	local ButtonsList = {}

	if type(RawButtons) == "string" then
		table.insert(ButtonsList, { Text = RawButtons, Callback = NofDebug.Callback })
	elseif type(RawButtons) == "table" then
		if RawButtons.Text or RawButtons.Name or RawButtons.Title then
			table.insert(ButtonsList, {
				Text = RawButtons.Text or RawButtons.Name or RawButtons.Title or "Okay",
				Callback = RawButtons.Callback or RawButtons.OnClick or RawButtons.Function,
				Primary = RawButtons.Primary or RawButtons.IsPrimary,
			})
		else
			local IsArray = #RawButtons > 0
			if IsArray then
				for _, Btn in ipairs(RawButtons) do
					if type(Btn) == "string" then
						table.insert(ButtonsList, { Text = Btn })
					elseif type(Btn) == "table" then
						table.insert(ButtonsList, {
							Text = Btn.Text or Btn.Name or Btn.Title or "Button",
							Callback = Btn.Callback or Btn.OnClick or Btn.Function,
							Primary = Btn.Primary or Btn.IsPrimary,
						})
					end
				end
			else
				for Name, Cb in pairs(RawButtons) do
					table.insert(ButtonsList, {
						Text = tostring(Name),
						Callback = type(Cb) == "function" and Cb or (type(Cb) == "table" and (Cb.Callback or Cb.OnClick or Cb.Function)),
						Primary = type(Cb) == "table" and (Cb.Primary or Cb.IsPrimary),
					})
				end
			end
		end
	end

	local HasButtons = #ButtonsList > 0
	local HasDescription = Description and Description ~= ""

	local CooldownLabel = Creator("TextLabel", {
		Name = "CooldownLabel",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 36, 0, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0, 15),
		Font = Enum.Font.Gotham,
		Text = "(" .. DisplayTime .. "s)",
		TextColor3 = Color3.fromRGB(150, 150, 160),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 22
	})

	local ProgressBar = Creator("Frame", {
		Name = "ProgressBar",
		BackgroundColor3 = ThemeColor("Accent"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 22,
		Children = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 2) })
		}
	})

	local ProgressBarBackground = Creator("Frame", {
		Name = "ProgressBarBackground",
		BackgroundColor3 = Color3.fromRGB(30, 30, 42),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 1, -4),
		Size = UDim2.new(1, -24, 0, 2),
		ZIndex = 21,
		Children = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 2) }),
			ProgressBar
		}
	})

	local ButtonContainer = nil
	local CreatedButtons = {}

	if HasButtons then
		local BtnRowChildren = {
			Creator("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 6)
			})
		}

		ButtonContainer = Creator("Frame", {
			Name = "ButtonContainer",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 1, -34),
			Size = UDim2.new(1, -24, 0, 24),
			ZIndex = 22,
			Children = BtnRowChildren
		})

		local NumButtons = #ButtonsList
		local TotalSpacing = (NumButtons - 1) * 6
		local BtnWidthScale = 1 / NumButtons
		local BtnWidthOffset = -math.floor(TotalSpacing / NumButtons)

		for Idx, BtnData in ipairs(ButtonsList) do
			local BtnText = BtnData.Text or "Button"
			local IsPrimary = BtnData.Primary or (Idx == 1)

			local BtnBg = IsPrimary and ThemeColor("Accent") or Color3.fromRGB(30, 30, 42)
			local BtnTextCol = IsPrimary and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)

			local BtnStroke = Creator("UIStroke", {
				Color = IsPrimary and ThemeColor("Accent") or Color3.fromRGB(50, 50, 65),
				Thickness = 1,
				Transparency = 0.3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			})

			local ButtonObj = Creator("TextButton", {
				Name = "Btn_" .. Idx,
				BackgroundColor3 = BtnBg,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = UDim2.new(BtnWidthScale, BtnWidthOffset, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = BtnText,
				TextColor3 = BtnTextCol,
				TextSize = 11,
				AutoButtonColor = false,
				ClipsDescendants = true,
				ZIndex = 23,
				Parent = ButtonContainer,
				Children = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
					BtnStroke
				}
			})

			table.insert(CreatedButtons, {
				Instance = ButtonObj,
				Stroke = BtnStroke,
				DefaultBg = BtnBg,
				IsPrimary = IsPrimary
			})
		end
	end

	local NotifChildren = {
		Creator("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Creator("UIStroke", {
			Color = Color3.fromRGB(55, 55, 75),
			Thickness = 1,
			Transparency = 0.4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		}),
		Creator("TextLabel", {
			Name = "TitleLabel",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 6),
			Size = UDim2.new(1, -55, 0, 18),
			Font = Enum.Font.GothamBold,
			Text = Title,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 22
		}),
		CooldownLabel,
		ProgressBarBackground
	}
	if ButtonContainer then
		table.insert(NotifChildren, ButtonContainer)
	end

	local NotificationFrame = Creator("Frame", {
		Name = "NotificationFrame",
		BackgroundColor3 = Color3.fromRGB(18, 18, 26),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 72),
		ZIndex = 20,
		Children = NotifChildren
	})

	if HasDescription then
		Creator("TextLabel", {
			Name = "DescLabel",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 24),
			Size = UDim2.new(1, -24, 0, 24),
			Font = Enum.Font.Gotham,
			Text = Description,
			TextColor3 = Color3.fromRGB(180, 180, 195),
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 22,
			Parent = NotificationFrame
		})
	end

	NotificationFrame.Parent = self.Container
	Tw.Play(ProgressBar, { Size = UDim2.new(0, 0, 1, 0) }, DisplayTime, Enum.EasingStyle.Linear)

	local IsDismissed = false
	local function DismissNotification()
		if IsDismissed then return end
		IsDismissed = true
		Tw.Play(NotificationFrame, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
			NotificationFrame:Destroy()
		end)
	end

	for Idx, B in ipairs(CreatedButtons) do
		local BtnInst = B.Instance
		local BtnData = ButtonsList[Idx]

		BtnInst.MouseButton1Click:Connect(function()
			if IsDismissed then return end
			if type(BtnData.Callback) == "function" then
				task.spawn(function()
					local Ok, Err = pcall(BtnData.Callback)
					if not Ok then warn("[Notification Callback Error]: " .. tostring(Err)) end
				end)
			end
			task.spawn(DismissNotification)
		end)
	end

	task.spawn(function()
		for I = DisplayTime, 1, -1 do
			if IsDismissed then break end
			if CooldownLabel and CooldownLabel.Parent then CooldownLabel.Text = "(" .. I .. "s)" end
			task.wait(1)
		end
	end)

	task.delay(DisplayTime, function()
		if not IsDismissed then
			DismissNotification()
		end
	end)
end

return Notification
