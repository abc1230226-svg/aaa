local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedJumpUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- 跑速UI
local speedLabel = Instance.new("TextLabel", ScreenGui)
speedLabel.Size = UDim2.new(0, 200, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 10)
speedLabel.Text = "跑速: 16"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
speedLabel.BorderSizePixel = 1
speedLabel.Active = true

local speedSlider = Instance.new("TextBox", ScreenGui)
speedSlider.Size = UDim2.new(0, 200, 0, 30)
speedSlider.Position = UDim2.new(0, 10, 0, 50)
speedSlider.Text = "16"
speedSlider.TextColor3 = Color3.new(1,1,1)
speedSlider.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
speedSlider.BorderSizePixel = 1

local minSpeed = 16
local maxSpeed = 999
local currentSpeed = 16

speedSlider.FocusLost:Connect(function()
    local val = tonumber(speedSlider.Text)
    if val and val >= minSpeed and val <= maxSpeed then
        currentSpeed = val
        speedLabel.Text = "跑速: " .. val
    else
        speedSlider.Text = tostring(currentSpeed)
    end
end)

-- 無限跳躍按鈕
local jumpButton = Instance.new("TextButton", ScreenGui)
jumpButton.Size = UDim2.new(0, 200, 0, 30)
jumpButton.Position = UDim2.new(0, 10, 0, 90)
jumpButton.Text = "無限跳躍 OFF"
jumpButton.TextColor3 = Color3.new(1,1,1)
jumpButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
jumpButton.BorderSizePixel = 1

-- 可拖動清單
local dragging = false
local dragStart
local startSpeedLabelPos
local startSpeedSliderPos
local startJumpButtonPos

speedLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position

        startSpeedLabelPos = speedLabel.Position
        startSpeedSliderPos = speedSlider.Position
        startJumpButtonPos = jumpButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart

        speedLabel.Position = UDim2.new(
            startSpeedLabelPos.X.Scale,
            startSpeedLabelPos.X.Offset + delta.X,
            startSpeedLabelPos.Y.Scale,
            startSpeedLabelPos.Y.Offset + delta.Y
        )

        speedSlider.Position = UDim2.new(
            startSpeedSliderPos.X.Scale,
            startSpeedSliderPos.X.Offset + delta.X,
            startSpeedSliderPos.Y.Scale,
            startSpeedSliderPos.Y.Offset + delta.Y
        )

        jumpButton.Position = UDim2.new(
            startJumpButtonPos.X.Scale,
            startJumpButtonPos.X.Offset + delta.X,
            startJumpButtonPos.Y.Scale,
            startJumpButtonPos.Y.Offset + delta.Y
        )
    end
end)

local infiniteJump = false
jumpButton.MouseButton1Click:Connect(function()
    infiniteJump = not infiniteJump
    jumpButton.Text = "無限跳躍 " .. (infiniteJump and "ON" or "OFF")
end)

-- 設定角色跑速
RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
    end
end)

-- 無限跳躍實現
UserInputService.JumpRequest:Connect(function()
    if infiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
