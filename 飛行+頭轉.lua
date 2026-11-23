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

-- ===== 射擊間隔 v2：提前監控 Backpack/Character，避免錯過裝備瞬間讀取 =====
-- 本功能只攔截 Roblox Instance 的 NumberValue/IntValue.Value 和 Attribute 讀取。
-- Lua 區域變數/ModuleScript table/伺服器槍械冷卻不在此 Hook 範圍。
local fireInterval = 0.10
local fireStateKey = "__fly_to_people_fire_hook_v2"
local fireState = hookEnv and hookEnv[fireStateKey] or nil
if type(fireState) ~= "table" then
    fireState = {
        enabled = true,
        interval = fireInterval,
        members = setmetatable({}, {__mode = "k"}),
        tool = nil,
        candidates = 0,
        readHits = 0,
        observedValueReads = 0,
        shotSignals = 0,
        indexInstalled = false,
        namecallInstalled = false,
    }
    if hookEnv then hookEnv[fireStateKey] = fireState end
end
fireState.enabled = true
fireState.interval = fireInterval
fireState.tool = nil
fireState.members = setmetatable({}, {__mode = "k"})
fireState.candidates = 0
fireState.readHits = 0
fireState.observedValueReads = 0
fireState.shotSignals = 0

local fireConnections = {}
local registeredFireTools = setmetatable({}, {__mode = "k"})
local function addFireConnection(conn)
    table.insert(fireConnections, conn)
    return conn
end

local intervalKeys = {
    firedelay=true, fireinterval=true, shotdelay=true, shotinterval=true,
    shootdelay=true, shootinterval=true, timebetweenshots=true,
    shotcooldown=true, shootcooldown=true, firecooldown=true,
    weaponcooldown=true, bulletsdelay=true, attackdelay=true,
    attackinterval=true, firewait=true,
}
local rpmKeys = {rpm=true, roundsperminute=true}
local perSecondKeys = {shotspersecond=true, roundspersecond=true, shotspersec=true}
local ambiguousKeys = {firerate=true, shootrate=true, rateoffire=true}

local function normalizeFireKey(key)
    if type(key) ~= "string" then return nil end
    return (string.lower(key):gsub("[^%w]", ""))
end

local function fireValueFor(key, original)
    if type(original) ~= "number" or original ~= original then return nil end
    local name = normalizeFireKey(key)
    if not name then return nil end
    local interval = fireState.interval
    if intervalKeys[name] then
        return interval
    elseif rpmKeys[name] then
        return 60 / interval
    elseif perSecondKeys[name] then
        return 1 / interval
    elseif ambiguousKeys[name] then
        -- FireRate 不是 Roblox 標準單位，各遊戲可能有不同定義
        if original >= 30 then return 60 / interval end
        if original >= 2 then return 1 / interval end
        return interval
    end
    return nil
end

local function registerFireTool(tool)
    if not tool or not tool:IsA("Tool") or registeredFireTools[tool] then return end
    registeredFireTools[tool] = true

    local function remember(inst)
        fireState.members[inst] = true
    end
    remember(tool)
    for _, descendant in ipairs(tool:GetDescendants()) do
        remember(descendant)
    end
    addFireConnection(tool.DescendantAdded:Connect(remember))
    addFireConnection(tool.Activated:Connect(function()
        if LocalPlayer.Character and tool.Parent == LocalPlayer.Character then
            fireState.shotSignals += 1
        end
    end))
    -- 預先處理 Backpack 內的槍，裝備瞬間不必等 0.6 秒才登記
end

local function registerFireContainer(container)
    if not container then return end
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Tool") then registerFireTool(child) end
    end
    addFireConnection(container.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            registerFireTool(child)
        end
    end))
end

