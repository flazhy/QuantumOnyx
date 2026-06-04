local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local env = getgenv() or _G

local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir = dir or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end

local function Protect(gui)
    if env.HIDEUI then
        gui.Parent = env.HIDEUI
    elseif gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
    else
        gui.Parent = game:GetService("CoreGui")
    end
end

local KeyLibrary = {}

function KeyLibrary:Create(config)
    config = config or {}
    local hubName = config.Name or "Quantum Onyx"
    local supportInfo = config.SupportInfo or {}
    local updateLog = config.UpdateLog or {}
    local onKeySubmit = config.OnKeySubmit or function(key) print("Key submitted:", key) end
    local onFreeClick = config.OnFreeClick or function() print("Free version selected") end

    local SG = Instance.new("ScreenGui")
    SG.Name = "KeyUI_" .. math.random(100000, 999999)
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true
    Protect(SG)

    local W, H = 480, 340

    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(0, W*0.6, 0, H*0.6)
    Card.Position = UDim2.new(0.5, 0, 0.5, 0)
    Card.AnchorPoint = Vector2.new(0.5, 0.5)
    Card.BackgroundColor3 = Color3.fromRGB(6, 3, 12)
    Card.BackgroundTransparency = 0.8
    Card.BorderSizePixel = 0
    Card.ZIndex = 201
    Card.ClipsDescendants = true
    Card.Parent = SG

    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", Card)
    stroke.Color = Color3.fromRGB(110, 50, 210)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.35

    local glow1 = Instance.new("Frame", Card)
    glow1.BackgroundColor3 = Color3.fromRGB(80,20,160)
    glow1.BackgroundTransparency = 0.85
    glow1.Size = UDim2.new(0, 240, 0, 240)
    glow1.Position = UDim2.new(0, -80, 0, -80)
    Instance.new("UICorner", glow1).CornerRadius = UDim.new(1, 0)

    local glow2 = Instance.new("Frame", Card)
    glow2.BackgroundColor3 = Color3.fromRGB(40,10,110)
    glow2.BackgroundTransparency = 0.88
    glow2.Size = UDim2.new(0, 200, 0, 200)
    glow2.Position = UDim2.new(1, -120, 1, -120)
    Instance.new("UICorner", glow2).CornerRadius = UDim.new(1, 0)

    local Header = Instance.new("Frame", Card)
    Header.Size = UDim2.new(1, 0, 0, 46)
    Header.BackgroundColor3 = Color3.fromRGB(9,5,18)
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0,14)

    local title = Instance.new("TextLabel", Header)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 42, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = hubName .. " — Key System"
    title.TextColor3 = Color3.fromRGB(220, 200, 255)
    title.TextSize = 14.5
    title.Font = Enum.Font.FredokaOne
    title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("ImageButton", Header)
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://79324227570635"
    CloseBtn.ImageColor3 = Color3.fromRGB(200, 80, 80)

    local RX = 195
    local RW = W - RX - 25

    local StatusLabel = Instance.new("TextLabel", Card)
    StatusLabel.Size = UDim2.new(0, RW, 0, 16)
    StatusLabel.Position = UDim2.new(0, RX, 0, 158)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 9.5
    StatusLabel.TextColor3 = Color3.fromRGB(155, 135, 190)
    StatusLabel.Text = ""

    local InputBg = Instance.new("Frame", Card)
    InputBg.Size = UDim2.new(0, RW, 0, 36)
    InputBg.Position = UDim2.new(0, RX, 0, 115)
    InputBg.BackgroundColor3 = Color3.fromRGB(4,2,9)
    Instance.new("UICorner", InputBg).CornerRadius = UDim.new(0,7)

    local KeyInput = Instance.new("TextBox", InputBg)
    KeyInput.Size = UDim2.new(1, -50, 1, 0)
    KeyInput.Position = UDim2.new(0, 35, 0, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.PlaceholderText = "Enter key here..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(85,60,125)
    KeyInput.TextColor3 = Color3.fromRGB(200,175,255)
    KeyInput.Font = Enum.Font.GothamBold
    KeyInput.TextSize = 11.5
    KeyInput.ClearTextOnFocus = false
    local function CreateButton(text, posX, color, callback)
        local btn = Instance.new("TextButton", Card)
        btn.Size = UDim2.new(0, 92, 0, 32)
        btn.Position = UDim2.new(0, posX, 0, 182)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.25
        btn.Text = ""
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)

        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(235, 235, 255)
        label.Font = Enum.Font.FredokaOne
        label.TextSize = 13.5

        btn.MouseButton1Click:Connect(function()
            callback()
        end)

        return btn
    end
    CreateButton("Free Version", RX, Color3.fromRGB(35,14,70), function()
        onFreeClick()
        SG:Destroy()
    end)

    CreateButton("Get Key", RX + 98, Color3.fromRGB(12,35,70), function()
        setclipboard("https://ads.luarmor.net/get_key?for=Quantum_Onyx_Keysytem-gyvyVEssDcDO")
        StatusLabel.Text = "Link copied to clipboard!"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    end)

    CreateButton("Submit", RX + 196, Color3.fromRGB(48,14,100), function()
        local key = KeyInput.Text:match("^%s*(.-)%s*$")
        if key and key ~= "" then
            StatusLabel.Text = "Validating..."
            StatusLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
            onKeySubmit(key)
        else
            StatusLabel.Text = "Please enter a key"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 140, 100)
        end
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        SG:Destroy()
    end)
    Tween(Card, {Size = UDim2.new(0, W, 0, H), BackgroundTransparency = 0}, 0.45, Enum.EasingStyle.Back)
    return {
        Status = StatusLabel,
        Input = KeyInput,
        Destroy = function() SG:Destroy() end,
    }
end

return KeyLibrary
