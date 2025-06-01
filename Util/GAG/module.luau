local Module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local SellRemote = ReplicatedStorage.GameEvents:WaitForChild("Sell_Inventory")
local FavoriteToolRemote = ReplicatedStorage.GameEvents:WaitForChild("Favorite_Item")
local BuyPetEgg = ReplicatedStorage.GameEvents:WaitForChild("BuyPetEgg")
local GetFarm = require(ReplicatedStorage.Modules:WaitForChild("GetFarm"))
local DataService = require(ReplicatedStorage.Modules:WaitForChild("DataService"))

local LP = Players.LocalPlayer
local ExecCmd = getgenv()

function Module.AutoPlantModule(): nil
	task.spawn(function()
		local PlantRemote = ReplicatedStorage.GameEvents:WaitForChild("Plant_RE")

		local Containers = { LP.Backpack, LP.Character or LP.CharacterAdded:Wait() }
		local CharParts = {}

		local function FindTool(seed: string): Tool?
			for _, container in Containers do
				for _, tool in container:GetChildren() do
					if tool:IsA("Tool") and string.find(tool.Name, seed) and tool.Name:find("Seed") then
						return tool
					end
				end
			end
			return nil
		end

		while ExecCmd.AutoPlant do
			local Character = LP.Character or LP.CharacterAdded:Wait()
			Containers[2] = Character

			local Humanoid = Character:FindFirstChildOfClass("Humanoid")
			local Root = Character:FindFirstChild("HumanoidRootPart")

			if not Humanoid or not Root then task.wait(1) continue end

			local Farm = GetFarm(LP)
			local SpawnPoint = Farm and Farm:FindFirstChild("Spawn_Point")

			if SpawnPoint and (Root.Position - SpawnPoint.Position).Magnitude > 30 then
				Root.CFrame = SpawnPoint.CFrame
				task.wait(1.5)
			end

			local PlantLocations = Farm and Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Plant_Locations")
			local Spots = {}

			if PlantLocations then
				for _, part in PlantLocations:GetDescendants() do
					if part:IsA("BasePart") and part.Name:find("Can_Plant") then
						table.insert(Spots, part)
					end
				end
			end

			if #Spots == 0 then task.wait(1) continue end

			local SeedName = ExecCmd.SeedName or "Any"
			local PlantMode = ExecCmd.PlantMode or "Pathways"
			local PlantStyle = ExecCmd.PlantStyle or "Random"

			local SeedList = {}

			if SeedName == "Any" then
				local Seen = {}
				for _, container in Containers do
					for _, tool in container:GetChildren() do
						if tool:IsA("Tool") and tool.Name:find("Seed") then
							local CleanName = tool.Name:gsub(" Seed.*", "")
							if not Seen[CleanName] then
								Seen[CleanName] = true
								table.insert(SeedList, CleanName)
							end
						end
					end
				end
			else
				table.insert(SeedList, SeedName)
			end

			for _, Seed in SeedList do
				local Tool = FindTool(Seed)
				local LastPos = nil

				while ExecCmd.AutoPlant and Tool do
					local Target = Spots[math.random(1, #Spots)]
					local Size = Target.Size
					local BasePos

					if PlantStyle == "Stacked" and LastPos then
						BasePos = LastPos + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
					else
						BasePos = Target.Position + Vector3.new(math.random(-Size.X / 2, Size.X / 2), 2, math.random(-Size.Z / 2, Size.Z / 2))
					end

					if not Tool:IsDescendantOf(Character) then
						Tool.Parent = Character
						repeat task.wait() until Character:FindFirstChild(Tool.Name)
					end

					if PlantMode == "Bypass" then
						PlantRemote:FireServer(BasePos, Seed)
					else
						table.clear(CharParts)
						for _, part in Character:GetDescendants() do
							if part:IsA("BasePart") then
								part.CanCollide = false
								table.insert(CharParts, part)
							end
						end

						local Done = false
						local Conn = Humanoid.MoveToFinished:Connect(function() Done = true end)
						Humanoid:MoveTo(BasePos)

						for _ = 1, 30 do
							if Done then break end
							task.wait(0.1)
						end

						Conn:Disconnect()
						for _, part in CharParts do part.CanCollide = true end
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
	task.spawn(function()
		local Remotes = nil
		repeat
			pcall(function()
				Remotes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Remotes"))
			end)
			task.wait(1)
		until Remotes and Remotes.Crops and Remotes.Crops.Collect and typeof(Remotes.Crops.Collect.send) == "function"

		while ExecCmd.AutoCollect do
			if #LP.Backpack:GetChildren() >= 200 then task.wait(0.3) continue end

			local Garden = nil
			for _, Plot in workspace:WaitForChild("Farm"):GetChildren() do
				local Important = Plot:FindFirstChild("Important")
				local Owner = Important and Important:FindFirstChild("Data") and Important.Data:FindFirstChild("Owner")
				if Owner and Owner.Value == LP.Name then
					Garden = Important:FindFirstChild("Plants_Physical")
					break
				end
			end

			if Garden then
				local Batch = {}
				for _, Prompt in Garden:GetDescendants() do
					if #Batch >= 10 then break end
					if Prompt:IsA("ProximityPrompt") and Prompt.Enabled and CollectionService:HasTag(Prompt, "CollectPrompt") then
						local Crop = Prompt.Parent and Prompt.Parent.Parent
						if Crop then table.insert(Batch, Crop) end
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

function Module.AutoBuyEggs(): nil
	task.spawn(function()
		while task.wait(0.5) do
			local AutoBuyEgg = ExecCmd.AutoBuyEgg
			local AutoBuyAllEggs = ExecCmd.AutoBuyAllEggs
			if not (AutoBuyEgg or AutoBuyAllEggs) then continue end

			local RawList = ExecCmd.SelectedEggList
			local SelectedEggList = typeof(RawList) == "string" and { RawList } or typeof(RawList) == "table" and RawList or {}

			pcall(function()
				local Data = DataService:GetData()
				local Stocks = Data.PetEggStock and Data.PetEggStock.Stocks or {}
				local Normalized = {}
				for _, Name in ipairs(SelectedEggList) do
					Normalized[string.lower(Name):gsub("%s+", "")] = true
				end

				for Index, Stock in ipairs(Stocks) do
					if Stock.Stock > 0 and (AutoBuyAllEggs or Normalized[string.lower(Stock.EggName):gsub("%s+", "")]) then
						BuyPetEgg:FireServer(Index)
					end
				end
			end)
		end
	end)
end

function Module.AutoHatchEggs(): nil
	task.spawn(function()
		while task.wait(1) do
			if not ExecCmd.AutoHatchEggs then continue end
			pcall(function()
				local Farm = GetFarm(LP)
				if not Farm then return end
				local Important = Farm:FindFirstChild("Important")
				local EggFolder = Important and Important:FindFirstChild("Objects_Physical") and Important.Objects_Physical:FindFirstChild("PetEgg")

				if not EggFolder then return end
				for _, Egg in ipairs(EggFolder:GetChildren()) do
					local Prompt = Egg:FindFirstChildWhichIsA("ProximityPrompt")
					if Prompt and Prompt.Enabled and Prompt.ActionText == "Hatch!" then
						fireproximityprompt(Prompt)
					end
				end
			end)
		end
	end)
end

return Module
