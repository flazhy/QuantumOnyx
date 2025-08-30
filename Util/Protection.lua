local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local rawgetmt = getrawmetatable or debug.getmetatable
local setreadonly = setreadonly or make_writeable
local newcclosure = newcclosure or function(f) return f end
local checkcaller = checkcaller or isourclosure or function() return false end
local getnamecallmethod = getnamecallmethod
local hookmetamethod = hookmetamethod
local hookfunction = hookfunction or replaceclosure
local iscclosure = iscclosure or function(f) return true end

local HookManager = {}
HookManager.Hooks = {}
HookManager.Shadow = {
    Properties = {},
    RemoteWhitelist = {},
    RemoteBlacklist = {},
}

local function safeHook(fn, callback)
    local old = hookfunction(fn, newcclosure(function(...)
        if not checkcaller() then
            return callback(old, ...)
        end
        return old(...)
    end))
    return old
end

function HookManager:SetShadow(obj, key, realValue, fakeValue)
    if not self.Shadow.Properties[obj] then
        self.Shadow.Properties[obj] = {}
    end
    self.Shadow.Properties[obj][key] = {Real = realValue, Fake = fakeValue}
end

function HookManager:GetShadow(obj, key)
    local data = self.Shadow.Properties[obj]
    if data and data[key] then
        return data[key].Real, data[key].Fake
    end
end
function HookManager:HookMethod(obj, methodName, callback)
    if not self.Hooks[obj] then
        self.Hooks[obj] = {}
    end
    local old = safeHook(obj[methodName], function(orig, self, ...)
        return callback(orig, self, ...)
    end)
    self.Hooks[obj][methodName] = old
    return old
end
function HookManager:HookIndex()
    local mt = rawgetmt(game)
    setreadonly(mt, false)

    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if not checkcaller() then
            local real, fake = HookManager:GetShadow(self, key)
            if fake ~= nil then
                return fake
            end
        end
        return old(self, key)
    end))

    self.Hooks["__index"] = old
    setreadonly(mt, true)
    return old
end
function HookManager:HookNewIndex()
    local mt = rawgetmt(game)
    setreadonly(mt, false)

    local old
    old = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
        if not checkcaller() then
            local real, fake = HookManager:GetShadow(self, key)
            if real ~= nil then
                HookManager.Shadow.Properties[self][key].Real = value
                return
            end
        end
        return old(self, key, value)
    end))

    self.Hooks["__newindex"] = old
    setreadonly(mt, true)
    return old
end

function HookManager:HookNamecall()
    local mt = rawgetmt(game)
    setreadonly(mt, false)

    local old
    old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() then
            local name = tostring(self):lower()
            if HookManager.Shadow.RemoteBlacklist[name] then
                return nil
            end
            if method == "FireServer" or method == "InvokeServer" then
                if not HookManager.Shadow.RemoteWhitelist[name] then
                    return nil
                end
            end
        end
        return old(self, ...)
    end))

    self.Hooks["__namecall"] = old
    setreadonly(mt, true)
    return old
end

function HookManager:SpoofIntegrity()
    for obj, tbl in pairs(self.Hooks) do
        for k, fn in pairs(tbl) do
            if not iscclosure(fn) then
                tbl[k] = newcclosure(fn)
            end
        end
    end
end

function HookManager:AutoRehook()
    task.spawn(function()
        while task.wait(5) do
            local mt = rawgetmt(game)
            if mt.__index ~= self.Hooks["__index"] then
                self:HookIndex()
            end
            if mt.__newindex ~= self.Hooks["__newindex"] then
                self:HookNewIndex()
            end
            if mt.__namecall ~= self.Hooks["__namecall"] then
                self:HookNamecall()
            end
        end
    end)
end


return HookManager
