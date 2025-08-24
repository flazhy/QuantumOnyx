local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local TweenInfo = TweenInfo.new

local Library, UISettings = {}, {} do
Library.Notification = {}
local Notification = Library.Notification

local CoreGui
do
	local protect = protectgui or (syn and syn.protect_gui) or function(x) return x end
	local isStudio = RunService:IsStudio()
	local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	if isStudio then
		CoreGui = LocalPlayer:WaitForChild("PlayerGui")
	else
		if typeof(gethui) == "function" then
			CoreGui = assert(gethui(), "gethui() failed to return a GUI root")
		else
			local gui = protect(game:GetService("CoreGui"))
			assert(typeof(gui) == "Instance" and gui:IsA("Instance"), "CoreGui protection failed")
			CoreGui = gui
		end
	end
end


local Creator
Creator = function(class, properties, parent)
	local instance = Instance.new(class)
	do
		for key, value in pairs(properties) do
			if key ~= "Children" and key ~= "Parent" then
				assert(pcall(function()
					instance[key] = value
				end), string.format('Failed to set property "%s" on %s', key, class))
			end
		end
	end
	do
		local children = properties["Children"]
		if children then
			for _, child in ipairs(children) do
				assert(pcall(function()
					child.Parent = instance
				end), string.format('Failed to parent child to %s', class))
			end
		end
	end
	instance.Parent = properties.Parent or parent
	return instance
end

function UISettings:Tween(target, properties, duration, style, direction, complete)
	style = style or Enum.EasingStyle.Quad
	direction = direction or Enum.EasingDirection.Out
	local Info = TweenInfo(duration, style, direction)
	local Tween = TweenService:Create(target, Info, properties)
	if typeof(complete) == "function" then
		local conn
		conn = Tween.Completed:Connect(function()
			conn:Disconnect()
			complete()
		end)
	end
	Tween:Play()
	return Tween
end

function Library:DestroyGui(Name)
	local gui = CoreGui:FindFirstChild(Name)
	if gui then gui:Destroy() end
end

function CircleClick(Button, X, Y)
	task.spawn(function()
		Button.ClipsDescendants = true

		local NewX = X - Button.AbsolutePosition.X
		local NewY = Y - Button.AbsolutePosition.Y
		local Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5
		local Time = 0.5

		local Circle = Creator("ImageLabel", {
			Name = "Circle",
			Image = "rbxassetid://266543268",
			ImageColor3 = Color3.fromRGB(80, 80, 80),
			ImageTransparency = 0.9,
			BackgroundTransparency = 1,
			ZIndex = 10,
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0, NewX, 0, NewY),
		}, Button)

		UISettings:Tween(Circle, {
			Size = UDim2.new(0, Size, 0, Size),
			Position = UDim2.new(0.5, -Size / 2, 0.5, -Size / 2)
		}, Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		UISettings:Tween(Circle, {
			ImageTransparency = 1
		}, Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, function()
			Circle:Destroy()
		end)
	end)
end

local ThemeManager = {
	Themes = {
		Purple = {
			Body = Color3.fromRGB(10, 10, 10),
			Primary = Color3.fromRGB(5, 5, 5),
			Lit = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 90)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(90, 40, 130)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 160)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(40, 100, 190)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 140, 200))
			},
			TextColor = Color3.fromRGB(255, 255, 255),
			SubTextColor = Color3.fromRGB(200, 200, 200),
			ButtonGradient = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 20, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 10, 200))
			},
			Accent = Color3.fromRGB(180, 180, 180)
		}
	},
	Current = nil
}

local function ThemeColor(name)
	if ThemeManager.Current and ThemeManager.Current[name] then
		return ThemeManager.Current[name]
	else
		return Color3.fromRGB(255, 0, 255)
	end
end

local function GetWrappedTextHeight(text, font, size, width)
	local size = TextService:GetTextSize(text, size, font, Vector2.new(width, math.huge))
	return size.Y
end
local function WrapText(text, font, size, width)
	local lines = {}
	for paragraph in (text .. "\n\n"):gmatch("(.-)\n") do
		if paragraph == "" then
			table.insert(lines, "")
		else
			local words = {}
			for word in paragraph:gmatch("%S+") do
				table.insert(words, word)
			end
			local Line = ""
			for _, word in ipairs(words) do
				local extra = Line == "" and word or Line .. " " .. word
				local size = TextService:GetTextSize(extra, size, font, Vector2.new(width, 1000))
				if size.X > width then
					table.insert(lines, Line)
					Line = word
				else
					Line = extra
				end
			end
			table.insert(lines, Line)
		end
	end
	return table.concat(lines, "\n")
end

function Notification:Init(parent)
	self.GUI = parent:FindFirstChild("STX_Notification")
	if not self.GUI then
		self.GUI = Creator("Frame", {
			Name = "STX_Notification",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 1, -52),
			Position = UDim2.new(1, -10, 1, -10),
			AnchorPoint = Vector2.new(1, 1),
			ClipsDescendants = false,
			ZIndex = 999,
			["Children"] = {
				Creator("UIListLayout", {
					Name = "STX_NotificationUIListLayout",
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					Padding = UDim.new(0, 6)
				})
			}
		}, parent)
	end
end

