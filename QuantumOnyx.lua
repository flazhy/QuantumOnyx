local Directory = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/Games"
local Api = "https://api.luarmor.net/files/v4/loaders"
local Scripts = {
    Free = {
        [994732206] = Directory .. "/BloxFruits.lua",
        [9186719164] = Directory .. "/SailorPiece.lua",
        [8191429227] = Directory .. "/CutTrees.lua",
    },
    Premium = {
        [994732206] = Api .. "/0ae9fe4cf963e3a13d25eed0e2ce5940.lua",
        [10004244222] = Api .. "/63980a492928552d074ceee243a918d6.lua",
        [9792947201] = Api .. "/50e8e00251d97215e14313c0bb012058.lua",
        [10200395747] = Api .. "/65265b2869c03f57430ee45357d8c3f9.lua"
    }
}
local SCRIPT_ID = "0ae9fe4cf963e3a13d25eed0e2ce5940"
local FOLDER = "Quantum Onyx Hub"
local KEY_FILE = FOLDER .. "/Key.json"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local gameId = game.GameId

local function Tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir = dir or Enum.EasingDirection.Out
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
        local c = New("ImageLabel", {
            Name = "Ripple",
            Image = "rbxassetid://266543268",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 0.82,
            BackgroundTransparency = 1,
            ZIndex = btn.ZIndex + 5,
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, nx, 0, ny),
        }, btn)
        Tween(c, { Size = UDim2.new(0, sz, 0, sz), Position = UDim2.new(0.5, -sz/2, 0.5, -sz/2) }, 0.45, Enum.EasingStyle.Quad)
        Tween(c, { ImageTransparency = 1 }, 0.45, Enum.EasingStyle.Linear)
        task.wait(0.46)
        c:Destroy()
    end)
end

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

local function ClearKey()
    if not isfolder(FOLDER) then makefolder(FOLDER) end
    pcall(writefile, KEY_FILE, HttpService:JSONEncode({}))
end

local SDK_RETRIES = 4
local SDK_RETRY_DELAY = 2.5
local _cachedAPI = nil

local function LoadSDK()
    local ok, result = pcall(function()
        local src = game:HttpGet("https://sdkapi-public.luarmor.net/library.lua")
        if not src or #src < 50 then
            error("SDK source too short")
        end
        local fn, err = loadstring(src)
        if not fn then error("SDK loadstring failed: " .. tostring(err)) end
        local api = fn()
        if type(api) ~= "table" then
            error("SDK returned unexpected type: " .. type(api))
        end
        return api
    end)
    return ok, result
end

local function VerifyKey(keyStr, onStatus)
    local function notify(msg, col)
        if onStatus then onStatus(msg, col) end
    end

    task.wait(0.5)

    local succeeded = false
    local finalStatus = nil

    for attempt = 1, SDK_RETRIES do
        if not succeeded then
            if attempt > 1 then
                notify("Retrying... (" .. attempt .. "/" .. SDK_RETRIES .. ")", Color3.fromRGB(210, 165, 80))
            end
            local sdkOk, api = LoadSDK()
            if sdkOk then
                api.script_id = SCRIPT_ID
                local checkOk, status = pcall(function()
                    return api.check_key(keyStr)
                end)
                if checkOk and type(status) == "table" then
                    _cachedAPI = api
                    succeeded = true
                    finalStatus = status
                else
                    warn(string.format("[QO] check_key error (attempt %d/%d): %s", attempt, SDK_RETRIES, tostring(status)))
                    if attempt < SDK_RETRIES then task.wait(SDK_RETRY_DELAY) end
                end
            else
                warn(string.format("[QO] SDK load failed (attempt %d/%d): %s", attempt, SDK_RETRIES, tostring(api)))
                if attempt < SDK_RETRIES then task.wait(SDK_RETRY_DELAY) end
            end
        end
    end
    if succeeded then
        return true, finalStatus
    end
    return false, {
        code = "SDK_UNREACHABLE",
        message = "Could not reach Luarmor after " .. SDK_RETRIES .. " attempts. Check your connection and try again."
    }
end