local function refreshEquippedFireTool()
    local character = LocalPlayer.Character
    local tool = character and character:FindFirstChildOfClass("Tool")
    if tool then registerFireTool(tool) end
    if tool == fireState.tool then return end
    fireState.tool = tool
    fireState.candidates = 0
    if not tool then return end

    local function countCandidate(inst)
        if inst:IsA("NumberValue") or inst:IsA("IntValue") then
            if fireValueFor(inst.Name, inst.Value) ~= nil then
                fireState.candidates += 1
            end
        end
        for attrName, value in pairs(inst:GetAttributes()) do
            if fireValueFor(attrName, value) ~= nil then
                fireState.candidates += 1
            end
        end
    end
    countCandidate(tool)
    for _, descendant in ipairs(tool:GetDescendants()) do
        countCandidate(descendant)
    end
    print("[射擊間隔診斷] 已裝備：" .. tool.Name .. "; 可辨識欄位：" .. fireState.candidates)
end

local function isOtherLocalScript()
    if type(checkcaller) ~= "function" then return true end
    local ok, own = pcall(checkcaller)
    return not (ok and own == true)
end

local function installFireIntervalHooks()
    if type(hookmetamethod) ~= "function" then
        warn("[射擊間隔] 執行環境沒有 hookmetamethod")
        return
    end
    if not fireState.indexInstalled then
        local oldIndex
        local function indexed(self, property)
            if fireState.members[self] and property == "Value" and isOtherLocalScript() then
                fireState.observedValueReads += 1
                if fireState.enabled then
                    local original = oldIndex(self, property)
                    local name = oldIndex(self, "Name")
                    local changed = fireValueFor(name, original)
                    if changed ~= nil then
                        fireState.readHits += 1
                        return changed
                    end
                    return original
                end
            end
            return oldIndex(self, property)
        end
        local replacement = indexed
        if type(newcclosure) == "function" then
            local ok, val = pcall(newcclosure, indexed)
            if ok then replacement = val end
        end
        local ok, old = pcall(function()
            return hookmetamethod(game, "__index", replacement)
        end)
        if ok and type(old) == "function" then
            oldIndex = old
            fireState.indexInstalled = true
        else
            warn("[射擊間隔] __index Hook 安裝失敗", old)
        end
    end

    if not fireState.namecallInstalled and type(getnamecallmethod) == "function" then
        local oldNamecall
        local function named(self, ...)
            if fireState.members[self] and fireState.enabled and isOtherLocalScript() then
                local method = getnamecallmethod()
                if method == "GetAttribute" then
                    local name = select(1, ...)
                    if type(name) == "string" then
                        local original = oldNamecall(self, ...)
                        local changed = fireValueFor(name, original)
                        if changed ~= nil then
                            fireState.readHits += 1
                            return changed
                        end
                        return original
                    end
                elseif method == "GetAttributes" then
                    local all = oldNamecall(self, ...)
                    if type(all) == "table" then
                        for name, original in pairs(all) do
                            local changed = fireValueFor(name, original)
                            if changed ~= nil then
                                all[name] = changed
                                fireState.readHits += 1
                            end
                        end
                    end
                    return all
                end
            end
            return oldNamecall(self, ...)
        end
        local replacement = named
        if type(newcclosure) == "function" then
            local ok, val = pcall(newcclosure, named)
            if ok then replacement = val end
        end
        local ok, old = pcall(function()
            return hookmetamethod(game, "__namecall", replacement)
        end)
        if ok and type(old) == "function" then
            oldNamecall = old
            fireState.namecallInstalled = true
        else
            warn("[射擊間隔] __namecall Hook 安裝失敗", old)
        end
    end
    print("[射擊間隔] v2 已安裝；會預先登記背包內 Tool，以免錯過剛裝備時的讀取")
end

-- 在安裝 Hook 前先把既有 Tool 登記好
local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
if backpack then registerFireContainer(backpack) end
addFireConnection(LocalPlayer.ChildAdded:Connect(function(child)
    if child:IsA("Backpack") then registerFireContainer(child) end
end))
if LocalPlayer.Character then registerFireContainer(LocalPlayer.Character) end
addFireConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    registerFireContainer(character)
    task.defer(refreshEquippedFireTool)
