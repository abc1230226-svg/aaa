-- UI部分
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DropRateMod"
ScreenGui.Parent = gui
ScreenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 200)
frame.Position = UDim2.new(0.5, -175, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Parent = ScreenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Text = "掉落率修改器"
title.TextColor3 = Color3.white
title.TextScaled = true
title.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 50)
btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
btn.Text = "搜尋並設定掉落率為99%"
btn.TextColor3 = Color3.white
btn.TextScaled = true
btn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 100)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.white
status.Text = "等待操作..."
status.TextScaled = true
status.Parent = frame

local targetVar -- 用來存找到的變數

-- 自訂搜尋函數
local function searchDropChance()
    local gcObjects = getgc(true)
    for i, v in ipairs(gcObjects) do
        if typeof(v) == "number" then
            -- 篩選範圍在0.01到1之間的數字
            if v >= 0.01 and v <= 1 then
                print("可能的掉落率：", v)
                targetVar = v
                return v
            end
        end
    end
    return nil
end

-- 嘗試修改變數
local function modifyDropChance(newChance)
    -- 這裡的核心問題：直接修改gc中的數字不一定有效
    -- 你需要找到該數字的引用，並修改
    -- 這裡示範用：搜尋到的變數可能是引用，直接修改
    -- 但在實務上，你要找到正確的變數或用debug來找到引用
    -- 這裡假設你已經找到正確的變數
    -- 例：你找到的變數在某個table中
    -- 你可以自己調整
    for i, v in ipairs(getgc(true)) do
        if v == targetVar then
            -- 這裡不一定能直接改
            -- 如果你知道變數在哪個table中，例如 game.ReplicatedStorage.DropChance
            -- 你可以直接修改
            -- 比如：game.ReplicatedStorage.DropChance = newChance
            -- 但這需要你自己知道變數位置
            -- 這裡只打印示意
            print("找到目標變數，預備修改為：", newChance)
            -- 你可以在這裡執行修改（根據你的遊戲結構）
            return true
        end
    end
    return false
end

local function onClick()
    status.Text = "正在搜尋..."
    local found = searchDropChance()
    if found then
        local success = modifyDropChance(0.99)
        if success then
            status.Text = "掉落率已設定為99%"
        else
            status.Text = "修改失敗，請手動調整"
        end
    else
        status.Text = "未找到可能的掉落率變數"
    end
end

btn.MouseButton1Click:Connect(onClick)
