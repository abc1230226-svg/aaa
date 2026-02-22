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

-- 控制界面框架
local MainFrame=Instance.new("Frame")
MainFrame.Size=UDim2.new(0,300,0,250)
MainFrame.Position=UDim2.new(0,10,0,10)
MainFrame.BackgroundColor3=Color3.new(0,0,0)
MainFrame.BackgroundTransparency=0.5
MainFrame.Parent=ScreenGui

-- 隱藏/顯示控制台按鈕
local toggleUIBtn=Instance.new("TextButton")
toggleUIBtn.Size=UDim2.new(0,150,0,30)
toggleUIBtn.Position=UDim2.new(0,10,0,0)
toggleUIBtn.Text="隱藏控制台"
toggleUIBtn.Parent=MainFrame

local espEnabled=false
local autoAim=true
local espObjects={}

local aimRange=50
local autoFiring=false
local autoFireActive=false

local excludedPlayers={} -- 不想鎖的玩家名單

-- UI元素
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

-- 下拉式清單（用來選擇不鎖的玩家）
local dropdownButton=Instance.new("TextButton")
dropdownButton.Size=UDim2.new(0,180,0,30)
dropdownButton.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing),0)
dropdownButton.Text="不鎖玩家（點擊展開）"
dropdownButton.Parent=MainFrame

local dropdownListFrame=Instance.new("Frame")
dropdownListFrame.Size=UDim2.new(0,180,0,150)
dropdownListFrame.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing)+30,0)
dropdownListFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)
dropdownListFrame.Visible=false
dropdownListFrame.Parent=MainFrame

local function refreshDropdown()
    dropdownListFrame:ClearAllChildren()
    local y=0
    for _,player in ipairs(Players:GetPlayers()) do
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,0,25)
        btn.Position=UDim2.new(0,0,0,y)
        btn.Text=player.Name
        btn.Parent=dropdownListFrame
        btn.BackgroundColor3=Color3.new(0.3,0.3,0.3)
        btn.TextColor3=Color3.new(1,1,1)
        btn.MouseButton1Click:Connect(function()
            -- 加入或移除不鎖的玩家
            if table.find(excludedPlayers,player.Name) then
                table.remove(excludedPlayers,table.find(excludedPlayers,player.Name))
            else
                table.insert(excludedPlayers,player.Name)
            end
            refreshDropdown()
        end)
        -- 字體加粗表示已加入排除清單
        if table.find(excludedPlayers,player.Name) then
            btn.Font=Enum.Font.SourceSansBold
        else
            btn.Font=Enum.Font.SourceSans
        end
        y=y+25
    end
end

-- 展開/收起清單
dropdownButton.MouseButton1Click:Connect(function()
    dropdownListFrame.Visible=not dropdownListFrame.Visible
    if dropdownListFrame.Visible then
        dropdownButton.Text="不鎖玩家（點擊收起）"
    else
        dropdownButton.Text="不鎖玩家（點擊展開）"
    end
end)

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
        autoFiring=false
        autoFireButton.Text="按住左鍵自動爆頭"
    else
        autoFiring=true
        startAutoFire()
        autoFireButton.Text="停止自動爆頭"
    end
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
    -- 清除所有ESP
    for _,v in pairs(espObjects) do
        if v then v:Destroy() end
    end
    espObjects={}

    -- 只顯示敵人ESP
    if espEnabled then
        for _,enemy in ipairs(getEnemies()) do
            if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                local adornment=Instance.new("BoxHandleAdornment")
                adornment.Adornee=enemy.Character.HumanoidRootPart
                adornment.Size=Vector3.new(3,6,1)
                adornment.Color3=Color3.new(1,0,0)
                adornment.Transparency=0.5
                adornment.ZIndex=10
                adornment.AlwaysOnTop=true
                adornment.Parent=workspace
                table.insert(espObjects,adornment)
            end
        end
    end

    -- 自動瞄準
    if autoAim then
        local target=getClosestEnemy()
        if target then
            if target.Character and target.Character:FindFirstChild("Head") then
                local enemyHead=target.Character.Head
                local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if selfHRP then
                    local newCamCF=CFrame.new(selfHRP.Position, enemyHead.Position)
                    Camera.CFrame=newCamCF
                end
            end
        end
    end
end)

-- 取得敵人（排除不鎖的玩家）
local function getEnemies()
    local t={}
    for _,v in ipairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v~=LocalPlayer then
            -- 如果在排除名單就跳過
            if not table.find(excludedPlayers, v.Name) then
                if not (v.Team and v.Team==LocalPlayer.Team) then
                    if not (v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health<=0) then
                        table.insert(t,v)
                    end
                end
            end
        end
    end
    return t
end

-- 自動開火
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

local function shootAtPosition(pos)
    local shootEvent=game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
    if shootEvent then
        shootEvent:FireServer(pos)
    end
end
