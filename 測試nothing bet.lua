local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI設定
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

local isAutoAim = false
local canShoot = true
local shootInterval = 0.2

toggleButton.MouseButton1Click:Connect(function()
    isAutoAim = not isAutoAim
    toggleButton.Text = isAutoAim and "自瞄：開啟" or "自瞄：關閉"
end)

local function getClosestEnemy()
    local closestDistance = math.huge
    local closestHead = nil
    for _, character in pairs(workspace:GetChildren()) do
        if character:FindFirstChild("Head") and character:FindFirstChildOfClass("Humanoid") then
            -- 避免自己
            if character ~= LocalPlayer.Character then
                local head = character:FindFirstChild("Head")
                local headPos = head.Position
                local screenPos, onScreen = Camera:WorldToScreenPoint(headPos)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestHead = head
                    end
                end
            end
        end
    end
    return closestHead
end

local function shoot(targetHead)
    local origin = Camera.CFrame.Position
    local targetPos
    if targetHead then
        targetPos = targetHead.Position
    else
        -- 沒找到敵人，就按原來方向
        targetPos = origin + Camera.CFrame.LookVector * 10000
    end

    -- 創建子彈
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

RunService.RenderStepped:Connect(function()
    if isAutoAim and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if canShoot then
            canShoot = false
            -- 找最近的敵人頭部
            local targetHead = getClosestEnemy()
            shoot(targetHead)
            delay(shootInterval, function()
                canShoot = true
            end)
        end
    end
end)
