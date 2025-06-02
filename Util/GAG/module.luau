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

	local Wait, Random, V3, Clock = task.wait, math.random, Vector3.new, os.clock
	local Containers = { lp.Backpack }
	local CharParts, SeenSeeds = {}, {}
	local CanFire, LastFire = true, 0
	local FireDelay = 0.25

	local function DelayFire()
		CanFire = false
		task.delay(FireDelay, function() CanFire = true end)
	end

	local function FindTool(seed): Tool?
		for _, container in Containers do
			for _, item in container:GetChildren() do
				if item:IsA("Tool") and item.Name:find(seed) and item.Name:find("Seed") then
					return item
				end
			end
		end
	end

	local function CacheCharParts(char)
		table.clear(CharParts)
		for _, p in char:GetDescendants() do
			if p:IsA("BasePart") then CharParts[#CharParts + 1] = p end
		end
	end

	local function SetCollision(state)
		for _, part in CharParts do
			part.CanCollide = state
		end
	end

	while ExecCmd.AutoPlant do
		local char = lp.Character or lp.CharacterAdded:Wait()
		Containers[2] = char

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then Wait(1) continue end

		CacheCharParts(char)
		local farm = GetFarm(lp)
		local sp = farm and farm:FindFirstChild("Spawn_Point")
		if sp and (root.Position - sp.Position).Magnitude > 30 then
			root.CFrame = sp.CFrame
			Wait(1.5)
		end

		local plantFolder = farm and farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plant_Locations")
		if not plantFolder then Wait(1) continue end

		local spots = {}
		for _, p in plantFolder:GetDescendants() do
			if p:IsA("BasePart") and p.Name:find("Can_Plant") then
				spots[#spots + 1] = p
			end
		end
		if #spots == 0 then Wait(1) continue end

		local mode, style = ExecCmd.PlantMode or "Pathways", ExecCmd.PlantStyle or "Random"
		local seeds, seedPref = {}, ExecCmd.SeedName or "Any"

		if seedPref == "Any" then
			table.clear(SeenSeeds)
			for _, container in Containers do
				for _, item in container:GetChildren() do
					if item:IsA("Tool") and item.Name:find("Seed") then
						local name = item.Name:gsub(" Seed.*", "")
						if not SeenSeeds[name] then
							SeenSeeds[name] = true
							seeds[#seeds + 1] = name
						end
					end
				end
			end
		else
			seeds[1] = seedPref
		end

		for _, seed in seeds do
			local tool = FindTool(seed)
			if not tool then continue end
			local lastPos

			while ExecCmd.AutoPlant and tool and tool:IsDescendantOf(char) do
				local spot = spots[Random(1, #spots)]
				local offset = (style == "Stacked" and lastPos) and V3(Random(-3, 3), 0, Random(-3, 3)) or
					V3(Random(-spot.Size.X / 2, spot.Size.X / 2), 2, Random(-spot.Size.Z / 2, spot.Size.Z / 2))
				local pos = (style == "Stacked" and lastPos) and (lastPos + offset) or (spot.Position + offset)

				if not tool:IsDescendantOf(char) then
					tool.Parent = char
					repeat Wait() until char:FindFirstChild(tool.Name)
				end

				if CanFire and Clock() - LastFire >= FireDelay then
					if mode == "Bypass" then
						PlantRemote:FireServer(pos, seed)
					else
						local dist = (root.Position - pos).Magnitude
						if dist > 1 then
							SetCollision(false)
							local done = false
							local conn = hum.MoveToFinished:Connect(function() done = true end)
							hum:MoveTo(pos)
							for _ = 1, 30 do
								if done or not ExecCmd.AutoPlant then break end
								Wait(0.1)
							end
							conn:Disconnect()
							SetCollision(true)
						end
						if ExecCmd.AutoPlant then
							PlantRemote:FireServer(pos, seed)
						end
					end
					LastFire = Clock()
					DelayFire()
				end

				lastPos = pos
				Wait(0.15)
				hum:UnequipTools()
				tool = FindTool(seed)
			end
		end

		Wait(0.2)
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

Module.AutoBuyEggs = function(): nil
	if Threads.AutoBuyEggs then return end
	type Types = { EggStock: { EggName: string, Stock: number }, Data: { PetEggStock: { Stocks: { Types.EggStock } } } }
	Threads.AutoBuyEggs = task.spawn(function()
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
		Threads.AutoBuyEggs = nil
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
