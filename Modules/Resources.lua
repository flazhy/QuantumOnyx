local VM = {}
local VM_CACHE = {}

local function requireVM(path)
    path = path:gsub("\\","/")
    if VM_CACHE[path] then return VM_CACHE[path] end
    local moduleFn = VM[path]
    if not moduleFn then error("Module not found: "..path) end
    local result = moduleFn()
    VM_CACHE[path] = result
    return result
end
local quantum = {} or getgenv()
VM["Modules/Resources.lua"] = function()
    local Config = {
        MaxForce = 1e9,
        MaxTorque = 1e9,
        Responsiveness = 200,
        YOffset = -3,
        DistanceOffset = 5,
        SafeHeightOffset = 10
    }
    
    local BaseAttachment = Instance.new("Attachment")
    
    local _attachments = {}
    local _alignments = {}
    local _lastSimulationUpdate = 0
    
    function GetAttachment(root)
        local attachment = root:FindFirstChild("MobBringAttachment")
        if not attachment then
            return CreateAttachment(root)
        end
        
        local alignPos = attachment:FindFirstChild("MobAlignPosition")
        local alignOri = attachment:FindFirstChild("MobAlignOrientation")
        
        if not (alignPos and alignOri) then
            attachment:Destroy()
            return CreateAttachment(root)
        end
        
        _attachments[root] = attachment
        _alignments[root] = {alignPos, alignOri}
        
        return attachment, alignPos, alignOri
    end
    
    function CreateAttachment(root)
        local attachment = BaseAttachment:Clone()
        attachment.Name = "MobBringAttachment"
        attachment.Parent = root
        
        local alignPos = Instance.new("AlignPosition")
        alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPos.MaxForce = Config.MaxForce
        alignPos.Responsiveness = Config.Responsiveness
        alignPos.Name = "MobAlignPosition"
        alignPos.Parent = attachment
        alignPos.Attachment0 = attachment
        
        local alignOri = Instance.new("AlignOrientation")
        alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignOri.MaxTorque = Config.MaxTorque
        alignOri.Responsiveness = Config.Responsiveness
        alignOri.Name = "MobAlignOrientation"
        alignOri.Parent = attachment
        alignOri.Attachment0 = attachment
        
        _attachments[root] = attachment
        _alignments[root] = {alignPos, alignOri}
        
        return attachment, alignPos, alignOri
    end
    
    local function OrphanedAttachments()
        for root, attachment in pairs(_attachments) do
            if not root:IsDescendantOf(workspace) or not attachment:IsDescendantOf(root) then
                pcall(function() attachment:Destroy() end)
                _attachments[root] = nil
                _alignments[root] = nil
            end
        end
    end
    
    local function CalculatePosition(plrPos, targetPos, targetRoot)
        local distanceOffset = (plrPos - targetPos).Unit * Config.DistanceOffset
        local baseY = workspace.FallenPartsDestroyHeight + Config.SafeHeightOffset < targetPos.Y and targetPos.Y or targetPos.Y
        local offset = Vector3.new(0, Config.YOffset, 0)
        
        return Vector3.new(targetPos.X + distanceOffset.X, baseY, targetPos.Z + distanceOffset.Z ) + offset
    end
    
    local function IsValidTarget(targetRoot, targetHumanoid)
        return targetRoot and targetHumanoid and targetHumanoid.Health > 0
    end
    
    function BringEnemies(__index)
        if not quantum.BringMonster then
            for root, attachment in pairs(_attachments) do
                pcall(function() attachment:Destroy() end)
            end
            _attachments = {}
            _alignments = {}
            return
        end
        if math.random(1, 10) == 1 then
            OrphanedAttachments()
        end
        
        local targetRoot = __index:FindFirstChild("HumanoidRootPart") or __index.PrimaryPart
        local targetHumanoid = __index:FindFirstChildOfClass("Humanoid")
        
        if not IsValidTarget(targetRoot, targetHumanoid) then
            return
        end
        
        local CurrentTime = tick()
        if CurrentTime - _lastSimulationUpdate > 0.5 then
            pcall(function()
                sethiddenproperty(Player, "SimulationRadius", math.huge)
            end)
            _lastSimulationUpdate = CurrentTime
        end
        
        local Character = Player.Character
        if not Character then return end
        
        local targetPos = targetRoot.Position
        local mobs = __index.Name
        local plrPos = Character:GetPivot().Position
        
        for _, v in ipairs(Enemies:GetChildren()) do
            if v.Name == mobs then
                local root = v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
                local humanoid = v:FindFirstChildOfClass("Humanoid")
                
                if IsValidTarget(root, humanoid) then
                    local distance = (plrPos - root.Position).Magnitude
                    
                    if distance <= quantum.BringMonsterRadius then
                        humanoid.WalkSpeed = 0
                        humanoid.JumpPower = 0
                        local attachment, alignPos, alignOri = GetAttachment(root)
                        
                        if attachment and alignPos and alignOri then
                            local targetPosition = CalculatePosition(plrPos, targetPos, targetRoot)
                            
                            alignPos.Enabled = true
                            alignOri.Enabled = true
                            alignPos.Position = targetPosition
                            alignOri.CFrame = CFrame.new(targetPosition) * CFrame.Angles(0, math.rad(90), 0)
                        end
                    else
                        local alignment = _alignments[root]
                        if alignment then
                            alignment[1].Enabled = false
                            alignment[2].Enabled = false
                        end
                    end
                else
                    local attachment = _attachments[root]
                    if attachment then
                        pcall(function() attachment:Destroy() end)
                        _attachments[root] = nil
                        _alignments[root] = nil
                    end
                end
            end
        end
    end
return BringMobs
end
