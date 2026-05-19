-- 這是一個示範腳本，可以貼到 Roblox LocalScript 或命令行中運行
-- 假設你沒管理員權限，只能在玩家端做UI和AI

local function injectChessUI()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local PlayerGui = player:WaitForChild("PlayerGui")
    
    -- 建立 ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ChessGUI"
    screenGui.Parent = PlayerGui
    
    -- 狀態欄
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 50)
    statusLabel.Position = UDim2.new(0, 0, 1, -50)
    statusLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.Text = "初始化"
    statusLabel.TextScaled = true
    statusLabel.Parent = screenGui
    
    -- 棋盤框架
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
    
    -- 棋盤資料
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
    
    -- AI 移動（簡單兵前進）
    local function generateAIMove()
        for r=1,8 do
            for c=1,8 do
                local p = board[r][c]
                if p ~= "." then
                    if p == "p" then
                        if r > 1 and board[r-1][c] == "." then
                            return {fr=r, fc=c, tr=r-1, tc=c}
                        end
                    elseif p == "P" then
                        if r < 8 and board[r+1][c] == "." then
                            return {fr=r, fc=c, tr=r+1, tc=c}
                        end
                    end
                end
            end
        end
        return nil
    end
    
    local function doAIMove()
        local move = generateAIMove()
        if move then
            local p = board[move.fr][move.fc]
            board[move.tr][move.tc] = p
            board[move.fr][move.fc] = "."
            setStatus("AI 移動：R"..move.fr.." C"..move.fc.." → R"..move.tr.." C"..move.tc)
            updateBoardDisplay()
        end
    end
    
    initBoard()
    
    -- 自動每秒走一步
    spawn(function()
        while true do
            wait(1)
            doAIMove()
        end
    end)
end

-- 啟動注入
injectChessUI()
