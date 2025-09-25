------------------------------ INITIALISE ------------------------------

local treeStats
local treeStats = {
	["baisic"] = 60,
	["birch"] = 120,
	["cactus"] = 90,
	["jungle"] = 600, -- create new global treestats for tree types
	["pine"] = 450,
	["snow"] = 220
}

local function attemptSave(plr, trees) -- handler for trying to save trees (incase pcall is required)
	for _, v in ipairs(workspace.Plots:GetChildren()) do
		if v.owner.Value == plr then
			for _, zone in pairs(v.PlantZones:GetChildren()) do
				local model = zone:FindFirstChildOfClass("Model")
				if model then
					table.insert(trees, {
						name = model.Name,
						grown = model:FindFirstChild("grown") and model.grown.Value or false,
						golden = model:FindFirstChild("golden") and model.golden.Value or false,
						cost = model:FindFirstChild("cost") and model.cost.Value or 400,
						growth = model:FindFirstChild("growth") and model.growth.Value or 0.05,
						treeType = model:FindFirstChild("type") and model.type.Value or "baisic",
						growthSize = model:FindFirstChild("growthSize") and model.growthSize.Value or 1
					})
				end
			end
		end
	end
	return trees
end

local function continueGrowth(growth, tree, maxGrowth, time) -- resumes growth of the given tree
	task.spawn(function() -- I wrapped it in task.spawn() just in case it yeilds (it wont now that I look at it bc its lamba so fuck me ig)
		time -= time * growth
		local nv = tree:FindFirstChild("growth")
		if not nv then
			nv = Instance.new("NumberValue")
			nv.Name = "growth"
			nv.Value = growth
			nv.Parent = tree
		end

		local growTween = game:GetService("TweenService"):Create( -- create tween
			nv,
			TweenInfo.new(time, Enum.EasingStyle.Linear),
			{Value = maxGrowth}
		)
		growTween:Play()

		local running = true
		local conn
		conn = nv.Changed:Connect(function(newVal) -- detect when number value changes from tween so as to not use runservice
			if not running then return end
			tree:ScaleTo(newVal)
			local soilAttachment = tree.Parent.Attachment
			local baseAttachment = tree.Attachment

			if soilAttachment and baseAttachment then
				local soilPos = soilAttachment.WorldPosition
				local basePos = baseAttachment.WorldPosition
				local diff = soilPos - basePos
				local pivot = tree:GetPivot()
				tree:PivotTo(CFrame.new(pivot.Position + diff) * (pivot - pivot.Position))
			end
		end)

		growTween.Completed:Connect(function(_) -- creates a highlight for the tree to indicate its finished
			running = false
			if conn then conn:Disconnect() end
			tree.grown.Value = true

			local hl = Instance.new("Highlight")
			hl.Parent = tree
			hl.Adornee = tree
			hl.FillTransparency = 0
			hl.OutlineTransparency = 0
			hl.FillColor = Color3.new(1, 1, 1)
			hl.OutlineColor = Color3.new(1, 1, 1)
			game:GetService("TweenService"):Create(hl, TweenInfo.new(5, Enum.EasingStyle.Linear), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
		end)
	end)
end

------------------------------ LOAD TREES/ TOOLS ------------------------------

game.Players.PlayerAdded:Connect(function(plr) -- the name speaks for itself, but when a player joins it loads their datastore
	
	---------- LOAD TREES ----------
	
	local TDS = game:GetService("DataStoreService"):GetDataStore("trees")

	local trees
	local success, result = pcall(function() -- pcall tests to make sure it worked
		return TDS:GetAsync(plr.UserId)
	end)

	if success and result then
		trees = result
	else
		print("err:",result)
		trees = {}
	end

	local plot
	task.wait(1) -- I still think that it's funny how instead of loading it just makes you wait a bit, it's smart really
	for _, v in pairs(workspace.Plots:GetChildren()) do
		if v.owner.Value == plr then
			plot = v
			break
		end
	end

	if plot then
		for i, zone in ipairs(plot.PlantZones:GetChildren()) do -- iterates trhough the plant zones
			if not trees[i] then return end

			local plantName = trees[i]["name"] -- initalsiation
			local plant = game.ReplicatedStorage.Plants:FindFirstChild(plantName)

			if plant then
				local clone = plant:Clone()
				clone.Parent = zone
				clone.Parent.occupied.Value = true

				if trees[i]["golden"] then -- makes golden golden
					for _,v in pairs(clone:GetDescendants()) do
						if v:IsA("BasePart") then
							v.BrickColor = BrickColor.new("Gold")
						end
					end
				end

				clone.grown.Value = trees[i]["grown"] -- i hate this part it costed me multiple days of my life
				clone.cost.Value = trees[i]["cost"]

				local treeType = Instance.new("StringValue") -- this was only in some trees
				treeType.Parent = clone
				treeType.Name = "type"
				treeType.Value = trees[i]["treeType"]

				local growth = Instance.new("NumberValue") -- this is only in freshly planted trees
				growth.Parent = clone
				growth.Name = "growth"
				growth.Value = trees[i]["growth"]

				local golden = Instance.new("BoolValue") -- idek why I added this
				golden.Parent = clone
				golden.Name = "golden"
				golden.Value = trees[i]["golden"]

				local growthSize = Instance.new("NumberValue") -- same here, guess it was causing issues question mark
				growthSize.Parent = clone
				growthSize.Name = "growthSize"
				growthSize.Value = trees[i]["growthSize"]

				clone:ScaleTo(trees[i]["growth"]) -- changes size/ pivot
				local treeType = trees[i]["treeType"]
				clone:ScaleTo(trees[i]["growth"])
				local soilAttachment = clone.Parent.Attachment
				local baseAttachment = clone.Attachment

				if soilAttachment and baseAttachment then -- I used to love spacial geometry. used to
					local soilPos = soilAttachment.WorldPosition
					local basePos = baseAttachment.WorldPosition
					local diff = soilPos - basePos
					local pivot = clone:GetPivot()
					clone:PivotTo(CFrame.new(pivot.Position + diff) * (pivot - pivot.Position))
				end
				
				if not trees[i]["grown"] then -- yeah continues growth
					continueGrowth(trees[i]["growth"], clone, trees[i]["growthSize"], treeStats[trees[i]["treeType"]])
				end
			end
		end
	end
	
	---------- LOAD TOOLS ----------
	
	local ToolDS = game:GetService("DataStoreService"):GetDataStore("tools")
	
	local tools = {}
	local success, result = pcall(function() -- pcall tests to make sure it worked
		return ToolDS:GetAsync(plr.UserId)
	end)

	if success and result then
		tools = result
	elseif not result then
		warn("no result :sob:")
	elseif not success then
		warn("err:",result)
	end
	
	for i,v in ipairs(tools) do
		game.ReplicatedStorage.Seeds:FindFirstChild(v):Clone().Parent = plr.Backpack
	end
end)

------------------------------ SAVE TREES/ TOOLS ------------------------------

game.Players.PlayerRemoving:Connect(function(plr) -- I really thought this would be the hard part...
	
	---------- SAVE TOOLS ----------
	
	local ToolDS = game:GetService("DataStoreService"):GetDataStore("tools") -- tool datastore
	local tools = {}
	
	for _,v in ipairs(plr.Backpack:GetChildren()) do
		if v.Name ~= "axe" then
			table.insert(tools, v.Name)
		end
	end
	print(tools)
	-- yeah
	local success, err = pcall(function()
		ToolDS:SetAsync(plr.UserId, tools)
	end)
	
	for i=1, 5 do -- retry saving
		local success, err = pcall(function()
			attemptSave(plr.UserId, tools)
			ToolDS:SetAsync(plr.UserId, tools)
		end)

		if success then break
		elseif not success then
			warn("error:",err)
		end
		
		task.wait(1)
	end
	
	---------- SAVE TREES ----------
	
	local TDS = game:GetService("DataStoreService"):GetDataStore("trees")
	local trees = {}

	attemptSave(plr, trees)
	local success, err = pcall(function() -- makes sure it sets
		TDS:SetAsync(plr.UserId, trees)
	end)
	
	if not success then
		warn("error:",err)
	end
	
	for i=1, 5 do -- yeah also
		local success, err = pcall(function()
			attemptSave(plr, trees)
			TDS:SetAsync(plr.UserId, trees)
			print(trees)
		end)
		
		if success then break
		elseif not success then
			warn(err)
		end
	end
end)
