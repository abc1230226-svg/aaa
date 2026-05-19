-- 全局變數：模擬 UI 狀態
local UI = {
    myColor = "White",
    aiEnabled = true,
    autoReplyEnabled = true,
    hintEnabled = false,
    aiDepth = 3,
    statusText = "初始化",
}

-- 棋盤數據
local board = {}
local function initBoard()
    board = {}
    for r=1,8 do
        board[r] = {}
        for c=1,8 do
            board[r][c] = "."
        end
    end
    -- 初始放幾個子（示例）
    -- 白兵
    for c=1,8 do
        board[2][c] = "P"
    end
    -- 黑兵
    for c=1,8 do
        board[7][c] = "p"
    end
    -- 其他子自行加入
end

-- 顯示棋盤（Console 模擬）
local function printBoard()
    print("  a b c d e f g h")
    for r=1,8 do
        local line = tostring(9 - r) .. " "
        for c=1,8 do
            line = line .. board[r][c] .. " "
        end
        print(line)
    end
end

local function setStatus(text)
    UI.statusText = "狀態："..tostring(text)
    print(UI.statusText)
end

-- 角色轉換
local function getSideChar()
    return UI.myColor == "White" and "w" or "b"
end
local function getEnemyChar()
    return UI.myColor == "White" and "b" or "w"
end

-- 複製棋盤
local function copyBoard(b)
    local newb = {}
    for r=1,8 do
        newb[r] = {}
        for c=1,8 do
            newb[r][c] = b[r][c]
        end
    end
    return newb
end

-- 生成合法走法（簡版，不完整）
local function generateMoves(b, side)
    local moves = {}
    for r=1,8 do
        for c=1,8 do
            local p = b[r][c]
            if p ~= "." then
                local lower = string.lower(p)
                if (side == "w" and string.match(p, "[P]")) or (side == "b" and string.match(p, "[p]")) then
                    -- 只做簡單：兵可往前走一格
                    local dr = (side=="w") and 1 or -1
                    local nr = r + dr
                    if nr >=1 and nr <=8 and b[nr][c] == "." then
                        table.insert(moves, {fr=r, fc=c, tr=nr, tc=c})
                    end
                end
            end
        end
    end
    return moves
end

-- 評估（簡單）
local pieceVal = {p=100,n=320,b=330,r=500,q=900,k=20000}
local function evaluate(b)
    local score = 0
    for r=1,8 do
        for c=1,8 do
            local p = b[r][c]
            if p ~= "." then
                local val = pieceVal[string.lower(p)] or 0
                if string.match(p, "[A-Z]") then
                    score = score + val
                else
                    score = score - val
                end
            end
        end
    end
    return score
end

-- Minimax
local function minimax(b, depth, alpha, beta, side)
    if depth == 0 then
        return evaluate(b)
    end
    local moves = generateMoves(b, side)
    if #moves == 0 then
        return evaluate(b)
    end
    if side == "w" then
        local maxEval = -math.huge
        for _, m in ipairs(moves) do
            local newb = copyBoard(b)
            newb[m.tr][m.tc] = newb[m.fr][m.fc]
            newb[m.fr][m.fc] = "."
            local eval = minimax(newb, depth-1, alpha, beta, "b")
            if eval > maxEval then maxEval = eval end
            if maxEval > alpha then alpha = maxEval end
            if beta <= alpha then break end
        end
        return maxEval
    else
        local minEval = math.huge
        for _, m in ipairs(moves) do
            local newb = copyBoard(b)
            newb[m.tr][m.tc] = newb[m.fr][m.fc]
            newb[m.fr][m.fc] = "."
            local eval = minimax(newb, depth-1, alpha, beta, "w")
            if eval < minEval then minEval = eval end
            if minEval < beta then beta = minEval end
            if beta <= alpha then break end
        end
        return minEval
    end
end

-- 找最佳步
local function findBestMove()
    local side = getSideChar()
    local moves = generateMoves(board, side)
    local bestScore = (side == "w") and -math.huge or math.huge
    local bestMove = nil
    for _, m in ipairs(moves) do
        local newb = copyBoard(board)
        newb[m.tr][m.tc] = newb[m.fr][m.fc]
        newb[m.fr][m.fc] = "."
        local score = minimax(newb, UI.aiDepth, -math.huge, math.huge, otherSide(side))
        if (side == "w" and score > bestScore) or (side=="b" and score < bestScore) then
            bestScore = score
            bestMove = m
        end
    end
    return bestMove
end

local function otherSide(side)
    return side == "w" and "b" or "w"
end

-- 顯示箭頭（模擬：輸出提示）
local function showArrow(fromR, fromC, toR, toC)
    local fromFile = string.char(96 + fromC)
    local toFile = string.char(96 + toC)
    local fromRank = 9 - fromR
    local toRank = 9 - toR
    print("箭頭：從 "..fromFile..fromRank.." 到 "..toFile..toRank)
end

-- 顯示最佳移動（箭頭 + 提示）
local function showBestMove()
    local move = findBestMove()
    if move then
        showArrow(move.fr, move.fc, move.tr, move.tc)
        local fromStr = string.char(96 + move.fc) .. (9 - move.fr)
        local toStr = string.char(96 + move.tc) .. (9 - move.tr)
        setStatus("最佳步："..fromStr.." 到 "..toStr)
    else
        setStatus("找不到合法步")
    end
end

-- 執行AI走步並顯示箭頭
local function doAIMove()
    local move = findBestMove()
    if move then
        -- 移動棋盤資料
        local p = board[move.fr][move.fc]
        board[move.tr][move.tc] = p
        board[move.fr][move.fc] = "."
        -- 顯示箭頭
        showArrow(move.fr, move.fc, move.tr, move.tc)
        local fromStr = string.char(96 + move.fc) .. (9 - move.fr)
        local toStr = string.char(96 + move.tc) .. (9 - move.tr)
        setStatus("AI 移動："..fromStr.." → "..toStr)
    end
end

-- 玩家輸入走法，示例：e2e4
local function playerMove(moveStr)
    if #moveStr ~= 4 then
        setStatus("輸入格式錯誤")
        return
    end
    local frFile, frRank, toFile, toRank = string.sub(moveStr,1,1), string.sub(moveStr,2,2), string.sub(moveStr,3,3), string.sub(moveStr,4,4)
    local frC = string.byte(frFile) - 96
    local frR = 9 - tonumber(frRank)
    local toC = string.byte(toFile) - 96
    local toR = 9 - tonumber(toRank)
    -- 簡單移動
    if board[frR][frC] ~= "." then
        board[toR][toC] = board[frR][frC]
        board[frR][frC] = "."
        setStatus("玩家走："..moveStr)
        printBoard()
    end
end

-- 自動循環（模擬）
while true do
    wait(1)
    -- 如果AI開啟，則每秒走一步
    if UI.aiEnabled then
        doAIMove()
        printBoard()
    end
    -- 你可以在這裡加入玩家輸入觸發
    -- 例如：用某個條件或外部輸入來呼叫 playerMove("e2e4")
end