local function ShowLoadingScreen()
    local SG2 = Instance.new("ScreenGui")
    SG2.Name = "QO_Loading_" .. tostring(math.random(1e6))
    SG2.ZIndexBehavior = Enum.ZIndexBehavior.Global
    SG2.ResetOnSpawn = false
    SG2.IgnoreGuiInset = true
    Protect(SG2)

    local Box = New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 18, 1, -18),
        Size = UDim2.new(0, 220, 0, 70),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        ZIndex = 300,
        Parent = SG2,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 10) }),
            New("UIStroke", {
                Color = Color3.fromRGB(40, 40, 40),
                Transparency = 0.20,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        }
    })

    local MsgLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -28, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = "Loading...",
        TextColor3 = Color3.fromRGB(210, 210, 210),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 301,
        Parent = Box
    })

    local BarTrack = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 34),
        Size = UDim2.new(1, -28, 0, 4),
        ZIndex = 301,
        Parent = Box,
        Children = { New("UICorner", { CornerRadius = UDim.new(1, 0) }) }
    })

    local BarFill = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(160, 160, 160),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 302,
        Parent = BarTrack,
        Children = { New("UICorner", { CornerRadius = UDim.new(1, 0) }) }
    })

    local SubLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 47),
        Size = UDim2.new(1, -28, 0, 14),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Color3.fromRGB(90, 90, 90),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 301,
        Parent = Box
    })

    Tween(Box, { Position = UDim2.new(1, -18, 1, -18) }, 0.28, Enum.EasingStyle.Quint)

    local animRunning = true
    local dismissed = false

    local function Dismiss()
        if dismissed then return end
        dismissed = true
        animRunning = false
        SubLabel.Text = ""
        local env = getgenv and getgenv()
        if not (env and env.LoadedQuantum == true) then
            MsgLabel.Text = "Loaded Script"
            MsgLabel.TextColor3 = Color3.fromRGB(160, 230, 160)
            BarFill.Size = UDim2.new(1, 0, 1, 0)
            BarFill.BackgroundColor3 = Color3.fromRGB(120, 210, 120)
        end
        task.wait(0.5)
        Tween(Box, { Position = UDim2.new(1, 18, 1, -18) }, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.28)
        SG2:Destroy()
    end

    task.spawn(function()
        local msgs = {
            { t = 0.0, msg = "Fetching script...",       pct = 0.20 },
            { t = 1.8, msg = "Injecting modules...",      pct = 0.45 },
            { t = 3.6, msg = "Setting up environment...", pct = 0.75 },
        }
        local start = tick()
        for _, s in ipairs(msgs) do
            local wait = s.t - (tick() - start)
            if wait > 0 then task.wait(wait) end
            if not animRunning then return end
            MsgLabel.Text = s.msg
            Tween(BarFill, { Size = UDim2.new(s.pct, 0, 1, 0) }, 0.6, Enum.EasingStyle.Quint)
        end
    end)

    task.spawn(function()
        local d = 0
        while animRunning do
            d = (d % 3) + 1
            SubLabel.Text = string.rep("•", d)
            task.wait(0.4)
        end
    end)

    task.spawn(function()
        while animRunning do
            local env = getgenv and getgenv()
            if env and env.LoadedQuantum == true then
                animRunning = false
                MsgLabel.Text = "Loaded"
                MsgLabel.TextColor3 = Color3.fromRGB(160, 230, 160)
                Tween(BarFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.20, Enum.EasingStyle.Quint)
                BarFill.BackgroundColor3 = Color3.fromRGB(120, 210, 120)
                SubLabel.Text = ""
                task.wait(0.5)
                Dismiss()
                break
            end
            task.wait(0.05)
        end
    end)

    return Dismiss
end

local function LoadScript(tier, key)
    if tier == "Premium" and key then
        getgenv().script_key = key

        local dismiss = ShowLoadingScreen()

        getgenv().LoadedQuantum = nil

        task.spawn(function()
            local ok, err = pcall(function()
                if _cachedAPI then
                    _cachedAPI.load_script()
                else
                    local url = Scripts.Premium and Scripts.Premium[gameId]
                    if url then
                        loadstring(game:HttpGet(url))()
                    else
                        warn("[QO] No premium script for GameId: " .. tostring(gameId))
                    end
                end
            end)
            if not ok then
                warn("[QO] Load error: " .. tostring(err))
            end
            getgenv().LoadedQuantum = true
            task.wait(0.6)
            dismiss()
        end)

    else
        local url = Scripts.Free and Scripts.Free[gameId]
        if url then
            local ok, err = pcall(function() loadstring(game:HttpGet(url))() end)
            if not ok then warn("[QO] Load error: " .. tostring(err)) end
        else
            warn("[QO] No free script for GameId: " .. tostring(gameId))
        end
    end
