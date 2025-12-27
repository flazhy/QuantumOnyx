return function(main)
	spawn(function()
		while task.wait() do
			main()
		end
	end)
end
