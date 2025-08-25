repeat task.wait() until game:IsLoaded()
local Vector2, CFrame, Instance, UDim2 = Vector2, CFrame, Instance, UDim2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local Characters = Workspace.Characters
local Character = Player.Character or Player.CharacterAdded:Wait()

local function WaitForChilds(Parent, ...)
    for _, ChildName in ipairs({...}) do
        if not Parent then return nil end
        Parent = Parent:WaitForChild(ChildName, 9e9)
    end
    return Parent
end

local Remotes = WaitForChilds(ReplicatedStorage, "Remotes")
local PlayerLevel = WaitForChilds(Player, "Data", "Level")
local Enemies = WaitForChilds(Workspace, "Enemies")
local CommF_ = WaitForChilds(Remotes, "CommF_")
local WorldOrigin = WaitForChilds(Workspace, "_WorldOrigin")

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
Assets:Load("Util/Debug")
local World1, World2, World3 = game.PlaceId == 2753915549, game.PlaceId == 4442272183, game.PlaceId == 7449423635
local hookmetamethod = hookmetamethod or function(...) return ... end

function FireRemote(...)
	return CommF_:InvokeServer(...)
end
  
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")

local RE_RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RE_RegisterHit = Net:WaitForChild("RE/RegisterHit")
local GuideModule = require(ReplicatedStorage.GuideModule)

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
		"KillAllBosses", "AutoTyrantOfTheSkies"
	}
	local function ShouldNoclip()
		for _, flag in ipairs(Flags) do
			if getgenv()[flag] then return true end
		end
		return false
	end

	local NoclipMotor = nil

	task.spawn(function()
		while true do
			if ShouldNoclip() then
				if not NoclipMotor then
					NoclipMotor = task.spawn(function()
						while ShouldNoclip() do
							if not Character or not HRP or not HRP.Parent then
								UpdateCharacter()
							end
							EnableNoclip()
							DisableCollisions()
							task.wait(0.1)
						end
						NoclipMotor = nil
					end)
				end
			else
				if NoclipMotor then
					NoclipMotor = nil
				end
			end
			task.wait(0.2)
		end
	end)

	local CachedLocations = {}

	local function GetLocationTable(placeId)
		if CachedLocations[placeId] then return CachedLocations[placeId] end
		local tbl = {}

		if placeId == 2753915549 then
			tbl = {
				["Sky3"] = Vector3.new(-7894, 5547, -380),
				["Sky3Exit"] = Vector3.new(-4607, 874, -1667),
				["UnderWater"] = Vector3.new(61163, 11, 1819),
				["UnderwaterExit"] = Vector3.new(4050, 0, -1814),
				["Pirate Village"] = Vector3.new(-1242, 5, 3902)
			}
		elseif placeId == 4442272183 then
			tbl = {
				["Swan Mansion"] = Vector3.new(-390, 332, 673),
				["Swan Room"] = Vector3.new(2285, 15, 905),
				["Cursed Ship"] = Vector3.new(923, 126, 32852),
				["Zombie Island"] = Vector3.new(-6509, 83, -133)
			}
		elseif placeId == 7449423635 then
			tbl = {
				["Floating Turtle"] = Vector3.new(-12462, 375, -7552),
				["Hydra Island"] = Vector3.new(5658, 1014, -335),
				["Mansion"] = Vector3.new(-12462, 375, -7552),
				["Castle"] = Vector3.new(-5036, 315, -3179),
				["Dimensional Shift"] = Vector3.new(-2097, 4777, -15013),
				["Beautiful Pirate"] = Vector3.new(5319, 23, -93),
				["Beautiful Room"] = Vector3.new(5315, 23, -125),
				["Temple of Time"] = Vector3.new(28286, 14897, 103)
			}
		end

		CachedLocations[placeId] = tbl
		return tbl
	end

	function CheckNearestTeleporter(targetPos)
		if typeof(targetPos) ~= "Vector3" then return nil end
		if not HRP or not HRP.Parent then return nil end

		local teleports = GetLocationTable(game.PlaceId)
		if not teleports or typeof(teleports) ~= "table" then return nil end

		local nearest, minDist = nil, math.huge
		table.foreach(teleports, function(_, pos)
			if typeof(pos) == "Vector3" then
				local dist = (pos - targetPos).Magnitude
				if dist < minDist then
					minDist = dist
					nearest = pos
				end
			end
		end)
		local playerPos = HRP.Position
		local playerDist = (targetPos - playerPos).Magnitude
		if nearest and (playerDist - minDist) >= 100 then
			return nearest
		end
		return nil
	end

	function RequestEntrance(pos)
		FireRemote("requestEntrance", pos)
		if HRP then
			HRP.CFrame = HRP.CFrame + Vector3.new(0, 50, 0)
		end
		task.wait(0.5)
	end

	local function Tween(target)
		if not HRP then return end
		local goal = typeof(target) == "Vector3" and CFrame.new(target) or target
		if not goal then return end

		local from = HRP.CFrame

		local tp = CheckNearestTeleporter(goal.Position)
		if tp then
			RequestEntrance(tp)
			task.wait(0.1)
			from = HRP.CFrame
		end

		local start = tick()
		local totalDistance = (goal.Position - from.Position).Magnitude

		while true do
			if StopFlag then return end
			local speed = tonumber(getgenv().TweenSpeed or 300)
			local elapsed = tick() - start
			local alpha = math.clamp((elapsed * speed) / totalDistance, 0, 1)
			HRP.CFrame = from:Lerp(goal, alpha)
			if (goal.Position - HRP.Position).Magnitude <= 5 or alpha >= 1 then
				break
			end

			task.wait()
		end

		if not StopFlag then
			HRP.CFrame = goal
		end
	end



	local function topos(target)
		StopFlag = false
		Tween(target)
	end

	function StopTween()
		StopFlag = true
		if HRP then
			HRP.CFrame = HRP.CFrame + Vector3.new(0, 0.01, 0)
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



local CheckMon = function(Mon)
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
  
  local GetEnemies = function(MonList)
	local Distance, Nearest = math.huge, nil
	local plrPP = Player.Character and Player.Character.PrimaryPart
	if not plrPP then
		return nil
	end
	for _, cont in ipairs({Enemies, ReplicatedStorage}) do
		for _, v in ipairs(cont:GetChildren()) do
			if table.find(MonList, v.Name) then
				local monH = v:FindFirstChild("Humanoid")
				local monPP = v.PrimaryPart
				if monH and monH.Health > 0 and monPP then
					local Mag = (plrPP.Position - monPP.Position).Magnitude
					if Mag < Distance then
						Distance = Mag
						Nearest = v
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
  
  local function StartQuest(Title, String, Position)
    local plrRP = Player.Character:FindFirstChild("HumanoidRootPart")
    if plrRP and GetDistance(Position) <= 3 then
        FireRemote("StartQuest", Title, String)
        task.wait(0.5)
    else
        topos(Position)
    end
end

local function TravelToSubmerged()
    local lp = game.Players.LocalPlayer
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
    local Locations = WorldOrigin:WaitForChild("Locations")
    local island = Locations:FindFirstChild("Submerged Island")

    local npcFolder = workspace:FindFirstChild("NPCs")
    local npc = npcFolder and npcFolder:FindFirstChild("Submarine Worker")

    if getgenv().AutoFarm and island and npc and npc:FindFirstChild("HumanoidRootPart") then
        if (hrp.Position - island.Position).Magnitude > 1000 then
            topos(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5))

            repeat task.wait()
            until not getgenv().AutoFarm or (hrp.Position - npc.HumanoidRootPart.Position).Magnitude < 10

            if getgenv().AutoFarm then
                local Net = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
                pcall(function()
                    Net:RemoteFunction("SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
                end)
                repeat task.wait()
                until not getgenv().AutoFarm or (hrp.Position - island.Position).Magnitude <= 500
                return true
            end
        end
    end
    return true
end




local function CheckQuest()
	MyLevel = game:GetService("Players").LocalPlayer.Data.Level.Value
	if World1 then
	if ((MyLevel == 1) or (MyLevel <= 9)) then
		Mon, NameQuest, LevelQuest = "Bandit", "BanditQuest1", 1
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
		if (CheckMon("Fajita") and (MyLevel >= 925)) then
		  	Mon, NameQuest, LevelQuest = "Fajita", "MarineQuest3", 3
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
		Mon, NameQuest, LevelQuest = "Horned Warrior", "IceSideQuest", 2
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
		Mon, NameQuest, LevelQuest = "Snow Lurker", "FrostQuest", 2	
	  elseif ((MyLevel == 1425) or (MyLevel <= 1449)) then
		Mon, NameQuest, LevelQuest = "Sea Soldier", "ForgottenQuest", 1
	  elseif (MyLevel >= 1450) then
		Mon, NameQuest, LevelQuest = "Water Fighter", "ForgottenQuest", 2
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
            if not TravelToSubmerged() then return end

        elseif (MyLevel >= 2625 and MyLevel <= 2649) then
            Mon, NameQuest, LevelQuest = "Coral Pirate", "SubmergedQuest1", 2
            if not TravelToSubmerged() then return end

        elseif (MyLevel >= 2650 and MyLevel <= 2674) then
            Mon, NameQuest, LevelQuest = "Sea Chanter", "SubmergedQuest2", 1
            if not TravelToSubmerged() then return end

        elseif (MyLevel >= 2675) then
            Mon, NameQuest, LevelQuest = "Ocean Prophet", "SubmergedQuest2", 2
            if not TravelToSubmerged() then return end
        end
    end
end

  function NPCPos()
    for i, v in pairs(GuideModule["Data"]["NPCList"]) do
        if v["NPCName"] == GuideModule["Data"]["LastClosestNPC"] then
            return i["CFrame"]
        end
    end
end
function GetQuest()
    local Distance = GetDistance(NPCPos())
    if Distance <= 20 then
        FireRemote("StartQuest", NameQuest, LevelQuest)
    else
        topos(NPCPos())
    end
    FireRemote("SetSpawnPoint")
end

  PlayerLevel.Changed:Connect(CheckQuest)
  task.spawn(function()
	  while task.wait(1) do
		  pcall(CheckQuest)
	  end
  end)
  CheckQuest()


  local function TouchMe(key)
	local VIM = game:GetService("VirtualInputManager")
	VIM:SendKeyEvent(true, key, false, game)
	wait()
	VIM:SendKeyEvent(false, key, false, game)
  end

  local function VerifyQuest(Name)
	local Quest = Player.PlayerGui.Main.Quest
	local Text1 = Quest.Container.QuestTitle.Title.Text:gsub("-", ""):lower()
	local Text2 = Name:gsub("-", ""):lower()
	return Quest.Visible and Text1:find(Text2)
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

  getgenv().BringMonster = true
getgenv().BringMonsterRadius = 400

local BRING_TAG = "b" .. math.random(80, 2e4) .. "t"

function _BringEnemies(toEnemy)
	if not getgenv().BringMonster then return end

	local targetRoot = toEnemy:FindFirstChild("HumanoidRootPart") or toEnemy.PrimaryPart
	local targetHumanoid = toEnemy:FindFirstChildWhichIsA("Humanoid")
	if not targetRoot or not (targetHumanoid and targetHumanoid.Health > 0) then return end

	pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)

	local targetCFrame = targetRoot.CFrame
	local name = toEnemy.Name
	local pos = Character:GetPivot().Position

	for _, mob in ipairs(Enemies:GetChildren()) do
		if mob.Name == name and not CollectionService:HasTag(mob, BRING_TAG) then
			local humanoid = mob:FindFirstChildWhichIsA("Humanoid")
			if humanoid and humanoid.Health > 0 then
				CollectionService:AddTag(mob, BRING_TAG)
				task.spawn(function()
					while mob and mob.Parent and humanoid and humanoid.Health > 0 do
						task.wait(0.2)
					end
					if mob and mob.Parent then
						CollectionService:RemoveTag(mob, BRING_TAG)
						local a = mob:FindFirstChild("MobBringAttachment")
						if a then a:Destroy() end
					end
				end)
			end
		end
	end

	for _, enemy in ipairs(CollectionService:GetTagged(BRING_TAG)) do
		if enemy.Name == name then
			local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
			if not (root and humanoid and humanoid.Health > 0) then continue end
			if (pos - root.Position).Magnitude > getgenv().BringMonsterRadius then continue end
			if root:FindFirstChild("MobBringAttachment") then continue end

			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0

			local attachment = Instance.new("Attachment")
			attachment.Name = "MobBringAttachment"
			attachment.Parent = root

			local align = Instance.new("AlignPosition")
			align.Name = "MobAlignPosition"
			align.Mode = Enum.PositionAlignmentMode.OneAttachment
			align.Position = targetCFrame.Position
			align.Responsiveness = 609
			align.MaxForce = math.huge
			align.Attachment0 = attachment
			align.Parent = attachment

			task.spawn(function()
				while enemy and enemy.Parent and humanoid and humanoid.Health > 0 do
					task.wait(1)
					if (targetCFrame.Position - root.Position).Magnitude > getgenv().BringMonsterRadius then break end
					task.wait(1)
					align.Position = targetCFrame.Position
					task.wait(1)
				end
				if attachment and attachment.Parent then attachment:Destroy() end
			end)
		end
	end
end


function GetPosMob(mobName)
	local CFrameTab = {}
	local folder = ReplicatedStorage:FindFirstChild("FortBuilderReplicatedSpawnPositionsFolder")
	if not folder then return CFrameTab end

	for _, v in pairs(folder:GetChildren()) do
		if v:IsA("Part") and v.Name == mobName then
			table.insert(CFrameTab, v.CFrame)
		end
	end

	return CFrameTab
end

local MobCycleIndex = {}
function MobsPosition(mobName)
	if type(mobName) ~= "string" then return nil end
	local SpawnPositions = GetPosMob(mobName)
	if #SpawnPositions == 0 then return nil end
	MobCycleIndex[mobName] = (MobCycleIndex[mobName] or 0) + 1
	if MobCycleIndex[mobName] > #SpawnPositions then
		MobCycleIndex[mobName] = 1
	end
	local NextPos = SpawnPositions[MobCycleIndex[mobName]]
	topos(NextPos * Pos)
	task.wait(0.5)
	local enemy = GetEnemies({ mobName })
	if enemy then return enemy end

	return nil
end

