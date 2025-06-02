local Module = {}

Module.Signal = {}
Module.Signal.__index = Module.Signal

function Module.Signal.new()
	local self = setmetatable({}, Module.Signal)
	self.Connections = {}
	return self
end

function Module.Signal:Connect(Func)
	local Conn = {Func = Func}
	table.insert(self.Connections, Conn)

	return {
		Disconnect = function()
			for i, v in ipairs(self.Connections) do
				if v == Conn then
					table.remove(self.Connections, i)
					break
				end
			end
		end
	}
end

function Module.Signal:Fire(...)
	for _, Conn in ipairs(self.Connections) do
		task.spawn(Conn.Func, ...)
	end
end

local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService: CollectionService = game:GetService("CollectionService")
local HttpService: HttpService = game:GetService("HttpService")
local TeleportService: TeleportService = game:GetService("TeleportService")
local Players: Players = game:GetService("Players")

local SellRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("Sell_Inventory")
local FavoriteToolRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("Favorite_Item")
local HoneyRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("HoneyMachineService_RE")
local PlantRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("Plant_RE")
local BuyPetEgg: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyPetEgg")
local StevenHRP: BasePart? = workspace:WaitForChild("NPCS"):WaitForChild("Steven"):WaitForChild("HumanoidRootPart")
local GetFarm: any = require(ReplicatedStorage.Modules:WaitForChild("GetFarm"))
local DataService: any = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local lp: Player = Players.LocalPlayer
local ExecCmd = getgenv() or {}

