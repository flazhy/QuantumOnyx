local LocalizationService = game:GetService("LocalizationService")
local http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TweenInfo = TweenInfo.new

local Library = {}
local UISettings = {}

local CoreGui = (game:GetService("RunService"):IsStudio() and LocalPlayer.PlayerGui) or (gethui() or game:GetService("CoreGui"):Clone())

local function CreateInstance(class, properties, parent)
	local instance = Instance.new(class)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function ApplyUIStroke(parent, color, transparency, size, mode)
	return CreateInstance("UIStroke", {
		Parent = parent,
		Color = color,
		Transparency = transparency,
		Thickness = size or 1,
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	}, parent)
end

function UISettings:Tween(instance, properties, duration, ...)
	TweenService:Create(instance, TweenInfo(duration, ...), properties):Play()
end

function Library:DestroyGui(Name)
	local gui = CoreGui:FindFirstChild(Name)
	if gui then gui:Destroy() end
end

local function HoverEffect(button, enterProps, leaveProps)
	button.MouseEnter:Connect(function()
		UISettings:Tween(button, enterProps, 0.15)
	end)
	button.MouseLeave:Connect(function()
		UISettings:Tween(button, leaveProps, 0.15)
	end)
end

function CircleClick(Button, X, Y)
	spawn(function()
		Button.ClipsDescendants = true
		local Circle = Instance.new("ImageLabel")
		Circle.Image = "rbxassetid://266543268"
		Circle.ImageColor3 = Color3.fromRGB(80, 80, 80)
		Circle.ImageTransparency = 0.8999999761581421
		Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Circle.BackgroundTransparency = 1
		Circle.ZIndex = 10
		Circle.Name = "Circle"
		Circle.Parent = Button
		local NewX = X - Circle.AbsolutePosition.X
		local NewY = Y - Circle.AbsolutePosition.Y
		Circle.Position = UDim2.new(0, NewX, 0, NewY)
		local Size = 0
		if Button.AbsoluteSize.X > Button.AbsoluteSize.Y then
			Size = Button.AbsoluteSize.X * 1.5
		elseif Button.AbsoluteSize.X < Button.AbsoluteSize.Y then
			Size = Button.AbsoluteSize.Y * 1.5
		elseif Button.AbsoluteSize.X == Button.AbsoluteSize.Y then
			Size = Button.AbsoluteSize.X * 1.5
		end

		local Time = 0.5
		Circle:TweenSizeAndPosition(UDim2.new(0, Size, 0, Size), UDim2.new(0.5, -Size/2, 0.5, -Size/2), "Out", "Quad", Time, false, nil)
		for _ = 1, 10 do
			Circle.ImageTransparency = Circle.ImageTransparency + 0.01
			wait(Time/10)
		end
		Circle:Destroy()
	end)
end

