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

-- UI元素
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

-- 下拉清單展開按鈕
local dropdownButton=Instance.new("TextButton")
dropdownButton.Size=UDim2.new(0,180,0,30)
dropdownButton.Position=UDim2.new(0,startX,startY+3*(buttonHeight+spacing),0)
dropdownButton.Text="點擊展開不鎖玩家"
dropdownButton.Parent=ScreenGui

local dropdownFrame=Instance.new("Frame")
dropdownFrame.Size=UDim2.new(0,180,0,150)
dropdownFrame.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing)+30,0)
dropdownFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)
dropdownFrame.Visible=false
dropdownFrame.Parent=ScreenGui

local espEnabled=false
local autoAim=true
local espObjects={}

local aimRange=50
local autoFiring=false
local autoFireActive=false

local excludedPlayers={} -- 不鎖玩家清單

-- 其他變數
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
                -- 排除清單判斷
                if not table.find(excludedPlayers, v.Name) then
                    if not (v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health<=0) then
                        table.insert(t,v)
                    end
                end
            end
        end
    end
    return t
end

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

-- 下拉清單展開/收起
local function refreshDropdown()
    dropdownFrame:ClearAllChildren()
    local y=0
    for _,player in ipairs(Players:GetPlayers()) do
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,0,25)
        btn.Position=UDim2.new(0,0,0,y)
        btn.Text=player.Name
        btn.Parent=dropdownFrame
        btn.BackgroundColor3=Color3.new(0.3,0.3,0.3)
        btn.TextColor3=Color3.new(1,1,1)
        btn.MouseButton1Click:Connect(function()
            local index=table.find(excludedPlayers,player.Name)
            if index then
                table.remove(excludedPlayers,index)
            else
                table.insert(excludedPlayers,player.Name)
            end
            refreshDropdown()
        end)
        -- 已加入排除清單，字體加粗
        if table.find(excludedPlayers,player.Name) then
            btn.Font=Enum.Font.SourceSansBold
        else
            btn.Font=Enum.Font.SourceSans
        end
        y=y+25
    end
end

dropdownButton.MouseButton1Click:Connect(function()
    dropdownFrame.Visible=not dropdownFrame.Visible
    if dropdownFrame.Visible then
        dropdownButton.Text="點擊收起不鎖玩家"
    else
        dropdownButton.Text="點擊展開不鎖玩家"
    end
    refreshDropdown()
end)

-- 初次刷新清單
refreshDropdown()

-- 每幀刷新：ESP和自動瞄準
RunService.RenderStepped:Connect(function()
    -- 先清除所有ESP
    clearESP()

    -- 僅顯示敵人的ESP
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
