local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService =game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local lp = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")
local PlayerLevel = lp:WaitForChild("Data"):WaitForChild("Level")
local Enemies = Workspace:WaitForChild("Enemies")
local Map = Workspace:WaitForChild("Map")
local WorldOrigin = Workspace:WaitForChild("_WorldOrigin")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")

pcall(function()
    local Reparent = require(ReplicatedStorage:FindFirstChild("Reparent"))
    if Reparent and Reparent.Unparent then
        Reparent.Unparent = function() end
    end
end)

local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")

local CombatController = require(ReplicatedStorage.Controllers.CombatController)
local Bodyparts = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"}
local CombatUtils = require(ReplicatedStorage.Modules.CombatUtil)
local Debounce = 0
local ComboDebounce = 0
local M1Combo = 0
function AttackAnim(Cooldown)
	local Animation = CombatUtils:GetMovesetAnimCache(lp.Character.Humanoid)
	local Weapon = CombatUtils:GetWeaponName(lp.Character:FindFirstChild("EquippedWeapon"))
	local PureWeapon = CombatUtils:GetPureWeaponName(Weapon)
	local WeaponData = CombatUtils:GetWeaponData(Weapon)
	local Moveset = PureWeapon .. "-basic" .. math.random(1, #WeaponData.Moveset.Basic)

	local anim = Animation[Moveset]
	local speed = (anim:GetAttribute("SpeedMult") or 1) * 5
	RegisterAttack:FireServer(Cooldown or 0)
	if not getgenv().RemoveAnimationFast then
		anim:Play(0, 1, speed)
		anim.TimePosition = 0.01
	end
end
function GetHits()
	local Bladehits = {}
	local RandomPart = Bodyparts[math.random(#Bodyparts)]
	
	if getgenv().attackmobs then
		local enemies = workspace.Enemies:GetChildren()
		for i = 1, #enemies do
			local v = enemies[i]
			if v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
				if lp:DistanceFromCharacter(v.HumanoidRootPart.Position) <= 70 then
					local Target = v:FindFirstChild(RandomPart) or v.HumanoidRootPart
					table.insert(Bladehits, {v, Target})
				end
			end
		end
	end
	if getgenv().attackplayers then
		for _, v in next,workspace.Characters:GetChildren() do
			if v ~= lp.Character and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 and not lp:GetAttribute("PvpDisabled") then
				if lp:DistanceFromCharacter(v.HumanoidRootPart.Position) <= 70 then
					local Target = v:FindFirstChild(RandomPart) or v.HumanoidRootPart
					table.insert(Bladehits, {v, Target})
				end
			end
		end
	end
	return Bladehits
end

local function GetCombo()
	local SinceLast = tick() - ComboDebounce
	local Combo = (SinceLast <= 0.5) and M1Combo or 0
		Combo = (Combo >= 4) and 1 or Combo + 1
		ComboDebounce = tick()
		M1Combo = Combo
	return Combo
end
local HitFunction
local LocalScript = lp:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
if LocalScript and getsenv then
    HitFunction = getsenv(LocalScript)._G.SendHitsToServer
end
function FastAttack()
	if not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
    if tool then
        local usedtool = tool.ToolTip
		local Cooldown = math.min(tool:FindFirstChild("Cooldown") and tool.Cooldown.Value or 0, 0.05)
        if table.find({"Melee","Blox Fruit","Sword"}, usedtool) then
			if getgenv().FastSettings == "Fast Attack" then
				local hits = GetHits()
				if #hits > 0 then
					local Combo = GetCombo()
					Cooldown = Cooldown + ((Combo >= 4) and 0.05 or 0)
					Debounce = (Combo >= 4 and usedtool ~= "Gun") and tick() or tick()
					local SendHits = coroutine.create(HitFunction)
					local closest = hits[1][2]
					if tool:FindFirstChild("LeftClickRemote") then
						local Leftremote = tool:FindFirstChild('LeftClickRemote')
						if closest then
							Leftremote:FireServer((closest.Position - lp.Character.HumanoidRootPart.Position).Unit, Combo)
						else
							Leftremote:FireServer(Vector3.new(0.01, - 500, 0.01), Combo, true)
						end
					end
					if HitFunction then
						AttackAnim(Cooldown)
						coroutine.resume(SendHits, closest, hits)
					end
				end
			elseif getgenv().FastSettings == "Legit Attack" then
				local enemies = Enemies:GetChildren()
				for i = 1, #enemies do
					local v = enemies[i]
					if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
						local root = v:FindFirstChild("HumanoidRootPart")
						local body = v:FindFirstChild("UpperTorso")
						if root then
							if lp:DistanceFromCharacter(root.Position) <= 50 then
								body.Size = Vector3.new(70, 70, 70)
								body.Transparency = 1
								body.CanCollide = false
								body.Massless = true
								local tool = lp.Character:FindFirstChildWhichIsA("Tool")
								if tool then
									CombatController:Attack(tool)
								end
							end
						end
					end
				end
			end
        end
    end
end

--QUANTUM ONYX - FLAZHY PUBLIC FAST ATTACK
