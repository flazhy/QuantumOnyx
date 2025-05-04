local Nofitication = {}

local function CreateInstance(class, properties, parent)
    local instance = Instance.new(class)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
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

local GUI = game:GetService("CoreGui"):FindFirstChild("STX_Nofitication")
function Nofitication:Notify(nofdebug, middledebug, all)
    local SelectedType = string.lower(tostring(middledebug.Type))
    
    local Shadow = CreateInstance("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.91525954, 0, 0.936809778, 0),
        Size = UDim2.new(0, 0, 0, 0),
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.400,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118)
    }, GUI)

    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, Shadow)
    ApplyUIStroke(Shadow, Color3.fromRGB(180, 180, 180), 0.8, 1, Enum.ApplyStrokeMode.Border)

    local Window = CreateInstance("Frame", {
        Name = "Window",
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 3),
        Size = UDim2.new(0, 200, 0, 50),
        ZIndex = 2
    }, Shadow)

    CreateInstance("UICorner", { CornerRadius = UDim.new(0, 7) }, Window)
    ApplyUIStroke(Window, Color3.fromRGB(180, 180, 180), 0.8, 1, Enum.ApplyStrokeMode.Border)

    local Outline_A = CreateInstance("Frame", {
        Name = "Outline_A",
        BackgroundColor3 = middledebug.OutlineColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(0, 230, 0, 2),
        ZIndex = 5
    }, Window)
    
    local WindowTitle = CreateInstance("TextLabel", {
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
    

    if SelectedType == "default" then
        local function ORBHB_fake_script()
            local script = Instance.new('LocalScript', Shadow)
        
            Shadow:TweenSize(UDim2.new(0, 240, 0, 90), "Out", "Linear", 0.2)
            Window.Size = UDim2.new(0, 230, 0, 70)
            Outline_A:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Linear", middledebug.Time)
    
            wait(middledebug.Time)
        
            Shadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
            
            wait(0.2)
            Shadow:Destroy()
        end
        coroutine.wrap(ORBHB_fake_script)()
    elseif SelectedType == "image" then
        Shadow:TweenSize(UDim2.new(0, 240, 0, 90), "Out", "Linear", 0.2)
        Window.Size = UDim2.new(0, 230, 0, 80)
        WindowTitle.Position = UDim2.new(0, 24, 0, 2)
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

        local function ORBHB_fake_script()
            local script = Instance.new('LocalScript', Shadow)
        
            Outline_A:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Linear", middledebug.Time)

            wait(middledebug.Time)
        
            Shadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
            
            wait(0.2)
            Shadow:Destroy()
        end
        coroutine.wrap(ORBHB_fake_script)()
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
            BackgroundTransparency = 1.000,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 28, 0, 76),
            Size = UDim2.new(0, 18, 0, 18),
            ZIndex = 5,
            AutoButtonColor = false,
            Image = "http://www.roblox.com/asset/?id=6031094667",
            ImageColor3 = Color3.fromRGB(83, 230, 50)
        }, Window)

        local function ORBHB_fake_script()
            local script = Instance.new('LocalScript', Shadow)
        
            local Stilthere = true
            local function Unchecked()
                pcall(function()
                    all.Callback(false)
                end)
                Shadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
                
                wait(0.2)
                Shadow:Destroy()
                Stilthere = false
            end
            local function Checked()
                pcall(function()
                    all.Callback(true)
                end)
                Shadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
                
                wait(0.2)
                Shadow:Destroy()
                Stilthere = false
            end
            Uncheck.MouseButton1Click:Connect(Unchecked)
            Check.MouseButton1Click:Connect(Checked)
            
            Outline_A:TweenSize(UDim2.new(0, 0, 0, 2), "Out", "Linear", middledebug.Time)
    
            wait(middledebug.Time)

            if Stilthere == true then
        
                Shadow:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Linear", 0.2)
                
                wait(0.2)
                Shadow:Destroy()
            end
        end
        coroutine.wrap(ORBHB_fake_script)()
    end
end

return Nofitication
