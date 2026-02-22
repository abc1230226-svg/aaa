-- 確保只在客戶端運行
if not game:GetService("RunService"):IsClient() then return end

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- 按鈕與輸入框
local toggleESP = Instance.new("TextButton")
toggleESP.Size = UDim2.new(0, 150, 0, 30)
toggleESP.Position = UDim2.new(0, 10, 0, 10)
toggleESP.Text = "切換ESP (OFF)"
toggleESP.Parent = ScreenGui

local toggleAim = Instance.new("TextButton")
toggleAim.Size = UDim2.new(0, 150, 0, 30)
toggleAim.Position = UDim2.new(0, 10, 0, 50)
toggleAim.Text = "切換自動瞄準 (OFF)"
toggleAim.Parent = ScreenGui

local autoFireBtn = Instance.new("TextButton")
autoFireBtn.Size = UDim2.new(0, 150, 0, 30)
autoFireBtn.Position = UDim2.new(0, 10, 0, 90)
autoFireBtn.Text = "按住左鍵自動爆頭"
autoFireBtn.Parent = ScreenGui

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(0, 180, 0, 30)
dropdownBtn.Position = UDim2.new(0, 10, 0, 130)
dropdownBtn.Text = "點擊展開不鎖玩家"
dropdownBtn.Parent = ScreenGui

local dropdownFrame = Instance.new("Frame")
dropdownFrame.Size = UDim2.new(0, 180, 0, 150)
dropdownFrame.Position = UDim2.new(0, 10, 0, 160)
dropdownFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
dropdownFrame.Visible = false
dropdownFrame.Parent = ScreenGui

-- 排除玩家列表（可手動添加或刪除）
local excludedPlayers = {}

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0, 120, 0, 30)
inputBox.Position = UDim2.new(0, 10, 0, 320)
inputBox.PlaceholderText = "輸入玩家名稱"
inputBox.Parent = ScreenGui

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(0, 60, 0, 30)
addButton.Position = UDim2.new(0, 140, 0, 320)
addButton.Text = "加入"
addButton.Parent = ScreenGui

local removeButton = Instance.new("TextButton")
removeButton.Size = UDim2.new(0, 60, 0, 30)
removeButton.Position = UDim2.new(0, 210, 0, 320)
removeButton.Text = "刪除"
removeButton.Parent = ScreenGui

-- 狀態變數
local espEnabled = false
local autoAim = false
local autoFiring = false
local aimRange = 150

-- 取得範圍內玩家
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

local function getEnemies()
    local enemies = {}
    local rangePlayers = getPlayersInRange(250, 300)
    for _, v in ipairs(rangePlayers) do
        if not table.find(excludedPlayers, v.Name) then
            if not (v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health <= 0) then
                table.insert(enemies, v)
            end
        end
    end
    return enemies
end

-- ESP
local espObjects = {}
local function createESP(player)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    box.Size = Vector3.new(2, 2, 1)
    box.Color3 = Color3.new(1, 0, 0)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Parent = player.Character
    return box
end

local function updateESP()
    if not espEnabled then
        for _, box in pairs(espObjects) do
            if box and box.Parent then box.Parent = nil end
        end
        espObjects = {}
        return
    end
    local enemies = getEnemies()
    -- 移除不存在的
    for playerName, box in pairs(espObjects) do
        if not table.find(enemies, Players:GetPlayerByName(playerName)) then
            if box and box.Parent then box.Parent = nil end
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

local function aimAt(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = target.Character.HumanoidRootPart
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
end

-- UI事件
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
    autoFireBtn.Text = autoFiring and "停止自動爆頭" or "按住左鍵自動爆頭"
end)

dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

-- 添加玩家到排除列表
addButton.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    if name ~= "" and not table.find(excludedPlayers, name) then
        table.insert(excludedPlayers, name)
        print("已加入排除：", name)
    end
end)

-- 從排除列表刪除玩家
removeButton.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    for i, v in ipairs(excludedPlayers) do
        if v == name then
            table.remove(excludedPlayers, i)
            print("已刪除排除：", name)
            break
        end
    end
end)

-- 自動射擊
local function autoShoot()
    if autoFiring then
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
