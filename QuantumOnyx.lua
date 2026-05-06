local Directory = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/Games"
local Scripts = {
    [994732206] = Directory.."/BloxFruits.lua",
    [9186719164] = Directory.."/SailorPiece.lua",
    [8191429227] = Directory.."/CutTrees.lua",
    [9792947201] = Directory.."/SlimeRNG.lua",
    [10004244222] = Directory.."/KickALuckyBlock.lua",
}

local url = Scripts[game.GameId]
if url then
    loadstring(game:HttpGet(url))()
end