function IsNear30(partA, partB)
    if not (partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart")) then return false end
    return (partA.Position - partB.Position).Magnitude <= 35
end


AutoFarmLevel = (function()
    local QuestGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")

    while getgenv().AutoFarm do 
        CheckQuest()
        task.wait(0.1)
        local Enemie = GetEnemies({Mon})
        local NearestEnemy = GetNearestEnemy()
        local char = Player.Character or {}
        local root = char:FindFirstChild("HumanoidRootPart")

        if getgenv().FarmMode == "Quest" then
            if not VerifyQuest("Mon") and (QuestGui and not QuestGui.Visible) then
                GetQuest()
            else
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
                    MobsPosition(Mon)
                end
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
                MobsPosition(Mon)
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
                MobsPosition(Mon)
            end
        end
    end
end)



AutoFarmBones = (function()
	while getgenv().Auto_Bone do 
		task.wait()
		local Enemie = GetEnemies({"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"})
		local QuestGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
		local BoneQuestPos = CFrame.new(-9517, 172, 6078)
        local root = (Player.Character or {}).HumanoidRootPart

		if getgenv().AcceptQuests and not VerifyQuest("Demonic Soul") and (QuestGui and not QuestGui.Visible) then
			StartQuest("HauntedQuest2", 1, BoneQuestPos)
		elseif Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
			local r = Enemie.HumanoidRootPart
			local StopFlag = IsNear30(root, r)
			if not StopFlag then
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
end)

local function AutoFarmCakePrince()
    task.spawn(function()
        while getgenv().AutoFarmPrince do
            FireRemote("CakePrinceSpawner")
            task.wait(0.1)
        end
    end)
    while getgenv().AutoFarmPrince do
        task.wait()
        local CakeFarmMobs = GetEnemies({"Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter"})
        local QuestGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
        local CakeQuestPos = CFrame.new(-2021.32, 37.80, -12028.73)
        local KatakuriPos = Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position
        local root = (Player.Character or {}).HumanoidRootPart
        
        if getgenv().AcceptQuests and not VerifyQuest("Cookie Crafter") and QuestGui and not QuestGui.Visible then
            StartQuest("CakeQuest1", 1, CakeQuestPos)
        elseif not getgenv().IgnoreCakePrince and CheckMon("Cake Prince") and (KatakuriPos - Vector3.new(-2152.47, 69.98, -12399.14)).Magnitude > 500 then
            local CakePrince = GetEnemies({"Cake Prince"})
            if CakePrince and CakePrince:FindFirstChild("HumanoidRootPart") then
                if (CakePrince.HumanoidRootPart.Position - KatakuriPos).Magnitude > 500 then
                    topos(CFrame.new(-2151.82153, 149.315704, -12404.9053))
                else
                    if WorldOrigin:FindFirstChild("Ring") or WorldOrigin:FindFirstChild("MochiSwirl") or WorldOrigin:FindFirstChild("Shockwave") or WorldOrigin:FindFirstChild("Swirl") or WorldOrigin:FindFirstChild("Fist")  then
                        topos(CakePrince.HumanoidRootPart.CFrame * Vector3.new(0, -40, -20))
                    else
                        topos(CakePrince.HumanoidRootPart.CFrame * Vector3.new(0, 40, 20))
                    end
                    pcall(function()
                        EquipWeapon()
                        AutoHaki()
                    end)
                end
            end
        elseif CakeFarmMobs and CakeFarmMobs:FindFirstChild("HumanoidRootPart") then
            local root = (Player.Character or {}).HumanoidRootPart
            local r = CakeFarmMobs.HumanoidRootPart
            local StopFlag = IsNear30(root, r)

            if not StopFlag then
                topos(r.CFrame * CFrame.new(Pos))
            end

            pcall(function()
                EquipWeapon()
                AutoHaki()
                _BringEnemies(CakeFarmMobs)
            end)
        else
            topos(CFrame.new(-2134, 149, -12340))
        end
    end
end

local function AutoDoughKing()
	local CocoaStats = ""
	task.spawn(function()
		while getgenv().AutoDoughKing do task.wait()
			CocoaStats = FireRemote("SweetChaliceNpc")
			if VerifyTool("Sweet Chalice") then
				FireRemote("CakePrinceSpawner")
			end
		end
	end)
  
	while getgenv().AutoDoughKing do 
		task.wait()
		if VerifyTool("Red Key") then
			FireRemote("CakeScientist", "Check")
		elseif CheckMon("Dough King") then
			local DoughKing = GetEnemies({"Dough King"})
			if DoughKing and DoughKing:FindFirstChild("HumanoidRootPart") then
				local PlayerPos = Player.Character.HumanoidRootPart.Position
				if (DoughKing.HumanoidRootPart.Position - PlayerPos).Magnitude > 500 then
					topos(CFrame.new(-2151.82153, 149.315704, -12404.9053))
					task.wait(2)
				else
					if WorldOrigin:FindFirstChild("Ring") or WorldOrigin:FindFirstChild("MochiSwirl") or WorldOrigin:FindFirstChild("Shockwave") or WorldOrigin:FindFirstChild("Swirl") or WorldOrigin:FindFirstChild("Fist")  then
                        topos(DoughKing.HumanoidRootPart.CFrame * Vector3.new(0, -40, -20))
                    else
                        topos(DoughKing.HumanoidRootPart.CFrame * Vector3.new(0, 40, 20))
                    end
                    pcall(function()
                        EquipWeapon()
                        AutoHaki()
                    end)
				end
			end
		else
			if VerifyTool("God's Chalice") and not VerifyTool("Sweet Chalice") then
				if string.find(CocoaStats, "Where") then
					local Enemie = GetEnemies({"Chocolate Bar Battler", "Cocoa Warrior"})
					if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
						topos(Enemie.HumanoidRootPart.CFrame * Pos)
						pcall(function()
							EquipWeapon()
							AutoHaki()
							getgenv().PosMon = Enemie.HumanoidRootPart.CFrame
						end)
					else
						topos(CFrame.new(400, 81, -12257))
					end
				end
			elseif CheckMon("Urban") and not VerifyTool("God's Chalice") and not VerifyTool("Sweet Chalice")
			or CheckMon("Deandre") and not VerifyTool("God's Chalice") and not VerifyTool("Sweet Chalice")
			or CheckMon("Diablo") and not VerifyTool("God's Chalice") and not VerifyTool("Sweet Chalice") then
				local NPC = "EliteHunterVerify"
				
				if VerifyQuest("Diablo") then
					NPC = "Diablo"
				elseif VerifyQuest("Deandre") then
					NPC = "Deandre"
				elseif VerifyQuest("Urban") then
					NPC = "Urban"
				else
					task.spawn(function() FireRemote("EliteHunter") end)
				end
				
				local EliteBoss = GetEnemies({NPC})
				if EliteBoss and EliteBoss:FindFirstChild("HumanoidRootPart") then
					topos(EliteBoss.HumanoidRootPart.CFrame * Pos)
					pcall(function()
						EquipWeapon()
						AutoHaki()
					end)
				end
			else
				if not getgenv().AutoFarm and not getgenv().Auto_Bone then
					local Enemie = GetEnemies({"Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter"})
					if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
						topos(Enemie.HumanoidRootPart.CFrame * Pos)
						pcall(function()
							EquipWeapon()
							AutoHaki()
							getgenv().PosMon = Enemie.HumanoidRootPart.CFrame
						end)
					else
						topos(CFrame.new(-2103, 70, -12165))
					end
				end
			end
		end
	end
  end

  local function AutoBartiloQuest()
	local BartiloQuestLevel = 0
	task.spawn(function()
	  while getgenv().AutoBartilo do task.wait()
		BartiloQuestLevel = FireRemote("BartiloQuestProgress", "Bartilo")
		FireRemote("BartiloQuestProgress", "Bartilo")
	  end
	end)
	
	local QuestActive = Player.PlayerGui.Main.Quest
	
	while getgenv().AutoBartilo do task.wait()
	  if PlayerLevel.Value >= 850 then
		local QuestTitle = QuestActive.Container.QuestTitle.Title
		if BartiloQuestLevel == 0 then
		  
		  local Enemie = GetEnemies({"Swan Pirate"})
		  
		  if not QuestActive.Visible then
			QuestTitle.Text = ""
		  end
		  
		  if QuestActive.Visible and not string.find(QuestTitle.Text, "Swan Pirate") and not string.find(QuestTitle.Text, "50") then
			FireRemote("AbandonQuest")
		  end
		  
		  if not QuestActive.Visible and not string.find(QuestTitle.Text, "Swan Pirate") and not string.find(QuestTitle.Text, "50") then
			StartQuest1("BartiloQuest", 1)
			elseif Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
				topos(Enemie.HumanoidRootPart.CFrame * Pos)
			pcall(function()
				EquipWeapon()
				AutoHaki()
				BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
			end)
		  end
		elseif BartiloQuestLevel == 1 then
		  local Enemie1 = GetEnemies({"Jeremy"})
		  
		  if Enemie1 and Enemie1:FindFirstChild("HumanoidRootPart") then
			topos(Enemie1.HumanoidRootPart.CFrame * Pos)
			pcall(function()
				EquipWeapon()
				AutoHaki()
				BringMob(Enemie1.Name, Enemie1.HumanoidRootPart.CFrame)
			end)
		  else
			topos(CFrame.new(2316, 449, 787))
		  end
		
		elseif BartiloQuestLevel == 2 then
		  local Plates = game:GetService("Workspace").Map.Dressrosa:FindFirstChild("BartiloPlates")
		  if Plates and Plates:FindFirstChild("Plate1") and Plates.Plate1.Color.G ~= 1 then
			topos(Plates.Plate1.CFrame)
		  elseif Plates and Plates:FindFirstChild("Plate2") and Plates.Plate2.Color.G ~= 1 then
			topos(Plates.Plate2.CFrame)
		  elseif Plates and Plates:FindFirstChild("Plate3") and Plates.Plate3.Color.G ~= 1 then
			topos(Plates.Plate3.CFrame)
		  elseif Plates and Plates:FindFirstChild("Plate4") and Plates.Plate4.Color.G ~= 1 then
			topos(Plates.Plate4.CFrame)
		  elseif Plates and Plates:FindFirstChild("Plate5") and Plates.Plate5.Color.G ~= 1 then
			topos(Plates.Plate5.CFrame)
		  elseif Plates and Plates:FindFirstChild("Plate6") and Plates.Plate6.Color.G ~= 1 then
			topos(Plates.Plate6.CFrame)
		  elseif Plates and Plates:FindFirstChild("Plate7") and Plates.Plate7.Color.G ~= 1 then
			topos(Plates.Plate7.CFrame)
		  elseif Plates and Plates:FindFirstChild("Plate8") and Plates.Plate8.Color.G ~= 1 then
			topos(Plates.Plate8.CFrame)
		  end
		end
	  end
	end
  end

local function AutoChestTween()
	while getgenv().AutoChestSafe do
		task.wait()
		local Position = (Player.Character or Player.CharacterAdded:Wait()).PrimaryPart.Position
		local Chests = CollectionService:GetTagged("_ChestTagged")
		local Nearest, MinDistance = nil, math.huge
		for _, Chest in ipairs(Chests) do
			if not Chest:GetAttribute("IsDisabled") then
				local Magnitude = (Chest:GetPivot().Position - Position).Magnitude
				if Magnitude < MinDistance then
					MinDistance, Nearest = Magnitude, Chest
				end
			end
		end
		local plrChar = Player and Player.Character and Player.Character.PrimaryPart
		if Nearest and plrChar then
			topos(Nearest:GetPivot())
		end
	end
end

AutoBerries = function()
		local char = Character
		local charPos = char and char:GetPivot().Position or nil
		local berry = nil

		while getgenv().AutoBerrySafe do
			task.wait(0.5)
			if char then
				if CurrentTargetBush then
					for _, part in ipairs(CurrentTargetBush:GetChildren()) do
						if part:IsA("BasePart") then
							for name, val in pairs(part:GetAttributes()) do
								if name:sub(1, 12) == "_BerryCFrame" then
									berry = val
								end
							end
						end
					end
					if not berry then CurrentTargetBush = nil end
				end
				if not CurrentTargetBush then
					local closest, closedist = nil, math.huge
					for _, bush in ipairs(CollectionService:GetTagged("BerryBush")) do
						for name, val in pairs(bush:GetAttributes()) do
							if name:sub(1, 12) == "_BerryCFrame" then
								local pos = bush.Parent:GetPivot().Position + Vector3.new(0, 2, 0)
								local dist = (charPos - pos).Magnitude
								if dist < closedist then
									closest = bush.Parent
									berry = val
									closedist = dist
								end
							end
						end
					end

					if closest then
						CurrentTargetBush = closest
						topos(CFrame.new(closest:GetPivot().Position + Vector3.new(0, 2, 0)))
						task.wait(0.3)
						local berries = closest:FindFirstChild("Berries")
						if berries then
							for _, model in ipairs(berries:GetChildren()) do
								if model:IsA("Model") then
									local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
									if part then
										topos(part.CFrame)
										task.wait(0.3)
									end
								end
							end
						end
					end
				end
				if berry and typeof(berry) == "CFrame" then
					if (charPos - berry.Position).Magnitude > 20 then
						topos(berry)
						task.wait(0.1)
					end
				end

				for _, bush in ipairs(CollectionService:GetTagged("BerryBushStreamed")) do
					for name, _ in pairs(bush:GetAttributes()) do
						if name:sub(1, 12) == "_BerryCFrame" then
							while bush:GetAttribute(name) and _ENV.AutoBerrySafe do
								ReplicatedStorage.Modules.Net["RF/ClaimBerry"]:InvokeServer(bush.Parent.Name, name)
								task.wait(0)
							end
						end
					end
				end
			end
		end
	end

local function AutoQuestBlaze()
	local TargetEnemy = nil
    spawn(function()
        pcall(function()
            while getgenv().AutoQuestBlaze do
                local args = {[1] = {Context = "Check"}}
                local QuestData = game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/DragonHunter"):InvokeServer(unpack(args))
                if typeof(QuestData) == "table" and next(QuestData) ~= nil then
                    for _, Quest in pairs(QuestData) do
                        if Quest == "Defeat 3 Venomous Assailants on Hydra Island." then
                            TargetEnemy = "Venomous Assailant"
                        elseif Quest == "Defeat 3 Hydra Enforcers on Hydra Island." then
                            TargetEnemy = "Hydra Enforcer"
                        elseif Quest == "Destroy 10 trees on Hydra Island." then
                            TargetEnemy = "Tree"
                        end
                    end
                else
                    topos(CFrame.new(5814.42724609375, 1208.3267822265625, 884.5785522460938))
                    spawn(function()
                        pcall(function()
                            while getgenv().AutoQuestBlaze do
                                local RequestQuest = {[1] = {Context = "RequestQuest"}}
                                game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/DragonHunter"):InvokeServer(unpack(RequestQuest))
                                local CheckQuest = {[1] = {Context = "Check"}}
                                game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/DragonHunter"):InvokeServer(unpack(CheckQuest))
                                wait()
                             end
                        end)
                    end)
                end
                wait()
            end
        end)
    end)

    while getgenv().AutoQuestBlaze do
        task.wait()
        for i, v in pairs(game:GetService("Workspace"):GetChildren()) do
            if v.Name == 'EmberTemplate' then
                topos(v.Part.CFrame)
            end
        end
        if TargetEnemy == "Tree" then
            task.spawn(function()
                local function PressKey(key)
                    local input = game:GetService("VirtualInputManager")
                    input:SendKeyEvent(true, key, false, game)
                    input:SendKeyEvent(false, key, false, game)
                end
                local function UseTool(ToolType)
                    local player = game.Players.LocalPlayer
                    local backpack = player.Backpack
                    for _, tool in pairs(backpack:GetChildren()) do
                        if (tool:IsA("Tool") and (tool.ToolTip == ToolType)) then
                            tool.Parent = player.Character
                            for _, key in ipairs({"Z", "X", "C", "V", "F"}) do task.wait()
                                pcall(function()
                                    PressKey(key)
                                end)
                            end
                            tool.Parent = backpack
                            break
                        end
                    end
                end
                local TreeLocations = {
                    CFrame.new(5288.61962890625, 1005.4000244140625, 392.43011474609375),
                    CFrame.new(5343.39453125, 1004.1998901367188, 361.0687561035156),
                    CFrame.new(5235.78564453125, 1004.1998901367188, 431.4530944824219),
                    CFrame.new(5321.30615234375, 1004.1998901367188, 440.8951416015625),
                    CFrame.new(5258.96484375, 1004.1998901367188, 345.5052490234375)
                }
                while getgenv().AutoQuestBlaze do
                    AutoHaki()
                    for _, TreePos in ipairs(TreeLocations) do
                        topos(TreePos)
                        wait()
                        local character = game.Players.LocalPlayer.Character
                        if (character and character:FindFirstChild("HumanoidRootPart")) then
                            local distance = (character.HumanoidRootPart.Position - TreePos.Position).Magnitude
                            if (distance <= 1) then
                                UseTool("Melee")
                                UseTool("Sword")
                                UseTool("Gun")
                            end
                        end
                    end
                end
            end)
        else
            local Target = nil
            for _, npc in pairs(Enemies:GetChildren()) do
                if npc.Name == TargetEnemy then
                    local npcHealth = npc:FindFirstChild("Humanoid")
                    if npcHealth and npcHealth.Health > 0 then
                        Target = npc
                    end
                end
            end
            if Target and Target:FindFirstChild("HumanoidRootPart") then
                topos(Target.HumanoidRootPart.CFrame * Pos)
                pcall(function()
                    AutoHaki()
                    EquipWeapon()
                    BringMob(Target.Name, Target.HumanoidRootPart.CFrame)
                end)
            end
        end
    end
end

task.spawn(function()
    game:GetService("RunService").RenderStepped:Connect(function()
        pcall(function()
            if getgenv().AutoQuestBlaze then
                for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Notifications:GetChildren()) do
                    if v.Name == "NotificationTemplate" then
                        if string.find(v.Text,"Skill locked!") then
                            v:Destroy()
                        end
                    end
                end
            end
        end)
    end)
end)




  local function AutoPirateRaid()
	while getgenv().AutoPirateRaid do task.wait()
		local Enemie = nil
		for _,npc in pairs(Enemies:GetChildren()) do
		  if npc.Name ~= "rip_indra True Form" then
			local npcH = npc:FindFirstChild("Humanoid")
			if npcH and npcH.Health > 0 then
			  if npc and npc.PrimaryPart and (npc.PrimaryPart.Position - Vector3.new(-5556, 314, -2988)).Magnitude < 700 then
				Enemie = npc
			  end
			end
		  end
		end
		
		if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
		  topos(Enemie.HumanoidRootPart.CFrame * Pos)
		  pcall(function()
			AutoHaki()
			EquipWeapon()
			BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
		end)
		else
			topos(CFrame.new(-5556, 314, -2988))
		end
	  end
	end


  
