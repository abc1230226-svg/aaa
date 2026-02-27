local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

local Window = Rayfield:CreateWindow({
   Name = "Insane Gun 暴力控制台",
   LoadingTitle = "正在載入內部腳本...",
   LoadingSubtitle = "by Rivals Destroyer",
})

local MainTab = Window:CreateTab("主要功能", 4483362458) -- 圖示 ID

-- 1. 靜默自瞄開關
local SilentAimEnabled = false
MainTab:CreateToggle({
   Name = "靜默槍 (Silent Aim)",
   CurrentValue = false,
   Callback = function(Value)
      SilentAimEnabled = Value
      -- 這裡接入你攔截 Namecall 的邏輯
   end,
})

-- 2. 瘋狂射速開關
local RapidFireEnabled = false
MainTab:CreateToggle({
   Name = "瘋狂射速 (Rapid Fire)",
   CurrentValue = false,
   Callback = function(Value)
      RapidFireEnabled = Value
      if Value then
          task.spawn(function()
              while RapidFireEnabled do
                  -- 模擬按下開火鍵或直接觸發 FireServer
                  -- game.ReplicatedStorage.ShootEvent:FireServer()
                  task.wait(0.01) -- 極速冷卻
              end
          end)
      end
   end,
})

-- 3. 魔法子彈/穿牆
MainTab:CreateButton({
   Name = "開啟魔法子彈 (Wallbang)",
   Callback = function()
       Rayfield:Notify({Title = "功能已開啟", Content = "所有子彈將無視障礙物直接命中目標"})
       -- 這裡放入修改 RaycastParams 的代碼
   end,
})

-- 4. 數值滑桿：調整射程或碰撞箱大小
MainTab:CreateSlider({
   Name = "Hitbox 擴大倍率",
   Range = {1, 50},
   Increment = 1,
   CurrentValue = 1,
   Callback = function(Value)
      -- 修改所有敵人的 HumanoidRootPart.Size
   end,
})
