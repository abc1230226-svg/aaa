-- 創建UI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local AimbotToggle = Instance.new("TextButton")
local ESPToggle = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")

-- UI屬性設定
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "CheatMenu"

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 250, 0, 150)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.new(0, 0, 0)
Frame.BackgroundTransparency = 0.5
Frame.BorderSizePixel = 0

AimbotToggle.Parent = Frame
AimbotToggle.Size = UDim2.new(1, -20, 0, 40)
AimbotToggle.Position = UDim2.new(0, 10, 0, 10)
AimbotToggle.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
AimbotToggle.Text = "自瞄: 關閉"
AimbotToggle.TextColor3 = Color3.new(1, 1, 1)

ESPToggle.Parent = Frame
ESPToggle.Size = UDim2.new(1, -20, 0, 40)
ESPToggle.Position = UDim2.new(0, 10, 0, 60)
ESPToggle.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ESPToggle.Text = "ESP: 關閉"
ESPToggle.TextColor3 = Color3.new(1, 1, 1)

CloseButton.Parent = Frame
CloseButton.Size = UDim2.new(1, -20, 0, 40)
CloseButton.Position = UDim2.new(0, 10, 0, 110)
CloseButton.BackgroundColor3 = Color3.new(1, 0, 0)
CloseButton.Text = "關閉"
CloseButton.TextColor3 = Color3.new(1, 1, 1)

-- 狀態變數
local aimbotEnabled = false
local espEnabled = false

-- 按鈕事件
AimbotToggle.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        AimbotToggle.Text = "自瞄: 開啟"
    else
        AimbotToggle.Text = "自瞄: 關閉"
    end
end)

ESPToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        ESPToggle.Text = "ESP: 開啟"
    else
        ESPToggle.Text = "ESP: 關閉"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- 自瞄功能範例（簡單的模擬範例）
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local function getClosestPlayer()
    local closestDist = math.huge
    local closestPlayer = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).magnitude
            if distance < closestDist then
                closestDist = distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer
end

-- ESP範例：在玩家頭上畫框
local function drawESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local box = Instance.new("BillboardGui", player.Character.Head)
            box.Name = "ESPBox"
            box.Size = UDim2.new(0, 100, 0, 100)
            box.Adornee = player.Character.Head
            box.AlwaysOnTop = true
            local frame = Instance.new("Frame", box)
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.new(1, 0, 0)
            frame.BorderSizePixel = 0
        end
    end
end

local espDrawnPlayers = {}

-- 運行循環
RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            -- 自瞄：簡單的模擬（實際會用更複雜的控制）
            local hrp = target.Character.HumanoidRootPart
            -- 這裡可以加入自瞄的實現（如調整相機或滑鼠位置）
            -- 由於示範，這裡不做實際的控制
        end
    end

    if espEnabled then
        -- 添加ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character and not player.Character:FindFirstChild("ESPBox") then
                -- 如果沒畫就畫
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local box = Instance.new("BillboardGui", head)
                    box.Name = "ESPBox"
                    box.Size = UDim2.new(0, 100, 0, 100)
                    box.Adornee = head
                    box.AlwaysOnTop = true
                    local frame = Instance.new("Frame", box)
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.BackgroundColor3 = Color3.new(1, 0, 0)
                    frame.BorderSizePixel = 0
                end
            end
        end
        -- 移除已不存在的ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local esp = player.Character:FindFirstChild("ESPBox")
                if not player.Character:FindFirstChild("Head") and esp then
                    esp:Destroy()
                end
            end
        end
    end
end)
