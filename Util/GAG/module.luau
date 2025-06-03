local Module = {}

local Services = setmetatable({}, {
	__index = function(self, Ind)
		local Success, Result = ypcall(function()
			return game:GetService(Ind)
		end)
		if Success and Result then
			rawset(self, Ind, Result)
			return Result
		end
		return nil
	end
})

local ReplicatedStorage: ReplicatedStorage = Services.ReplicatedStorage
local CollectionService: CollectionService = Services.CollectionService
local HttpService: HttpService = Services.HttpService
local TeleportService: TeleportService = Services.TeleportService
local Players: Players = Services.Players


local SellRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("Sell_Inventory")
local FavoriteToolRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("Favorite_Item")
local HoneyRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("HoneyMachineService_RE")
local PlantRemote: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("Plant_RE")
local BuyPetEgg: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("BuyPetEgg")
local PlaceEgg: RemoteEvent = ReplicatedStorage.GameEvents:WaitForChild("PetEggService")

local StevenHRP: BasePart? = Services.Workspace:WaitForChild("NPCS"):WaitForChild("Steven"):WaitForChild("HumanoidRootPart")

local GetFarm: any = require(ReplicatedStorage.Modules:WaitForChild("GetFarm"))
local DataService: any = require(ReplicatedStorage.Modules:WaitForChild("DataService"))


local lp: Player = Players.LocalPlayer
local ExecCmd = getgenv() or {}

local Threads = {}

Module.__index = Module

local Automation = setmetatable({}, Module)

local function CreateThread(name, fn)
	if Threads[name] then return end
	Threads[name] = task.spawn(function()
		fn()
		Threads[name] = nil
	end)
end
function Module:StopThread(name)
	local thread = Threads[name]
	if thread then
		task.cancel(thread)
		Threads[name] = nil
	end
end


