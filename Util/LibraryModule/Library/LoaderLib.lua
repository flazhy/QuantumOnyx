local Library = {}

local BASE_URL = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/LibraryModule/Library"

local function LoadModule(RelativePath)
    local LocalPath1 = "Quantum Onyx Hub/Library/" .. RelativePath
    local LocalPath2 = "scripts/Library/" .. RelativePath
    local Code = nil

    if isfile and isfile(LocalPath1) then
        local Ok, Content = pcall(readfile, LocalPath1)
        if Ok and Content then Code = Content end
    end

    if not Code and isfile and isfile(LocalPath2) then
        local Ok, Content = pcall(readfile, LocalPath2)
        if Ok and Content then Code = Content end
    end

    if not Code then
        local Ok, Content = pcall(game.HttpGet, game, BASE_URL .. "/" .. RelativePath)
        if Ok and Content and not Content:find("404: Not Found") then
            Code = Content
        end
    end

    if not Code then
        error("[Quantum Library] Failed to load component: " .. tostring(RelativePath))
    end

    local Executable, CompileErr = loadstring(Code)
    if not Executable then
        error("[Quantum Library] Compile error in " .. tostring(RelativePath) .. ": " .. tostring(CompileErr))
    end

    return Executable()
end

local Core = LoadModule("Core.lua")
local SaveSystem = LoadModule("SaveSystem.lua")
local Notification = LoadModule("Notification.lua")
local Translation = LoadModule("Translation.lua")
local Components = LoadModule("components/init.lua")
local Window = LoadModule("Window.lua")

Notification.Init(Core)

Library.SaveSystem = SaveSystem
Library.Notification = Notification
Library.Translation = Translation
Library.Components = Components

Library.Modules = {
    Core = Core,
    Save = SaveSystem,
    Notify = Notification,
    Translation = Translation,
    Components = Components,
    Util = Core.Util,
    Tween = Core.Tween,
    Media = Core.Media,
    Theme = Core.Theme,
    Services = Core.Services,
    ENV = Core.Services.ENV,
}

Window.Register(Library, Core, SaveSystem, Notification, Translation)

Library.Notify = function(self, NofDebug, MiddleDebug)
    return Notification:Notify(NofDebug, MiddleDebug)
end
Library.notify = Library.Notify

Library.destroyGui = function(self)
    return Library:DestroyGui()
end

return Library
