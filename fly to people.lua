local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local UI_PARENT = game:GetService("CoreGui") -- 使用 CoreGui

-- 避免重複建立
local oldGui = UI_PARENT:FindFirstChild("PlayerMarkerTPUI")
if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerMarkerTPUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = UI_PARENT

local function addCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
end

local function getRootPart(player)
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getHead(player)
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("Head")
end

local currentMarker = nil
local targetPlayer = nil
local lastTpTime = 0
local cooldown = 0.4

-- 建立玩家頭上標記
local function createMarker(player)
    if currentMarker then
        currentMarker:Destroy()
        currentMarker = nil
    end

    local head = getHead(player)
    local rootPart = getRootPart(player)

    if not head and not rootPart then
        return
    end

    local marker = Instance.new("BillboardGui")
    marker.Name = "TargetMarker"
    marker.Size = UDim2.new(0, 140, 0, 45)
    marker.StudsOffset = Vector3.new(0, 3, 0)
    marker.AlwaysOnTop = true
    marker.Adornee = head or rootPart
    marker.Parent = ScreenGui

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "🔵 " .. player.Name
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = marker

    currentMarker = marker
end

local function canUse()
    local now = os.clock()
    if now - lastTpTime < cooldown then
        return false
    end
    lastTpTime = now
    return true
end

local function prepareMyCharacter()
    local character = LocalPlayer.Character
    if not character then
        return nil, nil
    end
    local rootPart = getRootPart(LocalPlayer)
    if not rootPart then
        return nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Sit = false
    end
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    return character, rootPart
end

local function teleportBesidePlayer(player)
    if not player or player == LocalPlayer then return end
    if not canUse() then return end
    local targetRoot = getRootPart(player)
    if not targetRoot then return end
    local character = prepareMyCharacter()
    if not character then return end
    character:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 4))
end

local function teleportAbovePlayer(player)
    if not player or player == LocalPlayer then return end
    if not canUse() then return end
    local targetRoot = getRootPart(player)
    if not targetRoot then return end
    local character = prepareMyCharacter()
    if not character then return end
    character:PivotTo(CFrame.new(targetRoot.Position + Vector3.new(0, 5, 0)))
end

-- UI元素建構
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 70, 0, 35)
ToggleButton.Position = UDim2.new(0, 20, 0, 150)
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.TextSize = 16
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "選人"
ToggleButton.Parent = ScreenGui
addCorner(ToggleButton, 8)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 310, 0, 410)
MainFrame.Position = UDim2.new(0, 100, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 10)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
addCorner(TopBar, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "選擇玩家"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(0, 32, 0, 28)
RefreshButton.Position = UDim2.new(1, -72, 0, 5)
RefreshButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
RefreshButton.TextColor3 = Color3.new(1, 1, 1)
RefreshButton.TextSize = 15
RefreshButton.Font = Enum.Font.SourceSansBold
RefreshButton.Text = "↻"
RefreshButton.Parent = TopBar
addCorner(RefreshButton, 6)

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 32, 0, 28)
CloseButton.Position = UDim2.new(1, -36, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(120, 35, 35)
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.Parent = TopBar
addCorner(CloseButton, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 0, 26)
StatusLabel.Position = UDim2.new(0, 6, 1, -32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "選擇一個玩家"
StatusLabel.Parent = MainFrame

local ButtonContainer = Instance.new("ScrollingFrame")
ButtonContainer.Size = UDim2.new(1, -12, 1, -82)
ButtonContainer.Position = UDim2.new(0, 6, 0, 44)
ButtonContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ButtonContainer.BorderSizePixel = 0
ButtonContainer.ScrollBarThickness = 6
ButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ButtonContainer.Parent = MainFrame
addCorner(ButtonContainer, 8)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ButtonContainer
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)
UIPadding.PaddingBottom = UDim.new(0, 6)
UIPadding.Parent = ButtonContainer

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ButtonContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
end)

-- 拖動UI
local dragging = false
local dragStart
local startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local function clearList()
    for _, child in ipairs(ButtonContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

local function createEmptyText()
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -10, 0, 35)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(200, 200, 200)
    text.TextSize = 15
    text.Font = Enum.Font.SourceSans
    text.Text = "目前沒有其他玩家"
    text.Parent = ButtonContainer
