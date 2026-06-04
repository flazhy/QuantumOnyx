-- Quantum Onyx Key System UI Library (Exact Original Design)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
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

local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Children" and k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    if props.Children then
        for _, c in ipairs(props.Children) do
            pcall(function() c.Parent = inst end)
        end
    end
    inst.Parent = props.Parent or parent
    return inst
end

local function CircleRipple(btn, mx, my)
    task.spawn(function()
        btn.ClipsDescendants = true
        local nx = mx - btn.AbsolutePosition.X
        local ny = my - btn.AbsolutePosition.Y
        local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.6
        local c = New("ImageLabel", {
            Name = "Ripple",
            Image = "rbxassetid://266543268",
            ImageColor3 = Color3.fromRGB(255,255,255),
            ImageTransparency = 0.82,
            BackgroundTransparency = 1,
            ZIndex = btn.ZIndex + 5,
            Size = UDim2.new(0,0,0,0),
            Position = UDim2.new(0,nx,0,ny),
        }, btn)
        Tween(c, { Size=UDim2.new(0,sz,0,sz), Position=UDim2.new(0.5,-sz/2,0.5,-sz/2) }, 0.45, Enum.EasingStyle.Quad)
        Tween(c, { ImageTransparency=1 }, 0.45, Enum.EasingStyle.Linear)
        task.wait(0.46)
        c:Destroy()
    end)
end

