local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 建立UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Delta_Features"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- 穿牆 & 連跳開關按鈕
local toggleButton = Instance.new("TextButton", ScreenGui)
toggleButton.Size = UDim2.new(0, 220, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "穿牆 & 連跳 OFF"
toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
local enabled = false
toggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleButton.Text = "穿牆 & 連跳 " .. (enabled and "ON" or "OFF")
end)

-- 跑速滑桿
local speedLabel = Instance.new("TextLabel", ScreenGui)
speedLabel.Size = UDim2.new(0, 220, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 50)
speedLabel.Text = "跑速: 16"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.BackgroundColor3 = Color3.new(0,0,0)
speedLabel.TextScaled = true

local speedSlider = Instance.new("Slider", ScreenGui)
speedSlider.Size = UDim2.new(0, 220, 0, 20)
speedSlider.Position = UDim2.new(0, 10, 0, 75)
speedSlider.Min = 16
speedSlider.Max = 100
speedSlider.Value = 16

local currentSpeed = 16
local function updateSpeedLabel(val)
    speedLabel.Text = "跑速: " .. math.floor(val)
end
speedSlider.Changed:Connect(function()
    currentSpeed = speedSlider.Value
    updateSpeedLabel(currentSpeed)
end)
updateSpeedLabel(currentSpeed)

-- 無限跳躍按鈕
local jumpToggleButton = Instance.new("TextButton", ScreenGui)
jumpToggleButton.Size = UDim2.new(0, 220, 0, 30)
jumpToggleButton.Position = UDim2.new(0, 10, 0, 110)
jumpToggleButton.Text = "無限跳 OFF"
jumpToggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
jumpToggleButton.TextColor3 = Color3.new(1, 1, 1)
local infiniteJump = false
jumpToggleButton.MouseButton1Click:Connect(function()
    infiniteJump = not infiniteJump
    jumpToggleButton.Text = "無限跳 " .. (infiniteJump and "ON" or "OFF")
end)

-- 持續執行
RunService.Heartbeat:Connect(function()
    if not enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- 取得Humanoid
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- 設置跑速
    humanoid.WalkSpeed = currentSpeed
    
    -- 穿牆功能：設定所有BasePart的CanCollide為false
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    -- 連跳
    if infiniteJump then
        humanoid.Jump = true
    end
end)

-- 單次跳躍（空白鍵）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Jump = true
        end
    end
end)
