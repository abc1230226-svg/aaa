-- 預設載入
if not game:IsLoaded() then game.Loaded:Wait() end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local MainFileName = "UniversalSilentAim"

local SilentAimSettings = {
    Enabled = false,
    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "RightAlt",
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false,
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

-- 全局設置
getgenv().SilentAimSettings = SilentAimSettings

-- 服務
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- 常用函數
local function getMousePosition()
    return UserInputService:GetMouseLocation()
end

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = SilentAimSettings.MouseHitPredictionAmount

-- 目標UI元素
local function createVisuals()
    local mouse_box = Drawing.new("Square")
    mouse_box.Visible = false
    mouse_box.ZIndex = 999
    mouse_box.Color = Color3.fromRGB(54, 57, 241)
    mouse_box.Thickness = 20
    mouse_box.Size = Vector2.new(20, 20)
    mouse_box.Filled = true

    local fov_circle = Drawing.new("Circle")
    fov_circle.Thickness = 1
    fov_circle.NumSides = 100
    fov_circle.Radius = SilentAimSettings.FOVRadius
    fov_circle.Filled = false
    fov_circle.Visible = false
    fov_circle.ZIndex = 999
    fov_circle.Transparency = 1
    fov_circle.Color = Color3.fromRGB(54, 57, 241)

    return mouse_box, fov_circle
end

local mouse_box, fov_circle = createVisuals()

-- 目標取得
local function getClosestPlayer()
    local closest, minDist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if SilentAimSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        local char = player.Character
        if not char then continue end
        local rootPart = char:FindFirstChild(SilentAimSettings.TargetPart) or char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid or humanoid.Health <= 0 then continue end
        if SilentAimSettings.VisibleCheck and not game:GetService("Workspace"):FindPartOnRay(Ray.new(rootPart.Position, Vector3.new(0, -1, 0)), {LocalPlayer.Character}) then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then continue end
        local dist = (getMousePosition() - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
        if dist < minDist and dist <= SilentAimSettings.FOVRadius then
            closest = rootPart
            minDist = dist
        end
    end
    return closest
end

-- 針對擊中率進行判斷
local function calculateHitChance()
    local chance = math.random(0, 100)
    return chance <= SilentAimSettings.HitChance
end

-- 檢查參數是否符合
local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {"Instance", "Ray", "table", "boolean", "boolean"}
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {"Instance", "Ray", "table", "boolean"}
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {"Instance", "Ray", "Instance", "boolean", "boolean"}
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {"Instance", "Vector3", "Vector3", "RaycastParams"}
    }
}

local function validateArguments(args, method)
    if #args < method.ArgCountRequired then return false end
    for i, argType in ipairs(method.Args) do
        if typeof(args[i]) ~= argType then
            return false
        end
    end
    return true
end

-- hook自定義
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if SilentAimSettings.Enabled and not checkcaller() then
        if not calculateHitChance() then return oldNamecall(self, table.unpack(args)) end
        if method == "FindPartOnRay" and validateArguments(args, ExpectedArguments.FindPartOnRay) then
            local targetPart = getClosestPlayer()
            if targetPart then
                local origin = args[2].Origin
                local direction = (targetPart.Position - origin).unit * 999
                args[2] = Ray.new(origin, direction)
                return oldNamecall(self, table.unpack(args))
            end
        elseif method == "FindPartOnRayWithIgnoreList" and validateArguments(args, ExpectedArguments.FindPartOnRayWithIgnoreList) then
            local targetPart = getClosestPlayer()
            if targetPart then
                local origin = args[2].Origin
                local direction = (targetPart.Position - origin).unit * 999
                args[2] = Ray.new(origin, direction)
                return oldNamecall(self, table.unpack(args))
            end
        elseif method == "FindPartOnRayWithWhitelist" and validateArguments(args, ExpectedArguments.FindPartOnRayWithWhitelist) then
            local targetPart = getClosestPlayer()
            if targetPart then
                local origin = args[2].Origin
                local direction = (targetPart.Position - origin).unit * 999
                args[2] = Ray.new(origin, direction)
                return oldNamecall(self, table.unpack(args))
            end
        elseif method == "Raycast" and validateArguments(args, ExpectedArguments.Raycast) then
            local origin = args[2]
            local target = getClosestPlayer()
            if target then
                args[3] = (target.Position - origin).unit * 999
                return oldNamecall(self, table.unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, index)
    if self == Mouse and index == "Target" and SilentAimSettings.Enabled then
        local target = getClosestPlayer()
        if target then
            return target
        end
    elseif self == Mouse and index == "Hit" and SilentAimSettings.Enabled then
        local target = getClosestPlayer()
        if target then
            if SilentAimSettings.MouseHitPrediction then
                return Ray.new(target.CFrame.Position, target.Velocity * PredictionAmount)
            else
                return target.CFrame
            end
        end
    end
    return oldIndex(self, index)
end)

-- UI與控制
local function setupUI()
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
    Library:SetWatermark("github.com/Averiias")
    local Window = Library:CreateWindow({Title = 'Universal Silent Aim', Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2})
    local GeneralTab = Window:AddTab("General")
    local MainBOX = GeneralTab:AddLeftTabbox("Main")
    do
        local Main = MainBOX:AddTab("Main")
        -- 啟用開關
        local enableToggle = Main:AddToggle("aim_Enabled", {Text = "Enabled"})
        enableToggle:AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle"})
        Options.aim_Enabled_KeyPicker = enableToggle.KeyPicker
        enableToggle:OnClick(function()
            SilentAimSettings.Enabled = not SilentAimSettings.Enabled
            mouse_box.Visible = SilentAimSettings.Enabled
        end)

        -- 其他選項
        Main:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
            SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
        end)
        Main:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
            SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
        end)
        Main:AddDropdown("TargetPart", {AllowNull = true, Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}}):OnChanged(function()
            SilentAimSettings.TargetPart = Options.TargetPart.Value
        end)
        Main:AddDropdown("Method", {AllowNull = true, Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {
            "Raycast","FindPartOnRay",
            "FindPartOnRayWithWhitelist",
            "FindPartOnRayWithIgnoreList",
            "Mouse.Hit/Target"
        }}):OnChanged(function() 
            SilentAimSettings.SilentAimMethod = Options.Method.Value 
        end)
        Main:AddSlider('HitChance', {
            Text = 'Hit chance',
            Default = 100,
            Min = 0,
            Max = 100,
            Rounding = 1,
        }):OnChanged(function()
            SilentAimSettings.HitChance = Options.HitChance.Value
        end)
    end
    -- 額外UI設置省略（依照原腳本）
end

setupUI()

-- 每幀畫面更新
RunService.RenderStepped:Connect(function()
    if SilentAimSettings.ShowSilentAimTarget and SilentAimSettings.Enabled then
        local target = getClosestPlayer()
        if target then
            local rootPart = target.Parent and target.Parent:FindFirstChild("HumanoidRootPart") or target
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            mouse_box.Visible = onScreen
            mouse_box.Position = Vector2.new(screenPos.X, screenPos.Y)
        else
            mouse_box.Visible = false
        end
    end
    -- FOV圈
    if SilentAimSettings.FOVVisible then
        fov_circle.Visible = true
        fov_circle.Position = getMousePosition()
        fov_circle.Radius = SilentAimSettings.FOVRadius
        fov_circle.Color = Color3.fromRGB(54, 57, 241)
    else
        fov_circle.Visible = false
    end
end)
