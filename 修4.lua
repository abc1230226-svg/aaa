local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui")

-- 創建UI界面
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoRecoilUI"
screenGui.Parent = PlayerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 200, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "開啟無後座力"
toggleButton.Parent = screenGui

-- 狀態變數
local noRecoilEnabled = false
local isShooting = false
local lockedCFrame = nil

-- 按鈕點擊切換
toggleButton.MouseButton1Click:Connect(function()
    noRecoilEnabled = not noRecoilEnabled
    if noRecoilEnabled then
        toggleButton.Text = "關閉無後座力"
    else
        toggleButton.Text = "開啟無後座力"
    end
end)

-- 模擬射擊（可改成你的射擊條件）
function shoot()
    if not noRecoilEnabled then return end
    lockedCFrame = Camera.CFrame
    isShooting = true
end

-- 用鼠標左鍵射擊
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shoot()
    end
end)

-- 每幀保持相機角度
RunService.RenderStepped:Connect(function()
    if noRecoilEnabled and isShooting and lockedCFrame then
        Camera.CFrame = lockedCFrame
    end
end)
