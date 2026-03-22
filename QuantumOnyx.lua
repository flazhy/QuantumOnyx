local Scripts = {
    [994732206] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/BloxFruit.lua",
    [9186719164] = "",
}

local url = Scripts[game.GameId]
if url then
    loadstring(game:HttpGet(url))()
end
