-- 服務
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI設定：切換自瞄的按鈕
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "R6AutoAimGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 220, 0, 50)
toggleButton.Position = UDim2.new(0.5, -110, 0.1, 0)
toggleButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Text = "自瞄：關閉"
toggleButton.Parent = ScreenGui

-- 狀態變數
local isAutoAim = false
local canShoot = true
local shootInterval = 0.2 -- 射擊間隔（秒）
local maxAimDistance = 50 -- 最大瞄準距離
local smoothingFactor = 0.1 -- 瞄準平滑程度

-- 按鈕點擊切換
toggleButton.MouseButton1Click:Connect(function()
    isAutoAim = not isAutoAim
    toggleButton.Text = isAutoAim and "自瞄：開啟" or "自瞄：關閉"
end)

-- 瞄準平滑函數
local function smoothLookAt(targetPos, currentCFrame)
    local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
    return currentCFrame:Lerp(targetCFrame, smoothingFactor)
end

-- 找出最接近鼠標的敵人頭部（範圍內）
local function getClosestEnemyHead()
    local closestDistance = math.huge
    local targetHead = nil
    for _, character in pairs(workspace:GetChildren()) do
        if character:FindFirstChild("Head") and character:FindFirstChildOfClass("Humanoid") then
            -- 避免自己
            if character ~= LocalPlayer.Character then
                local head = character:FindFirstChild("Head")
                -- 計算距離
                local distance = (head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                if distance <= maxAimDistance then
                    -- 投影到螢幕上
                    local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        -- 計算螢幕距離
                        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                        if screenDistance < closestDistance then
                            closestDistance = screenDistance
                            targetHead = head
                        end
                    end
                end
            end
        end
    end
    return targetHead
end

-- 射擊子彈（簡單表示）
local function shootAtTarget(targetHead)
    local origin = Camera.CFrame.Position
    local targetPos
    if targetHead then
        targetPos = targetHead.Position
    else
        -- 沒有目標，射向前方遠處
        targetPos = origin + Camera.CFrame.LookVector * 10000
    end

    -- 創建子彈模型
    local bullet = Instance.new("Part")
    bullet.Size = Vector3.new(0.2, 0.2, 0.2)
    bullet.CFrame = CFrame.new(origin)
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.BrickColor = BrickColor.new("Bright red")
    bullet.Material = Enum.Material.Neon
    bullet.Parent = workspace

    -- 朝向目標位置
    bullet.CFrame = CFrame.new(origin, targetPos)

    -- 0.1秒後刪除子彈
    Debris:AddItem(bullet, 0.1)
end

-- 主循環：根據狀態自動瞄準並射擊
RunService.RenderStepped:Connect(function()
    if isAutoAim and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if canShoot then
            canShoot = false
            -- 找出最接近鼠標的敵人頭部
            local targetHead = getClosestEnemyHead()
            if targetHead then
                local origin = Camera.CFrame.Position
                local targetPos = targetHead.Position
                -- 平滑轉向敵人頭部
                Camera.CFrame = smoothLookAt(targetPos, Camera.CFrame)
                -- 模擬射擊
                shootAtTarget(targetHead)
            end
            -- 控制射擊頻率
            delay(shootInterval, function()
                canShoot = true
            end)
        end
    end
end)

-- (可選) 顯示敵人高亮，方便觀察（可註解掉）
--[[
for _, character in pairs(workspace:GetChildren()) do
    if character:FindFirstChild("Head") then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = character.Head
        highlight.FillColor = Color3.new(0, 1, 0)
        highlight.OutlineColor = Color3.new(0, 1, 0)
        highlight.Parent = character:FindFirstChild("Head")
    end
end
]]
