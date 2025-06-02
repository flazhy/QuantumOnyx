
repeat task.wait() until game:IsLoaded()
local Module = {}
local function LoadModule(path)
    if Module[path] then return Module[path] end

    local base = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/"
    local url = base .. path .. ".lua"
    local code = game:HttpGet(url)
    local loaded = loadstring(code)
    local result = loaded()
    Module[path] = result
    return result
end

local Notification = LoadModule("Util/NotifyLib")
local Data = LoadModule("Util/DataModuleGAG")
local Module = loadstring(game:HttpGet("https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/Util/GAG/module.luau"))()
local Library = LoadModule("Util/Library")

local Config = LoadModule("Util/Config")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local SellRemote = ReplicatedStorage.GameEvents:WaitForChild("Sell_Inventory")
local StevenHRP = workspace:WaitForChild("NPCS"):WaitForChild("Steven"):WaitForChild("HumanoidRootPart")
local GetFarm = require(ReplicatedStorage.Modules:WaitForChild("GetFarm"))
local FavoriteToolRemote = ReplicatedStorage.GameEvents:WaitForChild("Favorite_Item")
local BuyPetEgg = ReplicatedStorage.GameEvents:WaitForChild("BuyPetEgg")
local DataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))


local lp = Players.LocalPlayer
local ExecCmd = getgenv()

local VisitedFile = "VisitedServers.json"

local Window = Library:CreateWindow({
    Title = "Quantum Onyx",
    Subtitle = "Grow A Garden",
    Version = "v1.03",
    Theme = "Purple"
})

local Tab = {
    Home = Window:AddTab("Home", "home-quantum"),
    Sub = Window:AddTab("Sub", "visual-quantum"),
    Shop = Window:AddTab("Shop", "cart-quantum"),
    Serv = Window:AddTab("Server", "map-quantum"),
    Bug = Window:AddTab("Debug", "visual-quantum")
}

local ServerTab = Tab.Serv:addSection()
local ServerMenu = ServerTab:addMenu("Server")
local Label = ServerMenu:addLabel("Server Status", "Loading...")

task.spawn(function()
    for _, v in ipairs(game.CoreGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Text:find("Place Version:") then
            local ver = v.Text:match("Place Version:%s*(%d+)") or "Unknown"
            Label:RefreshDesc("Version: " .. ver .. "\n" .. game.JobId)
            return
        end
    end
end)

local VisitedFolder = "QuantumOnyxHub"
local VisitedFile = VisitedFolder .. "/visited.json"
local function FolderExists()
    return isfolder and isfolder(VisitedFolder)
end
local function LoadVisited()
    if FolderExists() and isfile and isfile(VisitedFile) then
        local Success, Result = pcall(function()
            return HttpService:JSONDecode(readfile(VisitedFile))
        end)
        if Success then
            return Result
        end
    end
    return {}
end
local function SaveVisited(Visited)
    if FolderExists() and writefile then
        writefile(VisitedFile, HttpService:JSONEncode(Visited))
    end
end
local function GetServers(Cursor)
    local Url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&excludeFullGames=true"):format(game.PlaceId)
    if Cursor then
        Url = Url .. "&cursor=" .. Cursor
    end
    local RequestFunc = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
    if not RequestFunc then
        return {}, nil
    end
    local Response = RequestFunc({ Url = Url, Method = "GET" })
    if not Response then
        return {}, nil
    end
    local Data = HttpService:JSONDecode(Response.Body)
    return Data.data or {}, Data.nextPageCursor
end

ServerMenu:addButton("Server Hop", function()
    local Visited = LoadVisited()
    Visited[game.JobId] = true
    SaveVisited(Visited)
    local Cursor, FoundServer = nil, false
    while not FoundServer do
        local Servers, NextCursor = GetServers(Cursor)
        if #Servers == 0 then return end
        table.sort(Servers, function(a,b) return a.playing < b.playing end)
        local i = 1
        while i <= #Servers and not FoundServer do
            local Server = Servers[i]
            if Server.playing < Server.maxPlayers and not Visited[Server.id] then
                Visited[Server.id] = true
                SaveVisited(Visited)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, Server.id)
                FoundServer = true
            end
            i = i + 1
        end
        if FoundServer then return end
        if not NextCursor then return end
        Cursor = NextCursor
    end
end)

