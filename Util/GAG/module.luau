local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local Backpack = lp:WaitForChild("Backpack")

local FavoriteToolRemote = ReplicatedStorage:WaitForChild("FavoriteToolRemote")
local BuyPetEgg = ReplicatedStorage:WaitForChild("BuyPetEgg")
local DataService = ReplicatedStorage:WaitForChild("DataService")
local GetFarm = require(ReplicatedStorage:WaitForChild("GetFarm"))

local Module = {}

function Module.HasAnyMutation(tool: Tool, mutations: {string}): boolean
	for _, mutation in ipairs(mutations) do
		if tool:GetAttribute(mutation) == true then
			return true
		end
	end
	return false
end

function Module.AutoMutate(opts: { SelectedFavMutations: {string}?, AutoFavMutate: boolean?, AutoUnfavMutate: boolean?, BackpackFolder: Folder?})
	task.spawn(function()
		local SelectedFavMutations = opts.SelectedFavMutations or {}
		local AutoFavMutate = opts.AutoFavMutate or false
		local AutoUnfavMutate = opts.AutoUnfavMutate or false
		local BackpackFolder = opts.BackpackFolder or Backpack

		if not AutoFavMutate and not AutoUnfavMutate then return end

		while true do
			task.wait(1)
			for _, tool in ipairs(BackpackFolder:GetChildren()) do
				if not tool:IsA("Tool") then continue end

				local matched = Module.HasAnyMutation(tool, SelectedFavMutations)
				local isFav = tool:GetAttribute("Favorite") == true

				if AutoFavMutate and matched and not isFav then
					FavoriteToolRemote:FireServer(tool)
				elseif AutoUnfavMutate and not matched and isFav then
					FavoriteToolRemote:FireServer(tool)
				end
			end
		end
	end)
end
function Module.AutoBuyEggs(opts: { AutoBuyEgg: boolean?, AutoBuyAllEggs: boolean?, SelectedEggList: any, })
	task.spawn(function()
		while true do
			task.wait(1)
			local AutoBuyEgg = opts.AutoBuyEgg or false
			local AutoBuyAllEggs = opts.AutoBuyAllEggs or false
			local SelectedEggListRaw = opts.SelectedEggList or {}

			local SelectedEggList: {string} = {}

			if typeof(SelectedEggListRaw) == "string" then
				SelectedEggList = { SelectedEggListRaw }
			elseif typeof(SelectedEggListRaw) == "table" then
				SelectedEggList = SelectedEggListRaw
			end

			if not (AutoBuyEgg or AutoBuyAllEggs) then
				continue
			end

			pcall(function()
				local data = DataService:GetData()
				local stocks = data.PetEggStock.Stocks
				local normalizedList = {}
				for i, eggName in ipairs(SelectedEggList) do
					normalizedList[i] = string.lower(eggName):gsub("%s+", "")
				end

				for i, stock in ipairs(stocks) do
					if stock.Stock > 0 then
						if AutoBuyAllEggs then
							BuyPetEgg:FireServer(i)
						elseif AutoBuyEgg then
							local eggNameNorm = string.lower(stock.EggName):gsub("%s+", "")
							for _, normName in ipairs(normalizedList) do
								if eggNameNorm == normName then
									BuyPetEgg:FireServer(i)
									break
								end
							end
						end
					end
				end
			end)
		end
	end)
end
function Module.AutoHatchEggs(opts: {AutoHatchEggs: boolean?})
	task.spawn(function()
		while true do
			task.wait(1)
			if not opts.AutoHatchEggs then continue end

			pcall(function()
				for _, Farm in ipairs(GetFarm()) do
					local Important = Farm:FindFirstChild("Important")
					local Data = Important and Important:FindFirstChild("Data")
					local Owner = Data and Data:FindFirstChild("Owner")

					if Owner and Owner.Value == lp.Name then
						local EggFolder = Important:FindFirstChild("Objects_Physical") and Important.Objects_Physical:FindFirstChild("PetEgg")
						if not EggFolder then continue end

						for _, Egg in ipairs(EggFolder:GetChildren()) do
							local Prompt = Egg:FindFirstChildOfClass("ProximityPrompt")
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

-- Auto plant seeds on player farm
function Module.AutoPlant(opts: {
	AutoPlant: boolean?,
	SeedName: string?,
	PlantMode: string?,
	PlantStyle: string?,
	BackpackFolder: Folder?,
	CharacterFolder: Model?,
})
	task.spawn(function()
		local PlantRemote = ReplicatedStorage.GameEvents:WaitForChild("Plant_RE") :: RemoteEvent
		local BackpackFolder = opts.BackpackFolder or lp:WaitForChild("Backpack")
		local CharacterFolder = opts.CharacterFolder or (lp.Character or lp.CharacterAdded:Wait())

		local Containers = { BackpackFolder, CharacterFolder }
		local CharParts = {}

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

		while opts.AutoPlant do
			local Character = lp.Character or lp.CharacterAdded:Wait()
			Containers[2] = Character

			local Humanoid = Character:FindFirstChildOfClass("Humanoid")
			local Root = Character:FindFirstChild("HumanoidRootPart")
			if not Humanoid or not Root then
				task.wait(1)
				continue
			end

			local Farm = GetFarm(lp)
			local SpawnPoint = Farm and Farm:FindFirstChild("Spawn_Point")

			if SpawnPoint and (Root.Position - SpawnPoint.Position).Magnitude > 30 then
				Root.CFrame = SpawnPoint.CFrame
				task.wait(1.5)
			end

			local PlantLocations = Farm and Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Plant_Locations")
			local Spots = {}

			if PlantLocations then
				for _, part in ipairs(PlantLocations:GetDescendants()) do
					if part:IsA("BasePart") and string.find(part.Name, "Can_Plant") then
						table.insert(Spots, part :: BasePart)
					end
				end
			end

			if #Spots == 0 then
				task.wait(1)
				continue
			end

			local SeedName = opts.SeedName or "Any"
			local PlantMode = opts.PlantMode or "Pathways"
			local PlantStyle = opts.PlantStyle or "Random"

			local SeedList = {}

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
				local Tool = FindTool(Seed)
				local LastPos = nil
				local Random = math.random
				local Vector3New = Vector3.new

				while opts.AutoPlant and Tool do
					local Target = Spots[Random(1, #Spots)]
					local Size = Target.Size
					local BasePos

					if PlantStyle == "Stacked" and LastPos then
						BasePos = LastPos + Vector3New(Random(-3, 3), 0, Random(-3, 3))
					else
						BasePos = Target.Position + Vector3New(
							Random(-Size.X / 2, Size.X / 2),
							2,
							Random(-Size.Z / 2, Size.Z / 2)
						)
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
								part.CanCollide = false
								table.insert(CharParts, part)
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

return Module
