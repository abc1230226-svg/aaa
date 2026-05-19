local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- 建立UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChessGUI"
screenGui.Parent = PlayerGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 50)
statusLabel.Position = UDim2.new(0, 0, 1, -50)
statusLabel.BackgroundColor3 = Color3.new(0, 0, 0)
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Text = "初始化"
statusLabel.TextScaled = true
statusLabel.Parent = screenGui

local gridSize = 8
local cellSize = UDim2.new(0, 40, 0, 40)
local boardFrame = Instance.new("Frame")
boardFrame.Size = UDim2.new(0, cellSize.X.Offset * gridSize, 0, cellSize.Y.Offset * gridSize)
boardFrame.Position = UDim2.new(0.5, -boardFrame.Size.X.Offset/2, 0.5, -boardFrame.Size.Y.Offset/2)
boardFrame.Parent = screenGui

local cells = {}
for r=1, gridSize do
    for c=1, gridSize do
        local btn = Instance.new("TextButton")
        btn.Size = cellSize
        btn.Position = UDim2.new(0, (c-1)*cellSize.X.Offset, 0, (r-1)*cellSize.Y.Offset)
        btn.BackgroundColor3 = ((r + c) % 2 == 0) and Color3.new(0.8, 0.8, 0.8) or Color3.new(0.2, 0.2, 0.2)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Text = ""
        btn.Parent = boardFrame
        table.insert(cells, {Button=btn, row=r, col=c})
    end
end

local board = {}
local function initBoard()
    board = {}
    for r=1,8 do
        board[r] = {}
        for c=1,8 do
            board[r][c] = "."
        end
    end
    for c=1,8 do
        board[2][c] = "P"
        board[7][c] = "p"
    end
    updateBoardDisplay()
    setStatus("遊戲已初始化")
end

local function updateBoardDisplay()
    for r=1,8 do
        for c=1,8 do
            local index = (r-1)*8 + c
            local cell = cells[index]
            local p = board[r][c]
            cell.Button.Text = p ~= "." and p or ""
        end
    end
end

local function setStatus(text)
    statusLabel.Text = "狀態："..tostring(text)
end

local selectedCell = nil

-- 點擊格子
for _, cell in ipairs(cells) do
    cell.Button.MouseButton1Click:Connect(function()
        if not selectedCell then
            selectedCell = {row=cell.row, col=cell.col}
            setStatus("選擇起點：R"..cell.row.." C"..cell.col)
        else
            local fr, fc = selectedCell.row, selectedCell.col
            local tr, tc = cell.row, cell.col
            -- 簡單移動
            if board[fr][fc] ~= "." then
                board[tr][tc] = board[fr][fc]
                board[fr][fc] = "."
                setStatus("移動：R"..fr.."-C"..fc.." 到 R"..tr.."-C"..tc)
                updateBoardDisplay()
            end
            selectedCell = nil
        end
    end)
end

-- 用於存儲箭頭
local arrowMarkers = {}

-- 畫箭頭（用紅色框框或文字模擬）
local function drawArrow(fromRow, fromCol, toRow, toCol)
    -- 先清除之前的箭頭
    for _, arrow in ipairs(arrowMarkers) do
        arrow:Destroy()
    end
    arrowMarkers = {}
    -- 繪製新箭頭（用 Label 或 Frame 模擬）
    local fromIndex = (fromRow-1)*8 + fromCol
    local toIndex = (toRow-1)*8 + toCol
    local fromCell = cells[fromIndex]
    local toCell = cells[toIndex]
    
    local arrow = Instance.new("Frame")
    arrow.Size = UDim2.new(0, 10, 0, 10)
    arrow.BackgroundColor3 = Color3.new(1, 0, 0)
    arrow.Position = fromCell.Button.Position + UDim2.new(0.5,0,0.5,0) - UDim2.new(0,5,0,5)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Parent = boardFrame
    table.insert(arrowMarkers, arrow)
    
    -- 可以擴展畫直線或箭頭，這裡用簡單的紅點示意
    -- 也可用Line或其他圖形實作
end

-- AI分析最佳步（簡單策略：移動最前的兵）
local function getBestMove()
    for r=1,8 do
        for c=1,8 do
            local p = board[r][c]
            if p ~= "." then
                if p == "p" then
                    if r > 1 and board[r-1][c] == "." then
                        return {from={r=r, c=c}, to={r=r-1, c=c}}
                    end
                elseif p == "P" then
                    if r < 8 and board[r+1][c] == "." then
                        return {from={r=r, c=c}, to={r=r+1, c=c}}
                    end
                end
            end
        end
    end
    return nil
end

local function showBestMove()
    local move = getBestMove()
    if move then
        -- 標記箭頭
        drawArrow(move.from.r, move.from.c, move.to.r, move.to.c)
        setStatus("建議步：R"..move.from.r.." C"..move.from.c.." 到 R"..move.to.r.." C"..move.to.c)
        return move
    else
        setStatus("沒有建議步")
        return nil
    end
end

-- 讓玩家點擊“建議步”按鈕來標記
local suggestButton = Instance.new("TextButton")
suggestButton.Size = UDim2.new(0, 200, 0, 50)
suggestButton.Position = UDim2.new(0.5, -100, 0, 50)
suggestButton.Text = "顯示建議步"
suggestButton.Parent = screenGui

suggestButton.MouseButton1Click:Connect(function()
    local move = showBestMove()
    -- 你可以在這裡加入自動移動或其他功能
end)

-- 初始化遊戲
initBoard()

-- 你也可以加入自動AI走步等功能
