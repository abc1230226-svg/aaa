local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game.Workspace

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 創建UI
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.new(1, 1, 1)

local function createButton(text, posY, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 150, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Text = text
    btn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    return btn
end

local toggleESPBtn = createButton("切換ESP（OFF）", 10, MainFrame)
local toggleAimBtn = createButton("切換自動瞄準（OFF）", 50, MainFrame)
local toggleWallBtn = createButton("穿牆：OFF", 90, MainFrame)

local espEnabled = false
local espBoxes = {}

local wallHackEnabled = false
local autoAimEnabled = false
local playerRootPart = nil

local function getPlayerRootPart()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart
    end
    return nil
end

local function onCharacterAdded(character)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        playerRootPart = hrp
    end
end
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- 透視（紅框）
local function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        toggleESPBtn.Text = "透視：ON"
        toggleESPBtn.BackgroundColor3 = Color3.new(1, 0, 0)
    else
        toggleESPBtn.Text = "切換ESP（OFF）"
        toggleESPBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
        -- 移除所有ESP框
        for _, box in pairs(espBoxes) do
            if box and box.Parent then
                box.Parent:Destroy()
            end
        end
        espBoxes = {}
    end
end
toggleESPBtn.MouseButton1Click:Connect(toggleESP)

-- 穿牆
local function toggleWall()
    wallHackEnabled = not wallHackEnabled
    if wallHackEnabled then
        toggleWallBtn.Text = "穿牆：ON"
        toggleWallBtn.BackgroundColor3 = Color3.new(1, 0, 0)
        if playerRootPart then
            playerRootPart.CanCollide = false
        end
    else
        toggleWallBtn.Text = "穿牆：OFF"
        toggleWallBtn.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
        if playerRootPart then
            playerRootPart.CanCollide = true
        end
    end
end
toggleWallBtn.MouseButton1Click:Connect(toggleWall)

-- 自動瞄準
local function toggleAutoAim()
    autoAimEnabled = not autoAimEnabled
    if autoAimEnabled then
        toggleAimBtn.Text = "自動瞄準：ON"
        toggleAimBtn.BackgroundColor3 = Color3.new(1, 0, 0)
    else
        toggleAimBtn.Text = "切換自動瞄準（OFF）"
        toggleAimBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    end
end
toggleAimBtn.MouseButton1Click:Connect(toggleAutoAim)

-- 主循環
RunService.RenderStepped:Connect(function()
    -- ESP（紅框）
    if espEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                local box = espBoxes[plr]
                if not box or not box.Parent then
                    box = Instance.new("BoxHandleAdornment")
                    box.Adornee = hrp
                    box.Size = hrp.Size
                    box.AlwaysOnTop = true
                    box.ZIndex = 10
                    box.Color3 = Color3.new(1, 0, 0)
                    box.Transparency = 0.5
                    box.Parent = Workspace
                    espBoxes[plr] = box
                else
                    box.Adornee = hrp
                end
            end
        end
        -- 移除不存在的玩家
        for plr, box in pairs(espBoxes) do
            if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
                if box and box.Parent then
                    box.Parent:Destroy()
                end
                espBoxes[plr] = nil
            end
        end
    end

    -- 穿牆（自己角色）
    if playerRootPart then
        if wallHackEnabled then
            playerRootPart.CanCollide = false
        else
            playerRootPart.CanCollide = true
        end
    end

    -- 自動瞄準
    if autoAimEnabled then
        local myPos = getPlayerRootPart().Position
        local closestPlr = nil
        local closestDist = math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- 排除隊友和屍體
                if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                    continue
                end
                if plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health <= 0 then
                    continue
                end
                local hrp = plr.Character.HumanoidRootPart
                local dist = (hrp.Position - myPos).magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlr = plr
                end
            end
        end
        if closestPlr and closestPlr.Character and closestPlr.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = closestPlr.Character.HumanoidRootPart
            local camera = Workspace.CurrentCamera
            local camCF = camera.CFrame
            local targetPos = targetHRP.CFrame.Position
            local newCF = CFrame.lookAt(camCF.Position, targetPos)
            camera.CFrame = newCF
        end
    end
end)

-- UI事件
toggleWallBtn.MouseButton1Click:Connect(function()
    toggleWall()
end)

toggleESPBtn.MouseButton1Click:Connect(function()
    toggleESP()
end)

toggleAimBtn.MouseButton1Click:Connect(function()
    toggleAutoAim()
end)