function Library:CreateWindow(namehub)
	self:DestroyGui(namehub)

	local ScreenGui = CreateInstance("ScreenGui", {
		Name = namehub,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, CoreGui)

	local Body = CreateInstance("Frame", {
		Name = "Body",
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -275, 0.5, -175),
		Size = UDim2.new(0, 550, 0, 350),
		ClipsDescendants = true
	}, ScreenGui)

	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 20) }, Body)

	CreateInstance("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 20)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(17, 17, 17)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(20, 20, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 0, 13))
		},
		Rotation = 45
	}, Body)


	local TopFrame = CreateInstance("Frame", {
		Name = "TopFrame",
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 30),
		ClipsDescendants = true
	}, Body)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, TopFrame)

	CreateInstance("TextLabel", {
		Name = "TitleHub",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 5, 0, 0),
		Size = UDim2.new(0, 558, 0, 30),
		Font = Enum.Font.FredokaOne,
		Text = "    " .. namehub .. " Project",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Body)

	CreateInstance("TextLabel", {
		Name = "FPSCounter",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 170, 0, 0),
		Size = UDim2.new(0, 50, 0, 30),
		Font = Enum.Font.FredokaOne,
		Text = "FPS: ",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Body)

	local FPSValue = CreateInstance("TextLabel", {
		Name = "FPSValue",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 200, 0, 0),
		Size = UDim2.new(0, 30, 0, 30),
		Font = Enum.Font.FredokaOne,
		Text = "0",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Body)

	local fps = 0
	local lastTime = tick()
	local Runser = game:GetService("RunService")
	local rs = Runser.RenderStepped

	rs:Connect(function()
		local currentTime = tick()
		local deltaTime = currentTime - lastTime
		lastTime = currentTime
		fps = 1 / deltaTime
	end)

	task.defer(function()
		while wait(0.5) do
			pcall(function()
				if fps >= 35 then
					FPSValue.TextColor3 = Color3.fromRGB(11, 192, 57)
				elseif fps >= 15 then
					FPSValue.TextColor3 = Color3.fromRGB(195, 163, 0)
				else
					FPSValue.TextColor3 = Color3.fromRGB(195, 0, 3)
				end
				FPSValue.Text = string.format("%.0f", fps)
			end)
		end
	end)

	local MinimizeButton = CreateInstance("ImageButton", {
		Name = "Minimize_Button",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 490, 0, 4),
		Size = UDim2.new(0, 20, 0, 20),
		Image = "rbxassetid://92966930061759",
	}, Body)

	local CloseButton = CreateInstance("ImageButton", {
		Name = "Close_Button",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 520, 0, 2),
		Size = UDim2.new(0, 22, 0, 22),
		Image = "rbxassetid://79324227570635",
	}, Body)


	local Tiktok = CreateInstance("TextButton", {
		Name = "Tiktok",
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		Position = UDim2.new(0, 400, 0, 2),
		Size = UDim2.new(0, 85, 0, 25),
		Text = "",
		AutoButtonColor = false
	}, Body)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, Tiktok)
	ApplyUIStroke(Tiktok, Color3.fromRGB(255, 255, 255), 0.8, 1, Enum.ApplyStrokeMode.Border)

	CreateInstance("ImageLabel", {
		Name = "TiktokLogo",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 2),
		Size = UDim2.new(0, 20, 0, 20),
		Image = "http://www.roblox.com/asset/?id=14620084334"
	}, Tiktok)

	CreateInstance("TextLabel", {
		Name = "TiktokTitle",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 35, 0, 0),
		Size = UDim2.new(0, 40, 0, 25),
		Font = Enum.Font.GothamBold,
		Text = "Tiktok",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Tiktok)


	Tiktok.MouseButton1Click:Connect(function()
		CircleClick(Tiktok, Mouse.X, Mouse.Y);
		(setclipboard or toclipboard)("https://www.tiktok.com/@trustmenotcondom?_t=ZS-8syewdU3Bxq&_r=1")
		wait(.1)
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Tiktok",
			Text = "Tiktok copied on your clipboard",
			Button1 = "Okay",
			Duration = 20
		})
	end)

	local Discord = CreateInstance("TextButton", {
		Name = "Discord",
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		Position = UDim2.new(0, 310, 0, 2),
		Size = UDim2.new(0, 85, 0, 25),
		Text = "",
		AutoButtonColor = false
	}, Body)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, Discord)
	ApplyUIStroke(Discord, Color3.fromRGB(255, 255, 255), 0.8, 1, Enum.ApplyStrokeMode.Border)

	CreateInstance("ImageLabel", {
		Name = "DiscordLogo",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 2),
		Size = UDim2.new(0, 20, 0, 20),
		Image = "http://www.roblox.com/asset/?id=129297846250682"
	}, Discord)

	CreateInstance("TextLabel", {
		Name = "DiscTitle",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 35, 0, 0),
		Size = UDim2.new(0, 40, 0, 25),
		Font = Enum.Font.GothamBold,
		Text = "Discord",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	}, Discord)

	Discord.MouseButton1Click:Connect(function()
		CircleClick(Discord, Mouse.X, Mouse.Y);
		(setclipboard or toclipboard)("https://discord.gg/2qMwBeAtsd")
		wait(.1)
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Discord",
			Text = "Discord copied on your clipboard",
			Button1 = "Okay",
			Duration = 20
		})
	end)

	local ListTile = CreateInstance("Frame", {
		Name = "ListTile",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 0, 2)
	}, Body)

	CreateInstance("UIGradient", {
		Name = "TileGradient",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 117, 83)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(25, 16, 42)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(53, 35, 90)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 117, 83)),
		})
	}, ListTile)

	local ToggleClose = CreateInstance("Frame", {
		Name = "Toggle",
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.0160791595, 0, 0.219451368, 0),
		Size = UDim2.new(0, 40, 0, 40),
		Draggable = true
	}, ScreenGui)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleClose)

	local ToggleLogo = CreateInstance("ImageButton", {
		Name = "ToggleLogo",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 40, 0, 40),
		Image = "rbxassetid://80812231439203",
		Draggable = true
	}, ToggleClose)

	local Minimized = false
	MinimizeButton.MouseButton1Click:Connect(function()
		if Minimized then
			UISettings:Tween(Body, {Size = UDim2.new(0, 550, 0, 350)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			MinimizeButton.Image = "rbxassetid://92966930061759"
			MinimizeButton.Position = UDim2.new(0, 490, 0, 4)
			ToggleLogo.Visible = true
			Minimized = false
		else
			UISettings:Tween(Body, {Size = UDim2.new(0, 260, 0, 30)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			MinimizeButton.Position = UDim2.new(0, 230, 0, 4)
			MinimizeButton.Image = "rbxassetid://124967485209478"
			ToggleLogo.Visible = false
			Minimized = true
		end
	end)


	local BlurOverlay = CreateInstance("Frame", {
		Name = "BlurOverlay",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.2,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 9
	}, Body)

	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 20) }, BlurOverlay)
	ApplyUIStroke(BlurOverlay, Color3.fromRGB(255, 255, 255), 0.8, 1)

	local Dialog = CreateInstance("Frame", {
		Name = "ComfirmDialog",
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		BackgroundTransparency = 0.1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.5, 0, 0.4, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Visible = false,
		ZIndex = 10
	}, Body)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 10) }, Dialog)
	ApplyUIStroke(Dialog, Color3.fromRGB(255, 255, 255), 0.8, 1)

	CreateInstance("TextLabel", {
		Name = "DialogTitle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0.6, 0),
		Position = UDim2.new(0, 10, 0, 10),
		Text = "Are you sure you want to destroy this?",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.SourceSans,
		TextWrapped = true,
		TextSize = 18,
		ZIndex = 11,
	}, Dialog)

	local ComfirmDialog = CreateInstance("TextButton", {
		Name = "ConfirmButton",
		BackgroundColor3 = Color3.fromRGB(34, 33, 33),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0.4, -10, 0.2, 0),
		Position = UDim2.new(0.1, 0, 0.7, 0),
		Text = "Yes",
		Font = Enum.Font.SourceSans,
		TextSize = 16,
		ZIndex = 11
	}, Dialog)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, ComfirmDialog)
	ApplyUIStroke(ComfirmDialog, Color3.fromRGB(255, 255, 255), 0.8, 1, Enum.ApplyStrokeMode.Border)

	local CancelDialog = CreateInstance("TextButton", {
		Name = "CancelButton",
		BackgroundColor3 = Color3.fromRGB(34, 33, 33),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0.4, -10, 0.2, 0),
		Position = UDim2.new(0.5, 10, 0.7, 0),
		Text = "No",
		Font = Enum.Font.SourceSans,
		TextSize = 16,
		ZIndex = 11
	}, Dialog)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, CancelDialog)
	ApplyUIStroke(CancelDialog, Color3.fromRGB(255, 255, 255), 0.8, 1, Enum.ApplyStrokeMode.Border)

	local function Center()
		Dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
	end
	Center()

	Body:GetPropertyChangedSignal("Size"):Connect(Center)
	Body:GetPropertyChangedSignal("Position"):Connect(Center)

	CloseButton.MouseButton1Click:Connect(function()
		BlurOverlay.Visible = true
		Dialog.Visible = true
	end)
	ComfirmDialog.MouseButton1Click:Connect(function()
		BlurOverlay.Visible = false
		self:DestroyGui(namehub)
	end)
	CancelDialog.MouseButton1Click:Connect(function()
		BlurOverlay.Visible = false
		Dialog.Visible = false
	end)

	local isMinimized = false
	local centerPosition = Body.Position

	ToggleLogo.MouseButton1Click:Connect(function()
		if isMinimized then
			UISettings:Tween(Body, {Size = UDim2.new(0, 550, 0, 350), Position = centerPosition, BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		else
			UISettings:Tween(Body, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1}, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		isMinimized = not isMinimized
	end)


	local dragging = false
	local dragInput, startPos, objectPos

	TopFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = input.Position
			objectPos = Body.Position

			local connection
			connection = RunService.Heartbeat:Connect(function()
				if not dragging then
					connection:Disconnect()
					return
				end

				if dragInput then
					local delta = dragInput.Position - startPos
					Body.Position = UDim2.new(
						objectPos.X.Scale, objectPos.X.Offset + delta.X,
						objectPos.Y.Scale, objectPos.Y.Offset + delta.Y
					)
				end
			end)
		end
	end)

	TopFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	TopFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local TabContainer = CreateInstance("Frame", {
		Name = "Tab_Container",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 36),
		ClipsDescendants = true
	}, Body)

	local TabList = CreateInstance("Frame", {
		Name = "Tab_List",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 0, 28)
	}, TabContainer)

	CreateInstance("UIGradient", {
		Name = "TabList_Gradient",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 117, 83)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(25, 16, 42)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(53, 35, 90)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 117, 83)),
		})
	}, TabList)

	local TabScroll = CreateInstance("ScrollingFrame", {
		Name = "Tab_Scroll",
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 0, 30),
		CanvasPosition = Vector2.new(0, 150),
		ScrollBarThickness = 0
	}, TabContainer)

	local TabLayout = CreateInstance("UIListLayout", {
		Name = "Tab_Layout",
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5)
	}, TabScroll)

	TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabScroll.CanvasSize = UDim2.new(0, 0 + TabLayout.Padding.Offset + TabLayout.AbsoluteContentSize.X, 0, 0)
	end)

	TabScroll.ChildAdded:Connect(function()
		TabScroll.CanvasSize = UDim2.new(0, 0 + TabLayout.Padding.Offset + TabLayout.AbsoluteContentSize.X, 0, 0)
	end)

	local MainContainer = CreateInstance("Frame", {
		Name = "Main_Container",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 590, 0, 400),
		Position = UDim2.new(0, 5, 0, 70)
	}, Body)

	CreateInstance("UIGradient", {
		Name = "ContainerGradients",
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 24, 61)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(41, 27, 70)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(47, 31, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(29, 19, 49)),
		})
	}, MainContainer)


	local Container = CreateInstance("Folder", {
		Name = "Container"
	}, MainContainer)

	local Tabs = {}
	local FirstTab = true

	function Tabs:AddTab(Tab_Title, Tab_Icon)
		local IconMapping = {
			["cat-quantum"] = "rbxassetid://82115431450716",
			["home-quantum"] = "rbxassetid://130439434919073",
			["swords-quantum"] = "rbxassetid://88173691221304",
			["rabbit-quantum"] = "rbxassetid://138575837887336",
			["ship-quantum"] = "rbxassetid://115481449706054",
			["visual-quantum"] = "rbxassetid://102173201308116",
			["info-quantum"] = "rbxassetid://88050097561287",
			["misc-quantum"] = "rbxassetid://137985950260873",
			["cart-quantum"] = "rbxassetid://137995400175306",
			["cherry-quantum"] = "rbxassetid://122029349593217",
			["map-quantum"] = "rbxassetid://125480398387209",
			["raid-quantum"] = "rbxassetid://104575804564229",
			["user-quantum"] = "rbxassetid://83474083071373",
			["settings-quantum"] = "rbxassetid://81151604784579",
			["bio-quantum"] = "rbxassetid://132316362727024",
			["craft-quantum"] = "rbxassetid://118197342073112"
		}

		local Tab = CreateInstance("TextButton", {
			Name = "Tab_Items",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 0, 24),
			AutoButtonColor = false,
			Font = Enum.Font.FredokaOne,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 14.000,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "" .. Tab_Title
		}, TabScroll)

		CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, TabScroll)

		CreateInstance("ImageLabel", {
			Name = "Tab_Icon",
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 5, 0.5, -8),
			Image = IconMapping[Tab_Icon] or ""
		}, Tab)

		local TabUnderline = CreateInstance("Frame", {
			Name = "Tab_Underline",
			BackgroundColor3 = Color3.fromRGB(46, 32, 88),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, 0),
			Visible = false
		}, Tab)
		CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, TabUnderline)

		UISettings:Tween(Tab, { Size = UDim2.new(0, 30 + Tab.TextBounds.X, 0, 24) }, .15)

		local ScrollFrame = CreateInstance("ScrollingFrame", {
			Name = "ScrollingFrame",
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			ScrollBarThickness = 0,
			Visible = false
		}, Container)

		local ScrollLayout = CreateInstance("UIListLayout", {
			Name = "Scrolling_Layout",
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 19)
		}, ScrollFrame)

		ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ScrollFrame.CanvasSize = UDim2.new(0, ScrollLayout.AbsoluteContentSize.X, 0, 0)
		end)

		ScrollFrame.ChildAdded:Connect(function()
			ScrollFrame.CanvasSize = UDim2.new(0, ScrollLayout.AbsoluteContentSize.X, 0, 0)
		end)

		if FirstTab then
			FirstTab = false
			Tab.TextColor3 = Color3.fromRGB(255, 255, 255)
			TabUnderline.Visible = true
			ScrollFrame.Visible = true
		end

		Tab.MouseButton1Click:Connect(function()
			for _, v in next, TabScroll:GetChildren() do
				if v:IsA("TextButton") then
					v.TextColor3 = Color3.fromRGB(200, 200, 200)
					local line = v:FindFirstChild("Tab_Underline")
					if line then
						line.Visible = false
					end
				end
			end
			Tab.TextColor3 = Color3.fromRGB(255, 255, 255)
			TabUnderline.Visible = true
			for _, v in next, Container:GetChildren() do
				if v.Name == "ScrollingFrame" then
					v.Visible = false
				end
			end
			ScrollFrame.Visible = true
		end)

		local Section = {}
		function Section:addSection()

			local SectionScroll = CreateInstance("ScrollingFrame", {
				Name = "SectionScroll",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 260, 0, 270),
				ScrollBarImageColor3 = Color3.fromRGB(150, 100, 255),
				ScrollBarThickness = 3,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ClipsDescendants = true,
				ScrollingDirection = Enum.ScrollingDirection.Y 
			}, ScrollFrame)

			CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, SectionScroll)

			local SectionLayout = CreateInstance("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 7)
			}, SectionScroll)

			local function CanvasSize()
				local Height = SectionLayout.AbsoluteContentSize.Y + SectionLayout.Padding.Offset + 5
				SectionScroll.CanvasSize = UDim2.new(0, 0, 0, Height)
			end

			SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(CanvasSize)
			SectionScroll.ChildAdded:Connect(CanvasSize)
			SectionScroll.ChildRemoved:Connect(CanvasSize)

			local Menus = {}
			function Menus:addMenu(Menu_Title)
				local Section = CreateInstance("Frame", {
					Name = "Section",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.48, 0, 0, 25)
				}, SectionScroll)

				local InnerSection = CreateInstance("Frame", {
					Name = "InnerSection",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0, 0),
					Size = UDim2.new(1, -5, 0, 25)
				}, Section)


				CreateInstance("UIGradient", {
					Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 40)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 30, 30)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 0, 50))
					},
					Rotation = 90
				}, InnerSection)

				CreateInstance("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 18)),
						ColorSequenceKeypoint.new(0.3, Color3.fromRGB(18, 18, 18)),
						ColorSequenceKeypoint.new(0.7, Color3.fromRGB(18, 18, 18)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 18)),
					})
				}, InnerSection)

				local SectionListLayout = CreateInstance("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 5)
				}, InnerSection)

				CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, InnerSection)

				local TitleContainer = CreateInstance("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
				}, InnerSection)

				local Line1 = CreateInstance("Frame", {
					BackgroundColor3 = Color3.fromRGB(150, 100, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.2, 0, 0, 8),
					Position = UDim2.new(0, 0, 0.5, -1)
				}, TitleContainer);CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, Line1)
				CreateInstance("UIGradient", {
					Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 20, 80)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(28, 14, 56)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 0, 90))
					}
				}, Line1)

				local Line2 = CreateInstance("Frame", {
					BackgroundColor3 = Color3.fromRGB(150, 100, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.2, 0, 0, 8),
					Position = UDim2.new(0.8, 0, 0.5, -1)
				}, TitleContainer);CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, Line2)
				CreateInstance("UIGradient", {
					Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 20, 80)),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(28, 14, 56)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 0, 90))
					}
				}, Line2)

				CreateInstance("TextLabel", {
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.6, 0, 1, 0),
					Position = UDim2.new(0.2, 0, 0, 0),
					Font = Enum.Font.Arcade,
					Text = Menu_Title,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Center
				}, TitleContainer)

				local function SectionSize()
					local Height = SectionListLayout.AbsoluteContentSize.Y + SectionListLayout.Padding.Offset + 5
					Section.Size = UDim2.new(1, 0, 0, Height)
					InnerSection.Size = UDim2.new(1, -10, 0, Height)
				end

				SectionListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(SectionSize)
				SectionSize()

				local Funcs = {}
				function Funcs:addButton(Title_Button, callback)
					callback = callback or function() end


					local MainButton = CreateInstance("TextButton", {
						Name = "MainButton",
						BackgroundColor3 = Color3.fromRGB(26, 25, 25),
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 30),
						AutoButtonColor = false,
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(220, 220, 220),
						Text = Title_Button,
						TextScaled = true,
						ClipsDescendants = true,
					}, InnerSection)

					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, MainButton)

					CreateInstance("UITextSizeConstraint", {
						MaxTextSize = 14,
						MinTextSize = 10
					}, MainButton)

					local Gradient = CreateInstance("UIGradient", {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 50, 150)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 25, 100))
						},
						Rotation = 90
					}, MainButton)

					MainButton.MouseEnter:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
						}
					end)

					MainButton.MouseLeave:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 180))
						}
					end)

					MainButton.MouseButton1Click:Connect(function()
						CircleClick(MainButton, Mouse.X, Mouse.Y)
						callback()
					end)
				end

				function Funcs:addToggle(toggle_title, default, callback)
					callback = callback or function() end
					default = default or false

					local ToggleFrame = CreateInstance("TextButton", {
						BackgroundColor3 = Color3.fromRGB(26, 25, 25),
						Size = UDim2.new(1, -25, 0, 33),
						Position = UDim2.new(0, 5, 0, 0),
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Text = "",
						ClipsDescendants = true,
					}, InnerSection)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, ToggleFrame)

					local BGFrame = CreateInstance("Frame", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						Position = UDim2.new(1, -50, 0.5, -8),
						Size = UDim2.new(0, 36, 0, 16),
						BorderSizePixel = 0
					}, ToggleFrame)
					CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, BGFrame)
					ApplyUIStroke(BGFrame, Color3.fromRGB(180, 180, 180), 0.8, 2, Enum.ApplyStrokeMode.Border)

					local SlideButton = CreateInstance("Frame", {
						BackgroundColor3 = default and Color3.fromRGB(120, 85, 255) or Color3.fromRGB(100, 100, 100),
						Position = default and UDim2.new(1, -16, 0, 1) or UDim2.new(0, 1, 0, 1),
						Size = UDim2.new(0, 14, 1, -2),
						BorderSizePixel = 0
					}, BGFrame)
					CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, SlideButton)

					local ToggleIcon = CreateInstance("ImageLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 10, 0, 5),
						Image = "rbxassetid://109617819538646",
						ImageColor3 = Color3.fromRGB(190, 90, 255),
						Size = UDim2.new(0, 20, 0, 20)
					}, ToggleFrame)

					local ToggleTitle = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 38, 0, 5),
						Size = UDim2.new(1, -90, 0, 20),
						Font = Enum.Font.GothamBold,
						Text = toggle_title,
						TextColor3 = default and Color3.fromRGB(180, 140, 255) or Color3.fromRGB(190, 90, 255),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextScaled = true,
					}, ToggleFrame)
					CreateInstance("UITextSizeConstraint", {
						MaxTextSize = 14,
						MinTextSize = 10
					}, ToggleTitle)
					local ToggleState = default

					local function UpdateToggle()
						SlideButton:TweenPosition(ToggleState and UDim2.new(1, -16, 0, 1) or UDim2.new(0, 1, 0, 1), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.1, true)
						SlideButton.BackgroundColor3 = ToggleState and Color3.fromRGB(180, 140, 255) or Color3.fromRGB(120, 120, 120)
						ToggleTitle.TextColor3 = ToggleState and Color3.fromRGB(190, 90, 255) or Color3.fromRGB(200, 200, 200)
						ToggleIcon.ImageTransparency = ToggleState and 0 or 0.6
						callback(ToggleState)
					end

					UpdateToggle()
					local function ToggleInput()
						CircleClick(ToggleFrame, Mouse.X, Mouse.Y)
						ToggleState = not ToggleState
						UpdateToggle()
					end

					local Gradient = CreateInstance("UIGradient", {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 10, 140)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100))
						},
						Rotation = 90
					}, ToggleFrame)

					ToggleFrame.MouseEnter:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
						}
					end)

					ToggleFrame.MouseLeave:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 180))
						}
					end)
					ToggleFrame.Activated:Connect(ToggleInput)
				end


				function Funcs:addSlider(slider_title, min, max, default, callback, step)
					callback = callback or function() end
					min = min or 0
					max = max or 100
					step = step or 1
					default = math.clamp(default or min, min, max)

					local function roundToStep(val, step)
						return math.floor(val / step + 0.5) * step
					end

					local function getDecimalPlaces(step)
						local s = tostring(step)
						local dot = s:find("%.")
						return dot and #s - dot or 0
					end

					local decimalPlaces = getDecimalPlaces(step)

					local SliderFrame = CreateInstance("Frame", {
						BackgroundColor3 = Color3.fromRGB(26, 25, 25),
						Size = UDim2.new(1, -25, 0, 50),
						Position = UDim2.new(0, 5, 0, 0),
						BorderSizePixel = 0,
					}, InnerSection)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, SliderFrame)

					local SliderTitle = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -55, 0, 20),
						Position = UDim2.new(0, 5, 0, 5),
						Font = Enum.Font.GothamBold,
						Text = " "..slider_title,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(190, 90, 255),
						TextTransparency = 0.2,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextScaled = true,
					}, SliderFrame)

					CreateInstance("UITextSizeConstraint", {
						MaxTextSize = 14,
						MinTextSize = 10,
					}, SliderTitle)

					local Gradient = CreateInstance("UIGradient", {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 10, 140)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100))
						},
						Rotation = 90
					}, SliderFrame)

					SliderFrame.MouseEnter:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
						}
					end)

					SliderFrame.MouseLeave:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 180))
						}
					end)

					local ValueCount = CreateInstance("TextBox", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						Position = UDim2.new(1, -55, 0, 5),
						Size = UDim2.new(0, 45, 0, 20),
						Font = Enum.Font.Gotham,
						Text = string.format("%."..decimalPlaces.."f", default),
						TextSize = 14,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextXAlignment = Enum.TextXAlignment.Center,
						ClearTextOnFocus = false,
					}, SliderFrame)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0.4, 0) }, ValueCount)

					local BGSlider = CreateInstance("Frame", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						Position = UDim2.new(0, 5, 0, 30),
						Size = UDim2.new(1, -15, 0, 13),
					}, SliderFrame)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, BGSlider)

					local SliderFill = CreateInstance("Frame", {    
						BackgroundColor3 = Color3.fromRGB(150, 100, 255),
						Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
					}, BGSlider)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0.5, 0) }, SliderFill)

					CreateInstance("UIGradient", {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 10, 140)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100))
						},
					}, SliderFill)

					local function LiveSlider(InputPosition)
						local RelativePosition = math.clamp((InputPosition - BGSlider.AbsolutePosition.X) / BGSlider.AbsoluteSize.X, 0, 1)
						local rawValue = min + (max - min) * RelativePosition
						local value = roundToStep(rawValue, step)

						SliderFill:TweenSize(UDim2.new(RelativePosition, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
						ValueCount.Text = string.format("%." .. decimalPlaces .. "f", value)
						callback(value)
					end

					local function SetDefault()
						local RelativePosition = (default - min) / (max - min)
						SliderFill.Size = UDim2.new(RelativePosition, 0, 1, 0)
						ValueCount.Text = string.format("%." .. decimalPlaces .. "f", default)
						callback(default)
					end

					SetDefault()

					local dragging = false

					local function onInputChanged(input)
						if dragging then
							LiveSlider(input.Position.X)
						end
					end

					local function onInputBegan(input)
						if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true
							LiveSlider(input.Position.X)
						end
					end

					local function onInputEnded(input)
						if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
						end
					end

					ValueCount.FocusLost:Connect(function()
						local newValue = tonumber(ValueCount.Text)
						if newValue then
							newValue = roundToStep(math.clamp(newValue, min, max), step)
							ValueCount.Text = string.format("%." .. decimalPlaces .. "f", newValue)
							local RelativePosition = (newValue - min) / (max - min)
							SliderFill:TweenSize(UDim2.new(RelativePosition, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
							callback(newValue)
						else
							SetDefault()
						end
					end)

					BGSlider.InputBegan:Connect(onInputBegan)
					game:GetService("UserInputService").InputChanged:Connect(onInputChanged)
					game:GetService("UserInputService").InputEnded:Connect(onInputEnded)
				end

-- Updated Dropdown Function with Fixed Callback, Background Color, and Default Handling
function Funcs:addDropdown(title, default, options, multi, callback)
	options = options or {}
	callback = callback or function() end

	-- Ensure default(s) are respected
	local Selected
	if multi then
		Selected = {}
		if type(default) == "table" then
			for _, v in ipairs(default) do
				if table.find(options, v) then
					table.insert(Selected, v)
				end
			end
		end
	else
		local Index = 1
		if type(default) == "number" then
			Index = math.clamp(default, 1, #options)
		elseif type(default) == "string" then
			for i, v in ipairs(options) do
				if v == default then
					Index = i
					break
				end
			end
		end
		Selected = options[Index] or options[1] or "None"
	end

	-- UI Elements Setup
	local DropdownFrame = CreateInstance("Frame", {
		BackgroundColor3 = Color3.fromRGB(26, 25, 25),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 1,
		Size = UDim2.new(1, -25, 0, 32)
	}, InnerSection)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, DropdownFrame)

	local Gradient = CreateInstance("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 10, 140)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100))
		},
		Rotation = 90
	}, DropdownFrame)

	DropdownFrame.MouseEnter:Connect(function()
		Gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
		}
	end)
	DropdownFrame.MouseLeave:Connect(function()
		Gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 180))
		}
	end)

	CreateInstance("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 6),
		Size = UDim2.new(1, -150, 0, 20),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "  " .. title,
		TextScaled = true,
		ClipsDescendants = true
	}, DropdownFrame)

	local SelectedBox = CreateInstance("Frame", {
		BackgroundColor3 = Color3.fromRGB(19, 19, 25),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 1,
		Position = UDim2.new(0, 130, 0, 5),
		Size = UDim2.new(1, -160, 0, 20)
	}, DropdownFrame)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, SelectedBox)

	local SelectedText = CreateInstance("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamSemibold,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = ""
	}, SelectedBox)
	CreateInstance("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 10 }, SelectedText)

	local DropIcon = CreateInstance("ImageButton", {
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -30, 0, 4),
		Size = UDim2.new(0, 20, 0, 20),
		Image = "rbxassetid://95968409641902"
	}, DropdownFrame)

	local DropdownScroll = CreateInstance("Frame", {
		Name = "ScrollDown",
		BackgroundColor3 = Color3.fromRGB(26, 25, 25),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 1,
		Size = UDim2.new(0.8, -10, 0, 0),
		ClipsDescendants = true
	}, InnerSection)
	CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, DropdownScroll)
	ApplyUIStroke(DropdownScroll, Color3.fromRGB(255, 255, 255), 0.8, 1, Enum.ApplyStrokeMode.Border)

	local DropdownListLayout = CreateInstance("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2)
	}, DropdownScroll)

	local function UpdateSelectedText()
		if multi then
			SelectedText.Text = (#Selected > 0) and table.concat(Selected, ", ") or "None"
		else
			SelectedText.Text = Selected
		end
	end

	local function RotateIcon(open)
		UISettings:Tween(DropIcon, { Rotation = open and 180 or 0 }, 0.3)
	end

	local function ToggleDropdown()
		local isOpen = DropdownScroll.Size.Y.Offset > 0
		local newSize = isOpen and 0 or DropdownListLayout.AbsoluteContentSize.Y + 5
		UISettings:Tween(DropdownScroll, { Size = UDim2.new(0.8, -10, 0, newSize) }, 0.3)
		RotateIcon(not isOpen)
	end
	DropIcon.MouseButton1Click:Connect(ToggleDropdown)

	local function AddOption(value)
		local Option = CreateInstance("TextButton", {
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 170, 0, 28),
			Font = Enum.Font.Gotham,
			AutoButtonColor = false,
			TextSize = 14,
			Text = value,
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}, DropdownScroll)
		CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, Option)

		local SelectionFrame = CreateInstance("Frame", {
			BackgroundColor3 = Color3.fromRGB(150, 100, 255),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 5, 0, 3),
			Size = UDim2.new(0, 8, 0, 20),
			Visible = multi and table.find(Selected, value) or (not multi and Selected == value)
		}, Option)
		CreateInstance("UICorner", { CornerRadius = UDim.new(1, 6) }, SelectionFrame)

		HoverEffect(Option, { TextColor3 = Color3.fromRGB(150, 100, 255) }, { TextColor3 = Color3.fromRGB(255, 255, 255) })

		Option.MouseButton1Click:Connect(function()
			CircleClick(Option, Mouse.X, Mouse.Y)
			if multi then
				local idx = table.find(Selected, value)
				if idx then
					table.remove(Selected, idx)
					SelectionFrame.Visible = false
				else
					table.insert(Selected, value)
					SelectionFrame.Visible = true
				end
				UpdateSelectedText()
				callback(table.clone(Selected))
			else
				for _, Other in ipairs(DropdownScroll:GetChildren()) do
					if Other:IsA("TextButton") then
						local frame = Other:FindFirstChildOfClass("Frame")
						if frame then frame.Visible = false end
					end
				end
				Selected = value
				SelectionFrame.Visible = true
				UpdateSelectedText()
				callback(value)
				ToggleDropdown()
			end
		end)
	end

	for _, v in ipairs(options) do
		AddOption(v)
	end

	UpdateSelectedText()
	callback(multi and table.clone(Selected) or Selected)

	local ResetDropFunc = {}
	function ResetDropFunc:Clear()
		for _, child in ipairs(DropdownScroll:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		Selected = multi and {} or "None"
		UpdateSelectedText()
		callback(multi and table.clone(Selected) or Selected)
		UISettings:Tween(DropdownScroll, { Size = UDim2.new(0.8, -10, 0, 0) }, 0.15)
		RotateIcon(false)
	end
	function ResetDropFunc:Refresh(NewList)
		self:Clear()
		for _, v in ipairs(NewList or {}) do
			AddOption(v)
		end
	end
	return ResetDropFunc
end


				function Funcs:addTextbox(text_tile, callback)
					callback = callback or function() end

					local TextBoxFrame = CreateInstance("Frame", {
						BackgroundColor3 = Color3.fromRGB(26, 25, 25),
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 30)
					}, InnerSection)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 4) }, TextBoxFrame)

					local TextBoxTitle = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 5, 0, 0),
						Size = UDim2.new(0, 150, 0, 30),
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 15,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "   " .. text_tile,
					}, TextBoxFrame)

					local TextBox = CreateInstance("TextBox", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 150, 0, 5),
						Size = UDim2.new(0, 60, 0, 20),
						Font = Enum.Font.SourceSansSemibold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 8,
						TextTransparency = 0.5,
						Text = "Enter Here",
						TextScaled = true,
						ClearTextOnFocus = false
					}, TextBoxFrame)

					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, TextBox)

					local Gradient = CreateInstance("UIGradient", {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 10, 140)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100))
						},
						Rotation = 90
					}, TextBoxFrame)

					TextBoxFrame.MouseEnter:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
						}
					end)

					TextBoxFrame.MouseLeave:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 180))
						}
					end)

					local function Placeholder()
						if TextBox.Text == "" then
							TextBox.Text = "Enter Here"
							TextBox.TextTransparency = 0.5
						else
							TextBox.TextTransparency = 0
						end
					end

					TextBox.Focused:Connect(function()
						if TextBox.Text == "Enter Here" then
							TextBox.Text = ""
							TextBox.TextTransparency = 0
						end
					end)

					TextBox.FocusLost:Connect(function()
						Placeholder()
						if TextBox.Text ~= "Enter Here" and TextBox.Text ~= "" then
							callback(TextBox.Text)
							UISettings:Tween(TextBox, { TextColor3 = Color3.fromRGB(150, 100, 255) }, .1)
							UISettings:Tween(TextBoxTitle, { TextColor3 = Color3.fromRGB(150, 100, 255) }, .1)
							wait(.1)
							UISettings:Tween(TextBox, { TextColor3 = Color3.fromRGB(255, 255, 255) }, .5)
							UISettings:Tween(TextBoxTitle, { TextColor3 = Color3.fromRGB(255, 255, 255) }, .5)
						end
					end)

					TextBox:GetPropertyChangedSignal("Text"):Connect(function()
						if TextBox.Text ~= "Enter Here" and TextBox.Text ~= "" then
							TextBox.TextTransparency = 0
						end
					end)

					return TextBox
				end

				function Funcs:addStatus(initial_prefix, initial_status, status_color)
					local StatusLabel = {}

					local LabelFrame = CreateInstance("Frame", {
						BackgroundColor3 = Color3.fromRGB(26, 25, 25),
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 30),
						ClipsDescendants = true
					}, InnerSection)

					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, LabelFrame)

					local TitleFrame = CreateInstance("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -10, 1, 0),
						Position = UDim2.new(0, 5, 0, 0)
					}, LabelFrame)
					local Title = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						RichText = true,
						TextScaled = false,
						TextWrapped = false
					}, TitleFrame)


					local Gradient = CreateInstance("UIGradient", {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 10, 140)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100))
						},
						Rotation = 90
					}, LabelFrame)

					LabelFrame.MouseEnter:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
						}
					end)

					LabelFrame.MouseLeave:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 180))
						}
					end)

					function StatusLabel:UpdateStatus(new_prefix, new_status, new_color)
						new_prefix = new_prefix or initial_prefix
						new_status = new_status or initial_status
						new_color = new_color or status_color

						local ColorHex = {
							["Orange"] = "FFA500",
							["Yellow"] = "FFFF00",
							["Red"] = "FF0000",
							["Green"] = "00FF00"
						}
						local ColorCode = ColorHex[new_color] or "FFFFFF"
						Title.Text = string.format('<font color="rgb(255,255,255)">%s:</font> <font color="#%s">%s</font>', new_prefix, ColorCode, new_status)
					end
					StatusLabel:UpdateStatus(initial_prefix, initial_status, status_color)

					return StatusLabel
				end


				function Funcs:addLabel(title_text, description_text)
					local LabelFunc = {}

					local PaddingBetweenLabels = 10
					local PaddingFrame = 15

					local LabelFrame = CreateInstance("Frame", {
						BackgroundColor3 = Color3.fromRGB(26, 25, 25),
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 50),
						ClipsDescendants = true
					}, InnerSection)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 6) }, LabelFrame)

					local Gradient = CreateInstance("UIGradient", {
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 10, 140)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 100))
						},
						Rotation = 90
					}, LabelFrame)

					LabelFrame.MouseEnter:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
						}
					end)

					LabelFrame.MouseLeave:Connect(function()
						Gradient.Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 0, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 0, 180))
						}
					end)

					local TitleFrame = CreateInstance("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 20),
						Position = UDim2.new(0, 0, 0, 0)
					}, LabelFrame)

					local Title = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -10, 1, 0),
						Position = UDim2.new(0, 5, 0, 7),
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Center,
						Text = title_text or "Default Title"
					}, TitleFrame)

					local DescFrame = CreateInstance("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 20),
						Position = UDim2.new(0, 0, 0, 30)
					}, LabelFrame)

					local Description = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -10, 1, 0),
						Position = UDim2.new(0, 5, 0, 0),
						Font = Enum.Font.Ubuntu,
						TextColor3 = Color3.fromRGB(200, 200, 200),
						TextSize = 12,
						TextWrapped = false,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = (description_text or "Default description."):gsub("\\n", "\n")
					}, DescFrame)

					local function AdjustFrameHeight()
						task.wait()

						local TitleHeight = Title.TextBounds.Y
						local DescriptionHeight = Description.TextBounds.Y

						TitleFrame.Size = UDim2.new(1, 0, 0, TitleHeight)
						DescFrame.Position = UDim2.new(0, 0, 0, TitleHeight + PaddingBetweenLabels)
						DescFrame.Size = UDim2.new(1, 0, 0, DescriptionHeight)

						local TotalHeight = TitleHeight + DescriptionHeight + PaddingBetweenLabels + PaddingFrame
						LabelFrame.Size = UDim2.new(1, -20, 0, TotalHeight)
					end

					Title:GetPropertyChangedSignal("TextBounds"):Connect(AdjustFrameHeight)
					Description:GetPropertyChangedSignal("TextBounds"):Connect(AdjustFrameHeight)

					AdjustFrameHeight()
					function LabelFunc:RefreshTitle(NewTitle)
						if Title.Text ~= NewTitle then
							Title.Text = NewTitle:gsub("\\n", "\n")
							AdjustFrameHeight()
						end
					end

					function LabelFunc:RefreshDesc(NewDesc)
						if Description.Text ~= NewDesc then
							Description.Text = NewDesc:gsub("\\n", "\n")
							AdjustFrameHeight()
						end
					end

					return LabelFunc
				end

				function Funcs:addBio()
					local BioFunc = {}

					local player = game.Players.LocalPlayer
					local username = player.DisplayName or player.Name
					local userId = player.UserId
					local thumbnailUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"

					local BioFrame = CreateInstance("Frame", {
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 90),
						ClipsDescendants = true
					}, InnerSection)
					CreateInstance("UICorner", { CornerRadius = UDim.new(0, 8) }, BioFrame)
					CreateInstance("UIStroke", {
						Color = Color3.fromRGB(140, 10, 255),
						Thickness = 2
					}, BioFrame)

					local Thumbnail = CreateInstance("ImageLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 55, 0, 55),
						Position = UDim2.new(0, 12, 0, 18),
						Image = thumbnailUrl,
						ScaleType = Enum.ScaleType.Fit
					}, BioFrame)
					CreateInstance("UICorner", { CornerRadius = UDim.new(1, 0) }, Thumbnail)

					local UsernameLabel = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -85, 0, 28),
						Position = UDim2.new(0, 80, 0, 12),
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 18,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextScaled = true,
						Text = username
					}, BioFrame)

					local UserIdLabel = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -85, 0, 18),
						Position = UDim2.new(0, 80, 0, 40),
						Font = Enum.Font.Gotham,
						TextColor3 = Color3.fromRGB(180, 180, 180),
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "ID: " .. userId
					}, BioFrame)

					local ServerTimeLabel = CreateInstance("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -85, 0, 18),
						Position = UDim2.new(0, 80, 0, 60),
						Font = Enum.Font.Gotham,
						TextColor3 = Color3.fromRGB(180, 180, 180),
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "Client: 00h 00m 00s"
					}, BioFrame)


					function BioFunc:UpdateUsername(newUsername)
						if UsernameLabel.Text ~= newUsername then
							UsernameLabel.Text = newUsername
						end
					end

					function BioFunc:UpdateUserId(newUserId)
						if UserIdLabel.Text ~= "ID: " .. newUserId then
							UserIdLabel.Text = "ID: " .. newUserId
						end
					end

					function BioFunc:UpdateThumbnail(newThumbnailUrl)
						if Thumbnail.Image ~= newThumbnailUrl then
							Thumbnail.Image = newThumbnailUrl
						end
					end

					function BioFunc:UpdateServerTime(newTime)
						ServerTimeLabel.Text = "Client: " .. newTime
					end

					local function LiveTime()
						local GameTime = math.floor(workspace.DistributedGameTime + 0.5)
						local Hour = math.floor(GameTime / (60 ^ 2)) % 24
						local Minute = math.floor(GameTime / (60 ^ 1)) % 60
						local Second = math.floor(GameTime / (60 ^ 0)) % 60
						local FormatTime = string.format("%02dh %02dm %02ds", Hour, Minute, Second)
						BioFunc:UpdateServerTime(FormatTime)
					end

					spawn(function()
						while game:GetService('RunService').Heartbeat:Wait() do
							LiveTime()
						end
					end)

					return BioFunc
				end


				return Funcs
			end


			return Menus
		end

		return Section
	end

	return Tabs
end
return Library
