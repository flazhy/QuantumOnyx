	local OldNamecall
	OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local Name = tostring(self)
		if not checkcaller() and Name == "PlayerGui" then
			if method == "Destroy" or method == "Remove" or method == "ClearAllChildren" then
				return
			end
		end
		return OldNamecall(self, ...)
	end))
