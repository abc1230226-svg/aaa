local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LocalPlayer=Players.LocalPlayer

-- UI設置
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimAssistUI"

-- 改成在PlayerGui中顯示
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

-- 顯示/隱藏控制台按鈕
local toggleUIBtn=Instance.new("TextButton")
toggleUIBtn.Size=UDim2.new(0,150,0,30)
toggleUIBtn.Position=UDim2.new(0,10,0,0)
toggleUIBtn.Text="隱藏控制台"
toggleUIBtn.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleUIBtn.TextColor3=Color3.new(1,1,1)
toggleUIBtn.Font=Enum.Font.SourceSansBold
toggleUIBtn.Parent=MainFrame

local contentYStart=40 -- 內容起點Y

-- ESP切換按鈕
local toggleESPButton=Instance.new("TextButton")
toggleESPButton.Size=UDim2.new("0",150,"0",30)
toggleESPButton.Position=UDim2.new(0,10,0,contentYStart)
toggleESPButton.Text="切換ESP（OFF）"
toggleESPButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleESPButton.TextColor3=Color3.new(1,1,1)
toggleESPButton.Font=Enum.Font.SourceSans
toggleESPButton.Parent=MainFrame

-- 自動瞄準切換
local toggleAimButton=Instance.new("TextButton")
toggleAimButton.Size=UDim2.new("0",150,"0",30)
toggleAimButton.Position=UDim2.new(0,10,0,contentYStart+40)
toggleAimButton.Text="切換自動瞄準（OFF）"
toggleAimButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleAimButton.TextColor3=Color3.new(1,1,1)
toggleAimButton.Font=Enum.Font.SourceSans
toggleAimButton.Parent=MainFrame

-- 自動爆頭按鈕
local autoFireButton=Instance.new("TextButton")
autoFireButton.Size=UDim2.new("0",150,"0",30)
autoFireButton.Position=UDim2.new(0,10,0,contentYStart+80)
autoFireButton.Text="按住左鍵自動爆頭"
autoFireButton.BackgroundColor3=Color3.new(0.2,0.2,0.2)
autoFireButton.TextColor3=Color3.new(1,1,1)
autoFireButton.Font=Enum.Font.SourceSans
autoFireButton.Parent=MainFrame

-- 排除玩家下拉按鈕
local excludeDropdown=Instance.new("TextButton")
excludeDropdown.Size=UDim2.new(0,180,0,30)
excludeDropdown.Position=UDim2.new(0,10,0,contentYStart+120)
excludeDropdown.Text="點擊選擇排除玩家"
excludeDropdown.BackgroundColor3=Color3.new(0.3,0.3,0.3)
excludeDropdown.TextColor3=Color3.new(1,1,1)
excludeDropdown.Font=Enum.Font.SourceSans
excludeDropdown.Parent=MainFrame

-- 排除列表框
local excludeListFrame=Instance.new("Frame")
excludeListFrame.Size=UDim2.new(0,180,0,150)
excludeListFrame.Position=UDim2.new(0,10,0,contentYStart+155)
excludeListFrame.BackgroundColor3=Color3.new(0.2,0.2,0.2)
excludeListFrame.Visible=false
excludeListFrame.Parent=MainFrame

-- 穿牆控制按鈕
local startY_WALL=contentYStart+200
local toggleWallBtn=Instance.new("TextButton")
toggleWallBtn.Size=UDim2.new(0,150,0,30)
toggleWallBtn.Position=UDim2.new(0,10,startY_WALL,0)
toggleWallBtn.Text="穿牆：OFF"
toggleWallBtn.BackgroundColor3=Color3.new(0.2,0.2,0.2)
toggleWallBtn.TextColor3=Color3.new(1,1,1)
toggleWallBtn.Font=Enum.Font.SourceSans
toggleWallBtn.Parent=MainFrame

-- 顯示/隱藏整個UI
local function toggleUI()
    MainFrame.Visible=not MainFrame.Visible
    if MainFrame.Visible then
        toggleUIBtn.Text="隱藏控制台"
    else
        toggleUIBtn.Text="顯示控制台"
    end
end

toggleUIBtn.MouseButton1Click:Connect(toggleUI)

-- =================== 穿牆功能 ===================
local wallHackEnabled=false -- 穿牆開關
local playerRootPart=nil -- 角色HumanoidRootPart

local function getPlayerRootPart()
    local character=LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart
    end
    return nil
end

local function onCharacterAdded(character)
    local hrp=character:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        playerRootPart=hrp
    end
end

-- 初始角色
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
-- 監聽角色重生
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- 按鈕事件：切換穿牆
toggleWallBtn.MouseButton1Click:Connect(function()
    wallHackEnabled=not wallHackEnabled
    if wallHackEnabled then
        toggleWallBtn.Text="穿牆：ON"
        toggleWallBtn.BackgroundColor3=Color3.new(1,0,0)
    else
        toggleWallBtn.Text="穿牆：OFF"
        toggleWallBtn.BackgroundColor3=Color3.new(0.8,0.8,0.8)
        -- 取消穿牆時恢復碰撞
        if playerRootPart then
            playerRootPart.CanCollide=true
        end
    end
end)

-- 每幀控制穿牆
RunService.RenderStepped:Connect(function()
    if not playerRootPart then
        playerRootPart=getPlayerRootPart()
        return
    end
    if wallHackEnabled and playerRootPart then
        playerRootPart.CanCollide=false
    else
        if playerRootPart then
            playerRootPart.CanCollide=true
        end
    end
end)
