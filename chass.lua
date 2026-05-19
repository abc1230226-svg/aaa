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
local cellSize = UDim2.new(0, 50, 0, 50)
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
    board = {
        -- 白方（第1、2行）
        { "♖", "♘", "♗", "♕", "♔", "♗", "♘", "♖" },
        { "♙", "♙", "♙", "♙", "♙", "♙", "♙", "♙" },
        -- 空格
        { "", "", "", "", "", "", "", "" },
        { "", "", "", "", "", "", "", "" },
        { "", "", "", "", "", "", "", "" },
        { "", "", "", "", "", "", "", "" },
        -- 黑方（第7、8行）
        { "♟", "♟", "♟", "♟", "♟", "♟", "♟", "♟" },
        { "♜", "♞", "♝", "♛", "♚", "♝", "♞", "♜" },
    }
    updateBoardDisplay()
    setStatus("遊戲已初始化")
end

local function updateBoardDisplay()
    for r=1,8 do
        for c=1,8 do
            local index = (r-1)*8 + c
            local cell = cells[index]
            local piece = board[r][c]
            cell.Button.Text = piece ~= "" and piece or ""
        end
    end
end

local function setStatus(text)
    statusLabel.Text = "狀態："..tostring(text)
end

local selectedCell = nil

local function isValidMove(fromR, fromC, toR, toC)
    local p = board[fromR][fromC]
    local target = board[toR][toC]
    -- 簡單規則：只能移動自己顏色的棋子，且走法符合規則
    if p == "" then return false end
    if p == "♙" then
        -- 白兵
        if fromC == toC then
            if toR == fromR + 1 and target == "" then
                return true
            end
            -- 初次可走兩格
            if fromR == 2 and toR == fromR + 2 and target == "" and board[fromR+1][fromC] == "" then
                return true
            end
        elseif math.abs(toC - fromC) == 1 and toR == fromR + 1 and target ~= "" then
            -- 吃子
            return true
        end
    elseif p == "♟" then
        -- 黑兵
        if fromC == toC then
            if toR == fromR - 1 and target == "" then
                return true
            end
            if fromR == 7 and toR == fromR - 2 and target == "" and board[fromR-1][fromC] == "" then
                return true
            end
        elseif math.abs(toC - fromC) == 1 and toR == fromR - 1 and target ~= "" then
            return true
        end
    elseif p == "♖" then
        -- 車：直線
        if fromR == toR then
            local step = (toC > fromC) and 1 or -1
            for c=fromC+step, toC-step, step do
                if board[fromR][c] ~= "" then return false end
            end
            return true
        elseif fromC == toC then
            local step = (toR > fromR) and 1 or -1
            for r=fromR+step, toR-1, step do
                if board[r][fromC] ~= "" then return false end
            end
            return true
        end
    elseif p == "♘" then
        -- 馬
        local dr = math.abs(toR - fromR)
        local dc = math.abs(toC - fromC)
        if (dr==2 and dc==1) or (dr==1 and dc==2) then
            return true
        end
    elseif p == "♝" then
        -- 象：對角線
        if math.abs(toR - fromR) == math.abs(toC - fromC) then
            local rStep = (toR > fromR) and 1 or -1
            local cStep = (toC > fromC) and 1 or -1
            local r,c = fromR + rStep, fromC + cStep
            while r ~= toR and c ~= toC do
                if board[r][c] ~= "" then return false end
                r = r + rStep
                c = c + cStep
            end
            return true
        end
    elseif p == "♛" then
        -- 后：直線或對角線
        if fromR == toR then
            local step = (toC > fromC) and 1 or -1
            for c=fromC+step, toC-step, step do
                if board[fromR][c] ~= "" then return false end
            end
            return true
        elseif fromC == toC then
            local step = (toR > fromR) and 1 or -1
            for r=fromR+step, toR-1, step do
                if board[r][fromC] ~= "" then return false end
            end
            return true
        elseif math.abs(toR - fromR) == math.abs(toC - fromC) then
            local rStep = (toR > fromR) and 1 or -1
            local cStep = (toC > fromC) and 1 or -1
            local r,c = fromR + rStep, fromC + cStep
            while r ~= toR and c ~= toC do
                if board[r][c] ~= "" then return false end
                r = r + rStep
                c = c + cStep
            end
            return true
        end
    elseif p == "♚" then
        -- 王
        if math.abs(toR - fromR) <= 1 and math.abs(toC - fromC) <=1 then
            return true
        end
    end
    return false
end

for _, cell in ipairs(cells) do
    cell.Button.MouseButton1Click:Connect(function()
        if not selectedCell then
            -- 選擇起點
            local r, c = cell.row, cell.col
            if board[r][c] ~= "" then
                selectedCell = {row=r, col=c}
                setStatus("選擇移動的棋子：R"..r.." C"..c)
            end
        else
            -- 選擇終點
            local fr, fc = selectedCell.row, selectedCell.col
            local tr, tc = cell.row, cell.col
            if isValidMove(fr, fc, tr, tc) then
                -- 移動
                board[tr][tc] = board[fr][fc]
                board[fr][fc] = ""
                updateBoardDisplay()
                setStatus("已移動")
            else
                setStatus("非法移動")
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

    local deltaX = (endPos.X.Offset - startPos.X.Offset)
    local deltaY = (endPos.Y.Offset - startPos.Y.Offset)
    local length = math.sqrt(deltaX^2 + deltaY^2)
    local angle = math.atan2(deltaY, deltaX)

    line.Size = UDim2.new(0, length, 0, 4)
    line.Position = startPos
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = Color3.new(1, 0, 0)
    table.insert(arrowParts, line)

    local arrowHead = Instance.new("Frame")
    arrowHead.Size = UDim2.new(0, 12, 0, 12)
    arrowHead.Position = endPos
    arrowHead.AnchorPoint = Vector2.new(0.5, 0.5)
    arrowHead.Rotation = math.deg(angle)
    arrowHead.BackgroundColor3 = Color3.new(1, 0, 0)
    arrowHead.Shape = Enum.PartType.Block
    arrowHead.Parent = boardFrame
    table.insert(arrowParts, arrowHead)
end

-- AI：簡單策略，找出所有白兵並建議前方走一步
local function getBestMove()
    for r=1,8 do
        for c=1,8 do
            local p = board[r][c]
            if p == "♙" then
                if r<8 and board[r+1][c] == "" then
                    return {from={r=r, c=c}, to={r=r+1, c=c}}
                end
            elseif p == "♟" then
                if r>1 and board[r-1][c] == "" then
                    return {from={r=r, c=c}, to={r=r-1, c=c}}
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
    else
        setStatus("沒有建議步")
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

-- 初始化
initBoard()