local function AutoUnlockSaber()
	local RichSonProgress = 0
	local SickManProgress = 0
	
	task.spawn(function()
	  while getgenv().Auto_Saber do task.wait()
		RichSonProgress = FireRemote("ProQuestProgress","RichSon")
		SickManProgress = FireRemote("ProQuestProgress", "SickMan")
	  end
	end)
	while getgenv().Auto_Saber do task.wait()
	  if PlayerLevel.Value > 200 then
		local plrChar = Player and Player.Character
		local plrBag = Player.Backpack
		local plrRP = plrChar:FindFirstChild("HumanoidRootPart")
		local Plates = game:GetService("Workspace").Map.Jungle.QuestPlates
		if not workspace.Map.Jungle.Final.Part.CanCollide then
		  local Enemie = GetEnemies({"Saber Expert"})
		  if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
			topos(Enemie.HumanoidRootPart.CFrame * Pos)
			EquipWeapon()
			pcall(function()
				AutoHaki()
			end)
		  else
			topos(CFrame.new(-1461, 30, -51))
		  end
		  
		elseif plrChar and VerifyTool("Relic") then
			topos(CFrame.new(-1408, 30, 3))
			EquipToolName("Relic")
		elseif SickManProgress == 1 and RichSonProgress == 0 and not workspace.Map.Desert.Burn.Part.CanCollide then
		  local Enemie = GetEnemies({"Mob Leader"})
		  if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
			topos(Enemie.HumanoidRootPart.CFrame * Pos)
			EquipWeapon()
			pcall(function()
				AutoHaki()
			end)
		  end
		elseif plrChar:FindFirstChild("Cup") and not plrChar["Cup"].Handle:FindFirstChild("TouchInterest") then
		  FireRemote("ProQuestProgress", "SickMan")
		elseif plrChar:FindFirstChild("Cup") and plrChar["Cup"].Handle:FindFirstChild("TouchInterest") then
			topos(CFrame.new(1393, 37, -1324, -0.408640295, 0, -0.912695527, 0, 1, 0, 0.912695527, 0, -0.408640295))
		elseif plrBag:FindFirstChild("Cup") then
			EquipToolName("Cup")
		elseif not workspace.Map.Desert.Burn.Part.CanCollide then
			topos(workspace.Map.Desert.Cup.CFrame)
		elseif plrChar:FindFirstChild("Torch") then
			topos(CFrame.new(1113, 5, 4352))
		elseif plrBag:FindFirstChild("Torch") then
			EquipToolName("Torch")
		elseif Plates:FindFirstChild("Door") and Plates.Door.CanCollide then
		  if Plates then
			local Plate1 = Plates:FindFirstChild("Plate1")
			local Plate2 = Plates:FindFirstChild("Plate2")
			local Plate3 = Plates:FindFirstChild("Plate3")
			local Plate4 = Plates:FindFirstChild("Plate4")
			local Plate5 = Plates:FindFirstChild("Plate5")
			if Plate1 and Plate1:FindFirstChild("Button") and Plate1.Button.BrickColor ~= BrickColor.new("Camo") then
				topos(Plate1.Button.CFrame)
			elseif Plate2 and Plate2:FindFirstChild("Button") and Plate2.Button.BrickColor ~= BrickColor.new("Camo") then
				topos(Plate2.Button.CFrame)
			elseif Plate3 and Plate3:FindFirstChild("Button") and Plate3.Button.BrickColor ~= BrickColor.new("Camo") then
				topos(Plate3.Button.CFrame)
			elseif Plate4 and Plate4:FindFirstChild("Button") and Plate4.Button.BrickColor ~= BrickColor.new("Camo") then
				topos(Plate4.Button.CFrame)
			elseif Plate5 and Plate5:FindFirstChild("Button") and Plate5.Button.BrickColor ~= BrickColor.new("Camo") then
				topos(Plate5.Button.CFrame)
			end
		  end
		elseif plrRP and Plates:FindFirstChild("Door") and not Plates.Door.CanCollide then
			topos(workspace.Map.Jungle.Torch.CFrame)
		end
	  end
	end
  end

  local function AutoDarkbeard()
	while getgenv().AutoDarkCoat and World2 do task.wait()
	  local Darkbeard = GetEnemies({"Darkbeard"})
	  if Darkbeard and Darkbeard:FindFirstChild("HumanoidRootPart") then
		topos(Darkbeard.HumanoidRootPart.CFrame * Pos)
		pcall(function()
			AutoHaki()
			EquipWeapon()
		end)
	  elseif VerifyTool("Fist of Darkness") then
		topos(workspace.Map.DarkbeardArena.Summoner.Detection.CFrame)
	  else
		topos(CFrame.new(3746, 13, -3632))
	  end
	end
  end

  local AutoWhiteBelt = function()
    local DojoQuestNpc = CFrame.new(5855.19629, 1208.32178, 872.713501, 0.606994748, -1.81058823e-09, -0.794705868, 5.72712722e-09, 1, 2.09605577e-09, 0.794705868, -5.82367621e-09, 0.606994748)
    
    task.spawn(function()
        while getgenv().AutoWhiteBelt do
            pcall(function()
                if (DojoQuestNpc.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5 then
                    local ClaimArgs = {
                        ["NPC"] = "Dojo Trainer",
                        ["Command"] = "ClaimQuest"
                    }
                    game:GetService("ReplicatedStorage").Modules.Net["RF/InteractDragonQuest"]:InvokeServer(ClaimArgs)
                    wait(1)
                    local RequestArgs = {
                        ["NPC"] = "Dojo Trainer",
                        ["Command"] = "RequestQuest"
                    }
                    game:GetService("ReplicatedStorage").Modules.Net["RF/InteractDragonQuest"]:InvokeServer(RequestArgs)
                end
            end)
            task.wait(1)
        end
    end)

    while getgenv().AutoWhiteBelt do
        task.wait()
        local table = GetEnemies({"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"})
        if table and table:FindFirstChild("HumanoidRootPart") then
            topos(table.HumanoidRootPart.CFrame * Pos)
            pcall(function()
                EquipWeapon()
                AutoHaki()
                BringMob(table.Name, table.HumanoidRootPart.CFrame)
            end)
        else
            topos(CFrame.new(-9506, 172, 6117))
        end
    end
end


local AutoPurpleBelt = function()
    task.spawn(function()
        while getgenv().AutoPurpleBelt do
            pcall(function()
                game:GetService("ReplicatedStorage").Modules.Net["RF/InteractDragonQuest"]:InvokeServer({
                    ["NPC"] = "Dojo Trainer",
                    ["Command"] = "RequestQuest"
                })
            end)
            task.wait(1)
        end
    end)
    while getgenv().AutoPurpleBelt do
        task.wait()
		local Elites = "EliteHunter"
		if VerifyQuest("Diablo") then
			Elites = "Diablo"
		elseif VerifyQuest("Deandre") then
			Elites = "Deandre"
		elseif VerifyQuest("Urban") then
			Elites = "Urban"
		else
			task.spawn(function()
				FireRemote("EliteHunter")
			end)
		end
        local enemy = GetEnemies({Elites})
        if enemy and enemy:FindFirstChild("HumanoidRootPart") then
            topos(enemy.HumanoidRootPart.CFrame * Pos)
             pcall(function()
                EquipWeapon()
                AutoHaki()
                BringMob(enemy.Name, enemy.HumanoidRootPart.CFrame)
            end)
        else
			topos(CFrame.new(-5119, 315, -2964))
        end
    end
end


local function AutoCursedCaptain()
	while getgenv().AutoCursedCaptain do task.wait()
		local Enemie = GetEnemies({"Cursed Captain"})
		if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
		  topos(Enemie.HumanoidRootPart.CFrame * Pos)
			pcall(function()EquipWeapon()AutoHaki()end)
		else
		  topos(CFrame.new(912, 186, 33591))
		end
	  end
  end

local function GetButton()
	local Summoner = workspace.Map["Boat Castle"].Summoner
	local Circle = Summoner:FindFirstChild("Circle")
	if Circle then
	  for _,part in pairs(Circle:GetChildren()) do
		if part and part.Name == "Part" and part:FindFirstChild("Part") and part.Part.BrickColor ~= BrickColor.new("Lime green") then
		  return part.Part
		end
	  end
	end
  end

  local function AutoKillRipIndra()
	while getgenv().AutoDarkDagger do task.wait()
		local Enemie = GetEnemies({"rip_indra True Form"})
		if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
		  topos(Enemie.HumanoidRootPart.CFrame * Pos)
		  pcall(function()AutoHaki()EquipWeapon()end)
		elseif VerifyTool("God's Chalice") then
			EquipToolName("God's Chalice")
		  topos(CFrame.new(-5561, 314, -2663))
		else
		  topos(CFrame.new(-5333, 424, -2673))
		end
	  end
  end

local AutoTrainGear = (function()
	task.spawn(function()
	  while getgenv().AutoTrain do task.wait()
		if Player.Character and WaitChilds(Player.Character, "RaceEnergy") and WaitChilds(Player.Character, "RaceTransformed") then
		  if Player.Character.RaceEnergy.Value >= 1 and not Player.Character.RaceTransformed.Value then
			  Player.Backpack.Awakening.RemoteFunction:InvokeServer({[1] = true})
		  end
	  end
	end
	end)
	
	while getgenv().AutoTrain do task.wait()
	  if getgenv().TrainMethod == "Bones" then
		local Enemie = GetEnemies({"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"})
		if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
		  topos(Enemie.HumanoidRootPart.CFrame * Pos)
		   pcall(function()
				EquipWeapon()
				AutoHaki()
				BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
		  	end)
		  else
			topos(CFrame.new(-9506, 172, 6117))
		  end
		elseif getgenv().TrainMethod == "Cakes" then
			local Enemie = GetEnemies({"Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter"})
			if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
			  topos(Enemie.HumanoidRootPart.CFrame * Pos)
			   pcall(function()
					EquipWeapon()
						AutoHaki()
						BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
			  		end)
				else
				topos(CFrame.new(-2134, 149, -12340))
			end
		end
	end
end)

	local function AutoFarmMusketeerHat()
		local QuestActive = Player.PlayerGui.Main.Quest
		
		local BossProgress = false
		local BanditProgress = false
		local QuestProgress = 0
		
		task.spawn(function()
		  while getgenv().AutoMusketeerHat do task.wait()
			BossProgress = FireRemote("CitizenQuestProgress").KilledBoss
			BanditProgress = FireRemote("CitizenQuestProgress").KilledBandits
			QuestProgress = FireRemote("CitizenQuestProgress", "Citizen")
		  end
		end)
		
		while getgenv().AutoMusketeerHat do task.wait()
		  local plrLevel = PlayerLevel.Value
		  local QuestTitle = QuestActive.Container.QuestTitle.Title
		  
		  if plrLevel < 1800 then
		  elseif not BanditProgress then
			local Enemie = GetEnemies({"Forest Pirate"})
			
			if not QuestActive.Visible then
			  QuestTitle.Text = ""
			end
			
			if QuestActive.Visible and not string.find(QuestTitle.Text, "Forest Pirate") and not string.find(QuestTitle.Text, "50") then
			  FireRemote("AbandonQuest")
			end
			
			if not QuestActive.Visible and not string.find(QuestTitle.Text, "Forest Pirate") and not string.find(QuestTitle.Text, "50") then
			  StartQuest1("CitizenQuest", 1)
			  FireRemote("CitizenQuestProgress", "Citizen")
			elseif Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
			  topos(Enemie.HumanoidRootPart.CFrame * Pos)
			  pcall(function()
				AutoHaki()
				EquipWeapon()
				BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
			end)
			end
		  elseif not BossProgress then
			local CursedCaptain = GetEnemies({"Captain Elephant"})
			
			if not QuestActive.Visible then
			  QuestTitle.Text = ""
			end
			
			if QuestActive.Visible and not string.find(QuestTitle.Text, "Captain Elephant") then
			  FireRemote("AbandonQuest")
			end
			
			if not QuestActive.Visible and not string.find(QuestTitle.Text, "Captain Elephant") then
			  FireRemote("CitizenQuestProgress", "Citizen")
			elseif CursedCaptain and CursedCaptain:FindFirstChild("HumanoidRootPart") then
			  topos(CursedCaptain.HumanoidRootPart.CFrame * Pos)
			  pcall(function()
				AutoHaki()
				EquipWeapon()
				BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
			end)
			else
			  topos(CFrame.new(-13393, 319, -8423))
			end
		  elseif QuestProgress == 2 then
			topos(CFrame.new(-12512, 340, -9872))
		  end
		end
	  end

  local function AutoLawRaid()
	task.spawn(function()
		while getgenv().AutoLawRaid do
			task.wait()
			if not CheckMon("Order") and not VerifyTool("Microchip") then
				FireRemote("BlackbeardReward", "Microchip", "2")
			end
		end
	end)
	task.spawn(function()
		while getgenv().AutoLawRaid do
			task.wait()
			if not CheckMon("Order") and VerifyTool("Microchip") then
				pcall(function()
					fireclickdetector(workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
				end)
			end
		end
	end)
	while getgenv().AutoLawRaid do task.wait()
		if CheckMon("Order") then
		local OrderBoss = GetEnemies({"Order"})
		if OrderBoss and OrderBoss:FindFirstChild("HumanoidRootPart") then
			topos(OrderBoss.HumanoidRootPart.CFrame * Pos)
			pcall(function()AutoHaki()EquipWeapon()end)
		else
			topos(CFrame.new(-6300, 16, -4997))
		end
	end
	end
  end

	local function AutoObservation()
		task.spawn(function()
			while getgenv().AutoObservation do task.wait(0.1)
				pcall(function()
					if game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui["ImageLabel"] then
						game:GetService("VirtualUser"):CaptureController()
					game:GetService("VirtualUser"):SetKeyDown("0x65")
					wait(2)
					game:GetService("VirtualUser"):SetKeyUp("0x65")
					end
				end)
			end
		end)
	  
		local function HandleEnemies(eName, dPos)
			local enemy = GetEnemies({eName})
			if enemy then
				if Player.PlayerGui.ScreenGui:FindFirstChild("ImageLabel") then
					repeat
						task.wait(0.1)
						topos(enemy.HumanoidRootPart.CFrame * CFrame.new(3, 0, 0))
					until not getgenv().AutoObservation or not Player.PlayerGui.ScreenGui:FindFirstChild("ImageLabel")
				else
					repeat
						task.wait(0.1)
						topos(enemy.HumanoidRootPart.CFrame * CFrame.new(0, 50, 10))
						if not Player.PlayerGui.ScreenGui:FindFirstChild("ImageLabel") and getgenv().StartObsHop then
							game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
						end
					until not getgenv().AutoObservation or Player.PlayerGui.ScreenGui:FindFirstChild("ImageLabel")
				end
			else
				topos(dPos)
			end
		end
	  
		while getgenv().AutoObservation do
			task.wait(0.1)
			if Player:FindFirstChild("VisionRadius") and Player.VisionRadius.Value < 5000 then
				if World1 then
					HandleEnemies("Galley Captain", CFrame.new(5533, 88, 4852))
				elseif World2 then
					HandleEnemies("Lava Pirate", CFrame.new(-5478, 16, -5247))
				elseif World3 then
					HandleEnemies("Venomous Assailant", CFrame.new(4731.27197265625, 1090.177978515625, 1078.1712646484375))
				end
			else
				Notification:SendNotification("Warning", "Max Vision", 5)
			end
		end
	  end

	  local function AutoTaskEliteHunter()
		while getgenv().AutoEliteHunter do
			task.wait()
			local NPC = "EliteHunter"
			if VerifyQuest("Diablo") then
				NPC = "Diablo"
			elseif VerifyQuest("Deandre") then
				NPC = "Deandre"
			elseif VerifyQuest("Urban") then
				NPC = "Urban"
			else
				task.spawn(function()
					FireRemote("EliteHunter")
				end)
			end
			local EliteBoss = GetEnemies({NPC})
			if EliteBoss and EliteBoss:FindFirstChild("HumanoidRootPart") then
				topos(EliteBoss.HumanoidRootPart.CFrame * Pos)
				pcall(function()
					EquipWeapon()
					AutoHaki()
				end)
			elseif not CheckMon("Deandre") and not CheckMon("Diablo") and not CheckMon("Urban") then
				topos(CFrame.new(-5119, 315, -2964))
			end
		end
	  end

	  
local function AutoFactory()
	while getgenv().AutoFactory do task.wait()
	  topos(CFrame.new(410, 200, -414))
	  	pcall(function()
		AutoHaki()
		EquipWeapon()
		end)
	end
  end

	  local function AutoTaskRenguko()
		while getgenv().AutoRenguko do task.wait()
			if VerifyTool("Hidden Key") then
				EquipToolName("Hidden Key")
				topos(CFrame.new(6571, 299, -6968))
			elseif VerifyTool("Library Key") then
				EquipToolName("Library Key")
				topos(CFrame.new(6373, 293, -6839))
			elseif CheckMon("Awakened Ice Admiral") then
				local AwakenedIceAdmiral = GetEnemies({"Awakened Ice Admiral"})
				if AwakenedIceAdmiral and AwakenedIceAdmiral:FindFirstChild("HumanoidRootPart") then
					topos(AwakenedIceAdmiral.HumanoidRootPart.CFrame * Pos)
					pcall(function()
						AutoHaki()
						EquipWeapon()
					end)
				end
			else
				local Enemie = GetEnemies({"Arctic Warrior", "Snow Lurker"})
				if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
					topos(Enemie.HumanoidRootPart.CFrame * Pos)
					pcall(function()
						AutoHaki()
						EquipWeapon()
						BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
					end)
				else
					topos(CFrame.new(5707, 28, -6402))
				end
			end
		end
	  end

	  local function AutoSoulReaper()
		while getgenv().AutoFarmBossHallow do task.wait()
			local SoulReaper = GetEnemies({"Soul Reaper"})
			if SoulReaper and SoulReaper:FindFirstChild("HumanoidRootPart") then
			  topos(SoulReaper.HumanoidRootPart.CFrame * Pos)
			  pcall(function()
				AutoHaki()
				EquipWeapon()
			end)
			elseif VerifyTool("Hallow Essence") then
				EquipToolName("Hallow Essence")
			  	pcall(function()
					topos(workspace.Map["Haunted Castle"].Summoner.Detection.CFrame)
				end)
			else
			  topos(CFrame.new(-9529, 316, 6712))
			end
		  end
	  end

	  local function TrainDummy()
		while getgenv().DummyTraining do task.wait()
			local Enemie = GetEnemies({"Training Dummy"})
			local QuestGui = Player.PlayerGui:FindFirstChild("Main") and Player.PlayerGui.Main:FindFirstChild("Quest")
	  
			if not VerifyQuest("Training Dummy") and not QuestGui.Visible then
				FireRemote("ArenaTrainer")
			end
			if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
				topos(Enemie.HumanoidRootPart.CFrame * Pos)
				pcall(function()
					EquipWeapon()
					AutoHaki()
					BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
				end)
			else
				topos(CFrame.new(3758, 92, 254))
			end
		end
	  end

	  function round(num)
		return math.floor(num + 0.5)
	end
	
	function PlayerESP()
		for _, player in pairs(game:GetService('Players'):GetChildren()) do
			pcall(function()
				if player == game.Players.LocalPlayer then return end
	
				local character = player.Character
				if not character or not character:FindFirstChild("Head") or not character:FindFirstChild("Humanoid") then return end
				
				local head = character.Head
				local BillboardName = 'NameEsp' .. player.UserId
	
				if getgenv().ESPPlayer then
					local BillboardGui = head:FindFirstChild(BillboardName)
					if not BillboardGui then
						BillboardGui = Instance.new('BillboardGui', head)
						BillboardGui.Name = BillboardName
						BillboardGui.ExtentsOffset = Vector3.new(0, 3, 0)
						BillboardGui.Size = UDim2.new(1, 200, 1, 40)
						BillboardGui.AlwaysOnTop = true
						local NameLabel = Instance.new('TextLabel', BillboardGui)
						NameLabel.Font = Enum.Font.SourceSansBold
						NameLabel.TextSize = 16
						NameLabel.TextWrapped = true
						NameLabel.Size = UDim2.new(1, 0, 1, 0)
						NameLabel.TextYAlignment = Enum.TextYAlignment.Top
						NameLabel.BackgroundTransparency = 1
						NameLabel.TextStrokeTransparency = 0.3
					end
	
					local NameLabel = BillboardGui.TextLabel
					local Distance = round((game.Players.LocalPlayer.Character.Head.Position - head.Position).Magnitude / 3)
					local Health = round(character.Humanoid.Health)
					local MaxHealth = round(character.Humanoid.MaxHealth)
	
					NameLabel.Text = string.format('[ %s | %d Studs ]\n[ Health: %d/%d ]', player.Name, Distance, Health, MaxHealth)
					NameLabel.TextColor3 = (player.Team == game.Players.LocalPlayer.Team) and Color3.fromRGB(3, 255, 158) or Color3.fromRGB(255, 0, 0)
				elseif head:FindFirstChild(BillboardName) then
					head[BillboardName]:Destroy()
				end
			end)
		end
	end
	

	local function AutoStartRaceV2()
		task.spawn(function()
			local QuestProgress = 0
			task.spawn(function()
				while getgenv().AutoEvoRaceV2 do
					task.wait(0.1)
					QuestProgress = FireRemote("Alchemist", "1")
				end
			end)
	  
			while getgenv().AutoEvoRaceV2 do task.wait()
				if not Player.Data.Race:FindFirstChild("Evolved") then
					if QuestProgress == 0 then
						local PlrChar = Player and Player.Character and Player.Character.PrimaryPart
						if PlrChar and (PlrChar.Position - Vector3.new(-2777, 73, -3570)).Magnitude <= 4 then
							FireRemote("Alchemist", "2")
						else
							topos(CFrame.new(-2777, 73, -3570))
						end
					elseif QuestProgress == 1 then
						local playerBag = Player:FindFirstChild("Backpack")
						local playerChar = Player.Character
						if not playerBag:FindFirstChild("Flower 1") and not playerChar:FindFirstChild("Flower 1") then
							topos(workspace:FindFirstChild("Flower1").CFrame)
						elseif not playerBag:FindFirstChild("Flower 2") and not playerChar:FindFirstChild("Flower 2") then
							topos(workspace:FindFirstChild("Flower2").CFrame)
						elseif not playerBag:FindFirstChild("Flower 3") and not playerChar:FindFirstChild("Flower 3") then
							local Enemie = GetEnemies({"Swan Pirate"})
							if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
								topos(Enemie.HumanoidRootPart.CFrame * Pos)
								pcall(function()
									AutoHaki()
									EquipWeapon()
									BringMob(Enemie.Name, Enemie.HumanoidRootPart.CFrame)
								end)
							else
								topos(CFrame.new(1069, 138, 1322))
							end
						end
					elseif QuestProgress == 2 then
						local PlrChar = Player and Player.Character and Player.Character.PrimaryPart
						if PlrChar and (PlrChar.Position - Vector3.new(-2777, 73, -3570)).Magnitude <= 4 then
							FireRemote("Alchemist", "3")
						else
							topos(CFrame.new(-2777, 73, -3570))
						end
					end
				end
			end
		end)
    end
	  
    local function GetHeadshotImage(userId)
	return string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", userId)
end

local function AddESP(Part, ESPColor, GetTextFunc, GetImageFunc)
	if not Part or Part:FindFirstChild("ESP_QuantumONYX") then return end

	local Folder = Instance.new("Folder", Part)
	Folder.Name = "ESP_QuantumONYX"

	local BHA = Instance.new("BoxHandleAdornment", Folder)
	BHA.Name = "Box"
	BHA.Adornee = Part
	BHA.Size = Part.Size
	BHA.AlwaysOnTop = true
	BHA.ZIndex = 10
	BHA.Transparency = 0.7
	BHA.Color3 = ESPColor or Color3.new(1, 1, 0)

	local BBG = Instance.new("BillboardGui", Folder)
	BBG.Adornee = Part
	BBG.Size = UDim2.new(0, 200, 0, 50)
	BBG.StudsOffset = Vector3.new(0, 3, 0)
	BBG.AlwaysOnTop = true

	local Icon = Instance.new("ImageLabel", BBG)
	Icon.BackgroundTransparency = 1
	Icon.Size = UDim2.new(0, 36, 0, 36)
	Icon.Position = UDim2.new(0, 0, 0.5, -18)
	Icon.Image = "rbxassetid://0"

	local TL = Instance.new("TextLabel", BBG)
	TL.BackgroundTransparency = 1
	TL.Size = UDim2.new(1, -40, 1, 0)
	TL.Position = UDim2.new(0, 40, 0, 0)
	TL.TextSize = 14
	TL.Font = Enum.Font.SourceSansBold
	TL.TextStrokeTransparency = 0.3
	TL.TextColor3 = ESPColor or Color3.new(1, 1, 1)
	TL.TextYAlignment = Enum.TextYAlignment.Center
	TL.TextWrapped = true
	TL.RichText = true

	task.spawn(function()
		while task.wait(0.1) do
			if not TL or not TL.Parent or not Part or not Part.Parent then break end
			pcall(function()
				if GetTextFunc then
					TL.Text = GetTextFunc()
				end
				if GetImageFunc then
					Icon.Image = GetImageFunc()
				end
			end)
		end
	end)
end

PlayerESP = (function()
	for _, player in pairs(game:GetService("Players"):GetPlayers()) do
		task.spawn(function()
			pcall(function()
				if player == game.Players.LocalPlayer then return end
				if not (player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid")) then return end

				local head = player.Character.Head
				local existing = head:FindFirstChild("ESP_QuantumONYX")

				if getgenv().ESPPlayer then
					if not existing then
						local isAlly = player.Team == game.Players.LocalPlayer.Team
						local espColor = isAlly and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 60, 60)
						local teamRelation = isAlly and "Ally" or "Enemy"

						AddESP(head, espColor, function()
							local lpChar = game.Players.LocalPlayer.Character
							local lpHead = lpChar and lpChar:FindFirstChild("Head")
							if not lpHead then return "" end

							local dist = math.floor((lpHead.Position - head.Position).Magnitude / 3)
							local hp = math.floor(player.Character.Humanoid.Health)
							local maxHp = math.floor(player.Character.Humanoid.MaxHealth)

							return string.format("[ %s | %d Studs | %s ]\n[ HP: %d / %d ]", player.Name, dist, teamRelation, hp, maxHp)
						end, function()
							return GetHeadshotImage(player.UserId)
						end)
					end
				elseif existing then
					existing:Destroy()
				end
			end)
		end)
	end
end)



IslandESP = (function()
	local character = game.Players.LocalPlayer.Character
	if not (character and character:FindFirstChild("Head")) then return end

	for _, island in ipairs(game.Workspace["_WorldOrigin"].Locations:GetChildren()) do
		task.spawn(function()
			pcall(function()
				if getgenv().ESPIsland and island:IsA("BasePart") and island.Name ~= "Sea" then
					if not island:FindFirstChild("ESP_QuantumONYX") then
						AddESP(island, Color3.fromRGB(173, 216, 230), function()
							local head = character:FindFirstChild("Head")
							if not head then return "" end

							local dist = math.floor((head.Position - island.Position).Magnitude)
							return string.format(
								"<font color='rgb(255,255,255)'>[</font> <font color='rgb(173,216,230)'>%s</font> <font color='rgb(255,255,255)'>]</font>\n<font color='rgb(255,255,255)'>[</font> <font color='rgb(0,0,139)'>%d studs</font> <font color='rgb(255,255,255)'>]</font>",
								island.Name, dist
							)
						end)
					end
				elseif island:FindFirstChild("ESP_QuantumONYX") then
					island:FindFirstChild("ESP_QuantumONYX"):Destroy()
				end
			end)
		end)
	end
end)


FruitESP = (function()
	local character = game.Players.LocalPlayer.Character
	if not (character and character:FindFirstChild("Head")) then return end

	for _, fruit in ipairs(game.Workspace:GetChildren()) do
		task.spawn(function()
			pcall(function()
				if getgenv().DevilFruitESP and fruit:FindFirstChild("Handle") and string.find(fruit.Name, "Fruit") then
					local handle = fruit.Handle
					if not handle:FindFirstChild("ESP_QuantumONYX") then
						AddESP(handle, Color3.fromRGB(144, 238, 144), function()
							local head = character:FindFirstChild("Head")
							if not head then return "" end

							local dist = math.floor((head.Position - handle.Position).Magnitude)
							return string.format(
								"<font color='rgb(255,255,255)'>[</font> <font color='rgb(144,238,144)'>%s</font> <font color='rgb(255,255,255)'>]</font>\n" ..
								"<font color='rgb(255,255,255)'>[</font> <font color='rgb(135,206,250)'>%d studs</font> <font color='rgb(255,255,255)'>]</font>",
								fruit.Name, dist
							)
						end)
					end
				elseif fruit:FindFirstChild("Handle") and fruit.Handle:FindFirstChild("ESP_QuantumONYX") then
					fruit.Handle:FindFirstChild("ESP_QuantumONYX"):Destroy()
				end
			end)
		end)
	end
end)


ChestESP = (function()
	local character = game.Players.LocalPlayer.Character
	if not (character and character:FindFirstChild("Head")) then return end

	for _, chest in ipairs(workspace:WaitForChild("ChestModels"):GetChildren()) do
		task.spawn(function()
			pcall(function()
				local root = chest:FindFirstChild("RootPart")
				if not root then return end

				if getgenv().ESPChest and string.find(chest.Name, "Chest") then
					if not root:FindFirstChild("ESP_QuantumONYX") then
						local n = chest.Name:lower()
						local color, iconId, displayName = Color3.fromRGB(255, 255, 255), "rbxassetid://0", "Chest"

						if n:find("silver") then
							color = Color3.fromRGB(192, 192, 192)
							iconId = "rbxassetid://97335861533611"
							displayName = "Silver Chest"
						elseif n:find("gold") then
							color = Color3.fromRGB(255, 215, 0)
							iconId = "rbxassetid://103232045481498"
							displayName = "Gold Chest"
						elseif n:find("diamond") then
							color = Color3.fromRGB(185, 242, 255)
							iconId = "rbxassetid://127242907265007"
							displayName = "Diamond Chest"
						end

						AddESP(root, color, function()
							local head = character:FindFirstChild("Head")
							if not head then return "" end
							local dist = math.floor((head.Position - root.Position).Magnitude)
							return string.format("<font color='rgb(%d,%d,%d)'>[ %s ]</font> <font color='rgb(169,169,169)'> %dm </font>", 
								color.R * 255, color.G * 255, color.B * 255, displayName, dist)
						end, function()
							return iconId
						end)
					end
				elseif root:FindFirstChild("ESP_QuantumONYX") then
					root.ESP_QuantumONYX:Destroy()
				end
			end)
		end)
	end
end)



BerriesESP = (function()
    local character = game.Players.LocalPlayer.Character
    if not (character and character:FindFirstChild("Head")) then return end

    local BerryBushes = CollectionService:GetTagged("BerryBush")
    for _, Bush in pairs(BerryBushes) do
        pcall(function()
            local parent = Bush.Parent
            if not parent then return end
            local attributes = Bush:GetAttributes()
            local HasBerry, BerryName = false, nil

            for _, Value in pairs(attributes) do
                if type(Value) == "string" and Value ~= "" then
                    HasBerry = true
                    BerryName = Value
                    break
                end
            end

            if getgenv().ESPBerry and HasBerry and BerryName then
                local gui = parent:FindFirstChild("BerryESP")
                if not gui then
                    gui = Instance.new("BillboardGui", parent)
                    gui.Name = "BerryESP"
                    gui.ExtentsOffset = Vector3.new(0, 2, 0)
                    gui.Size = UDim2.new(0, 200, 0, 40)
                    gui.Adornee = parent
                    gui.AlwaysOnTop = true

                    local frame = Instance.new("Frame", gui)
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 1, 0)

                    local icon = Instance.new("ImageLabel", frame)
                    icon.Name = "Icon"
                    icon.Size = UDim2.new(0, 24, 0, 24)
                    icon.Position = UDim2.new(0, 0, 0.5, -12)
                    icon.BackgroundTransparency = 1

                    local label = Instance.new("TextLabel", frame)
                    label.Name = "TextLabel"
                    label.Font = Enum.Font.SourceSansBold
                    label.TextSize = 16
                    label.Position = UDim2.new(0, 28, 0, 0)
                    label.Size = UDim2.new(1, -28, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    label.TextStrokeTransparency = 0.4
                    label.RichText = true
                end

                local label = gui.Frame:FindFirstChild("TextLabel")
                local icon = gui.Frame:FindFirstChild("Icon")
                if not (label and icon) then return end

                local LowerBerry = string.lower(BerryName)
                local BerryColor, IconId = "#FFFFFF", "rbxassetid://116786303832385"

                if string.find(LowerBerry, "^blue") then
                    BerryColor, IconId = "#0000FF", "rbxassetid://73501117648043"
                elseif string.find(LowerBerry, "^green") then
                    BerryColor, IconId = "#00FF00", "rbxassetid://138243952981617"
                elseif string.find(LowerBerry, "^orange") then
                    BerryColor, IconId = "#FFA500", "rbxassetid://91314674725185"
                elseif string.find(LowerBerry, "^pink") then
                    BerryColor, IconId = "#FFC0CB", "rbxassetid://91208172679559"
                elseif string.find(LowerBerry, "^purple") then
                    BerryColor, IconId = "#800080", "rbxassetid://85279887599288"
                elseif string.find(LowerBerry, "^red") then
                    BerryColor, IconId = "#FF0000", "rbxassetid://132185274190500"
                elseif string.find(LowerBerry, "^white") then
                    BerryColor, IconId = "#FFFFFF", "rbxassetid://116786303832385"
                elseif string.find(LowerBerry, "^yellow") then
                    BerryColor, IconId = "#FFFF00", "rbxassetid://81188836618030"
                end

                icon.Image = IconId
                local distance = math.floor((character.Head.Position - parent:GetPivot().Position).Magnitude)
                label.Text = string.format("<font color='#FFFFFF'>[</font> <font color='%s'>%s</font> <font color='#FFFFFF'>]</font> %dm", BerryColor, BerryName, distance)
            elseif parent:FindFirstChild("BerryESP") then
                parent.BerryESP:Destroy()
            end
        end)
    end
end)


local Window = Library:CreateWindow({
    Title = "Quantum Onyx",
    Subtitle = "Blox Fruit",
    Version = "v1.03",
    Theme = "Purple"
})

local Tab = {
	Home = Window:AddTab('Home', 'home-quantum'),
	Sub = Window:AddTab('Sub Farm', 'swords-quantum'),
	Sevent = Window:AddTab('Sea Event', 'ship-quantum'),
	Player = Window:AddTab('Player', 'user-quantum'),
	Dragon = Window:AddTab('Dragon Update', 'visual-quantum'),
	Raid = Window:AddTab('Dungeon', 'raid-quantum'),
	Trial = Window:AddTab('Trials', 'rabbit-quantum'),
    Travel = Window:AddTab('Travel', 'map-quantum'),
	Shop = Window:AddTab('Tiktok Shop', 'cart-quantum'),
	Misc = Window:AddTab('Misc', 'misc-quantum'),
}

local Sevent_Left = Tab.Sevent:addSection()
local Mirage = Sevent_Left:addMenu("Mirage Event")
Mirage:addToggle("Teleport to Mirage", false, function(Value)
	getgenv().AutoMirageIsland = Value
	task.spawn(function()
		while getgenv().AutoMirageIsland do task.wait()
			for _, location in pairs(game:GetService("Workspace")._WorldOrigin.Locations:GetChildren()) do
				if location.Name == "Mirage Island" then
					topos(location.CFrame * CFrame.new(0, 333, 0))
				end
			end
		end
	end)
	if not Value then StopTween() return end
end)
Mirage:addToggle("Teleport to Highest Point", false, function(Value)
	if not Value then StopTween() return end
end)


local Kitsune = Sevent_Left:addMenu("Kitsune Event")
Kitsune:addToggle("Teleport to Shrine", false, function(Value)
	getgenv().TeleportKitsune = Value
	task.spawn(function()
		while getgenv().TeleportKitsune do task.wait()
		local Map = workspace:WaitForChild("Map", 9e9)
			if Map:FindFirstChild("KitsuneIsland") then
				topos(Map.KitsuneIsland.ShrineActive.NeonShrinePart.CFrame * CFrame.new(0,0,10))
			end
		end
	end)
	if not Value then StopTween() return end
end)

Kitsune:addToggle("Auto Collect Azure Embers", false, function(Value)
	getgenv().CollectAzure = Value
	task.spawn(function()
		while getgenv().CollectAzure do task.wait()
			for i,v in pairs(workspace:GetChildren()) do
				if v.Name == 'EmberTemplate' then
					topos(v.Part.CFrame)
				end
			end
		end
	end)
	if not Value then StopTween() return end
end)

Kitsune:addSlider("Select Amount of Azure", 10, 25, 20, function(Value)
	getgenv().SetToTradeAureEmber = Value
end)

Kitsune:addToggle("Auto Trade Azure", false, function(Value)
	getgenv().TradeAzureEmber = Value
	task.spawn(function()
		while getgenv().TradeAzureEmber do task.wait()
			local AzureAvailable = CheckMaterial("Azure Ember")
			if AzureAvailable >= getgenv().SetToTradeAureEmber then
				game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/KitsuneStatuePray"):InvokeServer()
				FireRemote("KitsuneStatuePray")
			end
		end
	end)
end)

local Sevent_Right = Tab.Sevent:addSection()
local SeaFarm = Sevent_Right:addMenu("Sea Farm")

SeaFarm:addDropdown("Select Boat", 3, { 'Dinghy', 'PirateSloop', 'PirateBrigade', 'PirateGrandBrigade', 'MarineSloop', 'MarineBrigade', 'MarineGrandBrigade' }, function(Value)
	getgenv().BoatSelected = Value
end)

SeaFarm:addToggle("Auto Find Prehistoric Island", false, function(Value)
	getgenv().AutoFindPrehistoricIsland = Value
end)

function CheckSeaLevel()
    if getgenv().SeaLevelSelected == 'Level 1' then
        SeaCFrame = CFrame.new(-21998.375, 30.0006084, -682.309143, 0.120013528, 0.00690158736, 0.99274826, -0.0574118942, 0.998350561, -2.36509201e-10, -0.991110802, -0.0569955558, 0.120211802)
    elseif getgenv().SeaLevelSelected == 'Level 2' then
        SeaCFrame = CFrame.new(-26779.5215, 30.0005474, -822.858032, 0.307457417, 0.019647358, 0.951358974, -0.0637726262, 0.997964442, -4.15334017e-10, -0.949422479, -0.0606706589, 0.308084518)
    elseif getgenv().SeaLevelSelected == 'Level 3' then
        SeaCFrame = CFrame.new(-31171.957, 30.0001011, -2256.93774, 0.37637493, 0.0150483791, 0.926345229, -0.0399504974, 0.999201655, 2.70896673e-11, -0.925605655, -0.0370079502, 0.376675636)
    elseif getgenv().SeaLevelSelected == 'Level 4' then
        SeaCFrame = CFrame.new(-34054.6875, 30.2187767, -2560.12012, 0.0935864747, -0.00122954219, 0.995610416, 0.0624034069, 0.998040259, -0.00463332096, -0.993653536, 0.062563099, 0.0934797972)
    elseif getgenv().SeaLevelSelected == 'Level 5' then
        SeaCFrame = CFrame.new(-38887.5547, 30.0004578, -2162.99023, -0.188895494, -0.00704088295, 0.981971979, -0.0372481011, 0.999306023, -1.39882339e-09, -0.981290519, -0.0365765914, -0.189026669)
    elseif getgenv().SeaLevelSelected == 'Level 6' then
        SeaCFrame = CFrame.new(-44541.7617, 30.0003204, -1244.8584, -0.0844199061, -0.00553312758, 0.9964149, -0.0654025897, 0.997858942, 2.02319411e-10, -0.99428153, -0.0651681125, -0.0846010372)
    end
end

SeaFarm:addSlider("Float Distance", 30, 70, 40, function(Value)
	getgenv().SetFloatDistance = Value
end)
SeaFarm:addSlider("Boat Speed", 100, 350, 250, function(Value)
	getgenv().SetBoatSpeed = Value
end)

SeaFarm:addDropdown("Select Zone", 6, { 'Level 1', 'Level 2', 'Level 3', 'Level 4', 'Level 5', 'Level 6' }, function(Value)
	getgenv().SeaLevelSelected = Value
end)

SeaFarm:addToggle("Auto Sail", false, function(Value)
	getgenv().AutoSail = Value
	if not getgenv().AutoSail then StopTween() StopBoatsTween() return end
	local isBuyingBoat = false
	spawn(function()
		while task.wait() do
			if getgenv().AutoSail then
				pcall(function()
					CheckSeaLevel()
					local workspace = game:GetService("Workspace")
					local players = game:GetService("Players")
					local player = players.LocalPlayer
					local character = player.Character
					local humanoid = character:WaitForChild("Humanoid")
					local boat = workspace.Boats:FindFirstChild(getgenv().BoatSelected)
	
					if boat and boat:FindFirstChild("Owner") and boat.Owner.Value.Name == player.Name then
						if not humanoid.Sit then
							topos(boat.VehicleSeat.CFrame * CFrame.new(0, 1, 0))
						else
							StartBoatTween(boat)
						end
					else
						humanoid.Sit = false
						if not boat and not isBuyingBoat then
							HandleBoatPurchase()
						end
					end
				end)
			end
		end
	end)
	
	function HandleBoatPurchase()
		if isBuyingBoat then return end
		isBuyingBoat = true
	
		local player = game.Players.LocalPlayer
		local character = player.Character
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local targetPos = CFrame.new(-16927, 9, 434)
		topos(targetPos)
		if (targetPos.Position - humanoidRootPart.Position).Magnitude <= 10 then
			local args = {
				[1] = "BuyBoat",
				[2] = getgenv().BoatSelected
			}
			FireRemote(unpack(args))
			wait(2)
			local newBoat
			local waitTime = 0
			repeat
				newBoat = game:GetService("Workspace").Boats:FindFirstChild(getgenv().BoatSelected)
				wait(0.5)
				waitTime = waitTime + 0.5
			until newBoat or waitTime >= 3
			if newBoat and newBoat:FindFirstChild("Owner") and newBoat.Owner.Value.Name == player.Name then
				topos(newBoat.VehicleSeat.CFrame * CFrame.new(0, 1, 0))
				wait(0.3)
				StartBoatTween(newBoat)
			end
		end
		isBuyingBoat = false
	end
	
	function StartBoatTween(boat)
		local worldOrigin = game:GetService("Workspace")._WorldOrigin.Locations
		local targetLocation
		if getgenv().AutoFindPrehistoricIsland and worldOrigin:FindFirstChild("Prehistoric Island") then
			targetLocation = worldOrigin["Prehistoric Island"].CFrame * CFrame.new(0, getgenv().SetFloatDistance, 0)
		else
			targetLocation = SeaCFrame * CFrame.new(0, getgenv().SetFloatDistance, 0)
		end
		PlayBoatsTween(targetLocation)
	end
end)

 
local Home_Left = Tab.Home:addSection()
local Home = Home_Left:addMenu("Main Farm")

Home:addDropdown("Weapon", 1, { "Melee", "Sword", "Blox Fruit" },function(Value)
    getgenv().SelectWeapon = Value
end)

Home:addDropdown("Farm Method", 1, { "Quest", "No Quest", "Nearest" },function(Value)
	getgenv().FarmMode = Value
end)

Home:addToggle("Auto Farm", false, function(Value)
	getgenv().AutoFarm = Value;AutoFarmLevel()
	if not Value then StopTween() return end
end)

Home:addToggle("Teleport to Submerged", false, function(state)
    getgenv().AutoSubmerged = state
    if not state then StopTween() return end
        task.spawn(function()
            while getgenv().AutoSubmerged do task.wait()

                local lp = game.Players.LocalPlayer
                local char = lp.Character or lp.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")

                local npc = workspace:FindFirstChild("NPCs"):FindFirstChild("Submarine Worker")
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    topos(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5))
                    task.wait(1)
                    local Net = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
                    pcall(function()
                        Net:RemoteFunction("SubmarineWorkerSpeak"):InvokeServer("TravelToSubmergedIsland")
                    end)
                    getgenv().AutoSubmerged = false
                end
            end
        end)
end)


Home:addToggle("Auto Bones", false, function(Value)
	getgenv().Auto_Bone = Value
        if Value then
            task.spawn(function()
               AutoFarmBones()
            end)
        else
            task.spawn(function()
                StopTween()
            end)
        end
    end, nil, nil, {
        multiopt = true,
        list = {"Take Quest", "Auto Random Surprise"},
        callbacks = {
        function(optState) getgenv().AcceptQuests = optState end,
		function(optState2) 
			getgenv().Auto_Random_Surprise = optState2
		    while getgenv().Auto_Random_Surprise do task.wait()
				FireRemote("Bones", "Buy", 1, 1)
			end
		end
    }
})

Home:addToggle("Auto Pray", false, function(Value)
	getgenv().AutoPray = Value
	while getgenv().AutoPray do task.wait()
		FireRemote("gravestoneEvent", 1)
	end
end)

Home:addToggle("Auto Try Luck", false, function(Value)
	getgenv().AutoTryLuck = Value
	while getgenv().AutoTryLuck do task.wait()
		FireRemote("gravestoneEvent", 2)
	end
end)


local CakeInfo = Home:addLabel("Cake Status", "Scanning for Information...")

task.spawn(function()
	while task.wait(1) do
		if CheckMon("Dough King") then
			CakeInfo:RefreshDesc("Cake Stats: Spawned | Dough King")
		elseif CheckMon("Cake Prince") then
			CakeInfo:RefreshDesc("Cake Stats: Spawned | Cake Prince")
		else
			local EnemiesCake = FireRemote("CakePrinceSpawner", true)
			local count = 0
			if type(EnemiesCake) == "table" then
				count = EnemiesCake.Enemies or 0
			elseif type(EnemiesCake) == "string" then
				local match = string.match(EnemiesCake, "%d+")
				count = tonumber(match) or 0
			elseif type(EnemiesCake) == "number" then
				count = EnemiesCake
			end
			CakeInfo:RefreshDesc("Cake Stats: " .. count .. "/500")
		end
	end
end)


Home:addToggle("Auto Katakuri", false, function(Value)
	getgenv().AutoFarmPrince = Value
        if Value then
            task.spawn(function()
               AutoFarmCakePrince()
            end)
        else
            task.spawn(function()
                StopTween()
            end)
        end
    end, nil, nil, {
        multiopt = true,
        list = {"Take Quest", "Ignore Boss"},
        callbacks = {
        function(optState) getgenv().AcceptQuests = optState end,
		function(optState2) 
			getgenv().IgnoreCakePrince = optState2
		end
    }
})

Home:addToggle("Auto Dough King", false, function(Value)
    getgenv().AutoDoughKing = Value
	AutoDoughKing()
	if not Value then StopTween() return end
end)

local MaterialLists = {
	World1 = { "Leather + Scrap Metal", "Angel Wings", "Magma Ore", "Fish Tail" },
	World2 = { "Leather + Scrap Metal", "Radioactive Material", "Ectoplasm", "Mystic Droplet", "Magma Ore", "Vampire Fang" },
	World3 = { "Leather + Scrap Metal", "Demonic Wisp", "Conjured Cocoa", "Dragon Scale", "Gunpowder", "Fish Tail", "Mini Tusk" }
  }
  local MaterialList = World1 and MaterialLists.World1 or World2 and MaterialLists.World2 or World3 and MaterialLists.World3

Home:addDropdown("Select Material", 1, MaterialList ,function(Value)
	getgenv().SelectMaterial = Value
end)

Home:addToggle("Auto Farm Material", false, function(Value)
	getgenv().AutoMaterial = Value
	if not Value then StopTween() return end
	task.spawn(function()
		local function GetMaterialData()
			if World1 then
				if getgenv().SelectMaterial == "Angel Wings" then
					return {
						Monsters = { "Shanda", "Royal Squad", "Royal Soldier", "Wysper", "Thunder God" },
						Position = CFrame.new(-4698, 845, -1912)
					}
				elseif getgenv().SelectMaterial == "Leather + Scrap Metal" then
					return {
						Monsters = { "Brute", "Pirate" },
						Position = CFrame.new(-1145, 15, 4350)
					}
				elseif getgenv().SelectMaterial == "Magma Ore" then
					return {
						Monsters = { "Military Soldier", "Military Spy", "Magma Admiral" },
						Position = CFrame.new(-5815, 84, 8820)
					}
				elseif getgenv().SelectMaterial == "Fish Tail" then
					return {
						Monsters = { "Fishman Warrior", "Fishman Commando", "Fishman Lord" },
						Position = {CFrame.new(61423, 18, 1536), CFrame.new(61686, 18, 1608), CFrame.new(60940, 18, 1596)}
					}
				end
			elseif World2 then
				if getgenv().SelectMaterial == "Leather + Scrap Metal" then
					return {
						Monsters = { "Marine Captain" },
						Position = CFrame.new(-2011, 73, -3327)
					}
				elseif getgenv().SelectMaterial == "Magma Ore" then
					return {
						Monsters = { "Magma Ninja", "Lava Pirate" },
						Position = CFrame.new(-5428, 78, -5959)
					}
				elseif getgenv().SelectMaterial == "Ectoplasm" then
					return {
						Monsters = { "Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer" },
						Position = CFrame.new(911, 126, 33160)
					}
				elseif getgenv().SelectMaterial == "Mystic Droplet" then
					return {
						Monsters = { "Water Fighter" },
						Position = CFrame.new(-3385, 239, -10542)
					}
				elseif getgenv().SelectMaterial == "Radioactive Material" then
					return {
						Monsters = { "Factory Staff" },
						Position = CFrame.new(295, 73, -56)
					}
				elseif getgenv().SelectMaterial == "Vampire Fang" then
					return {
						Monsters = { "Vampire" },
						Position = CFrame.new(-6033, 7, -1317)
					}
				end
			elseif World3 then
				if getgenv().SelectMaterial == "Leather + Scrap Metal" then
					return {
						Monsters = { "Jungle Pirate" },
						Position = CFrame.new(-11976, 332, -10620)
					}
				elseif getgenv().SelectMaterial == "Demonic Wisp" then
					return {
						Monsters = { "Demonic Soul" },
						Position = CFrame.new(-9506, 172, 6159)
					}
				elseif getgenv().SelectMaterial == "Fish Tail" then
					return {
						Monsters = { "Fishman Raider", "Fishman Captain" },
						Position = CFrame.new(-10993, 332, -8940)
					}
				elseif getgenv().SelectMaterial == "Conjured Cocoa" then
					return {
						Monsters = { "Chocolate Bar Battler", "Cocoa Warrior" },
						Position = CFrame.new(621, 79, -12581)
					}
				elseif getgenv().SelectMaterial == "Dragon Scale" then
					return {
						Monsters = { "Dragon Crew Archer" },
						Position = CFrame.new(6594, 383, 139)
					}
				elseif getgenv().SelectMaterial == "Gunpowder" then
					return {
						Monsters = { "Pistol Billionaire" },
						Position = CFrame.new(-469, 74, 5904)
					}
				elseif getgenv().SelectMaterial == "Mini Tusk" then
					return {
						Monsters = { "Mythological Pirate" },
						Position = CFrame.new(-13545, 470, -6917)
					}
				end
			end
			return nil
		end
        while getgenv().AutoMaterial do task.wait()
            local MaterialData = GetMaterialData()
            local Monsters, Position = MaterialData.Monsters, MaterialData.Position
            local Enemy = GetEnemies(Monsters)

            if Enemy and Enemy:FindFirstChild("HumanoidRootPart") then
                local root = (Player.Character or {}).HumanoidRootPart
                local r = Enemy.HumanoidRootPart
                local StopFlag = IsNear30(root, r)
                if not StopFlag then
                    topos(r.CFrame * Pos)
                end
                pcall(function()
                    EquipWeapon()
                    AutoHaki()
                    _BringEnemies(Enemy)
                end)
             else
                if typeof(Position) == "table" then
                    for _, cf in ipairs(Position) do
                        topos(cf)
                        task.wait(1)
                    end
                else
                    topos(Position)
                end
            end
        end
	end)
end)

local Chest = Home_Left:addMenu("Chest Farm")

Chest:addToggle("Start Farming Chest", false, function(Value)
	getgenv().AutoChestSafe = Value
	if Value then
		task.spawn(function()
		 	AutoChestTween()
		end)
	else
		task.spawn(function()
		 	StopTween()
		end)
	end
end, nil, nil,{
	multiopt = true,
	list = {"Stop If Items"},
	callbacks = {
		function(state) 
			getgenv().StopChest = state
			task.spawn(function()
				while getgenv().StopChest do
					task.wait()
					if VerifyTool("God's Chalice") or VerifyTool("Fist of Darkness") then
						getgenv().AutoChestSafe = false
					end
				end
			end)
		end
	}
})


local Player_Left = Tab.Player:addSection()
local Stats = Player_Left:addMenu("Stats")

	if Player and Player:FindFirstChild("Data") then
		local stats, points = Player.Data.Stats, Player.Data.Points
		local PlayerStat = Stats:addLabel("Player Status", "Scanning for Information...")
		local StatNames = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }

		local function UpdateStats()
			if not stats then return end
			pcall(function()
				local statInfo = { "Points Available: " .. points.Value }
				for _, name in ipairs(StatNames) do
					local level = stats:FindFirstChild(name) and stats[name]:FindFirstChild("Level") and
						stats[name].Level.Value or 0
					table.insert(statInfo, name .. ": " .. level)
				end
				PlayerStat:RefreshDesc(table.concat(statInfo, "\n"))
			end)
		end

		task.spawn(function()
			while task.wait(0.3) do UpdateStats() end
		end)
	end
