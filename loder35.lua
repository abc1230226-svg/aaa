local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LocalPlayer=Players.LocalPlayer
local Workspace=game.Workspace

-- UI設置
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimAssistUI"
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
ScreenGui.Parent=playerGui

local MainFrame=Instance.new("Frame")
MainFrame.Size=UDim2.new(0,320,0,300)
MainFrame.Position=UDim2.new(0,10,0,10)
MainFrame.BackgroundColor3=Color3.new(0,0,0)
MainFrame.BackgroundTransparency=0.3
MainFrame.BorderSizePixel=2
MainFrame.BorderColor3=Color3.new(1,1,1)
MainFrame.Parent=ScreenGui

local toggleUIBtn=Instance.new("TextButton")
toggleUIBtn.Size=UDim2.new(0,150,0,30)
toggleUIBtn.Position=UDim2.new(0,10,0,0)
toggleUIBtn.Text="隱藏控制台"
toggleUIBtn.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleUIBtn.TextColor3=Color3.new(1,1,1)
toggleUIBtn.Font=Enum.Font.SourceSansBold
toggleUIBtn.Parent=MainFrame

local contentYStart=40

local toggleESPButton=Instance.new("TextButton")
toggleESPButton.Size=UDim2.new(0,150,0,30)
toggleESPButton.Position=UDim2.new(0,10,0,contentYStart)
toggleESPButton.Text="切換ESP（OFF）"
toggleESPButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleESPButton.TextColor3=Color3.new(1,1,1)
toggleESPButton.Font=Enum.Font.SourceSans
toggleESPButton.Parent=MainFrame

local toggleAimButton=Instance.new("TextButton")
toggleAimButton.Size=UDim2.new(0,150,0,30)
toggleAimButton.Position=UDim2.new(0,10,0,contentYStart+40)
toggleAimButton.Text="切換自動瞄準（OFF）"
toggleAimButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleAimButton.TextColor3=Color3.new(1,1,1)
toggleAimButton.Font=Enum.Font.SourceSans
toggleAimButton.Parent=MainFrame

local autoFireButton=Instance.new("TextButton")
autoFireButton.Size=UDim2.new(0,150,0,30)
autoFireButton.Position=UDim2.new(0,10,0,contentYStart+80)
autoFireButton.Text="按住左鍵自動爆頭"
autoFireButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
autoFireButton.TextColor3=Color3.new(1,1,1)
autoFireButton.Font=Enum.Font.SourceSans
autoFireButton.Parent=MainFrame

local excludeDropdown=Instance.new("TextButton")
excludeDropdown.Size=UDim2.new(0,180,0,30)
excludeDropdown.Position=UDim2.new(0,10,0,contentYStart+120)
excludeDropdown.Text="點擊選擇排除玩家"
excludeDropdown.BackgroundColor3=Color3.new(0.3,0.3,0.3)
excludeDropdown.TextColor3=Color3.new(1,1,1)
excludeDropdown.Font=Enum.Font.SourceSans
excludeDropdown.Parent=MainFrame

local excludeListFrame=Instance.new("Frame")
excludeListFrame.Size=UDim2.new(0,180,0,150)
excludeListFrame.Position=UDim2.new(0,10,0,contentYStart+155)
excludeListFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)
excludeListFrame.Visible=false
excludeListFrame.Parent=MainFrame

local startY_WALL=contentYStart+200
local toggleWallBtn=Instance.new("TextButton")
toggleWallBtn.Size=UDim2.new(0,150,0,30)
toggleWallBtn.Position=UDim2.new(0,10,startY_WALL,0)
toggleWallBtn.Text="穿牆：OFF"
toggleWallBtn.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleWallBtn.TextColor3=Color3.new(1,1,1)
toggleWallBtn.Font=Enum.Font.SourceSans
toggleWallBtn.Parent=MainFrame

local function toggleUI()
    MainFrame.Visible=not MainFrame.Visible
    if MainFrame.Visible then
        toggleUIBtn.Text="隱藏控制台"
    else
        toggleUIBtn.Text="顯示控制台"
    end
end
toggleUIBtn.MouseButton1Click:Connect(toggleUI)

