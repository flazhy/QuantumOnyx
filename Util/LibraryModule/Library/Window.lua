local Window = {}

function Window.Register(Library, Core, SaveSystem, Notification, Translation)
	local UISettings = {}
	local Util = Core.Util
	local Tw = Core.Tween
	local Media = Core.Media
	local ThemeMod = Core.Theme
	local ThemeManager = ThemeMod.Manager
	local Creator = Util.Create
	local Players = Core.Services.Players
	local LocalPlayer = Core.Services.LocalPlayer
	local Mouse = Core.Services.Mouse
	local CoreGui = Core.Services.CoreGui
	local UIS = Core.Services.UIS
	local TweenService = Core.Services.Tween
	local TextService = Core.Services.Text
	local HttpService = Core.Services.Http
	local _ENV = Core.Services.ENV
	local TrimText, GetWrappedTextHeight, WrapText, GetDescriptionMetrics = Util.Trim, Util.TextHeight, Util.WrapText, Util.DescMetrics
	local PathToAsset, ListFolderImages, ListFolderVideos, IsVideoPath = Media.PathToAsset, Media.ListImages, Media.ListVideos, Media.IsVideo
	local math_floor, math_max, math_min, math_clamp, math_random, math_abs = math.floor, math.max, math.min, math.clamp, math.random, math.abs
	local string_lower, string_upper, string_sub, string_find, string_format, string_gsub, string_match = string.lower, string.upper, string.sub, string.find, string.format, string.gsub, string.match
	local table_insert, table_remove, table_concat, table_sort, table_clear, table_find, table_clone = table.insert, table.remove, table.concat, table.sort, table.clear, table.find, table.clone
	local task_spawn, task_defer, task_wait, task_delay = task.spawn, task.defer, task.wait, task.delay
	function UISettings:Tween(target, properties, duration, style, direction, complete)
		return Tw.Play(target, properties, duration, style, direction, complete)
	end
	function CircleClick(Button, X, Y)
		task_spawn(function()
			Button.ClipsDescendants = true
			local NewX = X - Button.AbsolutePosition.X
			local NewY = Y - Button.AbsolutePosition.Y
			local Size = math_max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5
			local Circle = Creator("ImageLabel", {
				Name = "Circle", Image = "rbxassetid://266543268", ImageColor3 = Color3.fromRGB(80, 80, 80),
				ImageTransparency = 0.8, BackgroundTransparency = 1, ZIndex = 10,
				Position = UDim2.new(0, NewX, 0, NewY), Size = UDim2.new(0, 0, 0, 0)
			}, Button)
			Tw.Play(Circle, { Size = UDim2.new(0, Size, 0, Size), Position = UDim2.new(0.5, -Size / 2, 0.5, -Size / 2) }, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Tw.Play(Circle, { ImageTransparency = 1 }, 0.45, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, function() Circle:Destroy() end)
		end)
	end
	function ThemeColor(name) return ThemeMod.Color(name) end
	function ApplyTranslation(lang, cb) return Translation.Apply(lang, cb) end
	local TranslationData = Translation

Library.CreateWindow = (function(self, config)
	local NameHub = typeof(config) == "string" and config or config.Title or "Hub"
	if config.SaveFile and type(config.SaveFile) == "string" and config.SaveFile ~= "" then
		_fileName = SaveSystem:GetFileName(config.SaveFile)
		SaveSystem.Settings = {}
		SaveSystem:Load()
	else
		if not _fileName then
			_fileName = SaveSystem:GetFileName()
			SaveSystem:Load()
		end
	end
	local Subtitle = config.Subtitle or "Untitled"
	local Version = config.Version or "v1.0"
	local ThemeName = config.Theme or "Purple"
	local Credits = config.Credits or {}
	local F = {}

	F.IsDeveloperBuild = (function()
		local v = string_lower(tostring(Version))
		return v == "developer" or v == "v.developer" or string_find(v, "developer", 1, true) ~= nil
	end)

	local SelectedTheme = ThemeManager.Themes[ThemeName] or ThemeManager.Themes.Purple
	ThemeManager.Current = SelectedTheme
	function ParseKeySetting(key)
		if key == true then return true, nil end
		if type(key) ~= "table" then return false, nil end
		local enabled, mode = false, nil
		for _, v in ipairs(key) do
			if v == true then
				enabled = true
			elseif type(v) == "string" then
				mode = v
			end
		end
		return enabled, mode
	end

	local KeyConfig, KeyMode = ParseKeySetting(config.Key)
	local FullLock = KeyMode == "Full"
	local KeyLockedElements = {}
	local ToggleRegistry = {}
	local FullLockOverlay = nil
	local _locksCleared = false
	local FreemiumAccepted = false
	local HasIntro = config.Intro ~= false

	function LoadKeyValid()
		local keyPath = SaveSystem.FolderName .. "/Key.json"
		if not isfolder(SaveSystem.FolderName) or not isfile(keyPath) then return false end
		local ok, v = pcall(function() return JsonDecode(readfile(keyPath)) end)
		if not ok or type(v) ~= "table" then return false end
		if type(v.key) ~= "string" or v.key == "" then return false end
		return v.verified == true
	end
	local KeyValid = KeyConfig and LoadKeyValid() or false

	F.HasKeyAccess = (function()
		if not KeyConfig then return true end
		return KeyValid
	end)

	local dummyObj
	F.CreateDummy = (function()
		local dummy = {}
		setmetatable(dummy, {
			__index = function(t, k)
				return function()
					return dummy
				end
			end
		})
		return dummy
	end)
	dummyObj = F.CreateDummy()

	checkCondition = (function(cond)
		if cond == nil then return true end
		if type(cond) == "function" then
			local ok, res = pcall(cond)
			return ok and res
		end
		if type(cond) == "table" and type(cond.fn) == "function" then
			local ok, res = pcall(cond.fn)
			if not (ok and res) then return false end
			return true
		end
		return not not cond
	end)

	IsFullLocked = (function()
		return KeyConfig and FullLock and not KeyValid and not FreemiumAccepted
	end)

	RefreshKeyLock = (function()
		if not KeyValid then
			_locksCleared = false
			return
		end
		if _locksCleared then return end
		_locksCleared = true

		if FullLock and FullLockOverlay then
			FullLockOverlay.Visible = false
		end
		for _, x in ipairs(KeyLockedElements) do
			local Frame = x.frame
			if Frame and Frame.Parent then
			local Blocker = x.blocker
			if Blocker and Blocker.Parent then Blocker:Destroy() end
			for _, v in ipairs(Frame:GetChildren()) do
				if v:IsA("ImageLabel") and v.Image == "rbxassetid://7733992528" then
					v:Destroy()
				end
			end
			Frame.BackgroundTransparency = 0.4
			local AccentBar = Frame:FindFirstChild("AccentBar")
			if AccentBar then AccentBar.BackgroundTransparency = 0 end
			end
		end
		task_defer(function()
			for i, v in ipairs(ToggleRegistry) do
				pcall(function()
					if v.saveKey then
						local saved = SaveSystem:Get(v.saveKey, nil)
						if saved ~= nil then
							SaveSystem.Settings[v.saveKey] = saved
						end
					end
					if v.UpdateFn then v.UpdateFn() end
				end)
				if i % 12 == 0 then task_wait() end
			end
		end)
	end)
	RegisterKeyLocked = (function(frame, locked)
		if not KeyConfig or not locked then return end
		if F.HasKeyAccess() then return end
		frame.BackgroundTransparency = 0.55

		local AccentBar = frame:FindFirstChild("AccentBar")
		if AccentBar then AccentBar.BackgroundTransparency = 0.8 end
		for _, v in ipairs(frame:GetDescendants()) do
			if v:IsA("TextLabel") or v:IsA("TextButton") then
				if v.Name == "ButtonLabel" or v.Name == "ToggleTitle" or v.Name == "SliderTitle" then
					v.TextColor3 = Color3.fromRGB(130, 110, 160)
				end
			end
		end
		Creator("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.new(0, 11, 0, 11),
			Image = "rbxassetid://7733992528",
			ImageColor3 = Color3.fromRGB(140, 110, 190),
			ImageTransparency = 0.3,
			ZIndex = 10,
		}, frame)
		local blocker = Creator("TextButton", {
			Name = "_KeyBlocker",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = 10,
			AutoButtonColor = false,
		}, frame)

		blocker.Activated:Connect(function()
			Library.Notification:Notify({
				Title = "Key Required",
				Description = "Verify your key in the Key System panel to unlock this feature.",
			}, { Time = 3 })
		end)
		table_insert(KeyLockedElements, {
			frame = frame,
			blocker = blocker,
		})
	end)
	local LiveThemeElements = {
		body = nil,
		accentElements = {},
		litGradients = {},
		buttonGradients = {},
	}
	local TabRegistry, SearchBarFrame, SearchRegistry, FavoritesAPI
	FavoritesAPI = {
		List = SaveSystem:Get("_favorites", {}),
		Entries = {},
		Refresh = nil,
	}
	local ApplyTheme = (function(NewThemeName)
		local theme = ThemeManager.Themes[NewThemeName]
		if not theme then return end
		ThemeManager.Current = theme
		SaveSystem:Save("_activeTheme", NewThemeName)

		if LiveThemeElements.body then
			UISettings:Tween(LiveThemeElements.body, { BackgroundColor3 = theme.Body }, 0.28, Enum.EasingStyle.Quint)
		end
		for _, v in ipairs(LiveThemeElements.accentElements) do
			local element, prop, role = v[1], v[2], v[3]
			local color = theme[role] or theme.Accent
			if element and element.Parent then
				UISettings:Tween(element, { [prop] = color }, 0.28, Enum.EasingStyle.Quint)
			end
		end
		for _, v in ipairs(LiveThemeElements.litGradients) do
			if v and v.Parent then v.Color = theme.Lit end
		end
		for _, v in ipairs(LiveThemeElements.buttonGradients) do
			if v and v.Parent then
				v.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, theme.AccentLight),
					ColorSequenceKeypoint.new(1, theme.AccentDark),
				})
			end
		end
		pcall(function()
			if SearchBarFrame then
				local stroke = SearchBarFrame:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = theme.Accent end
			end
			for _, entry in ipairs(TabRegistry or {}) do
				if entry.tabUnderline then
					entry.tabUnderline.BackgroundColor3 = theme.Accent
				end
			end
			if TopFrame then
			end
		end)
	end)
	function RegisterThemeElement(element, prop, role)
		table_insert(LiveThemeElements.accentElements, { element, prop, role or "Accent" })
	end
	function RegisterLitGradient(grad)
		table_insert(LiveThemeElements.litGradients, grad)
	end
	function RegisterButtonGradient(grad)
		table_insert(LiveThemeElements.buttonGradients, grad)
	end

	function CreateAccentBar(parent, opts)
		opts = opts or {}
		local bar = Creator("Frame", {
			Name = "AccentBar",
			BackgroundColor3 = ThemeColor("Accent") or opts.Color or Color3.fromRGB(192, 132, 252),
			BackgroundTransparency = opts.Transparency or 0,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = opts.Size or UDim2.new(0, 2, 0, 14),
			ZIndex = 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}
		}, parent)
		if opts.Gradient then
			local grad = Creator("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, ThemeColor("AccentLight") or Color3.fromRGB(216, 180, 254)),
					ColorSequenceKeypoint.new(1, ThemeColor("AccentDark") or Color3.fromRGB(139, 92, 246)),
				}),
				Rotation = (opts.Gradient and opts.Gradient.Rotation) or 90,
			}, bar)
			RegisterButtonGradient(grad)
		end
		RegisterThemeElement(bar, "BackgroundColor3", "Accent")
		return bar
	end

	local ScreenGui = Creator("ScreenGui", {
		Name = GetRandomString(),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, CoreGui)

	local IsMobileDevice = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local UIScaleMin = IsMobileDevice and 0.45 or 0.50
	local UIScaleMax = 1.80
	local UIScaleDefault = IsMobileDevice and 0.70 or 1.0
	local UIScaleStep = 0.05

	local MainUIScale = Creator("UIScale", {
		Name = "LibraryUIScale",
		Scale = UIScaleDefault,
	}, ScreenGui)

	local LayoutRefreshRegistry = {}

	UnscaledLayout = (function(size)
		local scale = MainUIScale.Scale
		if scale == 0 then return size end
		return size / scale
	end)

	FitScrollCanvas = (function(scroll, layout, axis, pad)
		if not scroll or not layout then return end
		pad = pad or 4
		axis = axis or "Y"
		local content = axis == "X" and layout.AbsoluteContentSize.X or layout.AbsoluteContentSize.Y
		local view = axis == "X" and scroll.AbsoluteSize.X or scroll.AbsoluteSize.Y
		if view < 2 then
			view = axis == "X" and scroll.Size.X.Offset or scroll.Size.Y.Offset
		end
		content = UnscaledLayout(content)
		view = UnscaledLayout(math_max(view, 0))
		if content > 0 then content = content + pad end
		local canvas = math_max(content, 0)
		local needsScroll = content > (view + 1)
		if axis == "X" then
			scroll.CanvasSize = UDim2.new(0, canvas, 0, 0)
			if not needsScroll then
				scroll.CanvasPosition = Vector2.new(0, scroll.CanvasPosition.Y)
			end
		else
			scroll.CanvasSize = UDim2.new(0, 0, 0, canvas)
			if not needsScroll then
				scroll.CanvasPosition = Vector2.new(scroll.CanvasPosition.X, 0)
			end
		end
		scroll.ScrollingEnabled = true
		pcall(function()
			scroll.ElasticBehavior = needsScroll and Enum.ElasticBehavior.WhenScrollable or Enum.ElasticBehavior.Never
		end)
	end)

	local _PendingScrollUpdates = {}
	local _ScrollBatchScheduled = false
	function DebouncedFitScrollCanvas(scroll, layout, axis, pad)
		if not scroll or not layout then return end
		_PendingScrollUpdates[scroll] = { layout = layout, axis = axis or "Y", pad = pad or 2 }
		if not _ScrollBatchScheduled then
			_ScrollBatchScheduled = true
			task_defer(function()
				_ScrollBatchScheduled = false
				for s, data in pairs(_PendingScrollUpdates) do
					_PendingScrollUpdates[s] = nil
					FitScrollCanvas(s, data.layout, data.axis, data.pad)
				end
			end)
		end
	end

	function RegisterLayoutRefresh(fn)
		table_insert(LayoutRefreshRegistry, fn)
	end

	ScaledFontSize = (function(base, minBase)
		local s = MainUIScale.Scale
		if s <= 0 then s = 1 end
		if s < 1 then
			return math_max(math_floor(base * s), 4), 1
		end
		local boost = math_min(math_floor((s - 1) * 10 + 0.5), 6)
		return math_min(base + boost, 18), 1
	end)

	function MakeTextConstraint(baseMax, baseMin)
		local maxS = select(1, ScaledFontSize(baseMax, baseMin))
		local constraint = Creator("UITextSizeConstraint", { MaxTextSize = maxS, MinTextSize = 1 })
		RegisterLayoutRefresh(function()
			local newMax = select(1, ScaledFontSize(baseMax, baseMin))
			constraint.MaxTextSize = newMax
			constraint.MinTextSize = 1
		end)
		return constraint
	end

	function BindScaledText(label, baseSize)
		RegisterLayoutRefresh(function()
			label.TextSize = select(1, ScaledFontSize(baseSize))
		end)
	end

	local layoutRefreshScheduled = false

	RefreshAllLayouts = (function()
		for _, fn in ipairs(LayoutRefreshRegistry) do
			pcall(fn)
		end
	end)

	ScheduleRefreshAllLayouts = (function()
		if layoutRefreshScheduled then return end
		layoutRefreshScheduled = true
		task_defer(function()
			layoutRefreshScheduled = false
			RefreshAllLayouts()
		end)
	end)

	function F.SetUIScalePreview(scale)
		scale = math_clamp(scale, UIScaleMin, UIScaleMax)
		MainUIScale.Scale = scale
		local notifRoot = Library.Notification.GUI and Library.Notification.GUI.Parent
		if notifRoot then
			local notifScale = notifRoot:FindFirstChildOfClass("UIScale")
			if not notifScale then
				notifScale = Creator("UIScale", { Name = "LibraryUIScale" }, notifRoot)
			end
			notifScale.Scale = scale
		end
		return scale
	end

	function F.ApplyUIScale(scale)
		scale = F.SetUIScalePreview(scale)
		ScheduleRefreshAllLayouts()
		return scale
	end

	local AutoScaleEnabled = true
	local UserSetScale = UIScaleDefault

	local function UpdateAutoScale()
		if not AutoScaleEnabled then return end
		local Camera = workspace.CurrentCamera
		if not Camera then return end
		local size = Camera.ViewportSize
		if size.X < 50 or size.Y < 50 then return end

		local refWidth = IsMobileDevice and 800 or 1000
		local refHeight = IsMobileDevice and 460 or 600

		local scaleRatio = math_min(size.X / refWidth, size.Y / refHeight, 1.0)
		local targetScale = math_clamp(UserSetScale * scaleRatio, UIScaleMin, UIScaleMax)
		F.SetUIScalePreview(targetScale)
		ScheduleRefreshAllLayouts()
	end

	do
		local Camera = workspace.CurrentCamera
		if Camera then
			Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScale)
			task_defer(UpdateAutoScale)
		end
	end

	local OriginalApplyUIScale = F.ApplyUIScale
	function F.ApplyUIScale(scale)
		UserSetScale = scale
		return OriginalApplyUIScale(scale)
	end

	local Body = Creator("Frame", {
		BackgroundColor3 = ThemeColor("Body"),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 510, 0, 330),
		Visible = not HasIntro,
		Active = true,
		ClipsDescendants = true,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 10) })
		}
	}, ScreenGui)

	local BodyBackground = Creator("ImageLabel", {
		Name = "BodyBackground",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Image = "",
		ImageTransparency = 0.88,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 10) }),
		}
	}, Body)

	local BodyVideoHolder = Creator("Frame", {
		Name = "BodyVideoHolder",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 0,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 10) }),
		}
	}, Body)

	local BodyVideo = nil
	pcall(function()
		BodyVideo = Instance.new("VideoFrame")
		BodyVideo.Name = "BodyVideo"
		BodyVideo.BackgroundTransparency = 1
		BodyVideo.BorderSizePixel = 0
		BodyVideo.Size = UDim2.new(1, 0, 1, 0)
		BodyVideo.Visible = true
		BodyVideo.Looped = true
		BodyVideo.Volume = 0
		BodyVideo.ZIndex = 0
		BodyVideo.Parent = BodyVideoHolder
	end)

	function ClearBackgroundMedia()
		BodyBackground.Image = ""
		BodyBackground.Visible = false
		if BodyVideoHolder then BodyVideoHolder.Visible = false end
		if BodyVideo then
			pcall(function() BodyVideo.Playing = false end)
			pcall(function() BodyVideo:Pause() end)
			pcall(function() BodyVideo.Video = "" end)
		end
	end

	local _videoLoopThread = nil

	function ApplyBackgroundImage(path, transparency)
		transparency = transparency or SaveSystem:Get("_opt_BgImageTransparency", 0.88)
		if type(path) ~= "string" or path == "" then
			ClearBackgroundMedia()
			SaveSystem:Save("_opt_BgImage", "")
			return
		end

		local isVid = IsVideoPath(path)

		if isVid then
			BodyBackground.Image = ""
			BodyBackground.Visible = false
			local asset = PathToAsset(path)
			if not asset then
				Library.Notification:Notify({ Title = "Video BG", Description = "Could not load video asset. File not found or unsupported." }, { Time = 3 })
				ClearBackgroundMedia()
				return
			end

			if not BodyVideo or not BodyVideo.Parent then
				pcall(function()
					if BodyVideo then BodyVideo:Destroy() end
					BodyVideo = Instance.new("VideoFrame")
					BodyVideo.Name = "BodyVideo"
					BodyVideo.BackgroundTransparency = 1
					BodyVideo.BorderSizePixel = 0
					BodyVideo.Size = UDim2.new(1, 0, 1, 0)
					BodyVideo.Visible = true
					BodyVideo.Looped = true
					BodyVideo.Volume = 0
					BodyVideo.ZIndex = 0
					BodyVideo.Parent = BodyVideoHolder
				end)
			end

			if BodyVideoHolder then BodyVideoHolder.Visible = true end

			if BodyVideo then
				pcall(function()
					BodyVideo.Visible = true
					BodyVideo.Looped = true
					BodyVideo.Volume = 0
					BodyVideo.Video = asset
					BodyVideo.Playing = true
					BodyVideo:Play()
				end)

				task_spawn(function()
					task_wait(0.08)
					pcall(function()
						BodyVideo.Playing = true
						BodyVideo:Play()
					end)
					local t0 = tick()
					while tick() - t0 < 5 do
						local isLoaded = false
						pcall(function() isLoaded = BodyVideo.IsLoaded end)
						if isLoaded then
							pcall(function()
								BodyVideo.Playing = true
								BodyVideo:Play()
							end)
							break
						end
						task_wait(0.2)
					end
				end)

				if not _videoLoopThread then
					_videoLoopThread = task_spawn(function()
						while true do
							task_wait(1.5)
							if BodyVideoHolder and BodyVideoHolder.Visible and BodyVideo and BodyVideo.Parent then
								local isPlaying = false
								pcall(function() isPlaying = BodyVideo.Playing end)
								if not isPlaying then
									pcall(function()
										BodyVideo.Playing = true
										BodyVideo:Play()
									end)
								end
							end
						end
					end)
				end
			end

			SaveSystem:Save("_opt_BgImage", path)
		else
			local asset = PathToAsset(path)
			if not asset then return end
			ClearBackgroundMedia()
			BodyBackground.Visible = true
			BodyBackground.Image = asset
			BodyBackground.ImageTransparency = transparency
			SaveSystem:Save("_opt_BgImage", path)
		end
	end

	local savedBg = SaveSystem:Get("_opt_BgImage", "")
	if savedBg ~= "" then
		task_defer(function() ApplyBackgroundImage(savedBg) end)
	end
	BodyBackground.ImageTransparency = SaveSystem:Get("_opt_BgImageTransparency", 0.88)
	do
		local uiT = SaveSystem:Get("_opt_UITransparency", 0.05)
		Body.BackgroundTransparency = uiT
	end

	LiveThemeElements.body = Body
	Protect_UI(ScreenGui)
	self:DestroyGui()
	self._CurrentGui = ScreenGui
	Library.Notification:Init(Body)

	FullLockOverlay = Creator("Frame", {
		Name = "FullLockOverlay",
		BackgroundColor3 = Color3.fromRGB(6, 4, 12),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 1003,
		Active = true,
		["Children"] = {
			Creator("TextButton", {
				Name = "ClickBlocker",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 1004,
				Active = true,
			}),
			Creator("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 80, 220),
				Transparency = 0.55,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.38, 0),
				Size = UDim2.new(0, 28, 0, 28),
				Image = "rbxassetid://7733992528",
				ImageColor3 = Color3.fromRGB(160, 100, 240),
				ImageTransparency = 0.1,
				ZIndex = 1004,
			}),
			Creator("TextLabel", {
				Name = "LockTitle",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.52, 0),
				Size = UDim2.new(0.85, 0, 0, 22),
				Font = Enum.Font.FredokaOne,
				Text = "Premium Privilege Only",
				TextColor3 = Color3.fromRGB(210, 160, 255),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 1004,
			}),
			Creator("TextLabel", {
				Name = "LockDesc",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.66, 0),
				Size = UDim2.new(0.88, 0, 0, 36),
				Font = Enum.Font.Gotham,
				RichText = true,
				Text =
				'Premium features require a valid key.\n<font color="#34D399">Freemium</font> is still available below.',
				TextColor3 = Color3.fromRGB(180, 160, 210),
				TextSize = 10,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 1004,
			}),
			Creator("TextButton", {
				Name = "FreemiumBtn",
				BackgroundColor3 = Color3.fromRGB(30, 18, 52),
				BackgroundTransparency = 0.15,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.82, 0),
				Size = UDim2.new(0.62, 0, 0, 26),
				Font = Enum.Font.GothamBold,
				Text = "Continue Freemium",
				TextColor3 = Color3.fromRGB(130, 230, 180),
				TextSize = 11,
				AutoButtonColor = false,
				ZIndex = 1005,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Creator("UIStroke", {
						Color = Color3.fromRGB(80, 200, 140),
						Transparency = 0.45,
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}
			}),
			Creator("Frame", {
				BackgroundColor3 = Color3.fromRGB(140, 80, 220),
				BackgroundTransparency = 0.70,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.44, 0),
				Size = UDim2.new(0.55, 0, 0, 1),
				ZIndex = 1004,
				["Children"] = {
					Creator("UIGradient", {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.2, 0),
							NumberSequenceKeypoint.new(0.8, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}
			}),
		}
	}, Body)
	if IsFullLocked() then
		FullLockOverlay.Visible = true
	end
	local TopFrame = Creator("Frame", {
		BackgroundColor3 = ThemeColor("Body"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 32),
		ZIndex = 1005,
		Active = true,
		ClipsDescendants = true,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(1, 0) })
		}
	}, Body)

	local TitleHub = Creator("TextLabel", {
		Name = "TitleHub",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 2),
		Size = UDim2.new(1, -255, 0, 16),
		Font = Enum.Font.FredokaOne,
		Text = NameHub .. " Project",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left
	}, TopFrame)

	local SubtitleLabel = Creator("TextLabel", {
		Name = "SubtitleHub",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 18),
		Size = UDim2.new(1, -255, 0, 12),
		Font = Enum.Font.Gotham,
		RichText = true,
		Text = string.format(
			'<font color="#C084FC">%s</font> • <font color="#FF9E9E">%s</font>',
			Subtitle, os.date("%A")),
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 10,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left
	}, TopFrame)

	function F.SetSubtitleTier()
		if F.IsDeveloperBuild() then
			SubtitleLabel.Text = string.format(
				'<font color="#C084FC">%s</font> • <font color="#7286FF">v.Developer</font> • <font color="#FF9E9E">%s</font>',
				Subtitle, os.date("%A"))
		elseif F.HasKeyAccess() then
			SubtitleLabel.Text = string.format(
				'<font color="#C084FC">%s</font> • <font color="#FFD700">v.Premium</font> • <font color="#FF9E9E">%s</font>',
				Subtitle, os.date("%A"))
		elseif KeyConfig then
			SubtitleLabel.Text = string.format(
				'<font color="#C084FC">%s</font> • <font color="#34D399">v.Freemium</font> • <font color="#FF9E9E">%s</font>',
				Subtitle, os.date("%A"))
		else
			SubtitleLabel.Text = string.format(
				'<font color="#C084FC">%s</font> • <font color="#34D399">%s</font> • <font color="#FF9E9E">%s</font>',
				Subtitle, Version, os.date("%A"))
		end
	end
	function SetSubtitlePremium()
		F.SetSubtitleTier()
	end

	F.SetSubtitleTier()

	local FreemiumBtn = FullLockOverlay and FullLockOverlay:FindFirstChild("FreemiumBtn", true)
	if FreemiumBtn then
		FreemiumBtn.MouseButton1Click:Connect(function()
			FreemiumAccepted = true
			FullLockOverlay.Visible = false
			F.SetSubtitleTier()
		end)
	end

	function F.SyncKeyAccess()
		if KeyConfig then
			KeyValid = LoadKeyValid()
		end
		if KeyValid then
			RefreshKeyLock()
		end
		F.SetSubtitleTier()
	end

	local UIKeybindCode = Enum.KeyCode.RightControl
	local uiKeybindListening = false
	local KeybindValueLabel = nil
	local uiVisible = true

	SaveSystem:RegisterKey("_opt_UIKeybind")
	do
		local saved = SaveSystem:Get("_opt_UIKeybind", "RightControl")
		local code = Enum.KeyCode[saved]
		if code then UIKeybindCode = code end
	end

	local ToggleUIVisible
	ToggleUIVisible = function()
		uiVisible = not uiVisible
		Body.Visible = uiVisible
	end

	local MinimizeButton = Creator("ImageButton", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -34, 0, 16),
		Size = UDim2.new(0, 20, 0, 20),
		ZIndex = 1005,
		Image = "rbxassetid://92966930061759",
	}, Body)

	local CloseButton = Creator("ImageButton", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0, 16),
		Size = UDim2.new(0, 20, 0, 20),
		ZIndex = 1005,
		Image = "rbxassetid://79324227570635",
	}, Body)

	local CreditsBtn = Creator("TextButton", {
		Name = "CreditsBtn",
		BackgroundColor3 = Color3.fromRGB(14, 10, 22),
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -62, 0, 16),
		Size = UDim2.new(0, 83, 0, 23),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 1005,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(160, 100, 240),
				Transparency = 0.72,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),
			Creator("Frame", {
				BackgroundColor3 = Color3.fromRGB(160, 100, 240),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, -7),
				Size = UDim2.new(0, 2, 0, 14),
				ZIndex = 1006,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Creator("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 160, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 60, 220)),
						}),
						Rotation = 90,
					}),
				}
			}),
			Creator("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0.5, -7),
				Size = UDim2.new(0, 14, 0, 14),
				Image = "rbxassetid://83474083071373",
				ImageColor3 = Color3.fromRGB(185, 140, 255),
				ZIndex = 1006,
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 27, 0, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "Credits",
				TextColor3 = Color3.fromRGB(195, 155, 255),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 1006,
			}),
		}
	}, Body)

	local CreditsStroke = CreditsBtn:FindFirstChildOfClass("UIStroke")
	Util.BindHover(
		CreditsBtn,
		{ BackgroundColor3 = Color3.fromRGB(22, 14, 38) },
		{ BackgroundColor3 = Color3.fromRGB(14, 10, 22) },
		{ Transparency = 0.38 },
		{ Transparency = 0.72 },
		CreditsStroke
	)

	local SettingsBtn = Creator("TextButton", {
		Name = "SettingsBtn",
		BackgroundColor3 = Color3.fromRGB(14, 10, 22),
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -153, 0, 16),
		Size = UDim2.new(0, 83, 0, 23),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 1005,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(160, 100, 240),
				Transparency = 0.72,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			}),
			Creator("Frame", {
				BackgroundColor3 = Color3.fromRGB(160, 100, 240),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0.5, -7),
				Size = UDim2.new(0, 2, 0, 14),
				ZIndex = 1006,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Creator("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 160, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 60, 220)),
						}),
						Rotation = 90,
					}),
				}
			}),
			Creator("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0.5, -7),
				Size = UDim2.new(0, 14, 0, 14),
				Image = "rbxassetid://81151604784579",
				ImageColor3 = Color3.fromRGB(185, 140, 255),
				ZIndex = 1006,
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 27, 0, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "Settings",
				TextColor3 = Color3.fromRGB(195, 155, 255),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 1006,
			}),
		}
	}, Body)

	local SettingsStroke = SettingsBtn:FindFirstChildOfClass("UIStroke")
	Util.BindHover(
		SettingsBtn,
		{ BackgroundColor3 = Color3.fromRGB(22, 14, 38) },
		{ BackgroundColor3 = Color3.fromRGB(14, 10, 22) },
		{ Transparency = 0.38 },
		{ Transparency = 0.72 },
		SettingsStroke
	)

	local OverlayDragLock = false

	function F.MakeOverlay(titleText, iconId, dialogW, dialogH, onClose)
		local Blocker = Creator("Frame", {
			Visible = false,
			Active = true,
			BackgroundTransparency = 0.5,
			BackgroundColor3 = Color3.fromRGB(4, 2, 10),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 20,
		}, Body)

		local Dialog = Creator("Frame", {
			Visible = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(11, 8, 18),
			BackgroundTransparency = 0,
			Size = UDim2.new(0, dialogW, 0, dialogH),
			ZIndex = 2000,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 12) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(140, 90, 220),
					Transparency = 0.60,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Creator("Frame", {
					BackgroundColor3 = Color3.fromRGB(80, 40, 160),
					BackgroundTransparency = 0.92,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0.45, 0),
					Position = UDim2.new(0, 0, 0, 0),
					ZIndex = 21,
					["Children"] = {
						Creator("UICorner", { CornerRadius = UDim.new(0, 12) }),
						Creator("UIGradient", {
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0),
								NumberSequenceKeypoint.new(1, 1),
							}),
							Rotation = 90,
						}),
					}
				}),
				Creator("ImageLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 14),
					Size = UDim2.new(0, 20, 0, 20),
					Image = iconId,
					ImageColor3 = Color3.fromRGB(190, 140, 255),
					ZIndex = 22,
				}),
				Creator("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 38),
					Size = UDim2.new(1, -24, 0, 16),
					Font = Enum.Font.FredokaOne,
					Text = titleText,
					TextColor3 = Color3.fromRGB(210, 175, 255),
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex = 22,
				}),
				Creator("Frame", {
					BackgroundColor3 = Color3.fromRGB(160, 100, 255),
					BackgroundTransparency = 0.72,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 57),
					Size = UDim2.new(0.65, 0, 0, 1),
					ZIndex = 22,
					["Children"] = {
						Creator("UIGradient", {
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 1),
								NumberSequenceKeypoint.new(0.2, 0),
								NumberSequenceKeypoint.new(0.8, 0),
								NumberSequenceKeypoint.new(1, 1),
							}),
						}),
					}
				}),
			}
		}, Body)

		local Scroll = Creator("ScrollingFrame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 64),
			Size = UDim2.new(1, -16, 1, -100),
			Active = true,
			ScrollBarThickness = 0,
			ScrollBarImageTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ZIndex = 22,
			["Children"] = {
				Creator("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				}),
				Creator("UIPadding", {
					PaddingTop = UDim.new(0, 3),
					PaddingBottom = UDim.new(0, 3),
					PaddingLeft = UDim.new(0, 2),
					PaddingRight = UDim.new(0, 2),
				}),
			}
		}, Dialog)

		local CloseBtn = Creator("TextButton", {
			Name = "CloseBtn",
			BackgroundColor3 = Color3.fromRGB(30, 18, 52),
			BackgroundTransparency = 0,
			AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.new(0.52, 0, 0, 24),
			Position = UDim2.new(0.5, 0, 1, -9),
			Text = "Close",
			TextColor3 = Color3.fromRGB(180, 135, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			AutoButtonColor = false,
			ZIndex = 22,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(140, 90, 220),
					Transparency = 0.65,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}
		}, Dialog)

		CloseBtn.MouseEnter:Connect(function()
			UISettings:Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(50, 28, 85) }, 0.15, Enum.EasingStyle.Quint)
		end)
		CloseBtn.MouseLeave:Connect(function()
			UISettings:Tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(30, 18, 52) }, 0.2, Enum.EasingStyle.Quint)
		end)

		local isOpen = false

		local function Open()
			isOpen = true
			Blocker.Visible = true
			Dialog.Visible = true
			Dialog.Size = UDim2.new(0, dialogW * 0.5, 0, dialogH * 0.5)
			Dialog.BackgroundTransparency = 0.6
			UISettings:Tween(Dialog, { Size = UDim2.new(0, dialogW, 0, dialogH), BackgroundTransparency = 0,
			}, 0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end

		local function Close()
			if not isOpen then return end
			isOpen = false
			UISettings:Tween(Dialog, {
				Size = UDim2.new(0, dialogW * 0.5, 0, dialogH * 0.5),
				BackgroundTransparency = 0.6,
			}, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
				Dialog.Visible = false
				Blocker.Visible = false
				Dialog.Size = UDim2.new(0, dialogW, 0, dialogH)
				Dialog.BackgroundTransparency = 0
				if onClose then onClose() end
			end)
		end

		local function IsOpen() return isOpen end

		CloseBtn.MouseButton1Click:Connect(Close)
		Blocker.InputBegan:Connect(function(i)
			if OverlayDragLock then return end
			if i.UserInputType == Enum.UserInputType.MouseButton1
				or i.UserInputType == Enum.UserInputType.Touch then
				Close()
			end
		end)

		return Dialog, Scroll, Blocker, Open, Close, IsOpen
	end

	local _, CreditsScroll, _, OpenCredits, CloseCredits, IsCreditsOpen = F.MakeOverlay("Credits",
		"rbxassetid://83474083071373", 270, 270, nil)

	local RoleColors = {
		ServerOwner = Color3.fromRGB(255, 200, 80),
		MainDeveloper = Color3.fromRGB(175, 115, 255),
		WebDesigner = Color3.fromRGB(100, 200, 255),
		Tester = Color3.fromRGB(80, 225, 160),
	}
	if #Credits > 0 then
		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Font = Enum.Font.GothamBold,
			Text = "TEAM",
			TextColor3 = Color3.fromRGB(130, 90, 200),
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 23,
		}, CreditsScroll)
	end

	for _, v in ipairs(Credits) do
		local role       = v.Role or "Developer"
		local name       = v.Name or "Unknown"
		local socialUrl  = v.Url or ""
		local socialIcon = v.UrlIcon or "rbxassetid://83474083071373"
		local socialTag  = v.UrlTag or "View Profile"
		local col        = RoleColors[role] or Color3.fromRGB(175, 115, 255)
		local r, g, b    = col.R, col.G, col.B

		local cardH = (socialUrl ~= "") and 80 or 60

		local Card = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 7, 18),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, cardH),
			ZIndex = 23,
			ClipsDescendants = true,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 12) }),
			}
		}, CreditsScroll)
		Creator("Frame", {
			BackgroundColor3 = col,
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 23,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 12) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(r * 0.5, g * 0.5, b * 0.5)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 4, 12)),
					}),
					Rotation = 135,
				}),
			}
		}, Card)

		local CardStroke = Creator("UIStroke", {
			Color = col,
			Transparency = 0.65,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, Card)
		Creator("Frame", {
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 8),
			Size = UDim2.new(0, 3, 1, -16),
			ZIndex = 25,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, col),
					}),
					Rotation = 90,
				}),
			}
		}, Card)
		local AvatarCircle = Creator("Frame", {
			BackgroundColor3 = Color3.new(r * 0.18, g * 0.18, b * 0.18),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 12, 0, 10),
			Size = UDim2.new(0, 36, 0, 36),
			ZIndex = 25,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke", {
					Color = col,
					Transparency = 0.40,
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Creator("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Font = Enum.Font.FredokaOne,
					Text = string.upper(string.sub(name, 1, 1)),
					TextColor3 = col,
					TextSize = 18,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex = 26,
				}),
			}
		}, Card)

		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 58, 0, 10),
			Size = UDim2.new(1, -148, 0, 16),
			Font = Enum.Font.FredokaOne,
			Text = name,
			TextColor3 = Color3.fromRGB(242, 235, 255),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 25,
		}, Card)

		local RoleBadge = Creator("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.new(r * 0.12, g * 0.12, b * 0.12),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -8, 0, 10),
			Size = UDim2.new(0, 76, 0, 20),
			ZIndex = 25,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Creator("UIStroke", {
					Color = col,
					Transparency = 0.50,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(r * 0.24, g * 0.24, b * 0.24)),
						ColorSequenceKeypoint.new(1, Color3.new(r * 0.08, g * 0.08, b * 0.08)),
					}),
					Rotation = 90,
				}),
				Creator("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = role,
					TextColor3 = col,
					TextSize = 9,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex = 26,
				}),
			}
		}, Card)
		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 58, 0, 28),
			Size = UDim2.new(1, -148, 0, 12),
			Font = Enum.Font.Gotham,
			Text = string.lower(role),
			TextColor3 = Color3.new(r * 0.82, g * 0.82, b * 0.82),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 25,
		}, Card)

		if socialUrl ~= "" then
			Creator("Frame", {
				BackgroundColor3 = col,
				BackgroundTransparency = 0.78,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0, 52),
				Size = UDim2.new(1, -20, 0, 1),
				ZIndex = 25,
				["Children"] = {
					Creator("UIGradient", {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.15, 0),
							NumberSequenceKeypoint.new(0.85, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}
			}, Card)

			Creator("ImageLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 14, 0, 57),
				Size = UDim2.new(0, 13, 0, 13),
				Image = socialIcon,
				ImageColor3 = Color3.new(r * 0.80, g * 0.80, b * 0.80),
				ZIndex = 26,
			}, Card)
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 32, 0, 56),
				Size = UDim2.new(1, -140, 0, 14),
				Font = Enum.Font.Gotham,
				Text = socialTag,
				TextColor3 = Color3.new(r * 0.75, g * 0.75, b * 0.75),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 26,
			}, Card)
			local SocialBtn = Creator("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.new(r * 0.12, g * 0.12, b * 0.12),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -8, 0, 55),
				Size = UDim2.new(0, 68, 0, 20),
				AutoButtonColor = false,
				Text = "",
				ZIndex = 26,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Creator("UIStroke", {
						Color = col,
						Transparency = 0.50,
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
					Creator("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.new(r * 0.26, g * 0.26, b * 0.26)),
							ColorSequenceKeypoint.new(1, Color3.new(r * 0.08, g * 0.08, b * 0.08)),
						}),
						Rotation = 90,
					}),
				}
			}, Card)

			local SocialBtnLabel = Creator("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "COPY LINK",
				TextColor3 = col,
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 27,
			}, SocialBtn)

			local SocialBtnStroke = SocialBtn:FindFirstChildOfClass("UIStroke")

			SocialBtn.MouseEnter:Connect(function()
				UISettings:Tween(SocialBtn, { BackgroundColor3 = Color3.new(r * 0.28, g * 0.28, b * 0.28) }, 0.12, Enum.EasingStyle.Quint)
				UISettings:Tween(SocialBtnStroke, { Transparency = 0.15 }, 0.12)
			end)
			SocialBtn.MouseLeave:Connect(function()
				UISettings:Tween(SocialBtn, { BackgroundColor3 = Color3.new(r * 0.12, g * 0.12, b * 0.12) }, 0.18, Enum.EasingStyle.Quint)
				UISettings:Tween(SocialBtnStroke, { Transparency = 0.50 }, 0.18)
			end)

			local capturedUrl  = socialUrl
			local capturedName = name

			SocialBtn.MouseButton1Click:Connect(function()
				CircleClick(SocialBtn, Mouse.X, Mouse.Y)
				pcall(function() (setclipboard or toclipboard)(capturedUrl) end)
				SocialBtnLabel.Text = "COPIED"
				SocialBtnLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
				UISettings:Tween(SocialBtn, { BackgroundColor3 = Color3.fromRGB(14, 60, 32) }, 0.12, Enum.EasingStyle.Quint)
				task_delay(1.4, function()
					SocialBtnLabel.Text = "COPY LINK"
					SocialBtnLabel.TextColor3 = col
					UISettings:Tween(SocialBtn, { BackgroundColor3 = Color3.new(r * 0.12, g * 0.12, b * 0.12) }, 0.25, Enum.EasingStyle.Quint)
				end)
				Library.Notification:Notify({
					Title = capturedName,
					Description = "Profile link copied to clipboard!",
				}, { Time = 2 })
			end)
		end

		local CardHoverBtn = Creator("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, socialUrl ~= "" and 54 or cardH),
			Text = "",
			ZIndex = 28,
			AutoButtonColor = false,
		}, Card)

		CardHoverBtn.MouseEnter:Connect(function()
			UISettings:Tween(Card, { BackgroundColor3 = Color3.new(r * 0.06, g * 0.04, b * 0.11) }, 0.14, Enum.EasingStyle.Quint)
			UISettings:Tween(CardStroke, { Transparency = 0.28 }, 0.14)
			UISettings:Tween(AvatarCircle, {
				Size = UDim2.new(0, 39, 0, 39),
				Position = UDim2.new(0, 11, 0, 9),
			}, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
		CardHoverBtn.MouseLeave:Connect(function()
			UISettings:Tween(Card, { BackgroundColor3 = Color3.fromRGB(10, 7, 18) }, 0.20, Enum.EasingStyle.Quint)
			UISettings:Tween(CardStroke, { Transparency = 0.65 }, 0.20)
			UISettings:Tween(AvatarCircle, {
				Size = UDim2.new(0, 36, 0, 36),
				Position = UDim2.new(0, 12, 0, 10),
			}, 0.20, Enum.EasingStyle.Quint)
		end)
	end

		Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(140, 90, 220),
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 23,
		["Children"] = {
			Creator("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.12, 0),
					NumberSequenceKeypoint.new(0.88, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}
	}, CreditsScroll)

	local CommHeader = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		ZIndex = 23,
	}, CreditsScroll)

	Creator("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 0, 14),
		Font = Enum.Font.GothamBold,
		Text = "COMMUNITY",
		TextColor3 = Color3.fromRGB(130, 90, 200),
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 24,
	}, CommHeader)
	function F.MakePremiumSocialCard(parent, config)
		local ac   = config.AccentColor
		local r, g, b = ac.R, ac.G, ac.B

		local Card = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 7, 18),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 72),
			ZIndex = 23,
			ClipsDescendants = true,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 12) }),
			}
		}, parent)
		Creator("Frame", {
			BackgroundColor3 = ac,
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 23,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 12) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(r * 0.6, g * 0.6, b * 0.6)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 4, 12)),
					}),
					Rotation = 135,
				}),
			}
		}, Card)
		Creator("UIStroke", {
			Color = ac,
			Transparency = 0.65,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, Card)
		Creator("Frame", {
			BackgroundColor3 = ac,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 10),
			Size = UDim2.new(0, 3, 1, -20),
			ZIndex = 25,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, ac),
					}),
					Rotation = 90,
				}),
			}
		}, Card)
		local IconCircle = Creator("Frame", {
			BackgroundColor3 = Color3.new(r * 0.18, g * 0.18, b * 0.18),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 14, 0.5, -20),
			Size = UDim2.new(0, 40, 0, 40),
			ZIndex = 25,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke", {
					Color = ac,
					Transparency = 0.40,
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Creator("ImageLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 20, 0, 20),
					Image = config.IconImg,
					ImageColor3 = ac,
					ZIndex = 26,
				}),
			}
		}, Card)

		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 64, 0, 14),
			Size = UDim2.new(1, -160, 0, 18),
			Font = Enum.Font.FredokaOne,
			Text = config.Label,
			TextColor3 = Color3.fromRGB(240, 235, 255),
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 25,
		}, Card)
		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 64, 0, 34),
			Size = UDim2.new(1, -160, 0, 12),
			Font = Enum.Font.Gotham,
			Text = config.SubLabel,
			TextColor3 = Color3.new(r * 0.80, g * 0.80, b * 0.80),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 25,
		}, Card)
		local Badge = Creator("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Color3.new(r * 0.14, g * 0.14, b * 0.14),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, 68, 0, 28),
			AutoButtonColor = false,
			Text = "",
			ZIndex = 26,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
				Creator("UIStroke", {
					Color = ac,
					Transparency = 0.45,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(r * 0.28, g * 0.28, b * 0.28)),
						ColorSequenceKeypoint.new(1, Color3.new(r * 0.10, g * 0.10, b * 0.10)),
					}),
					Rotation = 90,
				}),
			}
		}, Card)

		local BadgeLabel = Creator("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = config.BadgeText or "COPY",
			TextColor3 = ac,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 27,
		}, Badge)

		local BadgeStroke = Badge:FindFirstChildOfClass("UIStroke")
		local CardStroke  = Card:FindFirstChildOfClass("UIStroke")
		local CardBtn = Creator("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = 28,
			AutoButtonColor = false,
		}, Card)

		CardBtn.MouseEnter:Connect(function()
			UISettings:Tween(Card, { BackgroundColor3 = Color3.new(r * 0.07, g * 0.04, b * 0.12) }, 0.14, Enum.EasingStyle.Quint)
			UISettings:Tween(CardStroke, { Transparency = 0.30 }, 0.14)
			UISettings:Tween(IconCircle, { Size = UDim2.new(0, 43, 0, 43), Position = UDim2.new(0, 12, 0.5, -21) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
		CardBtn.MouseLeave:Connect(function()
			UISettings:Tween(Card, { BackgroundColor3 = Color3.fromRGB(10, 7, 18) }, 0.20, Enum.EasingStyle.Quint)
			UISettings:Tween(CardStroke, { Transparency = 0.65 }, 0.20)
			UISettings:Tween(IconCircle, { Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 14, 0.5, -20) }, 0.20, Enum.EasingStyle.Quint)
		end)

		Badge.MouseEnter:Connect(function()
			UISettings:Tween(Badge, { BackgroundColor3 = Color3.new(r * 0.28, g * 0.28, b * 0.28) }, 0.12, Enum.EasingStyle.Quint)
			UISettings:Tween(BadgeStroke, { Transparency = 0.15 }, 0.12)
		end)
		Badge.MouseLeave:Connect(function()
			UISettings:Tween(Badge, { BackgroundColor3 = Color3.new(r * 0.14, g * 0.14, b * 0.14) }, 0.18, Enum.EasingStyle.Quint)
			UISettings:Tween(BadgeStroke, { Transparency = 0.45 }, 0.18)
		end)
		local function HandleClick()
			CircleClick(Badge, Mouse.X, Mouse.Y)
			pcall(function() (setclipboard or toclipboard)(config.CopyText) end)
			BadgeLabel.Text = "COPIED"
			BadgeLabel.TextColor3 = Color3.fromRGB(100, 255, 160)
			UISettings:Tween(Badge, { BackgroundColor3 = Color3.new(r * 0.10, g * 0.40, b * 0.25) }, 0.12, Enum.EasingStyle.Quint)
			UISettings:Tween(BadgeStroke, { Transparency = 0.0 }, 0.12)
			UISettings:Tween(CardStroke, { Transparency = 0.15 }, 0.12)
			task_delay(1.4, function()
				BadgeLabel.Text = config.BadgeText or "COPY"
				BadgeLabel.TextColor3 = ac
				UISettings:Tween(Badge, { BackgroundColor3 = Color3.new(r * 0.14, g * 0.14, b * 0.14) }, 0.35, Enum.EasingStyle.Quint)
				UISettings:Tween(BadgeStroke, { Transparency = 0.45 }, 0.35)
				UISettings:Tween(CardStroke, { Transparency = 0.65 }, 0.35)
			end)
			if config.OnClick then config.OnClick(config.CopyText) end
		end

		Badge.MouseButton1Click:Connect(HandleClick)
		CardBtn.MouseButton1Click:Connect(HandleClick)

		return Card
	end
	F.MakePremiumSocialCard(CreditsScroll, {
		Label = "TikTok",
		SubLabel = "@trustmenotcondom",
		IconImg = "http://www.roblox.com/asset/?id=14620084334",
		AccentColor= Color3.fromRGB(210, 145, 255),
		BadgeText  = "COPY",
		CopyText= ("https://www.tiktok.com/@trustmenotcondom?_t=ZS-8syewdU3Bxq&_r=1"),
		OnClick = function()
			Library.Notification:Notify({
				Title = "TikTok",
				Description = "TikTok link copied to clipboard.",
			}, { Time = 2 })
		end,
	})

	F.MakePremiumSocialCard(CreditsScroll, {
		Label = "Discord",
		SubLabel = "discord.gg/YEvpu5St2Z",
		IconImg = "rbxassetid://129297846250682",
		AccentColor= Color3.fromRGB(114, 137, 255),
		BadgeText = "COPY",
		CopyText = ("https://discord.gg/YEvpu5St2Z"),
		OnClick = function()
			Library.Notification:Notify({
				Title = "Discord",
				Description = "Discord invite copied to clipboard.",
			}, { Time = 3 })
		end,
	})

	local _, SettingsScroll, _, OpenSettings, CloseSettings, IsSettingsOpen = F.MakeOverlay("Settings",
		"rbxassetid://81151604784579", 270, 270, nil)
	local _, SaveScroll, _, OpenSave, CloseSave, IsSaveOpen = F.MakeOverlay("Save Manager",
		"rbxassetid://7733715400", 270, 270, nil)
	CreditsBtn.MouseButton1Click:Connect(function()
		CircleClick(CreditsBtn, Mouse.X, Mouse.Y)
		if IsSettingsOpen and IsSettingsOpen() then CloseSettings() end
		if IsSaveOpen and IsSaveOpen() then CloseSave() end
		OpenCredits()
	end)
	function CloseFullLock()
		if IsFullLocked() and FullLockOverlay then
			FullLockOverlay.Visible = true
		end
	end

	function F.MakeMiniToggle(parent, labelText, settingKey, defaultVal, zBase, locked, onChange)
		zBase = zBase or 23
		local isTogLocked = locked and not F.HasKeyAccess()
		if isTogLocked then
			SaveSystem:Save(settingKey, false)
		end
		local saved = SaveSystem:Get(settingKey, defaultVal)
		if isTogLocked then
			saved = false
		end

		local row = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 12, 30),
			BackgroundTransparency = 0.20,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 34),
			ZIndex = zBase,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}
		}, parent)

		local rowStroke = Creator("UIStroke", {
			Color = Color3.fromRGB(140, 90, 220),
			Transparency = (saved and not isTogLocked) and 0.45 or 0.82,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, row)

		local accentPill = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(160, 100, 255),
			BackgroundTransparency = (saved and not isTogLocked) and 0 or 0.8,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, -10),
			Size = UDim2.new(0, 3, 0, 20),
			ZIndex = zBase + 1,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 170, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 55, 210)),
					}),
					Rotation = 90,
				}),
			}
		}, row)

		local labelEl = Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(1, -70, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = labelText .. (isTogLocked and " (Premium)" or ""),
			TextColor3 = (saved and not isTogLocked) and Color3.fromRGB(215, 185, 255) or Color3.fromRGB(155, 130, 195),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = zBase + 1,
		}, row)

		if isTogLocked then
			Creator("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -54, 0.5, 0),
				Size = UDim2.new(0, 12, 0, 12),
				Image = "rbxassetid://7733992528",
				ImageColor3 = Color3.fromRGB(140, 110, 190),
				ZIndex = zBase + 3,
			}, row)
		end

		local TogBG = Creator("Frame", {
			BackgroundColor3 = (saved and not isTogLocked) and Color3.fromRGB(90, 45, 170) or Color3.fromRGB(14, 9, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, 38, 0, 20),
			BorderSizePixel = 0,
			ZIndex = zBase + 2,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}
		}, row)

		local trackStroke = Creator("UIStroke", {
			Color = Color3.fromRGB(140, 90, 220),
			Transparency = (saved and not isTogLocked) and 0.40 or 0.72,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, TogBG)

		local TogDot = Creator("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = (saved and not isTogLocked) and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.new(0, 14, 0, 14),
			BorderSizePixel = 0,
			ZIndex = zBase + 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0,
							(saved and not isTogLocked) and Color3.fromRGB(235, 205, 255) or Color3.fromRGB(120, 100, 150)),
						ColorSequenceKeypoint.new(1,
							(saved and not isTogLocked) and Color3.fromRGB(170, 105, 255) or Color3.fromRGB(60, 50, 90)),
					}),
					Rotation = 135,
				}),
			}
		}, TogBG)
		local dotGrad = TogDot:FindFirstChildOfClass("UIGradient")

		local TogBtn = Creator("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = zBase + 4,
		}, row)

		local state = saved
		TogBtn.MouseButton1Click:Connect(function()
			if isTogLocked then
				Library.Notification:Notify({
					Title = "Premium Only",
					Description = "This feature requires a premium key.",
				}, { Time = 3 })
				return
			end
			state = not state
			UISettings:Tween(TogDot, { Position = state and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.22,
				Enum.EasingStyle.Back)
			UISettings:Tween(TogBG,
				{ BackgroundColor3 = state and Color3.fromRGB(90, 45, 170) or Color3.fromRGB(14, 9, 26) }, 0.20,
				Enum.EasingStyle.Quint)
			UISettings:Tween(trackStroke, { Transparency = state and 0.40 or 0.72 }, 0.20)
			UISettings:Tween(rowStroke, { Transparency = state and 0.45 or 0.82 }, 0.20)
			UISettings:Tween(accentPill, { BackgroundTransparency = state and 0 or 0.8 }, 0.20)
			UISettings:Tween(labelEl,
				{ TextColor3 = state and Color3.fromRGB(215, 185, 255) or Color3.fromRGB(155, 130, 195) }, 0.20)
			if dotGrad then
				dotGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, state and Color3.fromRGB(235, 205, 255) or Color3.fromRGB(120, 100, 150)),
					ColorSequenceKeypoint.new(1, state and Color3.fromRGB(170, 105, 255) or Color3.fromRGB(60, 50, 90)),
				})
			end
			SaveSystem:Save(settingKey, state)
			if typeof(onChange) == "function" then
				pcall(onChange, state)
			end
		end)

		return function() return state end
	end

	function F.MakeMiniSlider(parent, labelText, settingKey, min, max, defaultVal, step, onChange, zBase, deferApply)
		zBase = zBase or 23
		step = step or 0.05
		deferApply = deferApply == true
		SaveSystem:RegisterKey(settingKey)

		local saved = SaveSystem:Get(settingKey, defaultVal)
		if saved ~= nil then defaultVal = saved end
		defaultVal = math_clamp(defaultVal, min, max)

		local thumbSize = IsMobileDevice and 16 or 12
		local thumbDragSize = IsMobileDevice and 20 or 14

		local function round(val)
			return math_floor(val / step + 0.5) * step
		end

		local function formatScale(val)
			return math_floor(val * 100 + 0.5) .. "%"
		end

		local parentScroll
		local scrollAncestor = parent
		while scrollAncestor do
			if scrollAncestor:IsA("ScrollingFrame") then
				parentScroll = scrollAncestor
				break
			end
			scrollAncestor = scrollAncestor.Parent
		end

		local row = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 12, 30),
			BackgroundTransparency = 0.20,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, IsMobileDevice and 52 or 48),
			Active = true,
			ZIndex = zBase,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}
		}, parent)

		Creator("UIStroke", {
			Color = Color3.fromRGB(140, 90, 220),
			Transparency = 0.70,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, row)

		Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(160, 100, 255),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, -12),
			Size = UDim2.new(0, 3, 0, 24),
			ZIndex = zBase + 1,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 170, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 55, 210)),
					}),
					Rotation = 90,
				}),
			}
		}, row)

		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0, 6),
			Size = UDim2.new(1, -70, 0, 14),
			Font = Enum.Font.GothamBold,
			Text = labelText,
			TextColor3 = Color3.fromRGB(215, 185, 255),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = zBase + 1,
		}, row)

		local ValueLabel = Creator("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 6),
			Size = UDim2.new(0, 44, 0, 14),
			Font = Enum.Font.GothamBold,
			Text = formatScale(defaultVal),
			TextColor3 = Color3.fromRGB(192, 132, 252),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = zBase + 1,
		}, row)

		local BGSlider = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(10, 10, 16),
			BackgroundTransparency = 0.10,
			Position = UDim2.new(0, 12, 0, IsMobileDevice and 30 or 28),
			Size = UDim2.new(1, -24, 0, IsMobileDevice and 14 or 10),
			Active = true,
			ZIndex = zBase + 2,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(140, 90, 220),
					Transparency = 0.72,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}
		}, row)

		local SliderFill = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(160, 100, 255),
			BackgroundTransparency = 0,
			Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0),
			ZIndex = zBase + 3,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(216, 180, 254)),
					}),
				}),
			}
		}, BGSlider)

		local Thumb = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new((defaultVal - min) / (max - min), 0, 0.5, 0),
			Size = UDim2.new(0, thumbSize, 0, thumbSize),
			Active = true,
			ZIndex = zBase + 4,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(192, 132, 252),
					Transparency = 0.30,
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}
		}, BGSlider)

		Creator("TextButton", {
			Name = "TouchHitbox",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, math_max(thumbSize + 14, 28), 0, math_max(thumbSize + 14, 28)),
			Text = "",
			ZIndex = zBase + 5,
		}, Thumb)

		local currentValue = defaultVal
		local dragging = false
		local activeInputType = nil

		local function NotifyChange(value, isFinal)
			if not onChange then return end
			if deferApply then
				onChange(value, isFinal)
			elseif isFinal then
				onChange(value, true)
			end
		end

		local function SetSlider(value, isFinal)
			isFinal = isFinal ~= false
			value = round(math_clamp(value, min, max))
			currentValue = value
			local ratio = (value - min) / (max - min)
			local fillSize = UDim2.new(ratio, 0, 1, 0)
			local thumbPos = UDim2.new(ratio, 0, 0.5, 0)
			if isFinal then
				UISettings:Tween(SliderFill, { Size = fillSize }, 0.12, Enum.EasingStyle.Quint)
				UISettings:Tween(Thumb, { Position = thumbPos }, 0.12, Enum.EasingStyle.Quint)
			else
				SliderFill.Size = fillSize
				Thumb.Position = thumbPos
			end
			ValueLabel.Text = formatScale(value)
			if isFinal then SaveSystem:Save(settingKey, value) end
			NotifyChange(value, isFinal)
		end

		local function LiveSlider(x)
			local rel = math_clamp((x - BGSlider.AbsolutePosition.X) / BGSlider.AbsoluteSize.X, 0, 1)
			SetSlider(min + (max - min) * rel, false)
		end

		local activeDragInput = nil

		local function EndDrag(input)
			if not dragging then return end
			if input ~= activeDragInput then return end
			dragging = false
			activeDragInput = nil
			activeInputType = nil
			OverlayDragLock = false
			if parentScroll then parentScroll.ScrollingEnabled = true end
			UISettings:Tween(Thumb, { Size = UDim2.new(0, thumbSize, 0, thumbSize) }, 0.15, Enum.EasingStyle.Quint)
			SaveSystem:Save(settingKey, currentValue)
			NotifyChange(currentValue, true)
		end

		local function BeginDrag(input)
			if activeDragInput ~= nil then return end
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				activeDragInput = input
				activeInputType = input.UserInputType
				OverlayDragLock = true
				if parentScroll then parentScroll.ScrollingEnabled = false end
				LiveSlider(input.Position.X)
				UISettings:Tween(Thumb, { Size = UDim2.new(0, thumbDragSize, 0, thumbDragSize) }, 0.12, Enum.EasingStyle.Back)
			end
		end

		BGSlider.InputBegan:Connect(BeginDrag)
		Thumb.InputBegan:Connect(BeginDrag)
		local touchHitbox = Thumb:FindFirstChild("TouchHitbox")
		if touchHitbox then touchHitbox.InputBegan:Connect(BeginDrag) end
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1 then
				local relY = input.Position.Y - row.AbsolutePosition.Y
				if relY >= (IsMobileDevice and 26 or 24) then BeginDrag(input) end
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if not dragging or not activeDragInput then return end
			if input == activeDragInput
				or (activeDragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
				LiveSlider(input.Position.X)
			end
		end)
		UIS.InputEnded:Connect(function(input)
			if input == activeDragInput then
				EndDrag(input)
			end
		end)

		SetSlider(defaultVal, true)

		return function() return currentValue end
	end

	function F.MakeKeybindRow(parent, labelText, settingKey, defaultKey)
		local row = Creator("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 12, 30),
			BackgroundTransparency = 0.20,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 34),
			ZIndex = 23,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}
		}, parent)

		Creator("UIStroke", {
			Color = Color3.fromRGB(140, 90, 220),
			Transparency = 0.70,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, row)

		Creator("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(1, -90, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = labelText,
			TextColor3 = Color3.fromRGB(215, 185, 255),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 24,
		}, row)

		KeybindValueLabel = Creator("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, 72, 0, 14),
			Font = Enum.Font.GothamBold,
			Text = UIKeybindCode.Name,
			TextColor3 = Color3.fromRGB(192, 132, 252),
			TextSize = 10,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 24,
		}, row)

		local BindBtn = Creator("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			ZIndex = 25,
		}, row)

		BindBtn.MouseButton1Click:Connect(function()
			uiKeybindListening = true
			KeybindValueLabel.Text = "..."
		end)
	end

	local GetAutoSave = F.MakeMiniToggle(SettingsScroll, "Auto Save changes", "_opt_AutoSave", true)
	local GetAutoTranslate = F.MakeMiniToggle(SettingsScroll, "Auto Translate UI", "_opt_AutoTranslate", false)
	F.MakeMiniSlider(
		SettingsScroll,
		"UI Scale",
		"_opt_UIScale",
		UIScaleMin,
		UIScaleMax,
		UIScaleDefault,
		UIScaleStep,
		function(value, isFinal)
			if isFinal then
				F.ApplyUIScale(value)
			else
				F.SetUIScalePreview(value)
			end
		end,
		nil,
		true
	)
	F.MakeKeybindRow(SettingsScroll, "UI Keybind", "_opt_UIKeybind", "RightControl")

	local LangOrder = {
		"English","Filipino","Hindi","Turkish","Indonesian","Spanish","French",
		"German","Japanese","Korean","Vietnamese","Thai","Russian","Portuguese",
		"Chinese Simplified","Chinese Traditional","Arabic","Italian","Polish",
		"Dutch","Ukrainian","Malay","Bengali","Urdu",
		"Persian","Romanian","Czech","Greek","Swedish","Hungarian","Danish",
		"Finnish","Norwegian","Hebrew","Slovak","Bulgarian","Croatian",
		"Serbian","Lithuanian","Latvian","Slovenian"
	}

	local ITEM_H = 26
	local PADDING = 3
	local LIST_PAD = 8
	local MAX_VISIBLE = 4
	local SEARCH_H = 30
	local SEARCH_GAP = 6
	local SIDE_PAD = 10

	local LangSearch = ""
	local listOpen = false

	local LangRow = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(14, 10, 24),
		BackgroundTransparency = 0.20,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34),
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 90, 220),
				Transparency = 0.70,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 14, 0, 0),
				Size = UDim2.new(0.45, 0, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "Language",
				TextColor3 = Color3.fromRGB(155, 130, 195),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}),
		}
	}, SettingsScroll)

	local savedLang = SaveSystem:Get("_opt_Language", "English")

	local LangSelectedText = Creator("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -30, 0.5, 0),
		Size = UDim2.new(0, 130, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = savedLang,
		TextColor3 = Color3.fromRGB(192, 132, 252),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 24,
	}, LangRow)

	Creator("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		Font = Enum.Font.GothamBold,
		Text = "›",
		TextColor3 = Color3.fromRGB(192, 132, 252),
		TextSize = 14,
		ZIndex = 24,
	}, LangRow)

	local LangDropdownHolder = Creator("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(1, -(SIDE_PAD * 2), 0, 0),
		ClipsDescendants = true,
		ZIndex = 24,
	}, SettingsScroll)

	local LangSearchBox = Creator("TextBox", {
		BackgroundColor3 = Color3.fromRGB(18, 13, 30),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, SEARCH_H),
		Font = Enum.Font.GothamBold,
		PlaceholderText = "Search language...",
		Text = "",
		TextColor3 = Color3.fromRGB(230, 230, 230),
		PlaceholderColor3 = Color3.fromRGB(120, 110, 145),
		TextSize = 11,
		ClearTextOnFocus = false,
		Visible = false,
		ZIndex = 30,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
			Creator("UIPadding", {
				PaddingLeft  = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		}
	}, LangDropdownHolder)

	local LangListFrame = Creator("ScrollingFrame", {
		BackgroundColor3 = Color3.fromRGB(14, 10, 20),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, SEARCH_H + SEARCH_GAP),
		Size = UDim2.new(1, 0, 0, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ClipsDescendants = true,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 90, 220),
				Transparency = 0.55,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, LangDropdownHolder)

	Creator("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, PADDING),
	}, LangListFrame)

	Creator("UIPadding", {
		PaddingTop    = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft   = UDim.new(0, 4),
		PaddingRight  = UDim.new(0, 4),
	}, LangListFrame)
	function F.GetFilteredLanguages()
		if LangSearch == "" then
			return table.clone(LangOrder)
		end
		local query = string.lower(LangSearch)
		local results = {}
		for _, name in ipairs(LangOrder) do
			if string.find(string.lower(name), query, 1, true) then
				table_insert(results, name)
			end
		end
		return results
	end
	function F.CalcListHeight(count)
		local visible = math_min(count, MAX_VISIBLE)
		if visible == 0 then return 0 end
		return LIST_PAD + visible * ITEM_H + (visible - 1) * PADDING
	end

	function F.SetCanvasHeight(count)
		local full = LIST_PAD + count * ITEM_H + math_max(count - 1, 0) * PADDING
		local viewH = UnscaledLayout(LangListFrame.AbsoluteSize.Y)
		local needsScroll = full > viewH + 1
		LangListFrame.CanvasSize = UDim2.new(0, 0, 0, needsScroll and full or 0)
		LangListFrame.ScrollingEnabled = needsScroll
		LangListFrame.ElasticBehavior = Enum.ElasticBehavior.Never
		if not needsScroll then
			LangListFrame.CanvasPosition = Vector2.new(0, 0)
		end
	end
	function F.BuildLangItems()
		for _, v in ipairs(LangListFrame:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end

		local currentLang = SaveSystem:Get("_opt_Language", "English")
		local filtered = F.GetFilteredLanguages()

		for order, name in ipairs(filtered) do
			local isSelected = (name == currentLang)

			local Item = Creator("TextButton", {
				BackgroundColor3    = isSelected and Color3.fromRGB(30, 18, 52) or Color3.fromRGB(18, 13, 30),
				BackgroundTransparency = isSelected and 0.20 or 0.50,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -2, 0, ITEM_H),
				LayoutOrder = order,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 25,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
					Creator("UIStroke", {
						Color = Color3.fromRGB(140, 90, 220),
						Transparency = isSelected and 0.42 or 0.82,
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
					Creator("Frame", {
						BackgroundColor3 = Color3.fromRGB(160, 100, 255),
						BackgroundTransparency = isSelected and 0 or 1,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 0, 0.5, -9),
						Size = UDim2.new(0, 3, 0, 18),
						ZIndex = 26,
						["Children"] = {
							Creator("UICorner", { CornerRadius = UDim.new(1, 0) })
						}
					}),
					Creator("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 12, 0, 0),
						Size = UDim2.new(1, -24, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = name,
						TextColor3 = isSelected and Color3.fromRGB(215, 185, 255) or Color3.fromRGB(175, 155, 210),
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 26,
					}),
				}
			}, LangListFrame)

			Item.MouseButton1Click:Connect(function()
				SaveSystem:Save("_opt_Language", name)
				LangSelectedText.Text = name
				listOpen = false
				LangSearch = ""
				LangSearchBox.Text = ""
				LangSearchBox.Visible = false
				F.BuildLangItems()

				local listH = F.CalcListHeight(#F.GetFilteredLanguages())
				LangListFrame.Size = UDim2.new(1, 0, 0, listH)

				UISettings:Tween(LangDropdownHolder, { Size = UDim2.new(1, -(SIDE_PAD * 2), 0, 0) }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				UISettings:Tween(LangListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

				if GetAutoTranslate() then
					local code = TranslationData.Languages[name]
					if code then
						task_spawn(ApplyTranslation, code)
					end
				end
			end)
		end

		F.SetCanvasHeight(#filtered)
	end
	LangSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		LangSearch = LangSearchBox.Text
		F.BuildLangItems()

		if listOpen then
			local filtered = F.GetFilteredLanguages()
			local listH = F.CalcListHeight(#filtered)

			LangListFrame.Size = UDim2.new(1, 0, 0, listH)
			LangDropdownHolder.Size = UDim2.new(1, -(SIDE_PAD * 2), 0, SEARCH_H + SEARCH_GAP + listH)
		end
	end)

	F.BuildLangItems()

	local LangRowBtn = Creator("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 25,
	}, LangRow)

	LangRowBtn.MouseButton1Click:Connect(function()
		listOpen = not listOpen
		LangSearch = ""
		LangSearchBox.Text = ""
		LangSearchBox.Visible = listOpen

		F.BuildLangItems()

		local filtered = F.GetFilteredLanguages()
		local listH = F.CalcListHeight(#filtered)
		local targetH = listOpen and (SEARCH_H + SEARCH_GAP + listH) or 0
		local ease = listOpen and Enum.EasingDirection.Out or Enum.EasingDirection.In

		UISettings:Tween(LangDropdownHolder, { Size = UDim2.new(1, -(SIDE_PAD * 2), 0, targetH) }, 0.25, Enum.EasingStyle.Quint, ease)
		UISettings:Tween(LangListFrame, { Size = UDim2.new(1, 0, 0, listH) }, 0.25, Enum.EasingStyle.Quint, ease)
	end)

	local _lastAutoTranslateState = SaveSystem:Get("_opt_AutoTranslate", false)
	local _lastLang = SaveSystem:Get("_opt_Language", "English")

	task_spawn(function()
		while true do
			task_wait(0.45)
			local current = GetAutoTranslate()
			local lang = SaveSystem:Get("_opt_Language", "English")
			if current ~= _lastAutoTranslateState or (current and lang ~= _lastLang) then
				_lastAutoTranslateState = current
				_lastLang = lang
				local code = TranslationData.Languages[lang]
				if current and code and code ~= "en" then
					ApplyTranslation(code)
				elseif not current then
					ApplyTranslation("en")
				end
			end
		end
	end)

	task_defer(function()
		if SaveSystem:Get("_opt_AutoTranslate", false) then
			local lang = SaveSystem:Get("_opt_Language", "English")
			local code = TranslationData.Languages[lang]
			if code and code ~= "en" then ApplyTranslation(code) end
		end
	end)
	Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(100, 60, 180),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 23,
		["Children"] = {
			Creator("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.15, 0),
					NumberSequenceKeypoint.new(0.85, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}
	}, SettingsScroll)

	SaveSystem.IsAutoSave = GetAutoSave

	local OpenSavePanelBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(22, 14, 38),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 90, 220),
				Transparency = 0.55,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -40, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "Open Save Manager",
				TextColor3 = Color3.fromRGB(210, 180, 255),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),
				Font = Enum.Font.GothamBold,
				Text = "›",
				TextColor3 = Color3.fromRGB(192, 132, 252),
				TextSize = 14,
				ZIndex = 24,
			}),
		}
	}, SettingsScroll)

	OpenSavePanelBtn.MouseEnter:Connect(function()
		UISettings:Tween(OpenSavePanelBtn, { BackgroundColor3 = Color3.fromRGB(30, 18, 52) }, 0.15, Enum.EasingStyle.Quint)
	end)
	OpenSavePanelBtn.MouseLeave:Connect(function()
		UISettings:Tween(OpenSavePanelBtn, { BackgroundColor3 = Color3.fromRGB(22, 14, 38) }, 0.2, Enum.EasingStyle.Quint)
	end)
	OpenSavePanelBtn.MouseButton1Click:Connect(function()
		CircleClick(OpenSavePanelBtn, Mouse.X, Mouse.Y)
		CloseSettings()
		OpenSave()
	end)

	Creator("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		Font = Enum.Font.Gotham,
		Text = "Saves are stored per Roblox account",
		TextColor3 = Color3.fromRGB(130, 110, 170),
		TextSize = 9,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 23,
	}, SettingsScroll)

	local SaveSlots = SaveSystem:Get("_saveSlots", {})
	local SlotFrames = {}
	local OpenedSlotIndex = nil
	local PanelOpen = false
	local PreviewFilterText = ""

	local ProfileStatsCard = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 12, 30),
		BackgroundTransparency = 0.20,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 52),
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 90, 220),
				Transparency = 0.65,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 18, 48)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 24)),
				}),
				Rotation = 135,
			}),
		}
	}, SaveScroll)

	local AccountLabel = Creator("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 7),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.GothamBold,
		RichText = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = string.format('Account: <font color="#C084FC"><b>%s</b></font>', SaveSystem:GetPlayerName()),
		TextColor3 = Color3.fromRGB(225, 200, 255),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 24,
	}, ProfileStatsCard)

	local ActiveProfileLabel = Creator("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 26),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.Gotham,
		RichText = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = string.format('Profile: <font color="#C084FC"><b>%s</b></font>  •  ID: <font color="#34D399">%s</font>', SaveSystem.ActiveProfile or "[Auto]", SaveSystem:GetGameId()),
		TextColor3 = Color3.fromRGB(165, 140, 205),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 24,
	}, ProfileStatsCard)

	local QuickActionsRow = Creator("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 28),
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
		}
	}, SaveScroll)

	local QuickSaveBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(70, 35, 150),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.new(0.32, 0, 1, 0),
		Text = "Quick Save",
		TextColor3 = Color3.fromRGB(215, 185, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		LayoutOrder = 1,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(150, 100, 235),
				Transparency = 0.60,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, QuickActionsRow)

	local ResetDefaultsBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(80, 50, 25),
		BackgroundTransparency = 0.40,
		BorderSizePixel = 0,
		Size = UDim2.new(0.32, 0, 1, 0),
		Text = "Reset All",
		TextColor3 = Color3.fromRGB(255, 190, 110),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		LayoutOrder = 2,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(255, 170, 80),
				Transparency = 0.65,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, QuickActionsRow)

	local ClearSavedBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(110, 18, 36),
		BackgroundTransparency = 0.40,
		BorderSizePixel = 0,
		Size = UDim2.new(0.33, 0, 1, 0),
		Text = "Clear All",
		TextColor3 = Color3.fromRGB(255, 110, 130),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		LayoutOrder = 3,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(255, 95, 120),
				Transparency = 0.65,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, QuickActionsRow)

	QuickSaveBtn.MouseEnter:Connect(function() UISettings:Tween(QuickSaveBtn, { BackgroundTransparency = 0.15 }, 0.12) end)
	QuickSaveBtn.MouseLeave:Connect(function() UISettings:Tween(QuickSaveBtn, { BackgroundTransparency = 0.35 }, 0.18) end)
	ResetDefaultsBtn.MouseEnter:Connect(function() UISettings:Tween(ResetDefaultsBtn, { BackgroundTransparency = 0.20 }, 0.12) end)
	ResetDefaultsBtn.MouseLeave:Connect(function() UISettings:Tween(ResetDefaultsBtn, { BackgroundTransparency = 0.40 }, 0.18) end)
	ClearSavedBtn.MouseEnter:Connect(function() UISettings:Tween(ClearSavedBtn, { BackgroundTransparency = 0.20 }, 0.12) end)
	ClearSavedBtn.MouseLeave:Connect(function() UISettings:Tween(ClearSavedBtn, { BackgroundTransparency = 0.40 }, 0.18) end)

	QuickSaveBtn.MouseButton1Click:Connect(function()
		CircleClick(QuickSaveBtn, Mouse.X, Mouse.Y)
		local snapshot = SaveSystem:GetSnapshot()
		local slots = SaveSystem:Get("_saveSlots", {})
		local activeTarget = SaveSystem.ActiveProfile or "[Auto]"
		local found = false
		for _, s in ipairs(slots) do
			if s.name == activeTarget then
				s.data = snapshot
				s.updated = os.date("%Y-%m-%d %H:%M")
				found = true
				break
			end
		end
		if not found then
			table_insert(slots, {
				name = activeTarget,
				data = snapshot,
				created = os.date("%Y-%m-%d %H:%M"),
				updated = os.date("%Y-%m-%d %H:%M")
			})
		end
		SaveSystem:Save("_saveSlots", slots)
		Library.Notification:Notify({
			Title = "Save Manager",
			Description = 'Saved state to "' .. activeTarget .. '".',
		}, { Time = 2 })
		RefreshSlots()
	end)

	ResetDefaultsBtn.MouseButton1Click:Connect(function()
		CircleClick(ResetDefaultsBtn, Mouse.X, Mouse.Y)
		SaveSystem:ResetToDefaults(true)
		Library.Notification:Notify({
			Title = "Save Manager",
			Description = "All controls have been reset to default values.",
		}, { Time = 3 })
	end)

	ClearSavedBtn.MouseButton1Click:Connect(function()
		CircleClick(ClearSavedBtn, Mouse.X, Mouse.Y)
		SaveSystem:ClearAll()
		SaveSystem:Save("_saveSlots", {})
		SaveSystem:Save("_autoLoadTarget", nil)
		SaveSystem.ActiveProfile = "[Auto]"
		if ActiveProfileLabel then
			ActiveProfileLabel.Text = 'Active Profile: <font color="#C084FC"><b>[Auto]</b></font>'
		end
		RefreshSlots()
		Library.Notification:Notify({
			Title = "Save Manager",
			Description = "All saved profiles and data have been cleared.",
		}, { Time = 3 })
	end)

	local SettingsPage = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 22,
		["Children"] = {
			Creator("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			Creator("UIPadding", {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 4),
			}),
		}
	}, SaveScroll)

	local SlotPage = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 22,
		["Children"] = {
			Creator("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
		}
	}, SaveScroll)

	local BackBar = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(20, 14, 34),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 26),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 1,
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 90, 220),
				Transparency = 0.60,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(0, 16, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "‹",
				TextColor3 = Color3.fromRGB(192, 132, 252),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 24,
			}),
			Creator("TextLabel", {
				Name = "BackLabel",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 28, 0, 0),
				Size = UDim2.new(1, -34, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "Back to Profiles",
				TextColor3 = Color3.fromRGB(210, 180, 255),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}),
		}
	}, SlotPage)

	local DetailContent = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			Creator("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
		}
	}, SlotPage)

	function F.SectionLabel(text, layoutOrder)
		return Creator("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 13),
			LayoutOrder = layoutOrder,
			Font = Enum.Font.GothamBold,
			Text = text,
			TextColor3 = Color3.fromRGB(140, 105, 200),
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 24,
		}, DetailContent)
	end

	F.SectionLabel("PROFILE NAME", 1)

	local NameRow = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(16, 11, 26),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 2,
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(130, 80, 210),
				Transparency = 0.68,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, DetailContent)

	local NameInput = Creator("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -70, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Color3.fromRGB(220, 200, 255),
		PlaceholderText = "Enter profile name...",
		PlaceholderColor3 = Color3.fromRGB(110, 85, 150),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 24,
	}, NameRow)

	local NameSaveBtn = Creator("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(80, 45, 160),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.new(0, 54, 0, 20),
		Text = "Rename",
		TextColor3 = Color3.fromRGB(220, 190, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 25,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(150, 100, 230),
				Transparency = 0.50,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, NameRow)

	F.SectionLabel("AUTO LOAD SETTING", 3)

	local AutoRow = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(16, 11, 26),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 4,
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(130, 80, 210),
				Transparency = 0.68,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -60, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "Auto Load this Profile on Game Start",
				TextColor3 = Color3.fromRGB(200, 175, 240),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}),
		}
	}, DetailContent)

	local AutoTogBG = Creator("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(14, 9, 26),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 36, 0, 18),
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(130, 80, 210),
				Transparency = 0.70,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, AutoRow)

	local AutoDot = Creator("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BorderSizePixel = 0,
		ZIndex = 25,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Creator("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 90, 140)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 45, 85)),
				}),
				Rotation = 135,
			}),
		}
	}, AutoTogBG)

	local AutoTogBtn = Creator("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		ZIndex = 26,
	}, AutoRow)

	F.SectionLabel("DATA INSPECTOR & PREVIEW", 5)

	local PreviewSearchBox = Creator("TextBox", {
		BackgroundColor3 = Color3.fromRGB(10, 8, 16),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 6,
		Font = Enum.Font.Gotham,
		PlaceholderText = "Search saved keys...",
		PlaceholderColor3 = Color3.fromRGB(110, 85, 150),
		Text = "",
		TextColor3 = Color3.fromRGB(215, 190, 255),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(120, 75, 200),
				Transparency = 0.75,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
		}
	}, DetailContent)

	local PreviewScroll = Creator("ScrollingFrame", {
		BackgroundColor3 = Color3.fromRGB(9, 6, 16),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 74),
		LayoutOrder = 7,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(120, 75, 200),
				Transparency = 0.72,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			Creator("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
			}),
		}
	}, DetailContent)

	F.SectionLabel("ACTIONS", 8)

	local ActionRow1 = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 9,
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
		}
	}, DetailContent)

	local LoadPanelBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(80, 40, 170),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.new(0.48, 0, 1, 0),
		LayoutOrder = 1,
		Text = "Load & Apply",
		TextColor3 = Color3.fromRGB(230, 205, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(190, 150, 255),
				Transparency = 0.50,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, ActionRow1)

	local OverwriteBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(40, 80, 140),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.new(0.48, 0, 1, 0),
		LayoutOrder = 2,
		Text = "Overwrite Current",
		TextColor3 = Color3.fromRGB(180, 220, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 190, 255),
				Transparency = 0.50,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, ActionRow1)

	local ActionRow2 = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 10,
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
		}
	}, DetailContent)

	local DuplicateBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(24, 18, 40),
		BackgroundTransparency = 0.20,
		BorderSizePixel = 0,
		Size = UDim2.new(0.32, 0, 1, 0),
		LayoutOrder = 1,
		Text = "Clone",
		TextColor3 = Color3.fromRGB(205, 180, 245),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(130, 90, 210),
				Transparency = 0.65,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, ActionRow2)

	local ShareBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(20, 75, 35),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.new(0.32, 0, 1, 0),
		LayoutOrder = 2,
		Text = "Export Code",
		TextColor3 = Color3.fromRGB(120, 240, 160),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(90, 220, 130),
				Transparency = 0.60,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, ActionRow2)

	local DeletePanelBtn = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(110, 18, 36),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.new(0.32, 0, 1, 0),
		LayoutOrder = 3,
		Text = "Delete",
		TextColor3 = Color3.fromRGB(255, 110, 130),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(255, 95, 120),
				Transparency = 0.60,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		}
	}, ActionRow2)

	local SlotsHeader = Creator("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 9,
		Font = Enum.Font.GothamBold,
		Text = "PROFILES & SLOTS",
		TextColor3 = Color3.fromRGB(150, 115, 215),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 23,
	}, SettingsPage)

	local SlotsContainer = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 10,
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
		}
	}, SettingsPage)

	local NewSlotRow = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(14, 10, 24),
		BackgroundTransparency = 0.20,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 11,
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(140, 90, 220),
				Transparency = 0.70,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 18, 55)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 10, 24)),
				}),
				Rotation = 135,
			}),
		}
	}, SettingsPage)

	local NameBox = Creator("TextBox", {
		BackgroundColor3 = Color3.fromRGB(8, 6, 14),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 8, 0.5, -10),
		Size = UDim2.new(1, -82, 0, 20),
		PlaceholderText = "New profile name...",
		PlaceholderColor3 = Color3.fromRGB(110, 85, 150),
		Text = "",
		TextColor3 = Color3.fromRGB(220, 200, 255),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(130, 80, 210),
				Transparency = 0.72,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
		}
	}, NewSlotRow)

	local SaveSlotBtn = Creator("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(80, 40, 160),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 62, 0, 22),
		Text = "+ Create",
		TextColor3 = Color3.fromRGB(220, 195, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 80, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 35, 150)),
				}),
				Rotation = 90,
			}),
		}
	}, NewSlotRow)

	local ImportRow = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(12, 9, 22),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 12,
		ZIndex = 23,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(80, 180, 120),
				Transparency = 0.70,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 38, 28)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 9, 22)),
				}),
				Rotation = 135,
			}),
		}
	}, SettingsPage)

	local ImportBox = Creator("TextBox", {
		BackgroundColor3 = Color3.fromRGB(8, 6, 14),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Position = UDim2.new(0, 8, 0.5, -10),
		Size = UDim2.new(1, -82, 0, 20),
		PlaceholderText = "Paste share code...",
		PlaceholderColor3 = Color3.fromRGB(80, 130, 100),
		Text = "",
		TextColor3 = Color3.fromRGB(160, 240, 200),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Creator("UIStroke", {
				Color = Color3.fromRGB(80, 180, 120),
				Transparency = 0.72,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
		}
	}, ImportRow)

	local ImportBtn = Creator("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 120, 70),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 62, 0, 22),
		Text = "Import",
		TextColor3 = Color3.fromRGB(160, 250, 195),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 24,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Creator("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 200, 120)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 100, 60)),
				}),
				Rotation = 90,
			}),
		}
	}, ImportRow)

	function F.ShowSettingsPage()
		SlotPage.Visible = false
		SettingsPage.Visible = true
		SaveScroll.CanvasPosition = Vector2.new(0, 0)
	end

	function F.ShowSlotPage(Index)
		SettingsPage.Visible = false
		SlotPage.Visible = true
		SaveScroll.CanvasPosition = Vector2.new(0, 0)
		local slots = SaveSystem:Get("_saveSlots", {})
		local slot = slots[Index]
		local BackLabel = BackBar:FindFirstChild("BackLabel")
		if BackLabel and slot then
			BackLabel.Text = slot.name or ("Slot " .. Index)
		end
	end

	function F.EncodeShareCode(SlotData)
		local ok, json = pcall(function() return JsonEncode(SlotData) end)
		if ok and json then return "QH-SAVE:" .. json end
		return nil
	end

	function F.DecodeShareCode(code)
		if not code then return nil end
		code = code:gsub("^%s+", ""):gsub("%s+$", "")
		if code:match("^QH%-SAVE:") then
			code = code:sub(9)
		end
		local ok, data = pcall(function() return JsonDecode(code) end)
		if ok and type(data) == "table" then return data end
		return nil
	end

	function F.UpdatePreview(SlotData, filterQuery)
		for _, v in ipairs(PreviewScroll:GetChildren()) do
			if v:IsA("TextLabel") or v:IsA("Frame") then v:Destroy() end
		end
		if not SlotData or not SlotData.data then
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.Gotham,
				Text = "(empty slot)",
				TextColor3 = Color3.fromRGB(110, 85, 140),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}, PreviewScroll)
			return
		end
		filterQuery = filterQuery and string.lower(filterQuery) or ""
		local Count = 0
		for k, v in pairs(SlotData.data) do
			if filterQuery == "" or string.find(string.lower(tostring(k)), filterQuery, 1, true) or string.find(string.lower(tostring(v)), filterQuery, 1, true) then
				Count = Count + 1
				if Count > 40 then
					Creator("TextLabel", {
						BackgroundTransparency = 1,
						LayoutOrder = Count,
						Size = UDim2.new(1, 0, 0, 14),
						Font = Enum.Font.Gotham,
						Text = "… + more items",
						TextColor3 = Color3.fromRGB(130, 95, 170),
						TextSize = 9,
						ZIndex = 24,
					}, PreviewScroll)
					break
				end
				local valStr = tostring(v)
				if type(v) == "table" then
					local ok, encoded = pcall(JsonEncode, v)
					valStr = ok and encoded or "[table]"
				end
				if #valStr > 32 then valStr = valStr:sub(1, 30) .. "…" end

				local valColor = "#88bb99"
				if type(v) == "boolean" then
					valColor = v and "#34D399" or "#F87171"
				elseif type(v) == "number" then
					valColor = "#60A5FA"
				elseif type(v) == "table" then
					valColor = "#FBBF24"
				end

				Creator("TextLabel", {
					BackgroundTransparency = 1,
					LayoutOrder = Count,
					Size = UDim2.new(1, 0, 0, 14),
					Font = Enum.Font.Gotham,
					RichText = true,
					Text = string.format('<font color="#C084FC">%s</font> <font color="#6B7280">=</font> <font color="%s">%s</font>', tostring(k), valColor, valStr),
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 24,
				}, PreviewScroll)
			end
		end
		if Count == 0 then
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.Gotham,
				Text = filterQuery ~= "" and "(no matching keys)" or "(no data keys saved)",
				TextColor3 = Color3.fromRGB(110, 85, 140),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}, PreviewScroll)
		end
	end

	PreviewSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		PreviewFilterText = PreviewSearchBox.Text
		if OpenedSlotIndex then
			local slots = SaveSystem:Get("_saveSlots", {})
			local slot = slots[OpenedSlotIndex]
			if slot then F.UpdatePreview(slot, PreviewFilterText) end
		end
	end)

	function F.OpenSlotPanel(Index)
		OpenedSlotIndex = Index
		PanelOpen = true
		local Slots = SaveSystem:Get("_saveSlots", {})
		local Slot = Slots[Index]
		if not Slot then return end

		NameInput.Text = Slot.name or ("Slot " .. Index)
		NameSaveBtn.Visible = false
		PreviewSearchBox.Text = ""
		PreviewFilterText = ""

		local Target = SaveSystem:Get("_autoLoadTarget", nil)
		local Auto = (Target == Slot.name)
		AutoTogBG.BackgroundColor3 = Auto and Color3.fromRGB(90, 45, 170) or Color3.fromRGB(14, 9, 26)
		AutoDot.Position = Auto and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local UIGradient = AutoDot:FindFirstChildOfClass("UIGradient")
		if UIGradient then
			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Auto and Color3.fromRGB(235, 205, 255) or Color3.fromRGB(110, 90, 140)),
				ColorSequenceKeypoint.new(1, Auto and Color3.fromRGB(170, 105, 255) or Color3.fromRGB(55, 45, 85)),
			})
		end
		F.UpdatePreview(Slot)
		F.ShowSlotPage(Index)
	end

	function F.CloseSlotPanel()
		PanelOpen = false
		OpenedSlotIndex = nil
		F.ShowSettingsPage()
		RefreshSlots()
	end

	BackBar.MouseButton1Click:Connect(function()
		CircleClick(BackBar, Mouse.X, Mouse.Y)
		F.CloseSlotPanel()
	end)

	SaveSlotBtn.MouseButton1Click:Connect(function()
		CircleClick(SaveSlotBtn, Mouse.X, Mouse.Y)
		local slots = SaveSystem:Get("_saveSlots", {})
		if #slots >= 10 then
			Library.Notification:Notify({ Title = "Save Manager", Description = "Maximum 10 profiles reached." }, { Time = 2 })
			return
		end
		local name = NameBox.Text ~= "" and NameBox.Text or ("Profile " .. (#slots + 1))
		local snapshot = SaveSystem:GetSnapshot()
		local newSlot = {
			name = name,
			data = snapshot,
			created = os.date("%Y-%m-%d %H:%M"),
			updated = os.date("%Y-%m-%d %H:%M"),
		}
		table_insert(slots, newSlot)
		SaveSystem:Save("_saveSlots", slots)
		NameBox.Text = ""
		Library.Notification:Notify({ Title = "Save Manager", Description = 'Created profile "' .. name .. '".' }, { Time = 2 })
		RefreshSlots()
	end)

	NameInput:GetPropertyChangedSignal("Text"):Connect(function()
		if not OpenedSlotIndex then return end
		local slots = SaveSystem:Get("_saveSlots", {})
		local slot  = slots[OpenedSlotIndex]
		if slot then
			NameSaveBtn.Visible = (NameInput.Text ~= slot.name and NameInput.Text ~= "")
		end
	end)

	NameSaveBtn.MouseButton1Click:Connect(function()
		if not OpenedSlotIndex then return end
		local slots = SaveSystem:Get("_saveSlots", {})
		local slot = slots[OpenedSlotIndex]
		if not slot then return end
		local oldName = slot.name
		local newName = NameInput.Text ~= "" and NameInput.Text or oldName
		slots[OpenedSlotIndex].name = newName
		if SaveSystem:Get("_autoLoadTarget", nil) == oldName then
			SaveSystem:Save("_autoLoadTarget", newName)
		end
		if SaveSystem.ActiveProfile == oldName then
			SaveSystem.ActiveProfile = newName
			if ActiveProfileLabel then
				ActiveProfileLabel.Text = string.format('Active Profile: <font color="#C084FC"><b>%s</b></font>', newName)
			end
		end
		SaveSystem:Save("_saveSlots", slots)
		NameSaveBtn.Visible = false
		local lbl = BackBar:FindFirstChild("BackLabel")
		if lbl then lbl.Text = newName end
		Library.Notification:Notify({ Title = "Save Manager", Description = 'Renamed to "' .. newName .. '".' }, { Time = 2 })
		RefreshSlots()
	end)

	AutoTogBtn.MouseButton1Click:Connect(function()
		if not OpenedSlotIndex then return end
		local slots = SaveSystem:Get("_saveSlots", {})
		local slot = slots[OpenedSlotIndex]
		if not slot then return end
		local cur = SaveSystem:Get("_autoLoadTarget", nil)
		local newAuto = not (cur == slot.name)
		SaveSystem:Save("_autoLoadTarget", newAuto and slot.name or nil)
		UISettings:Tween(AutoDot, { Position = newAuto and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.22, Enum.EasingStyle.Back)
		UISettings:Tween(AutoTogBG, { BackgroundColor3 = newAuto and Color3.fromRGB(90, 45, 170) or Color3.fromRGB(14, 9, 26) }, 0.20, Enum.EasingStyle.Quint)
		local dotGrad = AutoDot:FindFirstChildOfClass("UIGradient")
		if dotGrad then
			dotGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, newAuto and Color3.fromRGB(235, 205, 255) or Color3.fromRGB(110, 90, 140)),
				ColorSequenceKeypoint.new(1, newAuto and Color3.fromRGB(170, 105, 255) or Color3.fromRGB(55, 45, 85)),
			})
		end
		Library.Notification:Notify({
			Title = "Auto Load",
			Description = newAuto and ('"' .. slot.name .. '" set as default auto-load profile.') or "Auto Load disabled.",
		}, { Time = 2 })
		RefreshSlots()
	end)

	LoadPanelBtn.MouseButton1Click:Connect(function()
		if not OpenedSlotIndex then return end
		CircleClick(LoadPanelBtn, Mouse.X, Mouse.Y)
		local slots = SaveSystem:Get("_saveSlots", {})
		local slot  = slots[OpenedSlotIndex]
		if slot and slot.data then
			SaveSystem:ApplySnapshot(slot.data, true)
			SaveSystem.ActiveProfile = slot.name or ("Slot " .. OpenedSlotIndex)
			if ActiveProfileLabel then
				ActiveProfileLabel.Text = string.format('Active Profile: <font color="#C084FC"><b>%s</b></font>', SaveSystem.ActiveProfile)
			end
			Library.Notification:Notify({ Title = "Save Manager", Description = 'Applied profile "' .. (slot.name or "Slot") .. '" to all controls.' }, { Time = 3 })
			RefreshSlots()
		end
	end)

	OverwriteBtn.MouseButton1Click:Connect(function()
		if not OpenedSlotIndex then return end
		CircleClick(OverwriteBtn, Mouse.X, Mouse.Y)
		local slots = SaveSystem:Get("_saveSlots", {})
		local slot = slots[OpenedSlotIndex]
		if slot then
			slot.data = SaveSystem:GetSnapshot()
			slot.updated = os.date("%Y-%m-%d %H:%M")
			SaveSystem:Save("_saveSlots", slots)
			F.UpdatePreview(slot, PreviewFilterText)
			Library.Notification:Notify({ Title = "Save Manager", Description = 'Overwrote "' .. (slot.name or "profile") .. '" with current state.' }, { Time = 2 })
			RefreshSlots()
		end
	end)

	DuplicateBtn.MouseButton1Click:Connect(function()
		if not OpenedSlotIndex then return end
		CircleClick(DuplicateBtn, Mouse.X, Mouse.Y)
		local slots = SaveSystem:Get("_saveSlots", {})
		if #slots >= 10 then
			Library.Notification:Notify({ Title = "Save Manager", Description = "Maximum 10 profiles reached." }, { Time = 2 })
			return
		end
		local slot = slots[OpenedSlotIndex]
		if slot then
			local clonedData = {}
			for k, v in pairs(slot.data or {}) do clonedData[k] = v end
			table_insert(slots, {
				name = (slot.name or "Profile") .. " (Copy)",
				data = clonedData,
				created = os.date("%Y-%m-%d %H:%M"),
				updated = os.date("%Y-%m-%d %H:%M"),
			})
			SaveSystem:Save("_saveSlots", slots)
			Library.Notification:Notify({ Title = "Save Manager", Description = 'Cloned "' .. (slot.name or "profile") .. '".' }, { Time = 2 })
			RefreshSlots()
		end
	end)

	DeletePanelBtn.MouseButton1Click:Connect(function()
		if not OpenedSlotIndex then return end
		CircleClick(DeletePanelBtn, Mouse.X, Mouse.Y)
		local slots = SaveSystem:Get("_saveSlots", {})
		local removedName = slots[OpenedSlotIndex] and slots[OpenedSlotIndex].name
		table_remove(slots, OpenedSlotIndex)
		SaveSystem:Save("_saveSlots", slots)
		if removedName and SaveSystem:Get("_autoLoadTarget", nil) == removedName then
			SaveSystem:Save("_autoLoadTarget", nil)
		end
		if removedName and SaveSystem.ActiveProfile == removedName then
			SaveSystem.ActiveProfile = "[Auto]"
			if ActiveProfileLabel then
				ActiveProfileLabel.Text = 'Active Profile: <font color="#C084FC"><b>[Auto]</b></font>'
			end
		end
		Library.Notification:Notify({ Title = "Save Manager", Description = "Profile deleted." }, { Time = 2 })
		F.CloseSlotPanel()
	end)

	ShareBtn.MouseButton1Click:Connect(function()
		if not OpenedSlotIndex then return end
		CircleClick(ShareBtn, Mouse.X, Mouse.Y)
		local slots = SaveSystem:Get("_saveSlots", {})
		local slot  = slots[OpenedSlotIndex]
		if not slot then return end
		local code = F.EncodeShareCode({ name = slot.name, data = slot.data })
		if code then
			local setClip = setclipboard or toclipboard or (getgenv and getgenv().setclipboard)
			if setClip then pcall(setClip, code) end
			Library.Notification:Notify({ Title = "Share Saved", Description = "Share code copied to clipboard!" }, { Time = 3 })
		else
			Library.Notification:Notify({ Title = "Share Saved", Description = "Failed to encode save." }, { Time = 2 })
		end
	end)

	ImportBtn.MouseButton1Click:Connect(function()
		CircleClick(ImportBtn, Mouse.X, Mouse.Y)
		local code = ImportBox.Text:gsub("`", "")
		if code == "" then return end
		local data = F.DecodeShareCode(code)
		if not data then
			Library.Notification:Notify({ Title = "Import", Description = "Invalid share code format." }, { Time = 2 })
			return
		end
		local slots = SaveSystem:Get("_saveSlots", {})
		if #slots >= 10 then
			Library.Notification:Notify({ Title = "Import", Description = "Maximum 10 profiles reached." }, { Time = 2 })
			return
		end
		local newName = (data.name or "Imported") .. " (imported)"
		table_insert(slots, {
			name = newName,
			data = data.data or {},
			created = os.date("%Y-%m-%d %H:%M"),
			updated = os.date("%Y-%m-%d %H:%M")
		})
		SaveSystem:Save("_saveSlots", slots)
		ImportBox.Text = ""
		Library.Notification:Notify({ Title = "Import", Description = 'Imported profile "' .. newName .. '".' }, { Time = 3 })
		RefreshSlots()
	end)

	local _origCloseSettingsSlot = CloseSettings
	CloseSettings = function()
		if PanelOpen then
			PanelOpen = false
			OpenedSlotIndex = nil
			F.ShowSettingsPage()
		end
		_origCloseSettingsSlot()
	end

	local _origCloseSave = CloseSave
	CloseSave = function()
		if PanelOpen then
			PanelOpen = false
			OpenedSlotIndex = nil
			F.ShowSettingsPage()
		end
		_origCloseSave()
	end

	function RefreshSlots()
		for _, f in ipairs(SlotFrames) do f:Destroy() end
		SlotFrames = {}
		SaveSlots = SaveSystem:Get("_saveSlots", {})
		local autoLoadTarget = SaveSystem:Get("_autoLoadTarget", nil)

		if SlotsHeader then
			SlotsHeader.Text = string.format("PROFILES & SLOTS (%d/10)", #SaveSlots)
		end

		if #SaveSlots == 0 then
			local emptyLabel = Creator("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				Font = Enum.Font.Gotham,
				Text = "No saved profiles. Create or Quick Save above!",
				TextColor3 = Color3.fromRGB(130, 105, 160),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 23,
			}, SlotsContainer)
			table_insert(SlotFrames, emptyLabel)
		end

		for i, slot in ipairs(SaveSlots) do
			local isAutoTarget = (autoLoadTarget == slot.name)
			local isActive = (SaveSystem.ActiveProfile == slot.name)
			local isOpen = (OpenedSlotIndex == i and PanelOpen)

			local slotRow = Creator("Frame", {
				BackgroundColor3 = isOpen and Color3.fromRGB(24, 16, 42) or Color3.fromRGB(15, 10, 26),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 42),
				LayoutOrder = i,
				ZIndex = 23,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
					Creator("UIStroke", {
						Color = isOpen and Color3.fromRGB(190, 130, 255)
							or (isAutoTarget and Color3.fromRGB(160, 105, 240) or Color3.fromRGB(90, 60, 150)),
						Transparency = isOpen and 0.20 or (isAutoTarget and 0.40 or 0.75),
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}
			}, SlotsContainer)

			Creator("Frame", {
				BackgroundColor3 = isAutoTarget and Color3.fromRGB(190, 140, 255) or Color3.fromRGB(120, 70, 200),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0, 6),
				Size = UDim2.new(0, 3, 1, -12),
				ZIndex = 24,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				}
			}, slotRow)

			local NumberBadge = Creator("Frame", {
				BackgroundColor3 = Color3.fromRGB(38, 22, 70),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0.5, -10),
				Size = UDim2.new(0, 20, 0, 20),
				ZIndex = 24,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
					Creator("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = tostring(i),
						TextColor3 = Color3.fromRGB(200, 160, 255),
						TextSize = 10,
						TextXAlignment = Enum.TextXAlignment.Center,
						ZIndex = 25,
					}),
				}
			}, slotRow)

			local keyCount = 0
			if slot.data then for _ in pairs(slot.data) do keyCount = keyCount + 1 end end

			local TitleLabel = Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 36, 0, 6),
				Size = UDim2.new(1, -105, 0, 15),
				Font = Enum.Font.GothamBold,
				Text = slot.name or ("Profile " .. i),
				TextColor3 = isOpen and Color3.fromRGB(240, 220, 255)
					or (isActive and Color3.fromRGB(225, 195, 255) or Color3.fromRGB(190, 170, 230)),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 24,
			}, slotRow)

			local subMeta = string.format("%d keys", keyCount)
			if isAutoTarget then
				subMeta = subMeta .. "  •  auto load"
			elseif isActive then
				subMeta = subMeta .. "  •  active"
			end

			local SubLabel = Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 36, 0, 22),
				Size = UDim2.new(1, -105, 0, 13),
				Font = Enum.Font.Gotham,
				Text = subMeta,
				TextColor3 = isAutoTarget and Color3.fromRGB(180, 130, 255)
					or (isActive and Color3.fromRGB(140, 220, 170) or Color3.fromRGB(135, 115, 165)),
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}, slotRow)

			local QuickLoadBtn = Creator("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(70, 35, 140),
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.new(0, 48, 0, 22),
				Text = "Load",
				TextColor3 = Color3.fromRGB(215, 185, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 10,
				AutoButtonColor = false,
				ZIndex = 25,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 5) }),
					Creator("UIStroke", {
						Color = Color3.fromRGB(150, 100, 230),
						Transparency = 0.60,
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}
			}, slotRow)

			QuickLoadBtn.MouseEnter:Connect(function()
				UISettings:Tween(QuickLoadBtn, { BackgroundTransparency = 0.15 }, 0.12)
			end)
			QuickLoadBtn.MouseLeave:Connect(function()
				UISettings:Tween(QuickLoadBtn, { BackgroundTransparency = 0.35 }, 0.18)
			end)

			local capturedIndex = i
			local capturedSlot = slot

			QuickLoadBtn.MouseButton1Click:Connect(function()
				CircleClick(QuickLoadBtn, Mouse.X, Mouse.Y)
				if capturedSlot and capturedSlot.data then
					SaveSystem:ApplySnapshot(capturedSlot.data, true)
					SaveSystem.ActiveProfile = capturedSlot.name or ("Slot " .. capturedIndex)
					if ActiveProfileLabel then
						ActiveProfileLabel.Text = string.format('Active Profile: <font color="#C084FC"><b>%s</b></font>', SaveSystem.ActiveProfile)
					end
					Library.Notification:Notify({
						Title = "Save Manager",
						Description = 'Loaded profile "' .. (capturedSlot.name or "Slot") .. '".',
					}, { Time = 2 })
					RefreshSlots()
				end
			end)

			local RowHitbox = Creator("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -62, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				Text = "",
				ZIndex = 24,
			}, slotRow)

			RowHitbox.MouseEnter:Connect(function()
				if not isOpen then
					UISettings:Tween(slotRow, { BackgroundColor3 = Color3.fromRGB(22, 14, 38) }, 0.12)
				end
			end)
			RowHitbox.MouseLeave:Connect(function()
				UISettings:Tween(slotRow, { BackgroundColor3 = isOpen and Color3.fromRGB(24, 16, 42) or Color3.fromRGB(15, 10, 26) }, 0.18)
			end)

			RowHitbox.MouseButton1Click:Connect(function()
				CircleClick(RowHitbox, Mouse.X, Mouse.Y)
				if PanelOpen and OpenedSlotIndex == capturedIndex then
					F.CloseSlotPanel()
				else
					F.OpenSlotPanel(capturedIndex)
					RefreshSlots()
				end
			end)

			table_insert(SlotFrames, slotRow)
		end
	end

	RefreshSlots()

	task_defer(function()
		local autoTarget = SaveSystem:Get("_autoLoadTarget", nil)
		if autoTarget then
			local slots = SaveSystem:Get("_saveSlots", {})
			for _, slot in ipairs(slots) do
				if slot.name == autoTarget and slot.data then
					SaveSystem:ApplySnapshot(slot.data, true)
					SaveSystem.ActiveProfile = slot.name
					if ActiveProfileLabel then
						ActiveProfileLabel.Text = string.format('Active Profile: <font color="#C084FC"><b>%s</b></font>', slot.name)
					end
					break
				end
			end
		end
	end)

	Creator("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = "Theme Manager",
		TextColor3 = Color3.fromRGB(150, 105, 220),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 23,
	}, SettingsScroll)

	local ThemeCardsContainer = Creator("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 5),
			}),
		}
	}, SettingsScroll)

	local ThemeCardFrames = {}
	local ActiveThemeName = SaveSystem:Get("_activeTheme", ThemeName)

	if ThemeManager.Themes[ActiveThemeName] then
		ThemeManager.Current = ThemeManager.Themes[ActiveThemeName]
		Body.BackgroundColor3 = ThemeManager.Current.Body
	end

	function F.BuildThemeCards()
		for _, f in ipairs(ThemeCardFrames) do f:Destroy() end
		ThemeCardFrames = {}

		local themeOrder = { "Purple", "Crimson", "Ocean", "Emerald", "Sunset" }

		for _, tName in ipairs(themeOrder) do
			local tData = ThemeManager.Themes[tName]

			local isActive = (ActiveThemeName == tName)
			local accent = tData.Accent
			local accentDark = tData.AccentDark
			local preview = tData.PreviewColors

			local card = Creator("TextButton", {
				BackgroundColor3 = isActive and Color3.fromRGB(20, 13, 36) or Color3.fromRGB(14, 10, 22),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 44),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 23,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 9) }),
				}
			}, ThemeCardsContainer)

			local cardStroke = Creator("UIStroke", {
				Color = isActive and accent or Color3.fromRGB(90, 60, 140),
				Transparency = isActive and 0.30 or 0.78,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, card)

			Creator("Frame", {
				BackgroundColor3 = accent,
				BackgroundTransparency = isActive and 0 or 0.5,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 0, 0, 7),
				Size = UDim2.new(0, 3, 1, -14),
				ZIndex = 24,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Creator("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, tData.AccentLight),
							ColorSequenceKeypoint.new(1, accentDark),
						}),
						Rotation = 90,
					}),
				}
			}, card)

			local swatchX = 12
			for si, col in ipairs(preview) do
				Creator("Frame", {
					BackgroundColor3 = col,
					BorderSizePixel = 0,
					Position = UDim2.new(0, swatchX, 0.5, -10),
					Size = UDim2.new(0, 20, 0, 20),
					ZIndex = 24,
					["Children"] = {
						Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
						Creator("UIStroke", {
							Color = Color3.fromRGB(255, 255, 255),
							Transparency = 0.85,
							Thickness = 1,
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						}),
					}
				}, card)
				swatchX = swatchX + 16
			end

			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 72, 0, 0),
				Size = UDim2.new(1, -130, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = tData.DisplayName,
				TextColor3 = isActive and tData.AccentLight or Color3.fromRGB(185, 165, 215),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
			}, card)

			local badgeFrame = Creator("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = isActive
					and Color3.new(accentDark.R * 0.5, accentDark.G * 0.5, accentDark.B * 0.5)
					or Color3.fromRGB(18, 12, 28),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.new(0, 62, 0, 22),
				ZIndex = 24,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Creator("UIStroke", {
						Color = isActive and accent or Color3.fromRGB(90, 65, 130),
						Transparency = isActive and 0.35 or 0.72,
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
					Creator("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						Text = isActive and "Active" or "Apply",
						TextColor3 = isActive and tData.AccentLight or Color3.fromRGB(160, 130, 200),
						TextSize = 10,
						TextXAlignment = Enum.TextXAlignment.Center,
						ZIndex = 25,
					}),
				}
			}, card)

			table_insert(ThemeCardFrames, card)

			local capturedName = tName
			card.MouseEnter:Connect(function()
				if ActiveThemeName ~= capturedName then
					UISettings:Tween(card, { BackgroundColor3 = Color3.fromRGB(18, 13, 30) }, 0.15,
						Enum.EasingStyle.Quint)
					UISettings:Tween(cardStroke, { Transparency = 0.55 }, 0.15)
				end
			end)
			card.MouseLeave:Connect(function()
				if ActiveThemeName ~= capturedName then
					UISettings:Tween(card, { BackgroundColor3 = Color3.fromRGB(14, 10, 22) }, 0.2, Enum.EasingStyle
						.Quint)
					UISettings:Tween(cardStroke, { Transparency = 0.78 }, 0.2)
				end
			end)
			card.MouseButton1Click:Connect(function()
				if ActiveThemeName == capturedName then return end
				CircleClick(card, Mouse.X, Mouse.Y)
				ActiveThemeName = capturedName
				ApplyTheme(capturedName)
				F.BuildThemeCards()
				Library.Notification:Notify({
					Title = "Theme Manager",
					Description = capturedName .. " theme applied."
				}, { Time = 2 })
			end)
		end
	end

	F.BuildThemeCards()

	Creator("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = "Background Media",
		TextColor3 = Color3.fromRGB(150, 105, 220),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 23,
	}, SettingsScroll)

	Creator("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		Font = Enum.Font.Gotham,
		Text = "Drop .png/.jpg/.webm/.mp4 into Quantum Onyx Hub folder",
		TextColor3 = Color3.fromRGB(130, 110, 170),
		TextSize = 9,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 23,
	}, SettingsScroll)

	local BgImageScroll = Creator("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 72),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		ScrollingEnabled = true,
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			Creator("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		}
	}, SettingsScroll)

	function F.BuildBgImageCards()
		for _, child in ipairs(BgImageScroll:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local images = ListFolderImages(SaveSystem.FolderName)
		local videos = ListFolderVideos(SaveSystem.FolderName)
		local media = {}
		for _, p in ipairs(images) do table_insert(media, p) end
		for _, p in ipairs(videos) do table_insert(media, p) end
		local activeBg = SaveSystem:Get("_opt_BgImage", "")

		local noneBtn = Creator("TextButton", {
			BackgroundColor3 = activeBg == "" and Color3.fromRGB(22, 14, 38) or Color3.fromRGB(14, 10, 22),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -8, 0, 28),
			Font = Enum.Font.GothamBold,
			Text = "None (theme default)",
			TextColor3 = Color3.fromRGB(185, 165, 215),
			TextSize = 10,
			ZIndex = 24,
			LayoutOrder = 0,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
			}
		}, BgImageScroll)
		noneBtn.MouseButton1Click:Connect(function()
			ApplyBackgroundImage("")
			SaveSystem:Save("_opt_BgImage", "")
			F.BuildBgImageCards()
		end)

		for i, path in ipairs(media) do
			local fname = path:match("([^/\\]+)$") or path
			local isVideo = IsVideoPath(path)
			local isActive = activeBg == path
			local card = Creator("TextButton", {
				BackgroundColor3 = isActive and Color3.fromRGB(22, 14, 38) or Color3.fromRGB(14, 10, 22),
				BorderSizePixel = 0,
				Size = UDim2.new(1, -8, 0, 28),
				Font = Enum.Font.GothamBold,
				Text = (isActive and "✓ " or "") .. (isVideo and "[VID] " or "") .. fname,
				TextColor3 = isActive and Color3.fromRGB(210, 180, 255) or Color3.fromRGB(160, 140, 200),
				TextSize = 10,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 24,
				LayoutOrder = i,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
					Creator("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
				}
			}, BgImageScroll)
			local capturedPath = path
			card.MouseButton1Click:Connect(function()
				ApplyBackgroundImage(capturedPath)
				F.BuildBgImageCards()
				Library.Notification:Notify({
					Title = "Background",
					Description = "Applied " .. fname,
				}, { Time = 2 })
			end)
		end

		local layout = BgImageScroll:FindFirstChildOfClass("UIListLayout")
		if layout then
			FitScrollCanvas(BgImageScroll, layout, "Y", 4)
		end
	end

	F.BuildBgImageCards()

	F.MakeMiniSlider(
		SettingsScroll,
		"BG Image Fade",
		"_opt_BgImageTransparency",
		0.5,
		1,
		SaveSystem:Get("_opt_BgImageTransparency", 0.88),
		0.02,
		function(value, isFinal)
			if BodyBackground then BodyBackground.ImageTransparency = value end
			if isFinal then SaveSystem:Save("_opt_BgImageTransparency", value) end
		end,
		nil,
		true
	)

	local FontPresets = {
		{ Name = "Default", Regular = Enum.Font.Gotham, Bold = Enum.Font.GothamBold, Display = Enum.Font.FredokaOne },
		{ Name = "Gotham", Regular = Enum.Font.Gotham, Bold = Enum.Font.GothamBold, Display = Enum.Font.FredokaOne },
		{ Name = "Source Sans", Regular = Enum.Font.SourceSans, Bold = Enum.Font.SourceSansBold, Display = Enum.Font.SourceSansBold },
		{ Name = "Nunito", Regular = Enum.Font.Nunito, Bold = Enum.Font.Nunito, Display = Enum.Font.Nunito },
		{ Name = "Oswald", Regular = Enum.Font.Oswald, Bold = Enum.Font.Oswald, Display = Enum.Font.Oswald },
		{ Name = "Ubuntu", Regular = Enum.Font.Ubuntu, Bold = Enum.Font.Ubuntu, Display = Enum.Font.Ubuntu },
		{ Name = "Roboto", Regular = Enum.Font.Roboto, Bold = Enum.Font.Roboto, Display = Enum.Font.RobotoCondensed },
		{ Name = "Arcade", Regular = Enum.Font.Arcade, Bold = Enum.Font.Arcade, Display = Enum.Font.Arcade },
		{ Name = "Code", Regular = Enum.Font.Code, Bold = Enum.Font.Code, Display = Enum.Font.Code },
	}

	local FontRoleLookup = {
		[Enum.Font.Gotham] = "Regular",
		[Enum.Font.SourceSans] = "Regular",
		[Enum.Font.Nunito] = "Regular",
		[Enum.Font.Oswald] = "Regular",
		[Enum.Font.Ubuntu] = "Regular",
		[Enum.Font.Roboto] = "Regular",
		[Enum.Font.Arcade] = "Regular",
		[Enum.Font.Code] = "Regular",
		[Enum.Font.GothamBold] = "Bold",
		[Enum.Font.GothamSemibold] = "Bold",
		[Enum.Font.SourceSansBold] = "Bold",
		[Enum.Font.FredokaOne] = "Display",
		[Enum.Font.RobotoCondensed] = "Display",
	}

	function F.ResolveFontPreset(name)
		for _, p in ipairs(FontPresets) do
			if p.Name == name then return p end
		end
		return FontPresets[1]
	end

	function F.ApplyUIFont(presetName)
		local preset = F.ResolveFontPreset(presetName)
		SaveSystem:Save("_opt_UIFont", preset.Name)
		local map = {
			Regular = preset.Regular,
			Bold = preset.Bold,
			Display = preset.Display,
		}
		for _, desc in ipairs(Body:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
				local role = FontRoleLookup[desc.Font] or "Regular"
				pcall(function()
					desc.Font = map[role] or preset.Regular
				end)
			end
		end
	end

	Creator("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = "UI Font",
		TextColor3 = Color3.fromRGB(150, 105, 220),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 23,
	}, SettingsScroll)

	local FontScroll = Creator("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 90),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		ScrollingEnabled = true,
		ZIndex = 23,
		["Children"] = {
			Creator("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			Creator("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		}
	}, SettingsScroll)

	function F.BuildFontCards()
		for _, child in ipairs(FontScroll:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local activeFont = SaveSystem:Get("_opt_UIFont", "Gotham")
		for i, preset in ipairs(FontPresets) do
			local isActive = activeFont == preset.Name
			local card = Creator("TextButton", {
				BackgroundColor3 = isActive and Color3.fromRGB(22, 14, 38) or Color3.fromRGB(14, 10, 22),
				BorderSizePixel = 0,
				Size = UDim2.new(1, -8, 0, 26),
				Font = preset.Bold,
				Text = (isActive and "✓ " or "") .. preset.Name,
				TextColor3 = isActive and Color3.fromRGB(210, 180, 255) or Color3.fromRGB(160, 140, 200),
				TextSize = 11,
				ZIndex = 24,
				LayoutOrder = i,
				["Children"] = {
					Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
				}
			}, FontScroll)
			local captured = preset.Name
			card.MouseButton1Click:Connect(function()
				F.ApplyUIFont(captured)
				F.BuildFontCards()
				Library.Notification:Notify({
					Title = "Font",
					Description = "Applied " .. captured,
				}, { Time = 2 })
			end)
		end
		local layout = FontScroll:FindFirstChildOfClass("UIListLayout")
		if layout then
			FitScrollCanvas(FontScroll, layout, "Y", 4)
		end
	end
	F.BuildFontCards()
	task_defer(function()
		local savedFont = SaveSystem:Get("_opt_UIFont", "Default")
		if savedFont and savedFont ~= "Default" and savedFont ~= "Gotham" then
			F.ApplyUIFont(savedFont)
		end
	end)

	F.MakeMiniSlider(
		SettingsScroll,
		"UI Transparency",
		"_opt_UITransparency",
		0,
		0.55,
		SaveSystem:Get("_opt_UITransparency", 0.05),
		0.01,
		function(value, isFinal)
			if Body then Body.BackgroundTransparency = value end
			if isFinal then SaveSystem:Save("_opt_UITransparency", value) end
		end,
		nil,
		true
	)

	SettingsBtn.MouseButton1Click:Connect(function()
		CircleClick(SettingsBtn, Mouse.X, Mouse.Y)
		if IsCreditsOpen and IsCreditsOpen() then CloseCredits() end
		if IsSaveOpen and IsSaveOpen() then CloseSave() end
		if F.BuildBgImageCards then F.BuildBgImageCards() end
		OpenSettings()
	end)

	local ToggleClose = Creator("Frame", {
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.0160791595, 0, 0.219451368, 0),
		Size = UDim2.new(0, 60, 0, 60),
		Visible = not HasIntro,
		Active = true,
		["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(1, 0) }) }
	}, ScreenGui)

	local ToggleLogo = Creator("ImageButton", {
		Name = "ToggleLogo",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxassetid://87383580130479",
		Active = true,
		["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(1, 0) }) }
	}, ToggleClose)

	local togDrag = { on = false, moved = false, start = nil, origin = nil, input = nil }
	function F.PinToggleToOffset()
		Util.PinAbsToOffset(ToggleClose, ScreenGui, MainUIScale.Scale)
	end
	do
		local dragThreshold = IsMobileDevice and 12 or 5
		local function OnDragBegin(input)
			if togDrag.on then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			togDrag.on = true
			togDrag.input = input
			togDrag.moved = false
			togDrag.start = input.Position
			F.PinToggleToOffset()
			togDrag.origin = ToggleClose.Position
		end
		ToggleClose.InputBegan:Connect(OnDragBegin)
		ToggleLogo.InputBegan:Connect(OnDragBegin)

		UIS.InputChanged:Connect(function(input)
			if not togDrag.on or not togDrag.start or not togDrag.origin or not togDrag.input then return end
			if input == togDrag.input or (togDrag.input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
				local s = (MainUIScale and MainUIScale.Scale > 0) and MainUIScale.Scale or 1
				local delta = (input.Position - togDrag.start) / s
				if delta.Magnitude > dragThreshold then
					togDrag.moved = true
					ToggleClose.Position = UDim2.fromOffset(
						togDrag.origin.X.Offset + delta.X,
						togDrag.origin.Y.Offset + delta.Y
					)
				end
			end
		end)

		UIS.InputEnded:Connect(function(input)
			if not togDrag.on then return end
			if input == togDrag.input then
				togDrag.on = false
				togDrag.input = nil
				togDrag.start = nil
				togDrag.origin = nil
				task_delay(0.08, function()
					togDrag.moved = false
				end)
			end
		end)
	end

	local Minimized = false

	local function ExpandUI()
		if not Minimized then return end
		local curPos = Body.Position
		Body.Position = UDim2.new(curPos.X.Scale, curPos.X.Offset + 150, curPos.Y.Scale, curPos.Y.Offset + 149)
		Body.Size = UDim2.new(0, 510, 0, 330)
		TitleHub.Size = UDim2.new(1, -255, 0, 16)
		SubtitleLabel.Size = UDim2.new(1, -255, 0, 12)
		MinimizeButton.Image = "rbxassetid://92966930061759"
		MinimizeButton.Position = UDim2.new(1, -34, 0, 16)
		CloseButton.Position = UDim2.new(1, -8, 0, 16)
		TopFrame.BackgroundTransparency = 1

		if TabContainer then TabContainer.Visible = true end
		if MainContainer then MainContainer.Visible = true end
		if CreditsBtn then CreditsBtn.Visible = true end
		if SettingsBtn then SettingsBtn.Visible = true end
		if CloseButton then CloseButton.Visible = true end
		if BodyVideo and BodyVideoHolder and BodyVideoHolder.Visible then
			pcall(function() BodyVideo.Playing = true; BodyVideo:Play() end)
		end
		Minimized = false
	end

	local function MinimizeUI()
		if Minimized then return end
		if IsCreditsOpen and IsCreditsOpen() then CloseCredits() end
		if IsSettingsOpen and IsSettingsOpen() then CloseSettings() end
		if IsSaveOpen and IsSaveOpen() then CloseSave() end

		if TabContainer then TabContainer.Visible = false end
		if MainContainer then MainContainer.Visible = false end
		if CreditsBtn then CreditsBtn.Visible = false end
		if SettingsBtn then SettingsBtn.Visible = false end

		MinimizeButton.Position = UDim2.new(1, -34, 0, 16)
		CloseButton.Position = UDim2.new(1, -8, 0, 16)
		MinimizeButton.Image = "rbxassetid://124967485209478"
		TopFrame.BackgroundTransparency = 0

		TitleHub.Size = UDim2.new(1, -65, 0, 16)
		SubtitleLabel.Size = UDim2.new(1, -65, 0, 12)

		local curPos = Body.Position
		Body.Position = UDim2.new(curPos.X.Scale, curPos.X.Offset - 150, curPos.Y.Scale, curPos.Y.Offset - 149)
		Body.Size = UDim2.new(0, 210, 0, 32)
		Minimized = true
	end

	MinimizeButton.MouseButton1Click:Connect(function()
		if Minimized then
			ExpandUI()
		else
			MinimizeUI()
		end
	end)

	local BlurOverlay = Creator("Frame", {
		Name = "BlurOverlay",
		BackgroundColor3 = Color3.fromRGB(8, 6, 12),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
		Active = true,
		ZIndex = 4000,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Creator("TextButton", {
				Name = "ClickBlocker",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				Text = "",
				AutoButtonColor = false,
				Active = true,
				ZIndex = 4000,
			})
		}
	}, Body)

	local Dialog = Creator("Frame", {
		Name = "ComfirmDialog",
		BackgroundColor3 = Color3.fromRGB(18, 14, 26),
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 240, 0, 112),
		Visible = false,
		Active = true,
		ZIndex = 4001,
		ClipsDescendants = true,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 10) }),
		}
	}, BlurOverlay)

	Creator("TextLabel", {
		Name = "DialogTitle",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.new(1, -24, 0, 18),
		Text = "Are you sure?",
		TextColor3 = Color3.fromRGB(250, 245, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4002,
	}, Dialog)

	Creator("TextLabel", {
		Name = "DialogSubtitle",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 36),
		Size = UDim2.new(1, -24, 0, 16),
		Text = "Close and destroy interface?",
		TextColor3 = Color3.fromRGB(165, 150, 190),
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4002,
	}, Dialog)

	local ComfirmDialog = Creator("TextButton", {
		BackgroundColor3 = Color3.fromRGB(225, 45, 75),
		BackgroundTransparency = 0.05,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -14),
		Size = UDim2.new(0, 96, 0, 28),
		Text = "Yes",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 4002,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
		}
	}, Dialog)

	local CancelDialog = Creator("TextButton", {
		Name = "CancelButton",
		BackgroundColor3 = Color3.fromRGB(28, 22, 38),
		BackgroundTransparency = 0.05,
		TextColor3 = Color3.fromRGB(200, 190, 225),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -14),
		Size = UDim2.new(0, 96, 0, 28),
		Text = "No",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 4002,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
		}
	}, Dialog)

	local fullLockWasHidden = false

	CloseButton.MouseButton1Click:Connect(function()
		if Minimized then
			ExpandUI()
		end
		if IsCreditsOpen and IsCreditsOpen() then CloseCredits() end
		if IsSettingsOpen and IsSettingsOpen() then CloseSettings() end
		if IsSaveOpen and IsSaveOpen() then CloseSave() end
		BlurOverlay.Visible = true
		Dialog.Visible = true
	end)

	ComfirmDialog.MouseButton1Click:Connect(function()
		BlurOverlay.Visible = false
		Dialog.Visible = false
		self:DestroyGui()
	end)

	CancelDialog.MouseButton1Click:Connect(function()
		BlurOverlay.Visible = false
		Dialog.Visible = false
		if fullLockWasHidden then
			CloseFullLock()
		end
	end)

	UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode == Enum.KeyCode.Unknown then return end
		if uiKeybindListening then
			UIKeybindCode = input.KeyCode
			SaveSystem:Save("_opt_UIKeybind", input.KeyCode.Name)
			uiKeybindListening = false
			if KeybindValueLabel then KeybindValueLabel.Text = input.KeyCode.Name end
			return
		end
		if UIS:GetFocusedTextBox() then return end
		if input.KeyCode == UIKeybindCode then
			ToggleUIVisible()
		end
	end)

	local uiVisible = true

	ToggleUIVisible = function(forceState)
		local wantVisible = forceState
		if wantVisible == nil then wantVisible = not uiVisible end
		if wantVisible == uiVisible then return end

		uiVisible = wantVisible
		Body.Visible = wantVisible
		ToggleClose.Visible = true
		ToggleLogo.Visible = true

		if wantVisible then
			local uiTrans = SaveSystem:Get("_opt_UITransparency", 0.05)
			Body.BackgroundTransparency = uiTrans
			if BodyVideo and BodyVideoHolder and BodyVideoHolder.Visible then
				pcall(function() BodyVideo.Playing = true; BodyVideo:Play() end)
			end
		end
	end

	local lastTogglePressTime = 0
	local function OnToggleLogoActivated()
		if togDrag.moved then return end
		local now = tick()
		if now - lastTogglePressTime < 0.20 then return end
		lastTogglePressTime = now
		ToggleUIVisible()
	end
	ToggleLogo.Activated:Connect(OnToggleLogoActivated)

	F.MakeDraggable = Util.MakeDraggable
	Util.MakeDraggable(TopFrame, Body)

	local TabContainer = Creator("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 36),
		ClipsDescendants = false,
	}, Body)

	SearchBarFrame = Creator("Frame", {
		Name = "SearchBarFrame",
		BackgroundColor3 = Color3.fromRGB(22, 17, 34),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 1),
		Size = UDim2.new(0, 126, 0, 22),
		ZIndex = 6,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
		}
	}, TabContainer)

	Creator("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0.5, -6),
		Size = UDim2.new(0, 12, 0, 12),
		Image = "rbxassetid://3926305904",
		ImageRectOffset = Vector2.new(964, 324),
		ImageRectSize = Vector2.new(36, 36),
		ImageColor3 = Color3.fromRGB(175, 140, 230),
		ZIndex = 7,
	}, SearchBarFrame)

	local SearchBox = Creator("TextBox", {
		Name = "SearchBox",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 21, 0, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Font = Enum.Font.Gotham,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Color3.fromRGB(135, 120, 165),
		Text = "",
		TextColor3 = Color3.fromRGB(235, 230, 250),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 7,
	}, SearchBarFrame)

	local SearchClearBtn = Creator("TextButton", {
		Name = "SearchClear",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -3, 0.5, 0),
		Size = UDim2.new(0, 14, 0, 14),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Color3.fromRGB(175, 145, 215),
		TextSize = 12,
		Visible = false,
		ZIndex = 8,
		AutoButtonColor = false,
	}, SearchBarFrame)

	local SearchCountBadge = Creator("TextLabel", {
		Name = "SearchCount",
		BackgroundColor3 = Color3.fromRGB(110, 60, 190),
		BackgroundTransparency = 0.2,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -2, 0, -6),
		Size = UDim2.new(0, 22, 0, 13),
		Font = Enum.Font.GothamBold,
		Text = "0",
		TextColor3 = Color3.fromRGB(240, 225, 255),
		TextSize = 9,
		Visible = false,
		ZIndex = 9,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
		}
	}, SearchBarFrame)

	local TabScroll = Creator("ScrollingFrame", {
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 140, 0, -3),
		Size = UDim2.new(1, -148, 0, 30),
		CanvasPosition = Vector2.new(0, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(0, 7) }) }
	}, TabContainer)

	local TabLayout = Creator("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5)
	}, TabScroll)

	function F.RefreshTabScrollCanvas()
		DebouncedFitScrollCanvas(TabScroll, TabLayout, "X", 4)
	end
	RegisterLayoutRefresh(function() FitScrollCanvas(TabScroll, TabLayout, "X", 4) end)
	TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(F.RefreshTabScrollCanvas)
	TabScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(F.RefreshTabScrollCanvas)
	TabScroll.ChildAdded:Connect(F.RefreshTabScrollCanvas)

	local MainContainer = Creator("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 590, 0, 400),
		Position = UDim2.new(0, 5, 0, 70),
	}, Body)

	local Container = Creator("Folder", { Name = "Container" }, MainContainer)

	SearchRegistry = {}
	TabRegistry = {}
	local SearchMode = false
	local SearchActiveFrame = nil
	local PreSearchFrame = nil
	local transitioning = false
	local LastSearchMatches = {}

	function F.ActivateScroll(TargetScrollFrame, TargetTabButton, TargetUnderline, SkipAnim)
		if not SkipAnim and transitioning then return end
		if not SkipAnim and SearchActiveFrame == TargetScrollFrame then return end

		local CurrentIndex, TargetIndex = 1, 1
		for i, v in ipairs(TabRegistry) do
			if v.scrollFrame == SearchActiveFrame then CurrentIndex = i end
			if v.scrollFrame == TargetScrollFrame then TargetIndex = i end
		end
		local Direction = TargetIndex > CurrentIndex and 1 or -1

		for _, v in ipairs(TabRegistry) do
			UISettings:Tween(v.tabButton, { TextColor3 = Color3.fromRGB(130, 120, 155) }, 0.2, Enum.EasingStyle.Quint)
			if v.tabUnderline.Visible then
				UISettings:Tween(v.tabUnderline, { Size = UDim2.new(0, 0, 0, 3) }, 0.15, Enum.EasingStyle.Quint,
					Enum.EasingDirection.In, function()
						v.tabUnderline.Visible = false
						v.tabUnderline.Size = UDim2.new(0.5, 0, 0, 3)
					end)
			end

			if v.scrollFrame.Visible and v.scrollFrame ~= TargetScrollFrame then
				local leaving = v.scrollFrame
				if not SkipAnim then
					transitioning = true
					UISettings:Tween(leaving, { Position = UDim2.new(-0.04 * Direction, 0, 0, 0) }, 0.2,
						Enum.EasingStyle.Quint, Enum.EasingDirection.In)
					task_delay(0.2, function()
						leaving.Visible = false
						leaving.Position = UDim2.new(0, 0, 0, 0)
					end)
				else
					leaving.Visible = false
					leaving.Position = UDim2.new(0, 0, 0, 0)
				end
			end
		end

		if not SkipAnim then
			task_delay(0.15, function()
				TargetScrollFrame.Position = UDim2.new(0.04 * Direction, 0, 0, 0)
				TargetScrollFrame.Visible = true
				UISettings:Tween(TargetScrollFrame, { Position = UDim2.new(0, 0, 0, 0), }, 0.28, Enum.EasingStyle.Back,
					Enum.EasingDirection.Out)
				task_delay(0.28, function() transitioning = false end)
			end)
		else
			TargetScrollFrame.Position = UDim2.new(0, 0, 0, 0)
			TargetScrollFrame.Visible = true
			transitioning = false
		end

		UISettings:Tween(TargetTabButton, { TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.22, Enum.EasingStyle.Quint)
		TargetUnderline.Size = UDim2.new(0, 0, 0, 3)
		TargetUnderline.Visible = true
		UISettings:Tween(TargetUnderline, { Size = UDim2.new(0.5, 0, 0, 3) }, 0.3, Enum.EasingStyle.Back,
			Enum.EasingDirection.Out)
		SearchActiveFrame = TargetScrollFrame
	end

	function F.RefreshSectionVisibility()
		local SectionScrolls, Seen = {}, {}
		for _, v in ipairs(SearchRegistry) do
			if not Seen[v.sectionScroll] then
				Seen[v.sectionScroll] = true
				table_insert(SectionScrolls, v.sectionScroll)
			end
		end
		for _, ss in ipairs(SectionScrolls) do
			local ColumnVisible = false
			for _, x in ipairs(ss:GetChildren()) do
				if x.Name == "Section" then
					local SectionVisible = false
					for _, v in ipairs(SearchRegistry) do
						if v.sectionScroll == ss and v.sectionFrame == x and v.elementFrame.Visible then
							SectionVisible = true; break
						end
					end
					x.Visible = SectionVisible
					if SectionVisible then ColumnVisible = true end
				end
			end
			ss.Visible = ColumnVisible
		end
		local SeenSF, Columns = {}, {}
		for _, v in ipairs(SearchRegistry) do
			if not SeenSF[v.scrollFrame] then
				SeenSF[v.scrollFrame] = true
				Columns[v.scrollFrame] = {}
			end
		end
		for _, x in ipairs(SearchRegistry) do
			local list = Columns[x.scrollFrame]
			local already = false
			for _, v in ipairs(list) do
				if v == x.sectionScroll then
					already = true; break
				end
			end
			if not already then table_insert(list, x.sectionScroll) end
		end
		for _, x in pairs(Columns) do
			for _, v in ipairs(x) do
				if v.Visible then v.Size = UDim2.new(0, 240, 0, 260) end
			end
		end
	end

	local SearchHistoryFrame = Creator("Frame", {
		Name = "SearchHistoryFrame",
		BackgroundColor3 = Color3.fromRGB(16, 12, 24),
		BackgroundTransparency = 0.08,
		Position = UDim2.new(0, 8, 0, 26),
		Size = UDim2.new(0, 220, 0, 0),
		Visible = false,
		ZIndex = 50,
		ClipsDescendants = true,
		["Children"] = {
			Creator("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Creator("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			Creator("UIPadding", {
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
		}
	}, Body)

	local SearchTreeScroll = Creator("ScrollingFrame", {
		Name = "SearchTreeScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -8, 0, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		ZIndex = 51,
		Visible = false,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		ScrollingEnabled = true,
		["Children"] = {
			Creator("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
		}
	}, SearchHistoryFrame)

	local function HideSearchPanel()
		SearchHistoryFrame.Visible = false
		SearchHistoryFrame.Size = UDim2.new(0, 220, 0, 0)
		SearchTreeScroll.Visible = false
		SearchTreeScroll.Size = UDim2.new(1, -8, 0, 0)
		SearchTreeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	end

	function F.fuzzyMatch(str, pattern)
		str = str:lower()
		pattern = pattern:lower()
		local patternIdx = 1
		local strIdx = 1
		while patternIdx <= #pattern and strIdx <= #str do
			if pattern:sub(patternIdx, patternIdx) == str:sub(strIdx, strIdx) then
				patternIdx = patternIdx + 1
			end
			strIdx = strIdx + 1
		end
		return patternIdx > #pattern
	end

	function F.SplitWords(s)
		local words = {}
		for w in string.gmatch(string.lower(s), "%S+") do
			table_insert(words, w)
		end
		return words
	end

	function F.ScoreSearchEntry(entry, query)
		local q = query:lower()
		local title = (entry.title or ""):lower()
		local menu = (entry.menuTitle or ""):lower()
		local tab = (entry.tabTitle or ""):lower()
		local path = tab .. " " .. menu .. " " .. title
		local score = 0

		if title == q then return 200 end
		if title:sub(1, #q) == q then score = math_max(score, 160) end
		if title:find(q, 1, true) then score = math_max(score, 120) end
		if menu:find(q, 1, true) then score = math_max(score, 90) end
		if tab:find(q, 1, true) then score = math_max(score, 70) end

		local words = F.SplitWords(q)
		if #words > 1 then
			local allHit = true
			local wordScore = 0
			for _, w in ipairs(words) do
				if path:find(w, 1, true) then
					wordScore = wordScore + 25
				else
					allHit = false
				end
			end
			if allHit then score = math_max(score, 100 + wordScore) end
		end

		if F.fuzzyMatch(title, query) then score = math_max(score, 45) end
		if F.fuzzyMatch(path, query) then score = math_max(score, 35) end
		return score
	end

	local SearchHistory = SaveSystem:Get("_opt_SearchHistory", {})

	function F.SaveSearchToHistory(query)
		query = query:gsub("^%s+", ""):gsub("%s+$", "")
		if query == "" or #query < 2 then return end
		for i = #SearchHistory, 1, -1 do
			if SearchHistory[i] == query then
				table_remove(SearchHistory, i)
			end
		end
		table_insert(SearchHistory, 1, query)
		if #SearchHistory > 8 then
			table_remove(SearchHistory, 9)
		end
		SaveSystem:Save("_opt_SearchHistory", SearchHistory)
	end

	function F.NavigateToSearchEntry(entry)
		if not entry then return end
		for _, v in ipairs(TabRegistry) do
			if v.scrollFrame == entry.scrollFrame then
				F.ActivateScroll(v.scrollFrame, v.tabButton, v.tabUnderline, true)
				break
			end
		end
		entry.elementFrame.Visible = true
		entry.sectionFrame.Visible = true
		entry.sectionScroll.Visible = true
		F.RefreshSectionVisibility()

		task_defer(function()
			local el = entry.elementFrame
			local sc = entry.sectionScroll
			if not (el and el.Parent and sc and sc.Parent) then return end
			local rel = el.AbsolutePosition.Y - sc.AbsolutePosition.Y + sc.CanvasPosition.Y
			local targetY = math_max(0, rel - 40)
			UISettings:Tween(sc, { CanvasPosition = Vector2.new(0, targetY) }, 0.28, Enum.EasingStyle.Quint)

			local flash = Creator("Frame", {
				BackgroundColor3 = ThemeColor("Accent") or Color3.fromRGB(180, 120, 255),
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 50,
				["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(0, 6) }) }
			}, el)
			UISettings:Tween(flash, { BackgroundTransparency = 1 }, 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
				if flash then flash:Destroy() end
			end)
			local stroke = el:FindFirstChildOfClass("UIStroke")
			if not stroke then
				stroke = Creator("UIStroke", {
					Color = ThemeColor("Accent") or Color3.fromRGB(180, 120, 255),
					Transparency = 0.2,
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}, el)
				task_delay(0.8, function() if stroke and stroke.Parent then stroke:Destroy() end end)
			else
				local oldT = stroke.Transparency
				stroke.Transparency = 0.15
				task_delay(0.8, function() if stroke and stroke.Parent then stroke.Transparency = oldT end end)
			end
		end)
	end

	function F.UpdateSearchTreeUI(matches, query)
		for _, child in ipairs(SearchTreeScroll:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end
		local order = 0
		local contentH = 0

		if query == "" or not matches or #matches == 0 then
			SearchTreeScroll.Visible = false
			SearchTreeScroll.Size = UDim2.new(1, -8, 0, 0)
			SearchTreeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			return 0
		end

		local grouped = {}
		for _, entry in ipairs(matches) do
			local tabKey = entry.tabTitle or "Tab"
			grouped[tabKey] = grouped[tabKey] or {}
			local menuKey = entry.menuTitle or "Section"
			grouped[tabKey][menuKey] = grouped[tabKey][menuKey] or {}
			table_insert(grouped[tabKey][menuKey], entry)
		end

		for tabName, menus in pairs(grouped) do
			order = order + 1
			contentH = contentH + 16 + 2
			Creator("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamBold,
				Text = "" .. tabName,
				TextColor3 = Color3.fromRGB(192, 132, 252),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = order,
				ZIndex = 10001,
			}, SearchTreeScroll)
			for menuName, items in pairs(menus) do
				order = order + 1
				contentH = contentH + 14 + 2
				Creator("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 14),
					Font = Enum.Font.GothamSemibold,
					Text = "  └ " .. menuName,
					TextColor3 = Color3.fromRGB(160, 130, 200),
					TextSize = 9,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = order,
					ZIndex = 10001,
				}, SearchTreeScroll)
				for _, entry in ipairs(items) do
					order = order + 1
					contentH = contentH + 20 + 2
					local btn = Creator("TextButton", {
						BackgroundColor3 = Color3.fromRGB(22, 20, 28),
						BackgroundTransparency = 0.35,
						Size = UDim2.new(1, -12, 0, 20),
						Font = Enum.Font.Gotham,
						Text = "      • " .. (entry.title or ""),
						TextColor3 = Color3.fromRGB(210, 195, 230),
						TextSize = 9,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						LayoutOrder = order,
						ZIndex = 10001,
						["Children"] = {
							Creator("UICorner", { CornerRadius = UDim.new(0, 4) }),
						}
					}, SearchTreeScroll)
					btn.MouseButton1Click:Connect(function()
						F.NavigateToSearchEntry(entry)
						HideSearchPanel()
					end)
				end
			end
		end

		if order <= 0 or contentH <= 0 then
			SearchTreeScroll.Visible = false
			SearchTreeScroll.Size = UDim2.new(1, -8, 0, 0)
			SearchTreeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			SearchTreeScroll.ScrollingEnabled = false
			return 0
		end

		local viewH = math_max(UnscaledLayout(SearchTreeScroll.AbsoluteSize.Y), 1)
		local needsScroll = contentH > viewH + 1
		SearchTreeScroll.CanvasSize = UDim2.new(0, 0, 0, needsScroll and contentH or 0)
		SearchTreeScroll.ScrollingEnabled = needsScroll
		SearchTreeScroll.ElasticBehavior = Enum.ElasticBehavior.Never
		SearchTreeScroll.Visible = true
		return contentH
	end

	function F.UpdateHistoryUI(showTree)
		for _, child in ipairs(SearchHistoryFrame:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("TextLabel") then
				if child.Name ~= "SearchTreeScroll" and child ~= SearchTreeScroll then
					child:Destroy()
				end
			end
		end

		local panelHeight = 0
		if showTree then
			local treeH = 0
			if SearchTreeScroll.Visible then
				treeH = SearchTreeScroll.CanvasSize.Y.Offset
			end
			if treeH <= 0 then
				HideSearchPanel()
				return
			end
			local viewH = math_min(treeH, 180)
			SearchTreeScroll.Size = UDim2.new(1, -8, 0, viewH)
			panelHeight = viewH + 12
		else
			SearchTreeScroll.Visible = false
			SearchTreeScroll.Size = UDim2.new(1, -8, 0, 0)
			if #SearchHistory <= 0 then
				HideSearchPanel()
				return
			end
			Creator("TextLabel", {
				Name = "HistoryHeader",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				Font = Enum.Font.GothamBold,
				Text = "Recent",
				TextColor3 = Color3.fromRGB(140, 110, 190),
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
				ZIndex = 10000,
			}, SearchHistoryFrame)
			for i, query in ipairs(SearchHistory) do
				local btn = Creator("TextButton", {
					BackgroundColor3 = Color3.fromRGB(22, 20, 28),
					BackgroundTransparency = 0.5,
					Size = UDim2.new(1, 0, 0, 20),
					Font = Enum.Font.Gotham,
					Text = "  " .. query,
					TextColor3 = Color3.fromRGB(180, 160, 200),
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = i + 1,
					ZIndex = 10000,
					["Children"] = {
						Creator("UICorner", { CornerRadius = UDim.new(0, 4) })
					}
				}, SearchHistoryFrame)
				btn.MouseButton1Click:Connect(function()
					SearchBox.Text = query
					DoSearch(query)
					HideSearchPanel()
				end)
			end
			panelHeight = (#SearchHistory + 1) * 22 + 12
		end

		if panelHeight <= 0 then
			HideSearchPanel()
			return
		end
		SearchHistoryFrame.Size = UDim2.new(0, 220, 0, panelHeight)
		SearchHistoryFrame.Visible = true
	end

	DoSearch = (function(query)
		query = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
		SearchClearBtn.Visible = query ~= ""
		if query == "" then
			SearchMode = false
			LastSearchMatches = {}
			SearchCountBadge.Visible = false
			F.UpdateSearchTreeUI({}, "")
			HideSearchPanel()
			for _, v in ipairs(SearchRegistry) do
				v.elementFrame.Visible = true
				v.sectionFrame.Visible = true
				v.sectionScroll.Visible = true
				v.sectionScroll.Size = UDim2.new(0, 240, 0, 260)
			end
			for _, v in ipairs(TabRegistry) do v.tabButton.Visible = true end
			if PreSearchFrame then
				for _, v in ipairs(TabRegistry) do
					if v.scrollFrame == PreSearchFrame then
						F.ActivateScroll(v.scrollFrame, v.tabButton, v.tabUnderline, true)
						break
					end
				end
				PreSearchFrame = nil
			else
				if #TabRegistry > 0 then
					local e = TabRegistry[1]
					F.ActivateScroll(e.scrollFrame, e.tabButton, e.tabUnderline)
				end
			end
			return
		end
		if not SearchMode then
			SearchMode = true
			PreSearchFrame = SearchActiveFrame
		end
		for _, v in ipairs(SearchRegistry) do v.elementFrame.Visible = false end
		for _, v in ipairs(TabRegistry) do
			v.tabButton.Visible = false
			v.scrollFrame.Visible = false
			v.tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
			v.tabUnderline.Visible = false
		end
		local MatchedScrolls, MatchedScrollSet = {}, {}
		local scored = {}
		for _, entry in ipairs(SearchRegistry) do
			local score = F.ScoreSearchEntry(entry, query)
			if score > 0 then
				table_insert(scored, { entry = entry, score = score })
			end
		end
		table.sort(scored, function(a, b) return a.score > b.score end)
		LastSearchMatches = {}
		for _, item in ipairs(scored) do
			local entry = item.entry
			table_insert(LastSearchMatches, entry)
			entry.elementFrame.Visible = true
			if not MatchedScrollSet[entry.scrollFrame] then
				MatchedScrollSet[entry.scrollFrame] = true
				table_insert(MatchedScrolls, entry.scrollFrame)
			end
			for _, v in ipairs(TabRegistry) do
				if v.scrollFrame == entry.scrollFrame then
					v.tabButton.Visible = true; break
				end
			end
		end
		local matchCount = #LastSearchMatches
		SearchCountBadge.Visible = matchCount > 0
		SearchCountBadge.Text = tostring(matchCount)
		SearchCountBadge.Size = UDim2.new(0, math_max(22, #tostring(matchCount) * 8 + 10), 0, 14)
		local treeH = F.UpdateSearchTreeUI(LastSearchMatches, query)
		if treeH <= 0 then
			HideSearchPanel()
		else
			F.UpdateHistoryUI(true)
		end
		if #MatchedScrolls == 0 then return end
		F.RefreshSectionVisibility()
		for _, v in ipairs(TabRegistry) do
			if v.scrollFrame == MatchedScrolls[1] then
				F.ActivateScroll(v.scrollFrame, v.tabButton, v.tabUnderline, true)
				break
			end
		end
	end)
	local searchToken = 0
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = SearchBox.Text
		SearchClearBtn.Visible = text ~= ""
		searchToken = searchToken + 1
		local token = searchToken
		task_delay(0.08, function()
			if token ~= searchToken then return end
			DoSearch(text)
			if text == "" then
				HideSearchPanel()
			end
		end)
	end)
	SearchClearBtn.MouseButton1Click:Connect(function()
		SearchBox.Text = ""
		DoSearch("")
		HideSearchPanel()
		SearchBox:CaptureFocus()
	end)
	SearchBox.Focused:Connect(function()
		UISettings:Tween(SearchBarFrame, { BackgroundTransparency = 0.2 }, 0.15)
		local q = SearchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if q ~= "" and #LastSearchMatches > 0 then
			F.UpdateSearchTreeUI(LastSearchMatches, q)
			F.UpdateHistoryUI(true)
		elseif q == "" and #SearchHistory > 0 then
			F.UpdateHistoryUI(false)
		else
			HideSearchPanel()
		end
	end)
	SearchBox.FocusLost:Connect(function(enterPressed)
		UISettings:Tween(SearchBarFrame, { BackgroundTransparency = 0.4 }, 0.2)
		if enterPressed then
			F.SaveSearchToHistory(SearchBox.Text)
		end
		task_delay(0.25, function()
			if not SearchBox:IsFocused() then
				HideSearchPanel()
			end
		end)
	end)

	local Tabs = {}
	local FirstTab = true

	Tabs.AddTab = (function(self, Tab_Title, Tab_Icon, condition)
		if not checkCondition(condition) then return dummyObj end
		local IconMapping = {
			["cat-quantum"] = "rbxassetid://82115431450716",
			["home-quantum"] = "rbxassetid://130439434919073",
			["swords-quantum"] = "rbxassetid://88173691221304",
			["rabbit-quantum"] = "rbxassetid://138575837887336",
			["ship-quantum"] = "rbxassetid://115481449706054",
			["visual-quantum"] = "rbxassetid://102173201308116",
			["info-quantum"] = "rbxassetid://88050097561287",
			["misc-quantum"] = "rbxassetid://137985950260873",
			["cart-quantum"] = "rbxassetid://137995400175306",
			["cherry-quantum"] = "rbxassetid://122029349593217",
			["map-quantum"] = "rbxassetid://125480398387209",
			["raid-quantum"] = "rbxassetid://104575804564229",
			["user-quantum"] = "rbxassetid://83474083071373",
			["settings-quantum"] = "rbxassetid://81151604784579",
			["bio-quantum"] = "rbxassetid://132316362727024",
			["craft-quantum"] = "rbxassetid://118197342073112"
		}

		local icon_size, icon_padding, extra_padding = 16, 6, 12
		local tab_text_size = 14

		local Tab = Creator("TextButton", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.FredokaOne,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = tab_text_size,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = Tab_Title,
			ClipsDescendants = false,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 7) }),
				Creator("ImageLabel", {
					Name = "TabIcon",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.new(0, icon_size, 0, icon_size),
					Position = UDim2.new(0, 5, 0.5, 0),
					Image = IconMapping[Tab_Icon] or "",
					ScaleType = Enum.ScaleType.Fit,
				})
			}
		}, nil)

		local function RefreshTabSize()
			local textWidth = TextService:GetTextSize(
				Tab_Title,
				tab_text_size,
				Enum.Font.FredokaOne,
				Vector2.new(4096, 24)
			).X
			Tab.Size = UDim2.new(0, icon_padding + icon_size + extra_padding + textWidth, 0, 24)
		end
		RegisterLayoutRefresh(RefreshTabSize)
		RefreshTabSize()

		local TabUnderline = Creator("Frame", {
			Name = "Tab_Underline",
			BackgroundColor3 = Color3.fromRGB(110, 55, 190),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.new(0.5, 0, 0, 3),
			Position = UDim2.new(0.5, 0, 1, 1),
			Visible = false,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 100, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 40, 180)),
					}),
					Rotation = 0,
				}),
			}
		}, Tab)

		Tab.Parent = TabScroll

		local ScrollFrame = Creator("ScrollingFrame", {
			Name = "ScrollingFrame",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			ScrollBarThickness = 0,
			ScrollBarImageTransparency = 1,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			ScrollingEnabled = false,
			Visible = false,
			ClipsDescendants = true
		}, Container)

		local ScrollLayout = Creator("UIListLayout", {
			Name = "Scrolling_Layout",
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 19)
		}, ScrollFrame)

		local function RefreshTabContentCanvas()
			DebouncedFitScrollCanvas(ScrollFrame, ScrollLayout, "X", 4)
		end
		RegisterLayoutRefresh(function() FitScrollCanvas(ScrollFrame, ScrollLayout, "X", 4) end)
		ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshTabContentCanvas)
		ScrollFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshTabContentCanvas)
		ScrollFrame.ChildAdded:Connect(RefreshTabContentCanvas)
		ScrollFrame.ChildRemoved:Connect(RefreshTabContentCanvas)

		table_insert(TabRegistry, {
			tabButton = Tab,
			tabUnderline = TabUnderline,
			scrollFrame = ScrollFrame,
		})

		if FirstTab then
			FirstTab = false
			F.ActivateScroll(ScrollFrame, Tab, TabUnderline)
		end

		Tab.MouseButton1Click:Connect(function()
			if SearchMode then
				F.ActivateScroll(ScrollFrame, Tab, TabUnderline)
				F.RefreshSectionVisibility()
			else
				if SearchBox.Text ~= "" then SearchBox.Text = "" end
				F.ActivateScroll(ScrollFrame, Tab, TabUnderline)
			end
		end)

		local Section = {}
		Section.addSection = (function(self, condition)
			if not checkCondition(condition) then return dummyObj end
			local SectionScroll = Creator("ScrollingFrame", {
				Name = "SectionScroll",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 240, 0, 260),
				ScrollBarThickness = 0,
				ScrollBarImageTransparency = 1,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				Active = true,
				ClipsDescendants = true,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
				ScrollingEnabled = true,
				["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(1, 0) }) }
			}, ScrollFrame)

			local SectionLayout = Creator("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 7)
			}, SectionScroll)

			local function RefreshSectionScrollCanvas()
				DebouncedFitScrollCanvas(SectionScroll, SectionLayout, "Y", 4)
			end
			RegisterLayoutRefresh(function() FitScrollCanvas(SectionScroll, SectionLayout, "Y", 4) end)
			SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshSectionScrollCanvas)
			SectionScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(RefreshSectionScrollCanvas)
			SectionScroll.ChildAdded:Connect(RefreshSectionScrollCanvas)
			SectionScroll.ChildRemoved:Connect(RefreshSectionScrollCanvas)

			local Menus = {}
			Menus.addMenu = (function(self, Menu_Title, condition)
				if not checkCondition(condition) then return dummyObj end
				local Section = Creator("Frame", {
					Name = "Section",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0.48, 0, 0, 20),
					ClipsDescendants = false,
				}, SectionScroll)

				local InnerSection = Creator("Frame", {
					Name = "InnerSection",
					BackgroundColor3 = Color3.fromRGB(25, 25, 25),
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0, 0),
					Size = UDim2.new(1, -5, 0, 25),
					["Children"] = {
						Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
					}
				}, Section)

				local SectionListLayout = Creator("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 3),
				}, InnerSection)

				local TitleContainer = Creator("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 22),
					["Children"] = {
						Creator("TextLabel", {
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Size = UDim2.new(0.6, 0, 1, 0),
							Position = UDim2.new(0.2, 0, 0, 0),
							Font = Enum.Font.FredokaOne,
							Text = Menu_Title,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 15,
							TextTruncate = Enum.TextTruncate.AtEnd,
							TextXAlignment = Enum.TextXAlignment.Center,
							ZIndex = 3,
						})
					}
				}, InnerSection)

				local litGrad1 = Creator("UIGradient", { Color = ThemeColor("Lit"), Rotation = 60 })
				local litGrad2 = Creator("UIGradient", { Color = ThemeColor("Lit"), Rotation = 60 })
				RegisterLitGradient(litGrad1)
				RegisterLitGradient(litGrad2)

				local menuDecoLeft = Creator("Frame", {
					BackgroundColor3 = ThemeColor("Accent") or Color3.fromRGB(150, 100, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.2, 0, 0, 10),
					Position = UDim2.new(0, 0, 0.5, -1),
					ZIndex = 2,
					["Children"] = {
						Creator("UICorner", { CornerRadius = UDim.new(0.5) }),
						litGrad1
					}
				}, TitleContainer)
				local menuDecoRight = Creator("Frame", {
					BackgroundColor3 = ThemeColor("Accent") or Color3.fromRGB(150, 100, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.2, 0, 0, 10),
					Position = UDim2.new(0.8, 0, 0.5, -1),
					ZIndex = 2,
					["Children"] = {
						Creator("UICorner", { CornerRadius = UDim.new(0.5) }),
						litGrad2
					}
				}, TitleContainer)
				RegisterThemeElement(menuDecoLeft, "BackgroundColor3", "Accent")
				RegisterThemeElement(menuDecoRight, "BackgroundColor3", "Accent")

				local function SectionSize()
					local Height = math_max(UnscaledLayout(SectionListLayout.AbsoluteContentSize.Y) + 4, 22)
					Section.Size = UDim2.new(1, 0, 0, Height)
					InnerSection.Size = UDim2.new(1, -10, 0, Height)
				end
				RegisterLayoutRefresh(SectionSize)
				SectionListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(SectionSize)
				SectionSize()

				local function RegisterElement(elementFrame, titleText)
					elementFrame:SetAttribute("STX_SearchElement", true)
					local entry = {
						tabButton     = Tab,
						scrollFrame   = ScrollFrame,
						sectionScroll = SectionScroll,
						sectionFrame  = Section,
						elementFrame  = elementFrame,
						tabTitle      = Tab_Title,
						menuTitle     = Menu_Title,
						title         = titleText or "",
						favKey        = (Tab_Title or "") .. "|" .. (Menu_Title or "") .. "|" .. (titleText or ""),
					}
					table_insert(SearchRegistry, entry)
					FavoritesAPI.Entries[entry.favKey] = entry

					local function isPinned()
						for _, k in ipairs(FavoritesAPI.List) do
							if k == entry.favKey then return true end
						end
						return false
					end

					local function togglePin()
						local list = FavoritesAPI.List
						local idx
						for i, k in ipairs(list) do
							if k == entry.favKey then idx = i; break end
						end
						if idx then
							table_remove(list, idx)
							Library.Notification:Notify({ Title = "Favorites", Description = "Removed " .. (entry.title or "") }, { Time = 2 })
						else
							table_insert(list, entry.favKey)
							Library.Notification:Notify({ Title = "Favorites", Description = "Pinned " .. (entry.title or "") }, { Time = 2 })
						end
						SaveSystem:Save("_favorites", list)
						if FavoritesAPI.Refresh then FavoritesAPI.Refresh() end
						local pulse = Creator("Frame", {
							BackgroundColor3 = Color3.fromRGB(255, 200, 80),
							BackgroundTransparency = 0.4,
							Size = UDim2.new(1, 0, 1, 0),
							ZIndex = 40,
							["Children"] = { Creator("UICorner", { CornerRadius = UDim.new(0, 6) }) }
						}, elementFrame)
						UISettings:Tween(pulse, { BackgroundTransparency = 1 }, 0.4, Enum.EasingStyle.Quad, nil, function()
							if pulse then pulse:Destroy() end
						end)
					end

					local function showStarButton()
						local old = elementFrame:FindFirstChild("_FavStar")
						if old then old:Destroy() end
						local pinned = isPinned()
						local star = Creator("TextButton", {
							Name = "_FavStar",
							AnchorPoint = Vector2.new(1, 0.5),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Position = UDim2.new(1, -6, 0.5, 0),
							Size = UDim2.new(0, 22, 0, 22),
							Font = Enum.Font.GothamBold,
							Text = pinned and "★" or "☆",
							TextColor3 = pinned and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(210, 180, 255),
							TextSize = 16,
							ZIndex = 60,
							AutoButtonColor = false,
						}, elementFrame)
						star.MouseButton1Click:Connect(function()
							togglePin()
							if star and star.Parent then star:Destroy() end
						end)
						task_delay(3.5, function()
							if star and star.Parent then star:Destroy() end
						end)
					end

					local lastTapTime = 0
					local lastTapPos = Vector2.zero
					elementFrame.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton2 then
							showStarButton()
							return
						end
						if input.UserInputType == Enum.UserInputType.Touch then
							local now = os.clock()
							local pos = Vector2.new(input.Position.X, input.Position.Y)
							if (now - lastTapTime <= 0.35) and ((pos - lastTapPos).Magnitude < 40) then
								lastTapTime = 0
								togglePin()
							else
								lastTapTime = now
								lastTapPos = pos
							end
						end
					end)
				end

				local Funcs = {}
				if Library.Components and Library.Components.AttachAll then
					Library.Components.AttachAll(Funcs, {
						Creator = Creator,
						UISettings = UISettings,
						RegisterKeyLocked = RegisterKeyLocked,
						CircleClick = CircleClick,
						Mouse = Mouse,
						InnerSection = InnerSection,
						RegisterThemeElement = RegisterThemeElement,
						ThemeColor = ThemeColor,
						CheckCondition = checkCondition,
						DummyObj = dummyObj,
						F = F,
						SaveSystem = SaveSystem,
						ToggleRegistry = ToggleRegistry,
						ScreenGui = ScreenGui,
						UIS = UIS,
						CreateAccentBar = CreateAccentBar,
						RegisterElement = RegisterElement,
						RegisterTranslatable = RegisterTranslatable,
						MakeTextConstraint = MakeTextConstraint,
					})
				end
				return Funcs
			end)
			Menus.AddMenu = Menus.addMenu

			return Menus
		end)
		Section.AddSection = Section.addSection

		return Section
	end)
	Tabs.addTab = Tabs.AddTab
	do
		local StatusText = "Standard"
		if F.IsDeveloperBuild() then StatusText = "Developer"
		elseif F.HasKeyAccess() then StatusText = "Premium"
		elseif KeyConfig then StatusText = "Freemium" end

		local KeyStatus = "Not required"
		if KeyConfig then
			KeyStatus = F.HasKeyAccess() and "Verified" or "Not verified"
		end

		local Main = Tabs:AddTab("Main", "info-quantum")
		local LeftCol = Main:addSection()
		local RightCol = Main:addSection()
		local InfoMenu = LeftCol:addMenu("Information")
		InfoMenu:addLabel(
			"Script Information",
			string.format(
				"Hub: %s Project\nGame: %s\nAccount: %s\nStatus: %s",
				NameHub,
				tostring(Subtitle),
				LocalPlayer and LocalPlayer.Name or "Unknown",
				StatusText
			)
		)
		InfoMenu:addLabel(
			"Key Information",
			string.format(
				"Key Status: %s\nKey Mode: %s\nExpires: —\nPlan: —\nHWID: —\nNote: Key details will appear here later.",
				KeyStatus,
				tostring(KeyMode or (KeyConfig and "Optional" or "None"))
			)
		)
		local FavMenu = RightCol:addMenu("Favorites / Pinned")
		FavMenu:addLabel("Tip", "PC: right-click a function, then tap ★\nMobile: double-tap to pin")

		local favHost
		task_defer(function()
			for _, e in ipairs(SearchRegistry) do
				if e.tabTitle == "Main" and e.menuTitle == "Favorites / Pinned" then
					favHost = e.sectionFrame and e.sectionFrame:FindFirstChild("InnerSection")
					if favHost then break end
				end
			end
			if not favHost then
				for _, t in ipairs(TabRegistry) do
					if t.tabButton and t.tabButton.Text == "Main" and t.scrollFrame then
						local scrolls = {}
						for _, ch in ipairs(t.scrollFrame:GetChildren()) do
							if ch.Name == "SectionScroll" then table_insert(scrolls, ch) end
						end
						local hostScroll = scrolls[2] or scrolls[1]
						if hostScroll then
							favHost = Creator("Frame", {
								Name = "FavHost",
								BackgroundTransparency = 1,
								Size = UDim2.new(1, -10, 0, 0),
								AutomaticSize = Enum.AutomaticSize.Y,
								["Children"] = {
									Creator("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
								}
							}, hostScroll)
						end
						break
					end
				end
			end
			if FavoritesAPI.Refresh then FavoritesAPI.Refresh() end
			task_delay(1.5, function() if FavoritesAPI.Refresh then FavoritesAPI.Refresh() end end)
		end)

		FavoritesAPI.Refresh = function()
			if not favHost or not favHost.Parent then return end
			for _, ch in ipairs(favHost:GetChildren()) do
				if ch:IsA("TextButton") or (ch:IsA("TextLabel") and ch.Text == "No favorites yet") then ch:Destroy() end
			end
			local list = FavoritesAPI.List
			if #list == 0 then
				Creator("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -8, 0, 18),
					Font = Enum.Font.Gotham,
					Text = "No favorites yet",
					TextColor3 = Color3.fromRGB(140, 120, 170),
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, favHost)
				return
			end
			for i, key in ipairs(list) do
				local entry = FavoritesAPI.Entries[key]
				local title = entry and entry.title or (key:match("([^|]+)$") or key)
				local sub = entry and ((entry.tabTitle or "") .. " › " .. (entry.menuTitle or "")) or ""
				local btn = Creator("TextButton", {
					BackgroundColor3 = ThemeColor("Primary"),
					BackgroundTransparency = 0.35,
					Size = UDim2.new(1, -8, 0, 36),
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = i,
					["Children"] = {
						Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
						Creator("TextLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 10, 0, 2),
							Size = UDim2.new(1, -20, 0, 16),
							Font = Enum.Font.GothamBold,
							Text = "★  " .. title,
							TextColor3 = Color3.fromRGB(255, 220, 140),
							TextSize = 11,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextTruncate = Enum.TextTruncate.AtEnd,
						}),
						Creator("TextLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 10, 0, 18),
							Size = UDim2.new(1, -20, 0, 14),
							Font = Enum.Font.Gotham,
							Text = sub,
							TextColor3 = Color3.fromRGB(160, 140, 190),
							TextSize = 9,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextTruncate = Enum.TextTruncate.AtEnd,
						}),
					}
				}, favHost)
				btn.MouseButton1Click:Connect(function()
					if entry then F.NavigateToSearchEntry(entry) end
				end)
			end
		end
	end

	task_defer(function()
		pcall(F.SyncKeyAccess)
	end)
	ScheduleRefreshAllLayouts()

	Body.Visible = true
	ToggleClose.Visible = true
	uiVisible = true
	ScheduleRefreshAllLayouts()

	Tabs.IsDeveloper = F.IsDeveloperBuild
	Tabs.IsPremium = F.HasKeyAccess
	Tabs.ToggleUI = ToggleUIVisible
	Tabs.Favorites = FavoritesAPI
	Tabs.Destroy = function() Library:DestroyGui() end

	return Tabs
end)

	return Library.CreateWindow
end

return Window
