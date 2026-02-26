local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- 建立UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Perspective"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- 既有UI元素（你的原始）
local enemyHighlights = {} -- 儲存敵人Highlight

local function createButton(text, posY)
    local btn = Instance.new("TextButton", ScreenGui)
    btn.Size = UDim2.new(0, 200, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    btn.BorderSizePixel = 1
    return btn
end

local espButton = createButton("ESP (遠近透視) OFF", 10)
local aimbotButton = createButton("人物轉向敵人 OFF", 50)
local wallhackButton = createButton("穿牆 OFF", 90)

local espEnabled = false
local aimbotEnabled = false
local wallhackEnabled = false

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = "ESP (遠近透視) " .. (espEnabled and "ON" or "OFF")
end)

aimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotButton.Text = "人物轉向敵人 " .. (aimbotEnabled and "ON" or "OFF")
end)

wallhackButton.MouseButton1Click:Connect(function()
    wallhackEnabled = not wallhackEnabled
    wallhackButton.Text = "穿牆 " .. (wallhackEnabled and "ON" or "OFF")
end)

local function getClosestEnemy()
    local minDist = math.huge
    local closest = nil
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local head = v:FindFirstChild("Head")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local humanoid = v:FindFirstChildOfClass("Humanoid")
            if head and hrp and humanoid and humanoid.Health > 0 then
                local dist = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).magnitude
                if dist < minDist then
                    minDist = dist
                    closest = v
                end
            end
        end
    end
    return closest
end

-- 自瞄：轉向敵人
RunService.RenderStepped:Connect(function()
    -- 自瞄
    if aimbotEnabled then
        local target = getClosestEnemy()
        if target and target:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = target.HumanoidRootPart
            local localHRP = LocalPlayer.Character.HumanoidRootPart
            local direction = (targetHRP.Position - localHRP.Position).unit
            local lookAtCFrame = CFrame.new(localHRP.Position, localHRP.Position + direction)
            localHRP.CFrame = lookAtCFrame
        end
    end

    -- 透視（紅框）套在敵人身上
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local humanoid = v:FindFirstChildOfClass("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp and humanoid.Health > 0 then
                if espEnabled then
                    if not enemyHighlights[v] then
                        local hl = Instance.new("Highlight")
                        hl.Name = "EnemyHighlight"
                        hl.Parent = v
                        hl.Adornee = v
                        hl.FillColor = Color3.new(1, 0, 0)
                        hl.OutlineColor = Color3.new(1, 0, 0)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        enemyHighlights[v] = hl
                    else
                        enemyHighlights[v].Enabled = true
                    end
                else
                    if enemyHighlights[v] then
                        enemyHighlights[v].Enabled = false
                    end
                end
                if humanoid and humanoid.Health <= 0 then
                    if enemyHighlights[v] then
                        enemyHighlights[v]:Destroy()
                        enemyHighlights[v] = nil
                    end
                end
            else
                if enemyHighlights[v] then
                    enemyHighlights[v]:Destroy()
                    enemyHighlights[v] = nil
                end
            end
        end
    end
end)

-- 穿牆功能
local function applyWallhack()
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = not wallhackEnabled
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    wait(0.2)
    applyWallhack()
end)

if LocalPlayer.Character then
    delay(0.2, function()
        applyWallhack()
    end)
end

RunService.Heartbeat:Connect(function()
    applyWallhack()
end)

-- ==== 新增：跑速與連跳功能 ====

-- UI：跑速滑桿與連跳按鈕
local speedLabel = Instance.new("TextLabel", ScreenGui)
speedLabel.Size = UDim2.new(0, 200, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 130)
speedLabel.Text = "跑速: 16"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.BackgroundColor3 = Color3.new(0,0,0)
speedLabel.TextScaled = true

local speedSlider = Instance.new("Slider", ScreenGui)
speedSlider.Size = UDim2.new(0, 200, 0, 20)
speedSlider.Position = UDim2.new(0, 10, 0, 155)
speedSlider.Min = 16
speedSlider.Max = 100
speedSlider.Value = 16

local function updateSpeedLabel(value)
    speedLabel.Text = "跑速: " .. math.floor(value)
end
speedSlider.Changed:Connect(function()
    updateSpeedLabel(speedSlider.Value)
end)

local jumpToggleButton = Instance.new("TextButton", ScreenGui)
jumpToggleButton.Size = UDim2.new(0, 200, 0, 30)
jumpToggleButton.Position = UDim2.new(0, 10, 0, 185)
jumpToggleButton.Text = "連續跳躍 OFF"
jumpToggleButton.TextColor3 = Color3.new(1,1,1)
jumpToggleButton.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
jumpToggleButton.BorderSizePixel = 1

local jumpEnabled = false
jumpToggleButton.MouseButton1Click:Connect(function()
    jumpEnabled = not jumpEnabled
    jumpToggleButton.Text = "連續跳躍 " .. (jumpEnabled and "ON" or "OFF")
end)

-- 變數：跑速
local currentSpeed = speedSlider.Value

-- 更新跑速
speedSlider.Changed:Connect(function()
    currentSpeed = speedSlider.Value
end)

-- 自動調整速度與連跳
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        -- 設定跑速
        humanoid.WalkSpeed = currentSpeed
        -- 如果啟用連跳，自動跳
        if jumpEnabled then
            humanoid.Jump = true
        end
    end
end)

-- 按空白鍵：實現單次跳躍
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            humanoid.Jump = true
        end
    end
end)