-- =================== 功能變數 ===================
local espEnabled=false
local espBoxes={}
local wallHackEnabled=false
local autoAimEnabled=false
local targetPartName="HumanoidRootPart"
local playerRootPart=nil
local excludedPlayers={} -- 排除隊友或屍體

local function getPlayerRootPart()
    local character=player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart
    end
    return nil
end

local function onCharacterAdded(character)
    local hrp=character:WaitForChild("HumanoidRootPart",5)
    if hrp then
        playerRootPart=hrp
    end
end
if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- =================== 透視（ESP） ===================
local function toggleESP()
    espEnabled=not espEnabled
    if espEnabled then
        toggleESPButton.Text="透視：ON"
        toggleESPButton.BackgroundColor3=Color3.new(1,0,0)
    else
        toggleESPButton.Text="切換ESP（OFF）"
        toggleESPButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
        for _,box in pairs(espBoxes) do
            if box and box.Parent then
                box.Parent:Destroy()
            end
        end
        espBoxes={}
    end
end
toggleESPButton.MouseButton1Click:Connect(toggleESP)

RunService.RenderStepped:Connect(function()
    -- 透視
    if espEnabled then
        for _,plr in pairs(Players:GetPlayers()) do
            if plr~=player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp=plr.Character.HumanoidRootPart
                local box=espBoxes[plr]
                if not box or not box.Parent then
                    box=Instance.new("BoxHandleAdornment")
                    box.Adornee=hrp
                    box.Size=hrp.Size
                    box.AlwaysOnTop=true
                    box.ZIndex=10
                    box.Color3=Color3.new(1,0,0)
                    box.Transparency=0.5
                    box.Parent=game.Workspace
                    espBoxes[plr]=box
                else
                    box.Adornee=hrp
                end
            end
        end
        -- 移除已不存在的玩家
        for plr,box in pairs(espBoxes) do
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
                if box and box.Parent then
                    box.Parent:Destroy()
                end
                espBoxes[plr]=nil
            end
        end
    end
    -- 穿牆
    if playerRootPart then
        if wallHackEnabled then
            playerRootPart.CanCollide=false
        else
            playerRootPart.CanCollide=true
        end
    end
    -- 自動瞄準
    if autoAimEnabled then
        local closestPlr=nil
        local closestDistance=math.huge
        local myPos=getPlayerRootPart().Position
        for _,plr in pairs(Players:GetPlayers()) do
            if plr~=player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- 排除隊友或屍體
                if plr.Team and player.Team and plr.Team==player.Team then
                    continue
                end
                if plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health<=0 then
                    continue
                end
                local hrp=plr.Character.HumanoidRootPart
                local dist=(hrp.Position - myPos).magnitude
                if dist<closestDistance then
                    closestDistance=dist
                    closestPlr=plr
                end
            end
        end
        if closestPlr and closestPlr.Character and closestPlr.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP=closestPlr.Character.HumanoidRootPart
            local camera=Workspace.CurrentCamera
            local camCF=camera.CFrame
            local targetPos=targetHRP.CFrame.Position
            local newCF=CFrame.lookAt(camCF.Position, targetPos)
            camera.CFrame=newCF
        end
    end
end)

-- =================== UI 按鈕事件 ===================

toggleWallBtn.MouseButton1Click:Connect(function()
    wallHackEnabled=not wallHackEnabled
    if wallHackEnabled then
        toggleWallBtn.Text="穿牆：ON"
        toggleWallBtn.BackgroundColor3=Color3.new(1,0,0)
    else
        toggleWallBtn.Text="穿牆：OFF"
        toggleWallBtn.BackgroundColor3=Color3.new(0.8,0.8,0.8)
        if playerRootPart then
            playerRootPart.CanCollide=true
        end
    end
end)

toggleESPButton.MouseButton1Click:Connect(function()
    toggleESP()
end)

toggleAimButton.MouseButton1Click:Connect(function()
    autoAimEnabled=not autoAimEnabled
    if autoAimEnabled then
        toggleAimButton.Text="自動瞄準：ON"
        toggleAimButton.BackgroundColor3=Color3.new(1,0,0)
    else
        toggleAimButton.Text="自動瞄準：OFF"
        toggleAimButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
    end
end)
