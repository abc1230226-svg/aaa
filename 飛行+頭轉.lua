local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local UI_PARENT = game:GetService("CoreGui")

local oldGui = UI_PARENT:FindFirstChild("PlayerMarkerFlyLockUI")
if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerMarkerFlyLockUI"
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

local targetPlayer = nil
local currentMarker = nil

local flySpeed = 100
local flyHeight = 5
local isFlying = false

local lockAfterArrive = true
local isFollowingHead = false
local followConnection = nil

local lastUseTime = 0
local cooldown = 0.35

-- ===== 行走速度設定 (與飛行速度獨立) =====
local walkSpeed = 50  -- 可改預設速度
local walkHumanoid = nil
local walkWatchConnection = nil
local walkCharacterConnection = nil
local walkLastWarnTime = -math.huge
local walkLastRestoreTime = -math.huge
local walkResetCount = 0


-- ===== 客戶端 __newindex Hook（啟動後常駐；僅攔截本機 WalkSpeed 寫入） =====
-- Roblox Studio 標準 LocalScript 不提供 hookmetamethod/newcclosure。
-- 如果執行環境沒有 Hook API，就會退回原先的 WalkSpeed 設定與監測。
local hookEnv
if type(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then hookEnv = env end
end

local hookKey = "__fly_to_people_walkspeed_hook_20261124"
local hookState = hookEnv and hookEnv[hookKey] or nil
if type(hookState) ~= "table" then
    hookState = {
        installed = false,
        enabled = true,
        humanoid = nil,
        speed = walkSpeed,
        blocked = 0,
    }
    if hookEnv then hookEnv[hookKey] = hookState end
end
hookState.enabled = true
hookState.speed = walkSpeed

local function installWalkSpeedHook()
    if hookState.installed then return true end
    if type(hookmetamethod) ~= "function" then
        warn("[WalkSpeed Hook] 執行環境不支援 hookmetamethod；維持一般設定模式")
        return false
    end

    local oldNewIndex
    local function interceptNewIndex(self, property, value)
        if hookState.enabled and self == hookState.humanoid
            and property == "WalkSpeed" and type(value) == "number"
            and value ~= hookState.speed then
            local isExecutor = false
            if type(checkcaller) == "function" then
                local ok, result = pcall(checkcaller)
                isExecutor = ok and result == true
            end
            -- 僅取代其他遊戲客戶端 Lua 腳本的寫入，避免攔截本腳本按鈕。
            if not isExecutor then
                hookState.blocked += 1
                return oldNewIndex(self, property, hookState.speed)
            end
        end
        return oldNewIndex(self, property, value)
    end

    local replacement = interceptNewIndex
    if type(newcclosure) == "function" then
        local ok, result = pcall(newcclosure, interceptNewIndex)
        if ok then replacement = result end
    end
    local ok, result = pcall(function()
        return hookmetamethod(game, "__newindex", replacement)
    end)
    if not ok or type(result) ~= "function" then
        warn("[WalkSpeed Hook] 無法安裝 Hook：", result)
        return false
    end
    oldNewIndex = result
    hookState.installed = true
    print("[WalkSpeed Hook] 已啟用本機 __newindex 攔截")
    return true
end

installWalkSpeedHook()

-- 監控實際 WalkSpeed：如果其他腳本改了數值，記錄並嘗試恢復。
-- 注意：這只能處理 WalkSpeed 屬性被覆寫，不保證突破遊戲伺服器的移動限制。
local function watchWalkHumanoid(character)
    if walkWatchConnection then
        walkWatchConnection:Disconnect()
        walkWatchConnection = nil
    end
    walkHumanoid = nil
    hookState.humanoid = nil
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid", 10)
    if not humanoid then
        warn("[WalkSpeed] 找不到 Humanoid，無法設定速度")
        return
    end

    walkHumanoid = humanoid
    hookState.humanoid = humanoid
    hookState.speed = walkSpeed
    humanoid.WalkSpeed = walkSpeed
    print("[WalkSpeed] 已套用設定速度：", humanoid.WalkSpeed)

    walkWatchConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if walkHumanoid ~= humanoid or not humanoid.Parent then return end
        local actualSpeed = humanoid.WalkSpeed
        if math.abs(actualSpeed - walkSpeed) < 0.01 then return end

        walkResetCount += 1
        local now = os.clock()
        if now - walkLastWarnTime >= 2 then
            warn(string.format(
                "[WalkSpeed] 偵測到速度被改為 %.1f（設定 %.1f），累計 %d 次；嘗試恢復。",
                actualSpeed, walkSpeed, walkResetCount
            ))
            walkLastWarnTime = now
        end

        -- 限制每秒最多嘗試恢復約 10 次，避免其他腳本持續覆寫時無限反覆設定。
        if now - walkLastRestoreTime >= 0.1 then
            walkLastRestoreTime = now
            task.defer(function()
                if walkHumanoid == humanoid and humanoid.Parent
                    and math.abs(humanoid.WalkSpeed - walkSpeed) >= 0.01 then
                    humanoid.WalkSpeed = walkSpeed
                end
            end)
        end
    end)
end

local function applyWalkSpeed(value)
    local num = tonumber(value)
    if not num or num ~= num or num == math.huge or num == -math.huge then
        return false
    end

    walkSpeed = math.max(0, math.floor(num + 0.5))
    hookState.speed = walkSpeed
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if walkHumanoid ~= humanoid then
            -- 新角色，先掛上監控
            watchWalkHumanoid(character)
        end
        humanoid.WalkSpeed = walkSpeed
        print("[WalkSpeed] 要求設定：", walkSpeed, " / 目前實際屬性：", humanoid.WalkSpeed)
    end
    return true
