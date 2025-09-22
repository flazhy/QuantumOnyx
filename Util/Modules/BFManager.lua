
local AutoFarm = {}
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
