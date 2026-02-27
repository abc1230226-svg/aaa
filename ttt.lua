-- 確保你已經在遊戲中用Delta注入器注入
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- 定義你的Aim範圍
local aimRange = 100 -- 你可以調整範圍

-- 找到ShootEvent
local shootEvent = ReplicatedStorage:FindFirstChild("ShootEvent")
if not shootEvent then
    print("找不到ShootEvent，請確認名稱正確")
    return
end

-- 保存原始FireServer
local originalFireServer = shootEvent.FireServer

-- 定義一個函數，取得最近的敵人頭部位置
local function getClosestEnemyHeadPosition()
    local minDist = math.huge
    local targetPos = nil
    local selfHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return nil end

    for _,enemy in ipairs(Players:GetPlayers()) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            -- 排除自己
            if enemy ~= LocalPlayer then
                -- 排除隊友
                if enemy.Team ~= LocalPlayer.Team then
                    -- 排除已死的
                    local humanoid = enemy.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local head = enemy.Character:FindFirstChild("Head")
                        if head then
                            local dist = (head.Position - selfHRP.Position).Magnitude
                            if dist <= aimRange and dist < minDist then
                                minDist = dist
                                targetPos = head.Position
                            end
                        end
                    end
                end
            end
        end
    end
    return targetPos
end

-- Hook FireServer
shootEvent.FireServer = function(self, ...)
    local args = {...}
    local targetHeadPos = getClosestEnemyHeadPosition()
    if targetHeadPos then
        -- 讓子彈穿牆直接命中
        args[1] = targetHeadPos
    end
    -- 呼叫原始的FireServer
    return originalFireServer(self, unpack(args))
end

print("ShootEvent FireServer成功Hook，子彈將直接命中敵人頭部並穿牆")
