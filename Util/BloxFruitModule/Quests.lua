function CheckQuest()
    local MyLevel = tonumber(PlayerLevel.Value)

	local Mon = ""
	local NameQuest = ""
	local LevelQuest = 0

	if Sea_1 then
		if MyLevel >= 1  and MyLevel <= 9 then
			if tostring(lp.Team) == "Marines" then
				Mon, NameQuest, LevelQuest = "Trainee", "MarineQuest", 1
			elseif tostring(lp.Team) == "Pirates" then
				Mon, NameQuest, LevelQuest = "Bandit", "BanditQuest1", 1
			end
		elseif MyLevel >= 10 and MyLevel <= 14 then
			Mon, NameQuest, LevelQuest = "Monkey", "JungleQuest", 1
		elseif MyLevel >= 15 and MyLevel < 30 then
		if (CheckMon("The Gorilla King") and (MyLevel >= 20)) then
			Mon, NameQuest, LevelQuest = "The Gorilla King", "JungleQuest", 3
		else
			Mon, NameQuest, LevelQuest = "Gorilla", "JungleQuest", 2
		end
		elseif MyLevel >= 30 and MyLevel <= 39 then
			Mon, NameQuest, LevelQuest = "Pirate", "BuggyQuest1", 1
		elseif MyLevel >= 40 and MyLevel < 60 then
			if (CheckMon("Chief") and (MyLevel >= 55)) then
			Mon, NameQuest, LevelQuest = "Chief", "BuggyQuest1", 3
			else
			Mon, NameQuest, LevelQuest = "Brute", "BuggyQuest1", 2
			end
		elseif MyLevel >= 60 and MyLevel <= 74 then
			Mon, NameQuest, LevelQuest = "Desert Bandit", "DesertQuest", 1
		elseif MyLevel >= 75 and MyLevel <= 89 then
			Mon, NameQuest, LevelQuest = "Desert Officer", "DesertQuest", 2
		elseif MyLevel >= 90 and MyLevel <= 99 then
			Mon, NameQuest, LevelQuest = "Snow Bandit", "SnowQuest", 1
		elseif MyLevel >= 100 and MyLevel <= 119 then
			if (CheckMon("Yeti") and (MyLevel >= 105)) then
			Mon, NameQuest, LevelQuest = "Yeti", "SnowQuest", 3
			else
			Mon, NameQuest, LevelQuest = "Snowman", "SnowQuest", 2
			end
		elseif MyLevel >= 120 and MyLevel <= 149 then
			if (CheckMon("Vice Admiral") and (MyLevel >= 130)) then
			Mon, NameQuest, LevelQuest = "Vice Admiral", "MarineQuest2", 2
			else
			Mon, NameQuest, LevelQuest = "Chief Petty Officer", "MarineQuest2", 1
			end
		elseif MyLevel >= 150 and MyLevel <= 174 then
			Mon, NameQuest, LevelQuest = "Sky Bandit", "SkyQuest", 1
		elseif MyLevel >= 175 and MyLevel <= 189 then
			Mon, NameQuest, LevelQuest = "Dark Master", "SkyQuest", 2
		elseif MyLevel >= 190 and MyLevel <= 209 then
			Mon, NameQuest, LevelQuest = "Prisoner", "PrisonerQuest", 1
		elseif MyLevel >= 210 and MyLevel <= 249 then
			if (CheckMon("Swan") and (MyLevel >= 240)) then
				Mon, NameQuest, LevelQuest = "Swan", "ImpelQuest", 3
			elseif (CheckMon("Chief Warden") and (MyLevel >= 230)) then
				Mon, NameQuest, LevelQuest = "Chief Warden", "ImpelQuest", 2
			elseif (CheckMon("Warden") and (MyLevel >= 220)) then
				Mon, NameQuest, LevelQuest = "Warden", "ImpelQuest", 1
			else
				Mon, NameQuest, LevelQuest = "Dangerous Prisoner", "PrisonerQuest", 2
			end
		elseif MyLevel >= 250 and MyLevel <= 274 then
			Mon, NameQuest, LevelQuest = "Toga Warrior", "ColosseumQuest", 1
		elseif MyLevel >= 275 and MyLevel <= 299 then
			Mon, NameQuest, LevelQuest = "Gladiator",  "ColosseumQuest", 2
		elseif MyLevel >= 300 and MyLevel <= 324 then
			Mon, NameQuest, LevelQuest = "Military Soldier", "MagmaQuest", 1
		elseif MyLevel >= 325 and MyLevel <= 374 then
			if (CheckMon("Magma Admiral") and (MyLevel >= 350)) then
				Mon, NameQuest, LevelQuest = "Magma Admiral", "MagmaQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Military Spy", "MagmaQuest", 2
			end
		elseif MyLevel >= 375 and MyLevel <= 399 then
			Mon, NameQuest, LevelQuest = "Fishman Warrior", "FishmanQuest", 1
		elseif MyLevel >= 400 and MyLevel <= 449 then
			if (CheckMon("Fishman Lord") and (MyLevel >= 425)) then
				Mon, NameQuest, LevelQuest = "Fishman Lord", "FishmanQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Fishman Commando", "FishmanQuest", 2
			end
		elseif MyLevel >= 450 and MyLevel <= 474 then
			Mon, NameQuest, LevelQuest = "God's Guard", "SkyExp1Quest", 1
		elseif MyLevel >= 475 and MyLevel <= 524 then
			if (CheckMon("Wysper") and (MyLevel >= 500)) then
				Mon, NameQuest, LevelQuest = "Wysper", "SkyExp1Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Shanda", "SkyExp1Quest", 2
			end
		elseif MyLevel >= 525 and MyLevel <= 549 then
			Mon, NameQuest, LevelQuest = "Royal Squad", "SkyExp2Quest", 1
		elseif MyLevel >= 550 and MyLevel <= 624 then
			if (CheckMon("Thunder God") and (MyLevel >= 575)) then
				Mon, NameQuest, LevelQuest = "Thunder God", "SkyExp2Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Royal Soldier", "SkyExp2Quest", 2
			end
		elseif MyLevel >= 625 and MyLevel <= 649 then
			Mon, NameQuest, LevelQuest = "Galley Pirate", "FountainQuest", 1
	  elseif (MyLevel >= 650) then
		if CheckMon("Cyborg") and MyLevel >= 675 then
		  	Mon, NameQuest, LevelQuest = "Cyborg", "FountainQuest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Galley Captain", "FountainQuest", 2
		end
	  end
	elseif Sea_2 then
		if MyLevel >= 700 and MyLevel <= 724 then
			Mon, NameQuest, LevelQuest = "Raider", "Area1Quest", 1
		elseif MyLevel >= 725 and MyLevel <= 774 then
			if (CheckMon("Diamond") and (MyLevel >= 750)) then
				Mon, NameQuest, LevelQuest = "Diamond", "Area1Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Mercenary", "Area1Quest", 2
			end
		elseif MyLevel >= 775 and MyLevel <= 799 then
			Mon, NameQuest, LevelQuest = "Swan Pirate", "Area2Quest", 1
		elseif MyLevel >= 800 and MyLevel <= 874 then
			if (CheckMon("Jeremy") and (MyLevel >= 850)) then
				Mon, NameQuest, LevelQuest = "Jeremy", "Area2Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Factory Staff", "Area2Quest", 2
			end
		elseif MyLevel >= 875 and MyLevel <= 899 then
			Mon, NameQuest, LevelQuest = "Marine Lieutenant", "MarineQuest3", 1
		elseif MyLevel >= 900 and MyLevel <= 949 then
			if (CheckMon("Orbitus") and (MyLevel >= 925)) then
				Mon, NameQuest, LevelQuest = "Orbitus", "MarineQuest3", 3
			else
				Mon, NameQuest, LevelQuest = "Marine Captain", "MarineQuest3", 2
			end
		elseif MyLevel >= 950 and MyLevel <= 974 then
			Mon, NameQuest, LevelQuest = "Zombie", "ZombieQuest", 1
		elseif MyLevel >= 975 and MyLevel <= 999 then
			Mon, NameQuest, LevelQuest = "Vampire", "ZombieQuest", 2
		elseif MyLevel >= 1000 and MyLevel <= 1049 then
			Mon, NameQuest, LevelQuest = "Snow Trooper", "SnowMountainQuest", 1
		elseif MyLevel >= 1050 and MyLevel <= 1099 then
			Mon, NameQuest, LevelQuest = "Winter Warrior", "SnowMountainQuest", 2
		elseif MyLevel >= 1100 and MyLevel <= 1124 then
			Mon, NameQuest, LevelQuest = "Lab Subordinate", "IceSideQuest", 1
		elseif MyLevel >= 1125 and MyLevel <= 1174 then
			if (CheckMon("Smoke Admiral") and (MyLevel >= 1150)) then
				Mon, NameQuest, LevelQuest = "Smoke Admiral", "IceSideQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Horned Warrior", "IceSideQuest", 2
			end
		elseif MyLevel >= 1175 and MyLevel <= 1199 then
			Mon, NameQuest, LevelQuest = "Magma Ninja", "FireSideQuest", 1
		elseif MyLevel >= 1200 and MyLevel <= 1249 then
			Mon, NameQuest, LevelQuest = "Lava Pirate", "FireSideQuest", 2
		elseif MyLevel >= 1250 and MyLevel <= 1274 then
			Mon, NameQuest, LevelQuest = "Ship Deckhand", "ShipQuest1", 1
		elseif MyLevel >= 1275 and MyLevel <= 1299 then
			Mon, NameQuest, LevelQuest = "Ship Engineer", "ShipQuest1", 2
		elseif MyLevel >= 1300 and MyLevel <= 1324 then
			Mon, NameQuest, LevelQuest = "Ship Steward", "ShipQuest2", 1
		elseif MyLevel >= 1325 and MyLevel <= 1349 then
			Mon, NameQuest, LevelQuest = "Ship Officer", "ShipQuest2", 2
		elseif MyLevel >= 1350 and MyLevel <= 1374 then
			Mon, NameQuest, LevelQuest = "Arctic Warrior", "FrostQuest", 1
		elseif MyLevel >= 1375 and MyLevel <= 1424 then
			if (CheckMon("Awakened Ice Admiral") and (MyLevel >= 1400)) then
				Mon, NameQuest, LevelQuest = "Awakened Ice Admiral", "FrostQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Snow Lurker", "FrostQuest", 2
			end
		elseif MyLevel >= 1425 and MyLevel <= 1449 then
			Mon, NameQuest, LevelQuest = "Sea Soldier", "ForgottenQuest", 1
		elseif MyLevel >= 1450 then
		if (CheckMon("Tide Keeper") and (MyLevel >= 1475)) then
			Mon, NameQuest, LevelQuest = "Tide Keeper", "ForgottenQuest", 3
		else
			Mon, NameQuest, LevelQuest = "Water Fighter", "ForgottenQuest", 2
		end
	  end
	elseif Sea_3 then
		if MyLevel >= 1500 and MyLevel <= 1524 then
			Mon, NameQuest, LevelQuest = "Pirate Millionaire", "PiratePortQuest", 1
		elseif MyLevel >= 1525 and MyLevel <= 1574 then
			Mon, NameQuest, LevelQuest = "Pistol Billionaire", "PiratePortQuest", 2
		elseif MyLevel >= 1575 and MyLevel <= 1599 then
			Mon, NameQuest, LevelQuest = "Dragon Crew Warrior", "DragonCrewQuest", 1
		elseif MyLevel >= 1600 and MyLevel <= 1624 then
			Mon, NameQuest, LevelQuest = "Dragon Crew Archer", "DragonCrewQuest", 2
		elseif MyLevel >= 1625 and MyLevel <= 1649 then
			Mon, NameQuest, LevelQuest = "Hydra Enforcer", "VenomCrewQuest", 1
		elseif MyLevel >= 1650 and MyLevel <= 1699 then
			Mon, NameQuest, LevelQuest = "Venomous Assailant", "VenomCrewQuest", 2
		elseif MyLevel >= 1700 and MyLevel <= 1724 then
			Mon, NameQuest, LevelQuest = "Marine Commodore", "MarineTreeIsland", 1
		elseif MyLevel >= 1725 and MyLevel <= 1774 then
			Mon, NameQuest, LevelQuest = "Marine Rear Admiral", "MarineTreeIsland", 2
		elseif MyLevel >= 1775 and MyLevel <= 1799 then
			Mon, NameQuest, LevelQuest = "Fishman Raider", "DeepForestIsland3", 1
		elseif MyLevel >= 1800 and MyLevel <= 1824 then
			Mon, NameQuest, LevelQuest = "Fishman Captain", "DeepForestIsland3", 2
		elseif MyLevel >= 1825 and MyLevel <= 1849 then
			Mon, NameQuest, LevelQuest = "Forest Pirate", "DeepForestIsland", 1
		elseif MyLevel >= 1850 and MyLevel <= 1899 then
			Mon, NameQuest, LevelQuest = "Mythological Pirate", "DeepForestIsland", 2
		elseif MyLevel >= 1900 and MyLevel <= 1924 then
			Mon, NameQuest, LevelQuest = "Jungle Pirate", "DeepForestIsland2", 1
		elseif MyLevel >= 1925 and MyLevel <= 1974 then
			Mon, NameQuest, LevelQuest = "Musketeer Pirate", "DeepForestIsland2", 2
		elseif MyLevel >= 1975 and MyLevel <= 1999 then
			Mon, NameQuest, LevelQuest = "Reborn Skeleton", "HauntedQuest1", 1
		elseif MyLevel >= 2000 and MyLevel <= 2024 then
			Mon, NameQuest, LevelQuest = "Living Zombie", "HauntedQuest1", 2
		elseif MyLevel >= 2025 and MyLevel <= 2049 then
			Mon, NameQuest, LevelQuest = "Demonic Soul", "HauntedQuest2", 1
		elseif MyLevel >= 2050 and MyLevel <= 2074 then
			Mon, NameQuest, LevelQuest = "Posessed Mummy", "HauntedQuest2", 2
		elseif MyLevel >= 2075 and MyLevel <= 2099 then
			Mon, NameQuest, LevelQuest = "Peanut Scout", "NutsIslandQuest", 1
		elseif MyLevel >= 2100 and MyLevel <= 2124 then
			Mon, NameQuest, LevelQuest = "Peanut President", "NutsIslandQuest", 2
		elseif MyLevel >= 2125 and MyLevel <= 2149 then
			Mon, NameQuest, LevelQuest = "Ice Cream Chef", "IceCreamIslandQuest", 1
		elseif MyLevel >= 2150 and MyLevel <= 2199 then
			Mon, NameQuest, LevelQuest = "Ice Cream Commander", "IceCreamIslandQuest", 2
		elseif MyLevel >= 2200 and MyLevel <= 2224 then
			Mon, NameQuest, LevelQuest = "Cookie Crafter", "CakeQuest1", 1
		elseif MyLevel >= 2225 and MyLevel <= 2249 then
			Mon, NameQuest, LevelQuest = "Cake Guard", "CakeQuest1", 2
		elseif MyLevel >= 2250 and MyLevel <= 2274 then
			Mon, NameQuest, LevelQuest = "Baking Staff", "CakeQuest2", 1
		elseif MyLevel >= 2275 and MyLevel <= 2299 then
			Mon, NameQuest, LevelQuest = "Head Baker", "CakeQuest2", 2
		elseif MyLevel >= 2300 and MyLevel <= 2324 then
			Mon, NameQuest, LevelQuest = "Cocoa Warrior", "ChocQuest1", 1
		elseif MyLevel >= 2325 and MyLevel <= 2349 then
			Mon, NameQuest, LevelQuest = "Chocolate Bar Battler", "ChocQuest1", 2
		elseif MyLevel >= 2350 and MyLevel <= 2374 then
			Mon, NameQuest, LevelQuest = "Sweet Thief", "ChocQuest2", 1
		elseif MyLevel >= 2375 and MyLevel <= 2399 then
			Mon, NameQuest, LevelQuest = "Candy Rebel", "ChocQuest2", 2
		elseif MyLevel >= 2400 and MyLevel <= 2424 then
			Mon, NameQuest, LevelQuest = "Candy Pirate", "CandyQuest1", 1
		elseif MyLevel >= 2425 and MyLevel <= 2449 then
			Mon, NameQuest, LevelQuest = "Snow Demon", "CandyQuest1", 2
		elseif MyLevel >= 2450 and MyLevel <= 2474 then
			Mon, NameQuest, LevelQuest = "Isle Outlaw", "TikiQuest1", 1
		elseif MyLevel >= 2475 and MyLevel <= 2499 then
			Mon, NameQuest, LevelQuest = "Island Boy", "TikiQuest1", 2
		elseif MyLevel >= 2500 and MyLevel <= 2524 then
			Mon, NameQuest, LevelQuest = "Sun-kissed Warrior", "TikiQuest2", 1
		elseif MyLevel >= 2525 and MyLevel <= 2550 then
			Mon, NameQuest, LevelQuest = "Isle Champion", "TikiQuest2", 2
		elseif MyLevel >= 2550 and MyLevel <= 2574 then
			Mon, NameQuest, LevelQuest = "Serpent Hunter", "TikiQuest3", 1
		elseif MyLevel >= 2575 and MyLevel <= 2599 then
			Mon, NameQuest, LevelQuest = "Skull Slayer", "TikiQuest3", 2
		elseif MyLevel >= 2600 and MyLevel <= 2624 then
			Mon, NameQuest, LevelQuest = "Reef Bandit", "SubmergedQuest1", 1
		elseif MyLevel >= 2625 and MyLevel <= 2649 then
			Mon, NameQuest, LevelQuest = "Coral Pirate", "SubmergedQuest1", 2
		elseif MyLevel >= 2650 and MyLevel <= 2674 then
			Mon, NameQuest, LevelQuest = "Sea Chanter", "SubmergedQuest2", 1
		elseif MyLevel >= 2675 and MyLevel <= 2699 then
			Mon, NameQuest, LevelQuest = "High Disciple", "SubmergedQuest3", 1
		elseif MyLevel >= 2700 then
			Mon, NameQuest, LevelQuest = "Grand Devotee", "SubmergedQuest3", 2
		end
    end
	return {Mon, NameQuest, LevelQuest, MyLevel}
end
