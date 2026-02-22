-- 完整AimAssist腳本（範圍250~300 studs，包含ESP和自動瞄準）

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local buttonWidth, buttonHeight, spacing = 150, 30, 10
local startX, startY = 10, 10

-- 按鈕設定
local toggleESP = Instance.new("TextButton")
toggleESP.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
toggleESP.Position = UDim2.new(0, startX, 0, startY)
toggleESP.Text = "切換ESP (OFF)"
toggleESP.Parent = ScreenGui

local toggleAim = Instance.new("TextButton")
toggleAim.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
toggleAim.Position = UDim2.new(0, startX, 0, startY + buttonHeight + spacing)
toggleAim.Text = "切換自動瞄準 (OFF)"
toggleAim.Parent = ScreenGui

local autoFireBtn = Instance.new("TextButton")
autoFireBtn.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
autoFireBtn.Position = UDim2.new(0, startX, 0, startY + 2*(buttonHeight + spacing))
autoFireBtn.Text = "按住左鍵自動爆頭"
autoFireBtn.Parent = ScreenGui

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(0, 180, 0, 30)
dropdownBtn.Position = UDim2.new(0, startX, 0, startY + 3*(buttonHeight + spacing))
dropdownBtn.Text = "點擊展開不鎖玩家"
dropdownBtn.Parent = ScreenGui

local dropdownFrame = Instance.new("Frame")
dropdownFrame.Size = UDim2.new(0, 180, 0, 150)
dropdownFrame.Position = UDim2.new(0, startX, 0, startY + 3*(buttonHeight + spacing) + 30)
dropdownFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
dropdownFrame.Visible = false
dropdownFrame.Parent = ScreenGui

-- 變數
local espEnabled = false
local autoAim = false
local autoFiring = false
local aimRange = 150
local excludedPlayers = {}

-- 範圍設定
local minDistance = 250
local maxDistance = 300

-- 獲取範圍內玩家（距離在250-300之間）
local function getPlayersInRange(minD, maxD)
    local playersInRange = {}
    local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return playersInRange end
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (v.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
            if dist >= minD and dist <= maxD then
                table.insert(playersInRange, v)
            end
        end
    end
    return playersInRange
end

-- 取得範圍內的玩家（包括敵人和隊友）
local function getEnemies()
    local enemies = {}
    local rangePlayers = getPlayersInRange(minDistance, maxDistance)
    for _, v in ipairs(rangePlayers) do
        if not table.find(excludedPlayers, v.Name) then
            if not (v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health <= 0) then
                table.insert(enemies, v)
            end
        end
    end
    return enemies
end

-- 建立ESP框
local function createESP(player)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = player.Character:FindFirstChild("HumanoidRootPart")
    box.Size = Vector3.new(2, 2, 1)
    box.Color3 = Color3.new(1, 0, 0)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Parent = player.Character
    return box
end

local espObjects = {}

-- 更新ESP
local function updateESP()
    if not espEnabled then
        for _, box in pairs(espObjects) do
            if box and box.Parent then
                box.Parent = nil
            end
        end
        espObjects = {}
        return
    end
    local enemies = getEnemies()
    -- 移除不存在的
    for playerName, box in pairs(espObjects) do
        if not table.find(enemies, Players:GetPlayerByName(playerName)) then
            if box and box.Parent then
                box.Parent = nil
            end
            espObjects[playerName] = nil
        end
    end
    -- 添加或更新
    for _, v in ipairs(enemies) do
        if not espObjects[v.Name] then
            local box = createESP(v)
            espObjects[v.Name] = box
        end
    end
end

-- 自動瞄準
local function getClosestEnemy()
    local enemies = getEnemies()
    local closestPlayer = nil
    local closestDist = math.huge
    local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end
    for _, v in ipairs(enemies) do
        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (v.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
            if dist < closestDist and dist <= aimRange then
                closestDist = dist
                closestPlayer = v
            end
        end
    end
    return closestPlayer
end

-- 自動瞄準角度
local function aimAt(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = target.Character.HumanoidRootPart
    local camCFrame = Camera.CFrame
    local targetDirection = (hrp.Position - camCFrame.Position).unit
    local newCF = CFrame.lookAt(camCFrame.Position, hrp.Position)
    Camera.CFrame = CFrame.new(camCFrame.Position, hrp.Position)
end

-- 按鈕事件
toggleESP.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleESP.Text = "切換ESP (" .. (espEnabled and "ON" or "OFF") .. ")"
end)

toggleAim.MouseButton1Click:Connect(function()
    autoAim = not autoAim
    toggleAim.Text = "切換自動瞄準 (" .. (autoAim and "ON" or "OFF") .. ")"
end)

autoFireBtn.MouseButton1Click:Connect(function()
    autoFiring = not autoFiring
    autoFireBtn.Text = (autoFiring and "停止自動爆頭" or "按住左鍵自動爆頭")
end)

dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

-- 自動射擊（模擬點擊）
local function autoShoot()
    if autoFiring then
        -- 模擬左鍵點擊
        UserInputService:SetKeyDown(Enum.UserInputType.MouseButton1)
        wait(0.05)
        UserInputService:SetKeyUp(Enum.UserInputType.MouseButton1)
    end
end

-- 主循環
RunService.RenderStepped:Connect(function()
    updateESP()

    if autoAim then
        local target = getClosestEnemy()
        if target then
            aimAt(target)
        end
    end

    autoShoot()
end)
