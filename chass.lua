local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

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
            -- 使用Unicode旗子字符
            if r == 2 then
                board[r][c] = "♙" -- 白兵
            elseif r == 7 then
                board[r][c] = "♟" -- 黑兵
            else
                board[r][c] = ""
            end
        end
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
            cell.Button.Text = p ~= "" and p or ""
        end
    end
end

local function setStatus(text)
    statusLabel.Text = "狀態："..tostring(text)
end

local selectedCell = nil

for _, cell in ipairs(cells) do
    cell.Button.MouseButton1Click:Connect(function()
        if not selectedCell then
            selectedCell = {row=cell.row, col=cell.col}
            setStatus("選擇起點：R"..cell.row.." C"..cell.col)
        else
            local fr, fc = selectedCell.row, selectedCell.col
            local tr, tc = cell.row, cell.col
            -- 移動
            if board[fr][fc] ~= "" then
                board[tr][tc] = board[fr][fc]
                board[fr][fc] = ""
                setStatus("移動：R"..fr.." C"..fc.." 到 R"..tr.." C"..tc)
                updateBoardDisplay()
            end
            selectedCell = nil
        end
    end)
end

local arrowParts = {}
local function clearArrows()
    for _, part in ipairs(arrowParts) do
        part:Destroy()
    end
    arrowParts = {}
end

-- 畫箭頭（用長方形旋轉模擬箭頭）
local function drawArrow(fromRow, fromCol, toRow, toCol)
    clearArrows()
    local fromIndex = (fromRow-1)*8 + fromCol
    local toIndex = (toRow-1)*8 + toCol
    local fromCell = cells[fromIndex]
    local toCell = cells[toIndex]
    
    local startPos = fromCell.Button.Position + UDim2.new(0.5,0,0.5,0)
    local endPos = toCell.Button.Position + UDim2.new(0.5,0,0.5,0)
    
    local line = Instance.new("Frame")
    line.Parent = boardFrame
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    
    -- 計算距離和角度
    local deltaX = (endPos.X.Offset - startPos.X.Offset)
    local deltaY = (endPos.Y.Offset - startPos.Y.Offset)
    local length = math.sqrt(deltaX^2 + deltaY^2)
    local angle = math.atan2(deltaY, deltaX)
    
    line.Size = UDim2.new(0, length, 0, 4)
    line.Position = startPos
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = Color3.new(1, 0, 0)
    table.insert(arrowParts, line)
    
    -- 箭頭頭部（小三角形）可以用另一個Frame模擬
    local arrowHead = Instance.new("Frame")
    arrowHead.Size = UDim2.new(0, 10, 0, 10)
    arrowHead.Position = endPos
    arrowHead.AnchorPoint = Vector2.new(0.5, 0.5)
    arrowHead.Rotation = math.deg(angle)
    arrowHead.BackgroundColor3 = Color3.new(1, 0, 0)
    arrowHead.Shape = Enum.PartType.Block
    arrowHead.Parent = boardFrame
    table.insert(arrowParts, arrowHead)
end

-- 獲取推薦步（例如：最前面的白兵向前走）
local function getBestMove()
    for r=1,8 do
        for c=1,8 do
            local p = board[r][c]
            if p ~= "" then
                if p == "♙" and r > 1 and board[r-1][c] == "" then
                    return {from={r=r, c=c}, to={r=r-1, c=c}}
                elseif p == "♟" and r < 8 and board[r+1][c] == "" then
                    return {from={r=r, c=c}, to={r=r+1, c=c}}
                end
            end
        end
    end
    return nil
end

local function showBestMove()
    local move = getBestMove()
    if move then
        drawArrow(move.from.r, move.from.c, move.to.r, move.to.c)
        setStatus("建議步：R"..move.from.r.." C"..move.from.c.." → R"..move.to.r.." C"..move.to.c)
        return move
    else
        setStatus("沒有建議步")
        return nil
    end
end

local suggestBtn = Instance.new("TextButton")
suggestBtn.Size = UDim2.new(0, 200, 0, 50)
suggestBtn.Position = UDim2.new(0.5, -100, 0, 50)
suggestBtn.Text = "顯示建議步"
suggestBtn.Parent = screenGui

suggestBtn.MouseButton1Click:Connect(function()
    showBestMove()
end)

initBoard()
