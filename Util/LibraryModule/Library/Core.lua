
local Core = {}
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	pcall(function() LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end)
	LocalPlayer = LocalPlayer or Players.LocalPlayer
end

local Mouse = (LocalPlayer and LocalPlayer:GetMouse()) or { X = 0, Y = 0 }
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")

local _ENV = (getgenv and getgenv()) or _G

Core.Services = {
	Players = Players,
	UIS = UIS,
	Tween = TweenService,
	Text = TextService,
	Http = HttpService,
	LocalPlayer = LocalPlayer,
	Mouse = Mouse,
	CoreGui = CoreGui,
	ENV = _ENV
}

local Util, Tw, Media, ThemeMod = {}, {}, {}, {}
Core.Util = Util
Core.Tween = Tw
Core.Media = Media
Core.Theme = ThemeMod

function Util.Set(inst, k, v) inst[k] = v end
function Util.Protect(GUI)
	if _ENV.HIDEUI then GUI.Parent = _ENV.HIDEUI
	elseif gethui then GUI.Parent = gethui()
	elseif syn and syn.protect_gui then pcall(syn.protect_gui, GUI); GUI.Parent = CoreGui
	else GUI.Parent = CoreGui end
end

local _charAlphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
function Util.RandomName()
	local output = {}
	for i = 1, 16 do
		local r = math.random(1, #_charAlphabet)
		output[i] = _charAlphabet:sub(r, r)
	end
	return table.concat(output)
end

function Util.Create(class, properties, parent)
	local instance = Instance.new(class)
	if properties then
		for key, value in pairs(properties) do
			if key ~= "Children" and key ~= "Parent" then
				pcall(Util.Set, instance, key, value)
			end
		end
		local children = properties["Children"]
		if children then
			for i = 1, #children do
				local child = children[i]
				if child then child.Parent = instance end
			end
		end
		if properties.Parent then
			instance.Parent = properties.Parent
		elseif parent then
			instance.Parent = parent
		end
	elseif parent then
		instance.Parent = parent
	end
	return instance
end

function Util.GuiCenterLocal(gui, root, scale)
	scale = (scale and scale ~= 0) and scale or 1
	local parentAbs = (root and root.AbsolutePosition) or Vector2.zero
	local center = gui.AbsolutePosition + (gui.AbsoluteSize * 0.5)
	return (center.X - parentAbs.X) / scale, (center.Y - parentAbs.Y) / scale
end

function Util.PinAbsToOffset(gui, root, scale)
	scale = (scale and scale ~= 0) and scale or 1
	local pAbs = (root and root.AbsolutePosition) or Vector2.zero
	local abs = gui.AbsolutePosition
	gui.Position = UDim2.fromOffset((abs.X - pAbs.X) / scale, (abs.Y - pAbs.Y) / scale)
	return gui.Position
end

function Util.MakeDraggable(topBar, body, mainScale)
	local activeInput = nil
	local dragStart = Vector3.zero
	local startPos = UDim2.new()

	topBar.InputBegan:Connect(function(input)
		if activeInput ~= nil then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			activeInput = input
			dragStart = input.Position
			startPos = body.Position
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not activeInput then return end
		if input == activeInput or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
			local scale = (mainScale and mainScale.Scale > 0) and mainScale.Scale or 1
			local delta = input.Position - dragStart
			body.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + (delta.X / scale),
				startPos.Y.Scale,
				startPos.Y.Offset + (delta.Y / scale)
			)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input == activeInput then
			activeInput = nil
		end
	end)
end

function Util.BindHover(btn, enterProps, leaveProps, enterStroke, leaveStroke, stroke)
	btn.MouseEnter:Connect(function()
		Tw.Play(btn, enterProps, 0.15, Enum.EasingStyle.Quint)
		if stroke and enterStroke then Tw.Play(stroke, enterStroke, 0.15) end
	end)
	btn.MouseLeave:Connect(function()
		Tw.Play(btn, leaveProps, 0.2, Enum.EasingStyle.Quint)
		if stroke and leaveStroke then Tw.Play(stroke, leaveStroke, 0.2) end
	end)
end

function Util.Trim(text)
	if type(text) ~= "string" then return "" end
	return text:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[ \t]+", " "):gsub("\n[ \t]+", "\n"):gsub("[ \t]+\n", "\n")
end

local _TextSizeCache = {}
function Util.TextHeight(text, font, size, width)
	if not text or text == "" then return 0 end
	font = font or Enum.Font.Gotham
	size = size or 11
	width = width or 150
	local fontName = (typeof(font) == "EnumItem" and font.Name) or tostring(font)
	local cacheKey = tostring(text) .. "\0" .. fontName .. "\0" .. tostring(size) .. "\0" .. tostring(width)
	local cached = _TextSizeCache[cacheKey]
	if cached then return cached end

	local clean = tostring(text):gsub("<[^>]->", "")
	local count = 0
	for _ in clean:gmatch("\n") do count = count + 1 end
	local h = TextService:GetTextSize(clean, size, font, Vector2.new(width, 1e4)).Y
	local result = h + (count * 4) + 2
	_TextSizeCache[cacheKey] = result
	return result
