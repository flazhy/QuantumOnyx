
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
local uiControlCache = setmetatable({}, { __mode = "k" })

local function dbgPrint(...)
    if Config.Debug then
        print("[Config]", ...)
    end
end

local function CleanKey(section, label)
    local sectionName = rawget(section, "Name") or tostring(section)
    local sectionID = tostring(sectionName):gsub("table: ", ""):gsub("[^%w]", "")
    local cleanLabel = label:gsub("%s+", ""):gsub("[^%w_.]", "")
    return sectionID .. "_" .. cleanLabel
end

local function SyncGlobalsFromConfig()
    for key, value in pairs(rawConfig) do
        getgenv()[key] = typeof(value) == "table" and table.clone(value) or value
    end
end

local function LoadConfig()
    if not isfolder("QuantumOnyxHub") then makefolder("QuantumOnyxHub") end
    if not isfolder(Config.ConfigFolder) then makefolder(Config.ConfigFolder) end

    if isfile(Config.ConfigFile) then
        local ok, data = pcall(readfile, Config.ConfigFile)
        if ok and data then
            local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
            if success and typeof(decoded) == "table" then
                for k, v in pairs(decoded) do rawConfig[k] = v end
                dbgPrint("Config loaded")
                SyncGlobalsFromConfig()
                return
            else
                warn("[Config] Failed to decode JSON. Backing up.")
                pcall(function()
                    local backupPath = Config.ConfigFile .. ".bak"
                    if isfile(backupPath) then delfile(backupPath) end
                    writefile(backupPath, data)
                end)
                pcall(delfile, Config.ConfigFile)
            end
        end
    end
    dbgPrint("No config file found, starting fresh.")
end

local function CleanUnusedKeys()
    for key in pairs(rawConfig) do
        if not usedKeys[key] then
            rawConfig[key] = nil
            dbgPrint("Removed unused key:", key)
        end
    end
end

local function SaveConfig()
    CleanUnusedKeys()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, rawConfig)
    if not ok then
        warn("[Config] Failed to encode JSON:", encoded)
        return
    end

    local wrote, err = pcall(writefile, Config.ConfigFile, encoded)
    if not wrote then
        warn("[Config] Failed to write file:", err)
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
    __index = function(_, key) return rawConfig[key] end,
    __newindex = function(_, key, value)
        if rawConfig[key] ~= value then
            rawConfig[key] = value
            getgenv()[key] = value
            ScheduleSave()
            dbgPrint("Updated:", key, "=", value)
        end
    end,
})

local patchedSections = setmetatable({}, { __mode = "k" })

local function ApplyConfig(section)
    if patchedSections[section] then return end
    patchedSections[section] = true

    local OrigToggle = rawget(section, "addToggle") or section.addToggle
    local OrigSlider = rawget(section, "addSlider") or section.addSlider
    local OrigDropdown = rawget(section, "addDropdown") or section.addDropdown

    function section:addToggle(label, default, callback, description, image)
        local key = CleanKey(self, label)
        usedKeys[key] = true

        uiControlCache[self] = uiControlCache[self] or {}
        if uiControlCache[self][key] then return uiControlCache[self][key] end

        local value = rawConfig[key]
        if value == nil then
            value = default
            ConfigProxy[key] = default
        end
        getgenv()[key] = value

        local function onChanged(val)
            ConfigProxy[key] = val
            if callback then pcall(callback, val) end
        end

        local toggle
        if type(description) == "string" and type(image) == "string" then
            toggle = OrigToggle(self, label, value, onChanged, description, image)
        elseif type(description) == "string" then
            toggle = OrigToggle(self, label, value, onChanged, description)
        else
            toggle = OrigToggle(self, label, value, onChanged)
        end

        uiControlCache[self][key] = toggle
        return toggle
    end

    function section:addSlider(label, min, max, default, callback, increment)
        local key = CleanKey(self, label)
        usedKeys[key] = true

        local value = rawConfig[key]
        if value == nil then
            value = default
            ConfigProxy[key] = default
        end
        getgenv()[key] = value

        return OrigSlider(self, label, min, max, value, function(val)
            ConfigProxy[key] = val
            if callback then pcall(callback, val) end
        end, increment or 0.1)
    end

    function section:addDropdown(label, default, options, callback, multi)
        local key = CleanKey(self, label)
        usedKeys[key] = true

        local value = rawConfig[key]
        if value == nil then
            if type(default) == "number" and options[default] then
                value = options[default]
            else
                value = default
            end
            ConfigProxy[key] = value
        end
        getgenv()[key] = value

        return OrigDropdown(self, label, value, options, function(val)
            ConfigProxy[key] = val
            if callback then pcall(callback, val) end
        end, multi)
    end

    dbgPrint("Section patched:", section)
end

function Config.Toggle(section, label, default, callback, description, image)
    ApplyConfig(section)
    return section:addToggle(label, default, callback, description, image)
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
    if isfile(Config.ConfigFile) then pcall(delfile, Config.ConfigFile) end
    dbgPrint("Config reset")
end

function Config.ForceSave()
    SaveConfig()
end

function Config.Print()
    print("[Config Dump]")
    for k, v in pairs(rawConfig) do
        print(" ", k, "=", typeof(v), v)
    end
end

LoadConfig()
return Config
