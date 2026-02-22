-- 取得服務
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 建立UI界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") -- 使用 PlayerGui

-- UI按鈕尺寸和位置
local buttonWidth, buttonHeight, spacing = 150, 30, 10
local startX, startY = 10, 10

-- 切換ESP按鈕
local toggleESP = Instance.new("TextButton")
toggleESP.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
toggleESP.Position = UDim2.new(0, startX, 0, startY)
toggleESP.Text = "切換ESP (OFF)"
toggleESP.Parent = ScreenGui

-- 切換自動瞄準按鈕
local toggleAim = Instance.new("TextButton")
toggleAim.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
toggleAim.Position = UDim2.new(0, startX, 0, startY + buttonHeight + spacing)
toggleAim.Text = "切換自動瞄準 (OFF)"
toggleAim.Parent = ScreenGui

-- 自動爆頭按鈕
local autoFireBtn = Instance.new("TextButton")
autoFireBtn.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
autoFireBtn.Position = UDim2.new(0, startX, 0, startY + 2*(buttonHeight + spacing))
autoFireBtn.Text = "按住左鍵自動爆頭"
autoFireBtn.Parent = ScreenGui

-- 不鎖玩家展開按鈕
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(0, 180, 0, 30)
dropdownBtn.Position = UDim2.new(0, startX, 0, startY + 3*(buttonHeight + spacing))
dropdownBtn.Text = "點擊展開不鎖玩家"
dropdownBtn.Parent = ScreenGui

-- 排除玩家清單框
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
local espObjects = {}
local aimRange = 150
local excludedPlayers = {}

-- 獲取未排除且存活的敵人
local function getEnemies()
    local enemies = {}
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            if not (v.Team and v.Team == LocalPlayer.Team) then
                if not table.find(excludedPlayers, v.Name) then
                    if not (v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health <= 0) then
                        table.insert(enemies, v)
                    end
                end
            end
        end
    end
    return enemies
end

-- 找最近的敵人
local function getClosestEnemy()
    local minDist = math.huge
    local target = nil
    local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end
    for _, enemy in ipairs(getEnemies()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (enemy.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
            if dist <= aimRange and dist < minDist then
                minDist = dist
                target = enemy
            end
        end
    end
    return target
end

-- 建立ESP標記
local function createESP(target, color)
    local adornment = Instance.new("BoxHandleAdornment")
    adornment.Adornee = target.Character:FindFirstChild("HumanoidRootPart")
    adornment.Size = Vector3.new(3, 6, 1)
    adornment.Color3 = color
    adornment.Transparency = 0.5
    adornment.ZIndex = 10
    adornment.AlwaysOnTop = true
    adornment.Parent = workspace
    table.insert(espObjects, adornment)
    return adornment
end

local function clearESP()
    for _, v in pairs(espObjects) do
        if v then v:Destroy() end
    end
    espObjects = {}
end

-- 瞄準
local function aimAt(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local enemyHead = target.Character.Head
        local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if selfHRP then
            Camera.CFrame = CFrame.new(selfHRP.Position, enemyHead.Position)
        end
    end
end

-- 自動射擊
local function shootAt(pos)
    local shootEvent = game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
    if shootEvent then
        shootEvent:FireServer(pos)
    end
end

local function autoFire()
    if autoFiring then
        for _, enemy in ipairs(getEnemies()) do
            if enemy.Character and enemy.Character:FindFirstChild("Head") then
                shootAt(enemy.Character.Head.Position)
            end
        end
        wait(0.05)
        autoFire()
    end
end

local function startAutoFire()
    if not autoFiring then
        autoFiring = true
        spawn(autoFire)
    end
end

local function stopAutoFire()
    autoFiring = false
end

-- UI按鈕事件
toggleESP.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    toggleESP.Text = "切換ESP (" .. (espEnabled and "ON" or "OFF") .. ")"
end)

toggleAim.MouseButton1Click:Connect(function()
    autoAim = not autoAim
    toggleAim.Text = "切換自動瞄準 (" .. (autoAim and "ON" or "OFF") .. ")"
end)

autoFireBtn.MouseButton1Click:Connect(function()
    if autoFiring then
        autoFiring = false
        autoFireBtn.Text = "按住左鍵自動爆頭"
    else
        autoFiring = true
        startAutoFire()
        autoFireBtn.Text = "停止自動爆頭"
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        startAutoFire()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        stopAutoFire()
    end
end)

-- 排除玩家UI
local function refreshDropdown()
    dropdownFrame:ClearAllChildren()
    local y = 0
    for _, v in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.Position = UDim2.new(0, 0, 0, y)
        btn.Text = v.Name
        btn.Parent = dropdownFrame
        btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.MouseButton1Click:Connect(function()
            local index = table.find(excludedPlayers, v.Name)
            if index then
                table.remove(excludedPlayers, index)
            else
                table.insert(excludedPlayers, v.Name)
            end
            refreshDropdown()
        end)
        if table.find(excludedPlayers, v.Name) then
            btn.Font = Enum.Font.SourceSansBold
        else
            btn.Font = Enum.Font.SourceSans
        end
        y = y + 25
    end
end

-- 展開/收起排除清單
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
    if dropdownFrame.Visible then
        dropdownBtn.Text = "點擊收起不鎖玩家"
    else
        dropdownBtn.Text = "點擊展開不鎖玩家"
    end
    refreshDropdown()
end)

-- 預設刷新一次
refreshDropdown()

-- 主循環：畫ESP與瞄準
RunService.RenderStepped:Connect(function()
    -- 清除之前的ESP
    clearESP()
    if espEnabled then
        for _, enemy in ipairs(getEnemies()) do
            if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                createESP(enemy, Color3.new(1, 0, 0))
            end
        end
    end
    -- 自動瞄準
    if autoAim then
        local target = getClosestEnemy()
        if target then
            aimAt(target)
        end
    end
end)
