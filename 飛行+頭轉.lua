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
MainFrame.Size = UDim2.new(0, 360, 0, 360)
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


local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 0, 26)
StatusLabel.Position = UDim2.new(0, 6, 1, -32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Text = "選擇一個玩家"
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Size = UDim2.new(1, -142, 0, 26)
StatusLabel.Parent = MainFrame

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -12, 1, -150)
PlayerList.Position = UDim2.new(0, 6, 0, 114)
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


-- 新增：四肢繞頭（用戶端外觀；若遊戲安裝配套伺服器程式則會同步其他玩家）
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local orbitRadius = 1.8          -- 四肢繞頭半徑（studs）
local orbitSpeed = 1080         -- 繞頭速度（度／秒）
local orbitWobble = 0.75        -- 上下亂繞的幅度
local limbSelfSpin = 1440       -- 四肢自轉速度（度／秒）

local OrbitButton = Instance.new("TextButton")
OrbitButton.Name = "LimbOrbitToggle"
OrbitButton.Size = UDim2.new(0, 124, 0, 26)
OrbitButton.Position = UDim2.new(1, -130, 1, -32)
OrbitButton.BackgroundColor3 = Color3.fromRGB(70, 70, 95)
OrbitButton.TextColor3 = Color3.new(1, 1, 1)
OrbitButton.TextSize = 12
OrbitButton.Font = Enum.Font.SourceSansBold
OrbitButton.Text = "四肢繞頭：關"
OrbitButton.Parent = MainFrame
addCorner(OrbitButton, 6)

