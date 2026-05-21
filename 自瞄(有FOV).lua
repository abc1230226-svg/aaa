local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui") -- 改用CoreGui

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// 如果只想給自己或管理員用，把你的 UserId 放進來
--// 例如：local ALLOWED_USER_IDS = { [123456789] = true }
--// 留空代表所有玩家都可以看到
local ALLOWED_USER_IDS = {}

if next(ALLOWED_USER_IDS) ~= nil and not ALLOWED_USER_IDS[LocalPlayer.UserId] then
    return
end

--// 設定
local MAX_RANGE = 150
local FOV_MIN = 10
local FOV_MAX = 120
local FOVAngle = 70

--// 狀態
local lockEnabled = false
local useFOVMode = true
local playerListVisible = true
local showFOVCircle = true

local excludedPlayers = {}
local currentLockedTarget = nil

--// 避免重複產生 UI
local oldGui = CoreGui:FindFirstChild("AimLockUI")
if oldGui then
    oldGui:Destroy()
end

--// UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimLockUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 330, 0, 570)
MainFrame.Position = UDim2.new(0, 30, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TitleBar = Instance.new("TextButton")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextSize = 14
TitleBar.Text = "Aim Lock 控制台｜拖曳這裡移動"
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local ToggleUIBtn = Instance.new("TextButton")
ToggleUIBtn.Size = UDim2.new(0, 120, 0, 32)
ToggleUIBtn.Position = UDim2.new(0, 30, 0, 60)
ToggleUIBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleUIBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleUIBtn.TextSize = 14
ToggleUIBtn.Text = "隱藏控制台"
ToggleUIBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleUIBtn

local function createButton(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    return btn
end

local LockButton = createButton("鎖定：OFF", 50)
local ModeButton = createButton("模式：FOV 優先", 90)
local ListToggleButton = createButton("玩家清單：開啟", 130)
local FOVCircleButton = createButton("FOV 圈圈：顯示", 170)
local RefreshButton = createButton("刷新玩家清單", 210)

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -20, 0, 26)
TargetLabel.Position = UDim2.new(0, 10, 0, 250)
TargetLabel.BackgroundTransparency = 1
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.TextSize = 14
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Text = "目前鎖定：無"
TargetLabel.Parent = MainFrame

--// FOV Label
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -20, 0, 24)
FOVLabel.Position = UDim2.new(0, 10, 0, 280)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVLabel.TextSize = 14
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Text = "FOV 大小：" .. FOVAngle
FOVLabel.Parent = MainFrame

--// 自製 FOV Slider
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, -20, 0, 34)
SliderFrame.Position = UDim2.new(0, 10, 0, 310)
SliderFrame.BackgroundTransparency = 1
SliderFrame.Parent = MainFrame

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, 0, 0, 8)
SliderTrack.Position = UDim2.new(0, 0, 0, 13)
SliderTrack.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = SliderFrame

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(1, 0)
TrackCorner.Parent = SliderTrack

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent = SliderFill

local SliderKnob = Instance.new("TextButton")
SliderKnob.Size = UDim2.new(0, 22, 0, 22)
SliderKnob.Position = UDim2.new(0, -11, 0, 6)
SliderKnob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
SliderKnob.Text = ""
SliderKnob.Parent = SliderFrame

local KnobCorner = Instance.new("UICorner")
KnobCorner.CornerRadius = UDim.new(1, 0)
KnobCorner.Parent = SliderKnob

local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, -20, 0, 26)
ListTitle.Position = UDim2.new(0, 10, 0, 355)
ListTitle.BackgroundTransparency = 1
ListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ListTitle.TextSize = 14
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.Text = "選擇不要鎖定的玩家："
ListTitle.Parent = MainFrame

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -20, 0, 175)
PlayerList.Position = UDim2.new(0, 10, 0, 385)
PlayerList.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 6
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 8)
ListCorner.Parent = PlayerList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = PlayerList

--// FOV 圈圈
local FOVCircle = Instance.new("Frame")
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = true
FOVCircle.Parent = CoreGui -- 改放在CoreGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Color = Color3.fromRGB(255, 255, 255)
CircleStroke.Transparency = 0.25
CircleStroke.Parent = FOVCircle

--// 拖曳 UI
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

--// Slider 功能
local sliderDragging = false

local function setFOVFromAlpha(alpha)
    alpha = math.clamp(alpha, 0, 1)

    FOVAngle = math.floor(FOV_MIN + (FOV_MAX - FOV_MIN) * alpha + 0.5)
    FOVLabel.Text = "FOV 大小：" .. FOVAngle

    SliderFill.Size = UDim2.new(alpha, 0, 1, 0)
    SliderKnob.Position = UDim2.new(alpha, -11, 0, 6)
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

setFOVFromAlpha((FOVAngle - FOV_MIN) / (FOV_MAX - FOV_MIN))

--// 玩家判斷
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

    if not humanoid or not hrp then
        return false
    end

    return humanoid.Health > 0
end

local function getTargetPart(player)
    local char = player.Character
    if not char then return nil end

    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function isValidTarget(player)
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

    if distance > MAX_RANGE then
        return false
    end

    return true
end