end

local function createPlayerRow(player)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -10, 0, 52)
    Row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Row.BorderSizePixel = 0
    Row.Parent = ButtonContainer
    addCorner(Row, 7)

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -190, 1, 0)
    NameLabel.Position = UDim2.new(0, 10, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = player.Name
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.SourceSansBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Row

    local MarkButton = Instance.new("TextButton")
    MarkButton.Size = UDim2.new(0, 50, 0, 32)
    MarkButton.Position = UDim2.new(1, -166, 0.5, -16)
    MarkButton.BackgroundColor3 = Color3.fromRGB(60, 120, 160)
    MarkButton.TextColor3 = Color3.new(1, 1, 1)
    MarkButton.TextSize = 13
    MarkButton.Font = Enum.Font.SourceSansBold
    MarkButton.Text = "標記"
    MarkButton.Parent = Row
    addCorner(MarkButton, 6)

    local TpButton = Instance.new("TextButton")
    TpButton.Size = UDim2.new(0, 50, 0, 32)
    TpButton.Position = UDim2.new(1, -110, 0.5, -16)
    TpButton.BackgroundColor3 = Color3.fromRGB(70, 90, 160)
    TpButton.TextColor3 = Color3.new(1, 1, 1)
    TpButton.TextSize = 13
    TpButton.Font = Enum.Font.SourceSansBold
    TpButton.Text = "旁邊"
    TpButton.Parent = Row
    addCorner(TpButton, 6)

    local HeadButton = Instance.new("TextButton")
    HeadButton.Size = UDim2.new(0, 50, 0, 32)
    HeadButton.Position = UDim2.new(1, -54, 0.5, -16)
    HeadButton.BackgroundColor3 = Color3.fromRGB(90, 120, 70)
    HeadButton.TextColor3 = Color3.new(1, 1, 1)
    HeadButton.TextSize = 13
    HeadButton.Font = Enum.Font.SourceSansBold
    HeadButton.Text = "頭上"
    HeadButton.Parent = Row
    addCorner(HeadButton, 6)

    -- 事件綁定
    MarkButton.MouseButton1Click:Connect(function()
        targetPlayer = player
        createMarker(player)
        StatusLabel.Text = "已標記：" .. player.Name
    end)

    TpButton.MouseButton1Click:Connect(function()
        targetPlayer = player
        createMarker(player)
        teleportBesidePlayer(player)
        StatusLabel.Text = "已 TP 到：" .. player.Name
    end)

    HeadButton.MouseButton1Click:Connect(function()
        targetPlayer = player
        createMarker(player)
        teleportAbovePlayer(player)
        StatusLabel.Text = "已飛到 " .. player.Name .. " 頭上"
    end)
end

local function refreshPlayerList()
    clearList()
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            count = count + 1
            createPlayerRow(player)
        end
    end
    if count == 0 then
        createEmptyText()
    end
end

-- 按鈕事件
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        refreshPlayerList()
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

RefreshButton.MouseButton1Click:Connect(function()
    refreshPlayerList()
    StatusLabel.Text = "已刷新玩家列表"
end)

-- 玩家離開或加入
Players.PlayerAdded:Connect(function()
    if MainFrame.Visible then
        refreshPlayerList()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if targetPlayer == player then
        targetPlayer = nil
        if currentMarker then
            currentMarker:Destroy()
            currentMarker = nil
        end
        StatusLabel.Text = "目標玩家已離開"
    end
    if MainFrame.Visible then
        task.delay(0.1, function() refreshPlayerList() end)
    end
end)

-- 快捷鍵開關UI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            refreshPlayerList()
        end
    end
end)

-- 持續同步標記
RunService.RenderStepped:Connect(function()
    if currentMarker and targetPlayer and targetPlayer.Character then
        local head = getHead(targetPlayer)
        local rootPart = getRootPart(targetPlayer)
        if head then
            currentMarker.Adornee = head
        elseif rootPart then
            currentMarker.Adornee = rootPart
        end
    end
end)

-- 初始化
refreshPlayerList()