ServerMenu:addTextbox("Enter Job ID", function(Value)
	ServerId = Value
end)

ServerMenu:addButton("Join Job ID", function()
	game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, ServerId:gsub("`", ""):gsub("lua", ""))
end)

ServerMenu:addButton("Copy Current Job ID", function()
	setclipboard(tostring(game.JobId))
end)

local SubLeft = Tab.Sub:addSection()
local Fav = SubLeft:addMenu("Favorite System")

Config.Dropdown(Fav, "Mutations", 1, {"Wet", "Voidtouched", "Frozen", "Choc","Disco", "Plasma","Burnt", "Chilled", "Shocked", "Moonlit", "Bloodlit","Zombified", "Celestial", "HoneyGlazed", "Pollinated"}, function(Value)
    ExecCmd.SelectedFavMutations = Value
end, true)

Config.Toggle(Fav, "Auto Favorite", false, function(Value)
    ExecCmd.AutoFavMutate = Value;Module.FavoriteMutations()
end)

Config.Toggle(Fav, "Auto Unfavorite", false, function(Value)
    ExecCmd.AutoUnfavMutate = Value;Module.FavoriteMutations()
end)

local Egg = SubLeft:addMenu("Egg System")

Config.Dropdown(Egg, "Egg List", 1, {"Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg", "Bug Egg"}, function(val)
    ExecCmd.SelectedEggList = val
end, true)

Config.Toggle(Egg, "Auto Buy Egg", false, function()
    ExecCmd.AutoBuyEgg = Value;Module.AutoBuyEggs()
end)

Config.Toggle(Egg, "Auto Buy All Eggs", false, function()
    ExecCmd.AutoBuyAllEggs = Value;Module.AutoBuyEggs()
end)
Config.Toggle(Egg, "Auto Hatch Eggs", false, function()
    ExecCmd.AutoHatchEggs = Value;Module.AutoHatchEggs()
end)

local SubRight = Tab.Sub:addSection()
local Honey = SubRight:addMenu("Honey Event")
Config.Toggle(Honey, "Auto Give Pollinated", false, function()
    ExecCmd.AutoGivePollinated = Value;Module.AutoGivePollinated()
end)

local HomeLeft = Tab.Home:addSection()
local Farm = HomeLeft:addMenu("Farm")

Config.Dropdown(Farm, "Seed Plant", 1, Data.Seeds, function(v)
    ExecCmd.SeedName = v
end)

Config.Dropdown(Farm, "Plant Mode", 2, { "Pathways", "Bypass" }, function(v)
    ExecCmd.PlantMode = v
end)

Config.Dropdown(Farm, "Plant Style", 1, { "Random", "Stacked" }, function(v)
    ExecCmd.PlantStyle = v
end)
Config.Toggle(Farm, "Auto Plant", false, function(Value)
    ExecCmd.AutoPlant = Value;Module.AutoPlantModule()
end)

local Farm = HomeLeft:addMenu("Collections")
Config.Dropdown(Farm, "Mutations List", 1, {"Any", "Wet", "Voidtouched", "Frozen", "Choc","Disco", "Plasma","Burnt", "Chilled", "Shocked", "Moonlit", "Bloodlit","Zombified", "Celestial", "HoneyGlazed", "Pollinated"}, function(Value)
    ExecCmd.SelectedMutations = Value
end, true)

Config.Dropdown(Farm, "Variant List", 1, {"Any", "Normal", "Gold", "Rainbow"}, function(Value) 
    ExecCmd.SelectedVariants = Value 
end, true)