end

walkCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
    watchWalkHumanoid(character)
end)

if LocalPlayer.Character then
    task.defer(watchWalkHumanoid, LocalPlayer.Character)
end

-- 隱藏視窗不會停用 Hook；重複執行時，銷毀舊 GUI 才會清理舊連線。
ScreenGui.Destroying:Connect(function()
    hookState.enabled = false -- 舊版停用，重新執行時重用同一個 Hook
    if walkWatchConnection then walkWatchConnection:Disconnect() end
    if walkCharacterConnection then walkCharacterConnection:Disconnect() end
end)

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 75, 0, 35)
ToggleButton.Position = UDim2.new(0, 20, 0, 150)
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.TextSize = 16
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "選人"
ToggleButton.Parent = ScreenGui
addCorner(ToggleButton, 8)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 430)
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
Title.Text = "玩家標記 / TP / 飛頭固定"
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

local SpeedFrame = Instance.new("Frame")
SpeedFrame.Size = UDim2.new(1, -12, 0, 64)
SpeedFrame.Position = UDim2.new(0, 6, 0, 44)
SpeedFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SpeedFrame.BorderSizePixel = 0
SpeedFrame.Parent = MainFrame
addCorner(SpeedFrame, 8)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 120, 0, 26)
SpeedLabel.Position = UDim2.new(0, 8, 0, 5)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedLabel.TextSize = 14
SpeedLabel.Font = Enum.Font.SourceSansBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Text = "飛行速度: " .. flySpeed
SpeedLabel.Parent = SpeedFrame

local function updateSpeedText()
	SpeedLabel.Text = "飛行速度: " .. flySpeed
end

local SpeedDownButton = Instance.new("TextButton")
SpeedDownButton.Size = UDim2.new(0, 34, 0, 26)
SpeedDownButton.Position = UDim2.new(0, 130, 0, 5)
SpeedDownButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
SpeedDownButton.TextColor3 = Color3.new(1, 1, 1)
SpeedDownButton.TextSize = 18
SpeedDownButton.Font = Enum.Font.SourceSansBold
SpeedDownButton.Text = "-"
SpeedDownButton.Parent = SpeedFrame
addCorner(SpeedDownButton, 6)

local SpeedUpButton = Instance.new("TextButton")
SpeedUpButton.Size = UDim2.new(0, 34, 0, 26)
SpeedUpButton.Position = UDim2.new(0, 170, 0, 5)
SpeedUpButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
SpeedUpButton.TextColor3 = Color3.new(1, 1, 1)
SpeedUpButton.TextSize = 18
SpeedUpButton.Font = Enum.Font.SourceSansBold
SpeedUpButton.Text = "+"
SpeedUpButton.Parent = SpeedFrame
addCorner(SpeedUpButton, 6)

local LockButton = Instance.new("TextButton")
LockButton.Size = UDim2.new(0, 90, 0, 26)
LockButton.Position = UDim2.new(0, 210, 0, 5)
LockButton.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
LockButton.TextColor3 = Color3.new(1, 1, 1)
LockButton.TextSize = 13
LockButton.Font = Enum.Font.SourceSansBold
LockButton.Text = "固定: 開"
LockButton.Parent = SpeedFrame
addCorner(LockButton, 6)

local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(0, 46, 0, 26)
StopButton.Position = UDim2.new(1, -52, 0, 5)
StopButton.BackgroundColor3 = Color3.fromRGB(130, 60, 60)
StopButton.TextColor3 = Color3.new(1, 1, 1)
StopButton.TextSize = 13
StopButton.Font = Enum.Font.SourceSansBold
StopButton.Text = "停止"
StopButton.Parent = SpeedFrame
addCorner(StopButton, 6)

local function createSpeedButton(text, speed, x)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 72, 0, 22)
	btn.Position = UDim2.new(0, x, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 12
	btn.Font = Enum.Font.SourceSansBold
	btn.Text = text
	btn.Parent = SpeedFrame
	addCorner(btn, 5)

	btn.MouseButton1Click:Connect(function()
		flySpeed = speed
		updateSpeedText()
	end)
end

createSpeedButton("慢 30", 30, 8)
createSpeedButton("中 250", 250, 86)
createSpeedButton("快 500", 500, 164)
createSpeedButton("超快 1000", 1000, 242)

-- ===== 新增：可直接輸入的行走速度控制列 =====
local WalkFrame = Instance.new("Frame")
WalkFrame.Size = UDim2.new(1, -12, 0, 34)
WalkFrame.Position = UDim2.new(0, 6, 0, 112)
WalkFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
WalkFrame.BorderSizePixel = 0
WalkFrame.Parent = MainFrame
addCorner(WalkFrame, 8)

local WalkLabel = Instance.new("TextLabel")
WalkLabel.Size = UDim2.new(0, 82, 0, 26)
WalkLabel.Position = UDim2.new(0, 8, 0, 4)
WalkLabel.BackgroundTransparency = 1
WalkLabel.TextColor3 = Color3.new(1, 1, 1)
WalkLabel.TextSize = 14
WalkLabel.Font = Enum.Font.SourceSansBold
WalkLabel.TextXAlignment = Enum.TextXAlignment.Left
WalkLabel.Text = "行走速度"
WalkLabel.Parent = WalkFrame

local WalkInput = Instance.new("TextBox")
WalkInput.Size = UDim2.new(0, 68, 0, 26)
WalkInput.Position = UDim2.new(0, 92, 0, 4)
WalkInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WalkInput.TextColor3 = Color3.fromRGB(255, 255, 255)
WalkInput.TextSize = 15
WalkInput.Font = Enum.Font.SourceSansBold
WalkInput.Text = tostring(walkSpeed)
WalkInput.ClearTextOnFocus = false
WalkInput.Parent = WalkFrame
addCorner(WalkInput, 5)

local function makeWalkButton(label, x, width)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, 26)
    btn.Position = UDim2.new(0, x, 0, 4)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = label
    btn.Parent = WalkFrame
    addCorner(btn, 5)
    return btn
