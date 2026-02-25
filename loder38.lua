-- 基本服務
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- UI設計
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 320, 0, 150)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.new(0,0,0)
Frame.BackgroundTransparency = 0.3
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.new(1,1,1)

local function createButton(name, posY, label)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 150, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Text = label
    btn.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.Name = name
    return btn
end

local espBtn = createButton("ESP", 10, "透視（OFF）")
local aimBtn = createButton("Aim", 50, "自瞄（OFF）")
local wallBtn = createButton("Wall", 90, "穿牆（OFF）")

-- 狀態變數
local espActive = false
local aimActive = false
local wallActive = false

local espBoxes = {} --敵人紅框

-- 取得玩家HumanoidRootPart
local function getMyRootPart()
    local chr = LocalPlayer.Character
    if chr and chr:FindFirstChild("HumanoidRootPart") then
        return chr.HumanoidRootPart
    end
end
local myRootPart = getMyRootPart()

LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    myRootPart = getMyRootPart()
end)

-- 透視開關
local function toggleESP()
    espActive = not espActive
    if espActive then
        espBtn.Text = "透視（ON）"
        espBtn.BackgroundColor3 = Color3.new(1,0,0)
    else
        espBtn.Text = "透視（OFF）"
        espBtn.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
        for _, box in pairs(espBoxes) do
            if box and box.Parent then
                box.Parent = nil
            end
        end
        espBoxes = {}
    end
end
espBtn.MouseButton1Click:Connect(toggleESP)

-- 自瞄開關
local function toggleAim()
    aimActive = not aimActive
    if aimActive then
        aimBtn.Text = "自瞄（ON）"
        aimBtn.BackgroundColor3 = Color3.new(1,0,0)
    else
        aimBtn.Text = "自瞄（OFF）"
        aimBtn.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
    end
end
aimBtn.MouseButton1Click:Connect(toggleAim)

-- 穿牆開關
local function toggleWall()
    wallActive = not wallActive
    if wallActive then
        wallBtn.Text = "穿牆（ON）"
        wallBtn.BackgroundColor3 = Color3.new(1,0,0)
        if myRootPart then myRootPart.CanCollide = false end
    else
        wallBtn.Text = "穿牆（OFF）"
        wallBtn.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
        if myRootPart then myRootPart.CanCollide = true end
    end
end
wallBtn.MouseButton1Click:Connect(toggleWall)

-- 主循環
RunService.RenderStepped:Connect(function()
    -- 透視敵人
    if espActive then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if not espBoxes[plr] then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Adornee = plr.Character.HumanoidRootPart
                    box.Size = plr.Character.HumanoidRootPart.Size
                    box.Color3 = Color3.new(1,0,0)
                    box.Transparency = 0.3
                    box.ZIndex = 10
                    box.AlwaysOnTop = true
                    box.Parent = Workspace
                    espBoxes[plr] = box
                else
                    espBoxes[plr].Adornee = plr.Character.HumanoidRootPart
                end
            end
        end
        -- 移除不存在的
        for plr, box in pairs(espBoxes) do
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
                if box and box.Parent then
                    box.Parent = nil
                end
                espBoxes[plr] = nil
            end
        end
    end

    -- 穿牆
    if myRootPart then
        myRootPart.CanCollide = not wallActive
    end

    -- 自瞄
    if aimActive then
        local closestDist = math.huge
        local targetPlr = nil
        local myPos = getMyRootPart().Position
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- 排除隊友和屍體
                if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end
                local humanoid=plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health<=0 then continue end
                local hrp = plr.Character.HumanoidRootPart
                local dist = (hrp.Position - myPos).magnitude
                if dist < closestDist then
                    closestDist = dist
                    targetPlr = plr
                end
            end
        end
        -- 轉頭對準
        if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = targetPlr.Character.HumanoidRootPart.Position
            local camCF = Camera.CFrame
            local newCF = CFrame.lookAt(camCF.Position, targetPos)
            Camera.CFrame = newCF
        end
    end
end)

-- 模擬開槍，黏到敵人頭上（穿牆爆頭）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- 找最近的敵人頭部
        local closestDist = math.huge
        local hitHead = nil
        local myPos = getMyRootPart().Position
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                if not plr.Character:FindFirstChildOfClass("Humanoid") then continue end
                local humanoid=plr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health<=0 then continue end
                -- 排除隊友
                if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then continue end
                local head = plr.Character.Head
                local dist = (head.Position - myPos).magnitude
                if dist < closestDist then
                    closestDist=dist
                    hitHead = head
                end
            end
        end
        if hitHead then
            -- 模擬子彈黏到頭上造成爆頭
            local humanoid=hitHead.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health=0 -- 爆頭
            end
        end
    end
end)
