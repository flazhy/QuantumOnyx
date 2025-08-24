local Module = {}

do
    function Module.CheckQuest()
        local MyLevel = game:GetService("Players").LocalPlayer.Data.Level.Value
        local World1, World2, World3 = game.PlaceId == 2753915549, game.PlaceId == 4442272183, game.PlaceId == 7449423635
        local Quest = {"", "", 0}
        function IsBossAlive(name)
            for _, e in ipairs(game.workspace.Enemies:GetChildren()) do
                if e.Name == name and e:FindFirstChildWhichIsA("Humanoid").Health > 0 and e:FindFirstChild("CharacterReady") then
                    return true
                end
            end
        end

        if World1 then
            if ((MyLevel == 1) or (MyLevel <= 9)) then
                Quest = {"Bandit", "BanditQuest1", 1}
            elseif ((MyLevel >= 10) and (MyLevel <= 14)) then
                Quest = {"Monkey", "JungleQuest", 1}
            elseif ((MyLevel >= 15) and (MyLevel < 30)) then
                if IsBossAlive("The Gorilla King") and (MyLevel >= 20) then
                    Quest = {"The Gorilla King", "JungleQuest", 3}
                else
                    Quest = {"Gorilla", "JungleQuest", 2}
                end
            elseif ((MyLevel >= 30) and (MyLevel <= 39)) then
                Quest = {"Pirate", "PirateQuest", 1}
            elseif ((MyLevel >= 40) and (MyLevel <= 59)) then
                Quest = {"Brute", "PirateQuest", 2}
            elseif ((MyLevel >= 60) and (MyLevel <= 99)) then
                Quest = {"Dangerous Pirate", "PirateQuest", 3}
            elseif ((MyLevel >= 100) and (MyLevel < 150)) then
                Quest = {"Monkey King", "JungleQuest", 4}
            elseif ((MyLevel >= 150) and (MyLevel <= 224)) then
                Quest = {"Graveyard Boss", "GraveyardQuest", 1}
            elseif ((MyLevel >= 225) and (MyLevel <= 274)) then
                Quest = {"Giant Spider", "GraveyardQuest", 2}
            elseif ((MyLevel >= 275) and (MyLevel <= 299)) then
                Quest = {"Giant Mummy", "GraveyardQuest", 3}
            elseif ((MyLevel >= 300) and (MyLevel <= 324)) then
                Quest = {"Demon", "DemonQuest", 1}
            elseif ((MyLevel >= 325) and (MyLevel <= 399)) then
                Quest = {"Tanker", "DemonQuest", 2}
            elseif ((MyLevel >= 400) and (MyLevel <= 549)) then
                Quest = {"Ice Admiral", "IceQuest", 1}
            elseif ((MyLevel >= 550) and (MyLevel <= 599)) then
                Quest = {"Water Fighter", "IceQuest", 2}
            elseif ((MyLevel >= 600) and (MyLevel <= 649)) then
                Quest = {"Pirate Dragon", "FountainQuest", 1}
            elseif (MyLevel >= 650) then
                if IsBossAlive("Cyborg") and (MyLevel >= 675) then
                    Quest = {"Cyborg", "FountainQuest", 3}
                else
                    Quest = {"Galley Captain", "FountainQuest", 2}
                end
            end

        elseif World2 then
            if ((MyLevel >= 700) and (MyLevel <= 724)) then
                Quest = {"Rider", "Area1Quest", 1}
            elseif ((MyLevel >= 725) and (MyLevel <= 774)) then
                if IsBossAlive("Diamond") and (MyLevel >= 750) then
                    Quest = {"Diamond", "Area1Quest", 3}
                else
                    Quest = {"Mercenary", "Area1Quest", 2}
                end
            elseif ((MyLevel >= 775) and (MyLevel <= 874)) then
                Quest = {"Dragon", "Area1Quest", 4}
            elseif ((MyLevel >= 875) and (MyLevel <= 899)) then
                Quest = {"Dragon's Son", "Area1Quest", 5}
            elseif ((MyLevel >= 900) and (MyLevel <= 949)) then
                Quest = {"Lava Pirate", "Area2Quest", 1}
            elseif ((MyLevel >= 950) and (MyLevel <= 974)) then
                Quest = {"Lava Titan", "Area2Quest", 2}
            elseif ((MyLevel >= 975) and (MyLevel <= 1099)) then
                Quest = {"Ancient Robot", "Area2Quest", 3}
            elseif ((MyLevel >= 1100) and (MyLevel <= 1199)) then
                Quest = {"Royal Soldier", "Area2Quest", 4}
            elseif ((MyLevel >= 1200) and (MyLevel <= 1249)) then
                Quest = {"Royal Soldier", "Area2Quest", 4}
            elseif (MyLevel >= 1250) then
                if IsBossAlive("Gold Pirate") and (MyLevel >= 1300) then
                    Quest = {"Gold Pirate", "Area2Quest", 5}
                else
                    Quest = {"Royal Soldier", "Area2Quest", 4}
                end
            end

        elseif World3 then
            if ((MyLevel >= 1500) and (MyLevel <= 1524)) then
                Quest = {"Pirate Millionaire", "PiratePortQuest", 1}
            elseif ((MyLevel >= 1525) and (MyLevel <= 1574)) then
                Quest = {"Pistol Billionaire", "PiratePortQuest", 2}
            elseif ((MyLevel >= 1575) and (MyLevel <= 1599)) then
                Quest = {"Dragon", "PiratePortQuest", 3}
            elseif ((MyLevel >= 1600) and (MyLevel <= 1649)) then
                Quest = {"Dragon's Son", "PiratePortQuest", 4}
            elseif ((MyLevel >= 1650) and (MyLevel <= 1699)) then
                Quest = {"Royal Soldier", "PiratePortQuest", 5}
            elseif ((MyLevel >= 1700) and (MyLevel <= 1724)) then
                Quest = {"Ancient Robot", "PiratePortQuest", 6}
            end
        end

        return Quest
    end
end

return Module
