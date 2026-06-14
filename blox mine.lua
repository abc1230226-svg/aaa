-- 客戶端純粹用CoreGui界面控制的範例
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Effect = ReplicatedStorage:WaitForChild("Effect")
local Bindable = Effect:WaitForChild("Bindable")
local PunchModule = Effect:WaitForChild("Container"):WaitForChild("Chop"):WaitForChild("Punch")

-- 避免重複UI
local oldGui = PlayerGui:FindFirstChild("PunchSpeedController")
if oldGui then
    oldGui:Destroy()
end

-- 創建CoreGui界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PunchSpeedController"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = PlayerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 200, 0, 50)
toggleButton.Position = UDim2.new(0.5, -100, 0.1, 0)
toggleButton.Text = "開啟快速揮拳"
toggleButton.TextScaled = true
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Parent = ScreenGui

local isFast = false
local punchInterval = 0.2 -- 揮拳頻率

local function getCharacter()
    local charactersFolder = workspace:FindFirstChild("Characters")
    if not charactersFolder then
        warn("找不到 workspace.Characters")
        return nil
    end

    local character = charactersFolder:FindFirstChild("1234qwerasdfzxcv225")
    if not character then
        warn("找不到角色：1234qwerasdfzxcv225")
        return nil
    end

    return character
end

local function triggerPunch(duration)
    local Character = getCharacter()
    if not Character then return end
    -- 傳遞揮拳參數
    Bindable:Fire("spawn", PunchModule, {
        Character = Character,
        God = true,
        Duration = duration
    }, {
        Module = PunchModule,
        Name = "Chop.Punch",
        Id = 27977368
    })
end

toggleButton.MouseButton1Click:Connect(function()
    isFast = not isFast
    if isFast then
        toggleButton.Text = "關閉快速揮拳"
        toggleButton.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
    else
        toggleButton.Text = "開啟快速揮拳"
        toggleButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    end
end)

-- 持續自動觸發揮拳
task.spawn(function()
    while true do
        if isFast then
            triggerPunch(0.2)
            task.wait(punchInterval)
        else
            task.wait(0.1)
        end
    end
end)