Config.Toggle(Farm, "Auto Collect", false, function()
    ExecCmd.AutoCollect = Value;Module.CollectModule()
end)
local ShopLeft = Tab.Shop:addSection()
local Sell = ShopLeft:addMenu("Selling")

Sell:addToggle("Auto Sell if Full (inv)", false, function(Value)
    ExecCmd.AutoSell = Value;Module.AutoSell()
end)

Sell:addSlider("Sell Delay", 100, 1000, 500, function(Value)
    ExecCmd.DelaySell = Value
end, 50)


Sell:addToggle("Auto Sell Tick", false, function(Value)
    ExecCmd.AutoTickSell = Value;Module.AutoSell()
end)

Sell:addButton("Sell My Inventory", function()
	local Char = lp.Character or lp.CharacterAdded:Wait()
	local Farm = GetFarm(lp)
	local SpawnPoint = Farm and Farm:FindFirstChild("Spawn_Point")
	local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

	if Char and HRP and SpawnPoint and StevenHRP then
		local SellPos = StevenHRP.CFrame * CFrame.new(0, 2, 5)
		Char:PivotTo(SellPos)
		task.wait(0.25)
		pcall(SellRemote.FireServer, SellRemote)
		task.wait(0.25)
		Char:PivotTo(SpawnPoint.CFrame + Vector3.new(0, 3, 0))
	end
end)

local Seed = ShopLeft:addMenu("Seed Stocks")

Config.Dropdown(Seed, "Seed List", 1, Data.SeedStock, function(Value)
	ExecCmd.PurchaseSeed = Value
end, true)
Seed:addButton("Seed Shop", function()
	require(game.ReplicatedStorage.Modules.GuiController):Open(lp:WaitForChild("PlayerGui"):WaitForChild("Seed_Shop"))
end)
Config.Toggle(Seed, "Auto Purchase [Selected]", false, function(Value)
	ExecCmd.AutoPurchaseSeed = Value
	while ExecCmd.AutoPurchaseSeed do task.wait()
		for _, v in ipairs(ExecCmd.PurchaseSeed or {}) do
			game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(v)
		end
	end
end)

Config.Toggle(Seed, "Auto Buy All", false, function(Value)
	ExecCmd.AutoBuyAllSeed = Value
	while ExecCmd.AutoBuyAllSeed do task.wait()
		for _, v in ipairs(Data.SeedStock) do
			game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuySeedStock"):FireServer(v)
		end
	end
end)

local Gear = ShopLeft:addMenu("Gears Stock")
Config.Dropdown(Gear, "Gear List", 1, Data.Gears, function(Value)
	ExecCmd.PurchaseGear = Value
end, true)

Gear:addButton("Gear Shop", function()
	require(game.ReplicatedStorage.Modules.GuiController):Open(lp:WaitForChild("PlayerGui"):WaitForChild("Gear_Shop"))
end)

Config.Toggle(Gear, "Auto Purchase [Selected]", false, function(Value)
	ExecCmd.AutoPurchaseGear = Value
	while ExecCmd.AutoPurchaseGear do task.wait()
		for _, v in ipairs(ExecCmd.PurchaseGear or {}) do
			game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(v)
		end
	end
end)

Config.Toggle(Gear, "Auto Buy All", false, function(state)
	ExecCmd.AutoBuyAllGear = state
	while ExecCmd.AutoBuyAllGear do task.wait()
		for _, v in ipairs(Data.Gears) do
			game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuyGearStock"):FireServer(v)
		end
	end
end)

local Crate = ShopLeft:addMenu("Cosmetic Stock")

Config.Dropdown(Crate, "Cosmetic List", 1, Data.CratesList, function(Value)
	ExecCmd.PurchaseCrate = Value
end, true)

Crate:addButton("Cosmetic Shop", function()
	pcall(function()
		lp.PlayerGui:WaitForChild("CosmeticShop_UI").Enabled = true
		require(game.ReplicatedStorage.Modules.CosmeticShop_UI_Controller).Start({})
	end)
end)

