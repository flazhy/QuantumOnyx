
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

local canOpen = true
local waitTime = 10

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PremiumPrompt"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.6
overlay.Parent = screenGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 450, 0, 220)
bg.Position = UDim2.new(0.5, 0, 0.5, 0)
bg.AnchorPoint = Vector2.new(0.5, 0.5)
bg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
bg.BackgroundTransparency = 0.1
bg.BorderSizePixel = 0
bg.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 20)
uicorner.Parent = bg

local shadow = Instance.new("UIStroke")
shadow.Color = Color3.fromRGB(255, 255, 255)
shadow.Thickness = 0.7
shadow.Transparency = 0.7
shadow.Parent = bg

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 50)
title.Position = UDim2.new(0, 20, 0, 20)
title.Text = "Original Script Backup"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Parent = bg

local msg = Instance.new("TextLabel")
msg.Size = UDim2.new(1, -40, 0, 90)
msg.Position = UDim2.new(0, 20, 0, 80)
msg.Text = "This is a Beta version. Wait before opening again!"
msg.TextColor3 = Color3.fromRGB(200, 200, 200)
msg.TextWrapped = true
msg.TextScaled = true
msg.BackgroundTransparency = 1
msg.Font = Enum.Font.Gotham
msg.Parent = bg

local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(0, 160, 0, 50)
discordBtn.Position = UDim2.new(0.5, 0, 1, -5)
discordBtn.AnchorPoint = Vector2.new(0.5, 1)
discordBtn.Text = "Join Discord"
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextScaled = true
discordBtn.Parent = bg

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 15)
btnCorner.Parent = discordBtn

discordBtn.MouseEnter:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(114, 137, 218)}):Play()
end)

discordBtn.MouseLeave:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
end)

discordBtn.MouseButton1Click:Connect(function()
    TweenService:Create(discordBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 150, 0, 45)}):Play()
    task.wait(0.1)
    TweenService:Create(discordBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 160, 0, 50)}):Play()

    local discordURL = "https://discord.gg/xF4Xrqq7af"
    setclipboard(discordURL)
end)

bg.Position = UDim2.new(0.5, 0, -0.5, 0)
bg.BackgroundTransparency = 1
TweenService:Create(bg, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 0.1
}):Play()

spawn(function()
    canOpen = false
    task.wait(waitTime)
    canOpen = true
    screenGui:Destroy()
end)

local function ShowPrompt()
    if canOpen then
        screenGui.Enabled = true
    else
        warn("Please wait before opening the Beta prompt again!")
    end
end
ShowPrompt()