end

local WalkDown = makeWalkButton("-", 166, 32)
local WalkUp = makeWalkButton("+", 204, 32)
local WalkReset = makeWalkButton("預設 16", 242, 94)

local function refreshWalkInput()
    WalkInput.Text = tostring(walkSpeed)
end

WalkDown.MouseButton1Click:Connect(function()
    applyWalkSpeed(walkSpeed - 10)
    refreshWalkInput()
end)

WalkUp.MouseButton1Click:Connect(function()
    applyWalkSpeed(walkSpeed + 10)
    refreshWalkInput()
end)

WalkReset.MouseButton1Click:Connect(function()
    applyWalkSpeed(16)
    refreshWalkInput()
end)

WalkInput.FocusLost:Connect(function()
    applyWalkSpeed(WalkInput.Text) -- 非數字時保留原設定
    refreshWalkInput()
end)

applyWalkSpeed(walkSpeed)

-- ===== Hook 開關／真實移動速度診斷 =====
local HookFrame = Instance.new("Frame")
HookFrame.Size = UDim2.new(1, -12, 0, 32)
HookFrame.Position = UDim2.new(0, 6, 0, 150)
HookFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HookFrame.BorderSizePixel = 0
HookFrame.Parent = MainFrame
addCorner(HookFrame, 8)

local HookButton = Instance.new("TextButton")
HookButton.Size = UDim2.new(0, 90, 0, 26)
HookButton.Position = UDim2.new(0, 6, 0, 3)
HookButton.BackgroundColor3 = Color3.fromRGB(55, 88, 55)
HookButton.TextColor3 = Color3.new(1, 1, 1)
HookButton.TextSize = 13
HookButton.Font = Enum.Font.SourceSansBold
HookButton.Parent = HookFrame
addCorner(HookButton, 6)

local HookDetail = Instance.new("TextLabel")
HookDetail.Size = UDim2.new(1, -105, 1, 0)
HookDetail.Position = UDim2.new(0, 103, 0, 0)
HookDetail.BackgroundTransparency = 1
HookDetail.TextColor3 = Color3.fromRGB(210, 210, 210)
HookDetail.TextSize = 12
HookDetail.Font = Enum.Font.SourceSans
HookDetail.TextXAlignment = Enum.TextXAlignment.Left
HookDetail.Parent = HookFrame

-- Hook 預設常駐；狀態欄僅顯示，不再提供關閉按鈕。
local function refreshHookButton()
    if hookState.installed then
        hookState.enabled = true
        HookButton.Text = "Hook：常駐"
        HookButton.BackgroundColor3 = Color3.fromRGB(55, 88, 55)
    else
        HookButton.Text = "Hook 不支援"
        HookButton.BackgroundColor3 = Color3.fromRGB(85, 65, 65)
    end
    HookButton.AutoButtonColor = false
    HookButton.Active = false
end

refreshHookButton()

local diagnosticElapsed = 0
local lastDiagnosticPosition = nil
local diagnosticConnection = RunService.Heartbeat:Connect(function(dt)
    diagnosticElapsed += dt
    if diagnosticElapsed < 0.35 then return end
    local elapsed = diagnosticElapsed
    diagnosticElapsed = 0

    -- 當前角色如果被其他機制替換 Humanoid，重新監控；並定期確認速度設定。
    local currentCharacter = LocalPlayer.Character
    local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
    if currentHumanoid and currentHumanoid ~= walkHumanoid then
        task.defer(watchWalkHumanoid, currentCharacter)
    elseif currentHumanoid and math.abs(currentHumanoid.WalkSpeed - walkSpeed) >= 0.01 then
        -- 最多每 0.35 秒檢查並嘗試套用一次，避免高速寫入。
        currentHumanoid.WalkSpeed = walkSpeed
    end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        lastDiagnosticPosition = nil
        HookDetail.Text = "等待角色載入…"
        return
    end

    local p = root.Position
    local horizontalSpeed = 0
    if lastDiagnosticPosition then
        local diff = p - lastDiagnosticPosition
        horizontalSpeed = Vector3.new(diff.X, 0, diff.Z).Magnitude / elapsed
    end
    lastDiagnosticPosition = p
    if isFlying or isFollowingHead then
        HookDetail.Text = string.format("WalkSpeed %.0f | 正在飛行", humanoid.WalkSpeed)
    else
        HookDetail.Text = string.format(
            "屬性 %.0f / 實走 %.1f | 攔截 %d",
            humanoid.WalkSpeed, horizontalSpeed, hookState.blocked
        )
    end
end)
ScreenGui.Destroying:Connect(function()
    diagnosticConnection:Disconnect()
end)