local function AutoStats()
    local function AddStats(statName)
        local MaxPoints = Player.Data.Points.Value
        if MaxPoints >= 1 and PointsSlider and PointsSlider > 0 then
            local PointsToAdd = math.clamp(PointsSlider, 1, MaxPoints)
            FireRemote("AddPoint", statName, PointsToAdd)
        end
    end

    while getgenv().AutoStats do task.wait(0.3)
        if Melee then AddStats("Melee") end
        if Defense then AddStats("Defense") end
        if Sword then AddStats("Sword") end
        if Gun then AddStats("Gun") end
        if DemonFruit then AddStats("Demon Fruit") end
    end
end

	Stats:addSlider("Select Points", 0, 1000, 10, function(Value)
		PointsSlider = Value
	end)

	Stats:addToggle("Melee", false, function(Value)
		Melee = Value
	end)

	Stats:addToggle("Defense", false, function(Value)
		Defense = Value
	end)

	Stats:addToggle("Sword", false, function(Value)
		Sword = Value
	end)

	Stats:addToggle("Gun", false, function(Value)
		Gun = Value
	end)

	Stats:addToggle("Devil Fruit", false, function(Value)
		DemonFruit = Value
	end)

	Stats:addToggle("Start Adding Stats", false, function(Value)
		getgenv().AutoStats = Value
		if getgenv().AutoStats then
			AutoStats()
		end
	end)

