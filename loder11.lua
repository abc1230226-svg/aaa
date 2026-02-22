-- 最佳AimAssist腳本版本
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local Camera=workspace.CurrentCamera
local LocalPlayer=Players.LocalPlayer

-- UI建立
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimAssistUI"
ScreenGui.Parent=game:GetService("CoreGui") -- 需要在有權限的情況下使用

local buttonWidth,buttonHeight,spacing=150,30,10
local startX,startY=10,10

local toggleESP=Instance.new("TextButton")
toggleESP.Size=UDim2.new(0,buttonWidth,0,buttonHeight)
toggleESP.Position=UDim2.new(0,startX,0,startY)
toggleESP.Text="切換ESP（OFF）"
toggleESP.Parent=ScreenGui

local toggleAim=Instance.new("TextButton")
toggleAim.Size=UDim2.new(0,buttonWidth,0,buttonHeight)
toggleAim.Position=UDim2.new(0,startX,0,startY+buttonHeight+spacing)
toggleAim.Text="切換自動瞄準（OFF）"
toggleAim.Parent=ScreenGui

local autoFireBtn=Instance.new("TextButton")
autoFireBtn.Size=UDim2.new(0,buttonWidth,0,buttonHeight)
autoFireBtn.Position=UDim2.new(0,startX,0,startY+2*(buttonHeight+spacing))
autoFireBtn.Text="按住左鍵自動爆頭"
autoFireBtn.Parent=ScreenGui

local dropdownBtn=Instance.new("TextButton")
dropdownBtn.Size=UDim2.new(0,180,0,30)
dropdownBtn.Position=UDim2.new(0,startX,startY+3*(buttonHeight+spacing),0)
dropdownBtn.Text="點擊展開不鎖玩家"
dropdownBtn.Parent=ScreenGui

local dropdownFrame=Instance.new("Frame")
dropdownFrame.Size=UDim2.new(0,180,0,150)
dropdownFrame.Position=UDim2.new("0",startX,startY+3*(buttonHeight+spacing)+30,0)
dropdownFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)
dropdownFrame.Visible=false
dropdownFrame.Parent=ScreenGui

-- 狀態變數
local espEnabled=false
local autoAim=true
local espObjects={}
local aimRange=150 -- 可調整範圍
local autoFiring=false
local autoFireActive=false
local excludedPlayers={} -- 不鎖玩家清單

-- 判斷是否為隊友或屍體
local function isTeammateOrCorpse(enemy)
    if not enemy.Character then return false end
    if enemy.Team and enemy.Team==LocalPlayer.Team then
        return true
    end
    if enemy.Character:FindFirstChild("Humanoid") and enemy.Character.Humanoid.Health<=0 then
        return true
    end
    return false
end

-- 取得敵人（排除清單）
local function getEnemies()
    local t={}
    for _,v in ipairs(Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v~=LocalPlayer then
            if not (v.Team and v.Team==LocalPlayer.Team) then
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

-- 取得最接近的敵人
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
local function createESP(target, color)
    local adornment=Instance.new("BoxHandleAdornment")
    adornment.Adornee=target.Character:FindFirstChild("HumanoidRootPart")
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

local function aimAt(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local enemyHead=target.Character.Head
        local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if selfHRP then
            Camera.CFrame=CFrame.new(selfHRP.Position, enemyHead.Position)
        end
    end
end

local function shootAt(pos)
    -- 請根據你的遊戲調整攻擊事件
    local shootEvent=game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
    if shootEvent then
        shootEvent:FireServer(pos)
    end
end

local function autoFire()
    if autoFiring then
        for _,enemy in ipairs(getEnemies()) do
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
        autoFiring=true
        spawn(autoFire)
    end
end

local function stopAutoFire()
    autoFiring=false
end

-- UI事件
toggleESP.MouseButton1Click:Connect(function()
    espEnabled=not espEnabled
    toggleESP.Text="切換ESP ("..(espEnabled and "ON" or "OFF")..")"
end)

toggleAim.MouseButton1Click:Connect(function()
    autoAim=not autoAim
    toggleAim.Text="切換自動瞄準 ("..(autoAim and "ON" or "OFF")..")"
end)

autoFireBtn.MouseButton1Click:Connect(function()
    if autoFiring then
        autoFiring=false
        autoFireBtn.Text="按住左鍵自動爆頭"
    else
        autoFiring=true
        startAutoFire()
        autoFireBtn.Text="停止自動爆頭"
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        startAutoFire()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        stopAutoFire()
    end
end)

-- 排除玩家名單UI
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
            local index=table.find(excludedPlayers, player.Name)
            if index then
                table.remove(excludedPlayers, index)
            else
                table.insert(excludedPlayers, player.Name)
            end
            refreshDropdown()
        end)
        if table.find(excludedPlayers, player.Name) then
            btn.Font=Enum.Font.SourceSansBold
        else
            btn.Font=Enum.Font.SourceSans
        end
        y=y+25
    end
end

dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible=not dropdownFrame.Visible
    if dropdownFrame.Visible then
        dropdownBtn.Text="點擊收起不鎖玩家"
    else
        dropdownBtn.Text="點擊展開不鎖玩家"
    end
    refreshDropdown()
end)

refreshDropdown()

-- 主循環：ESP與自動瞄準
RunService.RenderStepped:Connect(function()
    -- 清除所有ESP
    clearESP()

    -- 顯示ESP
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
            aimAt(target)
        end
    end
end)
