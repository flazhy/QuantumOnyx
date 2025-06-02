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
			if not (ExecCmd.AutoBuyEgg or ExecCmd.AutoBuyAllEggs) then continue end

			local Selected = typeof(ExecCmd.SelectedEggList) == "string"
				and { ExecCmd.SelectedEggList }
				or ExecCmd.SelectedEggList or {}

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

return Automation