-- ===== R6 血量顯示：玩家身旁直立血條 + HP 數字 + 頭頂名稱 =====
-- 以 R6 頭部、腿部的實際螢幕投影決定血條高度。
-- 遠處玩家變小時，血條也跟著變小；不會出現人小、血條反而很大的情形。
local healthVisible = true
local healthEnemyOnly = false  -- 預設所有其他玩家，不依 Team 排除
local healthDisplayDistance = 250 -- 最遠顯示距離 (studs)
local hpSide = 1                   -- 1 = 玩家畫面右側；-1 = 左側
local hpSideGap = 6                -- 血條離玩家身體的螢幕間隔 (px)
local hpBarWidthRatio = 0.070     -- 血條寬 / 人物投影高度
local hpShowOnlyR6 = false        -- 自己使用 R6 不代表其他玩家是 R6；預設支援兩者
local hpNameFontLimit = 16        -- 頭頂名字最大字體大小

-- 獨立的 2D ScreenGui，所有顯示座標都由世界座標投影而來。
local hpGuiName = "PlayerMarkerFlyLock_HP_Overlays"
local oldHPGui = UI_PARENT:FindFirstChild(hpGuiName)
if oldHPGui then oldHPGui:Destroy() end
local hpScreen = Instance.new("ScreenGui")
hpScreen.Name = hpGuiName
hpScreen.ResetOnSpawn = false
hpScreen.IgnoreGuiInset = true
hpScreen.DisplayOrder = 1
hpScreen.Parent = UI_PARENT
ScreenGui.DisplayOrder = 3

local HealthFrame = Instance.new("Frame")
HealthFrame.Name = "EnemyHealthControls"
HealthFrame.Size = UDim2.new(1, -12, 0, 38)
HealthFrame.Position = UDim2.new(0, 6, 0, 190)
HealthFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HealthFrame.BorderSizePixel = 0
HealthFrame.Parent = MainFrame
addCorner(HealthFrame, 8)

local HealthTitle = Instance.new("TextLabel")
HealthTitle.Size = UDim2.new(0, 86, 1, 0)
HealthTitle.Position = UDim2.new(0, 8, 0, 0)
HealthTitle.BackgroundTransparency = 1
HealthTitle.Text = "敵人血量"
HealthTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
HealthTitle.TextSize = 14
HealthTitle.Font = Enum.Font.SourceSansBold
HealthTitle.TextXAlignment = Enum.TextXAlignment.Left
HealthTitle.Parent = HealthFrame

local HealthToggle = Instance.new("TextButton")
HealthToggle.Size = UDim2.new(0, 76, 0, 27)
HealthToggle.Position = UDim2.new(0, 95, 0, 5)
HealthToggle.BackgroundColor3 = Color3.fromRGB(52, 104, 63)
HealthToggle.TextColor3 = Color3.new(1, 1, 1)
HealthToggle.TextSize = 13
HealthToggle.Font = Enum.Font.SourceSansBold
HealthToggle.Text = "顯示：開"
HealthToggle.Parent = HealthFrame
addCorner(HealthToggle, 6)

local HealthMode = Instance.new("TextButton")
HealthMode.Size = UDim2.new(0, 73, 0, 27)
HealthMode.Position = UDim2.new(0, 177, 0, 5)
HealthMode.BackgroundColor3 = Color3.fromRGB(55, 70, 94)
HealthMode.TextColor3 = Color3.new(1, 1, 1)
HealthMode.TextSize = 13
HealthMode.Font = Enum.Font.SourceSansBold
HealthMode.Text = "所有玩家"
HealthMode.Parent = HealthFrame
addCorner(HealthMode, 6)

local HealthCount = Instance.new("TextLabel")
HealthCount.Size = UDim2.new(1, -257, 1, 0)
HealthCount.Position = UDim2.new(0, 255, 0, 0)
HealthCount.BackgroundTransparency = 1
HealthCount.TextColor3 = Color3.fromRGB(190, 190, 190)
HealthCount.TextSize = 12
HealthCount.Font = Enum.Font.SourceSans
HealthCount.TextXAlignment = Enum.TextXAlignment.Center
HealthCount.Text = "可見 0/0"
HealthCount.Parent = HealthFrame

local hpVisuals = {}
local hpPlayerConnections = {}
local hpGlobalConnections = {}
local hpActive = true

local function hpTrack(connection)
    table.insert(hpGlobalConnections, connection)
    return connection
end

local hpLastVisibleCount = 0
local function hpUpdateCount(visibleCount)
    if visibleCount ~= nil then hpLastVisibleCount = visibleCount end
    local attached = 0
    for _, entry in pairs(hpVisuals) do
        if entry.barPanel and entry.barPanel.Parent then attached += 1 end
    end
    HealthCount.Text = string.format("可見 %d/%d", math.min(hpLastVisibleCount, attached), attached)
end

local function hpShouldShow(player)
    if not healthVisible or player == LocalPlayer then return false end
    if healthEnemyOnly and LocalPlayer.Team ~= nil and player.Team ~= nil
        and not LocalPlayer.Neutral and not player.Neutral
        and LocalPlayer.Team == player.Team then
        return false
    end
    return true
end

local function hpRemove(player)
    local entry = hpVisuals[player]
    if not entry then return end
    hpVisuals[player] = nil
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    if entry.barPanel then entry.barPanel:Destroy() end
    if entry.nameLabel then entry.nameLabel:Destroy() end
    hpUpdateCount()
end

