local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local shooting = false
local shootInterval = 0.2 -- 控制射擊速度

local function shoot()
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (mouse.Hit.p - origin).Unit * 5000 -- 避免被阻擋，設定很長的距離
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace}
    params.CollisionGroup = nil -- 不限制碰撞，讓子彈穿牆

    local result = workspace:Raycast(origin, direction, params)
    if result then
        local hitPosition = result.Position

        -- 創建子彈
        local bullet = Instance.new("Part")
        bullet.Size = Vector3.new(0.2, 0.2, 0.2)
        bullet.CFrame = CFrame.new(origin)
        bullet.Anchored = true
        bullet.CanCollide = false -- 不碰撞牆壁
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
end

RunService.RenderStepped:Connect(function()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if not shooting then
            shooting = true
            shoot()
            wait(shootInterval)
            shooting = false
        end
    end
end)
