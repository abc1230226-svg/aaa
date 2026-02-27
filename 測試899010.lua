-- 完全穿透障礙物的子彈範例

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

-- UI設定
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PierceAimGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 220, 0, 50)
toggleButton.Position = UDim2.new(0.5, -110, 0.1, 0)
toggleButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Text = "子彈穿牆：關閉"
toggleButton.Parent = ScreenGui

local isEnabled = false
local canShoot = true
local shootInterval = 0.2

toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleButton.Text = isEnabled and "子彈穿牆：開啟" or "子彈穿牆：關閉"
end)

local function shoot()
    local origin = workspace.CurrentCamera.CFrame.Position
    local targetPos = mouse.Hit.p

    -- 用Raycast找到敵人頭部位置（忽略障礙物）
    local direction = (targetPos - origin).Unit * 10000 -- 無限長，確保命中
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace}
    params.CollisionGroup = nil
    params.IgnoreWater = true
    -- 不過濾任何物件，讓子彈穿透所有障礙物

    local result = workspace:Raycast(origin, direction, params)
    local hitPosition
    if result and result.Instance then
        -- 命中敵人
        hitPosition = result.Position
    else
        -- 沒有命中，設為遠端點
        hitPosition = origin + direction
    end

    -- 創建子彈
    local bullet = Instance.new("Part")
    bullet.Size = Vector3.new(0.2, 0.2, 0.2)
    bullet.CFrame = CFrame.new(origin)
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.BrickColor = BrickColor.new("Bright yellow")
    bullet.Material = Enum.Material.Neon
    bullet.Parent = workspace

    -- 計算飛行時間
    local distance = (hitPosition - origin).magnitude
    local speed = 300 -- 子彈速度
    local travelTime = distance / speed

    -- 使用Tween移動子彈
    local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(bullet, tweenInfo, {CFrame= CFrame.new(hitPosition)})
    tween:Play()

    -- 移除子彈
    Debris:AddItem(bullet, travelTime + 0.5)
end

-- 持續射擊控制
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
