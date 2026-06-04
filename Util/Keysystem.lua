
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local env = getgenv() or _G

local KeyLibrary = {}

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

local function CircleRipple(btn, mx, my)
    task.spawn(function()
        btn.ClipsDescendants = true
        local nx = mx - btn.AbsolutePosition.X
        local ny = my - btn.AbsolutePosition.Y
        local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.6
        local c = Instance.new("ImageLabel", btn)
        c.Name = "Ripple"
        c.Image = "rbxassetid://266543268"
        c.ImageColor3 = Color3.fromRGB(255,255,255)
        c.ImageTransparency = 0.82
        c.BackgroundTransparency = 1
        c.ZIndex = btn.ZIndex + 5
        c.Size = UDim2.new(0,0,0,0)
        c.Position = UDim2.new(0,nx,0,ny)
        
        Tween(c, {Size = UDim2.new(0,sz,0,sz), Position = UDim2.new(0.5,-sz/2,0.5,-sz/2)}, 0.45)
        Tween(c, {ImageTransparency = 1}, 0.45)
        task.wait(0.5)
        c:Destroy()
    end)
end

function KeyLibrary:Create(config)
    config = config or {}
    local hubName = config.Name or "Quantum Onyx"
    local supportInfo = config.SupportInfo or {}
    local updateLog = config.UpdateLog or {}
    
    local onFree = config.OnFree or function() end
    local onSubmit = config.OnSubmit or function(key) end

    local SG = Instance.new("ScreenGui")
    SG.Name = "QuantumKeyUI"
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true
    Protect(SG)

    local W, H = 450, 310

    local Card = Instance.new("Frame", SG)
    Card.AnchorPoint = Vector2.new(0.5, 0.5)
    Card.Position = UDim2.new(0.5, 0, 0.5, 0)
    Card.Size = UDim2.new(0, W*0.5, 0, H*0.5)
    Card.BackgroundColor3 = Color3.fromRGB(6,3,12)
    Card.BackgroundTransparency = 0.80
    Card.BorderSizePixel = 0
    Card.ZIndex = 201
    Card.ClipsDescendants = true

    Instance.new("UICorner", Card).CornerRadius = UDim.new(0,14)
    local stroke = Instance.new("UIStroke", Card)
    stroke.Color = Color3.fromRGB(110,50,210)
    stroke.Transparency = 0.38
    stroke.Thickness = 1

    Instance.new("Frame", Card).BackgroundColor3 = Color3.fromRGB(80,20,160)
    Instance.new("Frame", Card).BackgroundTransparency = 0.88
    Instance.new("Frame", Card).Size = UDim2.new(0,220,0,220)
    Instance.new("Frame", Card).Position = UDim2.new(0,-60,0,-60)
    Instance.new("UICorner", Instance.new("Frame", Card)).CornerRadius = UDim.new(1,0)

    Instance.new("Frame", Card).BackgroundColor3 = Color3.fromRGB(40,10,110)
    Instance.new("Frame", Card).BackgroundTransparency = 0.90
    Instance.new("Frame", Card).Size = UDim2.new(0,180,0,180)
    Instance.new("Frame", Card).Position = UDim2.new(1,-100,1,-100)
    Instance.new("UICorner", Instance.new("Frame", Card)).CornerRadius = UDim.new(1,0)
    local Header = Instance.new("Frame", Card)
    Header.Size = UDim2.new(1,0,0,44)
    Header.BackgroundColor3 = Color3.fromRGB(9,5,18)
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0,14)

    Instance.new("ImageLabel", Header).Image = "rbxassetid://7733992528"
    Instance.new("ImageLabel", Header).ImageColor3 = Color3.fromRGB(155,90,255)
    Instance.new("ImageLabel", Header).Size = UDim2.new(0,16,0,16)
    Instance.new("ImageLabel", Header).Position = UDim2.new(0,13,0.5,-8)

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1,-130,1,0)
    Title.Position = UDim2.new(0,35,0,0)
    Title.BackgroundTransparency = 1
    Title.Text = hubName .. " — Key System"
    Title.TextColor3 = Color3.fromRGB(220,200,255)
    Title.TextSize = 14
    Title.Font = Enum.Font.FredokaOne
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Badge = Instance.new("Frame", Header)
    Badge.Size = UDim2.new(0,72,0,20)
    Badge.Position = UDim2.new(1,-40,0.5,0)
    Badge.AnchorPoint = Vector2.new(1,0.5)
    Badge.BackgroundColor3 = Color3.fromRGB(30,60,20)
    Badge.BackgroundTransparency = 0.35
    Instance.new("UICorner", Badge).CornerRadius = UDim.new(0,5)
    Instance.new("UIStroke", Badge).Color = Color3.fromRGB(80,200,110)

    Instance.new("TextLabel", Badge).Text = "Freemium"
    Instance.new("TextLabel", Badge).TextColor3 = Color3.fromRGB(130,235,160)
    Instance.new("TextLabel", Badge).Font = Enum.Font.GothamBold
    Instance.new("TextLabel", Badge).TextSize = 10
    Instance.new("TextLabel", Badge).Size = UDim2.new(1,0,1,0)

    local CloseBtn = Instance.new("ImageButton", Header)
    CloseBtn.Size = UDim2.new(0,20,0,20)
    CloseBtn.Position = UDim2.new(1,-8,0.5,0)
    CloseBtn.AnchorPoint = Vector2.new(1,0.5)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://79324227570635"
    CloseBtn.ImageColor3 = Color3.fromRGB(200,80,80)

    local LW = 180
    local RX = LW + 18
    local RW = W - RX - 10

    local StatusLabel = Instance.new("TextLabel", Card)
    StatusLabel.Position = UDim2.new(0, RX, 0, 150)
    StatusLabel.Size = UDim2.new(0, RW, 0, 13)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 9
    StatusLabel.TextColor3 = Color3.fromRGB(155,135,190)
    StatusLabel.Text = ""

    local InputBg = Instance.new("Frame", Card)
    InputBg.Position = UDim2.new(0, RX, 0, 110)
    InputBg.Size = UDim2.new(0, RW, 0, 34)
    InputBg.BackgroundColor3 = Color3.fromRGB(4,2,9)
    Instance.new("UICorner", InputBg).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke", InputBg).Color = Color3.fromRGB(110,55,200)

    local KeyInput = Instance.new("TextBox", InputBg)
    KeyInput.Size = UDim2.new(1,-54,1,0)
    KeyInput.Position = UDim2.new(0,30,0,0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.PlaceholderText = "Enter premium key..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(85,60,125)
    KeyInput.TextColor3 = Color3.fromRGB(200,175,255)
    KeyInput.Font = Enum.Font.GothamBold
    KeyInput.TextSize = 11
    KeyInput.ClearTextOnFocus = false
    local BtnY = 168
    local BtnH = 30
    local BtnGap = 6
    local BtnW = math.floor((RW - BtnGap*2) / 3)

    local function MakeButton(text, x, color, callback)
        local btn = Instance.new("TextButton", Card)
        btn.Position = UDim2.new(0, x, 0, BtnY)
        btn.Size = UDim2.new(0, BtnW, 0, BtnH)
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.28
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 202
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(235,220,255)
        lbl.Font = Enum.Font.FredokaOne
        lbl.TextSize = 13

        btn.MouseButton1Click:Connect(function()
            CircleRipple(btn, LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y)
            callback()
        end)

        btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.08}, 0.12) end)
        btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 0.28}, 0.16) end)
    end
    MakeButton("Free Version", RX, Color3.fromRGB(35,14,70), function()
        onFree()
        SG:Destroy()
    end)

    MakeButton("Get Key", RX + BtnW + BtnGap, Color3.fromRGB(12,35,70), function()
        setclipboard("https://ads.luarmor.net/get_key?for=Quantum_Onyx_Keysytem-gyvyVEssDcDO")
        StatusLabel.Text = "Key link copied!"
        StatusLabel.TextColor3 = Color3.fromRGB(105,195,255)
    end)

    MakeButton("Enter Key", RX + (BtnW + BtnGap)*2, Color3.fromRGB(48,14,100), function()
        onSubmit(KeyInput.Text)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        SG:Destroy()
    end)
    Tween(Card, {Size = UDim2.new(0,W,0,H), BackgroundTransparency = 0}, 0.45, Enum.EasingStyle.Back)

    return {
        StatusLabel = StatusLabel,
        KeyInput = KeyInput,
        Destroy = function() SG:Destroy() end
    }
end

return KeyLibrary
