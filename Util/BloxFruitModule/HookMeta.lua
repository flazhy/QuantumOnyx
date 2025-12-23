return function()
    local Container = game.ReplicatedStorage.Effect.Container
  	local CameraShaker = require(ReplicatedStorage.Util.CameraShaker)
  	local Death = require(Container:FindFirstChild("Death"))
  	local Respawn = require(Container:FindFirstChild("Respawn"))
  	local LevelUp = require(Container:FindFirstChild("LevelUp"))
  	local DisplayNPC = require(ReplicatedStorage:FindFirstChild("GuideModule")).ChangeDisplayedNPC
  
  	hookfunction(Death, function() end)
  	hookfunction(LevelUp, function() end)
  	hookfunction(Respawn, function() end)
  	hookfunction(DisplayNPC, function() end)
  	CameraShaker:Stop()
end
