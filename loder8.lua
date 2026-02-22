local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Camera=workspace.CurrentCamera
local LocalPlayer=Players.LocalPlayer

-- UI設置
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimAssistUI"
ScreenGui.Parent=game:GetService("CoreGui")

-- 控制界面框架
local MainFrame=Instance.new("Frame")
MainFrame.Size=UDim2.new(0,300,0,250)
MainFrame.Position=UDim2.new(0,10,0,10)
MainFrame.BackgroundColor3=Color3.new(0,0,0)
MainFrame.BackgroundTransparency=0.5
MainFrame.Parent=ScreenGui

-- 顯示/隱藏控制界面按鈕
local toggleUIBtn=Instance.new("TextButton")
toggleUIBtn.Size=UDim2.new(0,150,0,30)
toggleUIBtn.Position=UDim2.new(0,10,0,0)
toggleUIBtn.Text="隱藏控制台"
toggleUIBtn.Parent=MainFrame

-- 其他按鈕
local buttonWidth=150
local buttonHeight=30
local startX=10
local startY=40
local spacing=10

local toggleESPButton=Instance.new("TextButton")
toggleESPButton.Size=UDim2.new("0",buttonWidth,"0",buttonHeight)
toggleESPButton.Position=UDim2.new("0",startX,"0",startY)
toggleESPButton.Text="切換ESP（OFF）"
toggleESPButton.Parent=MainFrame

local toggleAimButton=Instance.new("TextButton")
toggleAimButton.Size=UDim2.new("0",buttonWidth,"0",buttonHeight)
toggleAimButton.Position=UDim2.new("0",startX,"0",startY+buttonHeight+spacing)
toggleAimButton.Text="切換自動瞄準（OFF）"
toggleAimButton.Parent=MainFrame

local autoFireButton=Instance.new("TextButton")
autoFireButton.Size=UDim2.new("0",buttonWidth,"0",buttonHeight)
autoFireButton.Position=UDim2.new("0",startX,"0",startY+2*(buttonHeight+spacing))
autoFireButton.Text="按住左鍵自動爆頭"
autoFireButton.Parent=MainFrame

-- 排除名單下拉
local excludeDropdown=Instance.new("TextButton")
excludeDropdown.Size=UDim2.new(0,180,0,30)
excludeDropdown.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing),0)
excludeDropdown.Text="點擊選擇排除玩家"
excludeDropdown.Parent=MainFrame

local excludeListFrame=Instance.new("Frame")
excludeListFrame.Size=UDim2.new(0,180,0,150)
excludeListFrame.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing)+30,0)
excludeListFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)
excludeListFrame.Visible=false
excludeListFrame.Parent=MainFrame

local excludedPlayers={} -- 排除名單

-- 控制整個UI隱藏/顯示
local function toggleUI()
    MainFrame.Visible=not MainFrame.Visible
    if MainFrame.Visible then
        toggleUIBtn.Text="隱藏控制台"
    else
        toggleUIBtn.Text="顯示控制台"
    end
end

toggleUIBtn.MouseButton1Click:Connect(toggleUI)

local espEnabled=false
local autoAim=true
local espObjects={}

local aimRange=50
local autoFiring=false
local autoFireActive=false

-- 判斷是否為隊友或屍體
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

-- 取得敵人（排除隊友和屍體）
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

-- 取得最近的敵人
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

-- UI事件
toggleESPButton.MouseButton1Click:Connect(function()
    espEnabled=not espEnabled
    toggleESPButton.Text="切換ESP ("..(espEnabled and "ON" or "OFF")..")"
end)

toggleAimButton.MouseButton1Click:Connect(function()
    autoAim=not autoAim
    toggleAimButton.Text="切換自動瞄準 ("..(autoAim and "ON" or "OFF")..")"
end)

autoFireButton.MouseButton1Click:Connect(function()
    if autoFiring then
        stopAutoFire()
        autoFireButton.Text="按住左鍵自動爆頭"
    else
        startAutoFire()
        autoFireButton.Text="停止自動爆頭"
    end
end)

-- 排除玩家選擇
local function refreshExcludeList()
    excludeListFrame:ClearAllChildren()
    local y=0
    for _,player in ipairs(Players:GetPlayers()) do
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,0,25)
        btn.Position=UDim2.new(0,0,0,y)
        btn.Text=player.Name
        btn.Parent=excludeListFrame
        btn.BackgroundColor3=Color3.new(0.3,0.3,0.3)
        btn.TextColor3=Color3.new(1,1,1)
        btn.MouseButton1Click:Connect(function()
            -- 加入或移除排除名單
            local exists=table.find(excludedPlayers,player.Name)
            if exists then
                table.remove(excludedPlayers,exists)
            else
                table.insert(excludedPlayers,player.Name)
            end
            refreshExcludeList() -- 更新界面
        end)
        -- 顯示已加入排除的玩家，字體加粗
        if table.find(excludedPlayers,player.Name) then
            btn.Font=Enum.Font.SourceSansBold
        else
            btn.Font=Enum.Font.SourceSans
        end
        y=y+25
    end
end

-- 點擊下拉按鈕切換排除列表顯示
excludeDropdown.MouseButton1Click:Connect(function()
    excludeListFrame.Visible=not excludeListFrame.Visible
end)

-- 按鍵控制自動爆頭（鼠標左鍵）
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

-- 控制整個UI顯示/隱藏的按鈕
toggleUIBtn.MouseButton1Click:Connect(function()
    toggleUI()
end)

-- 監聽每幀刷新
RunService.RenderStepped:Connect(function()
    -- 清除ESP
    clearESP()

    -- 顯示敵人ESP
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

-- 初始化排除名單
refreshExcludeList()
