-- 偽代碼：攔截並修改射擊目標
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    -- 當遊戲嘗試發送「射擊」這個遠程事件時
    if method == "FireServer" and self.Name == "ShootEvent" then
        -- 找到最近的敵人
        local target = getClosestEnemy() 
        if target then
            -- 直接把子彈的「落點座標」改成敵人的頭部座標
            args[1] = target.Character.Head.Position 
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
