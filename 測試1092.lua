local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

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
    local targetPos = Mouse.Hit.p

    -- Raycast找到敵人位置（忽略所有障礙物）
    local direction = (targetPos - origin).Unit * 10000
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace} -- 不過濾任何東西
    params.CollisionGroup = nil
    params.IgnoreWater = true

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

    -- 瞬間移動子彈到命中位置（模擬穿透）
    bullet.CFrame = CFrame.new(hitPosition)

    -- 0.1秒後刪除子彈
    Debris:AddItem(bullet, 0.1)
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
