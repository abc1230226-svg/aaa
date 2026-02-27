if _G.AutoAimLockUI then return end
_G.AutoAimLockUI=true

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local workspace=game:GetService("Workspace")
local LocalPlayer=Players.LocalPlayer

-- 創建UI界面
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AimLockUI"
ScreenGui.Parent=game:GetService("CoreGui")

local MainFrame=Instance.new("Frame")
MainFrame.Size=UDim2.new(0,350,0,200)
MainFrame.Position=UDim2.new(0,10,0,10)
MainFrame.BackgroundColor3=Color3.new(0,0,0)
MainFrame.BackgroundTransparency=0.5
MainFrame.Parent=ScreenGui

local toggleUIBtn=Instance.new("TextButton")
toggleUIBtn.Size=UDim2.new(0,150,0,30)
toggleUIBtn.Position=UDim2.new(0,10,0,0)
toggleUIBtn.Text="隱藏控制台"
toggleUIBtn.Parent=MainFrame

local lockBtn=Instance.new("TextButton")
lockBtn.Size=UDim2.new(0,150,0,30)
lockBtn.Position=UDim2.new(0,10,0,40)
lockBtn.Text="鎖定敵人"
lockBtn.Parent=MainFrame

local unlockBtn=Instance.new("TextButton")
unlockBtn.Size=UDim2.new(0,150,0,30)
unlockBtn.Position=UDim2.new(0,10,0,80)
unlockBtn.Text="解除鎖定"
unlockBtn.Parent=MainFrame

local toggleWallBtn=Instance.new("TextButton")
toggleWallBtn.Size=UDim2.new(0,150,0,30)
toggleWallBtn.Position=UDim2.new(0,170,0,40)
toggleWallBtn.Text="穿牆子彈 ON"
toggleWallBtn.Parent=MainFrame

local statusLabel=Instance.new("TextLabel")
statusLabel.Size=UDim2.new(1,0,0,30)
statusLabel.Position=UDim2.new(0,0,0,120)
statusLabel.Text="狀態：未鎖定"
statusLabel.TextColor3=Color3.new(1,1,1)
statusLabel.BackgroundTransparency=1
statusLabel.Parent=MainFrame

-- UI控制變數
local isLocked=false
local lockedTarget=nil
local穿牆=true -- 穿牆開關

toggleUIBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible=not MainFrame.Visible
    if MainFrame.Visible then
        toggleUIBtn.Text="隱藏控制台"
    else
        toggleUIBtn.Text="顯示控制台"
    end
end)

lockBtn.MouseButton1Click:Connect(function()
    -- 鎖定最近敵人
    local minDist=math.huge
    local target=nil
    local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return end
    for _,enemy in ipairs(Players:GetPlayers()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") and enemy.Character:FindFirstChild("Humanoid") then
            if enemy~=LocalPlayer and enemy.Character.Humanoid.Health>0 then
                local dist=(enemy.Character.HumanoidRootPart.Position - selfHRP.Position).Magnitude
                if dist<50 and dist<minDist then
                    minDist=dist
                    target=enemy
                end
            end
        end
    end
    if target then
        lockedTarget=target
        isLocked=true
        statusLabel.Text="狀態：已鎖定 "..target.Name
    end
end)

unlockBtn.MouseButton1Click:Connect(function()
    isLocked=false
    lockedTarget=nil
    statusLabel.Text="狀態：未鎖定"
end)

toggleWallBtn.MouseButton1Click:Connect(function()
    穿牆=not 穿牆
    if 穿牆 then
        toggleWallBtn.Text="穿牆子彈 ON"
    else
        toggleWallBtn.Text="穿牆子彈 OFF"
    end
end)

-- 每幀保持鎖定目標
RunService.RenderStepped:Connect(function()
    if isLocked and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos=lockedTarget.Character.HumanoidRootPart.Position
        local selfHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if selfHRP then
            local cf=CFrame.new(selfHRP.Position, targetPos)
            workspace.CurrentCamera.CFrame=cf
        end
    end
end)

-- hook子彈發射事件，讓子彈穿牆
local shootEvent=game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent")
if shootEvent then
    hookfunction(shootEvent.FireServer, function(...)
        local args={...}
        local targetPos=args[1]
        if isLocked and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
            targetPos=lockedTarget.Character.Head.Position
        end
        -- 改變子彈目標位置，使子彈穿牆
        args[1]=targetPos
        return shootEvent.FireServer(unpack(args))
    end)
end
