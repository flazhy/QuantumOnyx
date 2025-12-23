return function(main)
	task.spawn(function()
		while task.wait() do
			main()
		end
	end)
end
