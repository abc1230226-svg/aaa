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
toggleESPButton.Size=UDim2.new(0,buttonWidth,0,buttonHeight)
toggleESPButton.Position=UDim2.new(0,startX,0,startY)
toggleESPButton.Text="切換ESP（OFF）"
toggleESPButton.Parent=ScreenGui

local toggleAimButton=Instance.new("TextButton")
toggleAimButton.Size=UDim2.new(0,buttonWidth,0,buttonHeight)
toggleAimButton.Position=UDim2.new(0,startX,0,startY+buttonHeight+spacing)
toggleAimButton.Text="切換自動瞄準（OFF）"
toggleAimButton.Parent=ScreenGui

local autoFireButton=Instance.new("TextButton")
autoFireButton.Size=UDim2.new(0,buttonWidth,0,buttonHeight)
autoFireButton.Position=UDim2.new(0,startX,0,startY+2*(buttonHeight+spacing))
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
    -- 你可以根據具體遊戲的標記進行判斷
    -- 這裡假設：隊友有"Team"屬性或名稱，屍體有特定標記
    if not enemy.Character then return false end
    -- 示例判斷（根據實際情況修改）
    if enemy.Team and enemy.Team==LocalPlayer.Team then
        return true -- 隊友
    end
    if enemy.Character:FindFirstChild("Humanoid") and enemy.Character.Humanoid.Health<=0 then
        return true -- 屍體（已死）
    end
    return false
end

-- 獲取敵人列表
local function getEnemies()
    local t={}
    for _,v in ipairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v~=LocalPlayer then
            table.insert(t,v)
        end
    end
    return t
end

-- 獲取最近的敵人
local function getClosestEnemy()
    local minDist=math.huge
    local target=nil
    local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end
    for _,enemy in ipairs(getEnemies()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            -- 先判斷是不是敵人
            if isTeammateOrCorpse(enemy) then
                -- 如果是隊友或屍體，跳過
            else
                local dist=(enemy.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
                if dist<=aimRange and dist<minDist then
                    minDist=dist
                    target=enemy
                end
            end
        end
    end
    return target
end

-- 創建ESP（不同顏色）
local function createESP(v, color)
    local adornment=Instance.new("BoxHandleAdornment")
    adornment.Adornee=v.Character:FindFirstChild("HumanoidRootPart")
    adornment.Size=Vector3.new(3,6,1)
    adornment.Color3=color
    adornment.Transparency=0.5
    adornment.ZIndex=10
    adornment.AlwaysOnTop=true
    adornment.Parent=workspace
    return adornment
end

local function clearESP()
    for _,v in pairs(espObjects) do
        if v then v:Destroy() end
    end
    espObjects={}
end

-- 瞄準敵人
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

-- 持續自動射擊
local function startAutoFire()
    if autoFiring then return end
    autoFiring=true
    spawn(function()
        while autoFiring do
            for _,enemy in ipairs(getEnemies()) do
                if enemy.Character and enemy.Character:FindFirstChild("Head") then
                    if not isTeammateOrCorpse(enemy) then
                        shootAtPosition(enemy.Character.Head.Position)
                    end
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

-- 按住左鍵，自動爆頭
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

-- 主循環：更新ESP &自動瞄準
RunService.RenderStepped:Connect(function()
    -- 更新ESP
    if espEnabled then
        for _,v in pairs(espObjects) do
            if v then v:Destroy() end
        end
        espObjects={}
        for _,enemy in ipairs(getEnemies()) do
            if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                if isTeammateOrCorpse(enemy) then
                    createESP(enemy, Color3.new(0,1,0)) -- 綠色：隊友或屍體
                else
                    createESP(enemy, Color3.new(1,0,0)) -- 紅色：敵人
                end
            end
        end
    end

    -- 自動瞄準
    if autoAim then
        local target=getClosestEnemy()
        if target then
            aimAtTarget(target)
        end
    end
end)
