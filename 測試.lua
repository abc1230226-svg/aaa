local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- 創建ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimAssistUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") -- 這裡用PlayerGui

-- 背景框
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 130)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.3

-- 開關按鈕
local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(0, 80, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "開啟"
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.BorderSizePixel = 0

-- 範圍標籤
local rangeLabel = Instance.new("TextLabel", frame)
rangeLabel.Size = UDim2.new(0, 180, 0, 20)
rangeLabel.Position = UDim2.new(0, 10, 0, 50)
rangeLabel.Text = "範圍: 100"
rangeLabel.TextColor3 = Color3.new(1,1,1)
rangeLabel.BackgroundTransparency = 1
rangeLabel.TextSize = 14

-- 範圍滑桿
local rangeSlider = Instance.new("Slider", frame)
rangeSlider.Size = UDim2.new(0, 180, 0, 20)
rangeSlider.Position = UDim2.new(0, 10, 0, 70)
rangeSlider.Min = 10
rangeSlider.Max = 300
rangeSlider.Value = 100

-- 狀態文字
local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(0, 180, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 90)
statusLabel.Text = "狀態: 關閉"
statusLabel.TextColor3 = Color3.new(1,0,0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextSize = 14

-- 變數控制
local enabled = false
local aimRange = 100

-- 按鈕點擊事件
toggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        toggleButton.Text = "關閉"
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        statusLabel.Text = "狀態: 開啟"
        statusLabel.TextColor3 = Color3.new(0,1,0)
    else
        toggleButton.Text = "開啟"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        statusLabel.Text = "狀態: 關閉"
        statusLabel.TextColor3 = Color3.new(1,0,0)
    end
end)

-- 範圍滑桿變動
rangeSlider.Changed:Connect(function()
    aimRange = rangeSlider.Value
    rangeLabel.Text = "範圍: " .. tostring(math.floor(aimRange))
end)

-- 找到ShootEvent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shootEvent = nil
local function findShootEvent()
    for _,obj in ipairs(ReplicatedStorage:GetChildren()) do
        if obj.Name == "ShootEvent" then
            return obj
        end
    end
    return nil
end
shootEvent = findShootEvent()
if not shootEvent then
    warn("沒有找到ShootEvent，請確認名稱")
    return
end
local originalFireServer = shootEvent.FireServer

-- 取得最近敵人頭部位置
local function getClosestEnemyHeadPosition()
    local minDist = math.huge
    local targetPos = nil
    local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end

    for _,enemy in ipairs(Players:GetPlayers()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            if enemy ~= LocalPlayer then
                if enemy.Team ~= LocalPlayer.Team then
                    local humanoid = enemy.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local head = enemy.Character:FindFirstChild("Head")
                        if head then
                            local dist = (head.Position - selfHRP.Position).Magnitude
                            if dist <= aimRange and dist < minDist then
                                minDist = dist
                                targetPos = head.Position
                            end
                        end
                    end
                end
            end
        end
    end
    return targetPos
end

-- 攔截FireServer
RunService.RenderStepped:Connect(function()
    if enabled and shootEvent and originalFireServer then
        shootEvent.FireServer = function(self, ...)
            local args = {...}
            local targetHeadPos = getClosestEnemyHeadPosition()
            if targetHeadPos then
                args[1] = targetHeadPos
            end
            return originalFireServer(self, unpack(args))
        end
    else
        -- 恢復原始
        if shootEvent and originalFireServer then
            shootEvent.FireServer = originalFireServer
        end
    end
end)