end))
installFireIntervalHooks()
refreshEquippedFireTool()

local function reportFireDiagnostics()
    refreshEquippedFireTool()
    local tool = fireState.tool
    if not tool then
        warn("[射擊間隔診斷] 角色未裝備 Roblox Tool；若是自訂武器系統，這版無法自動識別其冷卻設定")
        return
    end
    print("[射擊間隔診斷] 武器：", tool.Name,
        "候選欄位：", fireState.candidates,
        "攔截讀取：", fireState.readHits,
        "觀察 Value 讀取：", fireState.observedValueReads,
        "Tool.Activated 事件：", fireState.shotSignals)
    local moduleCount = 0
    local scripts = 0
    local paths = {}
    local function inspect(inst)
        if inst:IsA("ModuleScript") then moduleCount += 1 end
        if inst:IsA("LocalScript") then scripts += 1 end
        if inst:IsA("NumberValue") or inst:IsA("IntValue") then
            local value = inst.Value
            if fireValueFor(inst.Name, value) ~= nil then
                table.insert(paths, inst:GetFullName() .. ".Value = " .. tostring(value))
            end
        end
        for name, value in pairs(inst:GetAttributes()) do
            if fireValueFor(name, value) ~= nil then
                table.insert(paths, inst:GetFullName() .. " [" .. name .. "] = " .. tostring(value))
            end
        end
    end
    inspect(tool)
    for _, inst in ipairs(tool:GetDescendants()) do inspect(inst) end
    print("[射擊間隔診斷] ModuleScript 數量：", moduleCount, "LocalScript 數量：", scripts)
    if #paths == 0 then
        warn("[射擊間隔診斷] 沒有找到可辨識的射速欄位，可能使用 ModuleScript table、區域變數或伺服器計時")
    else
        for i = 1, math.min(#paths, 30) do
            print("[射擊間隔診斷] 欄位", i, paths[i])
        end
    end
end

ScreenGui.Destroying:Connect(function()
    fireState.enabled = false
    for _, conn in ipairs(fireConnections) do conn:Disconnect() end
    table.clear(fireConnections)
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

-- ===== 新增：射擊間隔控制列（僅客戶端槍械設定） =====
local FireFrame = Instance.new("Frame")
FireFrame.Size = UDim2.new(1, -12, 0, 78)
FireFrame.Position = UDim2.new(0, 6, 0, 186)
FireFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FireFrame.BorderSizePixel = 0
FireFrame.Parent = MainFrame
addCorner(FireFrame, 8)

local FireLabel = Instance.new("TextLabel")
FireLabel.Size = UDim2.new(0, 74, 0, 26)
FireLabel.Position = UDim2.new(0, 8, 0, 4)
FireLabel.BackgroundTransparency = 1
FireLabel.TextColor3 = Color3.new(1, 1, 1)
FireLabel.Font = Enum.Font.SourceSansBold
FireLabel.TextSize = 13
FireLabel.TextXAlignment = Enum.TextXAlignment.Left
FireLabel.Text = "射擊間隔"
FireLabel.Parent = FireFrame

local FireInput = Instance.new("TextBox")
FireInput.Size = UDim2.new(0, 63, 0, 26)
FireInput.Position = UDim2.new(0, 83, 0, 4)
FireInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FireInput.TextColor3 = Color3.new(1, 1, 1)
FireInput.Font = Enum.Font.SourceSansBold
FireInput.TextSize = 14
FireInput.Text = string.format("%.2f", fireInterval)
FireInput.ClearTextOnFocus = false
FireInput.Parent = FireFrame
addCorner(FireInput, 5)

local function fireButton(text, x, width)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, width, 0, 26)
    button.Position = UDim2.new(0, x, 0, 4)
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.SourceSansBold
    button.Text = text
    button.Parent = FireFrame
    addCorner(button, 5)
    return button
end

local FireDown = fireButton("−", 152, 29)
local FireUp = fireButton("＋", 185, 29)
local FireToggle = fireButton("攔截：開", 218, 73)
local FireReset = fireButton("0.10", 295, 46)

local FireDetail = Instance.new("TextLabel")
FireDetail.Size = UDim2.new(1, -14, 0, 18)
FireDetail.Position = UDim2.new(0, 8, 0, 35)
FireDetail.BackgroundTransparency = 1
FireDetail.TextColor3 = Color3.fromRGB(200, 200, 200)
FireDetail.TextSize = 11
FireDetail.Font = Enum.Font.SourceSans
FireDetail.TextXAlignment = Enum.TextXAlignment.Left
FireDetail.Text = "先裝備槍，再測試開火..."
FireDetail.Parent = FireFrame

local FireStatus = Instance.new("TextLabel")
FireStatus.Size = UDim2.new(1, -83, 0, 21)
FireStatus.Position = UDim2.new(0, 8, 0, 54)
FireStatus.BackgroundTransparency = 1
FireStatus.TextColor3 = Color3.fromRGB(190, 190, 190)
FireStatus.TextSize = 11
FireStatus.Font = Enum.Font.SourceSans
FireStatus.TextXAlignment = Enum.TextXAlignment.Left
FireStatus.Text = "檢查是否為 Tool/ModuleScript/伺服器冷卻"
FireStatus.Parent = FireFrame

local DiagnoseFire = fireButton("診斷", 288, 52)
DiagnoseFire.Position = UDim2.new(0, 288, 0, 51)
DiagnoseFire.MouseButton1Click:Connect(reportFireDiagnostics)

local function updateFireInterval(newValue)
    local n = tonumber(newValue)
    if not n or n ~= n or n == math.huge or n == -math.huge then return end
    fireInterval = math.clamp(math.floor(n * 1000 + 0.5) / 1000, 0.01, 5)
    fireState.interval = fireInterval
    FireInput.Text = string.format("%.3f", fireInterval)
end

FireInput.FocusLost:Connect(function()
    updateFireInterval(FireInput.Text)
    FireInput.Text = string.format("%.3f", fireInterval)
end)
FireDown.MouseButton1Click:Connect(function()
    updateFireInterval(fireInterval - 0.01)
end)
FireUp.MouseButton1Click:Connect(function()
    updateFireInterval(fireInterval + 0.01)
end)
FireReset.MouseButton1Click:Connect(function()
    updateFireInterval(0.10)
end)
FireToggle.MouseButton1Click:Connect(function()
    fireState.enabled = not fireState.enabled
    FireToggle.Text = fireState.enabled and "攔截：開" or "攔截：關"
    FireToggle.BackgroundColor3 = fireState.enabled
        and Color3.fromRGB(55, 88, 55) or Color3.fromRGB(90, 60, 60)
end)

local fireStatusElapsed = 0
local fireStatusConnection = RunService.Heartbeat:Connect(function(dt)
    fireStatusElapsed += dt
    if fireStatusElapsed < 0.4 then return end
    fireStatusElapsed = 0
    refreshEquippedFireTool()
    if not fireState.indexInstalled and not fireState.namecallInstalled then
        FireDetail.Text = "未安裝 Hook：執行環境不支援"
        FireStatus.Text = "此功能無法運作"
    elseif not fireState.tool then
        FireDetail.Text = "目前沒有偵測到裝備的 Tool"
        FireStatus.Text = "若你拿著槍，可能是自訂武器系統"
    else
        FireDetail.Text = string.format("%s｜欄位 %d｜攔截 %d",
            fireState.tool.Name, fireState.candidates, fireState.readHits)
        FireStatus.Text = string.format("開火事件 %d｜Value讀取 %d",
            fireState.shotSignals, fireState.observedValueReads)
    end
end)
ScreenGui.Destroying:Connect(function()
    fireStatusConnection:Disconnect()
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
PlayerList.Size = UDim2.new(1, -12, 1, -314)
PlayerList.Position = UDim2.new(0, 6, 0, 278)
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
