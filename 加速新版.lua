local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- 建立UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedJumpUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- 速度滑桿
local speedLabel = Instance.new("TextLabel", ScreenGui)
speedLabel.Size = UDim2.new(0, 200, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 10)
speedLabel.Text = "跑速: 16"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.BackgroundColor3 = Color3.new(0,0,0)
speedLabel.TextScaled = true

local speedSlider = Instance.new("Slider", ScreenGui)
speedSlider.Size = UDim2.new(0, 200, 0, 20)
speedSlider.Position = UDim2.new(0, 10, 0, 35)
speedSlider.Min = 16
speedSlider.Max = 100
speedSlider.Value = 16

local function updateSpeedLabel(value)
    speedLabel.Text = "跑速: " .. math.floor(value)
end

speedSlider.Changed:Connect(function()
    updateSpeedLabel(speedSlider.Value)
end)

-- 連跳開關
local jumpToggleButton = Instance.new("TextButton", ScreenGui)
jumpToggleButton.Size = UDim2.new(0, 200, 0, 30)
jumpToggleButton.Position = UDim2.new(0, 10, 0, 70)
jumpToggleButton.Text = "連續跳躍 OFF"
jumpToggleButton.TextColor3 = Color3.new(1,1,1)
jumpToggleButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
jumpToggleButton.BorderSizePixel = 1

local jumpEnabled = false
jumpToggleButton.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    jumpToggleButton.Text = "連續跳躍 " .. (jumpEnabled and "ON" or "OFF")
end)

-- 初始設定
local normalSpeed = 16
local boostedSpeed = speedSlider.Value

-- 監控滑桿變化
speedSlider.Changed:Connect(function()
    boostedSpeed = speedSlider.Value
end)

-- 在每個心跳調整速度
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        -- 根據是否啟用調整跑速
        humanoid.WalkSpeed = boostedSpeed
        -- 如果啟用了連跳，讓角色持續跳
        if jumpEnabled then
            humanoid.Jump = true
        end
    end
end)

-- 按空白鍵實現連跳
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            -- 立即跳躍
            humanoid.Jump = true
        end
    end
end)
