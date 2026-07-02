        task.wait(1.5)
        if LRM_IsUserPremium == true then
            LRMStatusLabel.Text = "Premium Detected"
            LRMStatusLabel.TextColor3 = Color3.fromRGB(80, 230, 130)
            SetStatus("Premium key detected — click Enter Key to activate.", Color3.fromRGB(130, 220, 160))
        elseif LRM_IsUserFree == true then
            LRMStatusLabel.Text = "Free User"
            LRMStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
        else
            LRMStatusLabel.Text = "Not Authenticated"
            LRMStatusLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)
    local SavedKey = LoadSavedKey()
    if SavedKey ~= "" then
        KeyInput.Text = SavedKey
        task.delay(1.0, function()
            if not done then
                SubmitKey(SavedKey)
            end
        end)
    end
    repeat task.wait(0.08) until done
    return isPremium, resultKey
end
local function AuthenticateAndLoad()
    local SavedKey = LoadSavedKey()
    if SavedKey and SavedKey ~= "" then
        local sdk, LuarmorAPI = pcall(function()
            return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
        end)
        if sdk and type(LuarmorAPI) == "table" then
            LuarmorAPI.script_id = SCRIPT_ID
            local check, status = pcall(function()
                return LuarmorAPI.check_key(SavedKey)
            end)
            if check and type(status) == "table" and status.code == "KEY_VALID" then
                getgenv().script_key = SavedKey
                LoadScript("Premium", SavedKey)
                return
            else
                ClearKey()
            end
        end
    end
    task.spawn(function()
        local premium, key = ShowKeyUI()
        if premium then
            LoadScript("Premium", key)
        else
            LoadScript("Free", nil)
        end
    end)
end
AuthenticateAndLoad()
