local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

getgenv().quantum = getgenv().quantum or {
    AutoAttack = true,
    attackmobs = true,
    attackplayers = true
}

local Config = {
    AttackDistance = 70,
    AttackCooldown = 0,
    ComboResetTime = 0.1,
    MaxCombo = 10,
    HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand", "Head", "UpperTorso", "LowerTorso" },
    AutoClickEnabled = true
}

local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
    local self = setmetatable({}, FastAttack)

    self.LastAttackTick = 0
    self.LastComboTick = 0
    self.CurrentCombo = 0
    self.Connections = {}
    self.HitFunction = nil
    self.RegisterAttack = nil
    self.RegisterHit = nil

    self:SetupRemotes()
    return self
end

function FastAttack:SetupRemotes()
    task.spawn(function()
        for _, script in ipairs(Player.PlayerScripts:GetChildren()) do
            if script:IsA("LocalScript") then
                local env = getfenv(script)
                if env and typeof(env._G) == "table" and typeof(env._G.SendHitsToServer) == "function" then
                    self.HitFunction = env._G.SendHitsToServer
                    break
                end
            end
        end
    end)

    local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
    if tool then
        self.RegisterAttack = tool:FindFirstChild("RegisterAttack") or tool:FindFirstChild("AttackRemote")
        self.RegisterHit = tool:FindFirstChild("RegisterHit") or tool:FindFirstChild("HitRemote")
    end
end

function FastAttack:IsAlive(char)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and humanoid.RootPart
end

function FastAttack:IsStunned(char, tooltip)
    if not char then return true end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local stun = char:FindFirstChild("Stun")
    local busy = char:FindFirstChild("Busy")

    if humanoid and humanoid.Sit and (tooltip == "Sword" or tooltip == "Melee" or tooltip == "Blox Fruit") then
        return true
    end
    if (stun and stun.Value > 0) or (busy and busy.Value) then
        return true
    end
    return false
end

function FastAttack:GetBestTargets(distance)
    local character = Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end

    local rootPos = character:GetPivot().Position
    local targets = {}
    distance = distance or Config.AttackDistance

    local function scan(folder)
        if not folder then return end
        for _, enemy in ipairs(folder:GetChildren()) do
            if enemy == character or not self:IsAlive(enemy) then continue end

            local part = enemy:FindFirstChild("HumanoidRootPart")
            if not part then continue end

            if (rootPos - part.Position).Magnitude <= distance then
                table.insert(targets, {enemy, part})
            end
        end
    end

    if Config.AttackMobs and getgenv().quantum.attackmobs then
        scan(Workspace.Enemies)
    end
    if Config.AttackPlayers and getgenv().quantum.attackplayers then
        scan(Workspace.Characters)
    end

    -- Sort by distance (closest first)
    table.sort(targets, function(a, b)
        return (rootPos - a[2].Position).Magnitude < (rootPos - b[2].Position).Magnitude
    end)

    return targets
end

function FastAttack:GetComboCount()
    if (tick() - self.LastComboTick) > Config.ComboResetTime then
        self.CurrentCombo = 0
    end
    self.CurrentCombo = math.min(self.CurrentCombo + 1, Config.MaxCombo)
    self.LastComboTick = tick()
    return self.CurrentCombo
end

function FastAttack:SendNormalAttack(targets, cooldown)
    if #targets == 0 then return end

    local primaryTarget = targets[1][2]  -- Closest HumanoidRootPart

    -- Prefer real hit function if available
    if self.HitFunction then
        local hitParts = {}
        for _, v in ipairs(targets) do
            local limb = v[1]:FindFirstChild(Config.HitboxLimbs[math.random(#Config.HitboxLimbs)])
            if limb then table.insert(hitParts, limb) end
        end
        task.spawn(self.HitFunction, primaryTarget, hitParts)
    elseif self.RegisterHit then
        self.RegisterHit:FireServer(primaryTarget, targets)
    end

    if self.RegisterAttack then
        self.RegisterAttack:FireServer(cooldown or 0)
    end
end

function FastAttack:SendFruitAttack(equipped, combo)
    local targets = self:GetBestTargets()
    if #targets == 0 or not equipped:FindFirstChild("LeftClickRemote") then return end

    local direction = (targets[1][2].Position - Player.Character:GetPivot().Position).Unit
    equipped.LeftClickRemote:FireServer(direction, combo)
end

function FastAttack:Attack()
    if not Config.AutoClickEnabled or not getgenv().quantum.AutoAttack then return end
    if tick() - self.LastAttackTick < Config.AttackCooldown then return end

    local character = Player.Character
    if not character or not self:IsAlive(character) then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    local tooltip = tool.ToolTip or ""
    if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, tooltip) then return end

    if self:IsStunned(character, tooltip) then return end

    local combo = self:GetComboCount()
    local extraDelay = (combo >= Config.MaxCombo and tooltip ~= "Gun") and 0.05 or 0
    local cooldown = (tool:FindFirstChild("Cooldown") and tool.Cooldown.Value) or Config.AttackCooldown
    cooldown += extraDelay

    self.LastAttackTick = tick() + extraDelay

    local targets = self:GetBestTargets()

    if tooltip == "Blox Fruit" and tool:FindFirstChild("LeftClickRemote") then
        self:SendFruitAttack(tool, combo)
    else
        self:SendNormalAttack(targets, cooldown)
    end
end

function FastAttack:Start()
    self.Connections[#self.Connections + 1] = RunService.Heartbeat:Connect(function()
        task.spawn(function() self:Attack() end)
    end)
end

function FastAttack:Stop()
    for _, conn in ipairs(self.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    self.Connections = {}
end

local FastAttackInstance = FastAttack.new()
FastAttackInstance:Start()

return FastAttackInstance
