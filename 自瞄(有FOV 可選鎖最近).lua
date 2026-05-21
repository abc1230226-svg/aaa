local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui") -- 改用CoreGui

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local SHOOT_EVENT_NAME = "ShootEvent"
local AIM_RANGE = 150
local FIRE_DELAY = 0.08

local espEnabled = false
local autoAimEnabled = false
local holdFireEnabled = false
local mouseHolding = false
local autoFiring = false

local excludedPlayers = {}
local espObjects = {}

-- 新增：鎖定模式與 FOV
local useFOVMode = true -- true = 鎖 FOV 圈內，false = 鎖最近玩家
local fovCircleVisible = true
local FOV_RADIUS = 160
local FOV_MIN = 50
local FOV_MAX = 350

-- 防止重複 UI
local oldGui = CoreGui:FindFirstChild("AimAssistUI")
if oldGui then
    oldGui:Destroy()
end

--// 建立 UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 600)
MainFrame.Position = UDim2.new(0, 30, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("TextButton")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextSize = 14
TitleBar.Text = "Aim Assist 控制台｜拖曳這裡移動"
TitleBar.Parent = MainFrame

local ToggleUIBtn = Instance.new("TextButton")
ToggleUIBtn.Size = UDim2.new(0, 120, 0, 32)
ToggleUIBtn.Position = UDim2.new(0, 30, 0, 60)
ToggleUIBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleUIBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleUIBtn.TextSize = 14
ToggleUIBtn.Text = "隱藏控制台"
ToggleUIBtn.Parent = ScreenGui

local function createButton(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = MainFrame
    return btn
end

local ESPButton = createButton("ESP：OFF", 50)
local AimButton = createButton("自動瞄準：OFF", 90)
local FireButton = createButton("按住左鍵自動攻擊：OFF", 130)
local RefreshButton = createButton("刷新玩家清單", 170)
local NoClipButton = createButton("NoClip：OFF", 210)
local ListToggleButton = createButton("玩家清單：開啟", 250)
local ModeButton = createButton("鎖定模式：FOV 圈內", 290)
local FOVCircleButton = createButton("FOV 圓圈：顯示", 330)

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -20, 0, 24)
TargetLabel.Position = UDim2.new(0, 10, 0, 370)
TargetLabel.BackgroundTransparency = 1
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.TextSize = 14
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Text = "目前目標：無"
TargetLabel.Parent = MainFrame

local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -20, 0, 24)
FOVLabel.Position = UDim2.new(0, 10, 0, 400)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVLabel.TextSize = 14
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Text = "FOV 大小：" .. FOV_RADIUS
FOVLabel.Parent = MainFrame

--// 自製 FOV 拉桿
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, -20, 0, 35)
SliderFrame.Position = UDim2.new(0, 10, 0, 430)
SliderFrame.BackgroundTransparency = 1
SliderFrame.Parent = MainFrame

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, 0, 0, 8)
SliderTrack.Position = UDim2.new(0, 0, 0, 14)
SliderTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local SliderKnob = Instance.new("TextButton")
SliderKnob.Size = UDim2.new(0, 22, 0, 22)
SliderKnob.Position = UDim2.new(0, -11, 0, 7)
SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderKnob.Text = ""
SliderKnob.Parent = SliderFrame

local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, -20, 0, 28)
ListTitle.Position = UDim2.new(0, 10, 0, 475)
ListTitle.BackgroundTransparency = 1
ListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ListTitle.TextSize = 14
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.Text = "選擇不要瞄準的玩家："
ListTitle.Parent = MainFrame

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -20, 0, 85)
PlayerList.Position = UDim2.new(0, 10, 0, 505)
PlayerList.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 6
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = PlayerList

--// 白色 FOV 圓圈
local FOVCircle = Instance.new("Frame")
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = CoreGui -- 改放在CoreGui

local FOVCircleCorner = Instance.new("UICorner")
FOVCircleCorner.CornerRadius = UDim.new(1, 0)
FOVCircleCorner.Parent = FOVCircle

local FOVCircleStroke = Instance.new("UIStroke")
FOVCircleStroke.Color = Color3.fromRGB(255, 255, 255)
FOVCircleStroke.Thickness = 2
FOVCircleStroke.Transparency = 0.15
FOVCircleStroke.Parent = FOVCircle

--// 拖曳功能
local dragging = false
local dragStart
local startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement 
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

ToggleUIBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible

    if MainFrame.Visible then
        ToggleUIBtn.Text = "隱藏控制台"
    else
        ToggleUIBtn.Text = "顯示控制台"
    end
