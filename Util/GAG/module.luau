local Module = {}

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
local GetFarm: {} = require(ReplicatedStorage.Modules:WaitForChild("GetFarm"))
local DataService: {} = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local lp: Player = Players.Localplayer
local ExecCmd = getgenv() or {}

Module.AutoPlantModule = function(): nil
	task.spawn(function()
		local Wait = task.wait
		local Random = math.random
		local Vector3New = Vector3.new
		local Containers: {Instance} = { lp.Backpack }
		local CharParts: {BasePart} = {}


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

			local PlantLocationsFolder: Folder? = Farm and Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Plant_Locations")
			if not PlantLocationsFolder then
				Wait(1)
				continue
			end
			local PlantingSpots: {BasePart} = {}
			for _, Descendant in ipairs(PlantLocationsFolder:GetDescendants()) do
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

			local SeedsToPlant: {string} = {}

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
				local Tool: Tool? = FindSeedTool(Seed)
				if not Tool then
					continue
				end
				local LastPosition: Vector3?
				while ExecCmd.AutoPlant and Tool do
					local Spot = PlantingSpots[Random(1, #PlantingSpots)]
					local Size = Spot.Size
					local TargetPosition: Vector3

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
					if PlantMode == "Bypass" then
						PlantRemote:FireServer(TargetPosition, Seed)
					else
						for _, Part in ipairs(CharParts) do
							Part.CanCollide = false
						end

						local Done = false
						local Conn = Humanoid.MoveToFinished:Connect(function()
							Done = true
						end)
						Humanoid:MoveTo(TargetPosition)
						for _ = 1, 30 do
							if Done then break end
							Wait(0.1)
						end
						Conn:Disconnect()
						for _, Part in ipairs(CharParts) do
							Part.CanCollide = true
						end

						PlantRemote:FireServer(TargetPosition, Seed)
					end
					LastPosition = TargetPosition
					Wait(0.1)
					Humanoid:UnequipTools()
					Wait(0.1)
					Tool = FindSeedTool(Seed)
					if not Tool then break end
				end
			end

			Wait(0.05)
		end
	end)
end



Module.CollectModule = function(): nil
	type Types = {
		RemoteModule: { Crops: { Collect: { send: (batch: {Instance}) -> () } } },
		PlantCollectionContex: { Plot: Model, Prompt: ProximityPrompt, Crop: Model }
	}

	task.spawn(function()
		local Remotes = nil
		while true do
			if pcall(function()
				Remotes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Remotes")) :: Types.RemoteModule
				return Remotes and Remotes.Crops and Remotes.Crops.Collect and typeof(Remotes.Crops.Collect.send) == "function"
			end) then break end
			task.wait(1)
		end

		while ExecCmd.AutoCollect do
			if #lp.Backpack:GetChildren() >= 200 then
				task.wait(0.3)
				continue
			end

			local Garden = nil
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
				local Batch = {}
				local SelectedMut = ExecCmd.SelectedMutations
				local SelectedVar = ExecCmd.SelectedVariants
				for _, Prompt in ipairs(Garden:GetDescendants()) do
					if #Batch >= 10 then break end
					if Prompt:IsA("ProximityPrompt") and Prompt.Enabled and CollectionService:HasTag(Prompt, "CollectPrompt") then
						local Crop = Prompt.Parent and Prompt.Parent.Parent
						if Crop then
							local Allow = false
							local MutationMatch = false
							if SelectedMut == "Any" or (typeof(SelectedMut) == "table" and table.find(SelectedMut, "Any")) then
								MutationMatch = true
							elseif typeof(SelectedMut) == "string" then
								for Name, Value in pairs(Crop:GetAttributes()) do
									if Value == true and Name == SelectedMut then
										MutationMatch = true
										break
									end
								end
							elseif typeof(SelectedMut) == "table" then
								for Name, Value in pairs(Crop:GetAttributes()) do
									if Value == true and table.find(SelectedMut, Name) then
										MutationMatch = true
										break
									end
								end
							end
							local VariantMatch = false
							local Variant = Crop:FindFirstChild("Variant")
							local VariantValue = Variant and Variant:IsA("StringValue") and Variant.Value
							if SelectedVar == "Any" or (typeof(SelectedVar) == "table" and table.find(SelectedVar, "Any")) then
								VariantMatch = true
							elseif typeof(SelectedVar) == "string" then
								VariantMatch = VariantValue == SelectedVar
							elseif typeof(SelectedVar) == "table" then
								VariantMatch = table.find(SelectedVar, VariantValue) ~= nil
							end

							if MutationMatch and VariantMatch then
								table.insert(Batch, Crop)
							end
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




Module.AutoBuyEggs = function(): nil
	type Types = { EggStock: { EggName: string, Stock: number }, Data: { PetEggStock: { Stocks: { Types.EggStock } } } }
	task.spawn(function()
		while task.wait() do
			local AutoBuyEgg = ExecCmd.AutoBuyEgg
			local AutoBuyAllEggs = ExecCmd.AutoBuyAllEggs
			if not (AutoBuyEgg or AutoBuyAllEggs) then continue end

			local RawList = ExecCmd.SelectedEggList
			local SelectedEggList = typeof(RawList) == "string" and { RawList } or typeof(RawList) == "table" and RawList or {}

			pcall(function()
				local Data: Types.Data = DataService:GetData()
				local Stocks = Data.PetEggStock.Stocks
				local Normalized = {}
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

Module.AutoHatchEggs = function(): nil
	type Types = { ProximityPrompt: Instance & { ActionText: string, Enabled: boolean }, StringValue: Instance & { Value: string } }
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

Module.FavoriteMutations = function(): nil
	task.spawn(function()
		while task.wait(0.3) do
			local List: {string} = ExecCmd.SelectedFavMutations or {}
			local AutoFav: boolean = ExecCmd.AutoFavMutate
			local AutoUnfav: boolean = ExecCmd.AutoUnfavMutate
			if not (AutoFav or AutoUnfav) then continue end
			local MutationSet: {[string]: boolean} = {}
			for _, mutation: string in ipairs(List) do
				MutationSet[mutation] = true
			end
			for _, Tool: Tool in ipairs(lp.Backpack:GetChildren()) do
				if not Tool:IsA("Tool") then continue end
				local Matched: boolean = false
				for mutation: string in pairs(MutationSet) do
					if Tool:GetAttribute(mutation) == true then
						Matched = true
					end
				end

				local IsFavorite: boolean = Tool:GetAttribute("Favorite") == true
				if AutoFav and Matched and not IsFavorite then
					FavoriteToolRemote:FireServer(Tool)
				elseif AutoUnfav and not Matched and IsFavorite then
					FavoriteToolRemote:FireServer(Tool)
				end
			end
		end
	end)
	return nil
end

Module.AutoSell = function(): nil
	task.spawn(function()
		while ExecCmd.AutoSell or ExecCmd.AutoTickSell do
			local Char = lp.Character or lp.CharacterAdded:Wait()
			local Backpack = lp.Backpack
			local Farm = GetFarm(lp)
			local SpawnPoint = Farm and Farm:FindFirstChild("Spawn_Point")
			local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

			if Char and HRP and Backpack and SpawnPoint and StevenHRP then
				local Count = #Backpack:GetChildren()
				local ShouldSell = (ExecCmd.AutoSell and Count >= 200) or ExecCmd.AutoTickSell

				if ShouldSell then
					if ExecCmd.AutoTickSell then
						task.wait(ExecCmd.DelaySell / 100)
					end
					local Sellpos = StevenHRP.CFrame * CFrame.new(0, 2, 5)
					Char:PivotTo(Sellpos)
					task.wait(0.25)
					task.spawn(function()
						pcall(SellRemote.FireServer, SellRemote)
					end)
					task.wait(0.25)
					Char:PivotTo(SpawnPoint.CFrame + Vector3.new(0, 3, 0))
				end
			end
			task.wait((ExecCmd.AutoTickSell and ExecCmd.DelaySell / 100) or 0.1)
		end
	end)
end

Module.AutoGivePollinated = function(): nil
	type Tool = ToolInstance & { Name: string }
	task.spawn(function()
		while ExecCmd.AutoGivePollinated do
			local Character = lp.Character or lp.CharacterAdded:Wait()
			local Backpack = lp:FindFirstChild("Backpack")

			if Character and Backpack then
				for _, Tool: Tool in ipairs(Backpack:GetChildren()) do
					if Tool:IsA("Tool") and string.find(string.lower(Tool.Name), "pollinated") then
						Tool.Parent = Character
						task.wait(0.5)

						for _ = 1, 10 do
							pcall(HoneyRemote.FireServer, HoneyRemote, "MachineInteract")
						end

						task.wait(0.5)
					end
				end
			end

			task.wait(0.25)
		end
	end)
end


return Module
