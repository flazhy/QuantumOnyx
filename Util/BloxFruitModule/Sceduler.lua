local TaskController = {}

local CurrentThread = nil
local CurrentKey = nil

function TaskController.Run(key, fn)
    if CurrentThread then
        task.cancel(CurrentThread)
        CurrentThread = nil
    end
    CurrentKey = key
    CurrentThread = task.spawn(function()
        while CurrentKey == key do
            local ok, err = pcall(fn)
            if not ok then
                warn("Task error:", key, err)
            end
            task.wait()
        end
    end)
end
function TaskController.Stop()
    if CurrentThread then
        task.cancel(CurrentThread)
        CurrentThread = nil
    end
    CurrentKey = nil
end
return TaskController