end

local function ShowKeyUI()
    local done = false
    local isPremium = false
    local resultKey = ""
    local submitting = false
    local supportInfo = {
        { label = "Discord", value = "discord.gg/quantumonyx" },
        { label = "Game", value = (pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end) and game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name) or "Unknown" },
        { label = "Version", value = "v.Freemium" },
    }
    local UpdateLog = {
        { version = "v2.2", date = "2026", notes = "Added Linkvertise as key service" },
        { version = "v2.3", date = "2026", notes = "API+SDK dual auth & loading screen" },
    }
    local SG = Instance.new("ScreenGui")
    SG.Name = "KL_" .. tostring(math.random(1e6))
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Global
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true
    Protect(SG)

    local Backdrop = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 200,
        Parent = SG,
    })

    local W, H = 450, 310
    local Card = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, W * 0.5, 0, H * 0.5),
        BackgroundColor3 = Color3.fromRGB(6, 3, 12),
        BackgroundTransparency = 0.80,
        BorderSizePixel = 0,
        ZIndex = 201,
        ClipsDescendants = true,
        Parent = SG,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 14) }),
            New("UIStroke", {
                Color = Color3.fromRGB(110, 50, 210),
                Transparency = 0.38,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            }),
        }
    })

    New("Frame", {
        BackgroundColor3 = Color3.fromRGB(80, 20, 160),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -60, 0, -60),
        Size = UDim2.new(0, 220, 0, 220),
        ZIndex = 201,
        Parent = Card,
        Children = { New("UICorner", { CornerRadius = UDim.new(1, 0) }) }
    })

    New("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 10, 110),
        BackgroundTransparency = 0.90,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -100, 1, -100),
        Size = UDim2.new(0, 180, 0, 180),
        ZIndex = 201,
        Parent = Card,
        Children = { New("UICorner", { CornerRadius = UDim.new(1, 0) }) }
    })

    local Header = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 5, 18),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 14) }),
            New("Frame", {
                BackgroundColor3 = Color3.fromRGB(9, 5, 18),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0.5, 0),
                ZIndex = 202
            }),
        }
    })

    New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 13, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Image = "rbxassetid://7733992528",
        ImageColor3 = Color3.fromRGB(155, 90, 255),
        ZIndex = 203,
        Parent = Header
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 35, 0, 0),
        Size = UDim2.new(1, -130, 1, 0),
        Font = Enum.Font.FredokaOne,
        Text = "Quantum Onyx — Key System",
        TextColor3 = Color3.fromRGB(220, 200, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = Header
    })

    New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(30, 60, 20),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -40, 0.5, 0),
        Size = UDim2.new(0, 72, 0, 20),
        ZIndex = 203,
        Parent = Header,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 5) }),
            New("UIStroke", { Color = Color3.fromRGB(80, 200, 110), Transparency = 0.45, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = "Freemium",
                TextColor3 = Color3.fromRGB(130, 235, 160),
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 204
            }),
        }
    })

    local CloseBtn = New("ImageButton", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Image = "rbxassetid://79324227570635",
        ImageColor3 = Color3.fromRGB(200, 80, 80),
        ZIndex = 203,
        Parent = Header
    })

    New("Frame", {
        BackgroundColor3 = Color3.fromRGB(110, 50, 210),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 44),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 202,
        Parent = Card,
        Children = { New("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0),
                NumberSequenceKeypoint.new(0.9, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
        }) }
    })

    local LW = 180
    local RX = LW + 18
    local RW = W - RX - 10

    New("Frame", {
        BackgroundColor3 = Color3.fromRGB(100, 50, 200),
        BackgroundTransparency = 0.65,
        BorderSizePixel = 0,
        Position = UDim2.new(0, LW + 8, 0, 52),
        Size = UDim2.new(0, 1, 0, H - 60),
        ZIndex = 202,
        Parent = Card,
        Children = { New("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.08, 0),
                NumberSequenceKeypoint.new(0.92, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
        }) }
    })

    local InfoBox = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 5, 18),
        BackgroundTransparency = 0.20,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 52),
        Size = UDim2.new(0, LW, 0, 112),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 8) }),
            New("UIStroke", { Color = Color3.fromRGB(100, 50, 190), Transparency = 0.58, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        }
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 9, 0, 5),
        Size = UDim2.new(1, -14, 0, 13),
        Font = Enum.Font.GothamBold,
        Text = "Information",
        TextColor3 = Color3.fromRGB(130, 85, 210),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = InfoBox
    })

    New("Frame", {
        BackgroundColor3 = Color3.fromRGB(110, 60, 200),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 7, 0, 20),
        Size = UDim2.new(1, -14, 0, 1),
        ZIndex = 203,
        Parent = InfoBox,
        Children = { New("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0),
                NumberSequenceKeypoint.new(0.9, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
        }) }
    })

    local rowY = 26
    for _, info in ipairs(supportInfo) do
        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 9, 0, rowY),
            Size = UDim2.new(0, 55, 0, 12),
            Font = Enum.Font.GothamBold,
            Text = (info.label or "") .. ":",
            TextColor3 = Color3.fromRGB(115, 85, 165),
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 203,
            Parent = InfoBox
        })
        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 64, 0, rowY),
            Size = UDim2.new(1, -70, 0, 12),
            Font = Enum.Font.Gotham,
            Text = tostring(info.value or ""),
            TextColor3 = Color3.fromRGB(180, 155, 220),
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 203,
            Parent = InfoBox
        })
        rowY = rowY + 16
        if rowY > 96 then break end
    end

    local LogBox = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 5, 18),
        BackgroundTransparency = 0.20,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 170),
        Size = UDim2.new(0, LW, 0, 128),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 8) }),
            New("UIStroke", { Color = Color3.fromRGB(100, 50, 190), Transparency = 0.58, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        }
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 9, 0, 5),
        Size = UDim2.new(1, -14, 0, 13),
        Font = Enum.Font.GothamBold,
        Text = "Update Log",
        TextColor3 = Color3.fromRGB(130, 85, 210),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = LogBox
    })

    New("Frame", {
        BackgroundColor3 = Color3.fromRGB(110, 60, 200),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 7, 0, 20),
        Size = UDim2.new(1, -14, 0, 1),
        ZIndex = 203,
        Parent = LogBox,
        Children = { New("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.1, 0),
                NumberSequenceKeypoint.new(0.9, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
        }) }
    })

    local logY = 26
    for _, entry in ipairs(UpdateLog) do
        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 9, 0, logY),
            Size = UDim2.new(1, -14, 0, 12),
            Font = Enum.Font.GothamBold,
            RichText = true,
            Text = string.format('<font color="#a855f7">%s</font>  <font color="#554466">%s</font>', entry.version or "", entry.date or ""),
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 203,
            Parent = LogBox
        })
        logY = logY + 13
        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 13, 0, logY),
            Size = UDim2.new(1, -18, 0, 11),
            Font = Enum.Font.Gotham,
            Text = "• " .. (entry.notes or ""),
            TextColor3 = Color3.fromRGB(150, 135, 185),
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 203,
            Parent = LogBox
        })
        logY = logY + 14
        if logY > 110 then break end
    end

    local NoticeBg = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 5, 18),
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Position = UDim2.new(0, RX, 0, 52),
        Size = UDim2.new(0, RW, 0, 50),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 7) }),
            New("UIStroke", { Color = Color3.fromRGB(80, 200, 110), Transparency = 0.52, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
            New("Frame", {
                BackgroundColor3 = Color3.fromRGB(80, 200, 110),
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0.5, -10),
                Size = UDim2.new(0, 3, 0, 20),
                ZIndex = 203,
                Children = { New("UICorner", { CornerRadius = UDim.new(1, 0) }) }
            })
        }
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(140, 230, 170),
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 203,
        Text = "Freemium — key is optional.\nEnter a key to unlock premium features.",
        Parent = NoticeBg
    })

    local LRMBar = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(9, 5, 18),
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Position = UDim2.new(0, RX, 0, 110),
        Size = UDim2.new(0, RW, 0, 28),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            New("UIStroke", { Color = Color3.fromRGB(100, 50, 190), Transparency = 0.60, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        }
    })

    New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12),
        Image = "rbxassetid://7733992528",
        ImageColor3 = Color3.fromRGB(130, 80, 200),
        ZIndex = 203,
        Parent = LRMBar
    })

    local LRMStatusLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 25, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Checking Luarmor...",
        TextColor3 = Color3.fromRGB(160, 140, 200),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 203,
        Parent = LRMBar
    })

    local InputBg = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(4, 2, 9),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0, RX, 0, 146),
        Size = UDim2.new(0, RW, 0, 34),
        ZIndex = 202,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 7) }),
            New("UIStroke", { Color = Color3.fromRGB(110, 55, 200), Transparency = 0.48, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        }
    })

    New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, -7),
        Size = UDim2.new(0, 14, 0, 14),
        Image = "rbxassetid://7733992528",
        ImageColor3 = Color3.fromRGB(120, 75, 195),
        ZIndex = 203,
        Parent = InputBg
    })

    local KeyInput = New("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -54, 1, 0),
        Font = Enum.Font.GothamBold,
        PlaceholderText = "Enter premium key...",
        PlaceholderColor3 = Color3.fromRGB(85, 60, 125),
        Text = "",
        TextColor3 = Color3.fromRGB(200, 175, 255),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 203,
        Parent = InputBg
    })

    local PasteBtn = New("ImageButton", {
        BackgroundColor3 = Color3.fromRGB(75, 35, 155),
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(324, 684),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Color3.fromRGB(155, 115, 225),
        ZIndex = 204,
        Parent = InputBg,
        Children = { New("UICorner", { CornerRadius = UDim.new(0, 5) }) }
    })

    PasteBtn.MouseEnter:Connect(function() Tween(PasteBtn, { BackgroundTransparency = 0.30 }, 0.12) end)
    PasteBtn.MouseLeave:Connect(function() Tween(PasteBtn, { BackgroundTransparency = 0.62 }, 0.16) end)
    PasteBtn.MouseButton1Click:Connect(function()
        if getclipboard then KeyInput.Text = getclipboard() or "" end
    end)

    local StatusLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, RX, 0, 185),
        Size = UDim2.new(0, RW, 0, 13),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Color3.fromRGB(155, 135, 190),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 202,
        Parent = Card
    })

    local function SetStatus(msg, col)
        StatusLabel.Text = msg
        StatusLabel.TextColor3 = col or Color3.fromRGB(155, 135, 190)
    end

    local function AnimateClose()
        Tween(Card, { Size = UDim2.new(0, W * 0.65, 0, H * 0.65), BackgroundTransparency = 0.75 }, 0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(Backdrop, { BackgroundTransparency = 1 }, 0.20, Enum.EasingStyle.Quint)
        task.delay(0.22, function()
            SG:Destroy()
            done = true
        end)
    end

    local function SubmitKey(keyStr)
        if submitting then return end
        if not keyStr or keyStr == "" then
            SetStatus("Please enter a key first.", Color3.fromRGB(255, 175, 80))
            return
        end
        submitting = true
        SetStatus("Verifying key...", Color3.fromRGB(175, 150, 255))

        task.spawn(function()
            local ok, status = VerifyKey(keyStr, function(msg, col)
                SetStatus(msg, col)
            end)
            submitting = false

            if not ok then
                SetStatus(tostring((status and status.message) or "Verification failed."), Color3.fromRGB(255, 90, 110))
                return
            end

            local code = status.code or ""
            if code == "KEY_VALID" then
                isPremium = true
                resultKey = keyStr
                SaveKey(keyStr)
                getgenv().script_key = keyStr
                LRMStatusLabel.Text = "Premium Active"
                LRMStatusLabel.TextColor3 = Color3.fromRGB(80, 230, 130)
                SetStatus("Key verified! Loading...", Color3.fromRGB(80, 230, 130))
                task.wait(0.5)
                AnimateClose()
            elseif code == "KEY_HWID_LOCKED" then
                ClearKey()
                SetStatus("HWID mismatch — reset your key.", Color3.fromRGB(255, 90, 110))
            elseif code == "KEY_EXPIRED" then
                ClearKey()
                SetStatus("Key expired — get a new one.", Color3.fromRGB(255, 90, 110))
            elseif code == "KEY_BANNED" then
                ClearKey()
                SetStatus("Key is banned.", Color3.fromRGB(255, 90, 110))
            elseif code == "KEY_INCORRECT" then
                ClearKey()
                SetStatus("Key not found.", Color3.fromRGB(255, 90, 110))
            elseif code == "SDK_UNREACHABLE" or code == "SDK_ERROR" or code == "VERIFY_FAILED" then
                SetStatus(tostring((status and status.message) or "Could not reach Luarmor."), Color3.fromRGB(255, 90, 110))
            else
                ClearKey()
                SetStatus(tostring(status.message or ("Unknown: " .. code)), Color3.fromRGB(255, 90, 110))
            end
        end)
    end

    local BtnY = 202
    local BtnH = 30
    local BtnGap = 6
    local BtnW = math.floor((RW - BtnGap * 2) / 3)

    local function MakeBtn(label, px, w, bg, tc, cb)
        local btn = New("TextButton", {
            BackgroundColor3 = bg,
            BackgroundTransparency = 0.28,
            BorderSizePixel = 0,
            Position = UDim2.new(0, px, 0, BtnY),
            Size = UDim2.new(0, w, 0, BtnH),
            AutoButtonColor = false,
            Text = "",
            ClipsDescendants = true,
            ZIndex = 202,
            Parent = Card,
            Children = {
                New("UICorner", { CornerRadius = UDim.new(0, 7) }),
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.FredokaOne,
                    Text = label,
                    TextColor3 = tc,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 203
                })
            }
        })
        btn.MouseEnter:Connect(function() Tween(btn, { BackgroundTransparency = 0.08 }, 0.12) end)
        btn.MouseLeave:Connect(function() Tween(btn, { BackgroundTransparency = 0.28 }, 0.16) end)
        btn.MouseButton1Click:Connect(function()
            CircleRipple(btn, Mouse.X, Mouse.Y)
            cb()
        end)
        return btn
    end

    MakeBtn("Free Version", RX, BtnW, Color3.fromRGB(35, 14, 70), Color3.fromRGB(170, 130, 255), function()
        if not Scripts.Free[gameId] then
            SetStatus("No free version for this game.", Color3.fromRGB(255, 150, 80))
        else
            isPremium = false
            AnimateClose()
        end
    end)

    local panelOpen = false
    local OptionPanel = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(4, 2, 9),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0, RX + BtnW + BtnGap, 0, BtnY - 78),
        Size = UDim2.new(0, BtnW, 0, 72),
        ZIndex = 215,
        Visible = false,
        ClipsDescendants = false,
        Parent = Card,
        Children = {
            New("UICorner", { CornerRadius = UDim.new(0, 7) }),
            New("UIStroke", {
                Color = Color3.fromRGB(110, 55, 200),
                Transparency = 0.48,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }),
        }
    })

    local function MakeOptionBtn(label, yPos, link, statusMsg)
        local btn = New("TextButton", {
            BackgroundColor3 = Color3.fromRGB(30, 10, 70),
            BackgroundTransparency = 0.30,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 4, 0, yPos),
            Size = UDim2.new(1, -8, 0, 30),
            AutoButtonColor = false,
            Text = label,
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(190, 160, 255),
            TextSize = 11,
            ZIndex = 216,
            Parent = OptionPanel,
            Children = { New("UICorner", { CornerRadius = UDim.new(0, 5) }) }
        })
        btn.MouseEnter:Connect(function() Tween(btn, { BackgroundTransparency = 0.08 }, 0.10) end)
        btn.MouseLeave:Connect(function() Tween(btn, { BackgroundTransparency = 0.30 }, 0.12) end)
        btn.MouseButton1Click:Connect(function()
            CircleRipple(btn, Mouse.X, Mouse.Y)
            pcall(function() (setclipboard or toclipboard)(link) end)
            SetStatus(statusMsg, Color3.fromRGB(105, 195, 255))
            task.delay(0.12, function()
                panelOpen = false
                OptionPanel.Visible = false
            end)
        end)
        return btn
    end

    MakeOptionBtn("Lootlabs", 4, "https://ads.luarmor.net/get_key?for=Quantum_Onyx_Key_Sytem-FpNBDhxVzYzS", "Lootlabs Link Copied")
    MakeOptionBtn("Linkvertise", 38, "https://ads.luarmor.net/get_key?for=Quantum_Onyx_Key_Sytem-TcgtEiNunUTO", "Linkvertise Link Copied")

    local getKeyBtn = MakeBtn("Get Key", RX + BtnW + BtnGap, BtnW, Color3.fromRGB(12, 35, 70), Color3.fromRGB(105, 175, 255), function()
        panelOpen = not panelOpen
        OptionPanel.Visible = panelOpen
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not panelOpen then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local ap = OptionPanel.AbsolutePosition
            local as = OptionPanel.AbsoluteSize
            local onPanel = pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
            local gkp = getKeyBtn.AbsolutePosition
            local gks = getKeyBtn.AbsoluteSize
            local onBtn = pos.X >= gkp.X and pos.X <= gkp.X + gks.X and pos.Y >= gkp.Y and pos.Y <= gkp.Y + gks.Y
            if not onPanel and not onBtn then
                panelOpen = false
                OptionPanel.Visible = false
            end
        end
    end)

    MakeBtn("Enter Key", RX + (BtnW + BtnGap) * 2, BtnW, Color3.fromRGB(48, 14, 100), Color3.fromRGB(200, 150, 255), function()
        SubmitKey(KeyInput.Text)
    end)

    local SY = BtnY + BtnH + 14
    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, RX, 0, SY),
        Size = UDim2.new(0, RW, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = "Community",
        TextColor3 = Color3.fromRGB(200, 170, 65),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 202,
        Parent = Card
    })

    local socials = {
        { img = "rbxassetid://129297846250682", col = Color3.fromRGB(100, 120, 255) },
        { img = "http://www.roblox.com/asset/?id=14620084334", col = Color3.fromRGB(185, 130, 255) },
    }
    local icSz = 26
    local totW = #socials * icSz + (#socials - 1) * 8
    local stX = RX + math.floor((RW - totW) / 2)
    for i, sd in ipairs(socials) do
        local ic = New("ImageButton", {
            BackgroundColor3 = sd.col,
            BackgroundTransparency = 0.68,
            BorderSizePixel = 0,
            Position = UDim2.new(0, stX + (i - 1) * (icSz + 8), 0, SY + 15),
            Size = UDim2.new(0, icSz, 0, icSz),
            Image = sd.img,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 202,
            Parent = Card,
            Children = {
                New("UICorner", { CornerRadius = UDim.new(1, 0) }),
                New("UIStroke", { Color = sd.col, Transparency = 0.40, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
            }
        })
        ic.MouseEnter:Connect(function() Tween(ic, { BackgroundTransparency = 0.28 }, 0.12) end)
        ic.MouseLeave:Connect(function() Tween(ic, { BackgroundTransparency = 0.68 }, 0.16) end)
    end

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { ImageColor3 = Color3.fromRGB(255, 70, 70) }, 0.12) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { ImageColor3 = Color3.fromRGB(200, 80, 80) }, 0.16) end)
    CloseBtn.MouseButton1Click:Connect(function()
        isPremium = false
        AnimateClose()
    end)

    Tween(Backdrop, { BackgroundTransparency = 0.50 }, 0.28, Enum.EasingStyle.Quint)
    Tween(Card, { Size = UDim2.new(0, W, 0, H), BackgroundTransparency = 0 }, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.spawn(function()
        task.wait(1.5)
        if LRM_IsUserPremium == true then
            LRMStatusLabel.Text = "Premium Detected"
            LRMStatusLabel.TextColor3 = Color3.fromRGB(80, 230, 130)
            SetStatus("Premium key detected — click Enter Key to activate.", Color3.fromRGB(130, 220, 160))
        elseif LRM_IsUserFree == true then
            LRMStatusLabel.Text = "Free User"
            LRMStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
        else
            LRMStatusLabel.Text = "Not Authenticated"
            LRMStatusLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)

    local SavedKey = LoadSavedKey()
    if SavedKey ~= "" then
        KeyInput.Text = SavedKey
        task.delay(1.0, function()
            if not done then
                SubmitKey(SavedKey)
            end
        end)
    end

    repeat task.wait(0.08) until done
    return isPremium, resultKey
end

local function AuthenticateAndLoad()
    local SavedKey = LoadSavedKey()
    if SavedKey and SavedKey ~= "" then
        local ok, status = VerifyKey(SavedKey, nil)
        if ok and type(status) == "table" and status.code == "KEY_VALID" then
            getgenv().script_key = SavedKey
            LoadScript("Premium", SavedKey)
            return
        else
            ClearKey()
        end
    end

    task.spawn(function()
        local premium, key = ShowKeyUI()
        if premium then
            LoadScript("Premium", key)
        else
            LoadScript("Free", nil)
        end
    end)
end

AuthenticateAndLoad()