function Module:AutoPlant()
	CreateThread("AutoPlant", function()
		local Wait, Random, Vector3New = task.wait, math.random, Vector3.new
		local Containers = { lp.Backpack }
		local CharParts = {}
		local CanFire, LastFireTime, MinFireInterval = true, 0, 0.25

		local function FindSeedTool(seed)
			for _, container in ipairs(Containers) do
				for _, item in ipairs(container:GetChildren()) do
					if item:IsA("Tool") and string.find(item.Name, seed) and item.Name:find("Seed") then
						return item
					end
				end
			end
		end

		local function CacheCharacterParts(character)
			table.clear(CharParts)
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(CharParts, part)
				end
			end
		end

		local function SetCollision(parts, state)
			for _, part in ipairs(parts) do
				part.CanCollide = state
			end
		end

		while ExecCmd.AutoPlant do
			local character = lp.Character or lp.CharacterAdded:Wait()
			Containers[2] = character

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if not humanoid or not root then Wait(1) continue end

			CacheCharacterParts(character)

			local farm = GetFarm(lp)
			local spawn = farm and farm:FindFirstChild("Spawn_Point")
			if spawn and (root.Position - spawn.Position).Magnitude > 30 then
				root.CFrame = spawn.CFrame
				Wait(1.5)
			end

			local plantingFolder = farm and farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plant_Locations")
			if not plantingFolder then Wait(1) continue end

			local spots = {}
			for _, d in ipairs(plantingFolder:GetDescendants()) do
				if d:IsA("BasePart") and d.Name:find("Can_Plant") then
					table.insert(spots, d)
				end
			end
			if #spots == 0 then Wait(1) continue end

			local seeds = {}
			local selected = ExecCmd.SeedName or "Any"
			if selected == "Any" then
				local seen = {}
				for _, container in ipairs(Containers) do
					for _, item in ipairs(container:GetChildren()) do
						if item:IsA("Tool") and item.Name:find("Seed") then
							local name = item.Name:gsub(" Seed.*", "")
							if not seen[name] then
								seen[name] = true
								table.insert(seeds, name)
							end
						end
					end
				end
			else
				table.insert(seeds, selected)
			end

			local mode = ExecCmd.PlantMode or "Pathways"
			local style = ExecCmd.PlantStyle or "Random"

			for _, seed in ipairs(seeds) do
				local tool = FindSeedTool(seed)
				if not tool then continue end

				local lastPos
				while ExecCmd.AutoPlant and tool do
					local spot = spots[Random(1, #spots)]
					local size = spot.Size
					local target = (style == "Stacked" and lastPos) and lastPos + Vector3New(Random(-3, 3), 0, Random(-3, 3)) or
						spot.Position + Vector3New(Random(-size.X / 2, size.X / 2), 2, Random(-size.Z / 2, size.Z / 2))

					if not tool:IsDescendantOf(character) then
						tool.Parent = character
						repeat Wait() until character:FindFirstChild(tool.Name)
					end

					if CanFire and os.clock() - LastFireTime >= MinFireInterval then
						if mode == "Bypass" then
							PlantRemote:FireServer(target, seed)
						else
							if (root.Position - target).Magnitude > 1 then
								SetCollision(CharParts, false)
								local done = false
								local conn = humanoid.MoveToFinished:Connect(function()
									done = true
								end)
								humanoid:MoveTo(target)
								for _ = 1, 30 do
									if done or not ExecCmd.AutoPlant then break end
									Wait(0.1)
								end
								conn:Disconnect()
								SetCollision(CharParts, true)
							end
							if ExecCmd.AutoPlant then
								PlantRemote:FireServer(target, seed)
							end
						end
						CanFire = false
						LastFireTime = os.clock()
						task.delay(MinFireInterval, function() CanFire = true end)
					end

					lastPos = target
					Wait(0.1)
					humanoid:UnequipTools()
					Wait(0.1)
					tool = FindSeedTool(seed)
					if not tool then break end
				end
			end
			Wait(0.1)
		end
	end)
end

function Module:AutoCollect()
	CreateThread("AutoCollect", function()
		local Remotes
		repeat
			local ok, res = pcall(function()
				Remotes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Remotes"))
				return Remotes and Remotes.Crops and Remotes.Crops.Collect
			end)
			task.wait(1)
		until ok and res

		local CropCollectRemote = Remotes.Crops.Collect

		local function MatchMutations(crop, filter)
			if filter == "Any" or table.find(filter, "Any") then return true end
			local attrs = crop:GetAttributes()
			for name, val in pairs(attrs) do
				if val == true and table.find(filter, name) then
					return true
				end
			end
			return false
		end

		local function MatchVariants(crop, filter)
			if filter == "Any" or table.find(filter, "Any") then return true end
			local var = crop:FindFirstChild("Variant")
			return var and var:IsA("StringValue") and table.find(filter, var.Value)
		end

		while ExecCmd.AutoCollect do
			if #lp.Backpack:GetChildren() >= 200 then task.wait(0.3) continue end

			local garden
			for _, plot in ipairs(workspace.Farm:GetChildren()) do
				local owner = plot:FindFirstChild("Important") and plot.Important:FindFirstChild("Data") and plot.Important.Data:FindFirstChild("Owner")
				if owner and owner.Value == lp.Name then
					garden = plot.Important:FindFirstChild("Plants_Physical")
					break
				end
			end

			if garden then
				local SelectedMut = ExecCmd.SelectedMutations
				local SelectedVar = ExecCmd.SelectedVariants
				local batch = {}

				for _, prompt in ipairs(garden:GetDescendants()) do
					if #batch >= 10 then break end
					if prompt:IsA("ProximityPrompt") and prompt.Enabled and CollectionService:HasTag(prompt, "CollectPrompt") then
						local crop = prompt.Parent and prompt.Parent.Parent
						if crop and MatchMutations(crop, SelectedMut) and MatchVariants(crop, SelectedVar) then
							table.insert(batch, crop)
						end
					end
				end

				if #batch > 0 then
					pcall(function() CropCollectRemote.send(batch) end)
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

function Module:AutoBuyEggs()
	CreateThread("AutoBuyEggs", function()
		while task.wait() do
			local Selected = typeof(ExecCmd.SelectedEggList) == "string" and { ExecCmd.SelectedEggList } or ExecCmd.SelectedEggList or {}
			pcall(function()
				local Stocks = DataService:GetData().PetEggStock.Stocks
				local Normalize = {}
				for _, name in ipairs(Selected) do
					Normalize[name:lower():gsub("%s+", "")] = true
				end

				for i, stock in ipairs(Stocks) do
					if stock.Stock > 0 then
						if ExecCmd.AutoBuyAllEggs or Normalize[stock.EggName:lower():gsub("%s+", "")] then
							BuyPetEgg:FireServer(i)
						end
					end
				end
			end)
		end
	end)
end

function Module:AutoFavoriteMutations(Mode)
	CreateThread("Auto" .. Mode .. "Mutations", function()
		while task.wait(0.3) do
			local List = ExecCmd.SelectedFavMutations or {}

			local MutationSet = {}
			for _, Mutation in ipairs(List) do
				MutationSet[Mutation] = true
			end

			for _, Tool in ipairs(lp.Backpack:GetChildren()) do
				if not Tool:IsA("Tool") then continue end

				local HasMutation = false
				for Mutation in pairs(MutationSet) do
					if Tool:GetAttribute(Mutation) == true then
						HasMutation = true
						break
					end
				end

				local IsFavorited = Tool:GetAttribute("Favorite") == true

				if Mode == "Favorite" and HasMutation and not IsFavorited then
					FavoriteToolRemote:FireServer(Tool)
				elseif Mode == "Unfavorite" and not HasMutation and IsFavorited then
					FavoriteToolRemote:FireServer(Tool)
				end
			end
		end
	end)
end


function Module:AutoSell()
	CreateThread("AutoSell", function()
		while task.wait() do
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

					local SellPos = StevenHRP.CFrame * CFrame.new(0, 2, 5)
					Char:PivotTo(SellPos)
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

function Module:AutoGivePollinated()
	CreateThread("AutoGivePollinated", function()
		while task.wait() do
			local Character = lp.Character or lp.CharacterAdded:Wait()
			local Backpack = lp:FindFirstChild("Backpack")

			if Character and Backpack then
				for _, Tool in ipairs(Backpack:GetChildren()) do
					if Tool:IsA("Tool") and string.find(string.lower(Tool.Name), "pollinated") then
						Tool.Parent = Character
						task.wait(0.5)
						for _ = 1, 2 do
							pcall(function()
								HoneyRemote:FireServer("MachineInteract")
							end)
						end

						task.wait(0.5)
					end
				end
			end

			task.wait(0.25)
		end
	end)
end

function Module:AutoHatchEggs()
	CreateThread("AutoHatchEggs", function()
		while task.wait() do
			pcall(function()
				for _, Farm in ipairs(GetFarm()) do
					local Owner = Farm:FindFirstChild("Important") and Farm.Important:FindFirstChild("Data") and Farm.Important.Data:FindFirstChild("Owner")

					if Owner and Owner.Value == lp.Name then
						local EggFolder = Farm.Important:FindFirstChild("Objects_Physical") and Farm.Important.Objects_Physical:FindFirstChild("PetEgg")

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

function Module:AutoPlaceEggs()
	CreateThread("AutoPlaceEggs", function()
		local Wait, Random, Vector3New = task.wait, math.random, Vector3.new
		local Containers = { lp.Backpack }
		local FAR_DISTANCE = 200

		local function GetAvailableEggTools()
			local tools = {}
			local seen = {}
			for _, container in ipairs(Containers) do
				for _, item in ipairs(container:GetChildren()) do
					if item:IsA("Tool") and item.Name:find("Egg") and not seen[item.Name] then
						seen[item.Name] = true
						table.insert(tools, item.Name)
					end
				end
			end
			return tools
		end

		local function FindEggTool(EggName)
			for _, container in ipairs(Containers) do
				for _, item in ipairs(container:GetChildren()) do
					if item:IsA("Tool") and item.Name == EggName then
						return item
					end
				end
			end
		end

		while ExecCmd.AutoPlaceEggs do
			local character = lp.Character or lp.CharacterAdded:Wait()
			Containers[2] = character

			local root = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid then Wait(1) continue end

			local selectedEgg = ExecCmd.SelectedEggList
			local eggs = {}

			if selectedEgg == "Any" then
				eggs = GetAvailableEggTools()
			elseif selectedEgg then
				table.insert(eggs, selectedEgg)
			end

			if #eggs == 0 then Wait(1) continue end

			for _, EggName in ipairs(eggs) do

				local tool = FindEggTool(EggName)

				if not tool:IsDescendantOf(character) then
					pcall(function() tool.Parent = character end)
					local attempts = 0
					repeat Wait(0.1) attempts += 1 until character:FindFirstChild(tool.Name) or attempts > 20
				end

				local offset = Vector3New(Random(-FAR_DISTANCE, FAR_DISTANCE), 1, Random(-FAR_DISTANCE, FAR_DISTANCE))
				local position = root.Position + offset

				pcall(function()
					PlaceEgg:FireServer("CreateEgg", position)
				end)

				Wait(0.1)
				humanoid:UnequipTools()
				Wait(0.1)
			end

			Wait(0.2)
		end
	end)
end

return Automation
