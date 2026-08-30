local UITabs = {}

function UITabs.BuildHome(Tab, ctx)
	local Funcs = ctx.Funcs
	local Settings = ctx.Settings
	local Module = ctx.Module
	local Data = ctx.Data or {}
	local Actions = ctx.Actions or {}

	local Home_Left = Tab.Home:addSection()
	local Home_Menu = Home_Left:addMenu("Main Farm")
	local EnabledFunctionsLabel = Home_Menu:addLabel("Debug Functions", "None")
	task.spawn(function()
		local Initialized = false
		while true do
			task.wait(1)
			local List = Module.GetEnabledFunctionNames()
			local MultiEnabled = false
			for _, v in ipairs(List) do
				if Module.IsMultiFunction(v) then
					MultiEnabled = true
					break
				end
			end
			if MultiEnabled and not Initialized and Module.ActiveFunction == nil then
				EnabledFunctionsLabel:RefreshDesc('<font color="#FFAA00"><b>Initializing Multifunctions, wait...</b></font>')
			else
				if MultiEnabled then Initialized = true end
				local Count = 0
				for _, v in ipairs(List) do
					local fn = Module.Functions[v]
					if fn and not fn.NoLock and not Module.IsMultiFunction(v) then Count = Count + 1 end
				end
				local Parts = {}
				for _, v in ipairs(List) do
					local fn = Module.Functions[v]
					if fn and not fn.NoLock then
						local title = (Module.FunctionDisplayNames and Module.FunctionDisplayNames[v]) or v
						local color = (Module.IsMultiFunction(v) or Count < 2) and "#00FF00" or "#FF0000"
						table.insert(Parts, '<font color="' .. color .. '"><b>' .. title .. '</b></font>')
					end
				end
				EnabledFunctionsLabel:RefreshDesc(#Parts > 0 and table.concat(Parts, "\n") or "None")
			end
		end
	end)

	Funcs:CreateDropdown(Home_Menu, "Weapon", "SelectWeapon", "Melee", { "Melee", "Sword", "Blox Fruit", "Gun" }, { global = true })
	Funcs:CreateDropdown(Home_Menu, "Farm Method", "FarmMode", "Quest", { "Quest", "No Quest", "Nearest" }, { global = true })
	Funcs:CreateDropdown(Home_Menu, "Quest Farm Mode", "QuestFarmMode", "Double Quest", { "Single Quest", "Double Quest", "Triple Quest" }, { global = true, save = true })
	Funcs:CreateSlider(Home_Menu, "Nearest (Distance)", "checknearestdist", 1000, 5000, 1500, { global = true })
	Funcs:CreateToggle(Home_Menu, "Auto Farm", "AutoFarm", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Home_Menu, "Take Quest", "AcceptQuests", false, { global = true, save = true, description = "Accept Quest for Bones/Cakes" })
	Funcs:CreateToggle(Home_Menu, "Auto Bones", "AutoFarmBones", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Home_Menu, "Enable Mastery", "MasteryFarm", false, { global = true, save = true })
	Funcs:CreateSlider(Home_Menu, "Health Mob%", "HealthMob", 15, 100, 25, { global = true })
	Funcs:CreateToggle(Home_Menu, "Auto Random Surprise", "Auto_Random_Surprise", false, { global = true, save = true })
	Funcs:CreateToggle(Home_Menu, "Auto Pray", "AutoPray", false, { global = true })
	Funcs:CreateToggle(Home_Menu, "Auto Try Luck", "AutoTryLuck", false, { global = true })
	Funcs:CreateToggle(Home_Menu, "Auto Katakuri", "AutoFarmPrince", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Home_Menu, "Ignore Katakuri", "IgnoreCakePrince", false, { global = true })
	Funcs:CreateToggle(Home_Menu, "Auto Dough King", "AutoDoughKing", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Home_Menu, "Ignore Farm Dough King Item", "IgnoreDoughChaliceFarm", false, { global = true, save = true, description = "this function will make the Auto Dough King only focus on boss and will not try to get chalice" })

	Funcs:CreateDropdown(Home_Menu, "Select Material", "SelectMaterial", (Data.Materials and Data.Materials[1]) or "Leather + Scrap Metal", Data.Materials or {}, { global = true })
	Funcs:CreateToggle(Home_Menu, "Auto Farm Material", "AutoMaterial", false, { global = true, stop = true })

	local Boss_Menu = Home_Left:addMenu("Boss Farm")
	Funcs:CreateDropdown(Boss_Menu, "Select Boss", "SelectBoss", 1, Data.BossNames or {}, { global = true })
	Funcs:CreateToggle(Boss_Menu, "Auto Farm Boss", "AutoFarmBoss", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Boss_Menu, "Auto Kill All Bosses", "AutoKillAllBosses", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Boss_Menu, "Get Boss Quest", "GetBossQuest", false, { global = true, save = true, description = "Automatically takes the boss quest before attacking" })

	local Tyrant_Menu = Home_Left:addMenu("Tyrant Farm")
	Funcs:CreateToggle(Tyrant_Menu, "Auto Summon Kill Tyrant Of The Skies", "AutoTyrantOfTheSkies", false, { global = true, save = true, stop = true, description = "turn on auto skill or gun shooting for destroying vases" })
	Funcs:CreateToggle(Tyrant_Menu, "Use Skull Guitar for Vases", "ShootGunTyrant", true, { global = true, save = true, description = "Uses Skull Guitar custom shoot to destroy Tyrant vases" })

	local Chest_Menu = Home_Left:addMenu("Chest Farm")
	Funcs:CreateToggle(Chest_Menu, "Start Farming Chest", "AutoChest", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Chest_Menu, "Stop If Items", "StopChest", false, { global = true, save = true })
	Funcs:CreateToggle(Chest_Menu, "Auto Hop Server On Chests", "AutoHopChest", false, { global = true, save = true })
	Funcs:CreateSlider(Chest_Menu, "Chest Hop Target Count", "ChestHopCount", 1, 50, 10, { global = true, save = true })
	Funcs:CreateToggle(Chest_Menu, "Stop Hop If Chalice / Fist", "StopHopChestIfChalice", true, { global = true, save = true })

	local Home_Right = Tab.Home:addSection()
	local Settings_Menu = Home_Right:addMenu("Farm Settings")
	Funcs:CreateSlider(Settings_Menu, "Tweening Speed", "TweenSpeed", 10, 250, 230, { global = true })
	Funcs:CreateToggle(Settings_Menu, "Lock Anchored Y", "ForceAnchoredY", false, { locked = true, save = true, global = true })
	Funcs:CreateToggle(Settings_Menu, "Bypass TP ", "BypassTP", false, { locked = true, save = true, global = true })
	Funcs:CreateSlider(Settings_Menu, "Farm Distance", "PosY", 0, 30, 18, { global = true })
	Funcs:CreateSlider(Settings_Menu, "Bring Radius", "BringMonsterRadius", 150, 400, 350, { global = true })
	Funcs:CreateDropdown(Settings_Menu, "Pos Method", "PosMethod", "Above", { "Above", "Orbit" }, { global = true })
	Funcs:CreateToggle(Settings_Menu, "Start Bring", "BringMonster", true, { global = true, save = true })
	Funcs:CreateDropdown(Settings_Menu, "Attack Method", "FastSettings", "Fast Attack", { "Fast Attack", "Legit Attack" }, { global = true })
	Funcs:CreateSlider(Settings_Menu, "Fast Attack Delay", "FastAttackDelay", 0, 1, 0, { global = true, step = 0.01 })
	Funcs:CreateToggle(Settings_Menu, "Fast Attack", "AutoAttack", true, { global = true, save = true })
	Funcs:CreateToggle(Settings_Menu, "Quantum Attack", "QuantumAttack", false, { global = true })
	Funcs:CreateToggle(Settings_Menu, "Auto Attack Gun", "AutoAttackGun", true, { global = true, save = true })
	Funcs:CreateDropdown(Settings_Menu, "Dragonstorm Mode", "DragonstormMode", "Spread Damage", { "Spread Damage", "Single Damage" }, { global = true, save = true, description = "Choose between Spread Damage or Single Damage for Dragonstorm gun" })
	Funcs:CreateSlider(Settings_Menu, "Gun Shoot Amount", "ShootAmount", 1, 10, 1, { global = true, save = true, description = "Number of shots to fire per attack cycle" })
	Funcs:CreateToggle(Settings_Menu, "Remove Fast Attack Animation", "RemoveAnimationFast", true, { global = true, save = true })
	Funcs:CreateToggle(Settings_Menu, "attack mobs", "attackmobs", true, { global = true, save = true })
	Funcs:CreateToggle(Settings_Menu, "attack players", "attackplayers", true, { global = true, save = true })
	Funcs:CreateToggle(Settings_Menu, "Auto Activate Observation Haki", "AutoActivateObservationHaki", false, { global = true, save = true })
	Funcs:CreateToggle(Settings_Menu, "Auto Set Spawn Point", "AutoSetSpawnPoint", false, { global = true, save = true })
	Funcs:CreateToggle(Settings_Menu, "Debounce Quests", "QuestDebounce", false, { global = true })
	Funcs:CreateToggle(Settings_Menu, "Bypass Get Quest", "BypassGetQuest", false, { global = true, save = true, description = "Gets the quest without teleporting to the quest NPC" })
	Funcs:CreateDropdown(Settings_Menu, "Select Team", "TeamSelectLoad", 1, { "Pirates", "Marines" }, { global = true })
	Funcs:CreateToggle(Settings_Menu, "Auto Load Script on Load", "AutoLoadScriptonLoad", false, { global = true, save = true, description = "Works on higher unc executors", callback = Actions.OnAutoLoadScript })
	Settings_Menu:addToggle("Disable Damage Counter", false, Actions.ToggleDamageCounter or function() end)
	Settings_Menu:addToggle("Disable Notifications", false, Actions.ToggleNotifications or function() end)
	Settings_Menu:addToggle("Walk in Water", true, Actions.ToggleWalkInWater or function() end)
	Funcs:CreateSlider(Settings_Menu, "Server Hop Delay (s)", "HopDelay", 1, 60, 10, { global = true, save = true, description = "Delay in seconds before hopping servers" })
	Funcs:CreateToggle(Settings_Menu, "Auto Hop when 30mins", "AutoHopwhen30mins", false, { locked = true, global = true, save = true, callback = Actions.OnAutoHop30Mins })
	Settings_Menu:addToggle("Auto Hop When Admin Joined", true, Actions.ToggleHopAdmin or function() end)
	Settings_Menu:addToggle("Anti Afk", true, Actions.ToggleAntiAFK or function() end)
	if Actions.RemoveEffects then
		Settings_Menu:addButton("Remove Effects", Actions.RemoveEffects)
	end

	local Skills_Menu = Home_Right:addMenu("Farm Settings")
	Funcs:CreateDropdown(Skills_Menu, "Select Skills", "SelectSkills", "Blox Fruit", { "Blox Fruit", "Melee", "Sword", "Gun" }, { global = true }, true)
	Funcs:CreateDropdown(Skills_Menu, "Blox Fruit Skills", "BloxFruitKeys", "Z", { "Z", "X", "C", "V", "F" }, { global = true }, true)
	Funcs:CreateDropdown(Skills_Menu, "Melee Skills", "MeleeKeys", "Z", { "Z", "X", "C" }, { global = true }, true)
	Funcs:CreateDropdown(Skills_Menu, "Sword Skills", "SwordKeys", "Z", { "Z", "X" }, { global = true }, true)
	Funcs:CreateDropdown(Skills_Menu, "Gun Skills", "GunKeys", "Z", { "Z", "X" }, { global = true }, true)
	Funcs:CreateToggle(Skills_Menu, "Auto Use Skills", "AutoSkills", false, { global = true, save = true })

	local SkillsTime_Menu = Home_Right:addMenu("Skills Settings")
	Funcs:CreateSlider(SkillsTime_Menu, "Z Hold Time (ms)", "HoldTime_Z", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "X Hold Time (ms)", "HoldTime_X", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "C Hold Time (ms)", "HoldTime_C", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "V Hold Time (ms)", "HoldTime_V", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "F Hold Time (ms)", "HoldTime_F", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "Blox Fruit Skill Delay (ms)", "BloxFruitDelay", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "Melee Skill Delay (ms)", "MeleeDelay", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "Sword Skill Delay (ms)", "SwordDelay", 0, 5, 0, { global = true, save = true, step = 0.1 })
	Funcs:CreateSlider(SkillsTime_Menu, "Gun Skill Delay (ms)", "GunDelay", 0, 5, 0, { global = true, save = true, step = 0.1 })
end

function UITabs.BuildSub(Tab, ctx)
	local Funcs = ctx.Funcs

	local Sub_Left = Tab.Sub:addSection()
	local WorldFarm_Menu = Sub_Left:addMenu("World Farm")
	Funcs:CreateToggle(WorldFarm_Menu, "Auto Second Sea Quest", "AutoSecondSea", false, { global = true, stop = true })
	Funcs:CreateToggle(WorldFarm_Menu, "Auto Third Sea Quest", "AutoThirdSea", false, { global = true, stop = true })

	local QuestFarm_Menu = Sub_Left:addMenu("Quest Farm")
	Funcs:CreateToggle(QuestFarm_Menu, "Complete Saber Quest", "AutoUnlockSaber", false, { global = true, stop = true })
	Funcs:CreateToggle(QuestFarm_Menu, "Complete Bartilo Quest", "AutoBartiloQuest", false, { global = true, stop = true })
	Funcs:CreateToggle(QuestFarm_Menu, "Complete Citizen Quest", "CompleteCitizenQuest", false, { global = true, stop = true })
	Funcs:CreateToggle(QuestFarm_Menu, "Complete Rainbow Haki Quest", "GetRainbowHaki", false, { global = true, stop = true })

	local SubItem_Menu = Sub_Left:addMenu("Items Farm")
	Funcs:CreateToggle(SubItem_Menu, "Auto Get Yama (Fully)", "AutoYama", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(SubItem_Menu, "Auto Get Tushita (Fully)", "AutoTushita", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(SubItem_Menu, "Auto Get CDK (Fully)", "AutoCDKQuest", false, { global = true, locked = true, stop = true, save = true, description = "don't turn on remove fog while using this function" })
	Funcs:CreateToggle(SubItem_Menu, "Auto Get Rengoku (Fully)", "AutoRengoku", false, { global = true, stop = true })
	Funcs:CreateToggle(SubItem_Menu, "Auto Get TTK (Fully)", "AutoTTK", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(SubItem_Menu, "Auto Evolve DarkBlade (V2)", "AutoGetDBV2", false, { locked = true, global = true, stop = true })
	Funcs:CreateToggle(SubItem_Menu, "Auto Shark Anchor (Fully)", "AutoSharkAnchor", false, { locked = true, global = true, stop = true })
	Funcs:CreateToggle(SubItem_Menu, "Auto Get Skull Guitar (Fully)", "AutoGetSkullGuitar", false, { global = true, locked = true, save = true, stop = true })
	Funcs:CreateToggle(SubItem_Menu, "Ignore Material Farm for Skull Guitar", "IgnoreMaterialFarmGuitar", false, { global = true, locked = true, stop = true })

	local SwordMastery_Menu = Sub_Left:addMenu("Sword Mastery")
	Funcs:CreateSlider(SwordMastery_Menu, "Select Sword Mastery", "SelectSwordMastery", 100, 600, 600, { locked = true, global = true })
	Funcs:CreateToggle(SwordMastery_Menu, "Auto Mastery Swords (Fully)", "AutoMasterySwords", false, { global = true, save = true })

	local FightStyle_Menu = Sub_Left:addMenu("Fight Style Obtainment")
	Funcs:CreateToggle(FightStyle_Menu, "Auto Death Step", "AutoDeathStep", false, { global = true, stop = true })
	Funcs:CreateToggle(FightStyle_Menu, "Auto Sharkman Karate", "AutoSharkmanKarate", false, { global = true, stop = true })
	Funcs:CreateToggle(FightStyle_Menu, "Auto Electric Claw", "AutoElectricClaw", false, { global = true, stop = true })
	Funcs:CreateToggle(FightStyle_Menu, "Auto Dragon Talon", "AutoDragonTalon", false, { global = true, stop = true })

	local Sub_Right = Tab.Sub:addSection()
	local RaidFarm_Menu = Sub_Right:addMenu("Timely Farm")
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Elite Hunter", "AutoTaskEliteHunter", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Factory Raid", "AutoFactoryRaid", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Pirate Raid", "AutoFarmPirateRaid", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Soul Reaper", "AutoSoulReaper", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Darkbeard", "AutoDarkbeard", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Greybeard", "AutoGreybeard", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Cursed Captain", "AutoCursedCaptain", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto Open Colors Plate", "AutoOpenColorsTask", false, { global = true, save = false, stop = true })
	Funcs:CreateToggle(RaidFarm_Menu, "Auto True Form Rip Indra", "AutoRipIndra", false, { global = true, save = true, stop = true })

	local TasksFarm_Menu = Sub_Right:addMenu("Other Farm")
	Funcs:CreateToggle(TasksFarm_Menu, "Start Farm Observation", "AutoFarmObservation", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(TasksFarm_Menu, "Auto Get Observation V2", "AutoKenV2", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(TasksFarm_Menu, "Farm Observation Hopping", "StartObsHop", false, { global = true, save = true })
	Funcs:CreateToggle(TasksFarm_Menu, "Auto Dummy Training", "DummyTraining", false, { global = true, save = true, stop = true })
end

function UITabs.BuildSeaEvents(Tab, ctx)
	local Funcs = ctx.Funcs
	local Module = ctx.Module
	local Data = ctx.Data or {}
	local Actions = ctx.Actions or {}

	local SEvent_Left = Tab.Sevent:addSection()
	local Mirage_Menu = SEvent_Left:addMenu("Mirage Event")
	Funcs:CreateToggle(Mirage_Menu, "Auto Find Mirage Island", "AutoFindMirageIsland", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Mirage_Menu, "Teleport to Mirage", "AutoTeleportMirage", false, { global = true, save = true, stop = true })

	local Kitsune_Menu = SEvent_Left:addMenu("Kitsune Event")
	Funcs:CreateToggle(Kitsune_Menu, "Auto Find Kitsune Island", "AutoFindKitsuneIsland", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Kitsune_Menu, "Teleport to Shrine", "AutoTeleportKitsune", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Kitsune_Menu, "Auto Collect Azure Embers", "CollectAzure", false, { global = true, save = true, stop = true })
	Module._BlueMoonState = "FIND_ISLAND"
	Funcs:CreateToggle(Kitsune_Menu, "Auto Kitsune Farm", "AutoBlueMoonFarm", false, { global = true, lock = true, save = true, stop = true })
	Funcs:CreateSlider(Kitsune_Menu, "Set Azure Ember", "SetAzureEmber", 1, 25, 1, { global = true })
	Funcs:CreateToggle(Kitsune_Menu, "Auto Trade Azure Ember", "TradeAzureEmber", false, { global = true, save = true })

	local Leviatan_Menu = SEvent_Left:addMenu("Leviathan Hunt")
	Leviatan_Menu:addButton("Bribe", Actions.BribeLeviathan or function() end)
	local FindLeviathan = Funcs:CreateToggle(Leviatan_Menu, "Auto Find Leviathan", "AutoFindLeviatan", false, { locked = true, global = true, stop = true })
	Module._FindLeviathan = FindLeviathan
	Funcs:CreateToggle(Leviatan_Menu, "Ignore Sea Events While Finding", "AutoIgnoreSeaEventsLeviathan", false, { global = true, save = true, description = "Ignores sea beasts, sharks, and ships so boat sails uninterrupted to Leviathan" })
	Funcs:CreateToggle(Leviatan_Menu, "Auto Kill Leviathan", "AutoKillLeviathan", false, { locked = true, global = true, stop = true })
	Funcs:CreateToggle(Leviatan_Menu, "Auto Sail back to Tiki", "AutoSailbacktoTiki", false, { locked = true, global = true, stop = true })

	local SEvent_Right = Tab.Sevent:addSection()
	local SeaFarm_Menu = SEvent_Right:addMenu("Sea Farm")
	Funcs:CreateDropdown(SeaFarm_Menu, "Select Boat", "BoatSelected", "PirateBrigade", Data.BoatsList or {}, { global = true, save = true })
	Funcs:CreateDropdown(SeaFarm_Menu, "Select Zone", "SeaLevelSelected", 6, Data.ZoneList or {}, { global = true })
	Funcs:CreateSlider(SeaFarm_Menu, "Boat Height", "BoatPosY", 0, 150, 31, { locked = true, global = true })
	Funcs:CreateSlider(SeaFarm_Menu, "Boat Speed", "SpeedBoat", 10, 250, 230, { global = true })
	Funcs:CreateDropdown(SeaFarm_Menu, "Sea Event Targets", "SeaEventTargets", 1, Data.SeaEventTargets or {}, { global = true }, true)

	local BoatTargetList = Actions.GetAllBoats and Actions.GetAllBoats() or { "My Boat" }
	local BoatTargetDropdown = Funcs:CreateDropdown(SeaFarm_Menu, "Select Owned Boat", "SailTargetBoat", "My Boat", BoatTargetList, { global = true })
	SeaFarm_Menu:addButton("Refresh Boats", function()
		if Actions.GetAllBoats then
			BoatTargetList = Actions.GetAllBoats()
			BoatTargetDropdown:Refresh(BoatTargetList)
		end
	end)
	Funcs:CreateToggle(SeaFarm_Menu, "Auto Drive", "AutoSail", false, { global = true, stop = true })
	SeaFarm_Menu:addButton("Buy New Boat", Actions.BuyNewBoat or function() end)
	Funcs:CreateToggle(SeaFarm_Menu, "Auto Farm Sea Events", "AutoFarmSeaEvents", false, { global = true, description = "don't turn off Auto Drive when farming sea events, it's connected" })
	Funcs:CreateToggle(SeaFarm_Menu, "Protect Boat (Float in Combat)", "ProtectBoat", true, { global = true, save = true, description = "Floats your boat high in the air when fighting sea events to prevent damage" })
	Funcs:CreateToggle(SeaFarm_Menu, "Auto Buy New Boat When dies", "AutoBuyNewBoatWhendies", false, { global = true })
	Funcs:CreateToggle(SeaFarm_Menu, "Auto Reset Charater if boat destroyed", "ResetPlayerdestroyboat", false, { global = true })
	Funcs:CreateToggle(SeaFarm_Menu, "Auto Dodge Terror Shark", "DodgeTerror", true, { global = true, save = true })
	Funcs:CreateToggle(SeaFarm_Menu, "Auto Dodge Seabeast", "DodgefSeabeast", true, { global = true, save = true })
	Funcs:CreateToggle(SeaFarm_Menu, "Use M1 DragonStorm for Seabeast/ships", "UseDragonSforSeabeasts", false, { global = true })
	Funcs:CreateSlider(SeaFarm_Menu, "Manual Speed", "ManualBoatSpeed", 20, 250, 150, { global = true, save = true })
	Funcs:CreateToggle(SeaFarm_Menu, "Manual Increase Boat Speed", "ManualIncreaseBoatSpeed", false, { global = true, save = true })

	local Fishing_Menu = SEvent_Right:addMenu("Fishing")
	Funcs:CreateDropdown(Fishing_Menu, "Fishing Rods", "SelectedRod", 1, Data.RodsList or {}, { global = true })
	Funcs:CreateDropdown(Fishing_Menu, "Baits", "SelectedBait", 1, Data.BaitsList or {}, { global = true })
	Fishing_Menu:addButton("Open Fish Index", Actions.OpenFishIndex or function() end)
	Funcs:CreateToggle(Fishing_Menu, "Auto Fishing", "Auto_Fishing", false, { global = true })
	Funcs:CreateToggle(Fishing_Menu, "Auto Catch Chest", "AutoGetChest", false, { global = true })
	Funcs:CreateToggle(Fishing_Menu, "Auto Craft Bait", "AutoCraftBait", false, { global = true })
	Funcs:CreateToggle(Fishing_Menu, "Auto Get / Complete Angler Quest", "AutoGetAnglerQuest", false, { global = true, save = true })
	Funcs:CreateToggle(Fishing_Menu, "Auto Sell Fish", "AutoSellFish", false, { global = true })
	Funcs:CreateToggle(Fishing_Menu, "Auto Use Rod Skill", "AutoUseRodSkill", false, { global = true })

	local Slap_Menu = SEvent_Right:addMenu("FishSlap Minigame")
	Funcs:CreateToggle(Slap_Menu, "Auto Fish Slap", "AutoSlap", false, { global = true })
end

function UITabs.BuildPlayer(Tab, ctx)
	local Funcs = ctx.Funcs
	local Settings = ctx.Settings
	local Module = ctx.Module
	local Actions = ctx.Actions or {}

	local Player_Left = Tab.Player:addSection()
	local PlayerStats_Menu = Player_Left:addMenu("Player Stats")
	local PlayerStat = PlayerStats_Menu:addLabel("Player Status", "Scanning for Information...")
	task.spawn(function()
		while task.wait(0.5) do
			if Actions.GetStatsInfo then
				PlayerStat:RefreshDesc(Actions.GetStatsInfo())
			end
		end
	end)

	Funcs:CreateSlider(PlayerStats_Menu, "Select Points", "PointsSlider", 0, 1000, 10, { global = true })
	PlayerStats_Menu:addToggle("Melee", false, function(Value) Settings.Melee = Value end)
	PlayerStats_Menu:addToggle("Defense", false, function(Value) Settings.Defense = Value end)
	PlayerStats_Menu:addToggle("Sword", false, function(Value) Settings.Sword = Value end)
	PlayerStats_Menu:addToggle("Gun", false, function(Value) Settings.Gun = Value end)
	PlayerStats_Menu:addToggle("Devil Fruit", false, function(Value) Settings.DemonFruit = Value end)
	PlayerStats_Menu:addToggle("Start Adding Stats", false, function(Value)
		Settings.AutoStats = Value
		if Settings.AutoStats and Actions.AutoStats then Actions.AutoStats() end
	end)

	local Player_Right = Tab.Player:addSection()
	local ESP_Menu = Player_Right:addMenu("ESP Menu")
	for _, esp in next, {
		{ "Players ESP", "ESPPlayer", "Player", ctx.PlayerESP },
		{ "Islands ESP", "ESPIsland", "Island", ctx.IslandESP },
		{ "Fruits ESP", "DevilFruitESP", "Fruit", ctx.FruitESP },
		{ "Chests ESP", "ESPChest", "Chest", ctx.ChestESP },
		{ "Berries ESP", "ESP_Berries", "Berry", ctx.BerryESP },
		{ "Natural Fruits ESP (Pineapple, etc.)", "ESP_RealFruits", "RealFruit", ctx.RealFruitESP }
	} do
		ESP_Menu:addToggle(esp[1], false, function(Value)
			Settings[esp[2]] = Value
			if not Value then
				if ctx.ClearESP then ctx.ClearESP(esp[3]) end
			else
				if esp[4] then esp[4]() end
			end
		end)
	end

	local PVP_Menu = Player_Right:addMenu("PVP Menu")
	local PlayerDropdown
	local function GetPList() return Actions.GetPlayerList and Actions.GetPlayerList() or { "Nearest" } end
	PlayerDropdown = Funcs:CreateDropdown(PVP_Menu, "Select Player", "SelectPlayer", 1, GetPList(), { global = true })
	PVP_Menu:addButton("Refresh Player List", function()
		if PlayerDropdown and PlayerDropdown.Refresh then
			PlayerDropdown:Refresh(GetPList())
		end
	end)

	Funcs:CreateToggle(PVP_Menu, "Cam Lock", "CamLock", false, { global = true, callback = Actions.OnCamLockToggle })
	Funcs:CreateToggle(PVP_Menu, "Spectate Player", "SpectatePlayer", false, { global = true, callback = Actions.OnSpectateToggle })
	Funcs:CreateToggle(PVP_Menu, "Teleport to Player", "TeleporttoPlayer", false, { global = true, stop = true, callback = Actions.OnTPPlayerToggle })
	Funcs:CreateToggle(PVP_Menu, "Enable Aimbot ", "EnableAimbot", false, { global = true })
	PVP_Menu:addButton("Get Player Quest", Actions.GetPlayerHunterQuest or function() end)

	local Server_Menu = Player_Right:addMenu("Server Menu")
	local ServerInfo = Server_Menu:addLabel("Server Status", "Loading..."); Module._ServerInfo = ServerInfo
	Server_Menu:addButton("Refresh Server Info", function()
		pcall(function()
			if Actions.StatusServer then ServerInfo:RefreshDesc(Actions.StatusServer()) end
		end)
	end)
	local PlayerInfo = Server_Menu:addLabel("Player Status", "Loading...")
	Server_Menu:addButton("Refresh Player Info", function()
		if Actions.PlayerStatus then PlayerInfo:RefreshDesc(Actions.PlayerStatus()) end
	end)
	local FruitStock = Server_Menu:addLabel("Fruit Stock", "Loading fruit stock...")
	Server_Menu:addButton("Refresh Fruit Stock", function()
		if Actions.GetFruitStock then FruitStock:RefreshDesc(Actions.GetFruitStock()) end
	end)
	task.spawn(function()
		task.wait(0.5)
		pcall(function()
			if Actions.StatusServer and ServerInfo then
				ServerInfo:RefreshDesc(Actions.StatusServer())
			end
		end)
	end)
end

function UITabs.BuildDragon(Tab, ctx)
	local Funcs = ctx.Funcs
	local Settings = ctx.Settings
	local Module = ctx.Module
	local Actions = ctx.Actions or {}

	local Dragon_Left = Tab.Dragon:addSection()
	local Berry_Menu = Dragon_Left:addMenu("Berry Farm")
	Funcs:CreateToggle(Berry_Menu, "Auto Collect Berries", "AutoBerrySafe", false, { global = true, stop = true })
	Funcs:CreateToggle(Berry_Menu, "Hop If No Berries", "HopIfNoBerries", false, { global = true, save = true })

	local Belt_Menu = Dragon_Left:addMenu("Belt Obtainment")
	Belt_Menu:addButton("Teleport to Dojo Trainer", Actions.TPDojoTrainer or function() end)
	Funcs:CreateToggle(Belt_Menu, "Auto White Belt", "AutoWhiteBelt", false, { global = true, stop = true })
	Funcs:CreateToggle(Belt_Menu, "Auto Purple Belt", "AutoPurpleBelt", false, { global = true, stop = true })

	local Dragon_Right = Tab.Dragon:addSection()
	local Prehistoric_Menu = Dragon_Right:addMenu("Prehistoric Event")
	local FindPrehistoricIsland = Funcs:CreateToggle(Prehistoric_Menu, "Auto Find Prehistoric Island", "AutoFindPrehistoricIsland", false, { global = true, save = true, stop = true })
	Module._FindPrehistoricIsland = FindPrehistoricIsland
	Funcs:CreateToggle(Prehistoric_Menu, "Teleport to Prehistoric Island", "AutoTeleportPrehistoric", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Prehistoric_Menu, "Auto Complete Volcanic Event", "AutoVolcanicEvent", false, { global = true, stop = true })
	Funcs:CreateToggle(Prehistoric_Menu, "Use Skull Guitar for Volcano", "ShootGunVolcano", true, { global = true, save = true, description = "Uses Skull Guitar custom shoot to patch the volcano" })
	Funcs:CreateToggle(Prehistoric_Menu, "Auto Collect Bones", "AutoCollectBones", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Prehistoric_Menu, "Auto Collect Dragon Eggs", "AutoCollectEgg", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Prehistoric_Menu, "Auto Farm Blaze Ember", "AutoQuestBlaze", false, { global = true, save = true, stop = true })
	Funcs:CreateDropdown(Prehistoric_Menu, "Select Gun", "SelectGunBlaze", 1, { "Skull Guitar", "Bazooka" }, { global = true })
	Funcs:CreateToggle(Prehistoric_Menu, "Use Shoot Gun for tree quest", "ShootGunBlaze", false, { global = true, save = true })
	Prehistoric_Menu:addButton("Teleport to Dragon Hunter", Actions.TPDragonHunter or function() end)
	Prehistoric_Menu:addButton("Teleport to Dragon Wizard", Actions.TPDragonWizard or function() end)
	Prehistoric_Menu:addToggle("Auto Upgrade Dragon Talon", false, Actions.ToggleUpgradeDragonTalon or function() end)
	Prehistoric_Menu:addButton("Craft Volcanic Magnet", function() Actions.CraftPrehistoricItem("Volcanic Magnet") end)
	Prehistoric_Menu:addButton("Craft Dragonheart", function() Actions.CraftPrehistoricItem("Dragonheart") end)
	Prehistoric_Menu:addButton("Craft Dragonstorm", function() Actions.CraftPrehistoricItem("Dragonstorm") end)
	Prehistoric_Menu:addButton("Craft Dino Hood", function() Actions.CraftPrehistoricItem("DinoHood") end)
	Prehistoric_Menu:addButton("Craft T-Rex Skull", function() Actions.CraftPrehistoricItem("TRexSkull") end)

	local Draco_Menu = Dragon_Right:addMenu("Draco Race")
	local AutoTrialDracoToggle = Funcs:CreateToggle(Draco_Menu, "Teleport to Draco Trial", "AutoTrialDracoTP", false, { global = true, stop = true })
	Module._AutoTrialDracoToggle = AutoTrialDracoToggle
	Draco_Menu:addButton("Change to Draco Race", Actions.ChangeDracoRace or function() end)
	Funcs:CreateToggle(Draco_Menu, "Auto Draco Race V2 ", "AutoCollectFireFlowers", false, { global = true, stop = true })
	Funcs:CreateToggle(Draco_Menu, "Auto Complete Draco Trial", "AutoCompleteDracoTrial", false, { locked = true, global = true, stop = true })
end

function UITabs.BuildRaid(Tab, ctx)
	local Funcs = ctx.Funcs
	local Settings = ctx.Settings
	local Module = ctx.Module
	local Data = ctx.Data or {}
	local Actions = ctx.Actions or {}

	local Raid_Left = Tab.Raid:addSection()
	local Raid_Menu = Raid_Left:addMenu("Raid Menu")
	Raid_Menu:addDropdown("Raid Chip", 1, Data.Raids_Chip or {}, function(Value) Settings.SelectRaid = Value end)
	Funcs:CreateToggle(Raid_Menu, "Auto Buy Chip", "AutoBuyChip", false, { global = true, save = true })
	local AutoRaidToggle = Funcs:CreateToggle(Raid_Menu, "Auto Complete Raid", "AutoRaidFull", false, { global = true, stop = true })
	Module._AutoRaidToggle = AutoRaidToggle
	Funcs:CreateToggle(Raid_Menu, "Instant Kill Islands 4-5 ", "InstantKillLateIslands", false, { locked = true, global = true })
	Funcs:CreateToggle(Raid_Menu, "Auto Unstore Below 1m Fruit", "AutoUnstoreBelowFruit", false, { global = true, save = true, description = "this will ignore fruit skins" })
	Funcs:CreateToggle(Raid_Menu, "Auto Awaken", "AutoAwaken", false, { global = true, save = true })
	Funcs:CreateSlider(Raid_Menu, "Frags Cap", "FragsCap", 1000, 1000000, 1000, { global = true })
	Funcs:CreateToggle(Raid_Menu, "Auto stop raid when fragments reach cap", "Autostopraid", false, { global = true, save = true })

	local Dungeon_Menu = Raid_Left:addMenu("Dungeon Menu")
	Funcs:CreateToggle(Dungeon_Menu, "Auto Unlock Difficulties", "AutoUnlockDifficulties", false, { global = true, save = true, description = "Automatically unlocks Hard and Challenge difficulties using Simulation Data" })
	Funcs:CreateToggle(Dungeon_Menu, "Auto Complete Dungeon", "AutoDungeonFull", false, { global = true, stop = true })
	Funcs:CreateToggle(Dungeon_Menu, "Auto Destroy Shrines and Vents", "AutoDungeonShrine", false, { global = true, stop = true })
	Funcs:CreateDropdown(Dungeon_Menu, "Select Cards", "CardsSelection", 1, Data.DungeonCards or {}, { global = true }, true)
	Funcs:CreateToggle(Dungeon_Menu, "Auto Select Cards", "AutoCardsDungeon", false, { global = true })
	Dungeon_Menu:addButton("Unlock Next Difficulty", Actions.UnlockDungeonDifficulty or function() end)
	Dungeon_Menu:addButton("Teleport to Dungeon Map", Actions.TPDungeonHub or function() end)
	Dungeon_Menu:addButton("Return to Previous Sea", Actions.TPDungeonBack or function() end)

	local Law_Menu = Raid_Left:addMenu("Law Menu")
	Funcs:CreateToggle(Law_Menu, "Start Law Raid Farm", "AutoLawRaid", false, { global = true, stop = true, save = true })

	local Raid_Right = Tab.Raid:addSection()
	local Fruit_Menu = Raid_Right:addMenu("Fruit Menu")
	Fruit_Menu:addButton("Open Normal Shop", Actions.OpenNormalFruitShop or function() end)
	Fruit_Menu:addButton("Open Advanced Shop", Actions.OpenAdvFruitShop or function() end)
	Funcs:CreateToggle(Fruit_Menu, "Auto Roll Fruit", "Random_Auto", false, { global = true, save = true })
	Funcs:CreateToggle(Fruit_Menu, "Auto Store Fruit", "AutoStoreFruit", false, { global = true, save = true })
	local FruitInfo = Fruit_Menu:addLabel("Fruit Spawn Status", "Scanning for fruit...")
	task.spawn(function()
		while task.wait(1.5) do
			if Actions.GetFruitSpawnStatus then
				FruitInfo:RefreshDesc(Actions.GetFruitSpawnStatus())
			end
		end
	end)
	Funcs:CreateToggle(Fruit_Menu, "Teleport to Fruit", "Tweenfruit", false, { global = true, save = true, stop = true })
	Funcs:CreateToggle(Fruit_Menu, "Hop If No Fruit In Server", "HopIfNoFruit", false, { global = true, save = true })
	Funcs:CreateSlider(Fruit_Menu, "Server Hop Delay (Fruit)", "HopDelay", 1, 60, 10, { global = true, save = true, description = "Delay in seconds before hopping when no fruit is found" })
	Funcs:CreateToggle(Fruit_Menu, "Fruit Notification", "FruitCheck", false, { global = true, save = true })
	Fruit_Menu:addButton("Teleport To Advanced Fruit Dealer", Actions.TPAdvFruitDealer or function() end)

	local Trinket_Menu = Raid_Right:addMenu("Trinkets & Refiner")
	Trinket_Menu:addButton("Buy Trinket", Actions.BuyTrinket or function() end)
	Funcs:CreateToggle(Trinket_Menu, "Auto Buy Trinkets", "AutoBuyTrinkets", false, { global = true, save = true, description = "Automatically buys trinkets when fragments/currency available" })
	Trinket_Menu:addButton("Fuse / Merge 3 Trinkets", Actions.FuseTrinkets or function() end)
	Funcs:CreateToggle(Trinket_Menu, "Auto Fuse / Merge Trinkets", "AutoFuseTrinkets", false, { global = true, save = true, description = "Automatically merges 3 matching trinkets to upgrade grade" })
	Trinket_Menu:addButton("Reforge / Refine Trinket", Actions.RefineTrinket or function() end)
	Funcs:CreateToggle(Trinket_Menu, "Auto Refine Trinket", "AutoRefineTrinkets", false, { global = true, save = true, description = "Automatically rerolls/refines trinket stats" })
	Trinket_Menu:addButton("Open Trinket Merge GUI", Actions.OpenTrinketMergeGUI or function() end)
	Trinket_Menu:addButton("Open Trinket Refiner GUI", Actions.OpenTrinketRefineGUI or function() end)
	Trinket_Menu:addButton("Open Trinket Scrap / Trash GUI", Actions.OpenTrinketScrapGUI or function() end)
	Funcs:CreateToggle(Trinket_Menu, "Auto Scrap Junk Trinkets", "AutoScrapTrinkets", false, { global = true, save = true, description = "Automatically scraps surplus trinkets for simulation data" })
end

function UITabs.BuildTrial(Tab, ctx)
	local Funcs = ctx.Funcs
	local Data = ctx.Data or {}
	local Actions = ctx.Actions or {}

	local Trial_Left = Tab.Trial:addSection()
	local Trial = Trial_Left:addMenu("Trials")
	if Actions.InitTempleOfTime then Actions.InitTempleOfTime() end
	Trial:addButton("Go to Race Door", Actions.TPRaceDoor or function() end)
	Funcs:CreateToggle(Trial, "Auto (Activate) Race", "AutoActiveRacenear", false, { global = true, description = "instantly activates the race the moment 2+ accounts are ready there" })
	Funcs:CreateToggle(Trial, "Auto Complete Trials", "AutoFinishTrial", false, { global = true, stop = true })
	Funcs:CreateToggle(Trial, "Kill Players after Trial", "AutoKillPlayerinTrial", false, { global = true, stop = true })
	Trial:addButton("Reset Character", Actions.ResetCharHead or function() end)
	Funcs:CreateToggle(Trial, "Auto Choose Gear", "AutoChooseGear", false, { global = true, stop = true, description = "Automatically selects and places your gear in the Ancient Clock upon winning the trial" })
	Funcs:CreateDropdown(Trial, "Train Method", "TrainMethod", "Bones", Data.TrainMethods or { "Bones", "Cakes" }, { global = true })
	Funcs:CreateToggle(Trial, "Start Auto Train", "AutoTrainGear", false, { global = true, stop = true })
	Funcs:CreateToggle(Trial, "Auto Pull Lever (Fully)", "AutoFullyPullLever", false, { locked = true, global = true, save = true, stop = true })
	Funcs:CreateToggle(Trial, "Teleport To Blue Gear", "TweenMGear", false, { global = true })

	local Tp = Trial_Left:addMenu("Area")
	Tp:addButton("Teleport to Top of Great Tree", function() Actions.TPTrialArea("GreatTree") end)
	Tp:addButton("Teleport to Temple of Time", function() Actions.TPTrialArea("TempleOfTime") end)
	Tp:addButton("Teleport to Ancient One", function() Actions.TPTrialArea("AncientOne") end)
	Tp:addButton("Teleport to Lever Pull", function() Actions.TPTrialArea("LeverPull") end)
	Tp:addButton("Teleport to Safe Zone", function() Actions.TPTrialArea("SafeZone") end)
	Tp:addButton("Teleport back to Pvp Zone", function() Actions.TPTrialArea("PvpZone") end)
	Tp:addButton("Teleport to Clock", function() Actions.TPTrialArea("Clock") end)

	local Trial_Right = Tab.Trial:addSection()
	local MTrial = Trial_Right:addMenu("Misc Trial")
	Funcs:CreateToggle(MTrial, "Auto Upgrade Gear", "BuyGear", false, { global = true })
	Funcs:CreateToggle(MTrial, "Auto Activate V3", "AutoAgility", false, { global = true, save = true })
	Funcs:CreateToggle(MTrial, "Auto Activate V4", "AutoActiveRaceV4", false, { global = true, save = true })
	Funcs:CreateToggle(MTrial, "Auto Look Moon", "AutoLookMoon", false, { global = true })

	local Upgrades = Trial_Right:addMenu("Upgrades")
	Funcs:CreateToggle(Upgrades, "Auto Race Evolve V2", "AutoStartRaceV2", false, { global = true, stop = true })
	Funcs:CreateToggle(Upgrades, "Auto Race Evolve V3", "AutoStartRaceV3", false, { global = true, stop = true })

	local raceobt = Trial_Right:addMenu("Race Obtainment")
	Funcs:CreateToggle(raceobt, "Auto Get Ghoul Race [Fully]", "AutoGetGhoulRace", false, { global = true, stop = true })
	Funcs:CreateToggle(raceobt, "Auto Get Cyborg Race [Fully]", "AutoGetCyborgRace", false, { global = true, stop = true })
end

function UITabs.BuildTravel(Tab, ctx)
	local Funcs = ctx.Funcs
	local Settings = ctx.Settings
	local Module = ctx.Module
	local Data = ctx.Data or {}
	local Actions = ctx.Actions or {}

	local Travel_Left = Tab.Travel:addSection()
	local World = Travel_Left:addMenu("World Travel")
	World:addButton("Teleport to World 1", function() Module:FireInvoke("TravelMain") end)
	World:addButton("Teleport to World 2", function() Module:FireInvoke("TravelDressrosa") end)
	World:addButton("Teleport to World 3", function() Module:FireInvoke("TravelZou") end)

	local Island = Travel_Left:addMenu("Island Travel")
	Module._ActiveIslands = Data.ActiveIslands or {}
	Island:addDropdown("Select Island", "walang kayo sorry", Data.IslandsList or {}, function(Value) Settings.TeleportIslandSelect = Value end)
	local TravelToggle = Funcs:CreateToggle(Island, "Start Traveling", "TeleportToIsland", false, { global = true, stop = true })
	Module._TravelToggle = TravelToggle

	local NPCT = Travel_Left:addMenu("NPC Travel")
	Funcs:CreateDropdown(NPCT, "Select Npc", "NpcTween", 1, Data.NPCList or {}, { global = true })
	Funcs:CreateToggle(NPCT, "Start Traveling", "TPtoNPC", false, { global = true, stop = true })

	local Travel_Right = Tab.Travel:addSection()
	local Server = Travel_Right:addMenu("Server Travel")
	Funcs:CreateTextbox(Server, "JobID [" .. game.PlaceId .. "]", "JobID", { save = false, callback = Actions.TeleportJobID })
	Funcs:CreateTextbox(Server, "Quantum Premium [" .. game.PlaceId .. "]", "QuantumPremium", { save = false, callback = Actions.TeleportQuantumPremium })
	Server:addButton("Copy Current Job ID", function() setclipboard(tostring(game.JobId)) end)

	local MServer = Travel_Right:addMenu("Misc Travel")
	MServer:addButton("Rejoin Server", Actions.RejoinServer or function() end)
	MServer:addButton("Server Hop, Random Server", Actions.ServerHop or function() end)

	local QJoiner = Travel_Right:addMenu("Quantum Joiner")
	QJoiner:addButton("Join Full Moon Server", function() Actions.JoinAPI("FullMoon") end)
	QJoiner:addButton("Join Near Full Moon Server", function() Actions.JoinAPI("NearFullMoon") end)
	QJoiner:addButton("Join Mirage Island Server", function() Actions.JoinAPI("mirage") end)
	QJoiner:addButton("Join Elite Hunter Server", function() Actions.JoinAPI("elites") end)
	QJoiner:addButton("Join Kitsune Island Server", function() Actions.JoinAPI("kitsune") end)
	QJoiner:addButton("Join Prehistoric Island Server", function() Actions.JoinAPI("prehistoric") end)
	QJoiner:addButton("Join Factory Raid Server", function() Actions.JoinAPI("factory") end)
	QJoiner:addButton("Join 4 Hours Server", function() Actions.JoinAPI("fourhours") end)
	QJoiner:addButton("Join Castle Raid Server", function() Actions.JoinAPI("pirate") end)
	Funcs:CreateDropdown(QJoiner, "Select Legendary Sword", "SelectLegendarySword", 1, Data.LegendarySwordNames or { "Shizu", "Oroshi", "Saishi" }, { global = true })
	QJoiner:addButton("Join Legendary Sword Server", function() Actions.JoinAPI("legendarysword") end)
	QJoiner:addButton("Join Fruit Server", function() Actions.JoinAPI("fruit") end)
	Funcs:CreateDropdown(QJoiner, "Select Boss", "SelectBosstoHop", 1, Data.BossHopNames or {}, { global = true })
	QJoiner:addButton("Join Raid Boss Server", Actions.JoinRaidBossServer or function() end)

	local AFKQJoiner = Travel_Right:addMenu("AFK Quantum Joiner")
	Funcs:CreateToggle(AFKQJoiner, "Auto Afk Join Castle Raid", "AutoAfkJoinCastleRaid", false, { locked = true, save = true, global = true })
	Funcs:CreateToggle(AFKQJoiner, "Auto Afk Join Factory Raid", "AutoAfkJoinFactoryRaid", false, { locked = true, global = true, save = true })
	Funcs:CreateToggle(AFKQJoiner, "Auto Afk Join Boss Raid", "AutoAfkJoinBossRaid", false, { locked = true, global = true, save = true })
	Funcs:CreateToggle(AFKQJoiner, "Auto Afk Join Elite Hunter", "AutoAfkJoinEliteHunter", false, { locked = true, global = true, save = true })
	Funcs:CreateToggle(AFKQJoiner, "Stop Hop If Chalice / Fist", "StopHopEliteIfChalice", true, { global = true, save = true })
end

function UITabs.BuildShop(Tab, ctx)
	local Funcs = ctx.Funcs
	local Settings = ctx.Settings
	local Data = ctx.Data or {}
	local Actions = ctx.Actions or {}

	local Shop_Left = Tab.Shop:addSection()
	local Selection = Shop_Left:addMenu("Selection Shop")
	Funcs:CreateDropdown(Selection, "Select Melee", "SelectMelee", 1, Data.MeleeNames or {}, { global = true })
	Funcs:CreateToggle(Selection, "Auto Buy Melee", "AutoBuyMelee", false, { global = true, stop = true })
	Funcs:CreateDropdown(Selection, "Abilities", "BuyAbility", "Geppo", Data.AbilityNames or {}, { global = true })
	Selection:addButton("Buy Ability", function() if Settings.BuyAbility and Actions.BuyItem then Actions.BuyItem(Settings.BuyAbility, "Ability") end end)
	Funcs:CreateDropdown(Selection, "Gun list", "GunSelect", "Slingshot", Data.GunNames or {}, { global = true })
	Selection:addButton("Buy Gun", function() if Settings.GunSelect and Actions.BuyItem then Actions.BuyItem(Settings.GunSelect, "Gun") end end)
	Funcs:CreateDropdown(Selection, "Accessories", "BuyAccessories", 1, Data.AccessoryNames or {}, { global = true })
	Selection:addButton("Buy Accessory", function() if Settings.BuyAccessories and Actions.BuyItem then Actions.BuyItem(Settings.BuyAccessories, "Accessory") end end)

	local ItemShop = Shop_Left:addMenu("Item Shop")
	Funcs:CreateToggle(ItemShop, "Buy Haki Color", "AutoBuyEnchancementColor", false, { global = true, save = true })
	Funcs:CreateToggle(ItemShop, "Buy Legendary Sword", "BuyLegendSword", false, { global = true, save = true })
	Funcs:CreateToggle(ItemShop, "Buy True Triple Katana", "BuyTTK", false, { global = true, save = true })

	local Shop_Right = Tab.Shop:addSection()
	local FruitDealerShop = Shop_Right:addMenu("Normal Fruit Dealer")
	Funcs:CreateDropdown(FruitDealerShop, "Select Fruit to Buy", "SelectFruitDealerFruit", "Buddha-Buddha", Data.DealerFruitList or {}, { global = true, save = true })
	Funcs:CreateToggle(FruitDealerShop, "Auto Buy Fruit (Normal Dealer)", "AutoBuyFruitDealer", false, { global = true, save = true })
	FruitDealerShop:addButton("Buy Selected Fruit", Actions.BuySelectedFruit or function() end)

	local RaceShop = Shop_Right:addMenu("Race Shop")
	RaceShop:addButton("Cyborg Race", Actions.BuyCyborgRace or function() end)
	RaceShop:addButton("Ghoul Race", Actions.BuyGhoulRace or function() end)

	local FragShop = Shop_Right:addMenu("Fragment Shop")
	FragShop:addButton("Reroll Race", function() if Actions.BuyItem then Actions.BuyItem("Race Rerol", "Frags") end end)
	FragShop:addButton("Reset Player Stats", function() if Actions.BuyItem then Actions.BuyItem("Reset Stats", "Frags") end end)

	local ScrollShop = Shop_Right:addMenu("Scroll Crafting & Trade")
	Funcs:CreateDropdown(ScrollShop, "Select Scroll", "SelectScrollType", "Common Scroll", { "Common Scroll", "Rare Scroll", "Legendary Scroll", "Mythical Scroll" }, { global = true, save = true })
	Funcs:CreateSlider(ScrollShop, "Craft Amount", "ScrollCraftAmount", 1, 10, 1, { global = true })
	ScrollShop:addButton("Craft Selected Scroll", Actions.CraftScroll or function() end)
	Funcs:CreateToggle(ScrollShop, "Auto Craft Selected Scroll", "AutoCraftScrolls", false, { global = true, save = true, description = "Automatically crafts scrolls when you have sufficient materials" })
end

function UITabs.BuildMisc(Tab, ctx)
	local Funcs = ctx.Funcs
	local Settings = ctx.Settings
	local Module = ctx.Module
	local Data = ctx.Data or {}
	local Actions = ctx.Actions or {}

	local Misc_Left = Tab.Misc:addSection()
	local TeamSelection = Misc_Left:addMenu("Team Selection")
	TeamSelection:addButton("Join Marines Team", function() Module:FireInvoke("SetTeam", "Marines") end)
	TeamSelection:addButton("Join Pirates Team", function() Module:FireInvoke("SetTeam", "Pirates") end)

	local OpenGuis = Misc_Left:addMenu("Menu Openings")
	OpenGuis:addButton("Open Title Names", Actions.OpenTitleNames or function() end)
	OpenGuis:addButton("Open Awakenings", Actions.OpenAwakenings or function() end)
	OpenGuis:addButton("Open Haki Colors", Actions.OpenHakiColors or function() end)

	local FakeAdmin = Misc_Left:addMenu("Fake Admin")
	FakeAdmin:addButtonGrid("Admin Panel", Data.AdminPanelGrid or {})

	local Misc_Right = Tab.Misc:addSection()
	local Client_Menu = Misc_Right:addMenu("Players Clients")
	Funcs:CreateToggle(Client_Menu, "Remove Observation Effect", "RemoveObservationEffect", false, { global = true, save = true })
	Client_Menu:addSlider("Walk Speed", 50, 500, 50, Actions.SetWalkSpeed or function() end)
	Client_Menu:addSlider("Jump Power", 50, 500, 50, Actions.SetJumpPower or function() end)
	Client_Menu:addToggle("X-ray Vision", false, Actions.ToggleXray or function() end)
	Client_Menu:addToggle("Infinite Zoom", false, Actions.ToggleInfiniteZoom or function() end)
	Client_Menu:addToggle("White Screen", false, Actions.ToggleWhiteScreen or function() end)
	Client_Menu:addToggle("Black Screen", false, Actions.ToggleBlackScreen or function() end)
	Client_Menu:addButton("Redeem all Codes", Actions.RedeemAllCodes or function() end)
	Funcs:CreateToggle(Client_Menu, "Remove Fog", "NoFog", false, { global = true, save = true })
	Client_Menu:addButton("Force FPS BOOST", Actions.ForceFPSBoost or function() end)
	Client_Menu:addButton("Developer Console", Actions.OpenDevConsole or function() end)
	Client_Menu:addButton("Clean Memory / Free RAM (GC)", Actions.CleanMemory or function() end)
	Funcs:CreateToggle(Client_Menu, "Auto Memory Cleaner (60s)", "AutoCleanMemory", true, { global = true, save = true })
	Funcs:CreateToggle(Client_Menu, "Auto Turn On Fast Mode", "AutoFastMode", false, { global = true, save = true, description = "Automatically enables the game's built-in Fast Mode setting to maximize FPS", callback = Actions.OnFastModeToggle })
end

function UITabs.BuildWeb(Tab, ctx)
	local Funcs = ctx.Funcs
	local Actions = ctx.Actions or {}

	local Web_Left = Tab.Web:addSection()
	local Weboe = Web_Left:addMenu("General Webhook")
	Funcs:CreateTextbox(Weboe, "Main Webhook Url", "Webhook", { save = true, global = true })
	Funcs:CreateToggle(Weboe, "Enable Send Webhook", "AutoWebhook", false, { global = true, save = true })
	Weboe:addButton("Send Test Webhook", Actions.SendTestWebhook or function() end)

	local Web_Events = Web_Left:addMenu("World & Fruit Events")
	Funcs:CreateToggle(Web_Events, "Send Webhook Prehistoric", "SendWebhookPrehistoric", false, { global = true, save = true })
	Funcs:CreateToggle(Web_Events, "Send Webhook Kitsune", "SendWebhookKitsune", false, { global = true, save = true })
	Funcs:CreateToggle(Web_Events, "Send Webhook Mirage", "SendWebhookMirage", false, { global = true, save = true })
	Funcs:CreateToggle(Web_Events, "Send Webhook Rolled Fruit", "SendWebhookRolledFruit", false, { global = true, save = true })
	Funcs:CreateToggle(Web_Events, "Send Webhook Store Fruit", "SendWebhookStoreFruit", false, { global = true, save = true })

	local Web_Right = Tab.Web:addSection()
	local Web_DataLog = Web_Right:addMenu("Data Log & Farm Tracker")
	Funcs:CreateToggle(Web_DataLog, "Enable Data Log Webhook", "SendWebhookDataLog", false, { global = true, save = true })
	Funcs:CreateTextbox(Web_DataLog, "DataLog Webhook URL (Optional)", "DataLogWebhookUrl", { save = true, global = true })
	Funcs:CreateSlider(Web_DataLog, "Data Log Interval (Minutes)", "DataLogInterval", 1, 60, 5, { global = true, save = true })
	Funcs:CreateToggle(Web_DataLog, "Send on Level Up", "SendWebhookLevelUp", false, { global = true, save = true })
	Funcs:CreateToggle(Web_DataLog, "Include Inventory in Data Log", "SendWebhookInventory", true, { global = true, save = true })
	Funcs:CreateToggle(Web_DataLog, "Include Farms All Summary", "SendWebhookFarmsAll", true, { global = true, save = true })
	Web_DataLog:addButton("Send Data Log Now", Actions.SendDataLogNow or function() end)

	local Web_Settings = Web_Right:addMenu("Webhook Ping & Settings")
	Funcs:CreateTextbox(Web_Settings, "Discord User ID (For Ping)", "WebhookPingId", { save = true, global = true })
	Funcs:CreateToggle(Web_Settings, "Ping on Mirage / Kitsune", "WebhookPingOnEvents", false, { global = true, save = true })
	Funcs:CreateToggle(Web_Settings, "Ping on Mythical Fruit", "WebhookPingOnMythical", false, { global = true, save = true })
end

function UITabs.BuildAll(Tab, ctx)
	UITabs.BuildHome(Tab, ctx)
	UITabs.BuildSub(Tab, ctx)
	UITabs.BuildSeaEvents(Tab, ctx)
	UITabs.BuildPlayer(Tab, ctx)
	UITabs.BuildDragon(Tab, ctx)
	UITabs.BuildRaid(Tab, ctx)
	UITabs.BuildTrial(Tab, ctx)
	UITabs.BuildTravel(Tab, ctx)
	UITabs.BuildShop(Tab, ctx)
	UITabs.BuildMisc(Tab, ctx)
	UITabs.BuildWeb(Tab, ctx)
end

setmetatable(UITabs, {
	__call = function(_, Tab, ctx)
		return UITabs.BuildAll(Tab, ctx)
	end
})

if getgenv then getgenv().UI_TabsModule = UITabs end
_G.UI_TabsModule = UITabs

return UITabs
