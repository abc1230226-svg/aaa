-- 客戶端腳本（用於Delta注入器）
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 創建UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Aimbot_Wallhack"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.Enabled = true

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

local espToggle = false -- 控制是否顯示紅框
local aimbotToggle = false -- 控制是否自瞄
local wallhackToggle = false -- 控制穿牆

local espButton = createButton("ESP (穿牆) OFF", 10)
local aimbotButton = createButton("自瞄 OFF", 50)
local wallhackButton = createButton("穿牆 OFF", 90)

-- UI按鈕事件
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

-- 變數
local targetEnemy = nil
local espBoxes = {}

-- 創建紅色長條框，覆蓋整個敵人身體
local function createESPBox()
    local box = Drawing.new("Square")
    box.Color = Color3.new(1, 0, 0)
    box.Thickness = 2
    box.Transparency = 0.5
    box.Visible = false
    return box
end

-- 找最近的敵人（只找頭部）
local function getClosestEnemy()
    local minDist = math.huge
    local closest = nil
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local head = v:FindFirstChild("Head")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local humanoid = v:FindFirstChildOfClass("Humanoid")
            if head and hrp then
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

-- 自瞄：每幀轉向最近敵人頭部
RunService.RenderStepped:Connect(function()
    if aimbotToggle then
        local target = getClosestEnemy()
        if target and target:FindFirstChild("Head") then
            local headPos = target.Head.Position
            -- 轉向鏡頭
            Camera.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, headPos)
        end
    end
end)

-- 透視（紅框）與敵人位置框
RunService.RenderStepped:Connect(function()
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local head = v:FindFirstChild("Head")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            local humanoid = v:FindFirstChildOfClass("Humanoid")
            if head and hrp then
                if espToggle then
                    if not espBoxes[v] then
                        espBoxes[v] = createESPBox()
                        espBoxes[v].Parent = nil
                    end
                    local box = espBoxes[v]
                    local headPos, onHead = Camera:WorldToScreenPoint(head.Position)
                    local hrpPos, onHrp = Camera:WorldToScreenPoint(hrp.Position)
                    if onHead and onHrp then
                        -- 只畫覆蓋整個身體的長條
                        local distance = (hrp.Position - Camera.CFrame.Position).magnitude
                        local sizeMultiplier = math.clamp(300 / distance, 0.5, 2)
                        local boxHeight =  (head.Position - hrp.Position).magnitude * sizeMultiplier
                        local boxWidth = boxHeight * 0.4 -- 比例
                        -- 計算中心點（頭到腳的中點）
                        local centerX = (headPos.X + hrpPos.X) / 2
                        local centerY = (headPos.Y + hrpPos.Y) / 2
                        -- 設定框大小
                        box.Size = Vector2.new(boxWidth, boxHeight)
                        -- 設定框位置
                        box.Position = Vector2.new(centerX - boxWidth/2, centerY - boxHeight/2)
                        box.Visible = true
                    else
                        if espBoxes[v] then espBoxes[v].Visible = false end
                    end
                else
                    if espBoxes[v] then espBoxes[v].Visible = false end
                end
                -- 如果敵人死亡，刪除框
                if humanoid and humanoid.Health <= 0 then
                    if espBoxes[v] then
                        espBoxes[v]:Remove()
                        espBoxes[v] = nil
                    end
                end
            end
        end
    end
end)

-- 釋放已不存在的敵人（清理）
RunService.Heartbeat:Connect(function()
    for v, box in pairs(espBoxes) do
        if not v.Parent then
            if box then
                box:Remove()
                espBoxes[v] = nil
            end
        end
    end
end)

-- 穿牆功能：修改人物碰撞與透明度（此處不改變自己角色透明）
local function setCharacterCollision(enabled)
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = enabled
            end
        end
    end
end

local function setCharacterTransparency(transparency)
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = transparency
            end
        end
    end
end

local function applyWallhack()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        -- 讓自己穿牆
        setCharacterCollision(not wallhackToggle)
        -- 不改變自己的透明度（保持透明度）
        -- 你可以選擇不要改變透明度或保持原狀
    end
end

-- 角色重生監聽
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(0.1)
    applyWallhack()
end)

if LocalPlayer.Character then
    delay(0.1, function()
        applyWallhack()
    end)
end

RunService.Heartbeat:Connect(function()
    applyWallhack()
end)
