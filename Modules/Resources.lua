local Fire = {}

local CommF_ = game:GetService("ReplicatedStorage"):WaitForChild("CommF_")

function Fire.RegisterRemote(...)
    return CommF_:InvokeServer(...)
end

return Fire
