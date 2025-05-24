local Scripts = {
    [2753915549] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua",
    [4442272183] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua",
    [7449423635] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/BloxFruit.lua",

    [7436755782] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/main/GAG.lua",
}

local function fetch(url)
    local ok, data = pcall(game.HttpGet, game, url)
    return ok and data or nil
end

local function loadFor(placeId)
    local url = Scripts[placeId]
    if not url then return end

    local source = fetch(url)
    if not source then return warn(("Loader: could not fetch %s"):format(url)) end

    local fn, err = loadstring(source)
    if not fn then return warn(("Loader: compile error – %s"):format(err)) end

    task.spawn(fn)
end

loadFor(game.PlaceId)
