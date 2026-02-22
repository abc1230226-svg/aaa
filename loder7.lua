local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Camera=workspace.CurrentCamera
local LocalPlayer=Players.LocalPlayer

-- UI設置
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimAssistUI"
ScreenGui.Parent=game:GetService("CoreGui")

local buttonWidth=150
local buttonHeight=30
local startX=10
local startY=10
local spacing=10

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

-- 排除玩家名單
local excludedPlayers = {}

-- 建立玩家選單UI
local dropdown = Instance.new("Frame", ScreenGui)
dropdown.Size = UDim2.new(0, 200, 0, 300)
dropdown.Position = UDim2.new(0, startX + buttonWidth + 20, 0, startY)
dropdown.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)

local uiListLayout = Instance.new("UIListLayout", dropdown)
uiListLayout.Padding = UDim.new(0, 5)

local function updatePlayerList()
    -- 先清空之前的選項
    for _, child in ipairs(dropdown:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, v in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton", dropdown)
        btn.Text = v.Name
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        btn.TextColor3 = Color3.new(1,1,1)

        -- 點擊切換排除狀態
        btn.MouseButton1Click:Connect(function()
            if table.find(excludedPlayers, v.Name) then
                -- 取消排除
                for i, name in ipairs(excludedPlayers) do
                    if name == v.Name then table.remove(excludedPlayers, i) end
                end
                btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
            else
                -- 加入排除
                table.insert(excludedPlayers, v.Name)
                btn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
            end
        end)
    end
end

updatePlayerList()

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- 判斷敵人（排除隊友和屍體）
local function isTeammateOrCorpse(enemy)
    if not enemy.Character then return false end
    if enemy.Team and enemy.Team==LocalPlayer.Team then
        return true --隊友
    end
    if enemy.Character:FindFirstChild("Humanoid") and enemy.Character.Humanoid.Health<=0 then
        return true --屍體
    end
    return false
end

local function getEnemies()
    local t={}
    for _,v in ipairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v~=LocalPlayer then
            if not (v.Team and v.Team==LocalPlayer.Team) then
                if not (v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health<=0) then
                    table.insert(t,v)
                end
            end
        end
    end
    return t
end

-- 排除玩家判斷
local function isExcluded(enemy)
    return table.find(excludedPlayers, enemy.Name) ~= nil
end

-- 取得最近的敵人（排除在排除名單中的）
local function getClosestEnemy()
    local minDist=math.huge
    local target=nil
    local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end
    for _,enemy in ipairs(getEnemies()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            if not isExcluded(enemy) then
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

-- ESP功能
local espObjects={}
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

local function shootAtPosition(pos)
    local shootEvent=game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
    if shootEvent then
        shootEvent:FireServer(pos)
    end
end

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

-- UI按鈕控制
local espEnabled=false
local autoAim=true
local autoFiring=false
local autoFireActive=false

toggleESPButton.MouseButton1Click:Connect(function()
    espEnabled=not espEnabled
    toggleESPButton.Text="切換ESP ("..(espEnabled and "ON" or "OFF")..")"
end)

toggleAimButton.MouseButton1Click:Connect(function()
    autoAim=not autoAim
    toggleAimButton.Text="切換自動瞄準 ("..(autoAim and "ON" or "OFF")..")"
end)

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

-- 每幀刷新
RunService.RenderStepped:Connect(function()
    -- 先清除所有ESP
    clearESP()

    -- 只顯示敵人的ESP
    if espEnabled then
        for _,enemy in ipairs(getEnemies()) do
            if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                createESP(enemy, Color3.new(1,0,0))
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
