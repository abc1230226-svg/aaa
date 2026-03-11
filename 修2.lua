local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- 建立UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimAssistUI"
ScreenGui.Parent = game:GetService("CoreGui")

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

local ShootButton = Instance.new("TextButton")
ShootButton.Size = UDim2.new(0, 150, 0, 40)
ShootButton.Position = UDim2.new(0, 10, 0, 90)
ShootButton.Text = "射擊"
ShootButton.TextColor3 = Color3.new(1, 1, 1)
ShootButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
ShootButton.Parent = MainFrame

-- 狀態變數
local recoilEnabled = false
local recoilOffset = Vector3.new(0,0,0)

-- 切換UI狀態
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

-- 模擬射擊
local function simulateRecoil()
    if not recoilEnabled then
        -- 模擬射擊產生偏移（隨機偏移角度）
        local angleX = math.random(-2, 2)
        local angleY = math.random(-2, 2)
        recoilOffset = Vector3.new(angleY, angleX, 0)
    else
        recoilOffset = Vector3.new(0,0,0)
    end
end

ShootButton.MouseButton1Click:Connect(function()
    simulateRecoil()
    print("偏移：", recoilOffset)
end)

-- 每幀更新
RunService.RenderStepped:Connect(function()
    if recoilEnabled then
        recoilOffset = Vector3.new(0,0,0)
    end
    -- 這裡將偏移應用到相機
    -- 例如：將相機角度微調
    -- 這裡假設你是用第一人稱
    Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(recoilOffset.X), math.rad(recoilOffset.Y), 0)
end)
