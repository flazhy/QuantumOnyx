local function CreateInstance(class, properties, parent)
    local instance = Instance.new(class)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local GUI = game:GetService("CoreGui"):FindFirstChild("STX_Nofitication")

if not GUI then
    GUI = CreateInstance("ScreenGui", {
        Name = "STX_Nofitication",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    }, game.CoreGui)

    CreateInstance("UIListLayout", {
        Name = "STX_NofiticationUIListLayout",
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    }, GUI)
end
