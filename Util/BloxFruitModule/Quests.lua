local PlaceID = game.PlaceId
local Sea_1 = (PlaceID == 2753915549 or PlaceID == 85211729168715)
local Sea_2 = (PlaceID == 4442272183 or PlaceID == 79091703265657)
local Sea_3 = (PlaceID == 7449423635 or PlaceID == 100117331123089)
function IsBoss(args1)
	for a,b in ipairs({workspace:WaitForChild("Enemies"), game:GetService("ReplicatedStorage")}) do
		if b then
			for i,v in ipairs(b:GetChildren()) do
				if v.Name == args1 then
					local Humanoid = v:FindFirstChild("Humanoid")
					if Humanoid and Humanoid.Health > 0 then
						return true
					end
				end
			end
		end
	end
	return false
end
return function()
    local MyLvl = game:GetService("Players").LocalPlayer.Data.Level.Value
	local Mon, NameQuest, LevelQuest  = "", "", 0

	if Sea_1 then
		if MyLvl >= 1  and MyLvl <= 9 then
			if tostring(game:GetService("Players").LocalPlayer.Team) == "Marines" then
				Mon, NameQuest, LevelQuest = "Trainee", "MarineQuest", 1
			elseif tostring(game:GetService("Players").LocalPlayer.Team) == "Pirates" then
				Mon, NameQuest, LevelQuest = "Bandit", "BanditQuest1", 1
			end
		elseif MyLvl >= 10 and MyLvl <= 14 then
			Mon, NameQuest, LevelQuest = "Monkey", "JungleQuest", 1
		elseif MyLvl >= 15 and MyLvl < 30 then
		if (IsBoss("The Gorilla King") and (MyLvl >= 20)) then
			Mon, NameQuest, LevelQuest = "The Gorilla King", "JungleQuest", 3
		else
			Mon, NameQuest, LevelQuest = "Gorilla", "JungleQuest", 2
		end
		elseif MyLvl >= 30 and MyLvl <= 39 then
			Mon, NameQuest, LevelQuest = "Pirate", "BuggyQuest1", 1
		elseif MyLvl >= 40 and MyLvl < 60 then
			if (IsBoss("Chief") and (MyLvl >= 55)) then
			Mon, NameQuest, LevelQuest = "Chief", "BuggyQuest1", 3
			else
			Mon, NameQuest, LevelQuest = "Brute", "BuggyQuest1", 2
			end
		elseif MyLvl >= 60 and MyLvl <= 74 then
			Mon, NameQuest, LevelQuest = "Desert Bandit", "DesertQuest", 1
		elseif MyLvl >= 75 and MyLvl <= 89 then
			Mon, NameQuest, LevelQuest = "Desert Officer", "DesertQuest", 2
		elseif MyLvl >= 90 and MyLvl <= 99 then
			Mon, NameQuest, LevelQuest = "Snow Bandit", "SnowQuest", 1
		elseif MyLvl >= 100 and MyLvl <= 119 then
			if (IsBoss("Yeti") and (MyLvl >= 105)) then
			Mon, NameQuest, LevelQuest = "Yeti", "SnowQuest", 3
			else
			Mon, NameQuest, LevelQuest = "Snowman", "SnowQuest", 2
			end
		elseif MyLvl >= 120 and MyLvl <= 149 then
			if (IsBoss("Vice Admiral") and (MyLvl >= 130)) then
			Mon, NameQuest, LevelQuest = "Vice Admiral", "MarineQuest2", 2
			else
			Mon, NameQuest, LevelQuest = "Chief Petty Officer", "MarineQuest2", 1
			end
		elseif MyLvl >= 150 and MyLvl <= 174 then
			Mon, NameQuest, LevelQuest = "Sky Bandit", "SkyQuest", 1
		elseif MyLvl >= 175 and MyLvl <= 189 then
			Mon, NameQuest, LevelQuest = "Dark Master", "SkyQuest", 2
		elseif MyLvl >= 190 and MyLvl <= 209 then
			Mon, NameQuest, LevelQuest = "Prisoner", "PrisonerQuest", 1
		elseif MyLvl >= 210 and MyLvl <= 249 then
			if (IsBoss("Swan") and (MyLvl >= 240)) then
				Mon, NameQuest, LevelQuest = "Swan", "ImpelQuest", 3
			elseif (IsBoss("Chief Warden") and (MyLvl >= 230)) then
				Mon, NameQuest, LevelQuest = "Chief Warden", "ImpelQuest", 2
			elseif (IsBoss("Warden") and (MyLvl >= 220)) then
				Mon, NameQuest, LevelQuest = "Warden", "ImpelQuest", 1
			else
				Mon, NameQuest, LevelQuest = "Dangerous Prisoner", "PrisonerQuest", 2
			end
		elseif MyLvl >= 250 and MyLvl <= 274 then
			Mon, NameQuest, LevelQuest = "Toga Warrior", "ColosseumQuest", 1
		elseif MyLvl >= 275 and MyLvl <= 299 then
			Mon, NameQuest, LevelQuest = "Gladiator",  "ColosseumQuest", 2
		elseif MyLvl >= 300 and MyLvl <= 324 then
			Mon, NameQuest, LevelQuest = "Military Soldier", "MagmaQuest", 1
		elseif MyLvl >= 325 and MyLvl <= 374 then
			if (IsBoss("Magma Admiral") and (MyLvl >= 350)) then
				Mon, NameQuest, LevelQuest = "Magma Admiral", "MagmaQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Military Spy", "MagmaQuest", 2
			end
		elseif MyLvl >= 375 and MyLvl <= 399 then
			Mon, NameQuest, LevelQuest = "Fishman Warrior", "FishmanQuest", 1
		elseif MyLvl >= 400 and MyLvl <= 449 then
			if (IsBoss("Fishman Lord") and (MyLvl >= 425)) then
				Mon, NameQuest, LevelQuest = "Fishman Lord", "FishmanQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Fishman Commando", "FishmanQuest", 2
			end
		elseif MyLvl >= 450 and MyLvl <= 474 then
			Mon, NameQuest, LevelQuest = "God's Guard", "SkyExp1Quest", 1
		elseif MyLvl >= 475 and MyLvl <= 524 then
			if (IsBoss("Wysper") and (MyLvl >= 500)) then
				Mon, NameQuest, LevelQuest = "Wysper", "SkyExp1Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Shanda", "SkyExp1Quest", 2
			end
		elseif MyLvl >= 525 and MyLvl <= 549 then
			Mon, NameQuest, LevelQuest = "Royal Squad", "SkyExp2Quest", 1
		elseif MyLvl >= 550 and MyLvl <= 624 then
			if (IsBoss("Thunder God") and (MyLvl >= 575)) then
				Mon, NameQuest, LevelQuest = "Thunder God", "SkyExp2Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Royal Soldier", "SkyExp2Quest", 2
			end
		elseif MyLvl >= 625 and MyLvl <= 649 then
			Mon, NameQuest, LevelQuest = "Galley Pirate", "FountainQuest", 1
	  elseif (MyLvl >= 650) then
		if IsBoss("Cyborg") and MyLvl >= 675 then
		  	Mon, NameQuest, LevelQuest = "Cyborg", "FountainQuest", 3
		else
		  	Mon, NameQuest, LevelQuest = "Galley Captain", "FountainQuest", 2
		end
	  end
	elseif Sea_2 then
		if MyLvl >= 700 and MyLvl <= 724 then
			Mon, NameQuest, LevelQuest = "Raider", "Area1Quest", 1
		elseif MyLvl >= 725 and MyLvl <= 774 then
			if (IsBoss("Diamond") and (MyLvl >= 750)) then
				Mon, NameQuest, LevelQuest = "Diamond", "Area1Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Mercenary", "Area1Quest", 2
			end
		elseif MyLvl >= 775 and MyLvl <= 799 then
			Mon, NameQuest, LevelQuest = "Swan Pirate", "Area2Quest", 1
		elseif MyLvl >= 800 and MyLvl <= 874 then
			if (IsBoss("Jeremy") and (MyLvl >= 850)) then
				Mon, NameQuest, LevelQuest = "Jeremy", "Area2Quest", 3
			else
				Mon, NameQuest, LevelQuest = "Factory Staff", "Area2Quest", 2
			end
		elseif MyLvl >= 875 and MyLvl <= 899 then
			Mon, NameQuest, LevelQuest = "Marine Lieutenant", "MarineQuest3", 1
		elseif MyLvl >= 900 and MyLvl <= 949 then
			if (IsBoss("Orbitus") and (MyLvl >= 925)) then
				Mon, NameQuest, LevelQuest = "Orbitus", "MarineQuest3", 3
			else
				Mon, NameQuest, LevelQuest = "Marine Captain", "MarineQuest3", 2
			end
		elseif MyLvl >= 950 and MyLvl <= 974 then
			Mon, NameQuest, LevelQuest = "Zombie", "ZombieQuest", 1
		elseif MyLvl >= 975 and MyLvl <= 999 then
			Mon, NameQuest, LevelQuest = "Vampire", "ZombieQuest", 2
		elseif MyLvl >= 1000 and MyLvl <= 1049 then
			Mon, NameQuest, LevelQuest = "Snow Trooper", "SnowMountainQuest", 1
		elseif MyLvl >= 1050 and MyLvl <= 1099 then
			Mon, NameQuest, LevelQuest = "Winter Warrior", "SnowMountainQuest", 2
		elseif MyLvl >= 1100 and MyLvl <= 1124 then
			Mon, NameQuest, LevelQuest = "Lab Subordinate", "IceSideQuest", 1
		elseif MyLvl >= 1125 and MyLvl <= 1174 then
			if (IsBoss("Smoke Admiral") and (MyLvl >= 1150)) then
				Mon, NameQuest, LevelQuest = "Smoke Admiral", "IceSideQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Horned Warrior", "IceSideQuest", 2
			end
		elseif MyLvl >= 1175 and MyLvl <= 1199 then
			Mon, NameQuest, LevelQuest = "Magma Ninja", "FireSideQuest", 1
		elseif MyLvl >= 1200 and MyLvl <= 1249 then
			Mon, NameQuest, LevelQuest = "Lava Pirate", "FireSideQuest", 2
		elseif MyLvl >= 1250 and MyLvl <= 1274 then
			Mon, NameQuest, LevelQuest = "Ship Deckhand", "ShipQuest1", 1
		elseif MyLvl >= 1275 and MyLvl <= 1299 then
			Mon, NameQuest, LevelQuest = "Ship Engineer", "ShipQuest1", 2
		elseif MyLvl >= 1300 and MyLvl <= 1324 then
			Mon, NameQuest, LevelQuest = "Ship Steward", "ShipQuest2", 1
		elseif MyLvl >= 1325 and MyLvl <= 1349 then
			Mon, NameQuest, LevelQuest = "Ship Officer", "ShipQuest2", 2
		elseif MyLvl >= 1350 and MyLvl <= 1374 then
			Mon, NameQuest, LevelQuest = "Arctic Warrior", "FrostQuest", 1
		elseif MyLvl >= 1375 and MyLvl <= 1424 then
			if (IsBoss("Awakened Ice Admiral") and (MyLvl >= 1400)) then
				Mon, NameQuest, LevelQuest = "Awakened Ice Admiral", "FrostQuest", 3
			else
				Mon, NameQuest, LevelQuest = "Snow Lurker", "FrostQuest", 2
			end
		elseif MyLvl >= 1425 and MyLvl <= 1449 then
			Mon, NameQuest, LevelQuest = "Sea Soldier", "ForgottenQuest", 1
		elseif MyLvl >= 1450 then
		if (IsBoss("Tide Keeper") and (MyLvl >= 1475)) then
			Mon, NameQuest, LevelQuest = "Tide Keeper", "ForgottenQuest", 3
		else
			Mon, NameQuest, LevelQuest = "Water Fighter", "ForgottenQuest", 2
		end
	  end
	elseif Sea_3 then
		if MyLvl >= 1500 and MyLvl <= 1524 then
			Mon, NameQuest, LevelQuest = "Pirate Millionaire", "PiratePortQuest", 1
		elseif MyLvl >= 1525 and MyLvl <= 1574 then
			Mon, NameQuest, LevelQuest = "Pistol Billionaire", "PiratePortQuest", 2
		elseif MyLvl >= 1575 and MyLvl <= 1599 then
			Mon, NameQuest, LevelQuest = "Dragon Crew Warrior", "DragonCrewQuest", 1
		elseif MyLvl >= 1600 and MyLvl <= 1624 then
			Mon, NameQuest, LevelQuest = "Dragon Crew Archer", "DragonCrewQuest", 2
		elseif MyLvl >= 1625 and MyLvl <= 1649 then
			Mon, NameQuest, LevelQuest = "Hydra Enforcer", "VenomCrewQuest", 1
		elseif MyLvl >= 1650 and MyLvl <= 1699 then
			Mon, NameQuest, LevelQuest = "Venomous Assailant", "VenomCrewQuest", 2
		elseif MyLvl >= 1700 and MyLvl <= 1724 then
			Mon, NameQuest, LevelQuest = "Marine Commodore", "MarineTreeIsland", 1
		elseif MyLvl >= 1725 and MyLvl <= 1774 then
			Mon, NameQuest, LevelQuest = "Marine Rear Admiral", "MarineTreeIsland", 2
		elseif MyLvl >= 1775 and MyLvl <= 1799 then
			Mon, NameQuest, LevelQuest = "Fishman Raider", "DeepForestIsland3", 1
		elseif MyLvl >= 1800 and MyLvl <= 1824 then
			Mon, NameQuest, LevelQuest = "Fishman Captain", "DeepForestIsland3", 2
		elseif MyLvl >= 1825 and MyLvl <= 1849 then
			Mon, NameQuest, LevelQuest = "Forest Pirate", "DeepForestIsland", 1
		elseif MyLvl >= 1850 and MyLvl <= 1899 then
			Mon, NameQuest, LevelQuest = "Mythological Pirate", "DeepForestIsland", 2
		elseif MyLvl >= 1900 and MyLvl <= 1924 then
			Mon, NameQuest, LevelQuest = "Jungle Pirate", "DeepForestIsland2", 1
		elseif MyLvl >= 1925 and MyLvl <= 1974 then
			Mon, NameQuest, LevelQuest = "Musketeer Pirate", "DeepForestIsland2", 2
		elseif MyLvl >= 1975 and MyLvl <= 1999 then
			Mon, NameQuest, LevelQuest = "Reborn Skeleton", "HauntedQuest1", 1
		elseif MyLvl >= 2000 and MyLvl <= 2024 then
			Mon, NameQuest, LevelQuest = "Living Zombie", "HauntedQuest1", 2
		elseif MyLvl >= 2025 and MyLvl <= 2049 then
			Mon, NameQuest, LevelQuest = "Demonic Soul", "HauntedQuest2", 1
		elseif MyLvl >= 2050 and MyLvl <= 2074 then
			Mon, NameQuest, LevelQuest = "Posessed Mummy", "HauntedQuest2", 2
		elseif MyLvl >= 2075 and MyLvl <= 2099 then
			Mon, NameQuest, LevelQuest = "Peanut Scout", "NutsIslandQuest", 1
		elseif MyLvl >= 2100 and MyLvl <= 2124 then
			Mon, NameQuest, LevelQuest = "Peanut President", "NutsIslandQuest", 2
		elseif MyLvl >= 2125 and MyLvl <= 2149 then
			Mon, NameQuest, LevelQuest = "Ice Cream Chef", "IceCreamIslandQuest", 1
		elseif MyLvl >= 2150 and MyLvl <= 2199 then
			Mon, NameQuest, LevelQuest = "Ice Cream Commander", "IceCreamIslandQuest", 2
		elseif MyLvl >= 2200 and MyLvl <= 2224 then
			Mon, NameQuest, LevelQuest = "Cookie Crafter", "CakeQuest1", 1
		elseif MyLvl >= 2225 and MyLvl <= 2249 then
			Mon, NameQuest, LevelQuest = "Cake Guard", "CakeQuest1", 2
		elseif MyLvl >= 2250 and MyLvl <= 2274 then
			Mon, NameQuest, LevelQuest = "Baking Staff", "CakeQuest2", 1
		elseif MyLvl >= 2275 and MyLvl <= 2299 then
			Mon, NameQuest, LevelQuest = "Head Baker", "CakeQuest2", 2
		elseif MyLvl >= 2300 and MyLvl <= 2324 then
			Mon, NameQuest, LevelQuest = "Cocoa Warrior", "ChocQuest1", 1
		elseif MyLvl >= 2325 and MyLvl <= 2349 then
			Mon, NameQuest, LevelQuest = "Chocolate Bar Battler", "ChocQuest1", 2
		elseif MyLvl >= 2350 and MyLvl <= 2374 then
			Mon, NameQuest, LevelQuest = "Sweet Thief", "ChocQuest2", 1
		elseif MyLvl >= 2375 and MyLvl <= 2399 then
			Mon, NameQuest, LevelQuest = "Candy Rebel", "ChocQuest2", 2
		elseif MyLvl >= 2400 and MyLvl <= 2424 then
			Mon, NameQuest, LevelQuest = "Candy Pirate", "CandyQuest1", 1
		elseif MyLvl >= 2425 and MyLvl <= 2449 then
			Mon, NameQuest, LevelQuest = "Snow Demon", "CandyQuest1", 2
		elseif MyLvl >= 2450 and MyLvl <= 2474 then
			Mon, NameQuest, LevelQuest = "Isle Outlaw", "TikiQuest1", 1
		elseif MyLvl >= 2475 and MyLvl <= 2499 then
			Mon, NameQuest, LevelQuest = "Island Boy", "TikiQuest1", 2
		elseif MyLvl >= 2500 and MyLvl <= 2524 then
			Mon, NameQuest, LevelQuest = "Sun-kissed Warrior", "TikiQuest2", 1
		elseif MyLvl >= 2525 and MyLvl <= 2550 then
			Mon, NameQuest, LevelQuest = "Isle Champion", "TikiQuest2", 2
		elseif MyLvl >= 2550 and MyLvl <= 2574 then
			Mon, NameQuest, LevelQuest = "Serpent Hunter", "TikiQuest3", 1
		elseif MyLvl >= 2575 and MyLvl <= 2599 then
			Mon, NameQuest, LevelQuest = "Skull Slayer", "TikiQuest3", 2
		elseif MyLvl >= 2600 and MyLvl <= 2624 then
			Mon, NameQuest, LevelQuest = "Reef Bandit", "SubmergedQuest1", 1
		elseif MyLvl >= 2625 and MyLvl <= 2649 then
			Mon, NameQuest, LevelQuest = "Coral Pirate", "SubmergedQuest1", 2
		elseif MyLvl >= 2650 and MyLvl <= 2674 then
			Mon, NameQuest, LevelQuest = "Sea Chanter", "SubmergedQuest2", 1
		elseif MyLvl >= 2675 and MyLvl <= 2699 then
			Mon, NameQuest, LevelQuest = "High Disciple", "SubmergedQuest3", 1
		elseif MyLvl >= 2700 then
			Mon, NameQuest, LevelQuest = "Grand Devotee", "SubmergedQuest3", 2
		end
    end
	return {Mon, NameQuest, LevelQuest, MyLvl}
end
