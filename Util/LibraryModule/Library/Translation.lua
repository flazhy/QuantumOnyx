local HttpService = game:GetService("HttpService")

local Translation = {
	Languages = {
		["English"] = "en",
		["Spanish"] = "es",
		["Portuguese"] = "pt",
		["French"] = "fr",
		["German"] = "de",
		["Russian"] = "ru",
		["Turkish"] = "tr",
		["Arabic"] = "ar",
		["Vietnamese"] = "vi",
		["Thai"] = "th",
		["Indonesian"] = "id",
		["Filipino"] = "tl",
		["Japanese"] = "ja",
		["Korean"] = "ko",
		["Chinese (Simplified)"] = "zh-CN",
		["Chinese (Traditional)"] = "zh-TW",
	},
	Cache = {},
	RegisteredElements = {},
	CurrentLanguage = "English",
	IsTranslating = false,
	_Pending = nil
}

function Translation.Register(Instance, Property, OriginalText)
	if not Instance then return end
	Property = Property or "Text"
	OriginalText = OriginalText or (Instance[Property] ~= nil and Instance[Property] or "")
	Translation.RegisteredElements[Instance] = {
		Property = Property,
		Original = OriginalText
	}
end

function Translation.Translate(Text, TargetLang)
	if not Text or Text == "" then return "" end
	local Target = Translation.Languages[TargetLang] or TargetLang
	if Target == "en" then return Text end

	local CacheKey = Target .. ":" .. Text
	if Translation.Cache[CacheKey] then return Translation.Cache[CacheKey] end

	local Ok, Result = pcall(function()
		local Url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. Target .. "&dt=t&q=" .. HttpService:UrlEncode(Text)
		local Response = game:HttpGet(Url)
		local Decoded = HttpService:JSONDecode(Response)
		local Out = ""
		if Decoded and Decoded[1] then
			for _, Seg in ipairs(Decoded[1]) do
				if Seg[1] then Out = Out .. Seg[1] end
			end
		end
		return Out
	end)

	if Ok and Result and Result ~= "" then
		Translation.Cache[CacheKey] = Result
		return Result
	end
	return Text
end

function Translation.Apply(LangName, FinishCb)
	if Translation.IsTranslating then
		Translation._Pending = LangName
		return
	end

	local LangCode = Translation.Languages[LangName] or "en"
	Translation.CurrentLanguage = LangName

	if LangCode == "en" then
		for Inst, Data in pairs(Translation.RegisteredElements) do
			if Inst and Inst.Parent then
				pcall(function() Inst[Data.Property] = Data.Original end)
			end
		end
		if FinishCb then FinishCb() end
		return
	end

	Translation.IsTranslating = true

	task.spawn(function()
		local Queue, Seen = {}, {}
		for Inst, Data in pairs(Translation.RegisteredElements) do
			if Inst and Inst.Parent then
				local Text = Data.Original
				if not Seen[Text] then
					Seen[Text] = true
					table.insert(Queue, Text)
				end
			end
		end

		for _, Text in ipairs(Queue) do
			local Translated = Translation.Translate(Text, LangCode)
			for Inst, Data in pairs(Translation.RegisteredElements) do
				if Inst and Inst.Parent and Data.Original == Text then
					pcall(function() Inst[Data.Property] = Translated end)
				end
			end
		end

		Translation.IsTranslating = false
		if FinishCb then FinishCb() end

		if Translation._Pending and Translation._Pending ~= LangName then
			local NextLang = Translation._Pending
			Translation._Pending = nil
			Translation.Apply(NextLang)
		end
	end)
end

return Translation
