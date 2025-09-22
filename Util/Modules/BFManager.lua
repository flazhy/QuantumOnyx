
local AutoFarm = {}

repeat task.wait() until game:IsLoaded()

do
	Players = game:GetService("Players")
	ReplicatedStorage = game:GetService("ReplicatedStorage")
	CollectionService = game:GetService("CollectionService")
	TweenService = game:GetService("TweenService")
	Workspace = game:GetService("Workspace")
	VirtualUser = game:GetService("VirtualUser")
	RunService = game:GetService("RunService")
	UserInputService = game:GetService("UserInputService")
	Lighting = game:GetService("Lighting")

	Player = Players.LocalPlayer
	Characters = Workspace.Characters
	Character = Player.Character or Player.CharacterAdded:Wait()

	Remotes = ReplicatedStorage:WaitForChild("Remotes")
 	PlayerLevel = Player:WaitForChild("Data"):WaitForChild("Level")
	CommF_ = Remotes:WaitForChild("CommF_")
	Enemies = Workspace:WaitForChild("Enemies", 9e9)
	WorldOrigin = Workspace:WaitForChild("_WorldOrigin", 9e9)

	Modules = ReplicatedStorage:WaitForChild("Modules")
	Net = Modules:WaitForChild("Net")
	RE_RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
	RE_RegisterHit = Net:WaitForChild("RE/RegisterHit")
	GuideModule = require(ReplicatedStorage.GuideModule)
end


local Assets = {};function Assets:Load(path)
    if not self[path] then
        local url = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/" .. path .. ".lua"
        local result = loadstring(game:HttpGet(url))()
        self[path] = result
    end
    return self[path]
end

local Notification = Assets:Load("Util/NotifyLib")
local Library = Assets:Load("Util/Library")

local World1, World2, World3 = game.PlaceId == 2753915549, game.PlaceId == 4442272183, game.PlaceId == 7449423635

function FireRemote(...)
	return CommF_:InvokeServer(...)
end

local Character, HRP, StopFlag = nil, nil, false

local function UpdateCharacter()
	Character = Player.Character or Player.CharacterAdded:Wait()
	HRP = Character:WaitForChild("HumanoidRootPart")
end

Player.CharacterAdded:Connect(UpdateCharacter)
UpdateCharacter()

local function EnableNoclip()
	if HRP and not HRP:FindFirstChild("BodyClip") then
		local clip = Instance.new("BodyVelocity")
		clip.Name, clip.Parent = "BodyClip", HRP
		clip.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		clip.Velocity = Vector3.zero
	end
end

local function DisableCollisions(char)
	char = char or Character
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

local Flags = {
	"AutoFarm", "Auto_Dungeon", "AutoFarmBossHallow", "AutoFarmPrince", "Auto_Bone",
	"Auto_Saber", "AutoDarkCoat", "AutoBartilo", "AutoFactory", "AutoPirateRaid",
	"AutoEvoRaceV2", "KillPlayer", "AutoDarkDagger", "AutoObservation", "AutoRainbowHaki",
	"AutoObservationv2", "TrainRace", "AutoLawRaid", "AutoMaterial", "TweenMGear",
	"AutoFinishTrial", "TeleportToIsland", "AutoOpenColors", "Tweenfruit", "AutoRenguko",
	"RaceDoor", "AutoDoughKing", "AutoRaid", "AutoMusketeerHat", "AutoThirdSea",
	"TeleportKitsune", "CollectAzure", "AutoDeathStep", "AutoEvolveV3Mink", "AutoCursedCaptain",
	"AutoTrain", "AutoVolcanoEvent", "AutoQuestBlaze", "AutoFarmBossSelected",
	"KillAllBosses", "AutoTyrantOfTheSkies", "AutoSecondSea"
}

local function ShouldNoclip()
	for _, flag in ipairs(Flags) do
		if getgenv()[flag] then return true end
	end
	return false
end

task.spawn(function()
	while true do
		if ShouldNoclip() then
			EnableNoclip()
			DisableCollisions()
		else
			if HRP then
				local clip = HRP:FindFirstChild("BodyClip")
				if clip then clip:Destroy() end
			end
		end
		task.wait(0.1)
	end
end)

local CachedLocations = {}

local function GetLocationTable(placeId)
	if CachedLocations[placeId] then return CachedLocations[placeId] end

	local tbl = {}
	if placeId == 2753915549 then
		tbl = {
			Vector3.new(-4652, 873, -1754),
			Vector3.new(-7895, 5547, -380),
			Vector3.new(61164, 5, 1820),
			Vector3.new(3865, 5, -1926)
		}
	elseif placeId == 4442272183 then
		tbl = {
			Vector3.new(-317, 331, 597),
			Vector3.new(2283, 15, 867),
			Vector3.new(923, 125, 32853),
			Vector3.new(-6509, 83, -133)
		}
	elseif placeId == 7449423635 then
		tbl = {
			Vector3.new(-12471, 374, -7551),
			Vector3.new(5756, 610, -282),
			Vector3.new(-5092, 315, -3130),
			Vector3.new(-12001, 332, -8861),
			Vector3.new(5319, 23, -93),
			Vector3.new(28286, 14897, 103)
		}
	end

	CachedLocations[placeId] = tbl
	return tbl
end

local function GetTPPos(targetPos)
	local teleports = GetLocationTable(game.PlaceId)
	if not teleports then return nil end

	local nearest, minDist = nil, math.huge
	for _, pos in ipairs(teleports) do
		local dist = (pos - targetPos).Magnitude
		if dist < minDist then
			minDist = dist
			nearest = pos
		end
	end
	return nearest
end

local function RequestEntrance(pos)
	FireRemote("requestEntrance", pos)

	if HRP then
		HRP.CFrame = HRP.CFrame + Vector3.new(0, 30, 0)
	end

	task.wait(0.5)
end

