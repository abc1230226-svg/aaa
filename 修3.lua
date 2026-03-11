local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local isShooting = false
local lockedCFrame = nil

-- 模擬射擊觸發（用你自己的觸發條件）
function shoot()
    -- 記錄當前相機角度
    lockedCFrame = Camera.CFrame
    isShooting = true
    -- 你可以在這裡加入實際射擊的邏輯
end

-- 例如用某個按鍵觸發
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        shoot()
    end
end)

-- 每幀保持相機角度不變
RunService.RenderStepped:Connect(function()
    if isShooting and lockedCFrame then
        -- 強制相機保持在鎖定的角度
        Camera.CFrame = lockedCFrame
    end
end)
