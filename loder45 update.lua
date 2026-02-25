-- 這個腳本適用於Delta注入器，請確保在支持Drawing的遊戲環境下運行

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 創建UI界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Aimbot_Wallhack"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 150)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.new(0, 0, 0)
Frame.BackgroundTransparency = 0.3
Frame.BorderSizePixel = 2

local function createButton(text, posY)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 200, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    btn.BorderSizePixel = 1
    return btn
end

local espToggle = false
local aimbotToggle = false
local wallhackToggle = false

local espButton = createButton("ESP (穿牆) OFF", 10)
local aimbotButton = createButton("自瞄 OFF", 50)
local wallhackButton = createButton("穿牆 OFF", 90)

-- 按鈕事件
espButton.MouseButton1Click:Connect(function()
    espToggle = not espToggle
    espButton.Text = "ESP (穿牆) " .. (espToggle and "ON" or "OFF")
end)

aimbotButton.MouseButton1Click:Connect(function()
    aimbotToggle = not aimbotToggle
    aimbotButton.Text = "自瞄 " .. (aimbotToggle and "ON" or "OFF")
end)

wallhackButton.MouseButton1Click:Connect(function()
    wallhackToggle = not wallhackToggle
    wallhackButton.Text = "穿牆 " .. (wallhackToggle and "ON" or "OFF")
end)

-- 創建長條矩形框（用於敵人位置）
local drawingBoxes = {}

local function createESPBox()
    local box = Drawing.new("Square")
    box.Color = Color3.new(1, 0, 0)
    box.Thickness = 2
    box.Transparency = 0.5
    box.Visible = false
    return box
end

-- 獲取最近敵人
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

-- 自瞄功能
RunService.RenderStepped:Connect(function()
    if aimbotToggle then
        local target = getClosestEnemy()
        if target and target:FindFirstChild("Head") then
            local headPos = target.Head.Position
            Camera.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, headPos)
        end
    end
end)

-- 主循環：畫框和清理
RunService.RenderStepped:Connect(function()
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local head = v:FindFirstChild("Head")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local humanoid = v:FindFirstChildOfClass("Humanoid")
            if head and hrp and humanoid and humanoid.Health > 0 then
                if espToggle then
                    if not drawingBoxes[v] then
                        drawingBoxes[v] = createESPBox()
                    end
                    local box = drawingBoxes[v]
                    local headScreenPos, onHead = Camera:WorldToScreenPoint(head.Position)
                    local hrpScreenPos, onHrp = Camera:WorldToScreenPoint(hrp.Position)
                    if onHead and onHrp then
                        local distance = (hrp.Position - Camera.CFrame.Position).magnitude
                        local sizeMultiplier = math.clamp(300 / distance, 0.5, 2)
                        local height = (head.Position - hrp.Position).magnitude * sizeMultiplier * 1.5
                        local width = height * 0.4
                        local centerX = (headScreenPos.X + hrpScreenPos.X) / 2
                        local centerY = (headScreenPos.Y + hrpScreenPos.Y) / 2
                        box.Size = Vector2.new(width, height)
                        box.Position = Vector2.new(centerX - width/2, centerY - height/2)
                        box.Visible = true
                    else
                        if drawingBoxes[v] then
                            drawingBoxes[v].Visible = false
                        end
                    end
                else
                    if drawingBoxes[v] then
                        drawingBoxes[v].Visible = false
                    end
                end
                -- 死亡自動移除框
                if humanoid and humanoid.Health <= 0 then
                    if drawingBoxes[v] then
                        drawingBoxes[v]:Remove()
                        drawingBoxes[v] = nil
                    end
                end
            else
                if drawingBoxes[v] then
                    drawingBoxes[v]:Remove()
                    drawingBoxes[v] = nil
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
                part.CanCollide = not wallhackToggle
            end
        end
    end
end

-- 角色重生監聽
LocalPlayer.CharacterAdded:Connect(function()
    wait(0.2)
    applyWallhack()
end)

-- 初始化
if LocalPlayer.Character then
    delay(0.2, function()
        applyWallhack()
    end)
end

-- 持續應用穿牆
RunService.Heartbeat:Connect(function()
    applyWallhack()
end)