local function Tween(goal)
	if not HRP then return end

	local from = HRP.CFrame
	local targetPos = goal.Position
	local portal = GetTPPos(targetPos)
	local playerDist = (targetPos - from.Position).Magnitude

	if portal then
		local portalDist = (targetPos - portal).Magnitude
		if playerDist > portalDist + 300 then
			RequestEntrance(portal)
			task.wait(0.1)
			from = HRP.CFrame
		end
	end

	local start = tick()
	local totalDistance = (targetPos - from.Position).Magnitude
	while true do
		if StopFlag then return end

		local speed = tonumber(getgenv().TweenSpeed or 300)
		local alpha = math.clamp(((tick() - start) * speed) / totalDistance, 0, 1)
		HRP:PivotTo(from:Lerp(goal, alpha))

		if (targetPos - HRP.Position).Magnitude <= 5 or alpha >= 1 then
			break
		end
		task.wait()
	end

	if not StopFlag then
		HRP:PivotTo(goal)
	end
end

local function topos(target)
	StopFlag = false
	local goal = typeof(target) == "Vector3" and CFrame.new(target) or target
	Tween(goal)
end

function StopTween()
	StopFlag = true
	if HRP then
		HRP.CFrame += Vector3.new(0, math.random(1, 3) / 100, 0)

		local clip = HRP:FindFirstChild("BodyClip")
		if clip then clip:Destroy() end
	end
end

	local Type = 1

	task.spawn(function()
		while true do
			Type = 1
			if Type == 1 then
				Pos = Vector3.new(0, PosY, 0)
			end
			task.wait(0.1)
		end
	end)

local StopTweenBoat = false

function PlayBoatsTween(Target)
    local boat = workspace.Boats:FindFirstChild(getgenv().BoatSelected)
    if not boat then return end

    local vehicleSeat = boat:FindFirstChild("VehicleSeat")
    if not vehicleSeat then return end

    local TargetCFrame = typeof(Target) == "Vector3" and CFrame.new(Target) or Target
    if not TargetCFrame then return end

    local function LerpTween(StartCFrame, EndCFrame, speed)
        local distance = (EndCFrame.Position - StartCFrame.Position).Magnitude
        local duration = distance / speed
        local startTime = tick()

        while tick() - startTime < duration do
            if StopTweenBoat then return end
            vehicleSeat.CFrame = StartCFrame:Lerp(EndCFrame, (tick() - startTime) / duration)
            task.wait()
        end
        if not StopTweenBoat then
            vehicleSeat.CFrame = EndCFrame
        end
    end

    LerpTween(vehicleSeat.CFrame, TargetCFrame, getgenv().SetBoatSpeed)
end

function StopBoatsTween()
    StopTweenBoat = true
    task.wait(0.1)
    StopTweenBoat = false
end

spawn(function()
    pcall(function()
        game:GetService("RunService").Stepped:Connect(function()
            if getgenv().AutoSail then
                if game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected) then
                    local BoatsTarget = game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected)
                    for _,v in pairs(BoatsTarget:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end
            end
        end)
    end)
end)

  spawn(function()
    while wait() do
        pcall(function()
            if getgenv().AutoSail then
                game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected).VehicleSeat.BodyVelocity.MaxForce = Vector3.new(100000000000,100000000000,100000000000)
                game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected).VehicleSeat.BodyPosition.MaxForce = Vector3.new(100000000,100000000,100000000)
            else
                game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected).VehicleSeat.BodyVelocity.MaxForce = Vector3.new(2453406976, 0, 2453406976)
                game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected).VehicleSeat.BodyPosition.MaxForce = Vector3.new(0, 2453406976, 0)
                game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected).VehicleSeat.BodyVelocity.Velocity = Vector3.new(0,0,0)

            end
        end)
    end
end)



CheckMon = function(Mon)
	for _, cont in ipairs({Enemies, ReplicatedStorage}) do
		for _, v in ipairs(cont:GetChildren()) do
			if v.Name == Mon then
				local monH = v:FindFirstChild("Humanoid")
				if monH and monH.Health > 0 then
					return true
				end
			end
		end
	end
	return false
end
  


  GetEnemies = function(MonList)
	local Distance, Nearest = math.huge, nil
	local plrPP = Player.Character and Player.Character.PrimaryPart
	if not plrPP then
		return nil
	end

	for _, cont in next, {Enemies, ReplicatedStorage} do
		for _, v in ipairs(cont:GetChildren()) do
			if table.find(MonList, v.Name) then
				local monH = v:FindFirstChild("Humanoid")
				local monPP = v.PrimaryPart
				if monH and monH.Health > 0 and monPP then
					local Mag = (plrPP.Position - monPP.Position).Magnitude
					if Mag < Distance then
						Distance, Nearest = Mag, v
					end
				end
			end
		end
	end

	return Nearest
end


  local function GetDistance(Pos)
	if typeof(Pos) == "CFrame" then
		return Player:DistanceFromCharacter(Pos.Position)
	elseif typeof(Pos) == "Vector3" then
		return Player:DistanceFromCharacter(Pos)
	end
  end
  local function StartQuest1(quest, number)
	FireRemote("StartQuest", quest, number)
end


  local function StartQuest(Title, String, Position)
    local plrRP = Player.Character:FindFirstChild("HumanoidRootPart")
    if plrRP and GetDistance(Position) <= 3 then
        FireRemote("StartQuest", Title, String)
        task.wait(0.5)
    else
        topos(Position)
    end
