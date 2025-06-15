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
local CropCollectRemote: any = require(ReplicatedStorage.Modules:WaitForChild("Remotes")).Crops.Collect


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

local _Env = {}
_Env.Containers = { lp.Backpack }

_Env.CacheCharacterParts = function(character)
	_Env.CharParts = _Env.CharParts or {}
	table.clear(_Env.CharParts)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(_Env.CharParts, part)
		end
	end
end

_Env.SetCollision = function(parts, state)
	for _, part in ipairs(parts) do
		part.CanCollide = state
	end
end

_Env.FindSeedTool = function(Name)
	for _, tool in ipairs(lp.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:find(Name) and tool.Name:find("Seed") then
			return tool
		end
	end
end

_Env.GetFarm = function(player)
	for _, farm in ipairs(workspace.Farm:GetChildren()) do
		local owner = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Data") and farm.Important.Data:FindFirstChild("Owner")
		if owner and owner.Value == player.Name then
			return farm
		end
	end
end

_Env.MatchMutations = function(crop, filter)
	if filter == "Any" or table.find(filter, "Any") then return true end
	local attrs = crop:GetAttributes()
	for name, val in pairs(attrs) do
		if val == true and table.find(filter, name) then
			return true
		end
	end
	return false
end

_Env.MatchVariants = function(crop, filter)
	if filter == "Any" or table.find(filter, "Any") then return true end
	local var = crop:FindFirstChild("Variant")
	return var and var:IsA("StringValue") and table.find(filter, var.Value)
end

_Env.MatchSeedName = function(crop, selectedName)
	return selectedName == "Any" or crop.Name == selectedName or (crop.Parent and crop.Parent.Name == selectedName)
end
_Env.MatchWeightRange = function(crop, selectedRange)
	if selectedRange == "Any" then return true end

	local weight
	local fruits = crop:FindFirstChild("Fruits")
	if fruits then
		for _, item in ipairs(fruits:GetChildren()) do
			local w = item:FindFirstChild("Weight")
			if w and w:IsA("NumberValue") then
				weight = w.Value
				break
			end
		end
	end

	if not weight then
		warn("[WeightMatch] No weight found in crop:", crop:GetFullName())
		return false
	end

	if selectedRange == "100kg above" then
		return weight > 100
	elseif selectedRange == "0 - 100kg" then
		return weight >= 0 and weight <= 100
	else
		local min, max = selectedRange:match("([%d%.]+)%s*%-%s*([%d%.]+)")
		min, max = tonumber(min), tonumber(max)
		if not min or not max then
			warn("[WeightMatch] Failed to parse selectedRange:", selectedRange)
			return false
		end
		return weight >= min and weight <= max
	end
end



function Module:AutoPlant()
	CreateThread("AutoPlant", function()
		local Wait, Random, Vector3New = task.wait, math.random, Vector3.new
		local CanFire, LastFireTime, MinFireInterval = true, 0, 0.25

		while ExecCmd.AutoPlant do
			local character = lp.Character or lp.CharacterAdded:Wait()
			_Env.Containers[2] = character

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if not humanoid or not root then Wait(1) continue end

			_Env.CacheCharacterParts(character)

			local farm = _Env.GetFarm(lp)
			local spawn = farm and farm:FindFirstChild("Spawn_Point")
			if spawn and (root.Position - spawn.Position).Magnitude > 30 then
				root.CFrame = spawn.CFrame
				Wait(1.5)
			end

			local plantingFolder = farm and farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plant_Locations")
			if not plantingFolder then Wait(1) continue end

			local spots = {}
			for _, part in ipairs(plantingFolder:GetDescendants()) do
				if part:IsA("BasePart") and part.Name:find("Can_Plant") then
					table.insert(spots, part)
				end
			end
			if #spots == 0 then Wait(1) continue end

			local seeds = {}
			local selected = ExecCmd.SeedName or "Any"
			if selected == "Any" then
				local seen = {}
				for _, container in ipairs(_Env.Containers) do
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
				local tool = _Env.FindSeedTool(seed)
				if not tool then continue end

				local lastPos
				while ExecCmd.AutoPlant and tool do
					local spot = spots[Random(1, #spots)]
					local size = spot.Size
					local target

					if style == "Stacked" and lastPos then
						target = lastPos + Vector3New(Random(-3, 3), 0, Random(-3, 3))
					else
						target = spot.Position + Vector3New(Random(-size.X / 2, size.X / 2), 2, Random(-size.Z / 2, size.Z / 2))
					end

					if not tool:IsDescendantOf(character) then
						tool.Parent = character
						repeat Wait() until character:FindFirstChild(tool.Name)
					end

					if CanFire and os.clock() - LastFireTime >= MinFireInterval then
						if mode == "Bypass" or (root.Position - target).Magnitude <= 1 then
							PlantRemote:FireServer(target, seed)
						else
							_Env.SetCollision(CharParts, false)
							local done = false
							local conn = humanoid.MoveToFinished:Connect(function() done = true end)
							humanoid:MoveTo(target)

							for _ = 1, 30 do
								if done or not ExecCmd.AutoPlant then break end
								Wait(0.1)
							end
							conn:Disconnect()
							_Env.SetCollision(CharParts, true)

							if ExecCmd.AutoPlant then
								PlantRemote:FireServer(target, seed)
							end
						end

						CanFire = false
						LastFireTime = os.clock()
						task.delay(MinFireInterval, function() CanFire = true end)
					end
					lastPos = target
					Wait(0.25)
					humanoid:UnequipTools()
					Wait(0.25)
					tool = _Env.FindSeedTool(seed)
					if not tool then break end
					tool.Parent = character
					Wait(0.25)
				end
			end

			Wait(0.25)
		end
	end)
end

function Module:AutoCollect()
	CreateThread("AutoCollect", function()
		while ExecCmd.AutoCollect do
			if #lp.Backpack:GetChildren() >= 200 then
				task.wait(0.3)
				continue
			end

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
				local SelectedSeed = ExecCmd.SeedNameC
				local SelectedWeight = ExecCmd.SelectedWeightRange

				print("SelectedWeightRange:", ExecCmd.SelectedWeightRange)
				local batch = {}

				for _, prompt in ipairs(garden:GetDescendants()) do
	if #batch >= 10 then break end
	if prompt:IsA("ProximityPrompt") and prompt.Enabled and CollectionService:HasTag(prompt, "CollectPrompt") then
		local crop = prompt.Parent and prompt.Parent.Parent
		if crop then
			local passedName = _Env.MatchSeedName(crop, SelectedSeed)
			local passedMut = _Env.MatchMutations(crop, SelectedMut)
			local passedVar = _Env.MatchVariants(crop, SelectedVar)
			local passedWeight = _Env.MatchWeightRange(crop, SelectedWeight)

			print(`[AutoCollect] Crop: {crop.Name} | Name: {passedName} | Mut: {passedMut} | Var: {passedVar} | Weight: {passedWeight}`)

			if passedName and passedMut and passedVar and passedWeight then
				table.insert(batch, crop)
				if #batch >= 10 then break end
			end
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
					local SellPos = StevenHRP.CFrame * CFrame.new(0, 2, 5)
					Char:PivotTo(SellPos)
					task.wait(1)

					task.spawn(function()
						pcall(SellRemote.FireServer, SellRemote)
					end)

					task.wait(1)
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
				for _, Farm in ipairs(workspace.Farm:GetChildren()) do
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