end)

--// FOV 拉桿功能
local sliderDragging = false

local function setFOVFromAlpha(alpha)
    alpha = math.clamp(alpha, 0, 1)

    FOV_RADIUS = math.floor(FOV_MIN + (FOV_MAX - FOV_MIN) * alpha + 0.5)
    FOVLabel.Text = "FOV 大小：" .. FOV_RADIUS

    SliderFill.Size = UDim2.new(alpha, 0, 1, 0)
    SliderKnob.Position = UDim2.new(alpha, -11, 0, 7)
end

local function updateSliderFromX(x)
    local trackX = SliderTrack.AbsolutePosition.X
    local trackWidth = SliderTrack.AbsoluteSize.X
    local alpha = (x - trackX) / trackWidth

    setFOVFromAlpha(alpha)
end

SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        sliderDragging = true
        updateSliderFromX(input.Position.X)
    end
end)

SliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        sliderDragging = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        updateSliderFromX(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        sliderDragging = false
    end
end)

setFOVFromAlpha((FOV_RADIUS - FOV_MIN) / (FOV_MAX - FOV_MIN))

--// 判斷玩家
local function isExcluded(player)
    return excludedPlayers[player.UserId] == true
end

local function getMyHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function isAlive(player)
    local char = player.Character
    if not char then return false end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then return false end

    return humanoid.Health > 0
end

local function getTargetPart(player)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function isEnemy(player)
    if not player then return false end
    if player == LocalPlayer then return false end
    if isExcluded(player) then return false end
    if not isAlive(player) then return false end

    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end

    local myHRP = getMyHRP()
    local targetPart = getTargetPart(player)

    if not myHRP or not targetPart then
        return false
    end

    local distance = (targetPart.Position - myHRP.Position).Magnitude
    if distance > AIM_RANGE then return false end

    return true
end

local function getClosestEnemy()
    local closestPlayer = nil
    local closestDistance = math.huge

    local myHRP = getMyHRP()
    if not myHRP then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local part = getTargetPart(player)

            if part then
                local distance = (part.Position - myHRP.Position).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

local function getFOVEnemy()
    Camera = workspace.CurrentCamera

    local closestToCenter = math.huge
    local bestPlayer = nil

    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local part = getTargetPart(player)

            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

                if onScreen then
                    local screenDistance = (
                        Vector2.new(screenPos.X, screenPos.Y) - center
                    ).Magnitude

                    if screenDistance <= FOV_RADIUS and screenDistance < closestToCenter then
                        closestToCenter = screenDistance
                        bestPlayer = player
                    end
                end
            end
        end
    end

    return bestPlayer
end

local function getTarget()
    if useFOVMode then
        return getFOVEnemy()
    else
        return getClosestEnemy()
    end
end

local function aimAtTarget(player)
    Camera = workspace.CurrentCamera

    local part = getTargetPart(player)
    if not part then return end

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
end

local function shootTarget(player)
    if not player then return end

    local shootEvent = ReplicatedStorage:FindFirstChild(SHOOT_EVENT_NAME)

    if not shootEvent then
        warn("找不到 RemoteEvent：" .. SHOOT_EVENT_NAME)
        return
    end

    local part = getTargetPart(player)
    if not part then return end

    shootEvent:FireServer(part.Position)
end

local function startAutoFire()
    if autoFiring then return end

    autoFiring = true

    task.spawn(function()
        while autoFiring and mouseHolding and holdFireEnabled do
            local target = getTarget()

            if target then
                if autoAimEnabled then
                    aimAtTarget(target)
                end

                shootTarget(target)
            end

            task.wait(FIRE_DELAY)
        end

        autoFiring = false
    end)
end

--// ESP：保留原本邏輯
local function clearESP()
    for _, obj in pairs(espObjects) do
        if obj then
            obj:Destroy()
        end
    end

    espObjects = {}
end

local function updateESP()
    if not espEnabled then
        clearESP()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character

        if isEnemy(player) and char then
            if not espObjects[player.UserId] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "AimAssistESP"
                highlight.Adornee = char
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.65
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = char
                espObjects[player.UserId] = highlight
            else
                espObjects[player.UserId].Adornee = char
            end
        else
            if espObjects[player.UserId] then
                espObjects[player.UserId]:Destroy()
                espObjects[player.UserId] = nil
            end
        end
    end
end