local Player_Right = Tab.Player:addSection()
local LocalPlayer = Player_Right:addMenu("Local Player")


LocalPlayer:addToggle("Players ESP", false, function(Value)
	getgenv().ESPPlayer = Value; PlayerESP()
end)

LocalPlayer:addToggle("Islands ESP", false, function(Value)
	getgenv().ESPIsland = Value; IslandESP()
end)

LocalPlayer:addToggle("Fruits ESP", false, function(Value)
	getgenv().DevilFruitESP = Value; FruitESP()
end)

LocalPlayer:addToggle("Chests ESP", false, function(Value)
	getgenv().ESPChest = Value; ChestESP()
end)

LocalPlayer:addToggle("Berries ESP", false, function(Value)
	getgenv().ESPBerry = Value; BerriesESP()
end)


task.spawn(function()
	while wait() do
		if getgenv().ESPPlayer then
			PlayerESP()
		elseif getgenv().ESPIsland then
			IslandESP()
		elseif getgenv().DevilFruitESP then
			FruitESP()
		elseif getgenv().ESPChest then
			ChestESP()
		elseif getgenv().ESPBerry then
			BerriesESP()
		end
	end
end)


local Home_Right = Tab.Home:addSection()
local FarmSet = Home_Right:addMenu("Farm Settings")

FarmSet:addSlider("Tweening Speed", 10, 300, 250, function(Value)
	getgenv().TweenSpeed = tonumber(Value)
end)

FarmSet:addSlider("Tween Skip Distance", 50, 200, 150, function(Value)
	getgenv().TweenSkip = tonumber(Value)
end)

FarmSet:addDropdown("Farm Distance", 2, { "20", "30" },function(Value)
	PosY = tonumber(Value)
end)

FarmSet:addSlider("Bring Radius", 150, 600, 350, function(Value)
	getgenv().BringMonsterRadius = Value
end)

FarmSet:addToggle("Start Bring", true, function(Value)
	getgenv().BringMonster = Value
end)

function FastAttack()
		local Debounce = 0
		local ComboDebounce = 0
		local M1Combo = 0
		local HitboxLimbs = { "RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand" }

		local SUCCESS_FLAGS, COMBAT_REMOTE_THREAD = pcall(function()
			return rawget(require(Modules.Flags), "COMBAT_REMOTE_THREAD") or false
		end)

        local HIT_FUNCTION; task.defer(function()
			local PlayerScripts = Player:WaitForChild("PlayerScripts")
			local LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")
			
			while not LocalScript do
				Player.PlayerScripts.ChildAdded:Wait()
				LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")
			end
			
			if getsenv then
				local Success, ScriptEnv = pcall(getsenv, LocalScript)
				
				if Success and ScriptEnv then
					HIT_FUNCTION = rawget(ScriptEnv._G, "SendHitsToServer")
				end
			end
		end)

		local function ExpandsHitBox(Enemies)
			for i = 1, #Enemies do
				Enemies[i][2].Size = Vector3.one * 50
				Enemies[i][2].Transparency = 1
			end
		end

		local function GetCombo()
			local timeSinceLast = tick() - ComboDebounce
			local Combo = (timeSinceLast <= 0.5) and M1Combo or 0
			Combo = (Combo >= 4) and 1 or Combo + 1
			ComboDebounce = tick()
			M1Combo = Combo
			return Combo
		end

		local function GetAllHits(Character)
			local BladeHits = {}
			local Closest = nil
			local ClosestDist = math.huge
			local Pos = Character:GetPivot().Position
			local PrimaryBladeHit = nil

			local function AddHit(Hitbox, Target)
				if PrimaryBladeHit then
					table.insert(BladeHits, { Target, Hitbox })
				else
					PrimaryBladeHit = Hitbox
				end
			end
			local function Scan(List)
				for _, Target in ipairs(List:GetChildren()) do
					local Humanoid = Target:FindFirstChildWhichIsA("Humanoid")
					if Target ~= Player.Character and Humanoid and Humanoid.Health > 0 then
						for _, LimbName in ipairs(HitboxLimbs) do
							local Part = Target:FindFirstChild(LimbName) or Target.PrimaryPart
							if Part and (Part.Position - Pos).Magnitude <= 50 then
								AddHit(Part, Target)
								local dist = (Part.Position - Pos).Magnitude
								if dist < ClosestDist then
									Closest = Part
									ClosestDist = dist
								end
							end
						end
					end
				end
			end
			Scan(Enemies)
			Scan(Characters)
			return BladeHits, Closest, PrimaryBladeHit
		end


		local function UseNormalClick(Humanoid, Character, Cooldown)
			if not Humanoid or not Character or not Cooldown then return end

			local Hits, Hitbox = GetAllHits(Character)
			if not Hitbox or type(Hits) ~= "table" or #Hits == 0 then return end
			if SUCCESS_FLAGS then
				RE_RegisterAttack:FireServer(Cooldown)
				if COMBAT_REMOTE_THREAD and HIT_FUNCTION then
					HIT_FUNCTION(Hitbox, Hits)
				else
					RE_RegisterHit:FireServer(Hitbox, Hits)
				end
			else
				table.insert(BladeHits, { Enemy, EnemyHitBox })
				ExpandsHitBox(BladeHits)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(0.05)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
			end
			return Humanoid
		end

		local function UseFruitM1(Character, Equipped, Combo)
			local Pos = Character:GetPivot().Position
			for _, Enemy in ipairs(Enemies:GetChildren()) do
				local Humanoid = Enemy:FindFirstChildWhichIsA("Humanoid")
				local Root = Enemy.PrimaryPart
				if Humanoid and Humanoid.Health > 0 and Root and (Root.Position - Pos).Magnitude <= 50 then
					local Dir = (Root.Position - Pos).Unit
					Equipped.LeftClickRemote:FireServer(Dir, Combo)
				end
			end
		end

		task.spawn(function()
			while getgenv().AutoAttack do
				local Character = Player.Character
				local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
				if Character and Humanoid and Humanoid.Health > 0 then
					local Tool = Character:FindFirstChildOfClass("Tool")
					local ToolTip = Tool and Tool.ToolTip
					local ToolName = Tool and Tool.Name

					if Tool and table.find({ "Gun", "Melee", "Blox Fruit", "Sword" }, ToolTip) then
						local Cooldown = math.min(Tool:FindFirstChild("Cooldown") and Tool.Cooldown.Value or 0, 0.05)

						if (tick() - Debounce) >= Cooldown then
							local function CheckStun()
								local Stun = Character:FindFirstChild("Stun")
								local Busy = Character:FindFirstChild("Busy")
								if Humanoid.Sit then return false end
								if (Stun and Stun.Value == true) or (Busy and Busy.Value == true) then return false end
								return true
							end

							if CheckStun() then
								local Combo = GetCombo()
								Cooldown = Cooldown + ((Combo >= 4) and 0.05 or 0)
								Debounce = (Combo >= 4 and ToolTip ~= "Gun") and tick() or tick()

								if ToolTip == "Blox Fruit" then
									if ToolName == "Ice-Ice" or ToolName == "Light-Light" then
										UseNormalClick(Humanoid, Character, Cooldown)
									elseif Tool:FindFirstChild("LeftClickRemote") then
										UseFruitM1(Character, Tool, Combo)
									end
								else
									UseNormalClick(Humanoid, Character, Cooldown)
								end
							end
						end
					end
				end
				task.wait(0.05)
			end
		end)
	end


FarmSet:addToggle("Fast Attack", true, function(Value)
    getgenv().AutoAttack = Value
     FastAttack()
end)

FarmSet:addToggle("Disable Damage Counter", true, function(Value)
	ReplicatedStorage.Assets.GUI.DamageCounter.Enabled = not Value
end)

FarmSet:addToggle("Disable Notifications", false, function(Value)
	Player.PlayerGui.Notifications.Enabled = not Value
end)

FarmSet:addToggle("Walk in Water", true, function(Value)
	getgenv().Water = Value
	task.spawn(function()
		local Map = workspace:WaitForChild("Map", 9e9)
		while getgenv().Water do task.wait(0.1)
		  Map:WaitForChild("WaterBase-Plane", 9e9).Size = Vector3.new(1000, 113, 1000)
		end
		Map:WaitForChild("WaterBase-Plane", 9e9).Size = Vector3.new(1000, 80, 1000)
	end)
end)

FarmSet:addToggle("Auto Hop When Admin Joined", true, function(Value)
	getgenv().HopWhenAdmin = Value
	task.spawn(function()
		while getgenv().HopWhenAdmin do task.wait()
			for _, v in pairs(game.Players:GetPlayers()) do
				local AdminList = {
					"red_game43", "rip_indra", "Axiore", "Polkster",
					"wenlocktoad", "Daigrock", "toilamvidamme",
					"oofficialnoobie", "Uzoth", "Azarth", "arlthmetic",
					"Death_King", "Lunoven", "TheGreateAced", "rip_fud",
					"drip_mama", "layandikit12", "Hingoi"
				}
				if table.find(AdminList, v.Name) then
				  		game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
					break
				end
			end
		end
	end)
end)

FarmSet:addToggle("Anti Afk", true, function(Value)
    getgenv().AntiAFK = Value
    local GC = getconnections or get_signal_cons

    if Value then
        if GC then
            for _, v in pairs(GC(Players.LocalPlayer.Idled)) do
                if v.Disable then v:Disable() elseif v.Disconnect then v:Disconnect() end
            end
        else
            local VirtualUser = game:GetService("VirtualUser")
            Players.LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    elseif GC then
        for _, v in pairs(GC(Players.LocalPlayer.Idled)) do
            if v.Disable then v:Disable() elseif v.Disconnect then v:Disconnect() end
        end
    end
end)


local Sub_Left = Tab.Sub:addSection()
local QuestFarm = Sub_Left:addMenu("Quest Farming")

QuestFarm:addToggle("Complete Saber Quest", false, function(Value)
	getgenv().Auto_Saber = Value
	AutoUnlockSaber()
	if not Value then StopTween() return end
end)

QuestFarm:addToggle("Complete Tushita Quest", false, function(Value)
	getgenv().AutoTushitaQuest = Value
	if not Value then StopTween() return end
	task.spawn(function()
		local Map = workspace:WaitForChild("Map", 9e9)
		local Turtle = Map:WaitForChild("Turtle", 9e9)
		local QuestTorches = Turtle:WaitForChild("QuestTorches", 9e9)
		
		local Active1 = false
		local Active2 = false
		local Active3 = false
		local Active4 = false
		local Active5 = false
		
		while getgenv().AutoTushitaQuest do task.wait()
		  if not Turtle:FindFirstChild("TushitaGate") then
			local Enemie = Enemies:FindFirstChild("Longma")
			
			if Enemie and Enemie:FindFirstChild("HumanoidRootPart") then
			  topos(Enemie.HumanoidRootPart.CFrame * Pos)
			  pcall(function()
				AutoHaki()
				EquipWeapon()
			end)
			else
			  topos(CFrame.new(-10218, 333, -9444))
			end
		  elseif CheckMon("rip_indra True Form") then
			if not VerifyTool("Holy Torch") then
			  topos(CFrame.new(5152, 142, 912))
			else
			  local Torch1 = QuestTorches:FindFirstChild("Torch1")
			  local Torch2 = QuestTorches:FindFirstChild("Torch2")
			  local Torch3 = QuestTorches:FindFirstChild("Torch3")
			  local Torch4 = QuestTorches:FindFirstChild("Torch4")
			  local Torch5 = QuestTorches:FindFirstChild("Torch5")
			  
			  local args1 = Torch1 and Torch1:FindFirstChild("Particles")
			  and Torch1.Particles:FindFirstChild("PointLight") and not Torch1.Particles.PointLight.Enabled
			  local args2 = Torch2 and Torch2:FindFirstChild("Particles")
			  and Torch2.Particles:FindFirstChild("PointLight") and not Torch2.Particles.PointLight.Enabled
			  local args3 = Torch3 and Torch3:FindFirstChild("Particles")
			  and Torch3.Particles:FindFirstChild("PointLight") and not Torch3.Particles.PointLight.Enabled
			  local args4 = Torch4 and Torch4:FindFirstChild("Particles")
			  and Torch4.Particles:FindFirstChild("PointLight") and not Torch4.Particles.PointLight.Enabled
			  local args5 = Torch5 and Torch5:FindFirstChild("Particles")
			  and Torch5.Particles:FindFirstChild("PointLight") and not Torch5.Particles.PointLight.Enabled
			  
			  if not Active1 and args1 then
			   topos(Torch1.CFrame)
			  elseif not Active2 and args2 then
			   topos(Torch2.CFrame)Active1 = true
			  elseif not Active3 and args3 then
			   topos(Torch3.CFrame)Active2 = true
			  elseif not Active4 and args4 then
				topos(Torch4.CFrame)Active3 = true
			  elseif not Active5 and args5 then
				topos(Torch5.CFrame)Active4 = true
			  else
				Active5 = true
			  end
			end
		  else
			if VerifyTool("God's Chalice") then
				EquipToolName("God's Chalice")
			  topos(CFrame.new(-5561, 314, -2663))
			else
			  local NPC = "EliteBossVerify"
			  if VerifyQuest("Diablo") then
				NPC = "Diablo"
			  elseif VerifyQuest("Deandre") then
				NPC = "Deandre"
			  elseif VerifyQuest("Urban") then
				NPC = "Urban"
			  else
				task.spawn(function()FireRemote("EliteHunter")end)
			  end
			  local EliteBoss = GetEnemies({NPC})
			  if EliteBoss and EliteBoss:FindFirstChild("HumanoidRootPart") then
				topos(EliteBoss.HumanoidRootPart.CFrame * Pos)
				EquipWeapon()
				pcall(function()
					AutoHaki()
				end)
			  end
			end
		  end
		end
	  end)
end)


QuestFarm:addToggle("Complete Bartilo Quest", false, function(Value)
	getgenv().AutoBartilo = Value;AutoBartiloQuest()
	if not Value then StopTween() return end
end)

local SubItem = Sub_Left:addMenu("Swords/Guns")
SubItem:addToggle("Auto Get Yama", false, function(Value)
	getgenv().AutoYama = Value
	task.spawn(function()
		while getgenv().AutoYama do task.wait()
		  pcall(function()
			if FireRemote("EliteHunter", "Progress") >= 30 then
			  fireclickdetector(workspace.Map.Waterfall.SealedKatana.Handle.ClickDetector)
			end
		  end)
		end
	end)
end)



SubItem:addToggle("Auto Get Rengoku", false, function(Value)
	getgenv().AutoRenguko = Value;AutoTaskRenguko()
	if not Value then StopTween() return end
end)

function GetWeaponInventory(Gun)
	for i,v in pairs(FireRemote("getInventory")) do
		if type(v) == "table" then
			if v.Type == "Gun" then
				if v.Name == Gun then
					return true
				end
			end
		end
	end
	return false
end
SubItem:addToggle("Auto Skull Guitar Fully", false, function(Value)
	getgenv().AutoSoulGuitar = Value
	if not Value then StopTween() return end
end)