end
function CheckQuest()
	MyLevel = game:GetService("Players").LocalPlayer.Data.Level.Value
	if World1 then
	if ((MyLevel == 1) or (MyLevel <= 9)) then
	 	if tostring(Player.Team) == "Marines" then
			Mon, NameQuest, LevelQuest = "Trainee", "MarineQuest", 1
		elseif tostring(Player.Team) == "Pirates" then
			Mon, NameQuest, LevelQuest = "Bandit", "BanditQuest1", 1
		end
	elseif ((MyLevel == 10) or (MyLevel <= 14)) then
		Mon, NameQuest, LevelQuest = "Monkey", "JungleQuest", 1
	elseif ((MyLevel == 15) or (MyLevel < 30)) then
	if (CheckMon("The Gorilla King") and (MyLevel >= 20)) then
		Mon, NameQuest, LevelQuest = "The Gorilla King", "JungleQuest", 3
	else
		Mon, NameQuest, LevelQuest = "Gorilla", "JungleQuest", 2
	end
	elseif ((MyLevel == 30) or (MyLevel <= 39)) then
		Mon, NameQuest, LevelQuest = "Pirate", "BuggyQuest1", 1
	elseif ((MyLevel == 40) or (MyLevel < 60)) then
		if (CheckMon("Chief") and (MyLevel >= 55)) then
		Mon, NameQuest, LevelQuest = "Chief", "BuggyQuest1", 3
		else
		Mon, NameQuest, LevelQuest = "Brute", "BuggyQuest1", 2
		end
	elseif ((MyLevel == 60) or (MyLevel <= 74)) then
		Mon, NameQuest, LevelQuest = "Desert Bandit", "DesertQuest", 1
	elseif ((MyLevel == 75) or (MyLevel <= 89)) then
		Mon, NameQuest, LevelQuest = "Desert Officer", "DesertQuest", 2
	elseif ((MyLevel == 90) or (MyLevel <= 99)) then
		Mon, NameQuest, LevelQuest = "Snow Bandit", "SnowQuest", 1
	elseif ((MyLevel == 100) or (MyLevel <= 119)) then
		if (CheckMon("Yeti") and (MyLevel >= 105)) then
		Mon, NameQuest, LevelQuest = "Yeti", "SnowQuest", 3
		else
		Mon, NameQuest, LevelQuest = "Snowman", "SnowQuest", 2
		end
	elseif ((MyLevel == 120) or (MyLevel <= 149)) then
		if (CheckMon("Vice Admiral") and (MyLevel >= 130)) then
		Mon, NameQuest, LevelQuest = "Vice Admiral", "MarineQuest2", 2
		else
		Mon, NameQuest, LevelQuest = "Chief Petty Officer", "MarineQuest2", 1
		end
	elseif ((MyLevel == 150) or (MyLevel <= 174)) then
		Mon, NameQuest, LevelQuest = "Sky Bandit", "SkyQuest", 1
	elseif ((MyLevel == 175) or (MyLevel <= 189)) then
		Mon, NameQuest, LevelQuest = "Dark Master", "SkyQuest", 2
	elseif ((MyLevel == 190) or (MyLevel <= 209)) then
		Mon, NameQuest, LevelQuest = "Prisoner", "PrisonerQuest", 1
	  elseif ((MyLevel == 210) or (MyLevel <= 249)) then
		if (CheckMon("Swan") and (MyLevel >= 240)) then
		 	Mon, NameQuest, LevelQuest = "Swan", "ImpelQuest", 3
		elseif (CheckMon("Chief Warden") and (MyLevel >= 230)) then
		  	Mon, NameQuest, LevelQuest = "Chief Warden", "ImpelQuest", 2
		elseif (CheckMon("Warden") and (MyLevel >= 220)) then
		  	Mon, NameQuest, LevelQuest = "Warden", "ImpelQuest", 1
		else
		  	Mon, NameQuest, LevelQuest = "Dangerous Prisoner", "PrisonerQuest", 2
		end
	  elseif ((MyLevel == 250) or (MyLevel <= 274)) then
		Mon, NameQuest, LevelQuest = "Toga Warrior", "ColosseumQuest", 1
	  elseif ((MyLevel == 275) or (MyLevel <= 299)) then
		Mon, NameQuest, LevelQuest = "Gladiator",  "ColosseumQuest", 2
	  elseif ((MyLevel == 300) or (MyLevel <= 324)) then
		Mon, NameQuest, LevelQuest = "Military Soldier", "MagmaQuest", 1
	  elseif ((MyLevel == 325) or (MyLevel <= 374)) then
		if (CheckMon("Magma Admiral") and (MyLevel >= 350)) then
		  	Mon, NameQuest, LevelQuest = "Magma Admiral", "MagmaQuest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Military Spy", "MagmaQuest", 2
		end
	  elseif ((MyLevel == 375) or (MyLevel <= 399)) then
		Mon, NameQuest, LevelQuest = "Fishman Warrior", "FishmanQuest", 1
	  elseif ((MyLevel == 400) or (MyLevel <= 449)) then
		if (CheckMon("Fishman Lord") and (MyLevel >= 425)) then
		  	Mon, NameQuest, LevelQuest = "Fishman Lord", "FishmanQuest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Fishman Commando", "FishmanQuest", 2
		end
	  elseif ((MyLevel == 450) or (MyLevel <= 474)) then
		Mon, NameQuest, LevelQuest = "God's Guard", "SkyExp1Quest", 1
	  elseif ((MyLevel == 475) or (MyLevel <= 524)) then
		if (CheckMon("Wysper") and (MyLevel >= 500)) then
		  	Mon, NameQuest, LevelQuest = "Wysper", "SkyExp1Quest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Shanda", "SkyExp1Quest", 2
		end
	  elseif ((MyLevel == 525) or (MyLevel <= 549)) then
		Mon, NameQuest, LevelQuest = "Royal Squad", "SkyExp2Quest", 1
	  elseif ((MyLevel == 550) or (MyLevel <= 624)) then
		if (CheckMon("Thunder God") and (MyLevel >= 575)) then
		  	Mon, NameQuest, LevelQuest = "Thunder God", "SkyExp2Quest", 3
		else
		 	Mon, NameQuest, LevelQuest = "Royal Soldier", "SkyExp2Quest", 2
		end
	  elseif ((MyLevel >= 625) and (MyLevel <= 649)) then
		Mon, NameQuest, LevelQuest = "Galley Pirate", "FountainQuest", 1
	  elseif (MyLevel >= 650) then
		if (CheckMon("Cyborg") and (MyLevel >= 675)) then
		  	Mon, NameQuest, LevelQuest = "Cyborg", "FountainQuest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Galley Captain", "FountainQuest", 2
		end
	  end
	elseif World2 then
	  if ((MyLevel == 700) or (MyLevel <= 724)) then
		Mon, NameQuest, LevelQuest = "Raider", "Area1Quest", 1
	  elseif ((MyLevel == 725) or (MyLevel <= 774)) then
		if (CheckMon("Diamond") and (MyLevel >= 750)) then
		  	Mon, NameQuest, LevelQuest = "Diamond", "Area1Quest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Mercenary", "Area1Quest", 2
		end
	  elseif ((MyLevel == 775) or (MyLevel <= 799)) then
		Mon, NameQuest, LevelQuest = "Swan Pirate", "Area2Quest", 1
	  elseif ((MyLevel == 800) or (MyLevel <= 874)) then
		if (CheckMon("Jeremy") and (MyLevel >= 850)) then
		  	Mon, NameQuest, LevelQuest = "Jeremy", "Area2Quest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Factory Staff", "Area2Quest", 2
		end
	  elseif ((MyLevel == 875) or (MyLevel <= 899)) then
		Mon, NameQuest, LevelQuest = "Marine Lieutenant", "MarineQuest3", 1
	  elseif ((MyLevel == 900) or (MyLevel <= 949)) then
		if (CheckMon("Orbitus") and (MyLevel >= 925)) then
		  	Mon, NameQuest, LevelQuest = "Orbitus", "MarineQuest3", 3
		else
		  	Mon, NameQuest, LevelQuest = "Marine Captain", "MarineQuest3", 2
		end
	  elseif ((MyLevel == 950) or (MyLevel <= 974)) then
		Mon, NameQuest, LevelQuest = "Zombie", "ZombieQuest", 1
	  elseif ((MyLevel == 975) or (MyLevel <= 999)) then
		Mon, NameQuest, LevelQuest = "Vampire", "ZombieQuest", 2
	  elseif ((MyLevel == 1000) or (MyLevel <= 1049)) then
		Mon, NameQuest, LevelQuest = "Snow Trooper", "SnowMountainQuest", 1
	  elseif ((MyLevel == 1050) or (MyLevel <= 1099)) then
		Mon, NameQuest, LevelQuest = "Winter Warrior", "SnowMountainQuest", 2
	  elseif ((MyLevel == 1100) or (MyLevel <= 1124)) then
		Mon, NameQuest, LevelQuest = "Lab Subordinate", "IceSideQuest", 1
	  elseif ((MyLevel == 1125) or (MyLevel <= 1174)) then
		if (CheckMon("Smoke Admiral") and (MyLevel >= 1150)) then
			Mon, NameQuest, LevelQuest = "Smoke Admiral", "IceSideQuest", 3
		else
			Mon, NameQuest, LevelQuest = "Horned Warrior", "IceSideQuest", 2
		end
	  elseif ((MyLevel == 1175) or (MyLevel <= 1199)) then
		Mon, NameQuest, LevelQuest = "Magma Ninja", "FireSideQuest", 1
	  elseif ((MyLevel == 1200) or (MyLevel <= 1249)) then
		Mon, NameQuest, LevelQuest = "Lava Pirate", "FireSideQuest", 2
	  elseif ((MyLevel == 1250) or (MyLevel <= 1274)) then
		Mon, NameQuest, LevelQuest = "Ship Deckhand", "ShipQuest1", 1
	  elseif ((MyLevel == 1275) or (MyLevel <= 1299)) then
		Mon, NameQuest, LevelQuest = "Ship Engineer", "ShipQuest1", 2
	  elseif ((MyLevel == 1300) or (MyLevel <= 1324)) then
		Mon, NameQuest, LevelQuest = "Ship Steward", "ShipQuest2", 1
	  elseif ((MyLevel == 1325) or (MyLevel <= 1349)) then
		Mon, NameQuest, LevelQuest = "Ship Officer", "ShipQuest2", 2
	  elseif ((MyLevel == 1350) or (MyLevel <= 1374)) then
		Mon, NameQuest, LevelQuest = "Arctic Warrior", "FrostQuest", 1
	  elseif ((MyLevel == 1375) or (MyLevel <= 1424)) then
		if (CheckMon("Awakened Ice Admiral") and (MyLevel >= 1400)) then
			Mon, NameQuest, LevelQuest = "Awakened Ice Admiral", "FrostQuest", 3
		else
			Mon, NameQuest, LevelQuest = "Snow Lurker", "FrostQuest", 2
		end
	  elseif ((MyLevel == 1425) or (MyLevel <= 1449)) then
		Mon, NameQuest, LevelQuest = "Sea Soldier", "ForgottenQuest", 1
	  elseif (MyLevel >= 1450) then
		if (CheckMon("Tide Keeper") and (MyLevel >= 1475)) then
			Mon, NameQuest, LevelQuest = "Tide Keeper", "ForgottenQuest", 3
		else
			Mon, NameQuest, LevelQuest = "Water Fighter", "ForgottenQuest", 2
		end
	  end
	elseif World3 then
	  if ((MyLevel == 1500) or (MyLevel <= 1524)) then
		Mon, NameQuest, LevelQuest = "Pirate Millionaire", "PiratePortQuest", 1
	  elseif ((MyLevel == 1525) or (MyLevel <= 1574)) then
		Mon, NameQuest, LevelQuest = "Pistol Billionaire", "PiratePortQuest", 2
	  elseif ((MyLevel == 1575) or (MyLevel <= 1599)) then
		Mon, NameQuest, LevelQuest = "Dragon Crew Warrior", "DragonCrewQuest", 1
	  elseif ((MyLevel == 1600) or (MyLevel <= 1624)) then
		Mon, NameQuest, LevelQuest = "Dragon Crew Archer", "DragonCrewQuest", 2
	  elseif ((MyLevel == 1625) or (MyLevel <= 1649)) then
		Mon, NameQuest, LevelQuest = "Hydra Enforcer", "VenomCrewQuest", 1
	  elseif ((MyLevel == 1650) or (MyLevel <= 1699)) then
		Mon, NameQuest, LevelQuest = "Venomous Assailant", "VenomCrewQuest", 2
	  elseif ((MyLevel == 1700) or (MyLevel <= 1724)) then
		Mon, NameQuest, LevelQuest = "Marine Commodore", "MarineTreeIsland", 1
	  elseif ((MyLevel == 1725) or (MyLevel <= 1774)) then
		Mon, NameQuest, LevelQuest = "Marine Rear Admiral", "MarineTreeIsland", 2
	  elseif ((MyLevel == 1775) or (MyLevel <= 1799)) then
		Mon, NameQuest, LevelQuest = "Fishman Raider", "DeepForestIsland3", 1
	  elseif ((MyLevel == 1800) or (MyLevel <= 1824)) then
		Mon, NameQuest, LevelQuest = "Fishman Captain", "DeepForestIsland3", 2
	  elseif ((MyLevel == 1825) or (MyLevel <= 1849)) then
		Mon, NameQuest, LevelQuest = "Forest Pirate", "DeepForestIsland", 1
	  elseif ((MyLevel == 1850) or (MyLevel <= 1899)) then
		Mon, NameQuest, LevelQuest = "Mythological Pirate", "DeepForestIsland", 2
	  elseif ((MyLevel == 1900) or (MyLevel <= 1924)) then
		Mon, NameQuest, LevelQuest = "Jungle Pirate", "DeepForestIsland2", 1
	  elseif ((MyLevel == 1925) or (MyLevel <= 1974)) then
		Mon, NameQuest, LevelQuest = "Musketeer Pirate", "DeepForestIsland2", 2
	  elseif ((MyLevel == 1975) or (MyLevel <= 1999)) then
		Mon, NameQuest, LevelQuest = "Reborn Skeleton", "HauntedQuest1", 1
	  elseif ((MyLevel == 2000) or (MyLevel <= 2024)) then
		Mon, NameQuest, LevelQuest = "Living Zombie", "HauntedQuest1", 2
	  elseif ((MyLevel == 2025) or (MyLevel <= 2049)) then
		Mon, NameQuest, LevelQuest = "Demonic Soul", "HauntedQuest2", 1
	  elseif ((MyLevel == 2050) or (MyLevel <= 2074)) then
		Mon, NameQuest, LevelQuest = "Posessed Mummy", "HauntedQuest2", 2
	  elseif ((MyLevel == 2075) or (MyLevel <= 2099)) then
		Mon, NameQuest, LevelQuest = "Peanut Scout", "NutsIslandQuest", 1
	  elseif ((MyLevel == 2100) or (MyLevel <= 2124)) then
		Mon, NameQuest, LevelQuest = "Peanut President", "NutsIslandQuest", 2
	  elseif ((MyLevel == 2125) or (MyLevel <= 2149)) then
		Mon, NameQuest, LevelQuest = "Ice Cream Chef", "IceCreamIslandQuest", 1
	  elseif ((MyLevel == 2150) or (MyLevel <= 2199)) then
		Mon, NameQuest, LevelQuest = "Ice Cream Commander", "IceCreamIslandQuest", 2
	  elseif ((MyLevel == 2200) or (MyLevel <= 2224)) then
		Mon, NameQuest, LevelQuest = "Cookie Crafter", "CakeQuest1", 1
	  elseif ((MyLevel == 2225) or (MyLevel <= 2249)) then
		Mon, NameQuest, LevelQuest = "Cake Guard", "CakeQuest1", 2
	  elseif ((MyLevel == 2250) or (MyLevel <= 2274)) then
		Mon, NameQuest, LevelQuest = "Baking Staff", "CakeQuest2", 1
	  elseif ((MyLevel == 2275) or (MyLevel <= 2299)) then
		Mon, NameQuest, LevelQuest = "Head Baker", "CakeQuest2", 2
	  elseif ((MyLevel == 2300) or (MyLevel <= 2324)) then
		Mon, NameQuest, LevelQuest = "Cocoa Warrior", "ChocQuest1", 1
	  elseif ((MyLevel == 2325) or (MyLevel <= 2349)) then
		Mon, NameQuest, LevelQuest = "Chocolate Bar Battler", "ChocQuest1", 2
	  elseif ((MyLevel == 2350) or (MyLevel <= 2374)) then
		Mon, NameQuest, LevelQuest = "Sweet Thief", "ChocQuest2", 1
	  elseif ((MyLevel == 2375) or (MyLevel <= 2399)) then
		Mon, NameQuest, LevelQuest = "Candy Rebel", "ChocQuest2", 2
	  elseif ((MyLevel == 2400) or (MyLevel <= 2424)) then
		Mon, NameQuest, LevelQuest = "Candy Pirate", "CandyQuest1", 1
	  elseif ((MyLevel == 2425) or (MyLevel <= 2449)) then
		Mon, NameQuest, LevelQuest = "Snow Demon", "CandyQuest1", 2
	  elseif ((MyLevel == 2450) or (MyLevel <= 2474)) then
		Mon, NameQuest, LevelQuest = "Isle Outlaw", "TikiQuest1", 1
	  elseif ((MyLevel == 2475) or (MyLevel <= 2499)) then
		Mon, NameQuest, LevelQuest = "Island Boy", "TikiQuest1", 2
	  elseif ((MyLevel == 2500) or (MyLevel <= 2524)) then
		Mon, NameQuest, LevelQuest = "Sun-kissed Warrior", "TikiQuest2", 1
	  elseif ((MyLevel == 2525) or (MyLevel <= 2550)) then
		Mon, NameQuest, LevelQuest = "Isle Champion", "TikiQuest2", 2
	  elseif ((MyLevel == 2550) or (MyLevel <= 2574)) then
		Mon, NameQuest, LevelQuest = "Serpent Hunter", "TikiQuest3", 1
	  elseif ((MyLevel == 2575) or (MyLevel <= 2600)) then
		Mon, NameQuest, LevelQuest = "Skull Slayer", "TikiQuest3", 2
        elseif (MyLevel >= 2600 and MyLevel <= 2624) then
            Mon, NameQuest, LevelQuest = "Reef Bandit", "SubmergedQuest1", 1
			if getgenv().AutoFarm then
				local npc = workspace:FindFirstChild("NPCs"):FindFirstChild("Submarine Worker")
				if npc and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
					if (hrp.Position - npc.HumanoidRootPart.Position).Magnitude > 50 then
						topos(npc.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
						task.wait(0.5)
						local Net = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
						pcall(function()
							Net:RemoteFunction("SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
						end)
					end
				end
			end
        elseif (MyLevel >= 2625 and MyLevel <= 2649) then
            Mon, NameQuest, LevelQuest = "Coral Pirate", "SubmergedQuest1", 2
			if getgenv().AutoFarm then
				local npc = workspace:FindFirstChild("NPCs"):FindFirstChild("Submarine Worker")
				if npc and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
					if (hrp.Position - npc.HumanoidRootPart.Position).Magnitude > 50 then
						topos(npc.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
						task.wait(0.5)
						local Net = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
						pcall(function()
							Net:RemoteFunction("SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
						end)
					end
				end
			end
        elseif (MyLevel >= 2650 and MyLevel <= 2674) then
            Mon, NameQuest, LevelQuest = "Sea Chanter", "SubmergedQuest2", 1
			if getgenv().AutoFarm then
				local npc = workspace:FindFirstChild("NPCs"):FindFirstChild("Submarine Worker")
				if npc and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
					if (hrp.Position - npc.HumanoidRootPart.Position).Magnitude > 50 then
						topos(npc.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
						task.wait(0.5)
						local Net = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
						pcall(function()
							Net:RemoteFunction("SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
						end)
					end
				end
			end
        elseif (MyLevel >= 2675) then
            Mon, NameQuest, LevelQuest = "Ocean Prophet", "SubmergedQuest2", 2
			if getgenv().AutoFarm then
				local npc = workspace:FindFirstChild("NPCs"):FindFirstChild("Submarine Worker")
				if npc and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
					if (hrp.Position - npc.HumanoidRootPart.Position).Magnitude > 50 then
						topos(npc.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
						task.wait(0.5)
						local Net = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
						pcall(function()
							Net:RemoteFunction("SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
						end)
					end
				end
			end
        end
    end
end

  local function GetBossQuest(BossName)
	-- Bosses Sea 1
	if BossName == "The Gorilla King" then
	  return true, CFrame.new(-1128, 6, -451), "JungleQuest"
	elseif BossName == "Chef" then
	  return true, CFrame.new(-1131, 14, 4080), "BuggyQuest1"
	elseif BossName == "Yeti" then
	  return true, CFrame.new(1185, 106, -1518), "SnowQuest"
	elseif BossName == "Vice Admiral" then
	  return true, CFrame.new(-4807, 21, 4360), "MarineQuest2", 2
	elseif BossName == "Swan" then
	  return true, CFrame.new(5230, 4, 749), "ImpelQuest"
	elseif BossName == "Chief Warden" then
	  return true, CFrame.new(5230, 4, 749), "ImpelQuest", 2
	elseif BossName == "Warden" then
	  return true, CFrame.new(5230, 4, 749), "ImpelQuest", 1
	elseif BossName == "Magma Admiral" then
	  return true, CFrame.new(-5694, 18, 8735), "MagmaQuest"
	elseif BossName == "Fishman Lord" then
	  return true, CFrame.new(61350, 31, 1095), "FishmanQuest"
	elseif BossName == "Wysper" then
	  return true, CFrame.new(-7927, 5551, -637), "SkyExp1Quest"
	elseif BossName == "Thunder God" then
	  return true, CFrame.new(-7751, 5607, -2315), "SkyExp2Quest"
	elseif BossName == "Cyborg" then
	  return true, CFrame.new(6138, 10, 3939), "FountainQuest"
	elseif BossName == "Saber Expert" then
	  return false, CFrame.new(-1461, 30, -51)
	elseif BossName == "The Saw" then
	  return false, CFrame.new(-690, 15, 1583)
	elseif BossName == "Greybeard" then
	  return false, CFrame.new(-4807, 21, 4360)
	-- Bosses Sea 2
	elseif BossName == "Diamond" then
	  return true, CFrame.new(-1569, 199, -31), "Area1Quest"
	elseif BossName == "Jeremy" then
	  return true, CFrame.new(2316, 449, 787), "Area2Quest"
	elseif BossName == "Fajita" then
	  return true, CFrame.new(-2086, 73, -4208), "MarineQuest3"
	elseif BossName == "Smoke Admiral" then
	  return true, CFrame.new(-5078, 24, -5352), "IceSideQuest"
	elseif BossName == "Awakened Ice Admiral" then
	  return true, CFrame.new(6473, 297, -6944), "FrostQuest"
	elseif BossName == "Tide Keeper" then
	  return true, CFrame.new(-3711, 77, -11469), "ForgottenQuest"
	elseif BossName == "Don Swan" then
	  return false, CFrame.new(2289, 15, 808)
	elseif BossName == "Cursed Captain" then
	  return false, CFrame.new(912, 186, 33591)
	elseif BossName == "Darkbeard" then
	  return false, CFrame.new(3695, 13, -3599)
	-- Bosses Sea 3
	elseif BossName == "Longma" then
	  return false, CFrame.new(-10218, 333, -9444)
	elseif BossName == "Stone" then
	  return true, CFrame.new(-1049, 40, 6791), "PiratePortQuest"
	elseif BossName == "Beautiful Pirate" then
	  return true, CFrame.new(5241, 23, 129), "VenomCrewQuest"
	elseif BossName == "Hydra Leader" then
	  return true, CFrame.new(5730, 602, 199), "AmazonQuest2"
	elseif BossName == "Kilo Admiral" then
	  return true, CFrame.new(2889, 424, -7233), "MarineTreeIsland"
	elseif BossName == "Captain Elephant" then
	  return true, CFrame.new(-13393, 319, -8423), "DeepForestIsland"
	elseif BossName == "Cake Queen" then
	  return true, CFrame.new(-710, 382, -11150), "IceCreamIslandQuest"
	elseif BossName == "Dough King" or BossName == "Cake Prince" then
	  return false, CFrame.new(-2103, 70, -12165)
	elseif BossName == "rip_indra True Form" then
	  return false, CFrame.new(-5333, 424, -2673)
	end
  end
  
  local BossListT = {
	"Greybeard",
	"The Saw",
	"Saber Expert",
	
	"The Gorilla King",
	"Bobby",
	"Yeti",
	"Vice Admiral",
	"Warden",
	"Chief Warden",
	"Swan",
	"Magma Admiral",
	"Fishman Lord",
	"Wysper",
	"Thunder God",
	"Cyborg",
	
	"Darkbeard",
	"Cursed Captain",
	"Order",
	"Don Swan",
	
	"Diamond",
	"Jeremy",
	"Fajita",
	"Smoke Admiral",
	"Awakened Ice Admiral",
	"Tide Keeper",
	
	"Dough King",
	"Cake Prince",
	"rip_indra True Form",
	"Soul Reaper",

	"Stone",
	"Kilo Admiral",
	"Captain Elephant",
	"Beautiful Pirate",
	"Hydra Leader",
	"Cake Queen",
	"Longma"
  }

  function NPCPos()
    for i, v in pairs(GuideModule["Data"]["NPCList"]) do
        if v["NPCName"] == GuideModule["Data"]["LastClosestNPC"] then
            return i["CFrame"]
        end
    end
end

QuestNeta = function()
    local Neta = CheckQuest()
    return {
        [1] = Mon,
        [2] = NameQuest,
        [3] = LevelQuest,
    }
end

local function QuestVisible()
  local QuestActive = Player.PlayerGui.Main.Quest
  if not QuestActive.Visible then
    local QuestActive = Player.PlayerGui.Main.Quest
    QuestActive.Container.QuestTitle.Title.Text = ""
  end
  return QuestActive.Visible
end

local function VerifyQuest(EnemieName)
  local QuestActive = Player.PlayerGui.Main.Quest
  local Text1 = QuestActive.Container.QuestTitle.Title.Text:gsub("-", ""):lower()
  local Text2 = EnemieName:gsub("-", ""):lower()
  return QuestActive.Visible and Text1:find(Text2)
end

PlayerLevel.Changed:Connect(CheckQuest)
task.spawn(function()while task.wait(1) do pcall(CheckQuest)end;end)
CheckQuest()


function GetQuest()
    local player = game.Players.LocalPlayer
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local npcPos = NPCPos()
    local Distance = GetDistance(npcPos)
    if not VerifyQuest(QuestNeta()[1]) then
        FireRemote("AbandonQuest")
    end
    if Distance <= 20 then
        FireRemote("StartQuest", QuestNeta()[2], QuestNeta()[3])
    else
        if root then
            local dir = (npcPos.Position - root.Position).Unit
            local targetCFrame = npcPos - (dir * 5)
            topos(targetCFrame)
        else
            topos(npcPos)
        end
    end
    FireRemote("SetSpawnPoint")
end


  local function TouchMe(key)
	local VIM = game:GetService("VirtualInputManager")
	VIM:SendKeyEvent(true, key, false, game)
	wait()
	VIM:SendKeyEvent(false, key, false, game)
  end

  AutoHaki = function()
	if not Player.Character:FindFirstChild("HasBuso") then
		FireRemote("Buso")
	end
  end
  
  local function VerifyTool(ToolName)
	local plrChar = Player and Player.Character
	local plrBag = Player and Player.Backpack
	if plrChar then
	  return plrChar:FindFirstChild(ToolName) or plrBag:FindFirstChild(ToolName)
	end
  end

  function CheckMaterial(MaterialName)
	local Inventory = FireRemote("getInventory")
	for _, v in pairs(Inventory) do
		if v.Name == MaterialName then
			return v["Count"]
		end
	end
  end
  
  local function GetNearestEnemy()
    local nearestEnemy, nearestDistance = nil, 3000
    local playerHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return nil end
    for _, enemy in ipairs(game.Workspace.Enemies:GetChildren()) do
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        local humanoid = enemy:FindFirstChild("Humanoid")
        
        if enemyHRP and humanoid and humanoid.Health > 0 then
            local distance = (playerHRP.Position - enemyHRP.Position).Magnitude
            if distance < nearestDistance then
                nearestEnemy = enemy
                nearestDistance = distance
            end
        end
    end
    return nearestEnemy
end

  local function EquipToolName(NameTool)
	local plrBag = Player.Backpack
	local plrChar = Player.Character
	local plrH = plrChar and plrChar:FindFirstChild("Humanoid")
	if plrBag and plrH and plrBag:FindFirstChild(NameTool) then
	  plrH:EquipTool(plrBag[NameTool])
	end
  end
  
  
  local EquipWeapon = (function()
	local plrBag = Player.Backpack
	local sWeapon = getgenv().SelectWeapon
	for _, tool in ipairs(plrBag:GetChildren()) do
		if tool and tool:IsA("Tool") and tool.ToolTip == sWeapon then
			EquipToolName(tool.Name)
			return
		end
	end
  end)

	local BaseAttachment = Instance.new("Attachment")
	BaseAttachment.Name = "MobBringAttachment"

	local BaseAlign = Instance.new("AlignPosition")
	BaseAlign.Name = "MobAlignPosition"
	BaseAlign.Mode = Enum.PositionAlignmentMode.OneAttachment
	BaseAlign.Responsiveness = 300
	BaseAlign.MaxForce = 9e9

function _BringEnemies(toEnemy)
    if not getgenv().BringMonster then return end

    local targetRoot = toEnemy:FindFirstChild("HumanoidRootPart") or toEnemy.PrimaryPart
    local targetHumanoid = toEnemy:FindFirstChildOfClass("Humanoid")
    if not (targetRoot and targetHumanoid and targetHumanoid.Health > 0) then return end

	pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
	local plrChar = Player.Character or Player.CharacterAdded:Wait()
    local targetCFrame = targetRoot.CFrame
    local mobName = toEnemy.Name
    local playerPos = plrChar:GetPivot().Position

    for _, enemy in pairs(Enemies:GetChildren()) do
        if enemy.Name == mobName then
            local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")

            if root and humanoid and humanoid.Health > 0 then
                if (playerPos - root.Position).Magnitude <= getgenv().BringMonsterRadius then
                    if not root:FindFirstChild("MobBringAttachment") then
                        humanoid.WalkSpeed, humanoid.JumpPower = 0, 0

                        local attachment = BaseAttachment:Clone()
                        attachment.Name = "MobBringAttachment"
                        attachment.Parent = root

                        local align = BaseAlign:Clone()
                        align.Attachment0 = attachment
                        align.Position = targetCFrame.Position
                        align.Parent = attachment
                    else
                        local attachment = root:FindFirstChild("MobBringAttachment")
                        if attachment and attachment:FindFirstChildOfClass("AlignPosition") then
                            attachment.AlignPosition.Position = targetCFrame.Position
                        end
                    end
                end
            end
        end
    end
end

function GetPosMob(Name)
	local CFrameTab = {}
	local folder = ReplicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder")
	if not folder then return CFrameTab end
	for _, v in pairs(folder:GetChildren()) do
		if v:IsA("Part") and v.Name == Name then
			table.insert(CFrameTab, v.CFrame)
		end
	end
	return CFrameTab
end

local MobCycleIndex = {}

function MobsPosition(Name)
	if type(Name) ~= "string" then 
		return nil
	end
	local mobspawn = GetPosMob(Name)
	if not mobspawn or #mobspawn == 0 then 
		return nil
	end
	local index = (MobCycleIndex[Name] or 0) + 1
	if index > #mobspawn then
		index = 1
	end
	MobCycleIndex[Name] = index
	local nextPos = mobspawn[index]
	if nextPos then
		topos(nextPos * Pos)
	end
	task.wait(0.5)
	local enemy = GetEnemies({Name})
	return enemy or nil
end


function IsNear30(partA, partB)
    if not (partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart")) then return false end
    return (partA.Position - partB.Position).Magnitude <= 25
end
AutoFarm.__index = AutoFarm

function AutoFarm.new(name)
    local self = setmetatable({}, AutoFarm)
    self.Name = name
    self.Running = false
    self.Thread = nil
    return self
end

function AutoFarm:Start()
    if self.Running then return end
    self.Running = true

    self.Thread = task.spawn(function()
        while self.Running do
            task.wait(0.5)

            local char = Player.Character or {}
            local root = char:FindFirstChild("HumanoidRootPart")

            if self.Name == "Level" then
                local Enemie = GetEnemies({ QuestNeta()[1] }) QuestVisible()
                local NearestEnemy = GetNearestEnemy()

                if getgenv().FarmMode == "Quest" then
                    if not VerifyQuest(QuestNeta()[1]) then
                        GetQuest()
                    elseif Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
                        local r = Enemie.HumanoidRootPart
                        if not IsNear30(root, r) then
                            topos(r.CFrame * Pos)
                        end
                        pcall(function()
                            EquipWeapon()
                            AutoHaki()
                            _BringEnemies(Enemie)
                        end)
                    else
                        MobsPosition(QuestNeta()[1])
                    end

                elseif getgenv().FarmMode == "No Quest" then
                    local target = Enemie
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        local r = target.HumanoidRootPart
                        if not IsNear30(root, r) then
                            topos(r.CFrame * Pos)
                        end
                        pcall(function()
                            EquipWeapon()
                            AutoHaki()
                            _BringEnemies(target)
                        end)
                    else
                        MobsPosition(QuestNeta()[1])
                    end

                elseif getgenv().FarmMode == "Nearest" then
                    local target = NearestEnemy
                    if target and target:FindFirstChild("HumanoidRootPart") then
                        local r = target.HumanoidRootPart
                        if not IsNear30(root, r) then
                            topos(r.CFrame * Pos)
                        end
                        pcall(function()
                            EquipWeapon()
                            AutoHaki()
                            _BringEnemies(target)
                        end)
                    else
                        MobsPosition(QuestNeta()[1])
                    end
                end

            elseif self.Name == "Bones" then
                local Enemie = GetEnemies({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" })
                local QuestGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
                local BoneQuestPos = CFrame.new(-9517, 172, 6078)

                if getgenv().AcceptQuests and not VerifyQuest("Demonic Soul") and (QuestGui and not QuestGui.Visible) then
                    StartQuest("HauntedQuest2", 1, BoneQuestPos)
                elseif Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
                    local r = Enemie.HumanoidRootPart
                    if not IsNear30(root, r) then
                        topos(r.CFrame * Pos)
                    end
                    pcall(function()
                        EquipWeapon()
                        AutoHaki()
                        _BringEnemies(Enemie)
                    end)
                else
                    topos(CFrame.new(-9506, 172, 6117))
                end
            end
        end
    end)
end

function AutoFarm:Stop()
    self.Running = false
    if self.Thread then
        task.cancel(self.Thread)
        self.Thread = nil
    end
end

local AutoFarmHolder = {
    Level = AutoFarm.new("Level"),
    Bones = AutoFarm.new("Bones")
}

warn("BFManager loaded")


return AutoFarmHolder
