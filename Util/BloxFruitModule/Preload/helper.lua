local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local PlayerGui = plr:WaitForChild("PlayerGui")

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if checkcaller() then
        return OldNamecall(self, ...)
    end
    if typeof(self) == "Instance" and self == PlayerGui then
        if method == "Destroy" or method == "Remove" or method == "ClearAllChildren" then
            return nil
        end
    end

    return OldNamecall(self, ...)
end))
