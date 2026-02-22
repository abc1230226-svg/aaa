-- 服務
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- UI建立
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- UI按鈕
local buttonWidth, buttonHeight, spacing = 150, 30, 10
local startX, startY = 10, 10

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

-- 狀態變數
local espEnabled = false
local autoAim = false
local autoFiring = false
local aimRange = 150

local espObjects = {}
local playerStates = {} -- 每個玩家的狀態（autoAim, esp, lockAim）
local playerButtons = {}

-- 取得其他玩家（不包含自己）
local function getServerPlayers()
    local players = {}
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(players, v)
            end
        end
    end
    return players
end

-- 更新玩家列表UI（點擊名字切換狀態用）
local function refreshPlayerList()
    dropdownFrame:ClearAllChildren()
    playerButtons = {}
    local y = 0
    for _, v in ipairs(getServerPlayers()) do
        if not playerStates[v.Name] then
            playerStates[v.Name] = {
                autoAim = true,
                esp = true,
                lockAim = false -- 是否鎖定
            }
        end
        local s = playerStates[v.Name]

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.Position = UDim2.new(0, 0, 0, y)
        btn.Text = v.Name

        -- 根據狀態設定背景色（鎖定狀態）
        if s.lockAim then
            btn.BackgroundColor3 = Color3.new(0, 1, 0) -- 綠色表示已鎖定
        else
            btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3) -- 灰色
        end

        -- 點擊切換鎖定狀態
        btn.MouseButton1Click:Connect(function()
            s.lockAim = not s.lockAim
            if s.lockAim then
                btn.BackgroundColor3 = Color3.new(0, 1, 0)
            else
                btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
            end
        end)

        -- 右鍵點擊切換autoAim和esp（可選，或者用其他方式）
        -- 這裡保留原有功能或刪除
        -- 你也可以只用點擊名字切換鎖定
        -- 例如：雙擊或長按來切換autoAim

        btn.Parent = dropdownFrame
        table.insert(playerButtons, btn)
        y = y + 25
    end
end

-- 展開/收起玩家列表
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
    if dropdownFrame.Visible then
        refreshPlayerList()
        dropdownBtn.Text = "點擊收起不鎖玩家"
    else
        dropdownBtn.Text = "點擊展開不鎖玩家"
    end
end)

-- 按鈕事件
toggleESP.MouseButton1Click = function()
    espEnabled = not espEnabled
    toggleESP.Text = "切換ESP (" .. (espEnabled and "ON" or "OFF") .. ")"
end

toggleAim.MouseButton1Click = function()
    autoAim = not autoAim
    toggleAim.Text = "切換自動瞄準 (" .. (autoAim and "ON" or "OFF") .. ")"
end

autoFireBtn.MouseButton1Click = function()
    if autoFiring then
        autoFiring = false
        autoFireBtn.Text = "按住左鍵自動爆頭"
    else
        autoFiring = true
        spawn(function()
            while autoFiring do
                for _, v in ipairs(getServerPlayers()) do
                    local s = playerStates[v.Name]
                    if s and s.esp and v.Character and v.Character:FindFirstChild("Head") then
                        shootAt(v.Character.Head.Position)
                    end
                end
                wait(0.05)
            end
        end)
        autoFireBtn.Text = "停止自動爆頭"
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        startAutoFire()
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        stopAutoFire()
    end
end)

local function autoFire()
    if autoFiring then
        for _, v in ipairs(getServerPlayers()) do
            local s = playerStates[v.Name]
            if s and s.esp and v.Character and v.Character:FindFirstChild("Head") then
                shootAt(v.Character.Head.Position)
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

local function shootAt(position)
    -- 模擬左鍵點擊
    UserInputService:SetMouseButton1Down()
    wait(0.05)
    UserInputService:SetMouseButton1Up()
end

-- 取得所有敵人（活著的玩家）
local function getEnemies()
    local enemies = {}
    for _, v in ipairs(getServerPlayers()) do
        local humanoid = v.Character and v.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 and v.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(enemies, v)
        end
    end
    return enemies
end

-- 找最近的活著的敵人
local function getClosestAliveEnemy()
    local minDist = math.huge
    local target = nil
    local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end
    for _, v in ipairs(getServerPlayers()) do
        local humanoid = v.Character and v.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (v.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
            if dist <= aimRange and dist < minDist then
                minDist = dist
                target = v
            end
        end
    end
    return target
end

-- 建立ESP
local function createESP(target, color)
    local adornment = Instance.new("BoxHandleAdornment")
    adornment.Adornee = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if adornment.Adornee then
        adornment.Size = Vector3.new(3, 6, 1)
        adornment.Color3 = color
        adornment.Transparency = 0.5
        adornment.ZIndex = 10
        adornment.AlwaysOnTop = true
        adornment.Parent = workspace
        table.insert(espObjects, adornment)
    end
    return adornment
end

local function clearESP()
    for _, v in pairs(espObjects) do
        v:Destroy()
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

-- 主循環
RunService.RenderStepped:Connect(function()
    -- 每幀刷新
    -- 先清空所有ESP
    clearESP()

    -- 畫ESP
    if espEnabled then
        for _, v in ipairs(getEnemies()) do
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                createESP(v, Color3.new(1, 0, 0))
            end
        end
    end

    -- 自動瞄準（只鎖活著的玩家）
    if autoAim then
        local target = getClosestAliveEnemy()
        if target then
            -- 如果該玩家已經被鎖定（playerStates[s].lockAim），則瞄準
            local s = playerStates[target.Name]
            if s and s.lockAim then
                aimAt(target)
            end
        end
    end
end)
