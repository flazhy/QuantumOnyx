

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local function W(c, n, t) return c:WaitForChild(n, t or 60) end
local Modules = W(ReplicatedStorage, "Modules")
local Net = W(Modules, "Net")
local RegisterAttack = W(Net, "RE/RegisterAttack")
local RegisterHit = W(Net, "RE/RegisterHit")

getgenv().quantum = getgenv().quantum or {
    AutoAttack = true,
    attackmobs = true,
    attackplayers = true,
    FastAttackDistance = 70
}

local FastAttack = {
    Combo = 0,
    LastCombo = 0,
    LastAttack = 0,
    RealHitFunc = nil,
    Connections = {}
}

task.spawn(function()
    for _, v in Player.PlayerScripts:GetDescendants() do
        if v:IsA("LocalScript") then
            local env = getfenv(v)
            if env and env._G and typeof(env._G.SendHitsToServer) == "function" then
                FastAttack.RealHitFunc = env._G.SendHitsToServer
                break
            end
        end
    end
end)

local Limbs = {"RightHand","LeftHand","RightLowerArm","LeftLowerArm","Head","UpperTorso"}

local function IsAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart")
end

local function GetTargets()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return {} end
    local rootPos = char:GetPivot().Position
    local targets = {}

    local function Scan(folder)
        if not folder then return end
        for _, ent in folder:GetChildren() do
            if ent == char or not IsAlive(ent) then continue end
            local hrp = ent.HumanoidRootPart
            if (rootPos - hrp.Position).Magnitude <= quantum.FastAttackDistance then
                local limb = ent:FindFirstChild(Limbs[math.random(#Limbs)]) or hrp
                table.insert(targets, {Root = hrp, Limb = limb})
            end
        end
    end

    if quantum.attackmobs then Scan(Workspace.Enemies) end
    if quantum.attackplayers then Scan(Workspace.Characters) end

    table.sort(targets, function(a,b)
        return (rootPos - a.Root.Position).Magnitude < (rootPos - b.Root.Position).Magnitude
    end)

    return targets
end

local function GetCombo()
    if tick() - FastAttack.LastCombo > 0.11 then
        FastAttack.Combo = 0
    end
    FastAttack.Combo = math.min(FastAttack.Combo + 1, 10)
    FastAttack.LastCombo = tick()
    return FastAttack.Combo
end

local function Attack()
    if not quantum.AutoAttack then return end
    if tick() - FastAttack.LastAttack < 0.01 then return end

    local char = Player.Character
    if not char or not IsAlive(char) then return end
    if char:FindFirstChild("Stun") and char.Stun.Value > 0 or char:FindFirstChild("Busy") then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local tip = tool.ToolTip or ""
    if not string.find(tip, "Sword") and not string.find(tip, "Melee") and not string.find(tip, "Blox Fruit") and not string.find(tip, "Gun") then return end

    local targets = GetTargets()
    if #targets == 0 then return end

    local combo = GetCombo()
    local isMax = combo >= 10

    FastAttack.LastAttack = tick() + (isMax and tip ~= "Gun" and 0.045 or 0)

    local parts = {}
    for _, t in targets do table.insert(parts, t.Limb) end
    if FastAttack.RealHitFunc then
        task.spawn(FastAttack.RealHitFunc, targets[1].Root, parts)
    else
        RegisterHit:FireServer(targets[1].Root, parts)
    end
    local cd = tool:FindFirstChild("Cooldown") and tool.Cooldown.Value or 0
    if isMax then cd += 0.05 end
    RegisterAttack:FireServer(cd)
    if tip == "Blox Fruit" then
        local remote = tool:FindFirstChild("LeftClickRemote")
        if remote then
            local dir = (targets[1].Root.Position - char:GetPivot().Position).Unit
            remote:FireServer(dir, combo)
        end
    end
end
FastAttack.Connections[#FastAttack.Connections+1] = RunService.Heartbeat:Connect(function()
    if quantum.AutoAttack then
        task.spawn(Attack)
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(3)
end)

return FastAttack