local Threads = {}
Module.AutoPlantModule = function(): nil
	if Threads.AutoPlant then return end
	Threads.AutoPlant = true

	local Wait = task.wait
	local Random = math.random
	local Vector3New = Vector3.new
	local Containers = { lp.Backpack }
	local CharParts = {}
	local CanFire = true
	local LastFireTime = 0
	local MinFireInterval = 0.25

	local function FindSeedTool(SeedName: string): Tool?
		for _, Container in ipairs(Containers) do
			for _, Item in ipairs(Container:GetChildren()) do
				if Item:IsA("Tool") and string.find(Item.Name, SeedName) and string.find(Item.Name, "Seed") then
					return Item
				end
			end
		end
		return nil
	end

	local function CacheCharacterParts(Character: Model)
		table.clear(CharParts)
		for _, Part in ipairs(Character:GetDescendants()) do
			if Part:IsA("BasePart") then
				table.insert(CharParts, Part)
			end
		end
	end

	local function SetCollision(Parts, CanCollide)
		for _, Part in ipairs(Parts) do
			Part.CanCollide = CanCollide
		end
	end

	while ExecCmd.AutoPlant do
		local Character: Model = lp.Character or lp.CharacterAdded:Wait()
		Containers[2] = Character

		local Humanoid: Humanoid? = Character:FindFirstChildOfClass("Humanoid")
		local RootPart: BasePart? = Character:FindFirstChild("HumanoidRootPart")
		if not Humanoid or not RootPart then
			Wait(1)
			continue
		end

		CacheCharacterParts(Character)

		local Farm: Model? = GetFarm(lp)
		local SpawnPoint: BasePart? = Farm and Farm:FindFirstChild("Spawn_Point")

		if SpawnPoint and (RootPart.Position - SpawnPoint.Position).Magnitude > 30 then
			RootPart.CFrame = SpawnPoint.CFrame
			Wait(1.5)
		end

		local PlantingFolder: Folder? = Farm and Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Plant_Locations")
		if not PlantingFolder then
			Wait(1)
			continue
		end

		local PlantingSpots = {}
		for _, Descendant in ipairs(PlantingFolder:GetDescendants()) do
			if Descendant:IsA("BasePart") and string.find(Descendant.Name, "Can_Plant") then
				table.insert(PlantingSpots, Descendant)
			end
		end

		if #PlantingSpots == 0 then
			Wait(1)
			continue
		end

		local SeedName: string = ExecCmd.SeedName or "Any"
		local PlantMode: string = ExecCmd.PlantMode or "Pathways"
		local PlantStyle: string = ExecCmd.PlantStyle or "Random"

		local SeedsToPlant = {}

		if SeedName == "Any" then
			local SeenSeeds = {}
			for _, Container in ipairs(Containers) do
				for _, Item in ipairs(Container:GetChildren()) do
					if Item:IsA("Tool") and string.find(Item.Name, "Seed") then
						local CleanName = string.gsub(Item.Name, " Seed.*", "")
						if not SeenSeeds[CleanName] then
							SeenSeeds[CleanName] = true
							table.insert(SeedsToPlant, CleanName)
						end
					end
				end
			end
		else
			table.insert(SeedsToPlant, SeedName)
		end

		for _, Seed in ipairs(SeedsToPlant) do
			local Tool = FindSeedTool(Seed)
			if not Tool then continue end

			local LastPosition

			while ExecCmd.AutoPlant and Tool do
				local Spot = PlantingSpots[Random(1, #PlantingSpots)]
				local Size = Spot.Size
				local TargetPosition

				if PlantStyle == "Stacked" and LastPosition then
					TargetPosition = LastPosition + Vector3New(Random(-3, 3), 0, Random(-3, 3))
				else
					TargetPosition = Spot.Position + Vector3New(
						Random(-Size.X / 2, Size.X / 2),
						2,
						Random(-Size.Z / 2, Size.Z / 2)
					)
				end

				if not Tool:IsDescendantOf(Character) then
					Tool.Parent = Character
					repeat Wait() until Character:FindFirstChild(Tool.Name)
				end

				if CanFire and os.clock() - LastFireTime >= MinFireInterval then
					if PlantMode == "Bypass" then
						PlantRemote:FireServer(TargetPosition, Seed)
					else
						local Distance = (RootPart.Position - TargetPosition).Magnitude
						if Distance > 1 then
							SetCollision(CharParts, false)
							local Done = false
							local Conn = Humanoid.MoveToFinished:Connect(function()
								Done = true
							end)
							Humanoid:MoveTo(TargetPosition)
							for _ = 1, 30 do
								if Done or not ExecCmd.AutoPlant then break end
								Wait(0.1)
							end
							Conn:Disconnect()
							SetCollision(CharParts, true)
						end

						if ExecCmd.AutoPlant then
							PlantRemote:FireServer(TargetPosition, Seed)
						end
					end
					CanFire = false
					LastFireTime = os.clock()
					task.delay(MinFireInterval, function()
						CanFire = true
					end)
				end

				LastPosition = TargetPosition
				Wait(0.1)
				Humanoid:UnequipTools()
				Wait(0.1)
				Tool = FindSeedTool(Seed)
			end
		end

		Wait(0.1)
	end

	Threads.AutoPlant = nil
end



Module.CollectModule = function(): nil
	if Threads.AutoCollect then return end
    local Remotes = nil
    while true do
        local success, result = pcall(function()
            Remotes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Remotes"))
            return Remotes and Remotes.Crops and Remotes.Crops.Collect and typeof(Remotes.Crops.Collect.send) == "function"
        end)
        if success and result then break end
        task.wait(1)
    end
    local CropCollectRemote = Remotes.Crops.Collect
    local function Mutations_(crop: Model, SelectedMut: string | {string}): boolean
        if SelectedMut == "Any" or (typeof(SelectedMut) == "table" and table.find(SelectedMut, "Any")) then
            return true
        end
        local attrs = crop:GetAttributes()
        if typeof(SelectedMut) == "string" then
            return attrs[SelectedMut] == true
        elseif typeof(SelectedMut) == "table" then
            for name, value in pairs(attrs) do
                if value == true and table.find(SelectedMut, name) then
                    return true
                end
            end
        end
        return false
    end

    local function Variant_(crop: Model, SelectedVar: string | {string}): boolean
        if SelectedVar == "Any" or (typeof(SelectedVar) == "table" and table.find(SelectedVar, "Any")) then
            return true
        end
        local variant = crop:FindFirstChild("Variant")
        local VariantVal = variant and variant:IsA("StringValue") and variant.Value or nil
        if typeof(SelectedVar) == "string" then
            return VariantVal == SelectedVar
        elseif typeof(SelectedVar) == "table" then
            return VariantVal and table.find(SelectedVar, VariantVal) ~= nil
        end
        return false
    end

    Threads.AutoCollect = task.spawn(function()
        while ExecCmd.AutoCollect do
            if #lp.Backpack:GetChildren() >= 200 then
                task.wait(0.3)
                continue
            end

			local garden: Model? = nil
            for _, plot in ipairs(workspace:WaitForChild("Farm"):GetChildren()) do
                local important = plot:FindFirstChild("Important")
                local data = important and important:FindFirstChild("Data")
                local owner = data and data:FindFirstChild("Owner")
                if owner and owner.Value == lp.Name then
                    garden = important and important:FindFirstChild("Plants_Physical")
                    break
                end
            end

            if garden then
                local batch = {}
                local SelectedMut = ExecCmd.SelectedMutations
                local SelectedVar = ExecCmd.SelectedVariants

                for _, prompt in ipairs(garden:GetDescendants()) do
                    if #batch >= 10 then break end
                    if prompt:IsA("ProximityPrompt") and prompt.Enabled and CollectionService:HasTag(prompt, "CollectPrompt") then
                        local crop = prompt.Parent and prompt.Parent.Parent
                        if crop and Mutations_(crop, SelectedMut) and Variant_(crop, SelectedVar) then
                            table.insert(batch, crop)
                        end
                    end
                end

                if #batch > 0 then
                    pcall(function()
                        CropCollectRemote.send(batch)
                    end)
                    task.wait(0.15)
                else
                    task.wait(0.2)
                end
            else
                task.wait(0.3)
            end
        end
		Threads.AutoCollect = nil
    end)
end

return Module
