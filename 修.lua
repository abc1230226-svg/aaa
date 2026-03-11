-- 服務
local RunService = game:GetService("RunService")

-- 創建UI界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.Parent = game:GetService("CoreGui") -- 避免出錯

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 150)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
MainFrame.BackgroundTransparency = 0.5
MainFrame.Parent = ScreenGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "無後座力控制"
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.TextScaled = true
TitleLabel.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 150, 0, 40)
ToggleButton.Position = UDim2.new(0, 10, 0, 40)
ToggleButton.Text = "無後座力：關閉"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ToggleButton.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 180, 0, 40)
StatusLabel.Position = UDim2.new(0, 180, 0, 40)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "狀態：關閉"
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.TextScaled = true
StatusLabel.Parent = MainFrame

-- 狀態變數
local recoilEnabled = false

-- 按鈕切換
ToggleButton.MouseButton1Click:Connect(function()
    recoilEnabled = not recoilEnabled
    if recoilEnabled then
        ToggleButton.Text = "無後座力：開啟"
        StatusLabel.Text = "狀態：開啟"
    else
        ToggleButton.Text = "無後座力：關閉"
        StatusLabel.Text = "狀態：關閉"
    end
end)

-- 模擬偏移值
local recoilOffset = 0

-- 模擬射擊產生偏移（點擊UI按鈕或其他方式來模擬射擊）
local function simulateRecoil()
    if not recoilEnabled then
        -- 當關閉時，偏移會增加（模擬射擊造成偏移）
        recoilOffset = recoilOffset + math.random(2, 5)
    else
        -- 開啟無後座力時，不增加偏移
        recoilOffset = 0
    end
end

-- 這裡添加一個按鈕來模擬射擊，讓用戶可以點擊
local ShootButton = Instance.new("TextButton")
ShootButton.Size = UDim2.new(0, 150, 0, 40)
ShootButton.Position = UDim2.new(0, 10, 0, 90)
ShootButton.Text = "射擊"
ShootButton.TextColor3 = Color3.new(1, 1, 1)
ShootButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ShootButton.Parent = MainFrame

ShootButton.MouseButton1Click:Connect(function()
    simulateRecoil()
    print("射擊偏移：", recoilOffset)
end)

-- 每幀更新
RunService.RenderStepped:Connect(function()
    -- 如果開啟無後座力則偏移永遠為0
    if recoilEnabled then
        recoilOffset = 0
    end
    -- 你可以在這裡用 recoilOffset 控制相機或武器偏移
    -- 這裡只示範輸出
    -- print("偏移值：", recoilOffset)
end)
