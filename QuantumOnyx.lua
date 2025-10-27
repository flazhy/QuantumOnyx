local Scripts = {
    [994732206] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/BloxFruit.lua", -- Blox Fruits
}

local url = Scripts[game.GameId]
if url then
    local success, response = pcall(game.HttpGet, game, url)
    if success and response then
        local loadSuccess, fn = pcall(loadstring, response)
        if loadSuccess and type(fn) == "function" then
            task.spawn(fn)
        else
            warn("[Loader] Failed to compile script from:", url)
        end
    else
        warn("[Loader] Failed to fetch script:", url)
    end
else
    warn(string.format("[Loader] No script found for GameId %d", game.GameId))
end