task.spawn(function()
	while wait() do
		pcall(function()
			if GetWeaponInventory("Skull Guitar") == false then
				if getgenv().AutoSoulGuitar then
					if CheckMaterial("Bones") >= 500 and CheckMaterial("Ectoplasm") >= 250 and CheckMaterial("Dark Fragment") >= 1 then
						if (CFrame.new(-9681.458984375, 6.139880657196045, 6341.3720703125).Position - game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3000 then
							if game:GetService("Workspace").Map["Haunted Castle"].Candle1.Transparency == 0 then
								local GuitarProgress = FireRemote("GuitarPuzzleProgress", "Check");
								if not GuitarProgress then 
									local gravestoneEvent = FireRemote("gravestoneEvent", 2);
									if gravestoneEvent == true then
										FireRemote("gravestoneEvent", 2, true);
									else 
										if getgenv().AutoSoulGuitar then
											game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
										end
									end;
								end
								if GuitarProgress then 
									local Swamp = GuitarProgress.Swamp;
									local Gravestones = GuitarProgress.Gravestones;
									local Ghost = GuitarProgress.Ghost;
									local Trophies = GuitarProgress.Trophies;
									local Pipes = GuitarProgress.Pipes;
									local CraftedOnce = GuitarProgress.CraftedOnce;
									if Swamp and Gravestones and Ghost and Trophies and Pipes then 
										getgenv().AutoSoulGuitar = false
									end
									if not Swamp then 
										repeat wait() 
											topos(CFrame.new(-10141.462890625, 138.6524658203125, 5935.06298828125) * CFrame.new(0,30,0))
										until game.Players.LocalPlayer:DistanceFromCharacter(Vector3.new(-10141.462890625, 138.6524658203125, 5935.06298828125)) <= 100
										for i,v in pairs(game.Workspace.Enemies:GetChildren()) do
											if v.Name == "Living Zombie" then
												if v:FindFirstChild('Humanoid') then 
													if v:FindFirstChild('HumanoidRootPart') then 
														if game.Players.LocalPlayer:DistanceFromCharacter(v.HumanoidRootPart.Position) <= 2000 then 
															repeat wait() 
																AutoHaki()
																EquipWeapon()
																topos(v.HumanoidRootPart.CFrame * Pos)
																StartSoulGuitarMagnt = true
																BringMob(v.Name, v.HumanoidRootPart.CFrame)
															until not v.Parent or v.Humanoid.Health <= 0 or not  v:FindFirstChild('HumanoidRootPart') or not v:FindFirstChild('Humanoid') or not getgenv().Settings.Main["Auto Quest Soul Guitar"]
															StartSoulGuitarMagnt = false
														end
													end
												end
											end
										end   
									end
									wait(1)
									if Swamp and not Gravestones then 
										FireRemote("GuitarPuzzleProgress", "Gravestones");
									end
									wait(1)
									if Swamp and  Gravestones and not Ghost then 
										FireRemote("GuitarPuzzleProgress", "Ghost");
									end 
									wait(1)
									if  Swamp and  Gravestones and Ghost and not Trophies then 
										FireRemote("GuitarPuzzleProgress", "Trophies");
									end
									wait(1)
									if  Swamp and  Gravestones and Ghost and Trophies and not Pipes then 
										FireRemote("GuitarPuzzleProgress", "Pipes");
									end
								end
							else
								if string.find(FireRemote("gravestoneEvent",2), "Error") then
									print("Go to Grave")
									topos(CFrame.new(-8653.2060546875, 140.98487854003906, 6160.033203125))
								elseif string.find(FireRemote("gravestoneEvent",2), "Nothing") then
									print("Wait Next Night")
								else
									FireRemote("gravestoneEvent",2,true)
								end
							end
						else
							topos(CFrame.new(-9681.458984375, 6.139880657196045, 6341.3720703125))
						end
					else
						if CheckMaterial("Ectoplasm") <= 250 then
							if World2 then
								if game:GetService("Workspace").Enemies:FindFirstChild("Ship Deckhand") or game:GetService("Workspace").Enemies:FindFirstChild("Ship Engineer") or game:GetService("Workspace").Enemies:FindFirstChild("Ship Steward") or game:GetService("Workspace").Enemies:FindFirstChild("Ship Officer") or game:GetService("Workspace").Enemies:FindFirstChild("Arctic Warrior") then
									for i,v in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
										if v.Name == "Ship Deckhand" or v.Name == "Ship Engineer" or v.Name == "Ship Steward" or v.Name == "Ship Officer" or v.Name == "Arctic Warrior" then
											if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
												repeat wait()
													AutoHaki()
													EquipWeapon()
													topos(v.HumanoidRootPart.CFrame * Pos)
													BringMob(v.Name, v.HumanoidRootPart.CFrame)
												until not getgenv().AutoSoulGuitar or not v.Parent or v.Humanoid.Health <= 0
											end
										end
									end
								else
									FireRemote("requestEntrance",Vector3.new(923.21252441406, 126.9760055542, 32852.83203125))
								end
							else
								FireRemote("TravelDressrosa")
							end
						elseif CheckMaterial("Dark Fragment") < 1 then
							if World2 then
								if game.ReplicatedStorage:FindFirstChild("Darkbeard") or game:GetService("Workspace").Enemies:FindFirstChild("Darkbeard") then
									for i,v in pairs(game.Workspace.Enemies:GetChildren()) do
										if v.Name == "Darkbeard" and v.Humanoid.Health > 0 and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
											repeat wait()
												AutoHaki()
												EquipWeapon()
												topos(v.HumanoidRootPart.CFrame * Pos)
											until getgenv().AutoSoulGuitar or v.Humanoid.Health <= 0
										end
									end
								else
									topos(CFrame.new(3798.4575195313, 13.826690673828, -3399.806640625))
								end
							else
								FireRemote("TravelDressrosa")
							end
						elseif CheckMaterial("Bones") <= 500 then
							if World3 then
								if game:GetService("Workspace").Enemies:FindFirstChild("Reborn Skeleton [Lv. 1975]") or game:GetService("Workspace").Enemies:FindFirstChild("Living Zombie [Lv. 2000]") or game:GetService("Workspace").Enemies:FindFirstChild("Demonic Soul [Lv. 2025]") or game:GetService("Workspace").Enemies:FindFirstChild("Posessed Mummy [Lv. 2050]") then
									for i,v in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
										if v.Name == "Reborn Skeleton" or v.Name == "Living Zombie" or v.Name == "Demonic Soul" or v.Name == "Posessed Mummy" then
											if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
												repeat wait()
													AutoHaki()
													EquipWeapon()
													topos(v.HumanoidRootPart.CFrame * Pos)
													BringMob(v.Name, v.HumanoidRootPart.CFrame)
												until not getgenv().AutoSoulGuitar or v.Humanoid.Health <= 0 or not v.Parent or v.Humanoid.Health <= 0
											end
										end
									end
								else
									topos(CFrame.new(-9504.8564453125, 172.14292907714844, 6057.259765625))
								end
							else
								FireRemote("TravelZou")
							end
						end
					end
				end
			end
		end)
	end
end)

local Sub_Right = Tab.Sub:addSection()
local TimelyRaidFarm = Sub_Right:addMenu("Timely Raid Farming")


TimelyRaidFarm:addToggle("Auto Elite Hunter", false, function(Value)
	getgenv().AutoEliteHunter = Value;AutoTaskEliteHunter()
  	if not Value then StopTween() return end
end)

TimelyRaidFarm:addToggle("Auto Factory Raid", false, function(Value)
	getgenv().AutoFactory = Value;AutoFactory()
	if not Value then StopTween() return end
end)

TimelyRaidFarm:addToggle("Auto Pirate Raid", false, function(Value)
	getgenv().AutoPirateRaid = Value;AutoPirateRaid()
	if not Value then StopTween() return end
end)

TimelyRaidFarm:addToggle("Auto Hallow Scythe", false, function(Value)
	getgenv().AutoFarmBossHallow = Value;AutoSoulReaper()
	if not Value then StopTween() return end
end)

TimelyRaidFarm:addToggle("Auto Dark Coat", false, function(Value)
	getgenv().AutoDarkCoat = Value;AutoDarkbeard()
	if not Value then StopTween() return end
end)

TimelyRaidFarm:addToggle("Auto Cursed Captain", false, function(Value)
	getgenv().AutoCursedCaptain = Value;AutoCursedCaptain()
	if not Value then StopTween() return end
end)


TimelyRaidFarm:addToggle("Auto Open Colors Plate", false, function(Value)
	getgenv().AutoOpenColors = Value
	task.spawn(function()
	  while getgenv().AutoOpenColors do
		  task.wait(0.1)
		  local plrChar = Player and Player.Character and Player.Character.PrimaryPart
		  if plrChar then
			  local positions = {
				  {pos = Vector3.new(-5415, 314, -2212), color = "Pure Red"},
				  {pos = Vector3.new(-4972, 336, -3720), color = "Snow White"},
				  {pos = Vector3.new(-5420, 1089, -2667), color = "Winter Sky"}
			  }
			  for _, data in pairs(positions) do
				  if (plrChar.Position - data.pos).Magnitude < 5 then
					game:GetService("ReplicatedStorage").Modules.Net["RF/FruitCustomizerRF"]:InvokeServer({
						["StorageName"] = data.color,
						["Type"] = "AuraSkin",
						["Context"] = "Equip"
					})
					  break
				  end
			  end
		  end
	  end
  end)
  task.spawn(function()
	  while getgenv().AutoOpenColors do
		  task.wait(0.2)
		  if not getgenv().AutoFarm and not getgenv().Auto_Bone and not getgenv().AutoFarmPrince then
			  local button = GetButton()
			  if button then
				  topos(button.CFrame)
			  elseif not button and not getgenv().AutoDarkDagger then
				  topos(CFrame.new(-5119, 315, -2964))
			  end
		  end
	  end
  end)
	if not Value then StopTween() return end
end)
TimelyRaidFarm:addToggle("Auto True Form Rip Indra", false, function(Value)
	getgenv().AutoDarkDagger = Value;AutoKillRipIndra()
	if not Value then StopTween() return end
end)

local TasksFarm = Sub_Right:addMenu("Tasks Farm")
TasksFarm:addToggle("Start Farm Observation", false, function(Value)
	getgenv().AutoObservation = Value;AutoObservation()
	if not Value then StopTween() return end
end)

TasksFarm:addToggle("Farm Observation Hopping", false, function(Value)
	getgenv().StartObsHop = Value
	if not Value then StopTween() return end
end)

TasksFarm:addToggle("Auto Dummy Training", false, function(Value)
	getgenv().DummyTraining = Value;TrainDummy()
	if not Value then StopTween() return end
end)

TasksFarm:addToggle("Auto Musketeer Hat", false, function(Value)
	getgenv().AutoMusketeerHat = Value;AutoFarmMusketeerHat()
	if not Value then StopTween() return end
end)

local Dragon_Left = Tab.Dragon:addSection()
local Dragon = Dragon_Left:addMenu("Collectables")

Dragon:addToggle("Auto Collect Berries", false, function(Value)
	getgenv().AutoBerrySafe = Value;AutoBerries()
	if not Value then StopTween() return end
end)

local Belts = Dragon_Left:addMenu("Belts")
Belts:addToggle("Auto White Belt", false, function(Value)
	getgenv().AutoWhiteBelt = Value;AutoWhiteBelt()
	if not Value then StopTween() return end
end)

Belts:addToggle("Auto Purple Belt", false, function(Value)
	getgenv().AutoPurpleBelt = Value;AutoPurpleBelt()
	if not Value then StopTween() return end
end)

local Dragon_Right = Tab.Dragon:addSection()
local Prehistoric = Dragon_Right:addMenu("Prehistoric Event")


Prehistoric:addToggle("Teleport to Prehistoric Island", false, function(Value)
	getgenv().AutoPrehistoricIsland = Value
	task.spawn(function()
		while getgenv().AutoPrehistoricIsland do task.wait()
			for _, location in pairs(game:GetService("Workspace")._WorldOrigin.Locations:GetChildren()) do
				if location.Name == "Prehistoric Island" then
					topos(location.CFrame * CFrame.new(0, 333, 0))
				end
			end
		end
	end)
	if not Value then StopTween() return end
end)

Prehistoric:addToggle("Auto Complete Volcano Event", false, function(Value)
    getgenv().AutoVolcanoEvent = Value
    task.spawn(function()
        local function PressKey(key)
            game:GetService("VirtualInputManager"):SendKeyEvent(true, key, false, game)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, key, false, game)
        end

        local function FindGolems(volcano)
            local PlayerChar = Player and Player.Character
            local playerPP = PlayerChar and PlayerChar.PrimaryPart
            if not playerPP then return {} end
            local enemies = {}
            for _, enemy in ipairs(Enemies:GetChildren()) do
                local enemyPP = enemy:FindFirstChild("RightHand")
                local humanoid = enemy:FindFirstChild("Humanoid")
                if enemyPP and humanoid and humanoid.Health > 0 and (enemyPP.Position - volcano.Position).Magnitude < 300 then
                    table.insert(enemies, {primaryPart = enemyPP, Humanoid = humanoid})
                end
            end
            return enemies
        end

        local function Golems(volcano)
            local enemies = FindGolems(volcano)
            for _, enemyData in ipairs(enemies) do
                local enemyPP = enemyData.primaryPart
                local humanoid = enemyData.Humanoid
                while humanoid.Health > 0 do
                    topos(enemyPP.Position + Vector3.new(0, 30, 0))
                    task.wait(0.1)
                end
            end
            return #enemies > 0
        end

        local function CheckForLava()
            local interior = workspace.Map.PrehistoricIsland.Core:FindFirstChild("InteriorLava")
            if interior and interior:IsA("Model") then interior:Destroy() end
            local Fetch1 = workspace.Map:FindFirstChild("PrehistoricIsland")
            if Fetch1 then
                for _, descend in pairs(Fetch1:GetDescendants()) do
                    if descend:IsA("Part") and descend.Name:lower():find("lava") then
                        descend:Destroy()
                    end
                end
            end
            local Fetch2 = workspace.Map:FindFirstChild("PrehistoricIsland")
            if Fetch2 then
                for _, descend in pairs(Fetch2:GetDescendants()) do
                    if descend:IsA("Model") then
                        for _, v in pairs(descend:GetDescendants()) do
                            if v:IsA("MeshPart") and v.Name:lower():find("lava") then
                                v:Destroy()
                            end
                        end
                    end
                end
            end
        end

        local function CheckRock()
            local Core = game.Workspace.Map.PrehistoricIsland.Core.VolcanoRocks
            for _, v in pairs(Core:GetChildren()) do
                if v:IsA("Model") then
                    local vrock = v:FindFirstChild("volcanorock")
                    if vrock and vrock:IsA("MeshPart") then
                        local vcolor = vrock.Color
                        if vcolor == Color3.fromRGB(185, 53, 56) or vcolor == Color3.fromRGB(185, 53, 57) then
                            return vrock
                        end
                    end
                end
            end
            return nil
        end

        local function SkillsActive(ToolType)
            local plr = game.Players.LocalPlayer
            local plrBg = plr.Backpack
            for _, v in pairs(plrBg:GetChildren()) do
                if v:IsA("Tool") and v.ToolTip == ToolType then
                    v.Parent = plr.Character
                    for _, skills in ipairs({"Z", "X", "C", "V"}) do
                        wait()
                        pcall(function() PressKey(skills) end)
                    end
                    v.Parent = plrBg
                    break
                end
            end
        end
        while getgenv().AutoVolcanoEvent do
            AutoHaki()
            pcall(CheckForLava)
            local LavaIndex = CheckRock()
            if LavaIndex then
                local Pos = CFrame.new(LavaIndex.Position)
                topos(Pos)
                if LavaIndex.Color == Color3.fromRGB(185, 53, 56) or LavaIndex.Color == Color3.fromRGB(185, 53, 57) then
                    if (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - LavaIndex.Position).Magnitude <= 1 then
                        if getgenv().UseMelee then SkillsActive("Melee") end
                        if getgenv().UseSword then SkillsActive("Sword") end
                        if getgenv().UseGun then SkillsActive("Gun") end
                    end
                end
            else
                local volcano = workspace.Map:FindFirstChild("PrehistoricIsland")
                if volcano and Golems(volcano) then
					AutoHaki()
					EquipWeapon()
                else
                    local core = volcano and volcano:FindFirstChild("Core") and volcano.Core:FindFirstChild("PrehistoricRelic")
                    local skull = core and core:FindFirstChild("Skull")
                    if skull then
                        topos(CFrame.new(skull.Position))
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    if not Value then StopTween() return end
end)


Prehistoric:addToggle("Use Melee Skills", true, function(Value)
	getgenv().UseMelee = Value
end)

Prehistoric:addToggle("Use Sword Skills", false, function(Value)
	getgenv().UseSword = Value
end)

Prehistoric:addToggle("Use Gun Skills", false, function(Value)
	getgenv().UseGun = Value
end)

local function AutoCollectEgg()
    while getgenv().AutoCollectEgg do task.wait()
        local SpawnedEggs = workspace.Map.PrehistoricIsland.Core.SpawnedDragonEggs:GetChildren()
        if #SpawnedEggs > 0 then
            local RandomEgg = SpawnedEggs[math.random(1, #SpawnedEggs)]
            if RandomEgg:IsA("Model") and RandomEgg.PrimaryPart then
                topos(RandomEgg.PrimaryPart.CFrame)
                local PlayerPosition = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
                local EggPosition = RandomEgg.PrimaryPart.Position
                local distance = (PlayerPosition - EggPosition).Magnitude
                if distance <= 1 then
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, "E", false, game)
                    wait(1.5)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, "E", false, game)
                end
            end
        end
    end
end


Prehistoric:addToggle("Auto Collect Bones", false, function(Value)
	getgenv().AutoCollectBone = Value
	if not Value then StopTween() return end
end)

spawn(function()
    while wait() do
        if getgenv().AutoCollectBone then
            for i, v in pairs(workspace:GetDescendants()) do
                if (v:IsA("BasePart") and (v.Name == "DinoBone")) then
                    topos(CFrame.new(v.Position))
                end
            end
        end
    end
end)

Prehistoric:addToggle("Auto Collect Dragon Eggs", false, function(Value)
	getgenv().AutoCollectEgg = Value
	AutoCollectEgg()
	if not Value then StopTween() return end
end)

Prehistoric:addToggle("Auto Farm Blaze Ember", false, function(Value)
	getgenv().AutoQuestBlaze = Value
	AutoQuestBlaze()
	if not Value then StopTween() return end
end)

Prehistoric:addButton("Teleport to Dragon Hunter", function()
	topos(CFrame.new(5865.80811, 1209.50269, 811.746582, -0.675207436, -6.76664627e-08, 0.737627923, 8.33632186e-09, 1, 9.93661047e-08, -0.737627923, 7.32418357e-08, -0.675207436))
end)

Prehistoric:addButton("Teleport to Dragon Wizard", function()
	topos(CFrame.new(5775.35059, 1209.50269, 805.679993, -0.696588516, -7.57756808e-08, 0.717470825, -7.6549334e-08, 1, 3.12936663e-08, -0.717470825, -3.31231078e-08, -0.696588516))
end)

Prehistoric:addToggle("Auto Upgrade Dragon Talon", false, function(Value)
	getgenv().AutoUpgradeDragonTalon = Value
	task.spawn(function()
		while task.wait() do
			if getgenv().AutoUpgradeDragonTalon then
				local UzothNPC = CFrame.new(5661.89014, 1211.31909, 864.836731, 0.811413169, -1.36805838e-08, -0.584473014, 4.75227395e-08, 1, 4.25682458e-08, 0.584473014, -6.23161966e-08, 0.811413169)
				topos(UzothNPC)
				if (UzothNPC.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5 then
					local RequestTable = {["NPC"] = "Uzoth",["Command"] = "Upgrade"}
					game:GetService("ReplicatedStorage").Modules.Net["RF/InteractDragonQuest"]:InvokeServer(RequestTable)
				end
			end
		end
	end)
	if not Value then StopTween() return end
end)

Prehistoric:addButton("Craft Volcanic Magnet", function()
	local args = {
		[1] = "CraftItem",
		[2] = "Craft",
		[3] = "Volcanic Magnet"
	}
	game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))
end)

local function AutoCollectFireFlowers()
    while getgenv().AutoCollectFireFlowers do task.wait()
            local FireFlowers = workspace:FindFirstChild("FireFlowers")
            if FireFlowers then
                for _, flower in pairs(FireFlowers:GetChildren()) do
                    if flower:IsA("Model") and flower.PrimaryPart then
                        local FlowerPosition = flower.PrimaryPart.Position
                        local PlayerPosition = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
                        local distance = (FlowerPosition - PlayerPosition).Magnitude
                        if distance <= 1 then
                            game:GetService("VirtualInputManager"):SendKeyEvent(true, "E", false, game)
                            wait(1.5)
                            game:GetService("VirtualInputManager"):SendKeyEvent(false, "E", false, game)
                        else
                            topos(CFrame.new(FlowerPosition))
                        end
                    end
                end
			end
		end
	end
Prehistoric:addToggle("Auto Collect Fire Flowers", false, function(Value)
	getgenv().AutoCollectFireFlowers = Value
	AutoCollectFireFlowers()
	if not Value then StopTween() return end
end)

local Draco = Dragon_Right:addMenu("Draco Race")

local function AutoTrialTeleport()
    while getgenv().AutoTrialDracoTP do task.wait()
        local TrialPart = workspace.Map.PrehistoricIsland:FindFirstChild("TrialTeleport")
        if TrialPart and TrialPart:IsA("Part") then
            topos(CFrame.new(TrialPart.Position))
        end
    end
end

Draco:addToggle("Teleport to Draco Trial", false, function(Value)
	getgenv().AutoTrialDracoTP = Value
	AutoTrialTeleport()
	if not Value then StopTween() return end
end)

Draco:addButton("Change to Draco Race", function()
	topos(CFrame.new(5814.427, 1208.327, 884.579))
	local targetPosition = Vector3.new(5814.427, 1208.327, 884.579)
	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	repeat task.wait() until (character.HumanoidRootPart.Position - targetPosition).Magnitude < 1
	local request = {
		{NPC = "Dragon Wizard", Command = "DragonRace"}
	}
	game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(request))
end)

