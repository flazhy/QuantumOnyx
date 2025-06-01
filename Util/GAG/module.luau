
local Module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local SellRemote = ReplicatedStorage.GameEvents:WaitForChild("Sell_Inventory")
local StevenHRP = workspace:WaitForChild("NPCS"):WaitForChild("Steven"):WaitForChild("HumanoidRootPart")
local GetFarm = require(ReplicatedStorage.Modules:WaitForChild("GetFarm"))
local FavoriteToolRemote = ReplicatedStorage.GameEvents:WaitForChild("Favorite_Item")
local BuyPetEgg = ReplicatedStorage.GameEvents:WaitForChild("BuyPetEgg")
local DataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local lp = Players.LocalPlayer
local ExecCmd = getgenv()

function Module.AutoPlantModule() : nil
    task.spawn(function()
        type Container = Tool | BasePart | Vector3 | Humanoid | Model | Backpack
		local PlantRemote = ReplicatedStorage.GameEvents:WaitForChild("Plant_RE") :: RemoteEvent

        local Containers: {Container} = { lp.Backpack, lp.Character or lp.CharacterAdded:Wait() }
        local CharParts: {BasePart} = {}

        local function FindTool(seed: string): Tool?
            for _, container in ipairs(Containers) do
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") and string.find(tool.Name, seed) and string.find(tool.Name, "Seed") then
                        return tool :: Tool
                    end
                end
            end
            return nil
        end
        while ExecCmd.AutoPlant do
            local Character: Model? = lp.Character or lp.CharacterAdded:Wait()
            Containers[2] = Character

            local Humanoid: Humanoid? = Character:FindFirstChildOfClass("Humanoid")
            local Root: BasePart? = Character:FindFirstChild("HumanoidRootPart")

            if not Humanoid or not Root then
                task.wait(1)
                continue
            end

            local Farm: Model? = GetFarm(lp)
            local SpawnPoint: BasePart? = Farm and Farm:FindFirstChild("Spawn_Point")

            if SpawnPoint and (Root.Position - SpawnPoint.Position).Magnitude > 30 then
                Root.CFrame = SpawnPoint.CFrame
                task.wait(1.5)
            end

            local PlantLocations: Model? = Farm and Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Plant_Locations")
            local Spots: {BasePart} = {}

            if PlantLocations then
                for _, part in ipairs(PlantLocations:GetDescendants()) do
                    if part:IsA("BasePart") and string.find(part.Name, "Can_Plant") then
                        table.insert(Spots, part :: BasePart)
                    end
                end
            end

            if #Spots == 0 then task.wait(1)
                continue
            end

            local SeedName: string = ExecCmd.SeedName or "Any"
            local PlantMode: string = ExecCmd.PlantMode or "Pathways"
            local PlantStyle: string = ExecCmd.PlantStyle or "Random"

            local SeedList: {string} = {}

            if SeedName == "Any" then
                local Seen = {}
                for _, container in ipairs(Containers) do
                    for _, tool in ipairs(container:GetChildren()) do
                        if tool:IsA("Tool") and string.find(tool.Name, "Seed") then
                            local CleanName = string.gsub(tool.Name, " Seed.*", "")
                            if not Seen[CleanName] then
                                Seen[CleanName] = true
                                table.insert(SeedList, CleanName)
                            end
                        end
                    end
                end
            else
                SeedList[1] = SeedName
            end
            for _, Seed in ipairs(SeedList) do
                local Tool: Tool? = FindTool(Seed)
                local LastPos: Vector3? = nil
                local Random = math.random
                local Vector3New = Vector3.new

                while ExecCmd.AutoPlant and Tool do
                    local Target: BasePart = Spots[Random(1, #Spots)]
                    local Size: Vector3 = Target.Size
                    local BasePos: Vector3

                    if PlantStyle == "Stacked" and LastPos then
                        BasePos = LastPos + Vector3New(Random(-3, 3), 0, Random(-3, 3))
                    else
                        BasePos = Target.Position + Vector3New(Random(-Size.X / 2, Size.X / 2), 2, Random(-Size.Z / 2, Size.Z / 2))
                    end
                    if not Tool:IsDescendantOf(Character) then
                        Tool.Parent = Character
                        repeat task.wait() until Character:FindFirstChild(Tool.Name)
                    end

                    if PlantMode == "Bypass" then
                        PlantRemote:FireServer(BasePos, Seed)
                    else
                        table.clear(CharParts)
                        for _, part in ipairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                local basePart = part :: BasePart
                                basePart.CanCollide = false
                                table.insert(CharParts, basePart)
                            end
                        end

                        local Done = false
                        local Conn = Humanoid.MoveToFinished:Connect(function()
                            Done = true
                        end)
                        Humanoid:MoveTo(BasePos)
                        for _ = 1, 30 do
                            if Done then break end
                            task.wait(0.1)
                        end
                        Conn:Disconnect()
                        for _, part in ipairs(CharParts) do
                            part.CanCollide = true
                        end
                        PlantRemote:FireServer(BasePos, Seed)
                    end
                    LastPos = BasePos
                    task.wait(0.05)
                    Humanoid:UnequipTools()
                    task.wait(0.03)
                    Tool = FindTool(Seed)
                end
            end
            task.wait(0.05)
        end
    end)
end

function Module.CollectModule(): nil
    type Types = {
        RemoteModule: {Crops: {Collect: {send: (batch: {Instance}) -> ()}}},
        PlantCollectionContext: {Plot: Model,Prompt: ProximityPrompt,Crop: Model,}
    }
    task.spawn(function()
        local Remotes: Types.RemoteModule? = nil
        while true do
            if pcall(function()
                Remotes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Remotes")) :: Types.RemoteModule
                return Remotes and Remotes.Crops and Remotes.Crops.Collect and typeof(Remotes.Crops.Collect.send) == "function"
            end) then
                break
            end
            task.wait(1)
        end
        while ExecCmd.AutoCollect == true do
            if #lp.Backpack:GetChildren() >= 200 then
                task.wait(0.3)
                continue
            end
            local Garden: Model? = nil
            for _, Plot in ipairs(workspace:WaitForChild("Farm"):GetChildren()) do
                local Important = Plot:FindFirstChild("Important")
                local Data = Important and Important:FindFirstChild("Data")
                local Owner = Data and Data:FindFirstChild("Owner")
                if Owner and typeof(Owner.Value) == "string" and Owner.Value == lp.Name then
                    Garden = Important:FindFirstChild("Plants_Physical")
                    break
                end
            end
            if Garden then
                local Batch: {Model} = {}
                for _, Prompt in ipairs(Garden:GetDescendants()) do
                    if #Batch >= 10 then break end
                    if Prompt:IsA("ProximityPrompt")
                        and Prompt.Enabled
                        and CollectionService:HasTag(Prompt, "CollectPrompt") then
                        local Crop = Prompt.Parent and Prompt.Parent.Parent
                        if Crop then
                            table.insert(Batch, Crop)
                        end
                    end
                end
                if #Batch > 0 then
                    pcall(function()
                        Remotes.Crops.Collect.send(Batch)
                    end)
                    task.wait(0.15)
                else
                    task.wait(0.2)
                end
            else
                task.wait(0.3)
            end
        end
    end)
end

Module.function AutoBuyEggs(): nil
	type Types = { EggStock = { EggName: string, Stock: number }, Data = { PetEggStock: { Stocks: { Types.EggStock } } } }
	task.spawn(function()
		while task.wait() do
			local AutoBuyEgg = ExecCmd.AutoBuyEgg
			local AutoBuyAllEggs = ExecCmd.AutoBuyAllEggs
			if not (AutoBuyEgg or AutoBuyAllEggs) then continue end

			local RawList = ExecCmd.SelectedEggList
			local SelectedEggList: { string } = typeof(RawList) == "string" and { RawList } or typeof(RawList) == "table" and RawList or {}

			pcall(function()
				local Data: Types.Data = DataService:GetData()
				local Stocks = Data.PetEggStock.Stocks
				local Normalized: { [string]: boolean } = {}
				for _, Name in ipairs(SelectedEggList) do
					Normalized[string.lower(Name):gsub("%s+", "")] = true
				end
				for Index, Stock in ipairs(Stocks) do
					if Stock.Stock > 0 then
						if AutoBuyAllEggs or Normalized[string.lower(Stock.EggName):gsub("%s+", "")] then
							BuyPetEgg:FireServer(Index)
						end
					end
				end
			end)
		end
	end)
end

function Module.AutoHatchEggs(): nil
	type Types = { ProximityPrompt: Instance & { ActionText: string, Enabled: boolean }, StringValue: Instance & { Value: string },}
	task.spawn(function()
		while task.wait(1) do
			if not ExecCmd.AutoHatchEggs then continue end
			pcall(function()
				for _, Farm in ipairs(GetFarm()) do
					local Owner = Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Data") and Farm.Important.Data:FindFirstChild("Owner") :: Types.StringValue?
					if Owner and Owner.Value == lp.Name then
						local EggFolder = Farm.Important:FindFirstChild("Objects_Physical") and Farm.Important.Objects_Physical:FindFirstChild("PetEgg")
						if not EggFolder then continue end
						for _, Egg in ipairs(EggFolder:GetChildren()) do
							local Prompt = Egg:FindFirstChildOfClass("ProximityPrompt") :: Types.ProximityPrompt?
							if Prompt and Prompt.Enabled and Prompt.ActionText == "Hatch!" then
								fireproximityprompt(Prompt)
							end
						end
					end
				end
			end)
		end
	end)
end

return Module