function Notification:Notify(nofdebug, middledebug)
	assert(self.GUI, "Notification GUI not initialized. Call :Init(parent) first.")

	local Title = nofdebug.Title or "Notification"
	local Description = nofdebug.Description or ""
	local DisplayTime = middledebug.Time or 3
	local fontSize = 12
	local font = Enum.Font.Gotham
	local maxWidth = 184

	local wrappedText = WrapText(Description, font, fontSize, maxWidth)
	local textHeight = GetWrappedTextHeight(wrappedText, font, fontSize, maxWidth)
	local totalHeight = 28 + textHeight + 8

	local Shadow = Creator("ImageLabel", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 250, 1, -10),
		Size = UDim2.new(0, 0, 0, 0),
		Image = "rbxassetid://1316045217",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.4,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		ZIndex = 1000
	}, self.GUI)

	local NotificationFrame = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 5, 0, 3),
		Size = UDim2.new(0, 200, 0, totalHeight),
		ZIndex = 1001,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(180, 180, 180),
				Transparency = 0.8,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 2),
				Size = UDim2.new(0, 184, 0, 18),
				ZIndex = 1002,
				Font = Enum.Font.FredokaOne,
				Text = Title,
				TextColor3 = Color3.fromRGB(220, 220, 220),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 22),
				Size = UDim2.new(0, 184, 0, textHeight),
				ZIndex = 1002,
				Font = font,
				Text = wrappedText,
				TextColor3 = Color3.fromRGB(180, 180, 180),
				TextSize = fontSize,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top
			}),
			Creator("Frame", {
				Name = "ProgressBarBackground",
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 1, -8),
				Size = UDim2.new(1, 0, 0, 8),
				ZIndex = 1002,
				["Children"] = {
					Creator("UICorner", {
						CornerRadius = UDim.new(0, 5)
					}),
					Creator("Frame", {
						Name = "ProgressBarFill",
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 1003,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 7)
							}),
							Creator("UIGradient", {
								Color = ThemeColor("Lit"),
								Rotation = 0
							})
						}
					})
				}
			})
		}
	}, Shadow)
	UISettings:Tween(Shadow, { Position = UDim2.new(1, -10, 1, -10) }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	UISettings:Tween(Shadow, { Size = UDim2.new(0, 200, 0, totalHeight + 10) }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	local fillBar = NotificationFrame:FindFirstChild("ProgressBarBackground"):FindFirstChild("ProgressBarFill")
	if fillBar then
		UISettings:Tween(fillBar, { Size = UDim2.new(0, 0, 1, 0) }, DisplayTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	end
	coroutine.wrap(function()
		task.wait(DisplayTime)
			UISettings:Tween(Shadow, { Position = UDim2.new(1, 250, 1, -10) }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
			UISettings:Tween(Shadow, { Size = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
		task.wait(0.3)
		Shadow:Destroy()
	end)()
end

function Library:CreateWindow(config)
	local namehub = typeof(config) == "string" and config or config.Title or "Hub"
	local subtitle = config.Subtitle or "Untitled"
	local version = config.Version or "v1.0"
	local ThemeName = config.Theme or "Purple"

	local SelectedTheme = ThemeManager.Themes[ThemeName] or ThemeManager.Themes.Purple
	ThemeManager.Current = SelectedTheme

	self:DestroyGui(namehub)
	local ScreenGui = Creator("ScreenGui", {
		Name = namehub,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, CoreGui)

	local Body = Creator("Frame", {
		BackgroundColor3 = ThemeColor("Body"),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -275, 0.5, -175),
		Size = UDim2.new(0, 510, 0, 330),
		ClipsDescendants = true,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 10)
			})
		}
	}, ScreenGui)

	Library.Notification:Init(Body)
	local TopFrame = Creator("Frame", {
		BackgroundColor3 = ThemeColor("Body"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 32),
		ZIndex = 1005,
		ClipsDescendants = true,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(1, 0)
			})
		}
	}, Body)

	Creator("TextLabel", {
		Name = "TitleHub",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 1, 0, 0),
		Size = UDim2.new(1, -10, 0, 20),
		Font = Enum.Font.FredokaOne,
		Text = "   " .. namehub .. " Project",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	}, TopFrame)
	
	Creator("TextLabel", {
		Name = "SubtitleHub",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 18),
		Size = UDim2.new(1, -10, 0, 10),
		Font = Enum.Font.Gotham,
		RichText = true,
		Text = string.format(
			'<font color="#C084FC">%s</font> • <font color="#34D399">%s</font> • <font color="#FF9E9E">%s</font>',
			subtitle,
			version,
			os.date("%A")
		),
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left
	}, TopFrame)

	local MinimizeButton = Creator("ImageButton", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 450, 0, 4),
		Size = UDim2.new(0, 20, 0, 20),
		ZIndex = 1005,
		Image = "rbxassetid://92966930061759",
	}, Body)

	local CloseButton = Creator("ImageButton", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 480, 0, 2),
		Size = UDim2.new(0, 22, 0, 22),
		ZIndex = 1005,
		Image = "rbxassetid://79324227570635",
	}, Body)


	local Tiktok = Creator("TextButton", {
		Name = "Tiktok",
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		Position = UDim2.new(0, 360, 0, 2),
		Size = UDim2.new(0, 85, 0, 25),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 1005,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 7)
			}),
			Creator("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 6, 0, 2),
			Size = UDim2.new(0, 20, 0, 20),
			Image = "http://www.roblox.com/asset/?id=14620084334"
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 35, 0, 0),
				Size = UDim2.new(0, 40, 0, 25),
				Font = Enum.Font.GothamBold,
				Text = "Tiktok",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		}
	}, Body)
	Tiktok.MouseButton1Click:Connect(function()
		CircleClick(Tiktok, Mouse.X, Mouse.Y);
		(setclipboard or toclipboard)("https://www.tiktok.com/@trustmenotcondom?_t=ZS-8syewdU3Bxq&_r=1")
		wait(.1)
		Library.Notification:Notify({
			Title = "Tiktok",
			Description = "Tiktok copied to clipboard"
		}, {
			Type = "default",
			Time = 2,
			OutlineColor = Color3.fromRGB(255, 255, 255)
		})
	end)

	local Discord = Creator("TextButton", {
		Name = "Discord",
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		Position = UDim2.new(0, 270, 0, 2),
		Size = UDim2.new(0, 85, 0, 25),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 1005,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 7)
		 	}),
			Creator("ImageLabel", {
				Name = "DiscordLogo",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 6, 0, 2),
				Size = UDim2.new(0, 20, 0, 20),
				Image = "http://www.roblox.com/asset/?id=129297846250682"
			}),
			Creator("TextLabel", {
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
			})
		}
	}, Body)

	Discord.MouseButton1Click:Connect(function()
		CircleClick(Discord, Mouse.X, Mouse.Y);
		(setclipboard or toclipboard)("https://discord.gg/ZK3fXgx3Gh")
		wait(.1)
		Library.Notification:Notify({
				Title = "Discord",
				Description = "Discord invite copied to clipboard"
			}, {
				Type = "default",
				Time = 2,
				OutlineColor = Color3.fromRGB(114, 137, 218)
		})
	end)
	local ToggleClose = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.0160791595, 0, 0.219451368, 0),
		Size = UDim2.new(0, 40, 0, 40),
		Draggable = true
	}, ScreenGui)
	Creator("UICorner", { CornerRadius = UDim.new(0, 5) }, ToggleClose)

	local ToggleLogo = Creator("ImageButton", {
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
			UISettings:Tween(Body, {Size = UDim2.new(0, 510, 0, 330)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			MinimizeButton.Image = "rbxassetid://92966930061759"
			TopFrame.BackgroundTransparency = 1
			MinimizeButton.Position = UDim2.new(0, 450, 0, 4)
			ToggleLogo.Visible = true
			Minimized = false
		else
			UISettings:Tween(Body, {Size = UDim2.new(0, 210, 0, 30)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			MinimizeButton.Position = UDim2.new(0, 180, 0, 4)
			TopFrame.BackgroundTransparency = 0
			MinimizeButton.Image = "rbxassetid://124967485209478"
			ToggleLogo.Visible = false
			Minimized = true
		end
	end)

	local BlurOverlay = Creator("Frame", {
		Name = "BlurOverlay",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.2,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 9,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 10)
			}),
			Creator("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.8,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),

		}
	}, Body)

	local Dialog = Creator("Frame", {
		Name = "ComfirmDialog",
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		BackgroundTransparency = 0.1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.5, 0, 0.4, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Visible = false,
		ZIndex = 10,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 10)
			}),
			Creator("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.8,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),
		}
	}, Body)

	Creator("TextLabel", {
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

	local ComfirmDialog = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(34, 33, 33),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0.4, -10, 0.2, 0),
		Position = UDim2.new(0.1, 0, 0.7, 0),
		Text = "Yes",
		Font = Enum.Font.SourceSans,
		TextSize = 16,
		ZIndex = 11,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 7)
			}),
			Creator("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.8,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),

		}
	}, Dialog)

	local CancelDialog = Creator("TextButton", {
		Name = "CancelButton",
		BackgroundColor3 = Color3.fromRGB(34, 33, 33),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0.4, -10, 0.2, 0),
		Position = UDim2.new(0.5, 10, 0.7, 0),
		Text = "No",
		Font = Enum.Font.SourceSans,
		TextSize = 16,
		ZIndex = 11, 
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 7)
			}),
			Creator("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.8,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),

		}
	}, Dialog)

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
	ToggleLogo.MouseButton1Click:Connect(function()
		Body.Visible = not isMinimized
		isMinimized = not isMinimized
	end)
	local function MakeDraggable(TopBar, Body)
		local Dragging = false
		local DragInput
		local DragStart
		local StartPosition

		local function Update(Input)
			local Delta = Input.Position - DragStart
			Body.Position = UDim2.new(
				StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
				StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
			)
		end

		TopBar.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				DragStart = Input.Position
				StartPosition = Body.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)

		TopBar.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
				DragInput = Input
			end
		end)

		UIS.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				Update(Input)
			end
		end)
	end
	MakeDraggable(TopFrame, Body)

	local TabContainer = Creator("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 36),
		ClipsDescendants = true
	}, Body)

	local TabScroll = Creator("ScrollingFrame", {
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, -3),
		Size = UDim2.new(1, -20, 0, 30),
		CanvasPosition = Vector2.new(0, 150),
		ScrollBarThickness = 0,
		["Children"] = {
			Creator("UICorner", {
				CornerRadius = UDim.new(0, 7)
			})
		}
	}, TabContainer)

	local TabLayout = Creator("UIListLayout", {
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

	local MainContainer = Creator("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 590, 0, 400),
		Position = UDim2.new(0, 5, 0, 70)
	}, Body)


	local Container = Creator("Folder", {
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

		local icon_size = 16
		local icon_padding = 6
		local extra_padding = 12

		local Tab = Creator("TextButton", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.FredokaOne,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 14.000,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "" .. Tab_Title,
			["Children"] = {
				Creator("UICorner", {
					CornerRadius = UDim.new(0, 7)
				}),
				Creator("ImageLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(0, 5, 0.5, -8),
					Image = IconMapping[Tab_Icon] or ""
				})
			}
		}, nil)

		task.spawn(function()
			repeat task.wait() until Tab.TextBounds.X > 0
			local width = icon_padding + icon_size + extra_padding + Tab.TextBounds.X
			Tab.Size = UDim2.new(0, width, 0, 24)
		end)

		local TabUnderline = Creator("Frame", {
			Name = "Tab_Underline",
			BackgroundColor3 = Color3.fromRGB(46, 32, 88),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 10),
			Position = UDim2.new(0, 0, 1, 0),
			Visible = false,
			["Children"] = {
				Creator("UICorner", {
					CornerRadius = UDim.new(1, 0)
				})
			}
		}, Tab)

		Tab.Parent = TabScroll

		local ScrollFrame = Creator("ScrollingFrame", {
			Name = "ScrollingFrame",
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			ScrollBarThickness = 0,
			Visible = false,
			ClipsDescendants = true
		}, Container)

		local ScrollLayout = Creator("UIListLayout", {
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

			local SectionScroll = Creator("ScrollingFrame", {
				Name = "SectionScroll",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 240, 0, 260),
				ScrollBarImageColor3 = Color3.fromRGB(150, 100, 255),
				ScrollBarThickness = 0,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ClipsDescendants = true,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				["Children"] = {
					Creator("UICorner", {
						CornerRadius = UDim.new(1, 0)
					})
				}
			}, ScrollFrame)

			local SectionLayout = Creator("UIListLayout", {
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
				local Section = Creator("Frame", {
					Name = "Section",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.48, 0, 0, 20),
					ClipsDescendants = true,
				}, SectionScroll)

				local InnerSection = Creator("Frame", {
					Name = "InnerSection",
					BackgroundColor3 = Color3.fromRGB(25, 25, 25),
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0, 0),
					Size = UDim2.new(1, -5, 0, 25)
				}, Section)

				local SectionListLayout = Creator("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 3),
					["Children"] = {
						Creator("UICorner", {
							CornerRadius = UDim.new(0, 4)
						})
					}
				}, InnerSection)

				local TitleContainer = Creator("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					["Children"] = {
						Creator("TextLabel", {
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Size = UDim2.new(0.6, 0, 1, 0),
							Position = UDim2.new(0.2, 0, 0, 0),
							Font = Enum.Font.FredokaOne,
							Text = Menu_Title,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 14,
							TextXAlignment = Enum.TextXAlignment.Center
						})
					}
				}, InnerSection)

				Creator("Frame", {
					BackgroundColor3 = Color3.fromRGB(150, 100, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.2, 0, 0, 10),
					Position = UDim2.new(0, 0, 0.5, -1),
					["Children"] = {
						Creator("UICorner", {
							CornerRadius = UDim.new(0.5)
						}),
						Creator("UIGradient", {
							Color = ThemeColor("Lit"),
							Rotation = 60
						})
					}
				}, TitleContainer)
				
				Creator("Frame", {
					BackgroundColor3 = Color3.fromRGB(150, 100, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.2, 0, 0, 10),
					Position = UDim2.new(0.8, 0, 0.5, -1),
					["Children"] = {
						Creator("UICorner", {
							CornerRadius = UDim.new(0.5)
						}),
						Creator("UIGradient", {
							Color = ThemeColor("Lit"),
							Rotation = 60
						})
					}
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

					local MainButton = Creator("TextButton", {
						BackgroundColor3 = ThemeColor("Primary"),
						BackgroundTransparency = 0.4,
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 30),
						AutoButtonColor = false,
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(220, 220, 220),
						Text = Title_Button,
						TextScaled = true,
						ClipsDescendants = true,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 6)
							}),
							Creator("UITextSizeConstraint", {
								MaxTextSize = 14,
								MinTextSize = 10
							})
						}
					}, InnerSection)
					MainButton.MouseButton1Click:Connect(function()
						CircleClick(MainButton, Mouse.X, Mouse.Y)
						callback()
					end)
				end

				function Funcs:addToggle(toggle_title, default, callback, descriptionOrIcon, iconOverride, options)
					callback = callback or function() end
					default = default or false

					local isAssetId = typeof(descriptionOrIcon) == "string" and descriptionOrIcon:find("rbxassetid://")
					local hasDescription = (not isAssetId and typeof(descriptionOrIcon) == "string")
					local description = hasDescription and descriptionOrIcon or nil
					local toggle_icon = iconOverride or (isAssetId and descriptionOrIcon or nil)
					local hasIcon = toggle_icon and true or false
					local frameHeight = hasDescription and 60 or 33

					local ToggleFrame = Creator("TextButton", {
						BackgroundColor3 = ThemeColor("Primary"),
						BackgroundTransparency = 0.4,
						Size = UDim2.new(1, -25, 0, frameHeight),
						Position = UDim2.new(0, 5, 0, 0),
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Text = "",
						ClipsDescendants = true,
						["Children"] = {
							Creator("UICorner", { CornerRadius = UDim.new(0, 6) })
						}
					}, InnerSection)

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
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border
							}),
						}
					}, ToggleFrame)

					local SlideButton = Creator("ImageLabel", {
						AnchorPoint = Vector2.new(0, 0.5),
						Size = UDim2.fromOffset(14, 14),
						Position = default and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
						Image = "http://www.roblox.com/asset/?id=12266946128",
						ImageTransparency = default and 0 or 0.5,
						BackgroundTransparency = 1,
						ImageColor3 = Color3.fromRGB(255, 255, 255),
					}, BGFrame)

					local SlideGradient = Creator("UIGradient", {
						Color = ThemeColor("Lit"),
						Rotation = 90,
					}, SlideButton)
					SlideGradient.Enabled = default

					local iconOffset = hasIcon and 38 or 10

					local ToggleIcon
					if hasIcon then
						ToggleIcon = Creator("ImageLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 10, 0, hasDescription and 10 or 7),
							Image = toggle_icon,
							ImageColor3 = Color3.fromRGB(220, 220, 220),
							Size = UDim2.new(0, 20, 0, 20),
							ImageTransparency = default and 0 or 0.6
						}, ToggleFrame)
					end

					local ToggleTitle = Creator("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, iconOffset, 0, 6),
						Size = UDim2.new(1, -(iconOffset + 50), 0, 20),
						Font = Enum.Font.GothamBold,
						Text = toggle_title,
						TextColor3 = default and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(180, 180, 180),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextWrapped = true,
						TextScaled = true,
						["Children"] = {
							Creator("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 10 })
						}
					}, ToggleFrame)

					if hasDescription then
						Creator("TextLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.new(0, iconOffset, 0, 30),
							Size = UDim2.new(1, -(iconOffset + 50), 0, 20),
							Font = Enum.Font.Gotham,
							Text = description,
							TextColor3 = Color3.fromRGB(160, 160, 160),
							TextXAlignment = Enum.TextXAlignment.Left,
							TextWrapped = true,
							TextScaled = true,
							["Children"] = {
								Creator("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 10 })
							}
						}, ToggleFrame)
					end

					local ToggleState = default
					local SubToggles = {}

					local function UpdateToggle()
						UISettings:Tween(SlideButton, {
							Position = ToggleState and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
							ImageTransparency = ToggleState and 0 or 0.5,
							ImageColor3 = Color3.fromRGB(255, 255, 255)
						}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

						SlideGradient.Enabled = ToggleState
						UISettings:Tween(ToggleTitle, {
							TextColor3 = ToggleState and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(120, 120, 120)
						}, 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

						if ToggleIcon then
							ToggleIcon.ImageTransparency = ToggleState and 0 or 0.6
						end

						if options and options.multiopt then
							for _, sub in ipairs(SubToggles) do
								sub.Frame.Visible = ToggleState
							end
						end

						callback(ToggleState)
					end
					UpdateToggle()

					local function ToggleInput()
						CircleClick(ToggleFrame, Mouse.X, Mouse.Y)
						ToggleState = not ToggleState
						UpdateToggle()
					end
					ToggleFrame.Activated:Connect(ToggleInput)

					if options and options.multiopt and options.list then
						local SubContainer = Creator("Frame", {
							BackgroundTransparency = 1,
							ClipsDescendants = true,
							Size = UDim2.new(1, -35, 0, 0),
							Position = UDim2.new(0, 15, 0, frameHeight),
							Parent = InnerSection
						})

						local Layout = Creator("UIListLayout", {
							Padding = UDim.new(0, 3),
							SortOrder = Enum.SortOrder.LayoutOrder
						}, SubContainer)

						for i, optName in ipairs(options.list) do
							local subDefault = false
							local subCB = options.callbacks and options.callbacks[i] or function() end

							local SubToggle = self:addToggle(optName, subDefault, subCB, nil, nil)
							SubToggle.Frame.Size = UDim2.new(1, 0, 0, 40)
							SubToggle.Frame.Parent = SubContainer
							table.insert(SubToggles, SubToggle)
						end

						local function AnimateSubs(open)
							local toggleHeight = 40
							local padding = Layout.Padding.Offset
							local totalHeight = (#SubToggles * toggleHeight) + math.max(0, (#SubToggles - 1) * padding)

							UISettings:Tween(SubContainer, {
								Size = open and UDim2.new(1, -35, 0, totalHeight) or UDim2.new(1, -35, 0, 0)
							}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						end

						local oldUpdate = UpdateToggle
						UpdateToggle = function()
							oldUpdate()
							AnimateSubs(ToggleState)
						end
					end

					return {
						Update = function(state)
							ToggleState = state
							UpdateToggle()
						end,
						Get = function()
							return ToggleState
						end,
						Frame = ToggleFrame,
						SubToggles = SubToggles
					}
				end


				function Funcs:addSlider(slider_title, min, max, default, callback, step)
					callback = callback or function() end
					min = min or 0
					max = max or 100
					step = step or 1
					default = math.clamp(default or min, min, max)

					local decimal = select(2, tostring(step):find("%.")) and #tostring(step) - tostring(step):find("%.") or 0
					local formatString = "%." .. decimal .. "f"

					local function round(val)
						return math.floor(val / step + 0.5) * step
					end

					local SliderFrame = Creator("Frame", {
						BackgroundColor3 = ThemeColor("Primary"),
						BackgroundTransparency = 0.4,
						Size = UDim2.new(1, -25, 0, 50),
						Position = UDim2.new(0, 5, 0, 0),
						BorderSizePixel = 0,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 8)
							}),
							Creator("TextLabel", {
								BackgroundTransparency = 1,
								Size = UDim2.new(1, -55, 0, 20),
								Position = UDim2.new(0, 5, 0, 5),
								Font = Enum.Font.GothamBold,
								Text = " " .. slider_title,
								TextSize = 14,
								TextColor3 = ThemeColor("TextColor"),
								TextTransparency = 0.2,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextScaled = true,
								["Children"] = {
									Creator("UITextSizeConstraint", {
										MaxTextSize = 14,
										MinTextSize = 10
									})
								}
							})
						}
					}, InnerSection)

					local ValueCount = Creator("TextBox", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						Position = UDim2.new(1, -55, 0, 5),
						Size = UDim2.new(0, 45, 0, 20),
						Font = Enum.Font.Gotham,
						Text = string.format(formatString, default),
						TextSize = 14,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextXAlignment = Enum.TextXAlignment.Center,
						ClearTextOnFocus = false,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0.4, 0)
							})
						}
					}, SliderFrame)

					local BGSlider = Creator("Frame", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						Position = UDim2.new(0, 5, 0, 30),
						Size = UDim2.new(1, -15, 0, 13),
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0.5, 0)
							}),

							Creator("UIStroke", {
								Color = Color3.fromRGB(255, 255, 255),
								Thickness = 1,
								Transparency = 0.6
							})
						}
					}, SliderFrame)


					local SliderFill = Creator("Frame", {
						BackgroundTransparency = 0,
						Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0.5, 0)
							}),
							Creator("UIGradient", {
								Color = ThemeColor("Lit"),
								Rotation = 90
							})
						}
					}, BGSlider)

					local dragging = false
					local function SetSlider(value)
						local ratio = (value - min) / (max - min)
						SliderFill:TweenSize(UDim2.new(ratio, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
						ValueCount.Text = string.format(formatString, value)
						callback(value)
					end

					local function LiveSlider(x)
						local rel = math.clamp((x - BGSlider.AbsolutePosition.X) / BGSlider.AbsoluteSize.X, 0, 1)
						SetSlider(round(min + (max - min) * rel))
					end

					local function SetDefault()
						SetSlider(default)
					end

					SetDefault()

					BGSlider.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true
							LiveSlider(input.Position.X)
						end
					end)

					UIS.InputChanged:Connect(function(input)
						if dragging then
							LiveSlider(input.Position.X)
						end
					end)

					UIS.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
						end
					end)

					ValueCount.FocusLost:Connect(function()
						local val = tonumber(ValueCount.Text)
						if val then
							val = round(math.clamp(val, min, max))
							SetSlider(val)
						else
							SetDefault()
						end
					end)
				end

				function Funcs:addDropdown(title, default, options, callback, multimode)

					default = default or 1
					options = options or {}
					callback = callback or function() end
					local SelectedIndices = {}
					local FilteredOptions = {}

					local function AddIndex(i)
						if not table.find(SelectedIndices, i) then table.insert(SelectedIndices, i) end
					end

					local function RemoveIndex(i)
						for k, v in ipairs(SelectedIndices) do
							if v == i then table.remove(SelectedIndices, k); return end
						end
					end

					local function SelectedValues()
						local t = {}
						for _, i in ipairs(SelectedIndices) do
							t[#t + 1] = options[i]
						end
						return t
					end

					local function InitializeSelection()
						local function SetAdd(val)
							if #options < 1 then return end

							local idx = type(val) == "number" and math.clamp(val, 1, #options)
								or type(val) == "string" and table.find(options, val)

							if idx then AddIndex(idx) end
						end


						if multimode then
							if typeof(default) == "table" then
								for _, val in ipairs(default) do SetAdd(val) end
							else
								SetAdd(default)
							end
							if #SelectedIndices == 0 then AddIndex(1) end
						else
							SetAdd(default)
							if #SelectedIndices == 0 then AddIndex(1) end
						end
					end
					local function FormatSelection(selected, limit)
						limit = limit or 2
						if #selected == 0 then
							return "None"
						elseif #selected <= limit then
							return table.concat(selected, ", ")
						else
							local shown = {}
							for i = 1, limit do
								table.insert(shown, selected[i])
							end
							return table.concat(shown, ", ") .. ", ..."
						end
					end

					InitializeSelection()

					local DropdownFrame = Creator("Frame", {
						BackgroundColor3 = ThemeColor("Primary"),
						BackgroundTransparency = 0.4,
						BorderColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 1,
						Size = UDim2.new(1, -25, 0, 32),
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 6)
							})
						}
					}, InnerSection)

					Creator("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 12, 0, 6),
						Size = UDim2.new(1, -150, 0, 20),
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "" .. title,
						TextScaled = false,
						ClipsDescendants = false,
						["Children"] = {
							Creator("UITextSizeConstraint", {
								MaxTextSize = 14,
								MinTextSize = 12
							})
						}
					}, DropdownFrame)


					local SelectedBox = Creator("Frame", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						BorderColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 1,
						Position = UDim2.new(0, 105, 0, 5),
						Size = UDim2.new(1, -140, 0, 20),
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 6)
							})
						}
					}, DropdownFrame)

					local SelectedText = Creator("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamSemibold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Text = multimode and table.concat(SelectedValues(), ", ") or (options[SelectedIndices[1]] or "None"),
						["Children"] = {
							Creator("UITextSizeConstraint", {
								MaxTextSize = 14,
								MinTextSize = 10
							})
						}
					}, SelectedBox)

					local DropIcon = Creator("ImageButton", {
						BackgroundTransparency = 1,
						Position = UDim2.new(1, -30, 0, 4),
						Size = UDim2.new(0, 20, 0, 20),
						Image = "rbxassetid://95968409641902"
					}, DropdownFrame)

					local Blocker = Creator("Frame", {
						Visible = false,
						Active = true,
						BackgroundTransparency = 0.5,
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 9,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 8)
							})
						}
					}, Body)

					local DialogBackground = Creator("Frame", {
						Visible = false,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundTransparency = 0.3,
						Size = UDim2.new(0, 250, 0, 0),
						BackgroundColor3 = ThemeColor("Primary"),
						ZIndex = 10,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 8)
							}),
							Creator("UIStroke", {
								Color = Color3.fromRGB(255, 255, 255),
								Transparency = 0.9,
								Thickness = 1
							}),
							Creator("TextLabel", {
								Size = UDim2.new(1, -12, 0, 20),
								Position = UDim2.new(0, 6, 0, 6),
								BackgroundTransparency = 1,
								Text = "" .. title,
								Font = Enum.Font.Gotham,
								TextSize = 14,
								TextColor3 = Color3.fromRGB(200, 200, 200),
								TextXAlignment = Enum.TextXAlignment.Left
							})
						}
					}, Body)


					local CloseButton = Creator("TextButton", {
						Text = "-",
						TextColor3 = Color3.new(1, 1, 1),
						TextSize = 30,
						Size = UDim2.new(0, 24, 0, 24),
						Position = UDim2.new(1, -28, 0, 4),
						BackgroundColor3 = Color3.fromRGB(40, 0, 60),
						BackgroundTransparency = 1,
						AutoButtonColor = false,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 5)
							})
						}
					}, DialogBackground)

					local SearchBox = Creator("TextBox", {
						Text = "",
						PlaceholderText = "Search...",
						Size = UDim2.new(1, -10, 0, 24),
						Position = UDim2.new(0, 5, 0, 30),
						TextSize = 14,
						Font = Enum.Font.Gotham,
						TextColor3 = Color3.new(1, 1, 1),
						BackgroundColor3 = Color3.fromRGB(32, 32, 45),
						ClearTextOnFocus = true,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 4)
							})
						}
					}, DialogBackground)

					local function GetRelativePosition(instance, relativeTo)
						local absPos = instance.AbsolutePosition
						local relAbsPos = relativeTo.AbsolutePosition
						return UDim2.new(0, absPos.X - relAbsPos.X, 0, absPos.Y - relAbsPos.Y)
					end

					local DialogFinalSize = UDim2.new(0, 250, 0, 230)

					local function OpenDialog()
						local iconPos = GetRelativePosition(DropIcon, Body)
						local iconSize = DropIcon.AbsoluteSize
						DialogBackground.Position = iconPos
						DialogBackground.Size = UDim2.new(0, iconSize.X, 0, iconSize.Y)
						DialogBackground.Visible = true
						Blocker.Visible = true
						UISettings:Tween(DialogBackground, {Position = UDim2.new(0.5, 0, 0.5, 0),Size = DialogFinalSize }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					end

					local function CloseDialog()
						local iconPos = GetRelativePosition(DropIcon, Body)
						local iconSize = DropIcon.AbsoluteSize

						UISettings:Tween(DialogBackground, {Position = iconPos,Size = UDim2.new(0, iconSize.X, 0, iconSize.Y)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

						task.delay(0.2, function()
							DialogBackground.Visible = false
							Blocker.Visible = false
						end)
					end

					local ScrollFrame = Creator("ScrollingFrame", {
						Size = UDim2.new(1, -4, 1, -60),
						Position = UDim2.new(0, 2, 0, 60),
						CanvasSize = UDim2.new(0, 0, 0, 0),
						ScrollBarThickness = 3,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						VerticalScrollBarInset = Enum.ScrollBarInset.None,
						["Children"] = {
							Creator("UIListLayout", {
								Padding = UDim.new(0, 4),
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							Creator("UIPadding", {
								PaddingLeft = UDim.new(0, 8),
								PaddingRight = UDim.new(0, 8),
								PaddingTop = UDim.new(0, 4),
								PaddingBottom = UDim.new(0, 4),
							})
						}
					}, DialogBackground)
					local function RefreshOptions(SearchText)
						for _, c in ipairs(ScrollFrame:GetChildren()) do
							if c:IsA("TextButton") then c:Destroy() end
						end

						FilteredOptions = {}
						for i, val in ipairs(options) do
							if not SearchText or SearchText == "" or string.find(string.lower(val), string.lower(SearchText), 1, true) then
								table.insert(FilteredOptions, { index = i, value = val })
							end
						end
						for _, data in ipairs(FilteredOptions) do
							local i, val = data.index, data.value
							local btn = Creator("TextButton", {
								Size = UDim2.new(1, -3, 0, 30),
								TextColor3 = Color3.fromRGB(255, 255, 255),
								Text = "",
								TextSize = 12,
								TextStrokeTransparency = 0.1,
								TextStrokeColor3 = Color3.new(255, 255, 255),
								BackgroundTransparency = 0.1,
								TextXAlignment = Enum.TextXAlignment.Center,
								AutoButtonColor = false,
								["Children"] = {
									Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
									Creator("UIGradient", {
										Color = ThemeColor("Lit"),
										Rotation = 70
									}),
									Creator("TextLabel", {
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.new(0.5, 0, 0.5, 0),
										Size = UDim2.new(1, -16, 1, -8),
										Text = val,
										TextSize = 12,
										Font = Enum.Font.GothamBold,
										BackgroundTransparency = 1,
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextStrokeTransparency = 0.1,
										TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
										TextXAlignment = Enum.TextXAlignment.Center,
										TextYAlignment = Enum.TextYAlignment.Center,
									})
								}
							}, ScrollFrame)

							local SelBar = Creator("Frame", {
								Size = UDim2.new(0, 8, 0, 20),
								Position = UDim2.new(0, 5, 0, 5),
								BackgroundTransparency = 0,
								Visible = table.find(SelectedIndices, i) ~= nil,
								["Children"] = {
									Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
									Creator("UIGradient", {
										Color = ThemeColor("Lit"),
										Rotation = 90
									})
								}
							}, btn)

							btn.MouseButton1Click:Connect(function()
								CircleClick(btn, Mouse.X, Mouse.Y)
								if multimode then
									if table.find(SelectedIndices, i) then
										RemoveIndex(i)
										SelBar.Visible = false
									else
										AddIndex(i)
										SelBar.Visible = true
									end
									local selected = SelectedValues()
									SelectedText.Text = FormatSelection(selected, 2)
									callback(selected)
								else
									SelectedIndices = {i}
									SelectedText.Text = options[i]
									callback(options[i])
									CloseDialog()
								end
							end)
						end
						if multimode then
							SelectedText.Text = FormatSelection(SelectedValues(), 2)
						else
							SelectedText.Text = options[SelectedIndices[1]] or "None"
						end
					end
					for _, child in ipairs(ScrollFrame:GetChildren()) do
						if child:IsA("UIPadding") then
							child:Destroy()
						end
					end
					Creator("UIPadding", {
						PaddingLeft = UDim.new(0, 4),
						PaddingRight = UDim.new(0, 4),
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
					}, ScrollFrame)

					SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
						RefreshOptions(SearchBox.Text)
					end)
					DropIcon.MouseButton1Click:Connect(function()
						RefreshOptions()
						OpenDialog()
					end)

					CloseButton.MouseButton1Click:Connect(CloseDialog)
					Blocker.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							CloseDialog()
						end
					end)

					callback(multimode and SelectedValues() or options[SelectedIndices[1]] or "None")
					local ResetDropFunc = {}
					ResetDropFunc.Clear = function()
						for _, v in ipairs(ScrollFrame:GetChildren()) do
							if v:IsA("TextButton") then
								v:Destroy()
							end
						end
						SelectedIndices = {}
						SelectedText.Text = "None"
						callback(multimode and {} or "None")
					end

					ResetDropFunc.Refresh = function(NewOptions)
						NewOptions = NewOptions or {}
						options = NewOptions

						local PreviousValues = SelectedValues()
						SelectedIndices = {}

						local function ReAdd(val)
							if val then
								local idx = table.find(options, val)
								if idx then AddIndex(idx) end
							end
						end
						if multimode then
							for _, val in ipairs(PreviousValues) do
								ReAdd(val)
							end
							if #SelectedIndices == 0 then AddIndex(1) end
						else
							ReAdd(PreviousValues[1])
							if #SelectedIndices == 0 then AddIndex(1) end
						end

						SelectedText.Text = multimode and table.concat(SelectedValues(), ", ") or (options[SelectedIndices[1]] or "None")
						RefreshOptions(SearchBox.Text)
					end
					return {
						Clear = function(self)
							ResetDropFunc.Clear()
						end,
						Refresh = function(self, NewOptions)
							ResetDropFunc.Refresh(NewOptions)
						end,
					}
				end
				function Funcs:addTextbox(text_tile, callback)
					callback = callback or function() end

					local TextBoxFrame = Creator("Frame", {
						BackgroundColor3 = ThemeColor("Primary"),
						BackgroundTransparency = 0.4,
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 30),
						ClipsDescendants = true,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 4)
							})
						}
					}, InnerSection)

					local TextBoxTitle = Creator("TextLabel", {
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

					local TextBox = Creator("TextBox", {
						BackgroundColor3 = Color3.fromRGB(19, 19, 25),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 140, 0, 5),
						Size = UDim2.new(0, 60, 0, 20),
						Font = Enum.Font.SourceSansSemibold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 8,
						TextTransparency = 0.5,
						Text = "Enter Here",
						TextScaled = true,
						ClearTextOnFocus = false,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 8)
							})
						}
					}, TextBoxFrame)

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

					local LabelFrame = Creator("Frame", {
						BackgroundColor3 = ThemeColor("Primary"),
						BackgroundTransparency = 0.4,
						BorderSizePixel = 0,
						Size = UDim2.new(1, -25, 0, 30),
						ClipsDescendants = true,
						["Children"] = {
							Creator("UICorner", {
								CornerRadius = UDim.new(0, 6)
							})
						}
					}, InnerSection)

					local TitleFrame = Creator("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -10, 1, 0),
						Position = UDim2.new(0, 5, 0, 0)
					}, LabelFrame)
					local Title = Creator("TextLabel", {
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
						local MaxWidth = 310
						local FontTitle = Enum.Font.GothamBold
						local FontDesc = Enum.Font.Ubuntu
						local FontSizeTitle = 14
						local FontSizeDesc = 12

						local LabelFrame = Creator("Frame", {
							BackgroundColor3 = ThemeColor("Primary"),
							BackgroundTransparency = 0.4,
							BorderSizePixel = 0,
							Size = UDim2.new(1, -24, 0, 50),
							ClipsDescendants = true,
							["Children"] = {
								Creator("UICorner", { CornerRadius = UDim.new(0, 6) })
							}
						}, InnerSection)

						local TitleFrame = Creator("Frame", {
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 20),
							Position = UDim2.new(0, 0, 0, 0)
						}, LabelFrame)

						local Title = Creator("TextLabel", {
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -10, 1, 0),
							Position = UDim2.new(0, 5, 0, 7),
							Font = FontTitle,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = FontSizeTitle,
							TextWrapped = true,
							RichText = true,
							TextXAlignment = Enum.TextXAlignment.Center,
							Text = title_text or "Default Title"
						}, TitleFrame)

						local DescFrame = Creator("Frame", {
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 20),
							Position = UDim2.new(0, 0, 0, 30)
						}, LabelFrame)

						local Description = Creator("TextLabel", {
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -10, 1, 0),
							Position = UDim2.new(0, 5, 0, 0),
							Font = FontDesc,
							TextColor3 = Color3.fromRGB(200, 200, 200),
							TextSize = FontSizeDesc,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
							RichText = true,
							Text = description_text or "Default description."
						}, DescFrame)

						local function CleanRichText(text)
							return (text:gsub("<[^>]->", ""))
						end

						local function GetTextHeight(text, font, size, width)
							local clean = CleanRichText(text)
							local result = game:GetService("TextService"):GetTextSize(clean, size, font, Vector2.new(width, math.huge))
							return result.Y
						end

						local function AdjustFrameHeight()
							task.wait()
							Title.Text = title_text or ""
							Description.Text = description_text or ""

							local TitleHeight = GetTextHeight(Title.Text, FontTitle, FontSizeTitle, MaxWidth)
							local DescHeight = GetTextHeight(Description.Text, FontDesc, FontSizeDesc, MaxWidth)

							TitleFrame.Size = UDim2.new(1, 0, 0, TitleHeight)
							DescFrame.Position = UDim2.new(0, 0, 0, TitleHeight + PaddingBetweenLabels)
							DescFrame.Size = UDim2.new(1, 0, 0, DescHeight)

							local TotalHeight = TitleHeight + DescHeight + PaddingBetweenLabels + PaddingFrame
							LabelFrame.Size = UDim2.new(1, -20, 0, TotalHeight)
						end

						AdjustFrameHeight()

						function LabelFunc:RefreshTitle(NewTitle)
							title_text = NewTitle
							AdjustFrameHeight()
						end

						function LabelFunc:RefreshDesc(NewDesc)
							description_text = NewDesc
							AdjustFrameHeight()
						end

						return LabelFunc
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
end
