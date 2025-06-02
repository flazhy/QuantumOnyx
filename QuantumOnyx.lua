local ScriptLoader = {}

ScriptLoader.Scripts = {
    [2753915549] = { Url = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua", Title = "BloxFruit" },
    [4442272183] = { Url = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua", Title = "BloxFruit" },
    [7449423635] = { Url = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua", Title = "BloxFruit" },
    [126884695634066] = { Url = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/GAG.lua", Title = "Grow A Garden" },
}

function ScriptLoader:GetScriptEntry(PlaceId: number)
    return self.Scripts[PlaceId]
end

function ScriptLoader:LoadScript(entry: {Url: string, Title: string})
    if not entry then return end
    local ok, fn = pcall(function()
        return loadstring(game:HttpGet(entry.Url))
    end)
    if ok and fn then
        task.spawn(fn)
    end
end

function ScriptLoader:LoadForPlace(PlaceId: number)
    local entry = self:GetScriptEntry(PlaceId)
    self:LoadScript(entry)
end

ScriptLoader:LoadForPlace(game.PlaceId)

return ScriptLoader
