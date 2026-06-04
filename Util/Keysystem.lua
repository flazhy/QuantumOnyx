if not game and game.GetService and game:GetService("RunService") or game.ClassName ~= "DataModel" or (typeof and typeof(game.Players) ~= "Instance") or not (getmetatable and setmetatable and type and pcall and rawget and rawset) then
    repeat task.wait() warn("stop skidding - flazhy") until false
end
local Players        = game:GetService("Players")
local HttpService    = game:GetService("HttpService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()

local LUARMOR = {
    PROJECT_ID  = "b51bc445318cbb9c68b360ff37884e84",
    GET_KEY_URL = "https://ads.luarmor.net/get_key?project=b51bc445318cbb9c68b360ff37884e84",
}

local function GetHTTP()
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    if typeof(http_request) == "function" then return http_request end
    if typeof(request) == "function" then return request end
    if typeof(httprequest) == "function" then return httprequest end
    return nil
end
local function LuarmorLoaderPremium()
    local ok, v = pcall(function() return LRM_IsUserPremium == true end)
    return ok and v == true
end

local function ApplyPremiumState(keyStr, isPremium)
    local env = (getgenv and getgenv()) or _G
    if LuarmorLoaderPremium() then
        isPremium = true
    end
    if isPremium == true then
        env.QuantumLuarmorVerified = true
        env.LRM_IsUserPremium = true
        env.QuantumKeyPremium = true
    else
        env.QuantumLuarmorVerified = false
        env.LRM_IsUserPremium = false
        env.QuantumKeyPremium = false
    end
    if keyStr and keyStr ~= "" then
        env.Key = keyStr
        pcall(function() script_key = keyStr end)
    end
end

local _apiCache = { key = "", at = 0, valid = false, msg = "" }

-- !!! CHANGE THIS TO YOUR ACTUAL SCRIPT ID !!!
local SCRIPT_ID = "0ae9fe4cf963e3a13d25eed0e2ce5940"  -- paste yours here

-- Load the Luarmor key check library
local LuarmorAPI = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
LuarmorAPI.script_id = SCRIPT_ID

local function CheckKeyViaLuarmorAPI(keyStr)
    if LuarmorLoaderPremium() then
        return true, "Premium via Luarmor"
    end

    if not keyStr or keyStr == "" then
        return false, "No key entered"
    end

    if _apiCache.key == keyStr and (tick() - _apiCache.at) < 30 then
        return _apiCache.valid, _apiCache.msg
    end
    local status = LuarmorAPI.check_key(keyStr)
    if status.code == "KEY_VALID" then
        ApplyPremiumState(keyStr, true)
        _apiCache = { key = keyStr, at = tick(), valid = true, msg = "Key verified" }
        return true, "Key verified"
    elseif status.code == "KEY_HWID_LOCKED" then
        _apiCache = { key = keyStr, at = tick(), valid = false, msg = "HWID mismatch – reset key" }
        return false, "HWID mismatch – reset key"
    elseif status.code == "KEY_EXPIRED" then
        _apiCache = { key = keyStr, at = tick(), valid = false, msg = "Key expired" }
        return false, "Key expired"
    elseif status.code == "KEY_BANNED" then
        _apiCache = { key = keyStr, at = tick(), valid = false, msg = "Key banned" }
        return false, "Key banned"
    elseif status.code == "KEY_INCORRECT" then
        _apiCache = { key = keyStr, at = tick(), valid = false, msg = "Key not found" }
        return false, "Key not found"
    else
        _apiCache = { key = keyStr, at = tick(), valid = false, msg = status.message or "Invalid key" }
        return false, status.message or "Invalid key"
    end
end
local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end

local function Protect(gui)
    local env = (getgenv and getgenv()) or _G
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
        local c  = New("ImageLabel", {
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
local FOLDER = "Quantum Onyx Hub"
local KEY_FILE = FOLDER .. "/Key.json"

local function SaveKey(key)
    if not isfolder(FOLDER) then makefolder(FOLDER) end
    pcall(writefile, KEY_FILE, HttpService:JSONEncode({ key = key }))
end

local function LoadSavedKey()
    if isfolder(FOLDER) and isfile(KEY_FILE) then
        local ok, v = pcall(function()
            return HttpService:JSONDecode(readfile(KEY_FILE))
        end)
        if ok and type(v) == "table" and v.key then return v.key end
    end
    return ""
end
local function RunKeyLoader(hubName, supportInfo, updateLog)
    hubName = hubName or "Quantum Onyx"
    supportInfo = supportInfo or {}
    updateLog = updateLog   or {}

    local done = false
    local isPremium = LuarmorLoaderPremium()
    local verifying = false

    if isPremium then
        local saved = LoadSavedKey()
        ApplyPremiumState(saved, true)
        return true, saved
    end

    local SG = Instance.new("ScreenGui")
    SG.Name = "KL_" .. tostring(math.random(1e6))
    SG.ZIndexBehavior  = Enum.ZIndexBehavior.Global
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset  = true
    Protect(SG)

    local Backdrop = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
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
        BorderSizePixel = 0,
        ZIndex = 201,
        ClipsDescendants = true,
        Parent = SG,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0,14) }),
            New("UIStroke", {
                Color = Color3.fromRGB(110,50,210),
                Transparency = 0.38,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        }
    })

    New("Frame", { BackgroundColor3=Color3.fromRGB(80,20,160), BackgroundTransparency=0.88,
        BorderSizePixel=0, Position=UDim2.new(0,-60,0,-60), Size=UDim2.new(0,220,0,220),
        ZIndex=201, Parent=Card, Children={ New("UICorner",{CornerRadius=UDim.new(1,0)}) } })
    New("Frame", { BackgroundColor3=Color3.fromRGB(40,10,110), BackgroundTransparency=0.90,
        BorderSizePixel=0, Position=UDim2.new(1,-100,1,-100), Size=UDim2.new(0,180,0,180),
        ZIndex=201, Parent=Card, Children={ New("UICorner",{CornerRadius=UDim.new(1,0)}) } })

    local Header = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(9,5,18),
        BorderSizePixel  = 0,
        Size = UDim2.new(1,0,0,44),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius=UDim.new(0,14) }),
            New("Frame", { BackgroundColor3=Color3.fromRGB(9,5,18), BorderSizePixel=0,
                Position=UDim2.new(0,0,0.5,0), Size=UDim2.new(1,0,0.5,0), ZIndex=202 }),
        }
    })
    New("ImageLabel", { BackgroundTransparency=1, Position=UDim2.new(0,13,0.5,-8),
        Size=UDim2.new(0,16,0,16), Image="rbxassetid://7733992528",
        ImageColor3=Color3.fromRGB(155,90,255), ZIndex=203, Parent=Header })
    New("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,35,0,0),
        Size=UDim2.new(1,-130,1,0), Font=Enum.Font.FredokaOne,
        Text=hubName.." — Key System", TextColor3=Color3.fromRGB(220,200,255),
        TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=203, Parent=Header })

    New("Frame", { AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=Color3.fromRGB(30,60,20),
        BackgroundTransparency=0.35, BorderSizePixel=0, Position=UDim2.new(1,-40,0.5,0),
        Size=UDim2.new(0,72,0,20), ZIndex=203, Parent=Header,
        Children = {
            New("UICorner",{CornerRadius=UDim.new(0,5)}),
            New("UIStroke",{Color=Color3.fromRGB(80,200,110),Transparency=0.45,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}),
            New("TextLabel",{ BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
                Font=Enum.Font.GothamBold, Text="Freemium", TextColor3=Color3.fromRGB(130,235,160),
                TextSize=10, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=204 }),
        }
    })

    local CloseBtn = New("ImageButton", { BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-8,0.5,0),
        Size=UDim2.new(0,20,0,20), Image="rbxassetid://79324227570635",
        ImageColor3=Color3.fromRGB(200,80,80), ZIndex=203, Parent=Header })

    New("Frame", { BackgroundColor3=Color3.fromRGB(110,50,210), BackgroundTransparency=0.55,
        BorderSizePixel=0, Position=UDim2.new(0,0,0,44), Size=UDim2.new(1,0,0,1),
        ZIndex=202, Parent=Card,
        Children={ New("UIGradient",{ Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.1,0),
            NumberSequenceKeypoint.new(0.9,0), NumberSequenceKeypoint.new(1,1) }) }) }
    })

    local LW = 180
    local RX = LW + 18
    local RW = W - RX - 10

    New("Frame", { BackgroundColor3=Color3.fromRGB(100,50,200), BackgroundTransparency=0.65,
        BorderSizePixel=0, Position=UDim2.new(0,LW+8,0,52), Size=UDim2.new(0,1,0,H-60),
        ZIndex=202, Parent=Card,
        Children={ New("UIGradient",{ Rotation=90, Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.08,0),
            NumberSequenceKeypoint.new(0.92,0), NumberSequenceKeypoint.new(1,1) }) }) }
    })

    local InfoBox = New("Frame", { BackgroundColor3=Color3.fromRGB(9,5,18), BackgroundTransparency=0.20,
        BorderSizePixel=0, Position=UDim2.new(0,8,0,52), Size=UDim2.new(0,LW,0,112),
        ZIndex=202, Parent=Card,
        Children={ New("UICorner",{CornerRadius=UDim.new(0,8)}),
            New("UIStroke",{Color=Color3.fromRGB(100,50,190),Transparency=0.58,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) }
    })
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,5),Size=UDim2.new(1,-14,0,13),
        Font=Enum.Font.GothamBold,Text="Information",TextColor3=Color3.fromRGB(130,85,210),
        TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=203,Parent=InfoBox})
    New("Frame",{BackgroundColor3=Color3.fromRGB(110,60,200),BackgroundTransparency=0.72,
        BorderSizePixel=0,Position=UDim2.new(0,7,0,20),Size=UDim2.new(1,-14,0,1),ZIndex=203,Parent=InfoBox,
        Children={New("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(0.1,0),NumberSequenceKeypoint.new(0.9,0),NumberSequenceKeypoint.new(1,1)})})}})
    local rowY = 26
    for _, info in ipairs(supportInfo) do
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,rowY),Size=UDim2.new(0,55,0,12),
            Font=Enum.Font.GothamBold,Text=(info.label or "")..":",TextColor3=Color3.fromRGB(115,85,165),
            TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=203,Parent=InfoBox})
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,64,0,rowY),Size=UDim2.new(1,-70,0,12),
            Font=Enum.Font.Gotham,Text=tostring(info.value or ""),TextColor3=Color3.fromRGB(180,155,220),
            TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=203,Parent=InfoBox})
        rowY = rowY + 16
        if rowY > 96 then break end
    end

    local LogBox = New("Frame",{BackgroundColor3=Color3.fromRGB(9,5,18),BackgroundTransparency=0.20,
        BorderSizePixel=0,Position=UDim2.new(0,8,0,170),Size=UDim2.new(0,LW,0,128),
        ZIndex=202,Parent=Card,
        Children={New("UICorner",{CornerRadius=UDim.new(0,8)}),
            New("UIStroke",{Color=Color3.fromRGB(100,50,190),Transparency=0.58,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})}})
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,5),Size=UDim2.new(1,-14,0,13),
        Font=Enum.Font.GothamBold,Text="Update Log",TextColor3=Color3.fromRGB(130,85,210),
        TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=203,Parent=LogBox})
    New("Frame",{BackgroundColor3=Color3.fromRGB(110,60,200),BackgroundTransparency=0.72,
        BorderSizePixel=0,Position=UDim2.new(0,7,0,20),Size=UDim2.new(1,-14,0,1),ZIndex=203,Parent=LogBox,
        Children={New("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(0.1,0),NumberSequenceKeypoint.new(0.9,0),NumberSequenceKeypoint.new(1,1)})})}})
    local logY = 26
    for _, entry in ipairs(updateLog) do
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,logY),Size=UDim2.new(1,-14,0,12),
            Font=Enum.Font.GothamBold,RichText=true,
            Text=string.format('<font color="#a855f7">%s</font>  <font color="#554466">%s</font>',
                entry.version or "", entry.date or ""),
            TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=203,Parent=LogBox})
        logY = logY + 13
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,13,0,logY),Size=UDim2.new(1,-18,0,11),
            Font=Enum.Font.Gotham,Text="• "..(entry.notes or ""),TextColor3=Color3.fromRGB(150,135,185),
            TextSize=8,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=203,Parent=LogBox})
        logY = logY + 14
        if logY > 110 then break end
    end

    local NoticeBg = New("Frame",{BackgroundColor3=Color3.fromRGB(9,5,18),BackgroundTransparency=0.22,
        BorderSizePixel=0,Position=UDim2.new(0,RX,0,52),Size=UDim2.new(0,RW,0,50),ZIndex=202,Parent=Card,
        Children={New("UICorner",{CornerRadius=UDim.new(0,7)}),
            New("UIStroke",{Color=Color3.fromRGB(80,200,110),Transparency=0.52,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}),
            New("Frame",{BackgroundColor3=Color3.fromRGB(80,200,110),BorderSizePixel=0,
                Position=UDim2.new(0,0,0.5,-10),Size=UDim2.new(0,3,0,20),ZIndex=203,
                Children={New("UICorner",{CornerRadius=UDim.new(1,0)})}}) }})
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-16,1,0),
        Font=Enum.Font.Gotham,TextColor3=Color3.fromRGB(140,230,170),TextSize=10,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=203,
        Text="Freemium — key is optional.\nEnter a key to unlock premium features.",Parent=NoticeBg})

    local LRMBar = New("Frame",{BackgroundColor3=Color3.fromRGB(9,5,18),BackgroundTransparency=0.22,
        BorderSizePixel=0,Position=UDim2.new(0,RX,0,110),Size=UDim2.new(0,RW,0,28),ZIndex=202,Parent=Card,
        Children={New("UICorner",{CornerRadius=UDim.new(0,6)}),
            New("UIStroke",{Color=Color3.fromRGB(100,50,190),Transparency=0.60,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})}})
    New("ImageLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0.5,-6),Size=UDim2.new(0,12,0,12),
        Image="rbxassetid://7733992528",ImageColor3=Color3.fromRGB(130,80,200),ZIndex=203,Parent=LRMBar})
    local LRMStatusLabel = New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,25,0,0),
        Size=UDim2.new(1,-30,1,0),Font=Enum.Font.GothamBold,Text="Checking Luarmor...",
        TextColor3=Color3.fromRGB(160,140,200),TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=203,Parent=LRMBar})

    local InputBg = New("Frame",{BackgroundColor3=Color3.fromRGB(4,2,9),BackgroundTransparency=0,
        BorderSizePixel=0,Position=UDim2.new(0,RX,0,146),Size=UDim2.new(0,RW,0,34),ZIndex=202,Parent=Card,
        Children={New("UICorner",{CornerRadius=UDim.new(0,7)}),
            New("UIStroke",{Color=Color3.fromRGB(110,55,200),Transparency=0.48,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})}})
    New("ImageLabel",{BackgroundTransparency=1,Position=UDim2.new(0,10,0.5,-7),Size=UDim2.new(0,14,0,14),
        Image="rbxassetid://7733992528",ImageColor3=Color3.fromRGB(120,75,195),ZIndex=203,Parent=InputBg})
    local KeyInput = New("TextBox",{BackgroundTransparency=1,Position=UDim2.new(0,30,0,0),
        Size=UDim2.new(1,-54,1,0),Font=Enum.Font.GothamBold,PlaceholderText="Enter premium key...",
        PlaceholderColor3=Color3.fromRGB(85,60,125),Text="",TextColor3=Color3.fromRGB(200,175,255),
        TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=203,Parent=InputBg})
    local PasteBtn = New("ImageButton",{BackgroundColor3=Color3.fromRGB(75,35,155),BackgroundTransparency=0.62,
        BorderSizePixel=0,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-5,0.5,0),
        Size=UDim2.new(0,24,0,24),Image="rbxassetid://3926305904",ImageRectOffset=Vector2.new(324,684),
        ImageRectSize=Vector2.new(36,36),ImageColor3=Color3.fromRGB(155,115,225),ZIndex=204,Parent=InputBg,
        Children={New("UICorner",{CornerRadius=UDim.new(0,5)})}})
    PasteBtn.MouseEnter:Connect(function() Tween(PasteBtn,{BackgroundTransparency=0.30},0.12) end)
    PasteBtn.MouseLeave:Connect(function() Tween(PasteBtn,{BackgroundTransparency=0.62},0.16) end)
    PasteBtn.MouseButton1Click:Connect(function()
        if getclipboard then KeyInput.Text = getclipboard() or "" end
    end)

    local StatusLabel = New("TextLabel",{BackgroundTransparency=1,
        Position=UDim2.new(0,RX,0,185),Size=UDim2.new(0,RW,0,13),
        Font=Enum.Font.GothamBold,Text="",TextColor3=Color3.fromRGB(155,135,190),
        TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=202,Parent=Card})

    local BtnY = 202
    local BtnH = 30
    local BtnGap = 6
    local BtnW = math.floor((RW - BtnGap*2) / 3)

    local function MakeBtn(label, px, w, bg, tc, cb)
        local btn = New("TextButton",{BackgroundColor3=bg,BackgroundTransparency=0.28,
            BorderSizePixel=0,Position=UDim2.new(0,px,0,BtnY),Size=UDim2.new(0,w,0,BtnH),
            AutoButtonColor=false,Text="",ClipsDescendants=true,ZIndex=202,Parent=Card,
            Children={New("UICorner",{CornerRadius=UDim.new(0,7)}),
                New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
                    Font=Enum.Font.FredokaOne,Text=label,TextColor3=tc,TextSize=13,
                    TextXAlignment=Enum.TextXAlignment.Center,ZIndex=203})}})
        btn.MouseEnter:Connect(function() Tween(btn,{BackgroundTransparency=0.08},0.12) end)
        btn.MouseLeave:Connect(function() Tween(btn,{BackgroundTransparency=0.28},0.16) end)
        btn.MouseButton1Click:Connect(function()
            CircleRipple(btn, Mouse.X, Mouse.Y)
            cb()
        end)
        return btn
    end

    local function AnimateClose()
        Tween(Card, {Size=UDim2.new(0,W*0.65,0,H*0.65),BackgroundTransparency=0.75}, 0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(Backdrop, {BackgroundTransparency=1}, 0.20, Enum.EasingStyle.Quint)
        task.delay(0.22, function() SG:Destroy() done = true end)
    end

    local function VerifyKey(keyStr)
        if verifying then return end
        verifying = true

        StatusLabel.Text = "Checking Luarmor API..."
        StatusLabel.TextColor3 = Color3.fromRGB(175,150,255)

        task.spawn(function()
            local valid, message = CheckKeyViaLuarmorAPI(keyStr)
            verifying = false

            if valid then
                isPremium = true
                SaveKey(keyStr)
                ApplyPremiumState(keyStr, true)
                StatusLabel.Text = " " .. message
                StatusLabel.TextColor3 = Color3.fromRGB(80,230,130)
                LRMStatusLabel.Text = "Premium Active"
                LRMStatusLabel.TextColor3 = Color3.fromRGB(80,230,130)
                task.wait(0.15)
                AnimateClose()
            else
                ApplyPremiumState(keyStr, false)
                StatusLabel.Text = "" .. (message or "Key invalid")
                StatusLabel.TextColor3 = Color3.fromRGB(255,90,110)
                LRMStatusLabel.Text = "Not Verified"
                LRMStatusLabel.TextColor3 = Color3.fromRGB(200,100,100)
            end
        end)
    end

    MakeBtn("Free Version", RX, BtnW,
        Color3.fromRGB(35,14,70), Color3.fromRGB(170,130,255),
        function()
            isPremium = false
            AnimateClose()
        end)

    MakeBtn("Get Key", RX + BtnW + BtnGap, BtnW,
        Color3.fromRGB(12,35,70), Color3.fromRGB(105,175,255),
        function()
            StatusLabel.Text = "Opening key link..."
            StatusLabel.TextColor3 = Color3.fromRGB(175,150,255)
            task.spawn(function()
                pcall(function() (setclipboard or toclipboard)(LUARMOR.GET_KEY_URL) end)
                StatusLabel.Text = "Key link copied to clipboard!"
                StatusLabel.TextColor3 = Color3.fromRGB(105,195,255)
            end)
        end)

    MakeBtn("Enter Key", RX + (BtnW + BtnGap)*2, BtnW,
        Color3.fromRGB(48,14,100), Color3.fromRGB(200,150,255),
        function()
            local k = KeyInput.Text
            if not k or k == "" then
                StatusLabel.Text = "Please enter a key first."
                StatusLabel.TextColor3 = Color3.fromRGB(255,175,80)
                return
            end
            VerifyKey(k)
        end)

    local SY = BtnY + BtnH + 14
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,RX,0,SY),Size=UDim2.new(0,RW,0,12),
        Font=Enum.Font.GothamBold,Text="Community",TextColor3=Color3.fromRGB(200,170,65),
        TextSize=9,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=202,Parent=Card})

    local socials = {
        { img="rbxassetid://129297846250682", col=Color3.fromRGB(100,120,255) },
        { img="http://www.roblox.com/asset/?id=14620084334", col=Color3.fromRGB(185,130,255) },
    }
    local icSz = 26
    local totW = #socials * icSz + (#socials-1)*8
    local stX  = RX + math.floor((RW - totW)/2)
    for i, sd in ipairs(socials) do
        local ic = New("ImageButton",{BackgroundColor3=sd.col,BackgroundTransparency=0.68,BorderSizePixel=0,
            Position=UDim2.new(0,stX+(i-1)*(icSz+8),0,SY+15),Size=UDim2.new(0,icSz,0,icSz),
            Image=sd.img,ImageColor3=Color3.fromRGB(255,255,255),ZIndex=202,Parent=Card,
            Children={New("UICorner",{CornerRadius=UDim.new(1,0)}),
                New("UIStroke",{Color=sd.col,Transparency=0.40,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})}})
        ic.MouseEnter:Connect(function() Tween(ic,{BackgroundTransparency=0.28},0.12) end)
        ic.MouseLeave:Connect(function() Tween(ic,{BackgroundTransparency=0.68},0.16) end)
    end

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn,{ImageColor3=Color3.fromRGB(255,70,70)},0.12) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn,{ImageColor3=Color3.fromRGB(200,80,80)},0.16) end)
    CloseBtn.MouseButton1Click:Connect(function()
        isPremium = false
        AnimateClose()
    end)

    Tween(Backdrop, {BackgroundTransparency=0.50}, 0.28, Enum.EasingStyle.Quint)
    Tween(Card, {Size=UDim2.new(0,W,0,H), BackgroundTransparency=0}, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.spawn(function()
        if LuarmorLoaderPremium() then
            LRMStatusLabel.Text = "● Premium (Luarmor)"
            LRMStatusLabel.TextColor3 = Color3.fromRGB(80,230,130)
            StatusLabel.Text = "Luarmor premium detected — click Enter Key to continue."
            StatusLabel.TextColor3 = Color3.fromRGB(130,220,160)
        else
            local isFree = false
            pcall(function() isFree = (LRM_IsUserFree == true) end)
            if isFree then
                LRMStatusLabel.Text = "Free User"
                LRMStatusLabel.TextColor3 = Color3.fromRGB(255,200,80)
            else
                LRMStatusLabel.Text = "API Check Ready"
                LRMStatusLabel.TextColor3 = Color3.fromRGB(160,140,200)
            end
        end
    end)

    local savedKey = LoadSavedKey()
    if savedKey ~= "" then
        KeyInput.Text = savedKey
        task.defer(function()
            if not done then VerifyKey(savedKey) end
        end)
    end

    repeat task.wait(0.08) until done

    local finalKey = LoadSavedKey()
    ApplyPremiumState((finalKey ~= "" and finalKey) or nil, isPremium)
    return isPremium, finalKey
end

local env = (getgenv and getgenv()) or _G
env.QuantumCheckKey = CheckKeyViaLuarmorAPI

return RunKeyLoader
