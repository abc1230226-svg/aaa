	TpButton.Position = UDim2.new(1, -116, 0.5, -16)
	TpButton.BackgroundColor3 = Color3.fromRGB(70, 90, 160)
	TpButton.TextColor3 = Color3.new(1, 1, 1)
	TpButton.TextSize = 13
	TpButton.Font = Enum.Font.SourceSansBold
	TpButton.Text = "旁邊"
	TpButton.Parent = Row
	addCorner(TpButton, 6)

	local FlyButton = Instance.new("TextButton")
	FlyButton.Size = UDim2.new(0, 52, 0, 32)
	FlyButton.Position = UDim2.new(1, -58, 0.5, -16)
	FlyButton.BackgroundColor3 = Color3.fromRGB(90, 120, 70)
	FlyButton.TextColor3 = Color3.new(1, 1, 1)
	FlyButton.TextSize = 13
	FlyButton.Font = Enum.Font.SourceSansBold
	FlyButton.Text = "飛頭"
	FlyButton.Parent = Row
	addCorner(FlyButton, 6)

	MarkButton.MouseButton1Click:Connect(function()
		targetPlayer = player
		createMarker(player)
		StatusLabel.Text = "已標記：" .. player.Name
	end)

	TpButton.MouseButton1Click:Connect(function()
		targetPlayer = player
		createMarker(player)
		teleportBesidePlayer(player)
	end)

	FlyButton.MouseButton1Click:Connect(function()
		targetPlayer = player
		createMarker(player)
		flyAbovePlayer(player)
	end)
end

local function refreshPlayerList()
	clearList()

	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			count += 1
			createPlayerRow(player)
		end
	end

	if count == 0 then
		createEmptyText()
	end
end

ToggleButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible

	if MainFrame.Visible then
		refreshPlayerList()
		StatusLabel.Text = "選擇一個玩家"
	end
end)

CloseButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
end)

RefreshButton.MouseButton1Click:Connect(function()
	refreshPlayerList()
	StatusLabel.Text = "已刷新玩家列表"
end)

Players.PlayerAdded:Connect(function()
	if MainFrame.Visible then
		refreshPlayerList()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if targetPlayer == player then
		targetPlayer = nil
		stopFlying()

		if currentMarker then
			currentMarker:Destroy()
			currentMarker = nil
		end

		StatusLabel.Text = "目標玩家已離開"
	end

	if MainFrame.Visible then
		task.delay(0.1, refreshPlayerList)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		MainFrame.Visible = not MainFrame.Visible

		if MainFrame.Visible then
			refreshPlayerList()
			StatusLabel.Text = "選擇一個玩家"
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if currentMarker and targetPlayer and targetPlayer.Character then
		local head = getHead(targetPlayer)
		local root = getRootPart(targetPlayer)

		if head then
			currentMarker.Adornee = head
		elseif root then
			currentMarker.Adornee = root
		end
	end
end)

refreshPlayerList()