local function refreshPlayerList()
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local totalHeight = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 32)
            btn.BackgroundColor3 = isExcluded(player)
                and Color3.fromRGB(140, 45, 45)
                or Color3.fromRGB(55, 55, 55)

            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 13

            if isExcluded(player) then
                btn.Text = "🚫 不瞄準：" .. player.Name
            else
                btn.Text = "✅ 可瞄準：" .. player.Name
            end

            btn.Parent = PlayerList

            btn.MouseButton1Click:Connect(function()
                excludedPlayers[player.UserId] = not excludedPlayers[player.UserId]
                refreshPlayerList()
                updateESP()
            end)

            totalHeight += 37
        end
    end

    PlayerList.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

--// UI 事件
ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPButton.Text = "ESP：" .. (espEnabled and "ON" or "OFF")
    updateESP()
end)

AimButton.MouseButton1Click:Connect(function()
    autoAimEnabled = not autoAimEnabled
    AimButton.Text = "自動瞄準：" .. (autoAimEnabled and "ON" or "OFF")
end)

FireButton.MouseButton1Click:Connect(function()
    holdFireEnabled = not holdFireEnabled
    FireButton.Text = "按住左鍵自動攻擊：" .. (holdFireEnabled and "ON" or "OFF")
end)

RefreshButton.MouseButton1Click:Connect(function()
    refreshPlayerList()
    updateESP()
end)

ListToggleButton.MouseButton1Click:Connect(function()
    local visible = not PlayerList.Visible

    PlayerList.Visible = visible
    ListTitle.Visible = visible

    if visible then
        ListToggleButton.Text = "玩家清單：開啟"
        MainFrame.Size = UDim2.new(0, 320, 0, 600)
    else
        ListToggleButton.Text = "玩家清單：關閉"
        MainFrame.Size = UDim2.new(0, 320, 0, 475)
    end
end)

ModeButton.MouseButton1Click:Connect(function()
    useFOVMode = not useFOVMode

    if useFOVMode then
        ModeButton.Text = "鎖定模式：FOV 圈內"
    else
        ModeButton.Text = "鎖定模式：最近玩家"
    end
end)

FOVCircleButton.MouseButton1Click:Connect(function()
    fovCircleVisible = not fovCircleVisible

    if fovCircleVisible then
        FOVCircleButton.Text = "FOV 圓圈：顯示"
    else
        FOVCircleButton.Text = "FOV 圓圈：隱藏"
    end
end)

--// NoClip
local noclipActive = false
local originalCollisions = {}

local function applyNoClip()
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if noclipActive then
                if originalCollisions[part] == nil then
                    originalCollisions[part] = part.CanCollide
                end
                part.CanCollide = false
            else
                if originalCollisions[part] ~= nil then
                    part.CanCollide = originalCollisions[part]
                    originalCollisions[part] = nil
                end
            end
        end
    end
end

NoClipButton.MouseButton1Click:Connect(function()
    noclipActive = not noclipActive
    NoClipButton.Text = "NoClip：" .. (noclipActive and "ON" or "OFF")
    applyNoClip()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    originalCollisions = {}

    if noclipActive then
        applyNoClip()
    end
end)

--// 按住左鍵攻擊
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseHolding = true

        if holdFireEnabled then
            startAutoFire()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseHolding = false
    end
end)

--// 玩家加入/離開
Players.PlayerAdded:Connect(function()
    task.wait(0.3)
    refreshPlayerList()
    updateESP()
end)

Players.PlayerRemoving:Connect(function(player)
    excludedPlayers[player.UserId] = nil

    if espObjects[player.UserId] then
        espObjects[player.UserId]:Destroy()
        espObjects[player.UserId] = nil
    end

    refreshPlayerList()
end)

--// 每幀更新
local espTimer = 0

RunService.RenderStepped:Connect(function(dt)
    Camera = workspace.CurrentCamera

    local target = nil

    if autoAimEnabled then
        target = getTarget()

        if target then
            aimAtTarget(target)
        end
    end

    if target then
        TargetLabel.Text = "目前目標：" .. target.Name
    else
        TargetLabel.Text = "目前目標：無"
    end

    -- 更新白色 FOV 圓圈
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    FOVCircle.Size = UDim2.fromOffset(FOV_RADIUS * 2, FOV_RADIUS * 2)
    FOVCircle.Position = UDim2.fromOffset(centerX - FOV_RADIUS, centerY - FOV_RADIUS)
    FOVCircle.Visible = fovCircleVisible and useFOVMode

    espTimer += dt

    if espTimer >= 0.25 then
        espTimer = 0
        updateESP()
    end

    if noclipActive then
        applyNoClip()
    end
end)

refreshPlayerList()