local function hpAttach(player, character)
    if not hpActive or player.Character ~= character or not hpShouldShow(player) then
        hpRemove(player)
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("HumanoidRootPart")
    local leftLeg = character:FindFirstChild("Left Leg")
        or character:FindFirstChild("LeftFoot")
        or character:FindFirstChild("LeftLowerLeg")
    local rightLeg = character:FindFirstChild("Right Leg")
        or character:FindFirstChild("RightFoot")
        or character:FindFirstChild("RightLowerLeg")
    -- 角色尚未載入完成時，不要刪除既有血條，下一次維護會重試。
    if not humanoid or not head or not torso then return end
    if hpShowOnlyR6 and humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        hpRemove(player)
        return
    end
    local previous = hpVisuals[player]
    if previous and previous.humanoid == humanoid and previous.head == head
        and previous.torso == torso then
        return
    end
    hpRemove(player)

    -- 玩家頭上的名稱：獨立 UI，不會跟血條排在同一框中。
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name_" .. tostring(player.UserId)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeColor3 = Color3.fromRGB(14, 14, 18)
    nameLabel.TextStrokeTransparency = 0.20
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.TextScaled = false
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = player.DisplayName
    nameLabel.AnchorPoint = Vector2.new(0.5, 1)
    nameLabel.Size = UDim2.fromOffset(130, 20)
    nameLabel.Visible = false
    nameLabel.Parent = hpScreen

    -- 血條放在人物右側（hpSide = -1 時改放左側）。
    local barPanel = Instance.new("Frame")
    barPanel.Name = "VerticalHP_" .. tostring(player.UserId)
    barPanel.BackgroundTransparency = 1
    barPanel.BorderSizePixel = 0
    barPanel.AnchorPoint = Vector2.new(0, 0)
    barPanel.Size = UDim2.fromOffset(60, 80)
    barPanel.Visible = false
    barPanel.Parent = hpScreen

    local barBack = Instance.new("Frame")
    barBack.Name = "VerticalBackground"
    barBack.BackgroundColor3 = Color3.fromRGB(25, 29, 32)
    barBack.BorderSizePixel = 0
    barBack.ClipsDescendants = true
    barBack.Size = UDim2.fromOffset(9, 80)
    barBack.Position = UDim2.fromOffset(0, 0)
    barBack.Parent = barPanel
    addCorner(barBack, 4)

    local barFill = Instance.new("Frame")
    barFill.Name = "RemainingHP"
    barFill.AnchorPoint = Vector2.new(0, 1) -- 從底部往上填充
    barFill.Position = UDim2.new(0, 0, 1, 0)
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(55, 214, 95)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBack

    local hpNumber = Instance.new("TextLabel")
    hpNumber.Name = "HPNumber"
    hpNumber.BackgroundTransparency = 1
    hpNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpNumber.TextStrokeColor3 = Color3.fromRGB(10, 10, 10)
    hpNumber.TextStrokeTransparency = 0.15
    hpNumber.TextScaled = false
    hpNumber.TextSize = 12
    hpNumber.Font = Enum.Font.SourceSansBold
    hpNumber.TextXAlignment = Enum.TextXAlignment.Left
    hpNumber.Size = UDim2.fromOffset(49, 18)
    hpNumber.Position = UDim2.fromOffset(13, 0)
    hpNumber.Text = "100 HP"
    hpNumber.Parent = barPanel

    local entry = {
        barPanel = barPanel,
        nameLabel = nameLabel,
        barBack = barBack,
        hpNumber = hpNumber,
        head = head,
        torso = torso,
        leftLeg = leftLeg,
        rightLeg = rightLeg,
        humanoid = humanoid,
        connections = {},
    }
    hpVisuals[player] = entry

    local function updateHealth()
        if not hpActive or hpVisuals[player] ~= entry then return end
        local maximum = math.max(1, humanoid.MaxHealth)
        local amount = math.clamp(humanoid.Health, 0, maximum)
        local ratio = math.clamp(amount / maximum, 0, 1)
        hpNumber.Text = string.format("%d HP", math.ceil(amount))
        barFill.Size = UDim2.new(1, 0, ratio, 0)
        if ratio > 0.50 then
            barFill.BackgroundColor3 = Color3.fromRGB(55, 214, 95)
        elseif ratio > 0.25 then
            barFill.BackgroundColor3 = Color3.fromRGB(243, 189, 50)
        else
            barFill.BackgroundColor3 = Color3.fromRGB(234, 68, 63)
        end
    end
    table.insert(entry.connections, humanoid.HealthChanged:Connect(updateHealth))
    table.insert(entry.connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth))
    table.insert(entry.connections, player:GetPropertyChangedSignal("DisplayName"):Connect(function()
        nameLabel.Text = player.DisplayName
    end))
    updateHealth()
    hpUpdateCount()
end

local function hpRefresh()
    for player in pairs(hpVisuals) do hpRemove(player) end
    if not healthVisible then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            hpAttach(player, player.Character)
        end
    end
end

local function hpWatchPlayer(player)
    if player == LocalPlayer or hpPlayerConnections[player] then return end
    local connections = {}
    hpPlayerConnections[player] = connections
    local function watchCharacter(character)
        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 12)
            local head = character:WaitForChild("Head", 12)
            if not humanoid or not head then return end
            if hpShowOnlyR6 and humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end
            local torso = character:FindFirstChild("Torso")
                or character:FindFirstChild("UpperTorso")
                or character:FindFirstChild("HumanoidRootPart")
                or character:WaitForChild("HumanoidRootPart", 12)
            if torso and hpActive and player.Character == character then
                hpAttach(player, character)
            end
        end)
    end
    table.insert(connections, player.CharacterAdded:Connect(watchCharacter))
    table.insert(connections, player.CharacterRemoving:Connect(function()
        hpRemove(player)
    end))
    table.insert(connections, player:GetPropertyChangedSignal("Team"):Connect(hpRefresh))
    table.insert(connections, player:GetPropertyChangedSignal("Neutral"):Connect(hpRefresh))
    if player.Character then watchCharacter(player.Character) end
