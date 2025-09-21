local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local CommF_ = game:GetService("ReplicatedStorage").Remotes.CommF_

local M = {}

function M.FireRemote(...)
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
	"KillAllBosses", "AutoTyrantOfTheSkies", "AutoSecondSea", "AutoPainCorrupt", 
	"AutoRipCommander", "CelestialSoldier", "CelestialDomain"
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
	M.FireRemote("requestEntrance", pos)
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
		local elapsed = tick() - start
		local alpha = math.clamp((elapsed * speed) / totalDistance, 0, 1)
		local newCF = from:Lerp(goal, alpha)
		HRP:PivotTo(newCF)
		if (targetPos - HRP.Position).Magnitude <= 5 or alpha >= 1 then
			break
		end
		task.wait()
	end
	if not StopFlag then
		HRP:PivotTo(goal)
	end
end

function M.topos(target)
	StopFlag = false
	local goal = typeof(target) == "Vector3" and CFrame.new(target) or target
	Tween(goal)
end

function M.StopTween()
	StopFlag = true
	if HRP then
		HRP.CFrame = HRP.CFrame + Vector3.new(0, math.random(1, 3) / 100, 0)
		local clip = HRP:FindFirstChild("BodyClip")
		if clip then
			clip:Destroy()
		end
	end
end

local Type, PosY = 1, 0
task.spawn(function()
	while true do
		Type = 1
		if Type == 1 then
			local Pos = Vector3.new(0, PosY, 0)
		end
		task.wait(0.1)
	end
end)

return M