local Dungeon_Left = Tab.Raid:addSection()
	local Raid = Dungeon_Left:addMenu("Fruit Awakenings")

	local Raids_Chip = {}

	pcall(function()
		local Raids = require(ReplicatedStorage.Raids)
		for _, b in pairs(Raids.raids) do
			table.insert(Raids_Chip, b)
		end
		for _, b in pairs(Raids.advancedRaids) do
			table.insert(Raids_Chip, b)
		end
	end)

	Raid:addDropdown("Raid Chip", 1, Raids_Chip, function(Value)
		getgenv().SelectRaid = Value
	end)

	Raid:addToggle("Auto Buy Chip", false, function(Value)
		getgenv().AutoBuyChip = Value
		task.spawn(function()
			while getgenv().AutoBuyChip do
				task.wait()
				if getgenv().SelectRaid and not VerifyTool("Special Microchip") then
					FireRemote("RaidsNpc", "Select", getgenv().SelectRaid)
					task.wait(1)
				end
			end
		end)
	end)

	Raid:addToggle("Auto Complete Raid", false, function(Value)
		getgenv().AutoRaid = Value

		if not Value then
			StopTween()
			return
		end

		task.spawn(function(self)
			self.Islands = workspace:WaitForChild("_WorldOrigin", 9e9):WaitForChild("Locations", 9e9)

			function self:GetIsland()
				local playerPP = Player.Character and Player.Character.PrimaryPart
				if not playerPP then return nil end

				for i = 5, 1, -1 do
					local name = "Island " .. i
					for _, island in ipairs(self.Islands:GetChildren()) do
						if island.Name == name and island:IsA("Part") and (playerPP.Position - island.Position).Magnitude < 3500 then
							return island
						end
					end
				end
				return nil
			end

			function self:FindEnemiesOnIsland(island)
				local enemies = {}
				for _, enemy in ipairs(Enemies:GetChildren()) do
					local enemyPP = enemy:FindFirstChild("RightHand")
					local humanoid = enemy:FindFirstChild("Humanoid")
					if enemyPP and humanoid and humanoid.Health > 0 and (enemyPP.Position - island.Position).Magnitude < 300 then
						table.insert(enemies, { primaryPart = enemyPP, Humanoid = humanoid })
					end
				end
				return enemies
			end

			function self:AttackEnemiesOnIsland(island)
				local enemies = self:FindEnemiesOnIsland(island)

				for _, enemyData in ipairs(enemies) do
					local enemyPP = enemyData.primaryPart
					local humanoid = enemyData.Humanoid
					local model = enemyPP and enemyPP:FindFirstAncestorWhichIsA("Model")

					if model and humanoid and humanoid.Health > 0 then
						while humanoid.Health > 0 and getgenv().AutoRaid do
							topos(enemyPP.Position + Vector3.new(0, 40, 0))
							task.wait(0.1)
						end
					end
				end
				return #enemies > 0
			end

			function self:HandleRaid()
				while getgenv().AutoRaid do
					task.wait()
					if Player.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
						EquipWeapon()
						AutoHaki()
						local island = self:GetIsland()
						if island then
							topos(island.CFrame + Vector3.new(0, 80, 0))
							local hasEnemies = self:AttackEnemiesOnIsland(island)
							task.wait(hasEnemies and 0.1 or 1)
						end
					end
				end
			end

			function self:SummonRaid()
				while getgenv().AutoRaid do
					task.wait()
					if not Player.PlayerGui.Main.TopHUDList.RaidTimer.Visible and VerifyTool("Special Microchip") then
						if not self:GetIsland() then
							pcall(function()
								if World2 then
									topos(CFrame.new(-6438.73535, 250.645355, -4501.50684))
									fireclickdetector(workspace.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector)
								elseif World3 then
									topos(CFrame.new(-5073, 315, -3153))
									fireclickdetector(workspace.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector)
								end
								repeat task.wait() until self:GetIsland() and Player.PlayerGui.Main.TopHUDList.RaidTimer.Visible
								task.wait(0.5)
							end)
						end
					end
				end
			end

			task.spawn(function() self:SummonRaid() end)
			task.spawn(function() self:HandleRaid() end)
		end, {})
	end)


Raid:addToggle("Auto Awaken", false, function(Value)
	getgenv().AutoAwaken = Value
	task.spawn(function()
	  while getgenv().AutoAwaken do task.wait(0.5)
		  FireRemote("Awakener", "Check")FireRemote("Awakener", "Awaken")
	  end
	end)
end)

local Fruits = {
    "Rocket-Rocket", "Spin-Spin", "Chop-Chop", "Spring-Spring", "Bomb-Bomb",
    "Smoke-Smoke", "Spike-Spike", "Flame-Flame", "Falcon-Falcon", "Ice-Ice",
    "Sand-Sand", "Dark-Dark", "Ghost-Ghost", "Diamond-Diamond", "Light-Light",
    "Rubber-Rubber", "Barrier-Barrier"
}

Raid:addToggle("Auto Unstore Low Fruits", false, function(Value)
    getgenv().UnstoreBadFruit = Value
end)

task.spawn(function()
    while wait(0.1) do
        if getgenv().UnstoreBadFruit then
            pcall(function()
                for _, fruit in ipairs(Fruits) do
                    if not Player.Backpack:FindFirstChild(fruit) and not Player.Character:FindFirstChild(fruit) then
                        FireRemote("LoadFruit", fruit)
                    end
                end
            end)
        end
    end
end)



local LawRaid = Dungeon_Left:addMenu("Law Raid")

LawRaid:addToggle("Start Law Raid Farm", false, function(Value)
	getgenv().AutoLawRaid = Value;AutoLawRaid()
	if not Value then StopTween() return end
end)


local Dungeon_Right = Tab.Raid:addSection()
local Fruit = Dungeon_Right:addMenu("Fruit Info")

Fruit:addButton("Open Normal Shop", function()
	require(game.Players.LocalPlayer.PlayerGui:WaitForChild("Main"):WaitForChild("FruitShopAndDealer"):WaitForChild("Controller")):Open()
end)

Fruit:addButton("Open Advanced Shop", function()
	require(game.Players.LocalPlayer.PlayerGui:WaitForChild("Main"):WaitForChild("FruitShopAndDealer"):WaitForChild("Controller")):Open("AdvancedFruitDealer")
end)

Fruit:addToggle("Auto Roll Fruit", false, function(Value)
	getgenv().Random_Auto = Value
	task.spawn(function()
		while getgenv().Random_Auto do task.wait()
		FireRemote("Cousin", "Buy")
		end
	end)
end)

Fruit:addToggle("Auto Roll Summer", false, function(Value)
	getgenv().Random_AutoSummer = Value
	task.spawn(function()
		while getgenv().Random_AutoSummer do task.wait()
		FireRemote("Cousin", "BuySummer")
		end
	end)
end)

local RarityFruits = {
	Common = {
		"Rocket Fruit", "Spin Fruit", "Chop Fruit", "Spring Fruit", "Bomb Fruit", "Smoke Fruit", "Spike Fruit"},
	Uncommon = {
		"Flame Fruit", "Falcon Fruit", "Ice Fruit", "Sand Fruit", "Diamond Fruit", "Dark Fruit"},
	Rare = {
		"Light Fruit", "Rubber Fruit", "Barrier Fruit", "Ghost Fruit", "Magma Fruit"},
	Legendary = {
		"Quake Fruit", "Budha Fruit", "Love Fruit", "Spider Fruit", "Sound Fruit", "Phoenix Fruit", "Portal Fruit", "Rumble Fruit", "Pain Fruit", "Blizzard Fruit"},
	Mythical = {
		"Gravity Fruit", "Mammoth Fruit", "T-Rex Fruit", "Dough Fruit", "Shadow Fruit", "Venom Fruit", "Control Fruit", "Spirit Fruit", "Dragon Fruit", "Leopard Fruit", "Kitsune Fruit"}
  }
  
  local SelectRarityFruits = {"Common - Mythical", "Uncommon - Mythical", "Rare - Mythical", "Legendary - Mythical", "Mythical"}
  local SetRarityFruits = "Common - Mythical"
  local ResultStoreFruits = {}

Fruit:addDropdown("Select Rarity", "Common - Mythical", SelectRarityFruits, function(Value)
	SetRarityFruits = Value
end)

function CheckFruits()
	local RarityOrder = {
		["Common - Mythical"] = { "Common", "Uncommon", "Rare", "Legendary", "Mythical" },
		["Uncommon - Mythical"] = { "Uncommon", "Rare", "Legendary", "Mythical" },
		["Rare - Mythical"] = { "Rare", "Legendary", "Mythical" },
		["Legendary - Mythical"] = { "Legendary", "Mythical" },
		["Mythical"] = { "Mythical" }
	}
	local SelectedRarities = RarityOrder[SetRarityFruits] or {}
	ResultStoreFruits = {}
	for _, rarity in ipairs(SelectedRarities) do
		if RarityFruits[rarity] then
			for _, fruit in ipairs(RarityFruits[rarity]) do
				table.insert(ResultStoreFruits, fruit)
			end
		end
	end
  end

  Fruit:addToggle("Auto Store Fruit", false, function(Value)
	getgenv().AutoStoreFruit = Value
	task.spawn(function()
		while getgenv().AutoStoreFruit do
			task.wait()
			ResultStoreFruits = {}
			CheckFruits()
			for _, v in pairs(Player.Backpack:GetChildren()) do
				if string.find(v.Name, "Fruit") then
					for _, Res in pairs(ResultStoreFruits) do
						if v.Name == Res then
							local FirstNameFruit = string.gsub(v.Name, " Fruit", "")
							if Player.Backpack:FindFirstChild(v.Name) then
								FireRemote("StoreFruit", FirstNameFruit .. "-" .. FirstNameFruit, v)
							end
						end
					end
				end
			end
			for _, v in pairs(Player.Character:GetChildren()) do
				if string.find(v.Name, "Fruit") then
					for _, Res in pairs(ResultStoreFruits) do
						if v.Name == Res then
							local FirstNameFruit = string.gsub(v.Name, " Fruit", "")
							if Player.Character:FindFirstChild(v.Name) then
								FireRemote("StoreFruit", FirstNameFruit .. "-" .. FirstNameFruit, v)
							end
						end
					end
				end
			end
		end
	end)
end)


local FruitInfo = Fruit:addLabel("Fruit Spawn Status", "Scanning for fruit...")

task.spawn(function()
	while wait(0.5) do
		local Count = 0
		local FruitDistance = math.huge
		local plrPos = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position
		if plrPos then
			for _, obj in ipairs(game.Workspace:GetChildren()) do
				if obj:IsA("Model") and string.find(obj.Name, "Fruit") then
					local Part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle")
					if Part and Part:IsA("BasePart") then
						Count = Count + 1
						local distance = (Part.Position - plrPos).Magnitude
						if distance < FruitDistance then
							FruitDistance = distance
						end
					end 
				end
			end
			local Status = Count > 0 and string.format("Fruits Found: %d\nPosition: %.2f Studs Away", Count, FruitDistance) or "No fruits detected nearby."
			FruitInfo:RefreshDesc(Status)
		end
	end
end)

Fruit:addToggle("Teleport to Fruit", false, function(Value)
	getgenv().Tweenfruit = Value
	task.spawn(function()
		while getgenv().Tweenfruit do task.wait()
			local plrPos = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.Position
			local Fruit = nil
			local FruitDistance = math.huge
			if plrPos then
				for _, obj in ipairs(game.Workspace:GetChildren()) do
					if obj:IsA("Model") and string.find(obj.Name, "Fruit") then
						local Part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle")
						if Part and Part:IsA("BasePart") then
							local distance = (Part.Position - plrPos).Magnitude
							if distance < FruitDistance then
								FruitDistance = distance
								Fruit = Part
							end
						end
					end
				end
				if Fruit then
					topos(Fruit.CFrame)
				end
			end
		end
	end)
	if not Value then StopTween() end
end)

Fruit:addToggle("Fruit Notification", false, function(Value)
	getgenv().FruitCheck = Value
	spawn(function()
		while wait(.1) do
			if getgenv().FruitCheck then
				for i,v in pairs(game.Workspace:GetChildren()) do
					if v:IsA("Tool") then
						require(game:GetService("ReplicatedStorage").Notification).new(v.Name.." Spawned"):Display();
						wait()
						setthreadcontext(5)
					end
				end
			end
		end
	end)
end)

Fruit:addButton("Teleport To Advanced Fruit Dealer", function()
	repeat
		wait()
	until game:GetService("Workspace").Map:FindFirstChild("MysticIsland")
	if game:GetService("Workspace").Map:FindFirstChild("MysticIsland") then
		local allNPCs = getnilinstances()
		for _, npc in pairs(game:GetService("ReplicatedStorage").NPCs:GetChildren()) do
			table.insert(allNPCs, npc)
		end
		for _, npc in pairs(allNPCs) do
			if npc.Name == "Advanced Fruit Dealer" then
				topos(npc.HumanoidRootPart.CFrame)
			end
		end
	end
end)

local MirageStockInfo = Fruit:addLabel("Mirage Stock Status", "Scanning for Information...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes
local Event = Remotes["CommF_"]
local result = Event:InvokeServer("GetFruits", true)

local function addCommas(number)
    local formatted = tostring(number)
    while true do  
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end
local function FruitName(FruitName)
    local parts = string.split(FruitName, "-")
    return parts[1]
end
local FruitsInfoString = ""
local FoundFruit = false
for _, FruitData in pairs(result) do
    if FruitData["OnSale"] == true then
        local Name = FruitName(FruitData["Name"])
        local PriceWithCommas = addCommas(FruitData["Price"])
        local FruitInfo = Name .. " - $" .. PriceWithCommas
        FoundFruit = true
        FruitsInfoString = FruitsInfoString .. FruitInfo .. "\n"
    end
end

if FoundFruit then
    MirageStockInfo:RefreshDesc("\n" .. FruitsInfoString)
else
    MirageStockInfo:RefreshDesc("No fruits on sale.")
end

local Trial_Left = Tab.Trial:addSection()
local Trial = Trial_Left:addMenu("Trials")

Trial:addButton("Go to Race Door", function()
	local Players = game:GetService("Players")
	local Race = Players.LocalPlayer.Data.Race.Value
	local RacePositions = {
		Fishman = CFrame.new(28224.057, 14889.427, -210.587),
		Human = CFrame.new(29237.295, 14889.427, -206.950),
		Cyborg = CFrame.new(28492.414, 14894.427, -422.110),
		Skypiea = CFrame.new(28967.408, 14918.075, 234.312),
		Ghoul = CFrame.new(28672.721, 14889.128, 454.596),
		Mink = CFrame.new(29020.660, 14889.427, -379.268)
	}
	local destination = RacePositions[Race]
	if destination then
		topos(destination)
	end
end)

Trial:addToggle("Auto Complete Trials", false, function(Value)
	getgenv().AutoFinishTrial = Value
	task.spawn(function()
	  while getgenv().AutoFinishTrial do task.wait(0.1)
		  local PlayerRace = Player.Data.Race.Value
		  if typeof(PlayerRace) == "string" then
			  if PlayerRace == "Cyborg" then
				  	topos(CFrame.new(28654, 14898, -30))
			  elseif PlayerRace == "Ghoul" or PlayerRace == "Human" then
				  	KillAura()
				elseif PlayerRace == "Fishman" then
					print("Not working as for now")
			  elseif PlayerRace == "Mink" then
					topos(workspace.Map.MinkTrial.Ceiling * CFrame.new(0, - 5, 0))
			  elseif PlayerRace == "Skypiea" then
					topos(workspace.Map.SkyTrial.Model.FinishPart)
			  	end
		  	end
	  	end
  	end)
end)

Trial:addToggle("Auto Kill Me", false, function(Value)
	getgenv().AutoKillMe = Value
	task.spawn(function()
	  while getgenv().AutoKillMe and Player.PlayerGui.Main.Timer.Visible do task.wait(0.1)
		game.Players.LocalPlayer.Character.Head:Destroy()
	  end
  	end)
end)

Trial:addToggle("Auto Kill Players", false, function(Value)
	getgenv().KillPlayer = Value
	if not Value then StopTween() return end
	task.spawn(function()
	  while getgenv().KillPlayer do task.wait()
		local cc
		pcall(function()
		  local TempleCFrame = CFrame.new(28730, 14887, -91, 0.557, 0, 0.83, 0, 1, 0, -0.83, 0, 0.557)
		  if Player.PlayerGui.Main.Timer.Visible and GetDistance(TempleCFrame) <= 380 then
			for _, p in pairs(game.Players:GetChildren()) do
			  local char = p.Character
			  if p.Name ~= Player.Name and char and char:FindFirstChild("HumanoidRootPart") then
				local hrp = char.HumanoidRootPart
				if GetDistance(TempleCFrame, hrp) <= 300 and char.Humanoid.Health > 0 then
				  cc = p
				end
			  end
			end
		  end
		end)
		for _, v in pairs(workspace.Characters:GetChildren()) do
		  if v.Name ~= Player.Name then
			local h, hrp = v:FindFirstChild("Humanoid"), v:FindFirstChild("HumanoidRootPart")
			if h and hrp and h.Health > 0 and 
			   (Player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude <= 100 then
				  repeat task.wait()
					  Target = v.Name
					  AutoHaki()
					  EquipWeapon()
					  topos(hrp.CFrame * CFrame.new(0, 5, 3))
					  if game.Players.LocalPlayer.Team ~= game.Players[Target].Team or tostring(game.Players.LocalPlayer.Team) == "Pirates" then
						topos(hrp.CFrame * CFrame.new(0, 0, 3))
					  end
				  until not getgenv().KillPlayer or h.Health <= 0 or not hrp or not h or not v.Parent
			end
		  end
		end
	  end
	end)
end)

Trial:addDropdown("Select Train Method", "Bones", {"Bones", "Cakes"}, function(Value)
	getgenv().TrainMethod = Value
end)

Trial:addToggle("Start Auto Train", false, function(Value)
	getgenv().AutoTrain = Value
	AutoTrainGear()
	if not Value then StopTween() return end
end)

Trial:addToggle("Teleport To Blue Gear", false, function(Value)
	getgenv().TweenMGear = Value
	task.spawn(function()
		while getgenv().TweenMGear do
			task.wait()
			local MysticIsland = workspace.Map:FindFirstChild("MysticIsland")
			if MysticIsland then
				for _, Part in pairs(MysticIsland:GetChildren()) do
					if Part.Name == "Part" and Part:IsA("MeshPart") then
						topos(Part.CFrame)
						Part.Transparency = 0
					end
				end
			end
		end
	end)
	if not Value then StopTween() return end
end)


local Tp = Trial_Left:addMenu("Area")

Tp:addButton("Teleport to Top of Great Tree", function()
	topos(CFrame.new(2948, 2282, -7214))
end)

Tp:addButton("Teleport to Temple of Time", function()
	topos(CFrame.new(28286, 14895, 103))
end)

Tp:addButton("Teleport to Acient One", function()
	topos(CFrame.new(28982, 14888, -120))
end)

Tp:addButton("Teleport to Lever Pull", function()
	topos(CFrame.new(28575, 14937, 72))
end)

Tp:addButton("Teleport to Safe Zone", function()
	topos(CFrame.new(28273, 14897, 157))
end)

Tp:addButton("Teleport back to Pvp Zone", function()
	topos(CFrame.new(28767, 14967, -164))
end)

Tp:addButton("Teleport to Clock", function()
	topos(CFrame.new(29552, 15069, -86))
end)

local Trial_Right = Tab.Trial:addSection()
local MTrial = Trial_Right:addMenu("Misc Trial")

MTrial:addToggle("Auto Upgrade Gear", false, function(Value)
	getgenv().BuyGear = Value
	task.spawn(function()
		while getgenv().BuyGear do task.wait()
			FireRemote("UpgradeRace", "Buy")
		end
	end)
end)

MTrial:addToggle("Disable Infinite Stairs", false, function(Value)
	game.Players.LocalPlayer.Character.InfiniteStairs.Disabled = Value
end)

MTrial:addToggle("Auto Activate V3", false, function(Value)
	getgenv().AutoAgility = Value
	task.spawn(function()
		while getgenv().AutoAgility do task.wait()
		game:GetService("ReplicatedStorage").Remotes.CommE:FireServer("ActivateAbility")
		end
	end)
end)

MTrial:addToggle("Auto Activate V4", false, function(Value)
	getgenv().AutoActiveRaceV4 = Value
	task.spawn(function()
		while getgenv().AutoActiveRaceV4 do
			task.wait()
			if Player.Character and Player.Character:FindFirstChild("RaceEnergy") and Player.Character:FindFirstChild("RaceTransformed") then
				if Player.Character.RaceEnergy.Value >= 1 and not Player.Character.RaceTransformed.Value then
					Player.Backpack.Awakening.RemoteFunction:InvokeServer({[1] = true})
				end
			end
		end
	end)
end)

local Upgrades = Trial_Right:addMenu("Upgrades")

Upgrades:addToggle("Auto Race Evolve V2", false, function(Value)
	getgenv().AutoEvoRaceV2 = Value;AutoStartRaceV2()
	if not Value then StopTween() return end
end)


local Travel_Left = Tab.Travel:addSection()
local World = Travel_Left:addMenu("World Travel")

World:addButton("Teleport to World 1", function()
	FireRemote("TravelMain")
end)

World:addButton("Teleport to World 2", function()
	FireRemote("TravelDressrosa")
end)

World:addButton("Teleport to World 3", function()
	FireRemote("TravelZou")
end)

local Island = Travel_Left:addMenu("Island Travel")

local IslandsList = {}
  
if World1 then
IslandsList = {
  "WindMill",
  "Marine",
  "Middle Town",
  "Jungle",
  "Pirate Village",
  "Desert",
  "Snow Island",
  "MarineFord",
  "Colosseum",
  "Sky Island 1",
  "Sky Island 2",
  "Sky Island 3",
  "Prison",
  "Magma Village",
  "Under Water Island",
  "Fountain City"
}
elseif World2 then
IslandsList = {
  "The Cafe",
  "First Spot",
  "Dark Area",
  "Flamingo Mansion",
  "Flamingo Room",
  "Green Zone",
  "Zombie Island",
  "Two Snow Mountain",
  "Punk Hazard",
  "Cursed Ship",
  "Ice Castle",
  "Forgotten Island",
  "Ussop Island"
}
elseif World3 then
IslandsList = {
  "Mansion",
  "Port Town",
  "Great Tree",
  "Castle On The Sea",
  "Hydra Island",
  "Floating Turtle",
  "Haunted Castle",
  "Ice Cream Island",
  "Peanut Island",
  "Cake Island",
  "Candy Cane Island",
  "Tiki Outpost"
}
end

Island:addDropdown("Select Island", "", IslandsList, function(Value)
	getgenv().TeleportIslandSelect = Value
end)

Island:addToggle("Start Traveling", false, function(Value)
    getgenv().TeleportToIsland = Value
    task.spawn(function()
        while getgenv().TeleportToIsland do
            task.wait()
            local Island = getgenv().TeleportIslandSelect
            if World1 then
                local locations = {
                    ["Middle Town"] = CFrame.new(-688, 15, 1585),
                    ["MarineFord"] = CFrame.new(-4810, 21, 4359),
                    ["Marine"] = CFrame.new(-2728, 25, 2056),
                    ["WindMill"] = CFrame.new(889, 17, 1434),
                    ["Desert"] = CFrame.new(944, 21, 4373),
                    ["Snow Island"] = CFrame.new(1298, 87, -1344),
                    ["Pirate Village"] = CFrame.new(-1173, 45, 3837),
                    ["Jungle"] = CFrame.new(-1614, 37, 146),
                    ["Prison"] = CFrame.new(4870, 6, 736),
                    ["Under Water Island"] = CFrame.new(61164, 5, 1820),
                    ["Colosseum"] = CFrame.new(-1535, 7, -3014),
                    ["Magma Village"] = CFrame.new(-5290, 9, 8349),
                    ["Sky Island 1"] = CFrame.new(-4814, 718, -2551),
                    ["Sky Island 2"] = CFrame.new(-4652, 873, -1754),
                    ["Sky Island 3"] = CFrame.new(-7895, 5547, -380)
                }
                if locations[Island] then
                    topos(locations[Island])
                end
            elseif World2 then
                local locations = {
                    ["The Cafe"] = CFrame.new(-382, 73, 290),
                    ["First Spot"] = CFrame.new(-11, 29, 2771),
                    ["Dark Area"] = CFrame.new(3494, 13, -3259),
                    ["Flamingo Mansion"] = CFrame.new(-317, 331, 597),
                    ["Flamingo Room"] = CFrame.new(2285, 15, 905),
                    ["Green Zone"] = CFrame.new(-2258, 73, -2696),
                    ["Zombie Island"] = CFrame.new(-5552, 194, -776),
                    ["Two Snow Mountain"] = CFrame.new(752, 408, -5277),
                    ["Punk Hazard"] = CFrame.new(-5897, 18, -5096),
                    ["Cursed Ship"] = CFrame.new(919, 125, 32869),
                    ["Ice Castle"] = CFrame.new(5505, 40, -6178),
                    ["Forgotten Island"] = CFrame.new(-3050, 240, -10178),
                    ["Ussop Island"] = CFrame.new(4816, 8, 2863)
                }
                if locations[Island] then
                    topos(locations[Island])
                end
            elseif World3 then
                local locations = {
                    ["Mansion"] = CFrame.new(-12471, 374, -7551),
                    ["Port Town"] = CFrame.new(-334, 7, 5300),
                    ["Castle On The Sea"] = CFrame.new(-5073, 315, -3153),
                    ["Hydra Island"] = CFrame.new(4731.27, 1090.18, 1078.17),
                    ["Great Tree"] = CFrame.new(2681, 1682, -7190),
                    ["Floating Turtle"] = CFrame.new(-12528, 332, -8658),
                    ["Haunted Castle"] = CFrame.new(-9517, 142, 5528),
                    ["Ice Cream Island"] = CFrame.new(-902, 79, -10988),
                    ["Peanut Island"] = CFrame.new(-2062, 50, -10232),
                    ["Cake Island"] = CFrame.new(-1897, 14, -11576),
                    ["Candy Cane Island"] = CFrame.new(-1038, 10, -14076),
                    ["Tiki Outpost"] = CFrame.new(-16224, 9, 439)
                }
                if locations[Island] then
                    topos(locations[Island])
                end
            end
        end
    end)
    if not Value then StopTween() return end
end)


local Travel_Right = Tab.Travel:addSection()
local Server = Travel_Right:addMenu("Server Travel")

Server:addTextbox("Enter Job ID", function(Value)
    getgenv().ServerId = Value
end)

Server:addButton("Join Job ID", function()
    getgenv().ServerId = getgenv().ServerId:gsub("`", ""):gsub("lua", "")
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, getgenv().ServerId)
end)

Server:addButton("Copy Current Job ID", function()
	setclipboard(tostring(game.JobId))
end)

local MServer = Travel_Right:addMenu("Misc Travel")

MServer:addButton("Rejoin Server", function()
	game:GetService("TeleportService"):Teleport(game.PlaceId, game.JobId, game:GetService("Players").LocalPlayer)
end)

MServer:addButton("Server Hop, Random Server", function()
	game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
end)

MServer:addButton("Hop to lower Player server", function()
	local MaxPlayers, BestServer = math.huge, nil
	local GameLink = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
	getgenv().FailedServerID = getgenv().FailedServerID or {}
	local function SearchServers()
		local success, response = pcall(function()
			return game:GetService("HttpService"):JSONDecode(game:HttpGetAsync(GameLink))
		end)
		if success and response and response.data then
			for _, server in pairs(response.data) do
				pcall(function()
					if server.id and server.playing and 
					   tonumber(MaxPlayers) > tonumber(server.playing) and 
					   not table.find(getgenv().FailedServerID, server.id) then
						MaxPlayers, BestServer = server.playing, server.id
					end
				end)
			end
		end
	end
	local function FetchServers(cursor)
		SearchServers()
		if cursor then
			GameLink = GameLink:gsub("&cursor=.*", "") .. "&cursor=" .. cursor
			FetchServers(cursor)
		end
	end
	pcall(function()
		SearchServers()
		if response and response.nextPageCursor then
			FetchServers(response.nextPageCursor)
		end
	end)

	wait(0.1)
	if BestServer and BestServer ~= game.JobId and MaxPlayers < #game:GetService("Players"):GetChildren() then
		table.insert(getgenv().FailedServerID, BestServer)
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, BestServer)
	end
	while wait(0.1) do
		pcall(function()
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end
			game.CoreGui.RobloxPromptGui.promptOverlay.DescendantAdded:Connect(function()
				local ErrorPrompt = game.CoreGui.RobloxPromptGui.promptOverlay:FindFirstChild("ErrorPrompt")
				if ErrorPrompt and ErrorPrompt.TitleFrame.ErrorTitle.Text == "Disconnected" then
					if #game.Players:GetPlayers() <= 1 then
						game.Players.LocalPlayer:Kick("\nRejoining...")
						wait(0.1)
						game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
					else
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
					end
				end
			end)
		end)
	end
end)


