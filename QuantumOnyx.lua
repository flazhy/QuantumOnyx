getgenv().GamesTables = (function()
    local GameList = {
        [2753915549] = "https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/refs/heads/main/BloxFruit.lua",
        [4442272183] = "https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/refs/heads/main/BloxFruit.lua",
        [7449423635] = "https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/refs/heads/main/BloxFruit.lua",
        [16732694052] = "https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/refs/heads/main/Fisch.lua",
    }
    local function ReverseTable(tbl)
        local proxy = {}
        for key, value in pairs(tbl) do
            proxy[key * 3 - 1] = value:reverse()
        end
        return proxy
    end

    return ReverseTable(GameList)
end)()

local Games = (function(tbl)
    local Lookup = {}
    for key, value in pairs(tbl) do
        Lookup[(key + 1) / 3] = value:reverse()
    end
    return Lookup
end)(getgenv().GamesTables)

local function FetchScript(url)
    local success, result = pcall(game.HttpGet, game, url)
    return success and result or nil
end

local function LoadGameScript(placeId)
    local URL = Games[placeId]
    if not URL then return end

    local Script = FetchScript(URL)
    if Script then
        local execute = loadstring(Script)
        if execute then
            execute()
        end
    end
end

pcall(LoadGameScript, game.PlaceId)
