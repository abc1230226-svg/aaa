-- UI部分
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- 避免重複產生 UI
local oldGui = gui:FindFirstChild("DropRateMod")
if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DropRateMod"
ScreenGui.Parent = gui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 200)
frame.Position = UDim2.new(0.5, -175, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.ZIndex = 1
frame.Parent = ScreenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Text = "掉落率修改器"
title.TextColor3 = Color3.white
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.ZIndex = 2
title.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 50)
btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
btn.Text = "搜尋並設定掉落率為99%"
btn.TextColor3 = Color3.white
btn.TextScaled = true
btn.Font = Enum.Font.SourceSansBold
btn.AutoButtonColor = true
btn.Active = true
btn.ZIndex = 2
btn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 25)
status.Position = UDim2.new(0, 10, 0, 100)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.white
status.Text = "等待操作..."
status.TextScaled = true
status.Font = Enum.Font.SourceSans
status.ZIndex = 2
status.Parent = frame

local testBtn = Instance.new("TextButton")
testBtn.Size = UDim2.new(1, -20, 0, 35)
testBtn.Position = UDim2.new(0, 10, 0, 140)
testBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
testBtn.Text = "測試按鈕是否可用"
testBtn.TextColor3 = Color3.white
testBtn.TextScaled = true
testBtn.Font = Enum.Font.SourceSansBold
testBtn.AutoButtonColor = true
testBtn.Active = true
testBtn.ZIndex = 2
testBtn.Parent = frame

local targetVar -- 用來存找到的變數

-- 自訂搜尋函數
local function searchDropChance()
	if typeof(getgc) ~= "function" then
		warn("這個環境沒有 getgc()")
		return nil
	end

	local gcObjects = getgc(true)

	for i, v in ipairs(gcObjects) do
		if typeof(v) == "number" then
			-- 篩選範圍在0.01到1之間的數字
			if v >= 0.01 and v <= 1 then
				print("可能的掉落率：", v)
				targetVar = v
				return v
			end
		end
	end

	return nil
end

-- 嘗試修改變數
local function modifyDropChance(newChance)
	if typeof(getgc) ~= "function" then
		return false
	end

	for i, v in ipairs(getgc(true)) do
		if v == targetVar then
			print("找到目標變數，預備修改為：", newChance)

			-- 這裡只是示範找到目標
			-- 如果你自己的遊戲有真正的掉落率變數，要在這裡接你的變數
			return true
		end
	end

	return false
end

local function onClick()
	status.Text = "正在搜尋..."
	btn.Text = "搜尋中..."
	btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)

	local found = searchDropChance()

	if found then
		local success = modifyDropChance(0.99)

		if success then
			status.Text = "掉落率已設定為99%"
			btn.Text = "設定成功"
			btn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
		else
			status.Text = "修改失敗，請手動調整"
			btn.Text = "修改失敗"
			btn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
		end
	else
		status.Text = "未找到可能的掉落率變數"
		btn.Text = "搜尋失敗"
		btn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
	end
end

btn.MouseButton1Click:Connect(onClick)

testBtn.MouseButton1Click:Connect(function()
	status.Text = "按鈕可以正常使用"
	testBtn.Text = "測試成功"
	testBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)

	print("測試按鈕被按下")
end)
