local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Camera=workspace.CurrentCamera
local LocalPlayer=Players.LocalPlayer

-- UI設置（縱向排版）
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimAssistUI"
ScreenGui.Parent=game:GetService("CoreGui") -- 放在CoreGui方便顯示

local buttonWidth=150
local buttonHeight=30
local startX=10
local startY=10
local spacing=10 -- 按鈕間距

local toggleESPButton=Instance.new("TextButton")
toggleESPButton.Size=UDim2.new("0",buttonWidth,"0",buttonHeight)
toggleESPButton.Position=UDim2.new("0",startX,"0",startY)
toggleESPButton.Text="切換ESP（OFF）"
toggleESPButton.Parent=ScreenGui

local toggleAimButton=Instance.new("TextButton")
toggleAimButton.Size=UDim2.new("0",buttonWidth,"0",buttonHeight)
toggleAimButton.Position=UDim2.new("0",startX,"0",startY+buttonHeight+spacing)
toggleAimButton.Text="切換自動瞄準（OFF）"
toggleAimButton.Parent=ScreenGui

local autoFireButton=Instance.new("TextButton")
autoFireButton.Size=UDim2.new("0",buttonWidth,"0",buttonHeight)
autoFireButton.Position=UDim2.new("0",startX,"0",startY+2*(buttonHeight+spacing))
autoFireButton.Text="按住左鍵自動爆頭"
autoFireButton.Parent=ScreenGui

-- 變數
local espEnabled=false
local autoAim=true
local espObjects={}
local aimRange=50

local autoFiring=false -- 按住左鍵自動射擊
local autoFireActive=false -- 是否按住左鍵

-- 判斷目標是否為隊友或屍體
local function isTeammateOrCorpse(enemy)
    if not enemy.Character then return false end
    if enemy.Team and enemy.Team==LocalPlayer.Team then
        return true -- 隊友
    end
    if enemy.Character:FindFirstChild("Humanoid") and enemy.Character.Humanoid.Health<=0 then
        return true -- 屍體
    end
    return false
end

-- 獲取所有敵人（非隊友、非屍體）
local function getEnemies()
    local t={}
    for _,v in ipairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v~=LocalPlayer then
            if not isTeammateOrCorpse(v) then
                table.insert(t,v)
            end
        end
    end
    return t
end

-- 找到最近的敵人（不考慮遮擋，只考距離）
local function getClosestEnemy()
    local minDist=math.huge
    local target=nil
    local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end
    for _,enemy in ipairs(getEnemies()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local dist=(enemy.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
            if dist<=aimRange and dist<minDist then
                minDist=dist
                target=enemy
            end
        end
    end
    return target
end

-- 創建ESP
local function createESP(v, color)
    local adornment=Instance.new("BoxHandleAdornment")
    adornment.Adornee=v.Character:FindFirstChild("HumanoidRootPart")
    adornment.Size=Vector3.new(3,6,1)
    adornment.Color3=color
    adornment.Transparency=0.5
    adornment.ZIndex=10
    adornment.AlwaysOnTop=true
    adornment.Parent=workspace
    table.insert(espObjects,adornment)
    return adornment
end

local function clearESP()
    for _,v in pairs(espObjects) do
        if v then v:Destroy() end
    end
    espObjects={}
end

-- 瞄準
local function aimAtTarget(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local enemyHead=target.Character.Head
        local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if selfHRP then
            local newCamCF=CFrame.new(selfHRP.Position, enemyHead.Position)
            Camera.CFrame=newCamCF
        end
    end
end

-- 發射子彈
local function shootAtPosition(pos)
    local shootEvent=game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
    if shootEvent then
        shootEvent:FireServer(pos)
    end
end

-- 自動射擊
local function startAutoFire()
    if autoFiring then return end
    autoFiring=true
    spawn(function()
        while autoFiring do
            for _,enemy in ipairs(getEnemies()) do
                if enemy.Character and enemy.Character:FindFirstChild("Head") then
                    shootAtPosition(enemy.Character.Head.Position)
                end
            end
            wait(0.05)
        end
    end)
end

local function stopAutoFire()
    autoFiring=false
end

-- UI事件
toggleESPButton.MouseButton1Click:Connect(function()
    espEnabled=not espEnabled
    toggleESPButton.Text="切換ESP ("..(espEnabled and "ON" or "OFF")..")"
end)

toggleAimButton.MouseButton1Click:Connect(function()
    autoAim=not autoAim
    toggleAimButton.Text="切換自動瞄準 ("..(autoAim and "ON" or "OFF")..")"
end)

-- 按住左鍵自動爆頭
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        autoFireActive=true
        startAutoFire()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        autoFireActive=false
        stopAutoFire()
    end
end)

-- 主循環：每幀更新
RunService.RenderStepped:Connect(function()
    -- 每次都清除舊的ESP
    clearESP()

    -- 只標記敵人
    if espEnabled then
        for _,enemy in ipairs(getEnemies()) do
            if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                createESP(enemy, Color3.new(1,0,0))
            end
        end
    end

    -- 自動瞄準，只鎖定敵人
    if autoAim then
        local target=getClosestEnemy()
        if target then
            aimAtTarget(target)
        end
    end
end)
