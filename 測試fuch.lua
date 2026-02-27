local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- UI設定
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "R6HeadshotAimGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 220, 0, 50)
toggleButton.Position = UDim2.new(0.5, -110, 0.1, 0)
toggleButton.BackgroundColor3 = Color3.new(0, 0.5, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Text = "頭部必中：關閉"
toggleButton.Parent = ScreenGui

local isEnabled = false
local canShoot = true
local shootInterval = 0.2

toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleButton.Text = isEnabled and "頭部必中：開啟" or "頭部必中：關閉"
end)

local function shoot()
    local origin = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector * 10000

    -- 射線找到敵人（假設敵人是R6模型）
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {workspace}
    params.CollisionGroup = nil
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)

    local hitPosition
    if result and result.Instance then
        local hitPart = result.Instance
        if hitPart and hitPart.Parent then
            local character = hitPart.Parent
            -- 確保是角色且是R6模型（通常是5個Parts）
            if character:FindFirstChild("Head") then
                local head = character:FindFirstChild("Head")
                hitPosition = head.Position
            else
                -- 若找不到Head，使用命中位置
                hitPosition = result.Position
            end
        else
            hitPosition = origin + direction
        end
    else
        hitPosition = origin + direction
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

    -- 立即移動子彈到頭部位置（模擬擊中）
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
