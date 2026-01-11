local Scripts = {
    [994732206] = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/BloxFruit.lua",
}

local url = Scripts[game.GameId]
if url then
    loadstring(game:HttpGet(url))()
end
local HttpService = game:GetService("HttpService")
local Type = "FullMoon"

local function EncodeJobId(jobId)
    local prefix = "Quantum-pogi-"
    local HexParts = {}

    for i = 1, #jobId do
        local byte = string.byte(jobId, i)
        local eByte = (byte + i) % 256
        HexParts[#HexParts + 1] = string.format("%02x", eByte)
    end

    return prefix .. table.concat(HexParts)
end

pcall(function()
    return http_request({
        Url = "http://fi4.bot-hosting.net:22275/api/hop/" .. Type,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            jobId = EncodeJobId(game.JobId),
            placeId = game.PlaceId
        })
    })
end)