-- ===== 四肢圍繞頭部的視覺效果（R6 / R15） =====
-- 與物理角色分開：克隆手腳來旋轉，原始關節完全不拆除。
local LIMB_GROUPS = {
    {"LeftUpperArm", "LeftLowerArm", "LeftHand"},
    {"RightUpperArm", "RightLowerArm", "RightHand"},
    {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    {"RightUpperLeg", "RightLowerLeg", "RightFoot"},
}
local LIMB_GROUPS_R6 = {
    {"Left Arm"},
    {"Right Arm"},
    {"Left Leg"},
    {"Right Leg"},
}

local function makeOrbitVisual(original)
    local previousArchivable = original.Archivable
    original.Archivable = true
    local ok, clone = pcall(function() return original:Clone() end)
    original.Archivable = previousArchivable
    if not ok or not clone then
        clone = Instance.new("Part")
        clone.Size = original.Size
        clone.Color = original.Color
        clone.Material = original.Material
    end
    -- 不複製關節、碰撞與執行程式。
    for _, child in ipairs(clone:GetDescendants()) do
        if child:IsA("JointInstance") or child:IsA("Constraint")
            or child:IsA("Script") or child:IsA("LocalScript")
            or child:IsA("ModuleScript") or child:IsA("BodyMover")
            or child:IsA("Sound") then
            child:Destroy()
        end
    end
    clone.Name = "Orbit_" .. original.Name
    clone.Anchored = true
    clone.CanCollide = false
    clone.CanTouch = false
    clone.CanQuery = false
    clone.CastShadow = false
    clone.Massless = true
    clone.LocalTransparencyModifier = 0
    return clone
end

local function orbitPose(headCF, groupIndex, elapsed, radius, speedDegrees, wobble, selfSpinDegrees)
    local phase = (groupIndex - 1) * (math.pi / 2)
    local direction = (groupIndex % 2 == 0) and -1 or 1
    local angle = phase + math.rad(speedDegrees) * elapsed * direction * (0.84 + groupIndex * 0.055)
    local varyingRadius = radius + 0.25 * math.sin(elapsed * 5.3 + phase)
    local x = math.cos(angle) * varyingRadius
    local y = math.sin(angle * 1.27 + phase) * wobble
    local z = math.sin(angle) * varyingRadius
    local twist = math.rad(selfSpinDegrees) * elapsed * (groupIndex % 2 == 0 and 1 or -1)
    return headCF * CFrame.new(x, y, z)
        * CFrame.Angles(twist * 0.65, twist, twist * 0.39)
end

-- 每組由 1 個（R6）或 3 個（R15）肢體零件組成。
local function constructOrbit(character, parentFolder, hideLocally)
    local head = character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return nil end

    local names = character:FindFirstChild("LeftUpperArm") and LIMB_GROUPS or LIMB_GROUPS_R6
    local data = {character=character, head=head, folder=parentFolder, groups={}, hidden={}}

    for index, limbNames in ipairs(names) do
        local originalParts = {}
        for _, name in ipairs(limbNames) do
            local part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                table.insert(originalParts, part)
            end
        end
        if #originalParts > 0 then
            local firstCF = originalParts[1].CFrame
            local group = {index=index, segments={}}
            for _, original in ipairs(originalParts) do
                local clone = makeOrbitVisual(original)
                clone.CFrame = original.CFrame
                clone.Parent = parentFolder
                table.insert(group.segments, {
                    part = clone,
                    relative = firstCF:ToObjectSpace(original.CFrame)
                })
                if data.hidden[original] == nil then
                    data.hidden[original] = hideLocally
                        and original.LocalTransparencyModifier or original.Transparency
                    if hideLocally then
                        original.LocalTransparencyModifier = 1
                    else
                        original.Transparency = 1
                    end
                end
            end
            table.insert(data.groups, group)
        end
    end

    -- 身體在視覺上消失，留下中央的頭與繞頭的四肢。
    for _, name in ipairs({"Torso", "UpperTorso", "LowerTorso"}) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") and data.hidden[part] == nil then
            data.hidden[part] = hideLocally
                and part.LocalTransparencyModifier or part.Transparency
            if hideLocally then
                part.LocalTransparencyModifier = 1
            else
                part.Transparency = 1
            end
        end
    end

    if #data.groups == 0 then
        for part, oldValue in pairs(data.hidden) do
            if part and part.Parent then
                if hideLocally then
                    part.LocalTransparencyModifier = oldValue
                else
                    part.Transparency = oldValue
                end
            end
        end
        return nil
    end
    return data
end

local function renderOrbit(data, elapsed, radius, speedDegrees, wobble, selfSpinDegrees)
    if not data or not data.head or not data.head.Parent then return false end
    local headCF = data.head.CFrame
    for _, group in ipairs(data.groups) do
        local pivot = orbitPose(headCF, group.index, elapsed, radius, speedDegrees, wobble, selfSpinDegrees)
        for _, segment in ipairs(group.segments) do
            if segment.part.Parent then
                segment.part.CFrame = pivot * segment.relative
            end
        end
    end
    return true
end

local function destroyOrbit(data, hideLocally)
    if not data then return end
    for part, oldValue in pairs(data.hidden) do
        if part and part.Parent then
            if hideLocally then
                part.LocalTransparencyModifier = oldValue
            else
                part.Transparency = oldValue
            end
        end
    end
    if data.folder then data.folder:Destroy() end
end

local orbitEnabled = false
local orbitConnection = nil
local orbitData = nil
local orbitElapsed = 0
local usingServerOrbit = false

local function showOrbitState(enabled)
    OrbitButton.Text = enabled and "四肢繞頭：開" or "四肢繞頭：關"
    OrbitButton.BackgroundColor3 = enabled
        and Color3.fromRGB(50, 125, 75)
        or Color3.fromRGB(70, 70, 95)
end

local function stopLocalOrbit()
    if orbitConnection then
        orbitConnection:Disconnect()
        orbitConnection = nil
    end
    destroyOrbit(orbitData, true)
    orbitData = nil
end

local function attachLocalOrbit(character)
    destroyOrbit(orbitData, true)
    orbitData = nil
    if not character or not character:FindFirstChild("Head") then return false end
    local folder = Instance.new("Folder")
    folder.Name = "LocalLimbOrbitVisuals"
    folder.Parent = workspace
    orbitData = constructOrbit(character, folder, true)
    if not orbitData then
        folder:Destroy()
        return false
    end
    return true
end

local function startLocalOrbit()
    if orbitConnection then return true end
    if not attachLocalOrbit(LocalPlayer.Character) then
        StatusLabel.Text = "找不到四肢；請確認角色已載入"
        return false
    end
    orbitElapsed = 0
    orbitConnection = RunService.RenderStepped:Connect(function(dt)
        if not orbitEnabled then return end
        if not orbitData or LocalPlayer.Character ~= orbitData.character then
            if not attachLocalOrbit(LocalPlayer.Character) then return end
        end
        orbitElapsed += math.min(dt, 0.1)
        renderOrbit(orbitData, orbitElapsed, orbitRadius, orbitSpeed, orbitWobble, limbSelfSpin)
    end)
    return true
end

local serverOrbitEvent = ReplicatedStorage:FindFirstChild("LimbOrbitToggleEvent")
if serverOrbitEvent and (not serverOrbitEvent:IsA("RemoteEvent")
    or serverOrbitEvent:GetAttribute("LimbOrbitServerReady") ~= true) then
    serverOrbitEvent = nil
end

if serverOrbitEvent then
    serverOrbitEvent.OnClientEvent:Connect(function(enabled, success, message)
        if not success then
            orbitEnabled = false
        else
            orbitEnabled = enabled
        end
        showOrbitState(orbitEnabled)
        if type(message) == "string" then StatusLabel.Text = message end
    end)
end

OrbitButton.MouseButton1Click:Connect(function()
    local desired = not orbitEnabled
    if serverOrbitEvent and serverOrbitEvent.Parent == ReplicatedStorage then
        -- 僅在遊戲擁有伺服器配套程式時能讓其他玩家一起看到。
        usingServerOrbit = true
        stopLocalOrbit()
        serverOrbitEvent:FireServer(desired)
        StatusLabel.Text = "已送出外觀切換請求"
        return
    end

    usingServerOrbit = false
    if desired then
        orbitEnabled = true
        if not startLocalOrbit() then
            orbitEnabled = false
            return
        end
        StatusLabel.Text = "四肢繞頭已開啟（僅自己可見）"
    else
        orbitEnabled = false
        stopLocalOrbit()
        StatusLabel.Text = "四肢繞頭已關閉"
    end
    showOrbitState(orbitEnabled)
end)

ScreenGui.Destroying:Connect(function()
    if usingServerOrbit and serverOrbitEvent and serverOrbitEvent.Parent then
        serverOrbitEvent:FireServer(false)
    end
    orbitEnabled = false
    stopLocalOrbit()
end)

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
