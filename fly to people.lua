local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local UI_PARENT = game:GetService("CoreGui") -- 改為 CoreGui

-- 避免重複建立 UI
local oldGui = UI_PARENT:FindFirstChild("TpToPlayerUI")
if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TpToPlayerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = UI_PARENT

local function addCorner(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
end

-- 開關按鈕
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 70, 0, 35)
OpenButton.Position = UDim2.new(0, 20, 0, 180)
OpenButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
OpenButton.TextColor3 = Color3.new(1, 1, 1)
OpenButton.TextSize = 16
OpenButton.Font = Enum.Font.SourceSansBold
OpenButton.Text = "TP"
OpenButton.Parent = ScreenGui
addCorner(OpenButton, 8)

-- 主框架
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 370)
MainFrame.Position = UDim2.new(0, 100, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 10)

-- 上方標題列
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
addCorner(TopBar, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -85, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "玩家 TP 清單"
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

-- 狀態文字
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 0, 24)
StatusLabel.Position = UDim2.new(0, 6, 1, -30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "點玩家旁邊按鈕即可 TP"
StatusLabel.Parent = MainFrame

-- 玩家清單
local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -12, 1, -78)
PlayerList.Position = UDim2.new(0, 6, 0, 44)
PlayerList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 6
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.Parent = MainFrame
addCorner(PlayerList, 8)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = PlayerList
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)
UIPadding.PaddingBottom = UDim.new(0, 6)
UIPadding.Parent = PlayerList

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PlayerList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 12)
end)

-- 拖動 UI
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

local function getRootPart(player)
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local lastTpTime = 0
local cooldown = 0.5

local function canTp()
    local now = os.clock()
    if now - lastTpTime < cooldown then
        StatusLabel.Text = "請不要點太快"
        return false
    end
    lastTpTime = now
    return true
end

local function prepareCharacter()
    local character = LocalPlayer.Character
    if not character then
        StatusLabel.Text = "找不到你的角色"
        return nil, nil
    end
    local rootPart = getRootPart(LocalPlayer)
    if not rootPart then
        StatusLabel.Text = "找不到你的 HumanoidRootPart"
        return nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Sit = false
    end
    rootPart.AssemblyLinearVelocity = Vector3.new()
    rootPart.AssemblyAngularVelocity = Vector3.new()
    return character, rootPart
end

-- TP 到玩家旁邊
local function teleportBesidePlayer(targetPlayer)
    if not canTp() then return end
    if not targetPlayer or targetPlayer == LocalPlayer then return end
    local targetRootPart = getRootPart(targetPlayer)
    if not targetRootPart then
        StatusLabel.Text = "找不到目標玩家角色"
        return
    end
    local character, rootPart = prepareCharacter()
    if not character then return end
    character:PivotTo(targetRootPart.CFrame * CFrame.new(0, 0, 4))
    StatusLabel.Text = "已 TP 到：" .. targetPlayer.Name
end

-- TP 到玩家頭上
local function teleportAbovePlayer(targetPlayer)
    if not canTp() then return end
    if not targetPlayer or targetPlayer == LocalPlayer then return end
    local targetRootPart = getRootPart(targetPlayer)
    if not targetRootPart then
        StatusLabel.Text = "找不到目標玩家角色"
        return
    end
    local character, rootPart = prepareCharacter()
    if not character then return end
    -- 頭上約5格
    local targetPos = targetRootPart.Position + Vector3.new(0, 5, 0)
    character:PivotTo(CFrame.new(targetPos))
    StatusLabel.Text = "已飛到 " .. targetPlayer.Name .. " 頭上"
end

local function clearButtons()
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
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
    text.Parent = PlayerList
end

local function createPlayerRow(player)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, -10, 0, 46)
    Row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Row.BorderSizePixel = 0
    Row.Parent = PlayerList
    addCorner(Row, 7)

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -150, 1, 0)
    NameLabel.Position = UDim2.new(0, 10, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = player.Name
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.SourceSansBold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = Row

    local TpBtn = Instance.new("TextButton")
    TpBtn.Size = UDim2.new(0, 60, 0, 30)
    TpBtn.Position = UDim2.new(1, -132, 0.5, -15)
    TpBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
    TpBtn.TextColor3 = Color3.new(1, 1, 1)
    TpBtn.TextSize = 13
    TpBtn.Font = Enum.Font.SourceSansBold
    TpBtn.Text = "旁邊"
    TpBtn.Parent = Row
    addCorner(TpBtn, 6)

    local HeadBtn = Instance.new("TextButton")
    HeadBtn.Size = UDim2.new(0, 60, 0, 30)
    HeadBtn.Position = UDim2.new(1, -66, 0.5, -15)
    HeadBtn.BackgroundColor3 = Color3.fromRGB(90, 120, 70)
    HeadBtn.TextColor3 = Color3.new(1, 1, 1)
    HeadBtn.TextSize = 13
    HeadBtn.Font = Enum.Font.SourceSansBold
    HeadBtn.Text = "頭上"
    HeadBtn.Parent = Row
    addCorner(HeadBtn, 6)

    TpBtn.MouseButton1Click:Connect(function()
        teleportBesidePlayer(player)
    end)

    HeadBtn.MouseButton1Click:Connect(function()
        teleportAbovePlayer(player)
    end)
end

local function refreshPlayerButtons()
    clearButtons()
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            count += 1
            createPlayerRow(player)
        end
    end
    if count == 0 then
        createEmptyText()
    end
end

-- 開關 UI
OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        refreshPlayerButtons()
        StatusLabel.Text = "點玩家旁邊按鈕即可 TP"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

RefreshButton.MouseButton1Click:Connect(function()
    refreshPlayerButtons()
    StatusLabel.Text = "已刷新玩家列表"
end)

Players.PlayerAdded:Connect(function()
    if MainFrame.Visible then
        refreshPlayerButtons()
    end
end)

Players.PlayerRemoving:Connect(function()
    if MainFrame.Visible then
        task.delay(0.1, refreshPlayerButtons)
    end
end)

-- 按 RightShift 也可以開關
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            refreshPlayerButtons()
            StatusLabel.Text = "點玩家旁邊按鈕即可 TP"
        end
    end
end)

refreshPlayerButtons()
