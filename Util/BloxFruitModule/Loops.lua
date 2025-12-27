return function(main)
	task.spawn(function()
		while wait() do
			main()
		end
	end)
end
