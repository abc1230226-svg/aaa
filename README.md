local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local localPlayer = players.LocalPlayer
local isLocking = false
local lockedTarget = nil
local lockKey = Enum.KeyCode.E

local espData = {}

-- 创建自瞄菜单UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotMenu"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 150)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = ScreenGui

local toggleBoxButton = Instance.new("TextButton")
toggleBoxButton.Size = UDim2.new(1, -20, 0, 30)
toggleBoxButton.Position = UDim2.new(0, 10, 0, 10)
toggleBoxButton.Text = "启用方框"
toggleBoxButton.Parent = frame

local showHealthCheckbox = Instance.new("TextButton")
showHealthCheckbox.Size = UDim2.new(1, -20, 0, 30)
showHealthCheckbox.Position = UDim2.new(0, 10, 0, 50)
showHealthCheckbox.Text = "显示血量：关闭"
showHealthCheckbox.Parent = frame

local bulletTrackButton = Instance.new("TextButton")
bulletTrackButton.Size = UDim2.new(1, -20, 0, 30)
bulletTrackButton.Position = UDim2.new(0, 10, 0, 90)
bulletTrackButton.Text = "子弹追踪：关闭"
bulletTrackButton.Parent = frame

-- 控制变量
local enableBox = false
local showHealth = false
local enableBulletTrack = false

toggleBoxButton.MouseButton1Click:Connect(function()
    enableBox = not enableBox
    toggleBoxButton.Text = enableBox and "禁用方框" or "启用方框"
end)

showHealthCheckbox.MouseButton1Click:Connect(function()
    showHealth = not showHealth
    showHealthCheckbox.Text = "显示血量：" .. (showHealth and "开启" or "关闭")
end)

bulletTrackButton.MouseButton1Click:Connect(function()
    enableBulletTrack = not enableBulletTrack
    bulletTrackButton.Text = "子弹追踪：" .. (enableBulletTrack and "开启" or "关闭")
end)

local function get_players()
    local entities = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child:FindFirstChildOfClass("Humanoid") then
            table.insert(entities, child)
        elseif child.Name == "HurtEffect" then
            for _, hurt_player in ipairs(child:GetChildren()) do
                if hurt_player.ClassName ~= "Highlight" then
                    table.insert(entities, hurt_player)
                end
            end
        end
    end
    return entities
end

local function get_closest_player()
    local closest, closestDist = nil, math.huge
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    for _, player in ipairs(get_players()) do
        if player == localPlayer then continue end
        if not player:FindFirstChild("HumanoidRootPart") then continue end
        local position, onScreen = camera:WorldToViewportPoint(player.HumanoidRootPart.Position)
        if not onScreen then continue end
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local dist = (center - Vector2.new(position.X, position.Y)).Magnitude
        if dist < closestDist then
            closestDist = dist
            closest = player
        end
    end
    return closest
end

local function createESP(player)
    local adornment = Instance.new("BoxHandleAdornment")
    adornment.Adornee = player.Character and player.Character:FindFirstChild("Head")
    adornment.Size = Vector3.new(2, 2, 2)
    adornment.Color3 = Color3.new(1, 0, 0)
    adornment.Transparency = 0.5
    adornment.ZIndex = 10
    adornment.AlwaysOnTop = true
    adornment.Parent = workspace

  local healthGui = nil
    if showHealth then
        healthGui = Instance.new("BillboardGui")
        healthGui.Size = UDim2.new(4, 0, 1, 0)
        healthGui.Adornee = player.Character and player.Character:FindFirstChild("Head")
        healthGui.Parent = workspace

  local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextScaled = true
        textLabel.Parent = healthGui
    end

  return {box = adornment, healthGui = healthGui}
end

local function destroyESP(data)
    if data.box then data.box:Destroy() end
    if data.healthGui then data.healthGui:Destroy() end
end

runService.RenderStepped:Connect(function()
    -- 自动锁定
    if isLocking then
        if not (lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart")) then
            lockedTarget = get_closest_player()
        end
        -- 镜头锁定
        if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = lockedTarget.Character.HumanoidRootPart.Position
            local currentCamCFrame = camera.CFrame
            local newCFrame = CFrame.new(currentCamCFrame.Position, targetPos)
            camera.CFrame = newCFrame
        end
    end

    -- 更新ESP
  for player, data in pairs(espData) do
        if not (player.Character and player.Character:FindFirstChild("Head")) then
            destroyESP(data)
            espData[player] = nil
        else
            -- 方框
            if enableBox then
                if not data.box then
                    data = createESP(player)
                    espData[player] = data
                else
                    data.box.Adornee = player.Character.Head
                end
            else
                if data then
                    destroyESP(data)
                    espData[player] = nil
                end
            end

            -- 血量显示
  if showHealth and data and data.healthGui and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local health = humanoid.Health
                local maxHealth = humanoid.MaxHealth
                local textLabel = data.healthGui:FindFirstChildOfClass("TextLabel")
                if textLabel then
                    textLabel.Text = string.format("血量: %.0f/%.0f", health, maxHealth)
                end
            end

            -- 距离显示
   if data and data.distanceGui then
                local headPos = player.Character.Head.Position
                local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                if onScreen then
                    if not data.distanceGui then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Size = UDim2.new(4, 0, 1, 0)
                        billboard.Adornee = player.Character.Head
                        billboard.Parent = workspace
                        local textLabel = Instance.new("TextLabel")
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.TextColor3 = Color3.new(1, 1, 1)
                        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                        textLabel.TextStrokeTransparency = 0
                        textLabel.TextScaled = true
                        textLabel.Parent = billboard
                        data.distanceGui = billboard
                    end
                    local distance = (headPos - workspace.CurrentCamera.CFrame.Position).Magnitude
                    local label = data.distanceGui:FindFirstChildOfClass("TextLabel")
                    if label then
                        label.Text = string.format("距離: %.1f", distance)
                    end
                    data.distanceGui.Adornee = player.Character.Head
                else
                    if data.distanceGui then
                        data.distanceGui:Destroy()
                        data.distanceGui = nil
                    end
                end
            end
        end
    end

    -- 添加新目标到espData
  for _, player in ipairs(get_players()) do
        if not espData[player] then
            espData[player] = {}
        end
    end

    -- 子弹追踪（示意）
  if enableBulletTrack and lockedTarget and lockedTarget.Character then
        -- 这里可以添加弹道追踪逻辑，示例为绘制一条线（需要LineHandleAdornment或类似实现，略）
        -- 由于没有具体API，此处留空或添加自定义弹道追踪
    end
end)

-- 监听锁定按键
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == lockKey then
        isLocking = not isLocking
        if isLocking then
            lockedTarget = get_closest_player()
        else
            lockedTarget = nil
        end
    end
end)
