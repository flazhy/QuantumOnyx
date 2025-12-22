return function(body)
	task.spawn(function()
		while task.wait() do
			  body()
		end
	end)
end