local Shop_Left = Tab.Shop:addSection()
local Selection = Shop_Left:addMenu("Selection Shop")

local BuyItem = function(item, category)
	local ItemsToBuy = {
		["Frags"] = {
			["Race Rerol"] = {"BlackbeardReward", "Reroll", "2"},
			["Reset Stats"] = {"BlackbeardReward", "Refund", "2"}
		},
		["Ability"] = {
			["Geppo"] = {"BuyHaki", "Geppo"},
			["Buso Haki"] = {"BuyHaki", "Buso"},
			["Soru"] = {"BuyHaki", "Soru"},
			["Observation Haki"] = {"KenTalk", "Buy"}
		},
		["FightingStyle"] = {
			["Black Leg"] = {"BuyBlackLeg"},
			["Electro"] = {"BuyElectro"},
			["Water Kung Fu"] = {"BuyFishmanKarate"},
			["Dragon Claw"] = {"BlackbeardReward", "DragonClaw", "1"},
			["Death Step"] = {"BuyDeathStep"},
			["Sharkman Karate"] = {"BuySharkmanKarate", true},
			["Electric Claw"] = {"BuyElectricClaw"},
			["Dragon Talon"] = {"BuyDragonTalon"},
			["Superhuman"] = {"BuySuperhuman"},
			["God Human"] = {"BuyGodhuman"},
			["Sanguine Art"] = {"BuySanguineArt", true}
		},
		["Gun"] = {
			["Slingshot"] = {"BuyItem", "Slingshot"},
			["Musket"] = {"BuyItem", "Musket"},
			["Flintlock"] = {"BuyItem", "Flintlock"},
			["Refined Slingshot"] = {"BuyItem", "Refined Flintlock"},
			["Refined Flintlock"] = {"BuyItem", "Refined Flintlock"},
			["Cannon"] = {"BuyItem", "Cannon"},
			["Kabucha"] = {"BlackbeardReward", "Slingshot", "1"},
			["Bizarre Rifle"] = {"Ectoplasm", "Buy", 1}
		},
		["Accessory"] = {
			["Black Cape"] = {"Black Cape"},
			["Swordsman Hat"] = {"Swordsman Hat"},
			["Tomoe Ring"] = {"Tomoe Ring"}
		},
		["Sword"] = {
			["Cutlass"] = {"Cutlass"},
			["Katana"] = {"Katana"},
			["Iron Mace"] = {"Iron Mace"},
			["Dual Katana"] = {"Duel Katana"},
			["Triple Katana"] = {"Triple Katana"},
			["Pipe"] = {"Pipe"},
			["Dual-Headed Blade"] = {"Dual-Headed Blade"},
			["Bisento"] = {"Bisento"},
			["Soul Cane"] = {"Soul Cane"},
			["Pole v.2"] = {"ThunderGodTalk"}
		}
	}
	
	local args = ItemsToBuy[category] and ItemsToBuy[category][item]
	if not args then return end
	if category == "Frags" or category == "Ability" or category == "Accessory" then
		FireRemote(unpack(args))
	elseif category == "Sword" then
		wait(0.1)
		FireRemote(item == "Pole v.2" and args or "BuyItem", args)
	elseif category == "Gun" then
		wait(0.5)
		if item == "Kabucha" then
			FireRemote(args[1], args[2], args[3])
			FireRemote(args[1], args[2], "2")
		else
			FireRemote(unpack(args))
		end
	elseif category == "FightingStyle" then
		FireRemote(unpack(args))
		if item == "Dragon Claw" then
			FireRemote("BlackbeardReward", "DragonClaw", "2")
		elseif item == "Sharkman Karate" then
			FireRemote("BuySharkmanKarate")
		elseif item == "Sanguine Art" then
			FireRemote("BuySanguineArt")
		end
	end
end

Selection:addDropdown("Select Ability", 'Geppo', {'Geppo', 'Buso Haki', 'Soru', 'Observation Haki'}, function(Value)
	getgenv().BuyAbility = Value
end)

Selection:addButton("Buy Ability", function()
	if getgenv().BuyAbility then
		BuyItem(getgenv().BuyAbility, "Ability")
	end
end)

Selection:addDropdown("Select Fighting Style", 'Black Leg', {'Black Leg', 'Electro', 'Water Kung Fu', 'Dragon Claw','Death Step', 'Sharkman Karate', 'Electric Claw', 'Dragon Talon', 'Superhuman', 'God Human', 'Sanguine Art'}, function(Value)
	getgenv().BuyFighting = Value
end)

Selection:addButton("Buy Fighting Style", function()
	if getgenv().BuyFighting then
		BuyItem(getgenv().BuyFighting, "FightingStyle")
	end
end)

Selection:addDropdown("Select Gun", 'Slingshot', {'Slingshot', 'Musket', 'Flintlock', 'Refined Slingshot', 'Refined Flintlock', 'Cannon', 'Kabucha', 'Bizarre Rifle'}, function(Value)
	getgenv().GunSelect = Value
end)

Selection:addButton("Buy Gun", function()
	if getgenv().GunSelect then
		BuyItem(getgenv().GunSelect, "Gun")
	end
end)

Selection:addDropdown("Select Accessory", 1, {'Black Cape', 'Swordsman Hat', 'Tomoe Ring'}, function(Value)
	getgenv().BuyAccessories = Value
end)

Selection:addButton("Buy Gun", function()
	if getgenv().BuyAccessories then
		BuyItem(getgenv().BuyAccessories, "Accessory")
	end
end)

local ItemShop = Shop_Left:addMenu("Item Shop")

ItemShop:addToggle("Buy Haki Color", false, function(Value)
	getgenv().AutoBuyEnchancementColor = Value
	task.spawn(function()
		while getgenv().AutoBuyEnchancementColor do task.wait(0.5)
		for i = 1, 2 do
			FireRemote("ColorsDealer", tostring(i))
		end
	end
  end)
end)

ItemShop:addToggle("Buy Legendary Sword", false, function(Value)
	getgenv().BuyLegendSword = Value
	task.spawn(function()
		while getgenv().BuyLegendSword do task.wait()
		for i = 1, 3 do
			FireRemote("LegendarySwordDealer", tostring(i))
			end
		end
	end)
end)

ItemShop:addToggle("Buy True Triple Katana", false, function(Value)
	getgenv().BuyTTK = Value
	task.spawn(function()
		while getgenv().BuyTTK do task.wait()
			FireRemote("MysteriousMan", "2")
		end
	end)
end)

local Shop_Right = Tab.Shop:addSection()
local RaceShop = Shop_Right:addMenu("Race Shop")

RaceShop:addButton("Cyborg Race", function()
	FireRemote("CyborgTrainer", "Buy")
end)

RaceShop:addButton("Ghoul Race", function()
	FireRemote("Ectoplasm", "BuyCheck", 4)
	FireRemote("Ectoplasm", "Change", 4)
end)

local FragShop = Shop_Right:addMenu("Fragment Shop")

FragShop:addButton("Reroll Race", function()
	BuyItem("Race Rerol", "Frags")
end)

FragShop:addButton("Reset Player Stats", function()
	BuyItem("Reset Stats", "Frags")
end)

local Misc_Left = Tab.Misc:addSection()
local TeamSelection = Misc_Left:addMenu("Team Selection")

TeamSelection:addButton("Join Marines Team", function()
	FireRemote("SetTeam","Marines")
end)

TeamSelection:addButton("Join Pirates Team", function()
	FireRemote("SetTeam","Pirates")
end)

local OpenGuis = Misc_Left:addMenu("Menu Openings")

OpenGuis:addButton("Open Title Name", function()
	FireRemote(unpack({[1] = "getTitles"}))
	Player.PlayerGui.Main.Titles.Visible = true
end)

OpenGuis:addButton("Open Bartender", function()
	require(game.ReplicatedStorage.Controllers.UI.JuiceWindow):Open({
		["Window"] = "First",
		["Mode"] = "Bartender"
	})
end)
OpenGuis:addButton("Open Juice Window", function()
	require(game.ReplicatedStorage.Controllers.UI.JuiceWindow):Open({
		["Window"] = "First"
	})
end)

OpenGuis:addButton("Open Juice Window Shop", function()
	require(game.ReplicatedStorage.Controllers.UI.JuiceWindow):Open({
		["Window"] = "First",
		["Mode"] = "Shop"
	})
end)

OpenGuis:addButton("Lookup", function()
require(game.ReplicatedStorage.Modules.Create.PlayerLookupComponent)({
		["Filter"] = function(arg1, arg2)
			return arg1._Category == "Server" and not game.Players:GetPlayerByUserId(arg2.UserId) and true or false
		end,
			["CategoryChanged"] = function(arg1)
				print((("CategoryChanged: %*"):format(arg1._Category)))
				if arg1._Category == "Server" then
					arg1:ChangeDescription("Choose a player to inspect")
					elseif arg1._Category == "Global" then
					arg1:ChangeDescription("Search for a player to inspect")
				end
			end,
	["MouseButton1Click"] = function(_, arg2)
			print("MouseButton1Click", arg2)
		end
	}):ChangeTitle("Inspect"):ChangeDescription("Choose a player to inspect."):EnableCategory({ "Server", "Global" }):ChangeCategory("Server"):Connect()
end)


OpenGuis:addButton("Open Awakenings", function()
	Player.PlayerGui.Main.AwakeningToggler.Visible = true
end)

local Misc_Right = Tab.Misc:addSection()
local ClientSelection = Misc_Right:addMenu("Players Clients")

ClientSelection:addSlider("Walk Speed", 50, 10000, 50, function(Value)
	getgenv().WalkSpeed = Value
	if getgenv().WalkSpeed then
        local Player = game:service'Players'.LocalPlayer
        Player.Character.Humanoid:GetPropertyChangedSignal'WalkSpeed':Connect(function()
            Player.Character.Humanoid.WalkSpeed = getgenv().WalkSpeed
        end)
        Player.Character.Humanoid.WalkSpeed = getgenv().WalkSpeed
    end
end)

ClientSelection:addSlider("Jump Power", 50, 10000, 50, function(Value)
	getgenv().JumpPower = Value
    if getgenv().JumpPower then
        game:GetService("Players").LocalPlayer.Character.Humanoid.JumpPower = getgenv().JumpPower
    end
end)

local transparent = false
function XrayView(Instance)
if Instance then
  for _,i in pairs(workspace:GetDescendants()) do
	if i:IsA("BasePart") and not i.Parent:FindFirstChild("Humanoid") and not i.Parent.Parent:FindFirstChild("Humanoid") then
	  i.LocalTransparencyModifier = 0.7
	end
  end
else
  for _,i in pairs(workspace:GetDescendants()) do
	if i:IsA("BasePart") and not i.Parent:FindFirstChild("Humanoid") and not i.Parent.Parent:FindFirstChild("Humanoid") then
	  i.LocalTransparencyModifier = 0
	end
  end
end
end

ClientSelection:addToggle("X-ray Vision", false, function(Value)
	NoWorld = Value
	if NoWorld == true then
	  transparent = true
	  XrayView(transparent)
	elseif NoWorld == false then
	  transparent = false
	  XrayView(transparent)
	end
end)

ClientSelection:addToggle("White Screen", false, function(Value)
    getgenv().White_Screen = Value
    if getgenv().White_Screen then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    else
        game:GetService("RunService"):Set3dRenderingEnabled(true)
    end
end)

ClientSelection:addToggle("Black Screen", false, function(Value)
	getgenv().BlackScreen = Value
end)

spawn(function()
	while wait() do
		if getgenv().BlackScreen then
			game:GetService("Players").LocalPlayer.PlayerGui.Main.Blackscreen.Size = UDim2.new(500, 0, 500, 500)
		else
			game:GetService("Players").LocalPlayer.PlayerGui.Main.Blackscreen.Size = UDim2.new(1, 0, 500, 500)
		end
	end
end)

ClientSelection:addButton("Click Teleport Tool", function()
	local plr = game:GetService("Players").LocalPlayer
	local mouse = plr:GetMouse()
	local tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.Name = "Teleport Tool"
	tool.Activated:Connect(function()
	local root = plr.Character.HumanoidRootPart
	local pos = mouse.Hit.Position + Vector3.new(0,2.5,0)
	local offset = pos-root.Position
		root.CFrame = root.CFrame + offset
	end)
	tool.Parent = plr.Backpack
end)


ClientSelection:addToggle("Remove Fog", false, function(Value)
	getgenv().NoFog = Value
	task.spawn(function()
		while wait() do
			pcall(function()
				if getgenv().NoFog then
					game.Lighting.FogEnd = math.huge
					if game:GetService("Lighting"):FindFirstChild("FantasySky") then
						game:GetService("Lighting").FantasySky:Destroy()
					elseif game:GetService("Lighting"):FindFirstChild("LightingLayers") then
						game:GetService("Lighting").LightingLayers:Destroy()
					elseif game:GetService("Lighting"):FindFirstChild("Sky") then
						game:GetService("Lighting").Sky:Destroy()
					elseif game:GetService("Lighting").SeaTerrorCC then
						game:GetService("Lighting").SeaTerrorCC:Destroy()
					end
				else
					game.Lighting.FogEnd = 2500
				end
			end)
		end
	end)
end)

ClientSelection:addButton("Force FPS BOOST", function()
	local Terrain = workspace:FindFirstChildOfClass('Terrain')
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 0
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	settings().Rendering.QualityLevel = 1
	for i,v in pairs(game:GetDescendants()) do
		if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
			v.Material = "Plastic"
			v.Reflectance = 0
		elseif v:IsA("Decal") then
			v.Transparency = 1
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Lifetime = NumberRange.new(0)
		elseif v:IsA("Explosion") then
			v.BlastPressure = 1
			v.BlastRadius = 1
		end
	end
	for i,v in pairs(Lighting:GetDescendants()) do
		if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
			v.Enabled = false
		end
	end
	workspace.DescendantAdded:Connect(function(child)
		task.spawn(function()
			if child:IsA('ForceField') then
				RunService.Heartbeat:Wait()
				child:Destroy()
			elseif child:IsA('Sparkles') then
				RunService.Heartbeat:Wait()
				child:Destroy()
			elseif child:IsA('Smoke') or child:IsA('Fire') then
				RunService.Heartbeat:Wait()
				child:Destroy()
			end
		end)
	end)
end)
