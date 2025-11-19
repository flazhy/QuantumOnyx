local VM = {}
local VM_CACHE = {}

local function requireVM(path)
    path = path:gsub("\\","/")
    if VM_CACHE[path] then return VM_CACHE[path] end
    local moduleFn = VM[path]
    if not moduleFn then error("Module not found: "..path) end
    local result = moduleFn()
    VM_CACHE[path] = result
    return result
end


return function()
    local module = {}
    function module.CheckQuest(deps)
        local PlayerLevel = deps.PlayerLevel
        local World1, World2, World3 = deps.World1, deps.World2, deps.World3
        local Player = deps.Player
        local CheckMon = deps.CheckMon

        local Levels = tonumber(PlayerLevel.Value)
        local Mon, NameQuest, LevelQuest
		
    Levels = tonumber(PlayerLevel.Value)
		if World1 then
			if Levels >= 1  and Levels <= 9 then
				if tostring(Player.Team) == "Marines" then
					Mon, NameQuest, LevelQuest = "Trainee", "MarineQuest", 1
				elseif tostring(Player.Team) == "Pirates" then
					Mon, NameQuest, LevelQuest = "Bandit", "BanditQuest1", 1
				end
			elseif Levels >= 10 and Levels <= 14 then
				Mon, NameQuest, LevelQuest = "Monkey", "JungleQuest", 1
			elseif Levels >= 15 and Levels < 30 then
			if (CheckMon("The Gorilla King") and (Levels >= 20)) then
				Mon, NameQuest, LevelQuest = "The Gorilla King", "JungleQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Gorilla", "JungleQuest", 2
			end
			elseif Levels >= 30 and Levels <= 39 then
				Mon, NameQuest, LevelQuest = "Pirate", "BuggyQuest1", 1
			elseif Levels >= 40 and Levels < 60 then
				if (CheckMon("Chief") and (Levels >= 55)) then
				Mon, NameQuest, LevelQuest = "Chief", "BuggyQuest1", 3
				else
				Mon, NameQuest, LevelQuest = "Brute", "BuggyQuest1", 2
				end
			elseif Levels >= 60 and Levels <= 74 then
				Mon, NameQuest, LevelQuest = "Desert Bandit", "DesertQuest", 1
			elseif Levels >= 75 and Levels <= 89 then
				Mon, NameQuest, LevelQuest = "Desert Officer", "DesertQuest", 2
			elseif Levels >= 90 and Levels <= 99 then
				Mon, NameQuest, LevelQuest = "Snow Bandit", "SnowQuest", 1
			elseif Levels >= 100 and Levels <= 119 then
				if (CheckMon("Yeti") and (Levels >= 105)) then
				Mon, NameQuest, LevelQuest = "Yeti", "SnowQuest", 3
				else
				Mon, NameQuest, LevelQuest = "Snowman", "SnowQuest", 2
				end
			elseif Levels >= 120 and Levels <= 149 then
				if (CheckMon("Vice Admiral") and (Levels >= 130)) then
				Mon, NameQuest, LevelQuest = "Vice Admiral", "MarineQuest2", 2
				else
				Mon, NameQuest, LevelQuest = "Chief Petty Officer", "MarineQuest2", 1
				end
			elseif Levels >= 150 and Levels <= 174 then
				Mon, NameQuest, LevelQuest = "Sky Bandit", "SkyQuest", 1
			elseif Levels >= 175 and Levels <= 189 then
				Mon, NameQuest, LevelQuest = "Dark Master", "SkyQuest", 2
			elseif Levels >= 190 and Levels <= 209 then
				Mon, NameQuest, LevelQuest = "Prisoner", "PrisonerQuest", 1
			elseif Levels >= 210 and Levels <= 249 then
				if (CheckMon("Swan") and (Levels >= 240)) then
					Mon, NameQuest, LevelQuest = "Swan", "ImpelQuest", 3
				elseif (CheckMon("Chief Warden") and (Levels >= 230)) then
					Mon, NameQuest, LevelQuest = "Chief Warden", "ImpelQuest", 2
				elseif (CheckMon("Warden") and (Levels >= 220)) then
					Mon, NameQuest, LevelQuest = "Warden", "ImpelQuest", 1
				else
					Mon, NameQuest, LevelQuest = "Dangerous Prisoner", "PrisonerQuest", 2
				end
			elseif Levels >= 250 and Levels <= 274 then
				Mon, NameQuest, LevelQuest = "Toga Warrior", "ColosseumQuest", 1
			elseif Levels >= 275 and Levels <= 299 then
				Mon, NameQuest, LevelQuest = "Gladiator",  "ColosseumQuest", 2
			elseif Levels >= 300 and Levels <= 324 then
				Mon, NameQuest, LevelQuest = "Military Soldier", "MagmaQuest", 1
			elseif Levels >= 325 and Levels <= 374 then
				if (CheckMon("Magma Admiral") and (Levels >= 350)) then
					Mon, NameQuest, LevelQuest = "Magma Admiral", "MagmaQuest", 3
				else
					Mon, NameQuest, LevelQuest = "Military Spy", "MagmaQuest", 2
				end
			elseif Levels >= 375 and Levels <= 399 then
				Mon, NameQuest, LevelQuest = "Fishman Warrior", "FishmanQuest", 1
			elseif Levels >= 400 and Levels <= 449 then
				if (CheckMon("Fishman Lord") and (Levels >= 425)) then
					Mon, NameQuest, LevelQuest = "Fishman Lord", "FishmanQuest", 3
				else
					Mon, NameQuest, LevelQuest = "Fishman Commando", "FishmanQuest", 2
				end
			elseif Levels >= 450 and Levels <= 474 then
				Mon, NameQuest, LevelQuest = "God's Guard", "SkyExp1Quest", 1
			elseif Levels >= 475 and Levels <= 524 then
				if (CheckMon("Wysper") and (Levels >= 500)) then
					Mon, NameQuest, LevelQuest = "Wysper", "SkyExp1Quest", 3
				else
					Mon, NameQuest, LevelQuest = "Shanda", "SkyExp1Quest", 2
				end
			elseif Levels >= 525 and Levels <= 549 then
				Mon, NameQuest, LevelQuest = "Royal Squad", "SkyExp2Quest", 1
			elseif Levels >= 550 and Levels <= 624 then
				if (CheckMon("Thunder God") and (Levels >= 575)) then
					Mon, NameQuest, LevelQuest = "Thunder God", "SkyExp2Quest", 3
				else
					Mon, NameQuest, LevelQuest = "Royal Soldier", "SkyExp2Quest", 2
				end
			elseif Levels >= 625 and Levels <= 649 then
				Mon, NameQuest, LevelQuest = "Galley Pirate", "FountainQuest", 1
		  elseif (Levels >= 650) then
			if CheckMon("Cyborg") and Levels >= 675 then
			  	Mon, NameQuest, LevelQuest = "Cyborg", "FountainQuest", 3
			else
			  	Mon, NameQuest, LevelQuest = "Galley Captain", "FountainQuest", 2
			end
		  end
		end
		if World2 then
			if Levels >= 700 and Levels <= 724 then
				Mon, NameQuest, LevelQuest = "Raider", "Area1Quest", 1
			elseif Levels >= 725 and Levels <= 774 then
				if (CheckMon("Diamond") and (Levels >= 750)) then
					Mon, NameQuest, LevelQuest = "Diamond", "Area1Quest", 3
				else
					Mon, NameQuest, LevelQuest = "Mercenary", "Area1Quest", 2
				end
			elseif Levels >= 775 and Levels <= 799 then
				Mon, NameQuest, LevelQuest = "Swan Pirate", "Area2Quest", 1
			elseif Levels >= 800 and Levels <= 874 then
				if (CheckMon("Jeremy") and (Levels >= 850)) then
					Mon, NameQuest, LevelQuest = "Jeremy", "Area2Quest", 3
				else
					Mon, NameQuest, LevelQuest = "Factory Staff", "Area2Quest", 2
				end
			elseif Levels >= 875 and Levels <= 899 then
				Mon, NameQuest, LevelQuest = "Marine Lieutenant", "MarineQuest3", 1
			elseif Levels >= 900 and Levels <= 949 then
				if (CheckMon("Orbitus") and (Levels >= 925)) then
					Mon, NameQuest, LevelQuest = "Orbitus", "MarineQuest3", 3
				else
					Mon, NameQuest, LevelQuest = "Marine Captain", "MarineQuest3", 2
				end
			elseif Levels >= 950 and Levels <= 974 then
				Mon, NameQuest, LevelQuest = "Zombie", "ZombieQuest", 1
			elseif Levels >= 975 and Levels <= 999 then
				Mon, NameQuest, LevelQuest = "Vampire", "ZombieQuest", 2
			elseif Levels >= 1000 and Levels <= 1049 then
				Mon, NameQuest, LevelQuest = "Snow Trooper", "SnowMountainQuest", 1
			elseif Levels >= 1050 and Levels <= 1099 then
				Mon, NameQuest, LevelQuest = "Winter Warrior", "SnowMountainQuest", 2
			elseif Levels >= 1100 and Levels <= 1124 then
				Mon, NameQuest, LevelQuest = "Lab Subordinate", "IceSideQuest", 1
			elseif Levels >= 1125 and Levels <= 1174 then
				if (CheckMon("Smoke Admiral") and (Levels >= 1150)) then
					Mon, NameQuest, LevelQuest = "Smoke Admiral", "IceSideQuest", 3
				else
					Mon, NameQuest, LevelQuest = "Horned Warrior", "IceSideQuest", 2
				end
			elseif Levels >= 1175 and Levels <= 1199 then
				Mon, NameQuest, LevelQuest = "Magma Ninja", "FireSideQuest", 1
			elseif Levels >= 1200 and Levels <= 1249 then
				Mon, NameQuest, LevelQuest = "Lava Pirate", "FireSideQuest", 2
			elseif Levels >= 1250 and Levels <= 1274 then
				Mon, NameQuest, LevelQuest = "Ship Deckhand", "ShipQuest1", 1
			elseif Levels >= 1275 and Levels <= 1299 then
				Mon, NameQuest, LevelQuest = "Ship Engineer", "ShipQuest1", 2
			elseif Levels >= 1300 and Levels <= 1324 then
				Mon, NameQuest, LevelQuest = "Ship Steward", "ShipQuest2", 1
			elseif Levels >= 1325 and Levels <= 1349 then
				Mon, NameQuest, LevelQuest = "Ship Officer", "ShipQuest2", 2
			elseif Levels >= 1350 and Levels <= 1374 then
				Mon, NameQuest, LevelQuest = "Arctic Warrior", "FrostQuest", 1
			elseif Levels >= 1375 and Levels <= 1424 then
				if (CheckMon("Awakened Ice Admiral") and (Levels >= 1400)) then
					Mon, NameQuest, LevelQuest = "Awakened Ice Admiral", "FrostQuest", 3
				else
					Mon, NameQuest, LevelQuest = "Snow Lurker", "FrostQuest", 2
				end
			elseif Levels >= 1425 and Levels <= 1449 then
				Mon, NameQuest, LevelQuest = "Sea Soldier", "ForgottenQuest", 1
			elseif Levels >= 1450 then
			if (CheckMon("Tide Keeper") and (Levels >= 1475)) then
				Mon, NameQuest, LevelQuest = "Tide Keeper", "ForgottenQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Water Fighter", "ForgottenQuest", 2
			end
		  end
		end
		if World3 then
			if Levels >= 1500 and Levels <= 1524 then
				Mon, NameQuest, LevelQuest = "Pirate Millionaire", "PiratePortQuest", 1
			elseif Levels >= 1525 and Levels <= 1574 then
				Mon, NameQuest, LevelQuest = "Pistol Billionaire", "PiratePortQuest", 2
			elseif Levels >= 1575 and Levels <= 1599 then
				Mon, NameQuest, LevelQuest = "Dragon Crew Warrior", "DragonCrewQuest", 1
			elseif Levels >= 1600 and Levels <= 1624 then
				Mon, NameQuest, LevelQuest = "Dragon Crew Archer", "DragonCrewQuest", 2
			elseif Levels >= 1625 and Levels <= 1649 then
				Mon, NameQuest, LevelQuest = "Hydra Enforcer", "VenomCrewQuest", 1
			elseif Levels >= 1650 and Levels <= 1699 then
				Mon, NameQuest, LevelQuest = "Venomous Assailant", "VenomCrewQuest", 2
			elseif Levels >= 1700 and Levels <= 1724 then
				Mon, NameQuest, LevelQuest = "Marine Commodore", "MarineTreeIsland", 1
			elseif Levels >= 1725 and Levels <= 1774 then
				Mon, NameQuest, LevelQuest = "Marine Rear Admiral", "MarineTreeIsland", 2
			elseif Levels >= 1775 and Levels <= 1799 then
				Mon, NameQuest, LevelQuest = "Fishman Raider", "DeepForestIsland3", 1
			elseif Levels >= 1800 and Levels <= 1824 then
				Mon, NameQuest, LevelQuest = "Fishman Captain", "DeepForestIsland3", 2
			elseif Levels >= 1825 and Levels <= 1849 then
				Mon, NameQuest, LevelQuest = "Forest Pirate", "DeepForestIsland", 1
			elseif Levels >= 1850 and Levels <= 1899 then
				Mon, NameQuest, LevelQuest = "Mythological Pirate", "DeepForestIsland", 2
			elseif Levels >= 1900 and Levels <= 1924 then
				Mon, NameQuest, LevelQuest = "Jungle Pirate", "DeepForestIsland2", 1
			elseif Levels >= 1925 and Levels <= 1974 then
				Mon, NameQuest, LevelQuest = "Musketeer Pirate", "DeepForestIsland2", 2
			elseif Levels >= 1975 and Levels <= 1999 then
				Mon, NameQuest, LevelQuest = "Reborn Skeleton", "HauntedQuest1", 1
			elseif Levels >= 2000 and Levels <= 2024 then
				Mon, NameQuest, LevelQuest = "Living Zombie", "HauntedQuest1", 2
			elseif Levels >= 2025 and Levels <= 2049 then
				Mon, NameQuest, LevelQuest = "Demonic Soul", "HauntedQuest2", 1
			elseif Levels >= 2050 and Levels <= 2074 then
				Mon, NameQuest, LevelQuest = "Posessed Mummy", "HauntedQuest2", 2
			elseif Levels >= 2075 and Levels <= 2099 then
				Mon, NameQuest, LevelQuest = "Peanut Scout", "NutsIslandQuest", 1
			elseif Levels >= 2100 and Levels <= 2124 then
				Mon, NameQuest, LevelQuest = "Peanut President", "NutsIslandQuest", 2
			elseif Levels >= 2125 and Levels <= 2149 then
				Mon, NameQuest, LevelQuest = "Ice Cream Chef", "IceCreamIslandQuest", 1
			elseif Levels >= 2150 and Levels <= 2199 then
				Mon, NameQuest, LevelQuest = "Ice Cream Commander", "IceCreamIslandQuest", 2
			elseif Levels >= 2200 and Levels <= 2224 then
				Mon, NameQuest, LevelQuest = "Cookie Crafter", "CakeQuest1", 1
			elseif Levels >= 2225 and Levels <= 2249 then
				Mon, NameQuest, LevelQuest = "Cake Guard", "CakeQuest1", 2
			elseif Levels >= 2250 and Levels <= 2274 then
				Mon, NameQuest, LevelQuest = "Baking Staff", "CakeQuest2", 1
			elseif Levels >= 2275 and Levels <= 2299 then
				Mon, NameQuest, LevelQuest = "Head Baker", "CakeQuest2", 2
			elseif Levels >= 2300 and Levels <= 2324 then
				Mon, NameQuest, LevelQuest = "Cocoa Warrior", "ChocQuest1", 1
			elseif Levels >= 2325 and Levels <= 2349 then
				Mon, NameQuest, LevelQuest = "Chocolate Bar Battler", "ChocQuest1", 2
			elseif Levels >= 2350 and Levels <= 2374 then
				Mon, NameQuest, LevelQuest = "Sweet Thief", "ChocQuest2", 1
			elseif Levels >= 2375 and Levels <= 2399 then
				Mon, NameQuest, LevelQuest = "Candy Rebel", "ChocQuest2", 2
			elseif Levels >= 2400 and Levels <= 2424 then
				Mon, NameQuest, LevelQuest = "Candy Pirate", "CandyQuest1", 1
			elseif Levels >= 2425 and Levels <= 2449 then
				Mon, NameQuest, LevelQuest = "Snow Demon", "CandyQuest1", 2
			elseif Levels >= 2450 and Levels <= 2474 then
				Mon, NameQuest, LevelQuest = "Isle Outlaw", "TikiQuest1", 1
			elseif Levels >= 2475 and Levels <= 2499 then
				Mon, NameQuest, LevelQuest = "Island Boy", "TikiQuest1", 2
			elseif Levels >= 2500 and Levels <= 2524 then
				Mon, NameQuest, LevelQuest = "Sun-kissed Warrior", "TikiQuest2", 1
			elseif Levels >= 2525 and Levels <= 2550 then
				Mon, NameQuest, LevelQuest = "Isle Champion", "TikiQuest2", 2
			elseif Levels >= 2550 and Levels <= 2574 then
				Mon, NameQuest, LevelQuest = "Serpent Hunter", "TikiQuest3", 1
			elseif Levels >= 2575 and Levels <= 2599 then
				Mon, NameQuest, LevelQuest = "Skull Slayer", "TikiQuest3", 2
			elseif Levels >= 2600 and Levels <= 2624 then
				Mon, NameQuest, LevelQuest = "Reef Bandit", "SubmergedQuest1", 1
			elseif Levels >= 2625 and Levels <= 2649 then
				Mon, NameQuest, LevelQuest = "Coral Pirate", "SubmergedQuest1", 2
			elseif Levels >= 2650 and Levels <= 2674 then
				Mon, NameQuest, LevelQuest = "Sea Chanter", "SubmergedQuest2", 1
			elseif Levels >= 2675 and Levels <= 2699 then
				Mon, NameQuest, LevelQuest = "High Disciple", "SubmergedQuest3", 1
			elseif Levels >= 2700 then
				Mon, NameQuest, LevelQuest = "Grand Devotee", "SubmergedQuest3", 2
			end
	    end
	end
}
