local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Perspective"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local enemyBoxes = {}

local function createBox()
    local box = Drawing.new("Square")
    box.Color = Color3.new(1, 0, 0)
    box.Thickness = 2
    box.Transparency = 0.5
    box.Visible = false
    return box
end

local wallhackEnabled = false

-- 按鈕UI
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

local wallhackButton = createButton("穿牆 OFF", 10)

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

RunService.RenderStepped:Connect(function()

    -- 透視投影
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local head = v:FindFirstChild("Head")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local humanoid = v:FindFirstChildOfClass("Humanoid")
            if head and hrp and humanoid and humanoid.Health > 0 then
                if true then -- 這裡不再檢查espEnabled
                    if not enemyBoxes[v] then
                        enemyBoxes[v] = createBox()
                    end
                    local box = enemyBoxes[v]
                    local headPos, onHead = Camera:WorldToScreenPoint(head.Position)
                    local hrpPos, onHrp = Camera:WorldToScreenPoint(hrp.Position)
                    if onHead and onHrp then
                        -- 計算距離與大小
                        local distance = (hrp.Position - Camera.CFrame.Position).magnitude
                        local sizeMultiplier = math.clamp(300 / distance, 0.5, 2)
                        local height = (head.Position - hrp.Position).magnitude * sizeMultiplier * 1.5
                        local width = height * 0.4
                        local centerX = (headPos.X + hrpPos.X) / 2
                        local centerY = (headPos.Y + hrpPos.Y) / 2
                        -- 設定矩形
                        box.Size = Vector2.new(width, height)
                        box.Position = Vector2.new(centerX - width/2, centerY - height/2)
                        box.Visible = true
                    else
                        if enemyBoxes[v] then
                            enemyBoxes[v].Visible = false
                        end
                    end
                else
                    if enemyBoxes[v] then
                        enemyBoxes[v].Visible = false
                    end
                end
                -- 死亡自動移除
                if humanoid and humanoid.Health <= 0 then
                    if enemyBoxes[v] then
                        enemyBoxes[v]:Remove()
                        enemyBoxes[v] = nil
                    end
                end
            else
                if enemyBoxes[v] then
                    enemyBoxes[v]:Remove()
                    enemyBoxes[v] = nil
                end
            end
        end
    end
end)

-- 穿牆
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
