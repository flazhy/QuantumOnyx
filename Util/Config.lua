local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = {}

-- Use GameId for proper multi-place support
local GameID = tostring(game.GameId)
Config.ConfigFolder = "QuantumOnyxHub/" .. GameID
Config.ConfigFile = Config.ConfigFolder .. "/Settings.json"
Config.SaveDelay = 0.5
Config.Debug = false

local config = {}
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

local function MakePath(section, label)
	return section .. "." .. CleanKey(label)
end

local function DeepSet(tbl, path, value)
	local segments = {}
	for segment in string.gmatch(path, "[^%.]+") do
		table.insert(segments, segment)
	end
	for i = 1, #segments - 1 do
		local seg = segments[i]
		tbl[seg] = tbl[seg] or {}
		tbl = tbl[seg]
	end
	tbl[segments[#segments]] = value
end

local function DeepGet(tbl, path)
	for segment in string.gmatch(path, "[^%.]+") do
		tbl = tbl[segment]
		if tbl == nil then return nil end
	end
	return tbl
end

local function DeepDelete(tbl, path)
	local segments = {}
	for segment in string.gmatch(path, "[^%.]+") do
		table.insert(segments, segment)
	end
	for i = 1, #segments - 1 do
		local seg = segments[i]
		tbl = tbl[seg]
		if not tbl then return end
	end
	tbl[segments[#segments]] = nil
end

local function SyncGlobalsFromConfig(tbl, prefix)
	prefix = prefix or ""
	for k, v in pairs(tbl) do
		if typeof(v) == "table" then
			SyncGlobalsFromConfig(v, prefix .. k .. ".")
		else
			getgenv()[prefix .. k] = v
		end
	end
end

local function LoadConfig()
	if not isfolder("QuantumOnyxHub") then makefolder("QuantumOnyxHub") end
	if not isfolder(Config.ConfigFolder) then
		makefolder(Config.ConfigFolder)
		dbgPrint("Created folder:", Config.ConfigFolder)
	end

	if isfile(Config.ConfigFile) then
		local ok, data = pcall(readfile, Config.ConfigFile)
		if ok and data then
			local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
			if success and typeof(decoded) == "table" then
				config = decoded
				dbgPrint("Config loaded")
				SyncGlobalsFromConfig(config)
				return
			else
				warn("[Config] Failed to decode config JSON")
			end
		else
			warn("[Config] Failed to read config file")
		end
	else
		dbgPrint("Config file not found, starting fresh")
	end
	config = {}
end

local function CleanUnusedKeys()
	local function clean(tbl, path)
		for k, v in pairs(tbl) do
			local full = path ~= "" and path .. "." .. k or k
			if typeof(v) == "table" then
				clean(v, full)
				if next(v) == nil then
					tbl[k] = nil
					dbgPrint("Removed empty section:", full)
				end
			elseif not usedKeys[full] then
				tbl[k] = nil
				dbgPrint("Removed unused config key:", full)
			end
		end
	end
	clean(config, "")
end

local function SaveConfig()
	CleanUnusedKeys()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, config)
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

local ConfigProxy = {}
ConfigProxy.__index = function(_, key)
	return config[key]
end
ConfigProxy.__newindex = function(_, key, value)
	config[key] = value
	getgenv()[key] = value
	ScheduleSave()
	dbgPrint("Config updated and scheduled save:", key, value)
end
config = setmetatable(config, ConfigProxy)

local patchedSections = {}

local function ApplyConfig(section, sectionName)
	if patchedSections[section] then return end
	patchedSections[section] = true

	assert(type(section) == "table", "ApplyConfig expects a table")
	assert(type(sectionName) == "string", "sectionName must be a string")

	local OrigToggle = section.addToggle
	local OrigSlider = section.addSlider
	local OrigDropdown = section.addDropdown

	function section:addToggle(label, default, callback)
		local path = MakePath(sectionName, label)
		usedKeys[path] = true
		local value = DeepGet(config, path)
		if value == nil then value = default end
		getgenv()[path] = value

		return OrigToggle(self, label, value, function(val)
			DeepSet(config, path, val)
			getgenv()[path] = val
			ScheduleSave()
			if callback then
				local ok, err = pcall(callback, val)
				if not ok then warn("[Config] addToggle callback error:", err) end
			end
		end)
	end

	function section:addSlider(label, min, max, default, callback, increment)
		local path = MakePath(sectionName, label)
		usedKeys[path] = true
		local value = DeepGet(config, path)
		if value == nil then value = default end
		getgenv()[path] = value

		return OrigSlider(self, label, min, max, value, function(val)
			DeepSet(config, path, val)
			getgenv()[path] = val
			ScheduleSave()
			if callback then
				local ok, err = pcall(callback, val)
				if not ok then warn("[Config] addSlider callback error:", err) end
			end
		end, increment or 0.1)
	end

	function section:addDropdown(label, default, options, callback, multi)
		local path = MakePath(sectionName, label)
		usedKeys[path] = true
		local value = DeepGet(config, path)
		if value == nil then value = default end
		getgenv()[path] = value

		return OrigDropdown(self, label, value, options, function(val)
			DeepSet(config, path, val)
			getgenv()[path] = val
			ScheduleSave()
			if callback then
				local ok, err = pcall(callback, val)
				if not ok then warn("[Config] addDropdown callback error:", err) end
			end
		end, multi)
	end

	dbgPrint("Section patched:", sectionName)
end

function Config.Toggle(section, sectionName, label, default, callback)
	ApplyConfig(section, sectionName)
	return section:addToggle(label, default, callback)
end

function Config.Slider(section, sectionName, label, min, max, default, callback, increment)
	ApplyConfig(section, sectionName)
	return section:addSlider(label, min, max, default, callback, increment)
end

function Config.Dropdown(section, sectionName, label, default, options, callback, multi)
	ApplyConfig(section, sectionName)
	return section:addDropdown(label, default, options, callback, multi)
end

function Config.Reset()
	config = setmetatable({}, ConfigProxy)
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