end

HealthToggle.MouseButton1Click:Connect(function()
    healthVisible = not healthVisible
    HealthToggle.Text = healthVisible and "顯示：開" or "顯示：關"
    HealthToggle.BackgroundColor3 = healthVisible
        and Color3.fromRGB(52, 104, 63) or Color3.fromRGB(99, 58, 58)
    hpRefresh()
end)

HealthMode.MouseButton1Click:Connect(function()
    healthEnemyOnly = not healthEnemyOnly
    HealthMode.Text = healthEnemyOnly and "只看敵隊" or "所有玩家"
    hpRefresh()
end)

hpTrack(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(hpRefresh))
hpTrack(LocalPlayer:GetPropertyChangedSignal("Neutral"):Connect(hpRefresh))
hpTrack(Players.PlayerAdded:Connect(hpWatchPlayer))
hpTrack(Players.PlayerRemoving:Connect(function(player)
    hpRemove(player)
    local connections = hpPlayerConnections[player]
    if connections then
        for _, connection in ipairs(connections) do connection:Disconnect() end
        hpPlayerConnections[player] = nil
    end
end))
for _, player in ipairs(Players:GetPlayers()) do hpWatchPlayer(player) end

-- 自動補抓已在線、晚載入及串流進入範圍的角色。
-- 只在沒有血條時嘗試建立，避免重複製作 UI 或反覆清除。
task.spawn(function()
    while hpActive do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local existing = hpVisuals[player]
                if not hpShouldShow(player) then
                    if existing then hpRemove(player) end
                elseif character and (not existing or existing.humanoid.Parent ~= character) then
                    hpAttach(player, character)
                elseif not character and existing then
                    hpRemove(player)
                end
            end
        end
        task.wait(1.5)
    end
end)

-- 人物頭頂到雙腳的投影高度決定血條高度；R6、R15 都使用相同比例。
local hpRenderConnection = RunService.RenderStepped:Connect(function()
    if not hpActive then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local ownRoot = getRootPart(LocalPlayer)
    local eyePosition = (ownRoot and ownRoot.Position) or camera.CFrame.Position
    local nowVisible = 0
    for player, entry in pairs(hpVisuals) do
        local panel, name = entry.barPanel, entry.nameLabel
        local head, torso = entry.head, entry.torso
        local humanoid = entry.humanoid
        if not healthVisible or not panel or not name or not head or not head.Parent
            or not torso or not torso.Parent or not humanoid or humanoid.Health <= 0 then
            if panel then panel.Visible = false end
            if name then name.Visible = false end
        else
            local topWorld = head.Position + Vector3.new(0, head.Size.Y * 0.5, 0)
            local leg = (entry.leftLeg and entry.leftLeg.Parent and entry.leftLeg)
                or (entry.rightLeg and entry.rightLeg.Parent and entry.rightLeg)
            local feetWorld
            if leg then
                feetWorld = leg.Position - Vector3.new(0, leg.Size.Y * 0.5, 0)
            else
                feetWorld = torso.Position - Vector3.new(0, 3, 0)
            end

            local topPoint, topVisible = camera:WorldToViewportPoint(topWorld)
            local bottomPoint = camera:WorldToViewportPoint(feetWorld)
            local torsoPoint = camera:WorldToViewportPoint(torso.Position)
            local distance = (eyePosition - torso.Position).Magnitude
            local figureHeight = math.abs(bottomPoint.Y - topPoint.Y)

            if topVisible and topPoint.Z > 0 and bottomPoint.Z > 0
                and distance <= healthDisplayDistance and figureHeight >= 16 then
                -- 不採用固定高度：血條與該名 R6 玩家在畫面的高度相同。
                local topY = math.min(topPoint.Y, bottomPoint.Y)
                local barHeight = math.floor(figureHeight + 0.5)
                local barWidth = math.clamp(math.floor(figureHeight * hpBarWidthRatio + 0.5), 4, 13)
                local playerHalfWidth = figureHeight * 0.22
                local barX = torsoPoint.X + (playerHalfWidth + hpSideGap) * hpSide
                if hpSide < 0 then barX -= (barWidth + 51) end
                panel.Position = UDim2.fromOffset(math.floor(barX + 0.5), math.floor(topY + 0.5))
                panel.Size = UDim2.fromOffset(barWidth + 53, barHeight)
                entry.barBack.Size = UDim2.fromOffset(barWidth, barHeight)
                entry.hpNumber.Position = UDim2.fromOffset(barWidth + 5, 0)
                entry.hpNumber.TextSize = math.clamp(math.floor(figureHeight * 0.16), 9, 13)
                panel.Visible = true
                nowVisible += 1

                local fontSize = math.clamp(math.floor(figureHeight * 0.16), 9, hpNameFontLimit)
                name.TextSize = fontSize
                name.Size = UDim2.fromOffset(math.clamp(math.floor(figureHeight * 1.75), 65, 175), fontSize + 5)
                name.Position = UDim2.fromOffset(math.floor(topPoint.X + 0.5), math.floor(topY - 5))
                name.Visible = true
            else
                panel.Visible = false
                name.Visible = false
            end
        end
    end
    if nowVisible ~= hpLastVisibleCount then
        hpUpdateCount(nowVisible)
    end
end)