local function purchase(v)
    if type(v) == "string" and v:lower():find("crate") then
        ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyCosmeticCrate"):FireServer(v)
    else
        ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyCosmeticItem"):FireServer(v)
    end
end

Config.Toggle(Crate, "Auto Purchase [Selected]", false, function(Value)
    ExecCmd.AutoPurchaseCrate = Value

    task.spawn(function()
        while ExecCmd.AutoPurchaseCrate do
            task.wait()
            for _, v in ipairs(ExecCmd.PurchaseCrate or {}) do
                purchase(v)
            end
        end
    end)
end)

Config.Toggle(Crate, "Auto Buy All", false, function(state)
   ExecCmd.AutoBuyAllCrate = state

    task.spawn(function()
        while ExecCmd.AutoBuyAllCrate do
            task.wait()
            for _, v in ipairs(Data.CratesList or {}) do
                purchase(v)
            end
        end
    end)
end)

local ShopRight = Tab.Shop:addSection()
local Event = ShopRight:addMenu("Honey Event")
Config.Dropdown(Event, "Honey List", 1, Data.HoneyList, function(Value)
	ExecCmd.PurchaseHoney = Value
end, true)

Event:addButton("Open Honey Shop", function()
	pcall(function()
		require(game:GetService("ReplicatedStorage").Modules.GuiController):Open(game.Players.LocalPlayer.PlayerGui.HoneyEventShop_UI)
	end)
end)

Config.Toggle(Event, "Auto Purchase [Selected]", false, function(Value)
	ExecCmd.AutoPurchaseEvent = Value
	while ExecCmd.AutoPurchaseEvent do task.wait()
		for _, v in ipairs(ExecCmd.PurchaseHoney or {}) do
			game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock"):FireServer(v)
		end
	end
end)

Config.Toggle(Event, "Auto Buy All", false, function(state)
	ExecCmd.AutoBuyAllEvent = state
	while ExecCmd.AutoBuyAllEvent do task.wait()
		for _, v in ipairs(Data.HoneyList) do
			game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock"):FireServer(v)
		end
	end
end)

local Debug_Left = Tab.Bug:addSection()

local Debug = Debug_Left:addMenu("Debugging")

local ItemModule = require(game:GetService("ReplicatedStorage").Item_Module)
local MutationHandler = require(game:GetService("ReplicatedStorage").Modules.MutationHandler)

local function CalculatePlantValue(item)
	local s, v, w = item:FindFirstChild("Item_String"), item:FindFirstChild("Variant"), item:FindFirstChild("Weight")
	if not (s and v and w) then return 0 end

	local data = ItemModule.Return_Data(s.Value)
	if not data or #data < 3 then return 0 end

	local base = data[3] * MutationHandler:CalcValueMulti(item) * ItemModule.Return_Multiplier(v.Value)
	local factor = math.clamp(w.Value / data[2], 0.95, 1e8)
	return math.round(base * factor * factor)
end

local function Abbrev(n)
	return n >= 1e9 and string.format("%.2fB", n / 1e9) or n >= 1e6 and string.format("%.2fM", n / 1e6) or n >= 1e3 and string.format("%.2fK", n / 1e3) or tostring(n)
end

local function NotifyBackpackValue()
	local backpack = lp:WaitForChild("Backpack")
	local total, top, maxVal, topWeight = 0, nil, 0, 0

	for _, item in ipairs(backpack:GetChildren()) do
		local val = CalculatePlantValue(item)
		total = total + val
		if val > maxVal then
			top, maxVal = item, val
			topWeight = item:FindFirstChild("Weight") and item.Weight.Value or 0
		end
	end

	local name = top and top:FindFirstChild("Item_String") and top.Item_String.Value or "None"

	task.spawn(function()
		Notification:Notify(
			{
				Title = "Inventory Value",
				Description = string.format("Total Sheckles: %s\nTop Item: %s (%s, %.2f KG)",
					Abbrev(total), name, Abbrev(maxVal), topWeight)
			},
			{
				OutlineColor = Color3.fromRGB(170, 85, 255),
				Time = 5,
				Type = "image"
			},
			{
				Image = "rbxassetid://80812231439203",
				ImageColor = Color3.fromRGB(255, 255, 255)
			}
		)
	end)
