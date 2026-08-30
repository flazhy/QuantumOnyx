local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local SaveSystem = {
	FolderName = "Quantum Onyx Hub",
	Settings = {},
	_Keys = {},
	RegisteredControls = {},
	ActiveProfile = "[Auto]",
}

function SaveSystem:RegisterKey(Key)
	self._Keys[Key] = true
end

function SaveSystem:RegisterControl(Key, ControlData)
	if not Key then return end
	self._Keys[Key] = true
	self.RegisteredControls[Key] = ControlData
end

function SaveSystem:PruneStaleKeys()
	if not next(self._Keys) then return end
	local Changed = false
	for K in pairs(self.Settings) do
		if K:sub(1, 1) ~= "_" and not self._Keys[K] then self.Settings[K] = nil; Changed = true end
	end
	local Slots = self:Get("_saveSlots", {})
	local SlotChanged = false
	for _, V in ipairs(Slots) do
		if V.data then
			for K in pairs(V.data) do
				if not self._Keys[K] then V.data[K] = nil; SlotChanged = true end
			end
		end
	end
	if Changed then self:Save() end
	if SlotChanged then self:Save("_saveSlots", Slots) end
end

local JsonEncode = function(Table) return HttpService:JSONEncode(Table) end
local JsonDecode = function(String) return HttpService:JSONDecode(String) end
local _FileName = nil

function SaveSystem:GetPlayerName()
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer then pcall(function() LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end) end
	local Name = LocalPlayer and LocalPlayer.Name
	if not Name or Name == "" then
		Name = "User_" .. tostring(LocalPlayer and LocalPlayer.UserId or "0")
	end
	return Name:gsub("[^%w]", "")
end

function SaveSystem:GetGameId()
	local GameId = 0
	pcall(function() GameId = game.GameId end)
	if not GameId or GameId == 0 then
		pcall(function() GameId = game.PlaceId end)
	end
	return tostring(GameId or 0)
end

function SaveSystem:GetFileName(CustomName)
	local PlayerName = self:GetPlayerName()
	local GameId = self:GetGameId()
	if CustomName and type(CustomName) == "string" and CustomName ~= "" then
		local BaseClean = CustomName:gsub("[^%w%s]", ""):gsub("%s+", "_")
		return PlayerName .. "-" .. BaseClean .. "-" .. GameId .. ".json"
	end
	if not _FileName then
		local Ok, Name = pcall(function()
			return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
		end)
		local GameName = (Ok and Name) and Name:gsub("[^%w%s]", ""):gsub("%s+", "_") or GameId
		_FileName = PlayerName .. "-" .. GameName .. "-" .. GameId .. ".json"
	end
	return _FileName
end

function SaveSystem:Save(Key, Value)
	if Key ~= nil then self.Settings[Key] = Value end
	if not isfolder(self.FolderName) then pcall(makefolder, self.FolderName) end
	pcall(writefile, self.FolderName .. "/" .. self:GetFileName(), JsonEncode(self.Settings))
end

function SaveSystem:Load()
	if not isfolder(self.FolderName) then pcall(makefolder, self.FolderName) end
	local PrimaryPath = self.FolderName .. "/" .. self:GetFileName()
	local Ok, Content = pcall(readfile, PrimaryPath)
	if not Ok or not Content then
		local PName = self:GetPlayerName()
		local GId = self:GetGameId()
		local LegacyPaths = {
			self.FolderName .. "/" .. PName .. "-" .. GId .. ".json",
			self.FolderName .. "/" .. PName .. ".json",
		}
		for _, Leg in ipairs(LegacyPaths) do
			local LegOk, LegContent = pcall(readfile, Leg)
			if LegOk and LegContent then
				Content = LegContent
				Ok = true
				break
			end
		end
	end
	if Ok and Content then
		local Decoded = nil
		pcall(function() Decoded = JsonDecode(Content) end)
		if type(Decoded) == "table" then
			self.Settings = Decoded
			return Decoded
		end
	end
	self:Save()
	return {}
end

function SaveSystem:Get(Key, Default)
	local Val = self.Settings[Key]
	return Val ~= nil and Val or Default
end

function SaveSystem:GetSnapshot()
	local Snapshot = {}
	for K, V in pairs(self.Settings) do
		if K:sub(1, 1) ~= "_" and self._Keys[K] then
			Snapshot[K] = V
		end
	end
	for K, Control in pairs(self.RegisteredControls) do
		if Snapshot[K] == nil and Control.Get then
			local Ok, Val = pcall(Control.Get)
			if Ok and Val ~= nil then Snapshot[K] = Val end
		end
	end
	return Snapshot
end

function SaveSystem:ApplySnapshot(Data, FireCallbacks)
	if type(Data) ~= "table" then return false end
	FireCallbacks = FireCallbacks ~= false
	for K, V in pairs(Data) do
		if K:sub(1, 1) ~= "_" then
			self.Settings[K] = V
			local Control = self.RegisteredControls[K]
			if Control and Control.Set then
				pcall(Control.Set, V, FireCallbacks)
			end
		end
	end
	self:Save()
	return true
end

function SaveSystem:ResetToDefaults(FireCallbacks)
	FireCallbacks = FireCallbacks ~= false
	for K, Control in pairs(self.RegisteredControls) do
		if Control and Control.Default ~= nil and Control.Set then
			self.Settings[K] = Control.Default
			pcall(Control.Set, Control.Default, FireCallbacks)
		end
	end
	self:Save()
end

function SaveSystem:ElementSave(Key, Value)
	local Auto = true
	if self.IsAutoSave then
		Auto = self:IsAutoSave()
	else
		Auto = self:Get("_opt_AutoSave", true)
	end
	if not Auto then return end
	self:Save(Key, Value)
	local Slots = self:Get("_saveSlots", {})
	local AutoIdx = nil
	for I, S in ipairs(Slots) do
		if S.name == "[Auto]" then AutoIdx = I; break end
	end
	local Snapshot = self:GetSnapshot()
	if AutoIdx then
		Slots[AutoIdx].data = Snapshot
		Slots[AutoIdx].updated = os.date("%Y-%m-%d %H:%M")
	else
		table.insert(Slots, 1, { name = "[Auto]", data = Snapshot, created = os.date("%Y-%m-%d %H:%M"), updated = os.date("%Y-%m-%d %H:%M") })
	end
	self:Save("_saveSlots", Slots)
end

function SaveSystem:ClearAll()
	self.Settings = {}
	if isfolder(self.FolderName) then
		pcall(writefile, self.FolderName .. "/" .. self:GetFileName(), "{}")
	end
end

return SaveSystem
