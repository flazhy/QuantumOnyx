local Notification = {}

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
    }, game:GetService("CoreGui"))

    CreateInstance("UIListLayout", {
        Name = "STX_NofiticationUIListLayout",
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    }, GUI)
end

local function ApplyUIStroke(parent, color, transparency, size, mode)
    return CreateInstance("UIStroke", {
        Parent = parent,
        Color = color,
        Transparency = transparency,
        Thickness = size or 1,
        ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
    }, parent)
end

function Nofitication:Notify(nofdebug, middledebug, all)
    local SelectedType = string.lower(tostring(middledebug.Type))

    local Shadow = CreateInstance("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.915, 0, 0.936, 0),
        Size = UDim2.new(0, 0, 0, 0),
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118)
    }, GUI)

    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, Shadow)
    ApplyUIStroke(Shadow, Color3.fromRGB(180, 180, 180), 0.8)

    local Window = CreateInstance("Frame", {
        Name = "Window",
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 3),
        Size = UDim2.new(0, 200, 0, 50),
        ZIndex = 2
    }, Shadow)

    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, Window)
    ApplyUIStroke(Window, Color3.fromRGB(180, 180, 180), 0.8)

    local Outline_A = CreateInstance("Frame", {
        Name = "Outline_A",
        BackgroundColor3 = middledebug.OutlineColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(0, 230, 0, 2),
        ZIndex = 5
    }, Window)

    CreateInstance("TextLabel", {
        Name = "WindowTitle",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 2),
        Size = UDim2.new(0, 222, 0, 22),
        ZIndex = 4,
        Font = Enum.Font.GothamSemibold,
        Text = nofdebug.Title,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, Window)

    CreateInstance("TextLabel", {
        Name = "WindowDescription",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 34),
        Size = UDim2.new(0, 216, 0, 40),
        ZIndex = 4,
        Font = Enum.Font.GothamSemibold,
        Text = nofdebug.Description,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, Window)

    local function AnimateDestroy(time)
        Outline_A:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Linear", time)
        task.wait(time)
        Shadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
        task.wait(0.2)
        Shadow:Destroy()
    end

    if SelectedType == "default" then
        Shadow:TweenSize(UDim2.new(0, 240, 0, 90), "Out", "Linear", 0.2)
        Window.Size = UDim2.new(0, 230, 0, 70)
        coroutine.wrap(function()
            AnimateDestroy(middledebug.Time)
        end)()

    elseif SelectedType == "image" then
        Shadow:TweenSize(UDim2.new(0, 240, 0, 90), "Out", "Linear", 0.2)
        Window.Size = UDim2.new(0, 230, 0, 80)

        local WindowTitle = Window:FindFirstChild("WindowTitle")
        if WindowTitle then
            WindowTitle.Position = UDim2.new(0, 24, 0, 2)
        end

        CreateInstance("ImageButton", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 4, 0, 4),
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 5,
            AutoButtonColor = false,
            Image = all.Image,
            ImageColor3 = all.ImageColor
        }, Window)

        coroutine.wrap(function()
            AnimateDestroy(middledebug.Time)
        end)()

    elseif SelectedType == "option" then
        Shadow:TweenSize(UDim2.new(0, 240, 0, 110), "Out", "Linear", 0.2)
        Window.Size = UDim2.new(0, 230, 0, 100)

        local Uncheck = CreateInstance("ImageButton", {
            Name = "Uncheck",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 7, 0, 76),
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 5,
            AutoButtonColor = false,
            Image = "http://www.roblox.com/asset/?id=6031094678",
            ImageColor3 = Color3.fromRGB(255, 84, 84)
        }, Window)

        local Check = CreateInstance("ImageButton", {
            Name = "Check",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 28, 0, 76),
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 5,
            AutoButtonColor = false,
            Image = "http://www.roblox.com/asset/?id=6031094667",
            ImageColor3 = Color3.fromRGB(83, 230, 50)
        }, Window)

        local Stilthere = true

        local function CloseWithCallback(state)
            pcall(function()
                all.Callback(state)
            end)
            Shadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
            task.wait(0.2)
            Shadow:Destroy()
            Stilthere = false
        end

        Uncheck.MouseButton1Click:Connect(function()
            CloseWithCallback(false)
        end)
        Check.MouseButton1Click:Connect(function()
            CloseWithCallback(true)
        end)

        coroutine.wrap(function()
            AnimateDestroy(middledebug.Time)
        end)()
    end
end

return Notification