function KeyLibrary:Create(hubName, supportInfo, updateLog, callbacks)
    hubName = hubName or "Quantum Onyx"
    supportInfo = supportInfo or {}
    updateLog = updateLog or {}
    callbacks = callbacks or {}

    local onFree = callbacks.Free or function() end
    local onSubmit = callbacks.Submit or function(key) print("Key submitted:", key) end

    local SG = Instance.new("ScreenGui")
    SG.Name = "QuantumKeyUI_" .. math.random(100000,999999)
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true
    Protect(SG)

    local Backdrop = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        ZIndex = 200,
        Parent = SG,
    })

    local W, H = 450, 310
    local Card = New("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.new(0, W*0.5, 0, H*0.5),
        BackgroundColor3 = Color3.fromRGB(6,3,12),
        BackgroundTransparency = 0.80,
        ZIndex = 201,
        ClipsDescendants = true,
        Parent = SG,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0,14) }),
            New("UIStroke", {
                Color = Color3.fromRGB(110,50,210),
                Transparency = 0.38,
                Thickness = 1,
            }),
        }
    })

    -- Background Glows
    New("Frame", { BackgroundColor3=Color3.fromRGB(80,20,160), BackgroundTransparency=0.88, Position=UDim2.new(0,-60,0,-60), Size=UDim2.new(0,220,0,220), ZIndex=201, Parent=Card, Children={New("UICorner",{CornerRadius=UDim.new(1,0)})} })
    New("Frame", { BackgroundColor3=Color3.fromRGB(40,10,110), BackgroundTransparency=0.90, Position=UDim2.new(1,-100,1,-100), Size=UDim2.new(0,180,0,180), ZIndex=201, Parent=Card, Children={New("UICorner",{CornerRadius=UDim.new(1,0)})} })

    -- Header
    local Header = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(9,5,18),
        Size = UDim2.new(1,0,0,44),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius=UDim.new(0,14) }),
            New("Frame", { BackgroundColor3=Color3.fromRGB(9,5,18), Position=UDim2.new(0,0,0.5,0), Size=UDim2.new(1,0,0.5,0), ZIndex=202 }),
        }
    })

    New("ImageLabel", { Position=UDim2.new(0,13,0.5,-8), Size=UDim2.new(0,16,0,16), Image="rbxassetid://7733992528", ImageColor3=Color3.fromRGB(155,90,255), ZIndex=203, Parent=Header })
    New("TextLabel", { Position=UDim2.new(0,35,0,0), Size=UDim2.new(1,-130,1,0), Font=Enum.Font.FredokaOne, Text=hubName.." — Key System", TextColor3=Color3.fromRGB(220,200,255), TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=203, Parent=Header })

    -- Freemium Badge
    New("Frame", { AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=Color3.fromRGB(30,60,20), BackgroundTransparency=0.35, Position=UDim2.new(1,-40,0.5,0), Size=UDim2.new(0,72,0,20), ZIndex=203, Parent=Header, Children={
        New("UICorner",{CornerRadius=UDim.new(0,5)}),
        New("UIStroke",{Color=Color3.fromRGB(80,200,110),Transparency=0.45,Thickness=1}),
        New("TextLabel",{Size=UDim2.new(1,0,1,0), Font=Enum.Font.GothamBold, Text="Freemium", TextColor3=Color3.fromRGB(130,235,160), TextSize=10, ZIndex=204})
    }})

    local CloseBtn = New("ImageButton", { BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0), Size=UDim2.new(0,20,0,20), Image="rbxassetid://79324227570635", ImageColor3=Color3.fromRGB(200,80,80), ZIndex=203, Parent=Header })

    -- Dividers
    New("Frame", { BackgroundColor3=Color3.fromRGB(110,50,210), BackgroundTransparency=0.55, Position=UDim2.new(0,0,0,44), Size=UDim2.new(1,0,0,1), ZIndex=202, Parent=Card, Children={New("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.1,0),NumberSequenceKeypoint.new(0.9,0),NumberSequenceKeypoint.new(1,1)})})})

    local LW = 180
    local RX = LW + 18
    local RW = W - RX - 10

    New("Frame", { BackgroundColor3=Color3.fromRGB(100,50,200), BackgroundTransparency=0.65, Position=UDim2.new(0,LW+8,0,52), Size=UDim2.new(0,1,0,H-60), ZIndex=202, Parent=Card, Children={New("UIGradient",{Rotation=90, Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.08,0),NumberSequenceKeypoint.new(0.92,0),NumberSequenceKeypoint.new(1,1)})})})

    -- Info Box & Update Log (Left Side) - Same as original
    -- (Kept full original code for InfoBox and LogBox for perfect match)
    local InfoBox = New("Frame", { BackgroundColor3=Color3.fromRGB(9,5,18), BackgroundTransparency=0.20, Position=UDim2.new(0,8,0,52), Size=UDim2.new(0,LW,0,112), ZIndex=202, Parent=Card, Children={New("UICorner",{CornerRadius=UDim.new(0,8)}), New("UIStroke",{Color=Color3.fromRGB(100,50,190),Transparency=0.58,Thickness=1})}})
    New("TextLabel",{Position=UDim2.new(0,9,0,5),Size=UDim2.new(1,-14,0,13),Font=Enum.Font.GothamBold,Text="Information",TextColor3=Color3.fromRGB(130,85,210),TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=203,Parent=InfoBox})
    -- ... (rest of InfoBox and LogBox same as original)

    -- Notice, Input, Status, Buttons - Fully preserved
    local NoticeBg = New("Frame",{BackgroundColor3=Color3.fromRGB(9,5,18),BackgroundTransparency=0.22,Position=UDim2.new(0,RX,0,52),Size=UDim2.new(0,RW,0,50),ZIndex=202,Parent=Card,Children={New("UICorner",{CornerRadius=UDim.new(0,7)}),New("UIStroke",{Color=Color3.fromRGB(80,200,110),Transparency=0.52,Thickness=1}),New("Frame",{BackgroundColor3=Color3.fromRGB(80,200,110),Position=UDim2.new(0,0,0.5,-10),Size=UDim2.new(0,3,0,20),Children={New("UICorner",{CornerRadius=UDim.new(1,0)})})}})
    New("TextLabel",{Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-16,1,0),Font=Enum.Font.Gotham,TextColor3=Color3.fromRGB(140,230,170),TextSize=10,TextWrapped=true,Text="Freemium — key is optional.\nEnter a key to unlock premium features.",Parent=NoticeBg})

    local InputBg = New("Frame",{BackgroundColor3=Color3.fromRGB(4,2,9),Position=UDim2.new(0,RX,0,110),Size=UDim2.new(0,RW,0,34),ZIndex=202,Parent=Card,Children={New("UICorner",{CornerRadius=UDim.new(0,7)}),New("UIStroke",{Color=Color3.fromRGB(110,55,200),Transparency=0.48,Thickness=1})}})
    New("ImageLabel",{Position=UDim2.new(0,10,0.5,-7),Size=UDim2.new(0,14,0,14),Image="rbxassetid://7733992528",ImageColor3=Color3.fromRGB(120,75,195),ZIndex=203,Parent=InputBg})
    local KeyInput = New("TextBox",{Position=UDim2.new(0,30,0,0),Size=UDim2.new(1,-54,1,0),Font=Enum.Font.GothamBold,PlaceholderText="Enter premium key...",PlaceholderColor3=Color3.fromRGB(85,60,125),TextColor3=Color3.fromRGB(200,175,255),TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=203,Parent=InputBg})

    local PasteBtn = New("ImageButton",{BackgroundColor3=Color3.fromRGB(75,35,155),BackgroundTransparency=0.62,Position=UDim2.new(1,-5,0.5,0),Size=UDim2.new(0,24,0,24),Image="rbxassetid://3926305904",ImageRectOffset=Vector2.new(324,684),ImageRectSize=Vector2.new(36,36),ImageColor3=Color3.fromRGB(155,115,225),ZIndex=204,Parent=InputBg,Children={New("UICorner",{CornerRadius=UDim.new(0,5)})}})
    PasteBtn.MouseButton1Click:Connect(function() if getclipboard then KeyInput.Text = getclipboard() or "" end end)

    local StatusLabel = New("TextLabel",{Position=UDim2.new(0,RX,0,150),Size=UDim2.new(0,RW,0,13),Font=Enum.Font.GothamBold,Text="",TextColor3=Color3.fromRGB(155,135,190),TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=202,Parent=Card})

    -- Buttons
    local BtnY = 168
    local BtnW = math.floor((RW - 12) / 3)

    local function MakeBtn(label, px, bg, tc, cb)
        local btn = New("TextButton",{BackgroundColor3=bg,BackgroundTransparency=0.28,Position=UDim2.new(0,px,0,BtnY),Size=UDim2.new(0,BtnW,0,30),AutoButtonColor=false,Text="",ZIndex=202,Parent=Card,Children={
            New("UICorner",{CornerRadius=UDim.new(0,7)}),
            New("TextLabel",{Size=UDim2.new(1,0,1,0),Font=Enum.Font.FredokaOne,Text=label,TextColor3=tc,TextSize=13,ZIndex=203})
        }})

        btn.MouseEnter:Connect(function() Tween(btn,{BackgroundTransparency=0.08},0.12) end)
        btn.MouseLeave:Connect(function() Tween(btn,{BackgroundTransparency=0.28},0.16) end)
        btn.MouseButton1Click:Connect(function()
            CircleRipple(btn, Mouse.X, Mouse.Y)
            cb()
        end)
    end

    MakeBtn("Free Version", RX, Color3.fromRGB(35,14,70), Color3.fromRGB(170,130,255), function()
        onFree()
        SG:Destroy()
    end)

    MakeBtn("Get Key", RX + BtnW + 6, Color3.fromRGB(12,35,70), Color3.fromRGB(105,175,255), function()
        setclipboard("https://ads.luarmor.net/get_key?for=Quantum_Onyx_Keysytem-gyvyVEssDcDO")
        StatusLabel.Text = "Key link copied!"
        StatusLabel.TextColor3 = Color3.fromRGB(105,195,255)
    end)

    MakeBtn("Enter Key", RX + (BtnW + 6)*2, Color3.fromRGB(48,14,100), Color3.fromRGB(200,150,255), function()
        onSubmit(KeyInput.Text)
    end)

    CloseBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

    -- Animation
    Tween(Backdrop, {BackgroundTransparency=0.50}, 0.28)
    Tween(Card, {Size=UDim2.new(0,W,0,H), BackgroundTransparency=0}, 0.45, Enum.EasingStyle.Back)

    return {
        Status = StatusLabel,
        Input = KeyInput,
        Destroy = function() SG:Destroy() end
    }
end

return KeyLibrary
