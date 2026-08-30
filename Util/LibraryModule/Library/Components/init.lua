local BASE_URL = "https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/LibraryModuleLibrary/Components"

local function LoadComp(Name)
    local Path1 = "Quantum Onyx Hub/Library/components/" .. Name .. ".lua"
    local Path2 = "scripts/Library/components/" .. Name .. ".lua"
    local Code = nil

    if isfile and isfile(Path1) then
        local Ok, Res = pcall(readfile, Path1)
        if Ok and Res then Code = Res end
    end
    if not Code and isfile and isfile(Path2) then
        local Ok, Res = pcall(readfile, Path2)
        if Ok and Res then Code = Res end
    end
    if not Code then
        local Ok, Res = pcall(game.HttpGet, game, BASE_URL .. "/" .. Name .. ".lua")
        if Ok and Res and not Res:find("404: Not Found") then Code = Res end
    end
    if not Code then
        error("[Quantum Library] Failed to fetch component: " .. tostring(Name))
    end
    return loadstring(Code)()
end

local Components = {
    Button = LoadComp("Button"),
    Toggle = LoadComp("Toggle"),
    Slider = LoadComp("Slider"),
    Dropdown = LoadComp("Dropdown"),
    Textbox = LoadComp("Textbox"),
    Label = LoadComp("Label"),
    ButtonGrid = LoadComp("ButtonGrid"),
}

function Components.AttachAll(Funcs, Context)
    if Components.Button and Components.Button.Attach then Components.Button.Attach(Funcs, Context) end
    if Components.Toggle and Components.Toggle.Attach then Components.Toggle.Attach(Funcs, Context) end
    if Components.Slider and Components.Slider.Attach then Components.Slider.Attach(Funcs, Context) end
    if Components.Dropdown and Components.Dropdown.Attach then Components.Dropdown.Attach(Funcs, Context) end
    if Components.Textbox and Components.Textbox.Attach then Components.Textbox.Attach(Funcs, Context) end
    if Components.Label and Components.Label.Attach then Components.Label.Attach(Funcs, Context) end
    if Components.ButtonGrid and Components.ButtonGrid.Attach then Components.ButtonGrid.Attach(Funcs, Context) end
end

return Components