ScreenGui.Destroying:Connect(function()
    hpActive = false
    hpRenderConnection:Disconnect()
    for _, connection in ipairs(hpGlobalConnections) do connection:Disconnect() end
    for player, connections in pairs(hpPlayerConnections) do
        for _, connection in ipairs(connections) do connection:Disconnect() end
        hpPlayerConnections[player] = nil
    end
    for player in pairs(hpVisuals) do hpRemove(player) end
    if hpScreen then hpScreen:Destroy() end
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 0, 26)
StatusLabel.Position = UDim2.new(0, 6, 1, -32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "選擇一個玩家"
StatusLabel.Parent = MainFrame

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -12, 1, -270)
PlayerList.Position = UDim2.new(0, 6, 0, 234)
PlayerList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlayerList.BorderSizePixel = 0

-- 啟用上下捲動
PlayerList.Active = true
PlayerList.ScrollingEnabled = true
PlayerList.ScrollingDirection = Enum.ScrollingDirection.Y
PlayerList.ScrollBarThickness = 6
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
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


local dragging = false
local dragStart
local startPos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)

TopBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local function createMarker(player)
	if currentMarker then
		currentMarker:Destroy()
		currentMarker = nil
	end

	local head = getHead(player)
	local root = getRootPart(player)

	if not head and not root then
		StatusLabel.Text = "找不到目標角色，無法標記"
		return
	end

	local marker = Instance.new("BillboardGui")
	marker.Name = "TargetMarker"
	marker.Size = UDim2.new(0, 150, 0, 45)
	marker.StudsOffset = Vector3.new(0, 3, 0)
	marker.AlwaysOnTop = true
	marker.Adornee = head or root
	marker.Parent = UI_PARENT

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

	if now - lastUseTime < cooldown then
		StatusLabel.Text = "請不要點太快"
		return false
	end

	lastUseTime = now
	return true
end

local function prepareMyCharacter()
	local character = LocalPlayer.Character
	if not character then
		StatusLabel.Text = "找不到你的角色"
		return nil, nil
	end

	local root = getRootPart(LocalPlayer)
	if not root then
		StatusLabel.Text = "找不到你的 HumanoidRootPart"
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Sit = false
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	return character, root
end

local function stopFollowingHead()
	isFollowingHead = false

	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
end

local function stopFlying()
	isFlying = false
	stopFollowingHead()
	StopButton.Text = "停止"
end

local function startFollowingHead(player)
	if not player or player == LocalPlayer then return end

	stopFollowingHead()

	isFollowingHead = true
	StopButton.Text = "停止"
	StatusLabel.Text = "已固定在 " .. player.Name .. " 頭上"

	followConnection = RunService.Heartbeat:Connect(function()
		if not isFollowingHead then
			stopFollowingHead()
			return
		end

		if not player or player.Parent ~= Players then
			stopFollowingHead()
			StatusLabel.Text = "目標玩家已離開"
			return
		end

		local myCharacter = LocalPlayer.Character
		local myRoot = getRootPart(LocalPlayer)
		local targetRoot = getRootPart(player)

		if not myCharacter or not myRoot or not targetRoot then
			stopFollowingHead()
			StatusLabel.Text = "固定失敗：找不到角色"
			return
		end

		local humanoid = myCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
		end

		myRoot.AssemblyLinearVelocity = Vector3.zero
		myRoot.AssemblyAngularVelocity = Vector3.zero

		local followPosition = targetRoot.Position + Vector3.new(0, flyHeight, 0)
		myCharacter:PivotTo(CFrame.new(followPosition))
	end)
end

local function teleportBesidePlayer(player)
	if not player or player == LocalPlayer then return end
	if not canUse() then return end

	local targetRoot = getRootPart(player)
	if not targetRoot then
		StatusLabel.Text = "找不到目標玩家角色"
		return
	end

	local myCharacter = prepareMyCharacter()
	if not myCharacter then return end

	stopFlying()

	myCharacter:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 4))
	StatusLabel.Text = "已 TP 到：" .. player.Name
end

local function flyAbovePlayer(player)
	if not player or player == LocalPlayer then return end
	if not canUse() then return end

	local myCharacter, myRoot = prepareMyCharacter()
	if not myCharacter or not myRoot then return end

	local targetRoot = getRootPart(player)
	if not targetRoot then
		StatusLabel.Text = "找不到目標玩家角色"
		return
	end

	stopFlying()
	task.wait()

	targetPlayer = player
	createMarker(player)

	isFlying = true
	StatusLabel.Text = "正在以速度 " .. flySpeed .. " 飛向：" .. player.Name

	task.spawn(function()
		local arrived = false

		while isFlying do
			local currentCharacter = LocalPlayer.Character
			local currentRoot = getRootPart(LocalPlayer)
			local targetRootNow = getRootPart(player)

			if not currentCharacter or not currentRoot or not targetRootNow then
				break
			end

			local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Sit = false
			end

			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentRoot.AssemblyAngularVelocity = Vector3.zero

			local targetPosition = targetRootNow.Position + Vector3.new(0, flyHeight, 0)
			local currentPosition = currentRoot.Position

			local direction = targetPosition - currentPosition
			local distance = direction.Magnitude

			if distance <= 1.2 then
				currentCharacter:PivotTo(CFrame.new(targetPosition))
				arrived = true

				if lockAfterArrive then
					isFlying = false
					startFollowingHead(player)
				else
					isFlying = false
					StatusLabel.Text = "已飛到 " .. player.Name .. " 頭上"
				end

				break
			end

			local dt = RunService.Heartbeat:Wait()
			local moveDistance = math.min(flySpeed * dt, distance)
			local newPosition = currentPosition + direction.Unit * moveDistance

			currentCharacter:PivotTo(CFrame.new(newPosition))
		end

		isFlying = false

		if not arrived and not isFollowingHead then
			if player and player.Parent == Players then
				StatusLabel.Text = "已停止飛行"
			else
				StatusLabel.Text = "目標玩家已離開"
			end
		end
	end)
