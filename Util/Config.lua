local HttpService = game:GetService("HttpService")

local Config = {}
local GameID = tostring(game.GameId)
Config.ConfigFolder = "QuantumOnyxHub/" .. GameID
Config.ConfigFile = Config.ConfigFolder .. "/Settings.json"
Config.SaveDelay = 0.5
Config.Debug = false

local rawConfig = {}
local usedKeys = {}
local SaveScheduled = false

local function dbgPrint(...)
	if Config.Debug then
		print("[Config]", ...)
	end
end

local function CleanKey(label)
	return label:gsub("%s+", ""):gsub("[^%w_.]", "")
end

local function SyncGlobalsFromConfig()
	for key, value in pairs(rawConfig) do
		getgenv()[key] = value
	end
end

local function LoadConfig()
	if not isfolder("QuantumOnyxHub") then
		makefolder("QuantumOnyxHub")
	end
	if not isfolder(Config.ConfigFolder) then
		makefolder(Config.ConfigFolder)
		dbgPrint("Created folder:", Config.ConfigFolder)
	end

	if isfile(Config.ConfigFile) then
		local ok, data = pcall(readfile, Config.ConfigFile)
		if ok and data then
			local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
			if success and typeof(decoded) == "table" then
				for k, v in pairs(decoded) do
					rawConfig[k] = v
				end
				dbgPrint("Config loaded")
				SyncGlobalsFromConfig()
				return
			else
				warn("[Config] Failed to decode config JSON, backing up and regenerating...")
				local backupPath = Config.ConfigFile .. ".bak"
				pcall(function()
					if isfile(backupPath) then delfile(backupPath) end
					writefile(backupPath, data)
				end)
				pcall(delfile, Config.ConfigFile)
				rawConfig = {}
				usedKeys = {}
				dbgPrint("Corrupt config backed up to:", backupPath)
			end
		else
			warn("[Config] Failed to read config file")
		end
	else
		dbgPrint("Config file not found, starting fresh")
	end
end

local function CleanUnusedKeys()
	for key in pairs(rawConfig) do
		if not usedKeys[key] then
			rawConfig[key] = nil
			dbgPrint("Removed unused config key:", key)
		end
	end
end

local function SaveConfig()
	CleanUnusedKeys()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, rawConfig)
	if not ok then
		warn("[Config] Failed to encode config JSON:", encoded)
		return
	end

	local success, formatted = pcall(function()
		return HttpService:JSONEncode(HttpService:JSONDecode(encoded))
	end)
	if success then
		encoded = formatted:gsub(",", ",\n"):gsub("{", "{\n"):gsub("}", "\n}")
	end

	local wrote, err = pcall(writefile, Config.ConfigFile, encoded)
	if not wrote then
		warn("[Config] Failed to write config file:", err)
	else
		dbgPrint("Config saved")
	end
end

local function ScheduleSave()
	if SaveScheduled then return end
	SaveScheduled = true
	task.delay(Config.SaveDelay, function()
		SaveConfig()
		SaveScheduled = false
	end)
end

local ConfigProxy = setmetatable({}, {
	__index = function(_, key)
		return rawConfig[key]
	end,
	__newindex = function(_, key, value)
		if rawConfig[key] ~= value then
			rawConfig[key] = value
			getgenv()[key] = value
			ScheduleSave()
			dbgPrint("Config updated and scheduled save:", key, value)
		end
	end,
})

local patchedSections = setmetatable({}, { __mode = "k" })

local function ApplyConfig(section)
	if patchedSections[section] then return end
	patchedSections[section] = true

	local OrigToggle = section.addToggle
	local OrigSlider = section.addSlider
	local OrigDropdown = section.addDropdown

	function section:addToggle(label, default, callback, description, image)
	local key = CleanKey(label)
	usedKeys[key] = true

	local value = rawConfig[key]
	if value == nil then
		value = default
		ConfigProxy[key] = default
	end

	getgenv()[key] = value

	local function onChanged(val)
		ConfigProxy[key] = val
		if callback then
			local ok, err = pcall(callback, val)
			if not ok then warn("[Config] addToggle callback error:", err) end
		end
	end

	if description or image then
		return OrigToggle(self, label, value, onChanged, description, image)
	else
		return OrigToggle(self, label, value, onChanged)
	end
end


	function section:addSlider(label, min, max, default, callback, increment)
		local key = CleanKey(label)
		usedKeys[key] = true

		local value = rawConfig[key]
		if value == nil then
			value = default
			ConfigProxy[key] = default
		end

		getgenv()[key] = value

		return OrigSlider(self, label, min, max, value, function(val)
			ConfigProxy[key] = val
			if callback then
				local ok, err = pcall(callback, val)
				if not ok then warn("[Config] addSlider callback error:", err) end
			end
		end, increment or 0.1)
	end

	function section:addDropdown(label, default, options, callback, multi)
		local key = CleanKey(label)
		usedKeys[key] = true

		local value = rawConfig[key]
		if value == nil then
			value = default
			ConfigProxy[key] = default
		end

		getgenv()[key] = value

		return OrigDropdown(self, label, value, options, function(val)
			ConfigProxy[key] = val
			if callback then
				local ok, err = pcall(callback, val)
				if not ok then warn("[Config] addDropdown callback error:", err) end
			end
		end, multi)
	end

	dbgPrint("Section patched:", section)
end

function Config.Toggle(section, label, default, callback)
	ApplyConfig(section)
	return section:addToggle(label, default, callback)
end

function Config.Slider(section, label, min, max, default, callback, increment)
	ApplyConfig(section)
	return section:addSlider(label, min, max, default, callback, increment)
end

function Config.Dropdown(section, label, default, options, callback, multi)
	ApplyConfig(section)
	return section:addDropdown(label, default, options, callback, multi)
end

function Config.Reset()
	rawConfig = {}
	usedKeys = {}
	if isfile(Config.ConfigFile) then
		local success, err = pcall(delfile, Config.ConfigFile)
		if not success then
			warn("[Config] Failed to delete config file:", err)
		else
			dbgPrint("Config file deleted")
		end
	end
	dbgPrint("Config reset and file deleted")
end

function Config.ForceSave()
	SaveConfig()
end

LoadConfig()
return Config
