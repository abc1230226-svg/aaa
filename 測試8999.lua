-- 穿牆無視障礙物直接命中敵人頭部
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

-- 創建UI用來開關
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoObstacleAimGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 220, 0, 50)
toggleButton.Position = UDim2.new(0.5, -110, 0.1, 0)
toggleButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Text = "開火無視障礙：關閉"
toggleButton.Parent = ScreenGui

local isEnabled = false
local canShoot = true
local shootInterval = 0.2 -- 射擊間隔

toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        toggleButton.Text = "開火無視障礙：開啟"
    else
        toggleButton.Text = "開火無視障礙：關閉"
    end
end)

local function shoot()
    local origin = workspace.CurrentCamera.CFrame.Position
    local targetPos = mouse.Hit.p
    local direction = (targetPos - origin).Unit * 5000 -- 長距離射線
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace}
    params.CollisionGroup = nil -- 不限制碰撞，子彈穿牆

    local result = workspace:Raycast(origin, direction, params)
    local hitPosition
    if result then
        hitPosition = result.Position
    else
        hitPosition = origin + direction
    end

    -- 創建子彈
    local bullet = Instance.new("Part")
    bullet.Size = Vector3.new(0.2, 0.2, 0.2)
    bullet.CFrame = CFrame.new(origin)
    bullet.Anchored = true
    bullet.CanCollide = false -- 不碰撞任何東西
    bullet.BrickColor = BrickColor.new("Bright yellow")
    bullet.Material = Enum.Material.Neon
    bullet.Parent = workspace

    -- 移動子彈到命中位置
    local distance = (hitPosition - origin).magnitude
    local speed = 300 -- 子彈速度
    local time = distance / speed

    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(bullet, tweenInfo, {CFrame= CFrame.new(hitPosition)})
    tween:Play()

    Debris:AddItem(bullet, time + 0.5)
end

RunService.RenderStepped:Connect(function()
    if isEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if canShoot then
            canShoot = false
            shoot()
            delay(shootInterval, function()
                canShoot = true
            end)
        end
    end
end)
