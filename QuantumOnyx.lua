local Scripts = {
    [2753915549] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua",
    [4442272183] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua",
    [7449423635] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua",

    [126884695634066] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/GAG.lua",
}

local function fetch(url)
    local ok, data = pcall(game.HttpGet, game, url)
    return ok and data or nil
end

local function loadFor(placeId)
    local url = Scripts[placeId]
    if not url then return end
    local source = fetch(url)
    local fn, err = loadstring(source)
    task.spawn(fn)
end

loadFor(game.PlaceId)