end

SpeedDownButton.MouseButton1Click:Connect(function()
	flySpeed = flySpeed - 40
	updateSpeedText()
end)

SpeedUpButton.MouseButton1Click:Connect(function()
	flySpeed = flySpeed + 40
	updateSpeedText()
end)

LockButton.MouseButton1Click:Connect(function()
	lockAfterArrive = not lockAfterArrive

	if lockAfterArrive then
		LockButton.Text = "固定: 開"
		LockButton.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	else
		LockButton.Text = "固定: 關"
		LockButton.BackgroundColor3 = Color3.fromRGB(110, 70, 70)
	end
end)

StopButton.MouseButton1Click:Connect(function()
	stopFlying()
	StatusLabel.Text = "已停止飛行 / 固定"
end)

local function clearList()
	for _, child in ipairs(PlayerList:GetChildren()) do
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
	text.Parent = PlayerList
end

local function createPlayerRow(player)
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, -10, 0, 52)
	Row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Row.BorderSizePixel = 0
	Row.Parent = PlayerList
	addCorner(Row, 7)

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Size = UDim2.new(1, -195, 1, 0)
	NameLabel.Position = UDim2.new(0, 10, 0, 0)
	NameLabel.BackgroundTransparency = 1
	NameLabel.Text = player.Name
	NameLabel.TextColor3 = Color3.new(1, 1, 1)
	NameLabel.TextSize = 14
	NameLabel.Font = Enum.Font.SourceSansBold
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.Parent = Row

	local MarkButton = Instance.new("TextButton")
	MarkButton.Size = UDim2.new(0, 52, 0, 32)
	MarkButton.Position = UDim2.new(1, -174, 0.5, -16)
	MarkButton.BackgroundColor3 = Color3.fromRGB(60, 120, 160)
	MarkButton.TextColor3 = Color3.new(1, 1, 1)
	MarkButton.TextSize = 13
	MarkButton.Font = Enum.Font.SourceSansBold
	MarkButton.Text = "標記"
	MarkButton.Parent = Row
	addCorner(MarkButton, 6)

	local TpButton = Instance.new("TextButton")
	TpButton.Size = UDim2.new(0, 52, 0, 32)
	TpButton.Position = UDim2.new(1, -116, 0.5, -16)
	TpButton.BackgroundColor3 = Color3.fromRGB(70, 90, 160)
	TpButton.TextColor3 = Color3.new(1, 1, 1)
	TpButton.TextSize = 13
	TpButton.Font = Enum.Font.SourceSansBold
	TpButton.Text = "旁邊"
	TpButton.Parent = Row
	addCorner(TpButton, 6)

	local FlyButton = Instance.new("TextButton")
	FlyButton.Size = UDim2.new(0, 52, 0, 32)
	FlyButton.Position = UDim2.new(1, -58, 0.5, -16)
	FlyButton.BackgroundColor3 = Color3.fromRGB(90, 120, 70)
	FlyButton.TextColor3 = Color3.new(1, 1, 1)
	FlyButton.TextSize = 13
	FlyButton.Font = Enum.Font.SourceSansBold
	FlyButton.Text = "飛頭"
	FlyButton.Parent = Row
	addCorner(FlyButton, 6)

	MarkButton.MouseButton1Click:Connect(function()
		targetPlayer = player
		createMarker(player)
		StatusLabel.Text = "已標記：" .. player.Name
	end)

	TpButton.MouseButton1Click:Connect(function()
		targetPlayer = player
		createMarker(player)
		teleportBesidePlayer(player)
	end)

	FlyButton.MouseButton1Click:Connect(function()
		targetPlayer = player
		createMarker(player)
		flyAbovePlayer(player)
	end)
end

local function refreshPlayerList()
	clearList()

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

ToggleButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible

	if MainFrame.Visible then
		refreshPlayerList()
		StatusLabel.Text = "選擇一個玩家"
	end
end)

CloseButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
end)

RefreshButton.MouseButton1Click:Connect(function()
	refreshPlayerList()
	StatusLabel.Text = "已刷新玩家列表"
end)

Players.PlayerAdded:Connect(function()
	if MainFrame.Visible then
		refreshPlayerList()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if targetPlayer == player then
		targetPlayer = nil
		stopFlying()

		if currentMarker then
			currentMarker:Destroy()
			currentMarker = nil
		end

		StatusLabel.Text = "目標玩家已離開"
	end

	if MainFrame.Visible then
		task.delay(0.1, refreshPlayerList)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		MainFrame.Visible = not MainFrame.Visible

		if MainFrame.Visible then
			refreshPlayerList()
			StatusLabel.Text = "選擇一個玩家"
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if currentMarker and targetPlayer and targetPlayer.Character then
		local head = getHead(targetPlayer)
		local root = getRootPart(targetPlayer)

		if head then
			currentMarker.Adornee = head
		elseif root then
			currentMarker.Adornee = root
		end
	end
end)

refreshPlayerList()