end

function Util.WrapText(text, font, size, width)
	if type(text) ~= "string" or text == "" then return "" end
	return text
end

function Util.DescMetrics(description, font, size, width)
	font = font or Enum.Font.Gotham
	size = size or 11
	width = width or 150
	if typeof(description) ~= "string" or description == "" then return "", 0 end
	local h = Util.TextHeight(description, font, size, width)
	return description, math.max(h, 14)
end

function Tw.Info(duration, style, direction, repeatCount, reverses, delayTime)
	return TweenInfo.new(duration, style or Enum.EasingStyle.Cubic, direction or Enum.EasingDirection.Out, repeatCount or 0, reverses or false, delayTime or 0)
end

function Tw.Play(target, properties, durationOrInfo, style, direction, complete)
	if not target then return nil end
	if typeof(durationOrInfo) == "number" and durationOrInfo == 0 then
		for k, v in pairs(properties) do pcall(Util.Set, target, k, v) end
		if typeof(complete) == "function" then complete() end
		return nil
	end
	local info = typeof(durationOrInfo) == "TweenInfo" and durationOrInfo or Tw.Info(durationOrInfo or 0.25, style, direction)
	local tween = TweenService:Create(target, info, properties)
	if typeof(complete) == "function" then
		local conn; conn = tween.Completed:Connect(function(state)
			if conn then conn:Disconnect() end
			if state == Enum.PlaybackState.Completed then complete() end
		end)
	end
	tween:Play(); return tween
end

function Tw.Group()
	local list = {}
	return {
		Play = function(_, target, properties, durationOrInfo, style, direction, complete)
			local tw = Tw.Play(target, properties, durationOrInfo, style, direction, complete)
			if tw then list[#list + 1] = tw end
			return tw
		end,
		Cancel = function()
			for i = 1, #list do local tw = list[i]; if tw then pcall(function() tw:Cancel() end) end end
			table.clear(list)
		end,
	}
end

function Media.PathToAsset(path, folderName)
	if type(path) ~= "string" or path == "" then return nil end
	local trimmed = path:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then return nil end
	if trimmed:match("^%d+$") then
		return "rbxassetid://" .. trimmed
	end
	if trimmed:find("^rbxassetid://") or trimmed:find("^rbxasset://") or trimmed:find("^http://") or trimmed:find("^https://") then
		return trimmed
	end
	local customAssetFn = getcustomasset or (_ENV and _ENV.getcustomasset) or getsynasset or (_ENV and _ENV.getsynasset)
	if customAssetFn then
		local ok, asset = pcall(customAssetFn, trimmed)
		if ok and type(asset) == "string" and asset ~= "" then return asset end
		if folderName then
			local folderPath1 = folderName .. "/" .. trimmed
			ok, asset = pcall(customAssetFn, folderPath1)
			if ok and type(asset) == "string" and asset ~= "" then return asset end

			local folderPath2 = folderName .. "\\" .. trimmed
			ok, asset = pcall(customAssetFn, folderPath2)
			if ok and type(asset) == "string" and asset ~= "" then return asset end
		end
		ok, asset = pcall(function() return customAssetFn(trimmed, true) end)
		if ok and type(asset) == "string" and asset ~= "" then return asset end
	end
	return trimmed
end

function Media.ListImages(folder)
	local images = {}
	if not (isfolder and listfiles and isfolder(folder)) then return images end
	local ok, files = pcall(listfiles, folder)
	if not ok or not files then return images end
	for _, path in ipairs(files) do
		local lower = string.lower(path)
		if lower:find("%.png") or lower:find("%.jpe?g") or lower:find("%.webp") or lower:find("%.gif") or lower:find("%.bmp") then
			table.insert(images, path)
		end
	end
	table.sort(images)
	return images
end

function Media.ListVideos(folder)
	local videos = {}
	if not (isfolder and listfiles and isfolder(folder)) then return videos end
	local ok, files = pcall(listfiles, folder)
	if not ok or not files then return videos end
	for _, path in ipairs(files) do
		local lower = string.lower(path)
		if lower:find("%.webm") or lower:find("%.mp4") or lower:find("%.mov") or lower:find("%.mkv") or lower:find("%.avi") then
			table.insert(videos, path)
		end
	end
	table.sort(videos)
	return videos
end

function Media.IsVideo(path)
	if type(path) ~= "string" then return false end
	local lower = string.lower(path)
	return lower:find("%.webm") or lower:find("%.mp4") or lower:find("%.mov") or lower:find("%.mkv") or lower:find("%.avi")
end

local ThemeManager = _ENV.QuantumThemeManager
if not ThemeManager then
	pcall(function()
		ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/Util/LibraryModule/Themes.lua"))()
		_ENV.QuantumThemeManager = ThemeManager
	end)
end
ThemeMod.Manager = ThemeManager
function ThemeMod.Color(name)
	if ThemeManager and ThemeManager.Current and ThemeManager.Current[name] then return ThemeManager.Current[name] end
	return Color3.fromRGB(255, 0, 255)
end

return Core
