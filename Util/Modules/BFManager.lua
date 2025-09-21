local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local CommF_ = ReplicatedStorage.Remotes.CommF_

local M = {}

function M.FireRemote(...)
	return CommF_:InvokeServer(...)
end

local Character, HRP
local StopFlag = false

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
	for _, part in ipairs((char or Character):GetDescendants()) do
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
end

task.spawn(function()
	while task.wait(0.2) do
		if ShouldNoclip() then
			if not Character or not HRP or not HRP.Parent then
				UpdateCharacter()
			end
			EnableNoclip()
			DisableCollisions()
		end
	end
end)

local CachedLocations = {
	[2753915549] = {
		Vector3.new(-4652, 873, -1754),
		Vector3.new(-7895, 5547, -380),
		Vector3.new(61164, 5, 1820),
		Vector3.new(3865, 5, -1926),
	},
	[4442272183] = {
		Vector3.new(-317, 331, 597),
		Vector3.new(2283, 15, 867),
		Vector3.new(923, 125, 32853),
		Vector3.new(-6509, 83, -133),
	},
	[7449423635] = {
		Vector3.new(-12471, 374, -7551),
		Vector3.new(5756, 610, -282),
		Vector3.new(-5092, 315, -3130),
		Vector3.new(-12001, 332, -8861),
		Vector3.new(5319, 23, -93),
		Vector3.new(28286, 14897, 103),
	}
}

local function GetTPPos(targetPos)
	local teleports = CachedLocations[game.PlaceId]
	if not teleports then return end

	local nearest, minDist
	for _, pos in ipairs(teleports) do
		local dist = (pos - targetPos).Magnitude
		if not minDist or dist < minDist then
			minDist, nearest = dist, pos
		end
	end
	return nearest
end

local function RequestEntrance(pos)
	M.FireRemote("requestEntrance", pos)
	if HRP then HRP.CFrame += Vector3.new(0, 30, 0) end
	task.wait(0.5)
end

local function Tween(goal)
	if not HRP then return end
	local from = HRP.CFrame
	local targetPos = goal.Position
	local portal = GetTPPos(targetPos)

	if portal and (targetPos - from.Position).Magnitude > (targetPos - portal).Magnitude + 300 then
		RequestEntrance(portal)
		task.wait(0.1)
		from = HRP.CFrame
	end

	local start, totalDistance = tick(), (targetPos - from.Position).Magnitude
	while not StopFlag do
		local speed = tonumber(getgenv().TweenSpeed or 300)
		local alpha = math.clamp(((tick() - start) * speed) / totalDistance, 0, 1)
		HRP:PivotTo(from:Lerp(goal, alpha))
		if alpha >= 1 or (targetPos - HRP.Position).Magnitude <= 5 then break end
		task.wait()
	end

	if not StopFlag then HRP:PivotTo(goal) end
end

function M.topos(target)
	StopFlag = false
	Tween(typeof(target) == "Vector3" and CFrame.new(target) or target)
end

function M.StopTween()
	StopFlag = true
	if HRP then
		HRP.CFrame += Vector3.new(0, math.random(1, 3) / 100, 0)
		local clip = HRP:FindFirstChild("BodyClip")
		if clip then clip:Destroy() end
	end
end

return M
