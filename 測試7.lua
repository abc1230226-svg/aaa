--[[
完整穿牆子彈控制腳本（含UI）
--]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local TweenService = game:GetService("TweenService")

-- 創建UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WallPiercingGUI"
ScreenGui.Parent = game:GetService("CoreGui") -- 在遊戲界面上

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 220, 0, 50)
toggleButton.Position = UDim2.new(0.5, -110, 0.1, 0)
toggleButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Text = "穿牆射擊：關閉"
toggleButton.Parent = ScreenGui

local isEnabled = false

toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        toggleButton.Text = "穿牆射擊：開啟"
    else
        toggleButton.Text = "穿牆射擊：關閉"
    end
end)

-- 旗標控制射擊
local canShoot = true
local shootInterval = 0.2 -- 每次射擊間隔秒數

-- 射擊函數
local function shootRaycast()
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (mouse.Hit.p - origin).Unit * 1000 -- 遠距離
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace}
    params.CollisionGroup = nil -- 不限制碰撞層，穿牆

    local result = workspace:Raycast(origin, direction, params)

    if result then
        -- 創建子彈效果
        local bulletPart = Instance.new("Part")
        bulletPart.Size = Vector3.new(0.2, 0.2, 0.2)
        bulletPart.CFrame = CFrame.new(origin)
        bulletPart.Anchored = true
        bulletPart.BrickColor = BrickColor.new("Bright yellow")
        bulletPart.Material = Enum.Material.Neon
        bulletPart.Parent = workspace

        -- 計算距離與速度
        local distance = (result.Position - origin).magnitude
        local speed = 300 -- 子彈速度（stud/sec）
        local time = distance / speed

        -- 移動子彈到命中點
        local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(bulletPart, tweenInfo, {CFrame= CFrame.new(result.Position)})
        tween:Play()

        -- 1秒後刪除子彈
        Debris:AddItem(bulletPart, time + 0.5)
    end
end

-- 持續監控射擊
RunService.RenderStepped:Connect(function()
    if isEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and canShoot then
        canShoot = false
        shootRaycast()
        -- 控制射擊頻率
        delay(shootInterval, function()
            canShoot = true
        end)
    end
end)
