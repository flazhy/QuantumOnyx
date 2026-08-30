local LabelModule = {}

function LabelModule.Attach(Funcs, Context)
	local Creator, UISettings, RegisterKeyLocked, CircleClick, Mouse, InnerSection, RegisterThemeElement, ThemeColor, CheckCondition, DummyObj, F = Context.Creator, Context.UISettings, Context.RegisterKeyLocked, Context.CircleClick, Context.Mouse, Context.InnerSection, Context.RegisterThemeElement, Context.ThemeColor, Context.CheckCondition, Context.DummyObj, Context.F

	function Funcs:addLabel(title_text, description_text, Locked)
		local LabelFunc = {}
		local FontTitle, FontDesc = Enum.Font.GothamBold, Enum.Font.Gotham
		local FontSizeTitle, FontSizeDesc = 13, 11

		local LabelFrame = Creator("Frame", {
			BackgroundColor3 = ThemeColor("Primary"),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -24, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ClipsDescendants = false,
			["Children"] = {
				Creator("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Creator("UIStroke", {
					Color = Color3.fromRGB(110, 55, 190),
					Transparency = 0.88,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Creator("UIPadding", {
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 14),
					PaddingRight = UDim.new(0, 14),
				}),
				Creator("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
			}
		}, InnerSection)

		RegisterKeyLocked(LabelFrame, Locked)

		local Title = Creator("TextLabel", {
			Name = "TitleLabel",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
			Font = FontTitle,
			TextColor3 = Color3.fromRGB(230, 230, 240),
			TextSize = FontSizeTitle,
			TextWrapped = true,
			RichText = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = title_text or "Default Title",
			ZIndex = 3,
		}, LabelFrame)

		local hasDesc = description_text and description_text ~= ""

		local Divider = Creator("Frame", {
			Name = "Divider",
			BackgroundColor3 = Color3.fromRGB(110, 55, 190),
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			LayoutOrder = 2,
			Visible = hasDesc,
			ZIndex = 3,
			["Children"] = {
				Creator("UIGradient", {
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.7, 0),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}
		}, LabelFrame)

		local Description = Creator("TextLabel", {
			Name = "DescLabel",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			Font = FontDesc,
			TextColor3 = Color3.fromRGB(165, 165, 185),
			TextSize = FontSizeDesc,
			TextWrapped = true,
			RichText = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = description_text or "",
			Visible = hasDesc,
			ZIndex = 3,
		}, LabelFrame)

		RegisterTranslatable(Title, title_text)
		RegisterTranslatable(Description, description_text)

		function LabelFunc:RefreshTitle(NewTitle)
			title_text = NewTitle
			Title.Text = NewTitle or ""
		end

		function LabelFunc:RefreshDesc(NewDesc)
			description_text = NewDesc
			Description.Text = NewDesc or ""
			local descActive = NewDesc and NewDesc ~= ""
			Divider.Visible = descActive
			Description.Visible = descActive
		end

		return LabelFunc
	end

	Funcs.AddLabel = Funcs.addLabel
end

return LabelModule
