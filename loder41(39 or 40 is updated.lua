-- 透視（全身紅框）與敵人位置框
RunService.RenderStepped:Connect(function()
    -- 更新敵人紅框
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v ~= LocalPlayer.Character then
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hrp then
                if espToggle then
                    if not espBoxes[v] then
                        espBoxes[v] = createESPBox()
                        espBoxes[v].Parent = nil -- 不用設parent，直接用Drawing
                    end
                    local box = espBoxes[v]
                    
                    -- 計算模型的AABB（包圍盒）範圍
                    local minX, minY, minZ = math.huge, math.huge, math.huge
                    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

                    -- 遍歷所有Parts來找到包圍盒
                    local parts = {}
                    for _, p in pairs(v:GetChildren()) do
                        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                            table.insert(parts, p)
                        end
                    end

                    if #parts > 0 then
                        for _, part in pairs(parts) do
                            local cf = part.CFrame
                            local size = part.Size
                            local corners = {
                                cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                                cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                                cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                                cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                                cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                                cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                            }
                            for _, corner in pairs(corners) do
                                local pos = corner.Position
                                minX = math.min(minX, pos.X)
                                minY = math.min(minY, pos.Y)
                                minZ = math.min(minZ, pos.Z)
                                maxX = math.max(maxX, pos.X)
                                maxY = math.max(maxY, pos.Y)
                                maxZ = math.max(maxZ, pos.Z)
                            end
                        end

                        -- 取得包圍盒的8個角座標
                        local corners3D = {
                            Vector3.new(minX, minY, minZ),
                            Vector3.new(maxX, minY, minZ),
                            Vector3.new(minX, maxY, minZ),
                            Vector3.new(maxX, maxY, minZ),
                            Vector3.new(minX, minY, maxZ),
                            Vector3.new(maxX, minY, maxZ),
                            Vector3.new(minX, maxY, maxZ),
                            Vector3.new(maxX, maxY, maxZ),
                        }

                        -- 轉換成螢幕座標
                        local screenPoints = {}
                        local onScreen = true
                        for _, corner in pairs(corners3D) do
                            local sp, ons = Camera:WorldToScreenPoint(corner)
                            if not ons then
                                onScreen = false
                                break
                            end
                            table.insert(screenPoints, Vector2.new(sp.X, sp.Y))
                        end

                        if onScreen and #screenPoints == 8 then
                            local minX2 = math.huge
                            local minY2 = math.huge
                            local maxX2 = -math.huge
                            local maxY2 = -math.huge
                            for _, p in pairs(screenPoints) do
                                minX2 = math.min(minX2, p.X)
                                minY2 = math.min(minY2, p.Y)
                                maxX2 = math.max(maxX2, p.X)
                                maxY2 = math.max(maxY2, p.Y)
                            end

                            -- 設定矩形框位置大小
                            box.Size = Vector2.new(maxX2 - minX2, maxY2 - minY2)
                            box.Position = Vector2.new(minX2, minY2)
                            box.Visible = true
                        else
                            box.Visible = false
                        end
                    else
                        -- 若模型沒有Parts（可能是空模型），則隱藏框
                        if box then box.Visible = false end
                    end
                else
                    if espBoxes[v] then espBoxes[v].Visible = false end
                end
            end
        end
    end
end)