local function getAngleToPlayer(player)
    Camera = workspace.CurrentCamera

    local part = getTargetPart(player)
    if not part then
        return math.huge
    end

    local camPos = Camera.CFrame.Position
    local directionVector = part.Position - camPos

    if directionVector.Magnitude <= 0.01 then
        return math.huge
    end

    local direction = directionVector.Unit
    local lookVector = Camera.CFrame.LookVector
    local dot = math.clamp(lookVector:Dot(direction), -1, 1)

    return math.deg(math.acos(dot))
end

local function getDistanceToPlayer(player)
    local myHRP = getMyHRP()
    local part = getTargetPart(player)

    if not myHRP or not part then
        return math.huge
    end

    return (part.Position - myHRP.Position).Magnitude
end

local function getTargetByFOV()
    local bestPlayer = nil
    local bestAngle = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local angle = getAngleToPlayer(player)

            if angle <= FOVAngle and angle < bestAngle then
                bestAngle = angle
                bestPlayer = player
            end
        end
    end

    return bestPlayer
end

local function getTargetByClosest()
    local bestPlayer = nil
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local distance = getDistanceToPlayer(player)

            if distance < bestDistance then
                bestDistance = distance
                bestPlayer = player
            end
        end
    end

    return bestPlayer
end

local function getBestTarget()
    if useFOVMode then
        return getTargetByFOV()
    else
        return getTargetByClosest()
    end
end

local function aimAtTarget(player)
    Camera = workspace.CurrentCamera

    local part = getTargetPart(player)
    if not part then return end

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
end

local function updateTargetLabel()
    if currentLockedTarget and isValidTarget(currentLockedTarget) then
        TargetLabel.Text = "目前鎖定：" .. currentLockedTarget.Name
    else
        TargetLabel.Text = "目前鎖定：無"
    end
end

--// 玩家清單
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
                btn.Text = "🚫 不鎖定：" .. player.Name
            else
                btn.Text = "✅ 可鎖定：" .. player.Name
            end

            btn.Parent = PlayerList

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = btn

            btn.MouseButton1Click = (function()
                excludedPlayers[player.UserId] = not excludedPlayers[player.UserId]
                if currentLockedTarget == player and isExcluded(player) then
                    currentLockedTarget = nil
                end
                refreshPlayerList()
                updateTargetLabel()
            end)

            totalHeight += 37
        end
    end

    PlayerList.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

local function setPlayerListVisible(value)
    playerListVisible = value

    ListTitle.Visible = playerListVisible
    PlayerList.Visible = playerListVisible

    if playerListVisible then
        ListToggleButton.Text = "玩家清單：開啟"
        MainFrame.Size = UDim2.new(0, 330, 0, 570)
    else
        ListToggleButton.Text = "玩家清單：關閉"
        MainFrame.Size = UDim2.new(0, 330, 0, 355)
    end
end

--// UI 事件
ToggleUIBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible

    if MainFrame.Visible then
        ToggleUIBtn.Text = "隱藏控制台"
    else
        ToggleUIBtn.Text = "顯示控制台"
    end
end)

LockButton.MouseButton1Click:Connect(function()
    lockEnabled = not lockEnabled
    if lockEnabled then
        currentLockedTarget = getBestTarget()
        LockButton.Text = "鎖定：ON"
    else
        currentLockedTarget = nil
        LockButton.Text = "鎖定：OFF"
    end
    updateTargetLabel()
end)

ModeButton.MouseButton1Click:Connect(function()
    useFOVMode = not useFOVMode
    currentLockedTarget = nil
    if useFOVMode then
        ModeButton.Text = "模式：FOV 優先"
    else
        ModeButton.Text = "模式：最近玩家"
    end
    updateTargetLabel()
end)

ListToggleButton.MouseButton1Click:Connect(function()
    setPlayerListVisible(not playerListVisible)
end)

FOVCircleButton.MouseButton1Click:Connect(function()
    showFOVCircle = not showFOVCircle
    if showFOVCircle then
        FOVCircleButton.Text = "FOV 圈圈：顯示"
    else
        FOVCircleButton.Text = "FOV 圈圈：隱藏"
    end
end)

RefreshButton.MouseButton1Click:Connect(function()
    refreshPlayerList()
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.3)
    refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function(player)
    excludedPlayers[player.UserId] = nil
    if currentLockedTarget == player then
        currentLockedTarget = nil
    end
    refreshPlayerList()
    updateTargetLabel()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    currentLockedTarget = nil
    updateTargetLabel()
end)

--// 每幀更新
RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera

    if lockEnabled then
        if not currentLockedTarget or not isValidTarget(currentLockedTarget) then
            currentLockedTarget = getBestTarget()
        end
        if currentLockedTarget then
            aimAtTarget(currentLockedTarget)
        end
    end

    updateTargetLabel()

    local viewport = Camera.ViewportSize
    local centerX = viewport.X / 2
    local centerY = viewport.Y / 2

    local radius = math.clamp(FOVAngle * 4, 40, math.min(viewport.X, viewport.Y) / 2)
    FOVCircle.Size = UDim2.fromOffset(radius * 2, radius * 2)
    FOVCircle.Position = UDim2.fromOffset(centerX - radius, centerY - radius)
    FOVCircle.Visible = showFOVCircle and useFOVMode and MainFrame.Visible
end)

refreshPlayerList()
setPlayerListVisible(true)
updateTargetLabel()
