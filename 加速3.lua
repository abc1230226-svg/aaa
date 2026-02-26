local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 建立UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Delta_Mods"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- 穿牆與連跳開關
local toggleButton = Instance.new("TextButton", ScreenGui)
toggleButton.Size = UDim2.new(0, 220, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "穿牆 & 連跳 OFF"
toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.BorderSizePixel = 1

local isEnabled = false
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleButton.Text = "穿牆 & 連跳 " .. (isEnabled and "ON" or "OFF")
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

-- 初始化顯示
updateSpeedLabel(currentSpeed)

-- 變數控制
local humanoid = nil
local function getHumanoid()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        return LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- 監控角色變化，設置穿牆
LocalPlayer.CharacterAdded:Connect(function()
    wait(0.2)
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = not isEnabled
            end
        end
    end
end)

if LocalPlayer.Character then
    wait(0.2)
    for _, part in pairs(LocalPlayer.Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not isEnabled
        end
    end
end

-- 持續監控角色的CanCollide
RunService.Heartbeat:Connect(function()
    if not isEnabled then return end
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 無限跳躍
local infiniteJump = false
local jumpButton = Instance.new("TextButton", ScreenGui)
jumpButton.Size = UDim2.new(0, 220, 0, 30)
jumpButton.Position = UDim2.new(0, 10, 0, 110)
jumpButton.Text = "無限跳 OFF"
jumpButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
jumpButton.TextColor3 = Color3.new(1, 1, 1)
jumpButton.BorderSizePixel = 1

jumpButton.MouseButton1Click:Connect(function()
    infiniteJump = not infiniteJump
    jumpButton.Text = "無限跳 " .. (infiniteJump and "ON" or "OFF")
end)

-- 持續自動跳躍
RunService.Heartbeat:Connect(function()
    if isEnabled then
        -- 設定跑速
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = currentSpeed
            if infiniteJump then
                hum.Jump = true
            end
        end
    end
end)

-- 單次跳躍（空白鍵）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        local hum = getHumanoid()
        if hum then
            hum.Jump = true
        end
    end
end)
