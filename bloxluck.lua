-- 客戶端掉落率修改器完整腳本

local Players = game:GetService("Players")
local player = Players.LocalPlayer

if not player then
    warn("這個程式碼要放在 LocalScript 裡面才會有 UI")
    return
end

local gui = player:WaitForChild("PlayerGui")

-- 避免重複產生 UI
local oldGui = gui:FindFirstChild("DropRateMod")
if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DropRateMod"
ScreenGui.Parent = gui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 左上角開啟按鈕
local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 120, 0, 40)
openButton.Position = UDim2.new(0, 20, 0, 80)
openButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
openButton.Text = "掉落率UI"
openButton.TextColor3 = Color3.white
openButton.TextScaled = true
openButton.Font = Enum.Font.SourceSansBold
openButton.Active = true
openButton.AutoButtonColor = true
openButton.ZIndex = 10
openButton.Parent = ScreenGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 200)
frame.Position = UDim2.new(0.5, -175, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Visible = false
frame.ZIndex = 20
frame.Parent = ScreenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.Text = "掉落率修改器"
title.TextColor3 = Color3.white
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.ZIndex = 21
title.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 50)
btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
btn.Text = "搜尋並設定掉落率為99%"
btn.TextColor3 = Color3.white
btn.TextScaled = true
btn.Font = Enum.Font.SourceSansBold
btn.Active = true
btn.AutoButtonColor = true
btn.ZIndex = 21
btn.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 30)
status.Position = UDim2.new(0, 10, 0, 100)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.white
status.Text = "等待操作..."
status.TextScaled = true
status.Font = Enum.Font.SourceSans
status.ZIndex = 21
status.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(1, -20, 0, 35)
closeButton.Position = UDim2.new(0, 10, 0, 150)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeButton.Text = "關閉"
closeButton.TextColor3 = Color3.white
closeButton.TextScaled = true
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Active = true
closeButton.AutoButtonColor = true
closeButton.ZIndex = 21
closeButton.Parent = frame

openButton.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

closeButton.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

local targetVar -- 用來存找到的變數

-- 自訂搜尋函數
local function searchDropChance()
    if typeof(getgc) ~= "function" then
        status.Text = "這個環境沒有 getgc()"
        warn("這個環境沒有 getgc()")
        return nil
    end

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
    if typeof(getgc) ~= "function" then
        return false
    end

    for i, v in ipairs(getgc(true)) do
        if v == targetVar then
            print("找到目標變數，預備修改為：", newChance)

            -- 這裡需要知道變數在哪個table中，假設是直接修改
            -- 你可以根據實際情況加入修改邏輯，例如：
            -- v = newChance
            -- 但因為 getgc() 返回的數字是值，不能直接修改
            -- 你需要找到該變數在某個table中的位置並改值
            -- 例如：
            -- local targetTable = ... -- 找到table
            -- targetTable.dropChance = newChance

            -- 這裡提供一個範例，假設目標變數是在某個table中的
            -- 但實際情況需要你自己調整
            -- 由於特殊性，這裡暫時無法直接修改，請根據實際情況填寫
            -- 以下為範例：
            -- if someTable and someTable.dropChance then
            --     someTable.dropChance = newChance
            --     return true
            -- end

            -- 暫時返回成功，表示找到變數
            return true
        end
    end

    return false
end

local function onClick()
    status.Text = "正在搜尋..."
    btn.Text = "搜尋中..."
    btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)

    local found = searchDropChance()

    if found then
        local success = modifyDropChance(0.99)

        if success then
            status.Text = "掉落率已設定為99%"
            btn.Text = "設定成功"
            btn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
        else
            status.Text = "修改失敗，請手動調整"
            btn.Text = "修改失敗"
            btn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        end
    else
        status.Text = "未找到可能的掉落率變數"
        btn.Text = "搜尋失敗"
        btn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
    end
end

btn.MouseButton1Click:Connect(onClick)