end

Debug:addButton("Check Value Inventory", function()
	NotifyBackpackValue()
end)

local Stream = Debug_Left:addMenu("Resources")

local function BoostFPS()
    local S = {
        WS = game:GetService("Workspace"),
        LG = game:GetService("Lighting"),
        PL = game:GetService("Players")
    }
    local LP      = S.PL.LocalPlayer
    local Terrain = S.WS:FindFirstChildOfClass("Terrain")
    pcall(function()
        local settings = UserSettings():GetService("UserGameSettings")
        settings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)
    pcall(function() if setfpscap then setfpscap(60) end end)
    pcall(function() S.WS.StreamingEnabled = true end)
    pcall(function()
        S.LG.GlobalShadows  = false
        S.LG.Technology     = Enum.Technology.Compatibility
        S.LG.Brightness     = 1
        S.LG.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        S.LG.FogStart       = 0
        S.LG.FogEnd         = 1e5
        for _,e in ipairs(S.LG:GetChildren()) do
            if e:IsA("PostEffect") or e:IsA("ColorCorrectionEffect") then e:Destroy() end
        end
    end)
    if Terrain then
        Terrain.WaterWaveSize     = 0
        Terrain.WaterWaveSpeed    = 0
        Terrain.WaterReflectance  = 0
        Terrain.WaterTransparency = 1
    end
    for _,o in ipairs(S.WS:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam")
        or o:IsA("Smoke") or o:IsA("Fire") then
            o.Enabled = false

        elseif o:IsA("Decal") then
            o.Transparency = 1

        elseif o:IsA("BasePart") then
            o.Material     = Enum.Material.SmoothPlastic
            o.Reflectance  = 0
            o.CastShadow   = false

        elseif o:IsA("Sound") then
            o.Volume = 0

        elseif o:IsA("MeshPart") or o:IsA("SpecialMesh") then
            if o:IsA("MeshPart") then o.TextureID = "" end
            if o:IsA("SpecialMesh") then o.TextureId = "" end
        end
    end
    local function cleanChar(char)
        for _,it in ipairs(char:GetChildren()) do
            if it:IsA("Accessory") or it:IsA("Clothing") then
                it:Destroy()
            elseif it:IsA("Humanoid") then
                it:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                it:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end
    end

    if LP.Character then cleanChar(LP.Character) end
    LP.CharacterAdded:Connect(cleanChar)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = 70
            cam:ClearAllChildren()
        end
    end)
end
Stream:addButton("FPS Boost", function()
	BoostFPS()
end)
Config.Toggle(Stream, "Anti AFK", false, function(Value)
    ExecCmd.AntiAfk = Value

    local VirtualUser = game:GetService("VirtualUser")
    local lp = game:GetService("Players").LocalPlayer

    if Value then
        if not ExecCmd.AntiAfkConnection then
            ExecCmd.AntiAfkConnection = lp.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    else
        if ExecCmd.AntiAfkConnection then
            ExecCmd.AntiAfkConnection:Disconnect()
            ExecCmd.AntiAfkConnection = nil
        end
    end
end)



local Debug_Right = Tab.Bug:addSection()
local Visual = Debug_Right:addMenu("Visuals")

Visual:addToggle("Fake Blood Moon", false, function(value)
	workspace:SetAttribute("BloodMoonEvent", value)
end)
Visual:addToggle("Fake Frost Event", false, function(value)
	workspace:SetAttribute("FrostEvent", value)
end)

Visual:addToggle("Fake Thunderstorm", false, function(value)
	workspace:SetAttribute("Thunderstorm", value)
end)

Visual:addToggle("Fake Disco Event", false, function(value)
	workspace:SetAttribute("DiscoEvent", value)
end)
