local HttpService = game:GetService("HttpService")

local Config = {}
Config.ConfigFolder = "QuantumOnyxHub"
Config.ConfigFile = Config.ConfigFolder .. "/Settings.json"
Config.SaveDelay = 0.5
Config.Debug = false

local config = {}
local SavedConfig = false

local function dbgPrint(...)
    if Config.Debug then
        print("[Config]", ...)
    end
end

local function CleanKey(label)
    label = label:gsub("%s+", ""):gsub("[^%w_.]", "")
    return label
end

-- Add this helper function to sync loaded config values to getgenv()
local function SyncGlobalsFromConfig()
    for key, value in pairs(config) do
        getgenv()[key] = value
    end
end

local function LoadConfig()
    if not isfolder(Config.ConfigFolder) then
        makefolder(Config.ConfigFolder)
        dbgPrint("Created folder", Config.ConfigFolder)
    end

    if isfile(Config.ConfigFile) then
        local ok, data = pcall(readfile, Config.ConfigFile)
        if ok and data then
            local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
            if success and typeof(decoded) == "table" then
                config = decoded
                dbgPrint("Config loaded")

                -- Sync loaded config values into getgenv() immediately
                SyncGlobalsFromConfig()

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

local function SaveConfig()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, config)
    if not ok then
        warn("[Config] Failed to encode config JSON:", encoded)
        return
    end
    local success, err = pcall(writefile, Config.ConfigFile, encoded)
    if not success then
        warn("[Config] Failed to write config file:", err)
        return
    end
    dbgPrint("Config saved")
end

local function ScheduleSave()
    if SavedConfig then return end
    SavedConfig = true
    spawn(function()
        wait(Config.SaveDelay)
        SaveConfig()
        SavedConfig = false
    end)
end

local ConfigProxy = {}
ConfigProxy.__index = function(_, key)
    return config[key]
end
ConfigProxy.__newindex = function(_, key, value)
    if config[key] ~= value then
        config[key] = value
        getgenv()[key] = value
        ScheduleSave()
        dbgPrint("Config updated:", key, value)
    end
end
config = setmetatable(config, ConfigProxy)

local patchedSections = {}

local function ApplyConfig(section)
    if patchedSections[section] then return end
    patchedSections[section] = true

    assert(section and type(section) == "table", "ApplyConfig expects a table")

    local OrigToggle = section.addToggle
    local OrigSlider = section.addSlider
    local OrigDropdown = section.addDropdown

    assert(type(OrigToggle) == "function", "section.addToggle must be a function")
    assert(type(OrigSlider) == "function", "section.addSlider must be a function")
    assert(type(OrigDropdown) == "function", "section.addDropdown must be a function")

    function section:addToggle(label, default, callback)
        local key = CleanKey(label)
        local value = config[key]
        if value == nil then value = default end
        getgenv()[key] = value

        return OrigToggle(self, label, value, function(val)
            config[key] = val
            if callback then
                local ok, err = pcall(callback, val)
                if not ok then warn("[Config] addToggle callback error:", err) end
            end
        end)
    end
    function section:addSlider(label, min, max, default, callback, increment)
        local key = CleanKey(label)
        local value = config[key]
        if value == nil then value = default end
        getgenv()[key] = value

        return OrigSlider(self, label, min, max, value, function(val)
            config[key] = val
            if callback then
                local ok, err = pcall(callback, val)
                if not ok then warn("[Config] addSlider callback error:", err) end
            end
        end, increment or 0.1)
    end

    function section:addDropdown(label, default, options, callback, multi)
        local key = CleanKey(label)
        local value = config[key]
        if value == nil then value = default end
        getgenv()[key] = value

        return OrigDropdown(self, label, value, options, function(val)
            config[key] = val
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
    config = setmetatable({}, ConfigProxy)
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
