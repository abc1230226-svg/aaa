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
local espBoxes = {}

-- 創建紅框函數（用Drawing）
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

-- 透視（全身紅框）與敵人位置框
RunService.RenderStepped:Connect(function()
    -- 更新敵人紅框
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                if espToggle then
                    if not espBoxes[v] then
                        espBoxes[v] = createESPBox()
                        espBoxes[v].Parent = nil -- 不用設parent，直接用Drawing
                    end
                    local box = espBoxes[v]
                    
                    -- 計算模型的AABB（包圍盒）
                    local parts = {}
                    for _, p in pairs(v:GetChildren()) do
                        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                            table.insert(parts, p)
                        end
                    end
                    if #parts > 0 then
                        local minX, minY, minZ = math.huge, math.huge, math.huge
                        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
                        for _, part in pairs(parts) do
                            local cf = part.CFrame
                            local size = part.Size
                            local corners = {
                                cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                                cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                                cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                                cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                                cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                            }
                            for _, corner in pairs(corners) do
                                local pos = corner.Position
                                minX = math.min(minX, pos.X)
                                minY = math.min(minY, pos.Y)
                                minZ = math.min(minZ, pos.Z)
                                maxX = math.max(maxX, pos.X)
                                maxY = math.max(maxY, pos.Y)
                                maxZ = math.max(maxZ, pos.Z)
                            end
                        end
                        -- 取得包圍盒的8個角
                        local corners3D = {
                            Vector3.new(minX, minY, minZ),
                            Vector3.new(maxX, minY, minZ),
                            Vector3.new(minX, maxY, minZ),
                            Vector3.new(maxX, maxY, minZ),
                            Vector3.new(minX, minY, maxZ),
                            Vector3.new(maxX, minY, maxZ),
                            Vector3.new(minX, maxY, maxZ),
                            Vector3.new(maxX, maxY, maxZ),
                        }
                        -- 轉換成螢幕座標
                        local screenPoints = {}
                        local onScreen = true
                        for _, corner in pairs(corners3D) do
                            local sp, ons = Camera:WorldToScreenPoint(corner)
                            if not ons then
                                onScreen = false
                                break
                            end
                            table.insert(screenPoints, Vector2.new(sp.X, sp.Y))
                        end
                        if onScreen and #screenPoints == 8 then
                            local minX2 = math.huge
                            local minY2 = math.huge
                            local maxX2 = -math.huge
                            local maxY2 = -math.huge
                            for _, p in pairs(screenPoints) do
                                minX2 = math.min(minX2, p.X)
                                minY2 = math.min(minY2, p.Y)
                                maxX2 = math.max(maxX2, p.X)
                                maxY2 = math.max(maxY2, p.Y)
                            end
                            -- 設定矩形框位置大小
                            box.Size = Vector2.new(maxX2 - minX2, maxY2 - minY2)
                            box.Position = Vector2.new(minX2, minY2)
                            box.Visible = true
                        else
                            if box then box.Visible = false end
                        end
                    else
                        if box then box.Visible = false end
                    end
                else
                    if espBoxes[v] then espBoxes[v].Visible = false end
                end
            end
        end
    end
end)

-- 釋放已經不存在的敵人（清理）
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

-- 穿牆功能：修改人物碰撞
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = not wallhackToggle
            end
        end
    end
end)
