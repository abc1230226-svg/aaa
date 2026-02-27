-- 這是注入器用的完整腳本

-- 避免重複運行
if _G.AimAssistInjected then return end
_G.AimAssistInjected=true

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local workspace=game.Workspace
local LocalPlayer=Players.LocalPlayer

-- UI界面
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimAssistUI"
ScreenGui.Parent=game:GetService("CoreGui") -- 注入器用CoreGui不會被屏蔽

local MainFrame=Instance.new("Frame")
MainFrame.Size=UDim2.new(0,300,0,250)
MainFrame.Position=UDim2.new(0,10,0,10)
MainFrame.BackgroundColor3=Color3.new(0,0,0)
MainFrame.BackgroundTransparency=0.5
MainFrame.Parent=ScreenGui

local toggleUIBtn=Instance.new("TextButton")
toggleUIBtn.Size=UDim2.new(0,150,0,30)
toggleUIBtn.Position=UDim2.new(0,10,0,0)
toggleUIBtn.Text="隱藏控制台"
toggleUIBtn.Parent=MainFrame

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

local autoFireBtn=Instance.new("TextButton")
autoFireBtn.Size=UDim2.new("0",buttonWidth,"0",buttonHeight)
autoFireBtn.Position=UDim2.new("0",startX,"0",startY+2*(buttonHeight+spacing))
autoFireBtn.Text="按住左鍵自動爆頭"
autoFireBtn.Parent=MainFrame

local excludeBtn=Instance.new("TextButton")
excludeBtn.Size=UDim2.new(0,180,0,30)
excludeBtn.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing),0)
excludeBtn.Text="點擊選擇排除玩家"
excludeBtn.Parent=MainFrame

local excludeListFrame=Instance.new("Frame")
excludeListFrame.Size=UDim2.new(0,180,0,150)
excludeListFrame.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing)+30,0)
excludeListFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)
excludeListFrame.Visible=false
excludeListFrame.Parent=MainFrame

local excludedPlayers={}
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
        btn.Font=Enum.Font.SourceSans
        btn.MouseButton1Click:Connect(function()
            local exists=table.find(excludedPlayers,player.Name)
            if exists then
                table.remove(excludedPlayers,exists)
            else
                table.insert(excludedPlayers,player.Name)
            end
            refreshExcludeList()
        end)
        if table.find(excludedPlayers,player.Name) then
            btn.Font=Enum.Font.SourceSansBold
        end
        y=y+25
    end
end

-- UI切換
toggleUIBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible=not MainFrame.Visible
    if MainFrame.Visible then
        toggleUIBtn.Text="隱藏控制台"
    else
        toggleUIBtn.Text="顯示控制台"
    end
end)

local uiSettings={
    esp=false,
    autoAim=false,
    allowThroughWalls=true,
    autoHeadshot=true
}

toggleESPButton.MouseButton1Click:Connect(function()
    uiSettings.esp=not uiSettings.esp
    toggleESPButton.Text="切換ESP ("..(uiSettings.esp and "ON" or "OFF")..")"
end)

toggleAimButton.MouseButton1Click:Connect(function()
    uiSettings.autoAim=not uiSettings.autoAim
    toggleAimButton.Text="切換自動瞄準 ("..(uiSettings.autoAim and "ON" or "OFF")..")"
end)

autoFireBtn.MouseButton1Click:Connect(function()
    if _G.AutoFire then
        _G.AutoFire=false
        autoFireBtn.Text="按住左鍵自動爆頭"
    else
        _G.AutoFire=true
        autoFireBtn.Text="停止自動爆頭"
    end
end)

excludeBtn.MouseButton1Click:Connect(function()
    excludeListFrame.Visible=not excludeListFrame.Visible
end)

refreshExcludeList()

-- 監聽並hook子彈射擊事件
local shootEvent=game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
local originalFire=shootEvent and shootEvent.FireServer
if originalFire then
    hookfunction(shootEvent.FireServer, function(...)
        local args={...}
        local targetPos=args[1]
        if uiSettings.allowThroughWalls then
            local target=getClosestEnemy()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                targetPos=target.Character.Head.Position
            end
            args[1]=targetPos
        end
        return originalFire(unpack(args))
    end)
end

-- 判斷敵人
local function isTeammateOrDead(enemy)
    if not enemy.Character then return true end
    if enemy.Team and enemy.Team==LocalPlayer.Team then return true end
    if enemy.Character:FindFirstChild("Humanoid") and enemy.Character.Humanoid.Health<=0 then return true end
    for _,name in pairs(excludedPlayers) do
        if enemy.Name==name then return true end
    end
    return false
end

local function getClosestEnemy()
    local minDist=math.huge
    local target=nil
    local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end
    for _,enemy in ipairs(Players:GetPlayers()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            if not isTeammateOrDead(enemy) then
                local dist=(enemy.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
                if dist<50 and dist<minDist then
                    minDist=dist
                    target=enemy
                end
            end
        end
    end
    return target
end

local function aimAtTarget(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local headPos=target.Character.Head.Position
        local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if selfHRP then
            local cf=CFrame.new(selfHRP.Position, headPos)
            workspace.CurrentCamera.CFrame=cf
        end
    end
end

-- 自動爆頭功能
_G.AutoFire=false
local autoFireRunning=false
local function startAutoFire()
    _G.AutoFire=true
    if autoFireRunning then return end
    autoFireRunning=true
    spawn(function()
        while _G.AutoFire do
            local target=getClosestEnemy()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local shootEvent=game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
                if shootEvent then
                    shootEvent:FireServer(target.Character.Head.Position)
                end
            end
            wait(0.05)
        end
        autoFireRunning=false
    end)
end
local function stopAutoFire()
    _G.AutoFire=false
end

-- 按住左鍵啟動/停止自動爆頭
UserInputService.InputBegan:Connect(function(input,gameProcessed)
    if gameProcessed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        startAutoFire()
    end
end)

UserInputService.InputEnded:Connect(function(input,gameProcessed)
    if gameProcessed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        stopAutoFire()
    end
end)

-- 每幀刷新
RunService.RenderStepped:Connect(function()
    -- ESP
    if uiSettings.esp then
        for _,enemy in ipairs(Players:GetPlayers()) do
            if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                if not isTeammateOrDead(enemy) then
                    local adorn=Instance.new("BoxHandleAdornment")
                    adorn.Adornee=enemy.Character.HumanoidRootPart
                    adorn.Size=Vector3.new(3,6,1)
                    adorn.Color3=Color3.new(1,0,0)
                    adorn.Transparency=0.5
                    adorn.ZIndex=10
                    adorn.AlwaysOnTop=true
                    adorn.Parent=workspace
                end
            end
        end
    end
    -- 自動瞄準
    if uiSettings.autoAim then
        local target=getClosestEnemy()
        if target then
            aimAtTarget(target)
        end
    end
end)
