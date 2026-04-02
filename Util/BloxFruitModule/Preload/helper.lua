local Guard = (function()
    local Players = game:GetService("Players")
    local plr = Players.LocalPlayer
    local PlayerGui = plr:WaitForChild("PlayerGui")
    local BLOCKED_METHODS = {
        Destroy = true,
        Remove = true,
        ClearAllChildren = true,
    }
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if checkcaller() then
            return OldNamecall(self, ...)
        end
        if typeof(self) == "Instance" and self == PlayerGui and BLOCKED_METHODS[method] then
            task.defer(function()
                warn(("[Guard] Blocked '%s' on PlayerGui"):format(method))
            end)
            return nil
        end
        return OldNamecall(self, ...)
    end))
    task.defer(function()
        print("[Guard] PlayerGui protection active")
    end)
end)()
