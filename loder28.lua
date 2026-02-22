local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- UI建立
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local startX, startY = 10, 10
local buttonWidth, buttonHeight, spacing = 150, 30, 10

local togglePerspectiveBtn = Instance.new("TextButton")
togglePerspectiveBtn.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
togglePerspectiveBtn.Position = UDim2.new(0, startX, 0, startY)
togglePerspectiveBtn.Text = "開啟透視"
togglePerspectiveBtn.Parent = ScreenGui

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
local espEnabled = false -- 改為透視開關
local autoAim = false
local autoFiring = false
local aimRange = 150
local perspectiveEnabled = false -- 透視開啟狀態

local espObjects = {}
local playerStates = {} -- 儲存每個玩家的鎖定狀態（autoAim, esp, lockAim）
local playerButtons = {}

-- 取得其他玩家
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

-- 重新整理玩家列表UI
local function refreshPlayerList()
    dropdownFrame:ClearAllChildren()
    playerButtons = {}
    local y = 0
    for _, v in ipairs(getServerPlayers()) do
        if not playerStates[v.Name] then
            playerStates[v.Name] = {
                autoAim = true,
                esp = true,
                lockAim = false
            }
        end
        local s = playerStates[v.Name]

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.Position = UDim2.new(0, 0, 0, y)
        local lockText = s.lockAim and "[鎖定]" or "[未鎖]"
        btn.Text = v.Name .. " " .. lockText

        if s.lockAim then
            btn.BackgroundColor3 = Color3.new(0, 1, 0)
        else
            btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        end

        btn.MouseButton1Click:Connect(function()
            s.lockAim = not s.lockAim
            local lockText2 = s.lockAim and "[鎖定]" or "[未鎖]"
            btn.Text = v.Name .. " " .. lockText2
            if s.lockAim then
                btn.BackgroundColor3 = Color3.new(0, 1, 0)
            else
                btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
            end
        end)
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

-- 透視開關
togglePerspectiveBtn.MouseButton1Click = function()
    perspectiveEnabled = not perspectiveEnabled
    togglePerspectiveBtn.Text = (perspectiveEnabled and "關閉透視" or "開啟透視")
end

-- 自動瞄準
toggleAim.MouseButton1Click = function()
    autoAim = not autoAim
    toggleAim.Text = "切換自動瞄準 (" .. (autoAim and "ON" or "OFF") .. ")"
end

-- 自動爆頭
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

local function shootAt(position)
    UserInputService:SetMouseButton1Down()
    wait(0.05)
    UserInputService:SetMouseButton1Up()
end

local function getFirstLockedTarget()
    for _, v in ipairs(getServerPlayers()) do
        local s = playerStates[v.Name]
        if s and s.lockAim and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    return nil
end

local function aimAt(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local enemyHead = target.Character.Head
        local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if selfHRP then
            Camera.CFrame = CFrame.new(selfHRP.Position, enemyHead.Position)
        end
    end
end

-- ESP
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

-- 主循環
RunService.RenderStepped:Connect(function()
    -- ESP
    clearESP()
    if espEnabled then -- 改成透視控制
        for _, v in ipairs(getEnemies()) do
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                createESP(v, Color3.new(1, 0, 0))
            end
        end
    end

    -- 透視 (開啟後讓所有模型變成透視)
    if perspectiveEnabled then
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0.5
                part.Reflectance = 0
            end
        end
    else
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
    end

    -- 自動瞄準
    if autoAim then
        local target = getFirstLockedTarget()
        if target then
            aimAt(target)
        end
    end
end)
