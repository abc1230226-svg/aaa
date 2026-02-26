local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Perspective"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

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
            -- 轉向
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
                -- 建立或更新Highlight
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
                    -- 取消Highlight
                    if enemyHighlights[v] then
                        enemyHighlights[v].Enabled = false
                    end
                end
                -- 死亡自動移除
                if humanoid and humanoid.Health <= 0 then
                    if enemyHighlights[v] then
                        enemyHighlights[v]:Destroy()
                        enemyHighlights[v] = nil
                    end
                end
            else
                -- 不在畫面或死掉，移除Highlight
                if enemyHighlights[v] then
                    enemyHighlights[v]:Destroy()
                    enemyHighlights[v] = nil
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
