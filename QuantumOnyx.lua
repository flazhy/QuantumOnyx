local Scripts = {
    [994732206] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/Games/BloxFruits.lua",
    [9186719164] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/Games/SailorPiece.lua",
}

local url = Scripts[game.GameId]
if url then
    loadstring(game:HttpGet(url))()
end
