VM["combat/fastattack.lua"] = function()
    local Config = {
        AttackDistance = 70,
        AttackMobs = true,
        AttackPlayers = true,
        AttackCooldown = 0,
        ComboResetTime = 0.1,
        MaxCombo = 10,
        HitboxLimbs = {"RightLowerArm","RightUpperArm","LeftLowerArm","LeftUpperArm","RightHand","LeftHand"},
        AutoClickEnabled = true
    }
    
    local FastAttack = {}
    FastAttack.__index = FastAttack
    
    function FastAttack.new()
        local self = setmetatable({
            Debounce = 0,
            ComboDebounce = 0,
            M1Combo = 0,
            EnemyRootPart = nil,
            Connections = {},
        }, FastAttack)
        pcall(function()
            self.CombatFlags  = requireVM("modules/flags").COMBAT_REMOTE_THREAD
            local LocalScript = Player:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
            if LocalScript and getsenv then
                self.HitFunction = getsenv(LocalScript)._G.SendHitsToServer
            end
        end)
        return self
    end
    
    function FastAttack:IsAlive(entity)
        local humanoid = entity and entity:FindFirstChildOfClass("Humanoid")
        return humanoid and humanoid.Health > 0
    end
    
    function FastAttack:CheckStun(Character, Humanoid, ToolTip)
        local Stun = Character:FindFirstChild("Stun")
        local Busy = Character:FindFirstChild("Busy")
        if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
            return false
        elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
            return false
        end
        return true
    end
    
    function FastAttack:GetBladeHits(Character, Distance)
        local Position  = Character:GetPivot().Position
        local BladeHits = {}
        Distance = Distance or Config.AttackDistance
        local function ProcessTargets(Folder)
            for _, Enemy in ipairs(Folder:GetChildren()) do
                if Enemy ~= Character and self:IsAlive(Enemy) then
                    local BasePart = Enemy:FindFirstChild(Config.HitboxLimbs[math.random(#Config.HitboxLimbs)]) or Enemy:FindFirstChild("HumanoidRootPart")
                    if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                        if not self.EnemyRootPart then
                            self.EnemyRootPart = BasePart
                        else
                            table.insert(BladeHits, {Enemy, BasePart})
                        end
                    end
                end
            end
        end
        if Config.AttackMobs and quantum.attackmobs then ProcessTargets(Workspace.Enemies) end
        if Config.AttackPlayers and quantum.attackplayers then ProcessTargets(Workspace.Characters) end
        return BladeHits
    end
    
    function FastAttack:GetCombo()
        local Combo = (tick() - self.ComboDebounce) <= Config.ComboResetTime and self.M1Combo or 0
        Combo = Combo >= Config.MaxCombo and 1 or Combo + 1
        self.ComboDebounce = tick()
        self.M1Combo = Combo
        return Combo
    end
    
    function FastAttack:UseNormalClick(Character, Humanoid, Cooldown)
        self.EnemyRootPart = nil
        local BladeHits = self:GetBladeHits(Character)
        if self.EnemyRootPart then
            RegisterAttack:FireServer(Cooldown)
            if self.CombatFlags and self.HitFunction then
                self.HitFunction(self.EnemyRootPart, BladeHits)
            else
                RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
            end
        end
    end
    
    function FastAttack:UseFruitM1(Character, Equipped, Combo)
        local Targets = self:GetBladeHits(Character)
        if not Targets[1] then return end
        local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
        Equipped.LeftClickRemote:FireServer(Direction, Combo)
    end
    
    function FastAttack:Attack()
        if not Config.AutoClickEnabled or (tick() - self.Debounce) < Config.AttackCooldown then return end
        local Character = Player.Character
        if not Character or not self:IsAlive(Character) then return end
        local Humanoid = Character.Humanoid
        local Equipped = Character:FindFirstChildOfClass("Tool")
        if not Equipped then return end
        local ToolTip = Equipped.ToolTip
        if not table.find({"Melee","Blox Fruit","Sword","Gun"}, ToolTip) then return end
        local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or Config.AttackCooldown
        if not self:CheckStun(Character, Humanoid, ToolTip) then return end
        local Combo = self:GetCombo()
        Cooldown = Cooldown + (Combo >= Config.MaxCombo and 0.05 or 0)
        self.Debounce = Combo >= Config.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
        if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
            self:UseFruitM1(Character, Equipped, Combo)
        else
            self:UseNormalClick(Character, Humanoid, Cooldown)
        end
    end
    
    local AttackInstance = FastAttack.new()
    table.insert(AttackInstance.Connections, RunService.Stepped:Connect(function()
        if quantum.AutoAttack then
            AttackInstance:Attack()
        end
    end))

    return FastAttack
end
