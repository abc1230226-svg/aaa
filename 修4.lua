local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- 建立UI
local screenGui = Instance.new("ScreenGui", PlayerGui)
local toggleButton = Instance.new("TextButton", screenGui)
toggleButton.Size = UDim2.new(0, 200, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "開啟無後座力"

local noRecoilEnabled = false
local isShooting = false
local lockedCFrame = nil

toggleButton.MouseButton1Click:Connect(function()
    noRecoilEnabled = not noRecoilEnabled
    if noRecoilEnabled then
        toggleButton.Text = "關閉無後座力"
    else
        toggleButton.Text = "開啟無後座力"
    end
end)

-- 模擬射擊（你可以改成你的射擊觸發條件）
function shoot()
    if not noRecoilEnabled then return end
    lockedCFrame = Camera.CFrame
    isShooting = true
    -- 你可以在此加入實際射擊的邏輯
end

-- 用鼠標左鍵觸發射擊
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
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
