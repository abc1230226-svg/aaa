--// ChessGUI_FullRules_RecommendMove.lua
--// 放在 StarterPlayer > StarterPlayerScripts > LocalScript
--// 功能：完整棋盤 UI、推薦步箭頭、玩家移動後箭頭消失
--// 新增：王車易位、吃過路兵、將軍保護、基本將死/和棋判斷、升變皇后

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- 很重要：這份一定要放在 LocalScript。
-- 如果放在 Script，Players.LocalPlayer 會是 nil，UI 就跑不出來。
if not player then
    warn("ChessGUI 沒有啟動：請把這份程式放在 StarterPlayer > StarterPlayerScripts > LocalScript")
    return
end

local PlayerGui = player:WaitForChild("PlayerGui")

-- 避免重複執行時舊 UI 卡住
local oldGui = PlayerGui:FindFirstChild("ChessGUI")
if oldGui then
    oldGui:Destroy()
end

--====================================================
-- GUI：照你原本那種寫法，但用 PlayerGui 才能在 Roblox Studio 正常顯示
--====================================================

--====================================================
-- GUI：照你原本那種寫法，但整個棋盤選單可以拖曳移動
--====================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChessGUI"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true

-- 把棋盤、按鈕、狀態文字全部包在這個 menuFrame 裡
-- 之後只要拖曳上方標題列，就能整個一起移動
local menuFrame = Instance.new("Frame", screenGui)
menuFrame.Name = "Chess_Menu_Frame"
menuFrame.Size = UDim2.new(0, 640, 0, 500)
menuFrame.Position = UDim2.new(0, 60, 0, 60)
menuFrame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
menuFrame.BorderSizePixel = 2
menuFrame.Active = true
menuFrame.Visible = true
menuFrame.ZIndex = 1

local gridSize = 8
local cellPixel = 48
local board = {}
local cells = {}
local selectedCell = nil
local currentBestMove = nil
local sideToMove = "w" -- w = 白棋，b = 黑棋
local searchDepth = 2

local gameState = {
    castlingRights = {
        wK = true,
        wQ = true,
        bK = true,
        bQ = true,
    },
    enPassantTarget = nil, -- {r = row, c = col}
}

local whiteSquareColor = Color3.new(0.8, 0.8, 0.8)
local blackSquareColor = Color3.new(0.25, 0.25, 0.25)
local selectedColor = Color3.new(0.2, 0.55, 1)
local recommendFromColor = Color3.new(0.1, 0.7, 0.1)
local recommendToColor = Color3.new(1, 0.7, 0.1)
local checkColor = Color3.new(1, 0.15, 0.15)

local pieceValue = {
    ["♙"] = 100,
    ["♟"] = 100,
    ["♘"] = 320,
    ["♞"] = 320,
    ["♗"] = 330,
    ["♝"] = 330,
    ["♖"] = 500,
    ["♜"] = 500,
    ["♕"] = 900,
    ["♛"] = 900,
    ["♔"] = 20000,
    ["♚"] = 20000,
}

local whitePieces = {
    ["♙"] = true,
    ["♘"] = true,
    ["♗"] = true,
    ["♖"] = true,
    ["♕"] = true,
    ["♔"] = true,
}

local blackPieces = {
    ["♟"] = true,
    ["♞"] = true,
    ["♝"] = true,
    ["♜"] = true,
    ["♛"] = true,
    ["♚"] = true,
}

local function createButton(text, posY)
    local btn = Instance.new("TextButton", menuFrame)
    btn.Size = UDim2.new(0, 210, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    btn.BorderSizePixel = 1
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Visible = true
    btn.Active = true
    btn.ZIndex = 20
    return btn
end

local statusLabel = Instance.new("TextLabel", menuFrame)
statusLabel.Size = UDim2.new(0, 610, 0, 44)
statusLabel.Position = UDim2.new(0, 15, 0, 445)
statusLabel.BackgroundColor3 = Color3.new(0, 0, 0)
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Text = "初始化"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.GothamBold
statusLabel.ZIndex = 20

local titleLabel = Instance.new("TextLabel", menuFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 38)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Text = "Chess Recommend Move - Full Rules    ｜拖曳這裡移動"
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Active = true
titleLabel.ZIndex = 30

-- 拖曳 menu：按住 titleLabel 移動整個棋盤選單
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    menuFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = menuFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

local boardFrame = Instance.new("Frame", menuFrame)
boardFrame.Size = UDim2.new(0, cellPixel * gridSize, 0, cellPixel * gridSize)
boardFrame.Position = UDim2.new(0, 240, 0, 50)
boardFrame.BackgroundColor3 = Color3.new(0, 0, 0)
boardFrame.BorderSizePixel = 2
boardFrame.ZIndex = 5

local suggestBtn = createButton("顯示白棋推薦步", 55)
local resetBtn = createButton("重置棋盤", 98)

local function setStatus(text)
    statusLabel.Text = "狀態：" .. tostring(text)
end

local function getCellIndex(r, c)
    return (r - 1) * 8 + c
end

local function isInside(r, c)
    return r >= 1 and r <= 8 and c >= 1 and c <= 8
end

local function otherSide(side)
    return side == "w" and "b" or "w"
end

local function sideName(side)
    return side == "w" and "白棋" or "黑棋"
end

local function getPieceSide(piece)
    if whitePieces[piece] then
        return "w"
    elseif blackPieces[piece] then
        return "b"
    end
    return nil
end

local function isEnemy(piece, side)
    local pieceSide = getPieceSide(piece)
    return pieceSide ~= nil and pieceSide ~= side
end

local function isSameSide(piece, side)
    return getPieceSide(piece) == side
end

local function copyBoard(b)
    local newBoard = {}
    for r = 1, 8 do
        newBoard[r] = {}
        for c = 1, 8 do
            newBoard[r][c] = b[r][c]
        end
    end
    return newBoard
end

local function copyState(state)
    return {
        castlingRights = {
            wK = state.castlingRights.wK,
            wQ = state.castlingRights.wQ,
            bK = state.castlingRights.bK,
            bQ = state.castlingRights.bQ,
        },
        enPassantTarget = state.enPassantTarget and {
            r = state.enPassantTarget.r,
            c = state.enPassantTarget.c,
        } or nil,
    }
end

local function rcToAlg(r, c)
    local file = string.char(string.byte("a") + c - 1)
    local rank = tostring(9 - r)
    return file .. rank
end

local function moveToText(move)
    local text = rcToAlg(move.fr, move.fc) .. " → " .. rcToAlg(move.tr, move.tc)

    if move.castle == "K" then
        text ..= "（王車易位：短易位）"
    elseif move.castle == "Q" then
        text ..= "（王車易位：長易位）"
    elseif move.enPassant then
        text ..= "（吃過路兵）"
    elseif move.promotion then
        text ..= "（升變皇后）"
    end

    return text
end

local function sameMove(a, b)
    if not a or not b then
        return false
    end
    return a.fr == b.fr and a.fc == b.fc and a.tr == b.tr and a.tc == b.tc
end

local function getSquareColor(r, c)
    return ((r + c) % 2 == 0) and whiteSquareColor or blackSquareColor
end

local function resetSquareColors()
    for _, cell in ipairs(cells) do
        cell.Button.BackgroundColor3 = getSquareColor(cell.row, cell.col)
    end
end

local function updateBoardDisplay()
    for r = 1, 8 do
        for c = 1, 8 do
            local index = getCellIndex(r, c)
            local cell = cells[index]
            local p = board[r][c]
            cell.Button.Text = p ~= "" and p or ""
            cell.Button.TextScaled = true
            cell.Button.Font = Enum.Font.SourceSansBold
        end
    end
end

local arrowParts = {}

local function clearArrows()
    for _, part in ipairs(arrowParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    arrowParts = {}
    currentBestMove = nil
    resetSquareColors()
end

local function drawArrow(fromRow, fromCol, toRow, toCol)
    clearArrows()

    local startX = (fromCol - 0.5) * cellPixel
    local startY = (fromRow - 0.5) * cellPixel
    local endX = (toCol - 0.5) * cellPixel
    local endY = (toRow - 0.5) * cellPixel

    local deltaX = endX - startX
    local deltaY = endY - startY
    local length = math.sqrt(deltaX ^ 2 + deltaY ^ 2)
    local angle
if math.atan2 then
    angle = math.atan2(deltaY, deltaX)
else
    angle = math.atan(deltaY, deltaX)
end

    local line = Instance.new("Frame", boardFrame)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Size = UDim2.new(0, length, 0, 6)
    line.Position = UDim2.new(0, (startX + endX) / 2, 0, (startY + endY) / 2)
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = Color3.new(1, 0, 0)
    line.BorderSizePixel = 0
    line.ZIndex = 10
    table.insert(arrowParts, line)

    local arrowHead = Instance.new("Frame", boardFrame)
    arrowHead.AnchorPoint = Vector2.new(0.5, 0.5)
    arrowHead.Size = UDim2.new(0, 16, 0, 16)
    arrowHead.Position = UDim2.new(0, endX, 0, endY)
    arrowHead.Rotation = math.deg(angle) + 45
    arrowHead.BackgroundColor3 = Color3.new(1, 0, 0)
    arrowHead.BorderSizePixel = 0
    arrowHead.ZIndex = 11
    table.insert(arrowParts, arrowHead)

    local fromCell = cells[getCellIndex(fromRow, fromCol)]
    local toCell = cells[getCellIndex(toRow, toCol)]
    fromCell.Button.BackgroundColor3 = recommendFromColor
    toCell.Button.BackgroundColor3 = recommendToColor
end

local function findKing(b, side)
    local king = side == "w" and "♔" or "♚"
    for r = 1, 8 do
        for c = 1, 8 do
            if b[r][c] == king then
                return r, c
            end
        end
    end
    return nil, nil
end

local function isSquareAttacked(b, targetR, targetC, bySide)
    -- 兵攻擊
    if bySide == "w" then
        for _, dc in ipairs({-1, 1}) do
            local r = targetR + 1
            local c = targetC + dc
            if isInside(r, c) and b[r][c] == "♙" then
                return true
            end
        end
    else
        for _, dc in ipairs({-1, 1}) do
            local r = targetR - 1
            local c = targetC + dc
            if isInside(r, c) and b[r][c] == "♟" then
                return true
            end
        end
    end

    -- 馬攻擊
    local knight = bySide == "w" and "♘" or "♞"
    local knightOffsets = {
        {-2, -1}, {-2, 1},
        {-1, -2}, {-1, 2},
        {1, -2}, {1, 2},
        {2, -1}, {2, 1},
    }

    for _, o in ipairs(knightOffsets) do
        local r = targetR + o[1]
        local c = targetC + o[2]
        if isInside(r, c) and b[r][c] == knight then
            return true
        end
    end

    -- 斜線：象 / 后
    local bishop = bySide == "w" and "♗" or "♝"
    local rook = bySide == "w" and "♖" or "♜"
    local queen = bySide == "w" and "♕" or "♛"

    for _, d in ipairs({{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}) do
        local r = targetR + d[1]
        local c = targetC + d[2]
        while isInside(r, c) do
            local p = b[r][c]
            if p ~= "" then
                if p == bishop or p == queen then
                    return true
                end
                break
            end
            r += d[1]
            c += d[2]
        end
    end

    -- 直線：車 / 后
    for _, d in ipairs({{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) do
        local r = targetR + d[1]
        local c = targetC + d[2]
        while isInside(r, c) do
            local p = b[r][c]
            if p ~= "" then
                if p == rook or p == queen then
                    return true
                end
                break
            end
            r += d[1]
            c += d[2]
        end
    end

    -- 王攻擊
    local king = bySide == "w" and "♔" or "♚"
    for dr = -1, 1 do
        for dc = -1, 1 do
            if not (dr == 0 and dc == 0) then
                local r = targetR + dr
                local c = targetC + dc
                if isInside(r, c) and b[r][c] == king then
                    return true
                end
            end
        end
    end

    return false
end

local function inCheck(b, side)
    local kr, kc = findKing(b, side)
    if not kr then
        return true
    end
    return isSquareAttacked(b, kr, kc, otherSide(side))
end

local function addMove(moves, b, fr, fc, tr, tc, side, extra)
    if not isInside(tr, tc) then
        return
    end

    local target = b[tr][tc]
    if target == "" or isEnemy(target, side) then
        local move = {
            fr = fr,
            fc = fc,
            tr = tr,
            tc = tc,
            capture = target,
        }

        if extra then
            for k, v in pairs(extra) do
                move[k] = v
            end
        end

        table.insert(moves, move)
    end
end

local function addSlideMoves(moves, b, fr, fc, side, dirs)
    for _, d in ipairs(dirs) do
        local nr = fr + d[1]
        local nc = fc + d[2]

        while isInside(nr, nc) do
            local target = b[nr][nc]
            if target == "" then
                addMove(moves, b, fr, fc, nr, nc, side)
            else
                if isEnemy(target, side) then
                    addMove(moves, b, fr, fc, nr, nc, side)
                end
                break
            end
            nr += d[1]
            nc += d[2]
        end
    end
end

local function canCastle(b, state, side, castleSide)
    local row = side == "w" and 8 or 1
    local king = side == "w" and "♔" or "♚"
    local rook = side == "w" and "♖" or "♜"
    local enemySide = otherSide(side)

    if b[row][5] ~= king then
        return false
    end

    if inCheck(b, side) then
        return false
    end

    if side == "w" and castleSide == "K" and not state.castlingRights.wK then return false end
    if side == "w" and castleSide == "Q" and not state.castlingRights.wQ then return false end
    if side == "b" and castleSide == "K" and not state.castlingRights.bK then return false end
    if side == "b" and castleSide == "Q" and not state.castlingRights.bQ then return false end

    if castleSide == "K" then
        if b[row][8] ~= rook then return false end
        if b[row][6] ~= "" or b[row][7] ~= "" then return false end
        if isSquareAttacked(b, row, 6, enemySide) then return false end
        if isSquareAttacked(b, row, 7, enemySide) then return false end
        return true
    else
        if b[row][1] ~= rook then return false end
        if b[row][2] ~= "" or b[row][3] ~= "" or b[row][4] ~= "" then return false end
        if isSquareAttacked(b, row, 4, enemySide) then return false end
        if isSquareAttacked(b, row, 3, enemySide) then return false end
        return true
    end
end

local function generatePseudoMoves(b, side, state)
    local moves = {}

    for r = 1, 8 do
        for c = 1, 8 do
            local piece = b[r][c]

            if piece ~= "" and isSameSide(piece, side) then
                if piece == "♙" or piece == "♟" then
                    local dir = side == "w" and -1 or 1
                    local startRow = side == "w" and 7 or 2
                    local promotionRow = side == "w" and 1 or 8
                    local promotionPiece = side == "w" and "♕" or "♛"

                    -- 前進一步
                    if isInside(r + dir, c) and b[r + dir][c] == "" then
                        local extra = nil
                        if r + dir == promotionRow then
                            extra = {promotion = promotionPiece}
                        end
                        addMove(moves, b, r, c, r + dir, c, side, extra)

                        -- 起始雙步
                        if r == startRow and isInside(r + dir * 2, c) and b[r + dir * 2][c] == "" then
                            addMove(moves, b, r, c, r + dir * 2, c, side, {doublePawn = true})
                        end
                    end

                    -- 斜吃 + 升變
                    for _, dc in ipairs({-1, 1}) do
                        local nr = r + dir
                        local nc = c + dc
                        if isInside(nr, nc) and isEnemy(b[nr][nc], side) then
                            local extra = nil
                            if nr == promotionRow then
                                extra = {promotion = promotionPiece}
                            end
                            addMove(moves, b, r, c, nr, nc, side, extra)
                        end
                    end

                    -- 吃過路兵
                    if state.enPassantTarget then
                        local ep = state.enPassantTarget
                        if ep.r == r + dir and math.abs(ep.c - c) == 1 then
                            local capturedPawn = side == "w" and "♟" or "♙"
                            if b[r][ep.c] == capturedPawn then
                                addMove(moves, b, r, c, ep.r, ep.c, side, {
                                    enPassant = true,
                                    epCaptureR = r,
                                    epCaptureC = ep.c,
                                    capture = capturedPawn,
                                })
                            end
                        end
                    end

                elseif piece == "♘" or piece == "♞" then
                    local offsets = {
                        {-2, -1}, {-2, 1},
                        {-1, -2}, {-1, 2},
                        {1, -2}, {1, 2},
                        {2, -1}, {2, 1},
                    }
                    for _, o in ipairs(offsets) do
                        addMove(moves, b, r, c, r + o[1], c + o[2], side)
                    end

                elseif piece == "♗" or piece == "♝" then
                    addSlideMoves(moves, b, r, c, side, {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}})

                elseif piece == "♖" or piece == "♜" then
                    addSlideMoves(moves, b, r, c, side, {{-1, 0}, {1, 0}, {0, -1}, {0, 1}})

                elseif piece == "♕" or piece == "♛" then
                    addSlideMoves(moves, b, r, c, side, {
                        {-1, -1}, {-1, 1}, {1, -1}, {1, 1},
                        {-1, 0}, {1, 0}, {0, -1}, {0, 1},
                    })

                elseif piece == "♔" or piece == "♚" then
                    for dr = -1, 1 do
                        for dc = -1, 1 do
                            if not (dr == 0 and dc == 0) then
                                addMove(moves, b, r, c, r + dr, c + dc, side)
                            end
                        end
                    end

                    -- 王車易位
                    if canCastle(b, state, side, "K") then
                        addMove(moves, b, r, c, r, 7, side, {castle = "K"})
                    end
                    if canCastle(b, state, side, "Q") then
                        addMove(moves, b, r, c, r, 3, side, {castle = "Q"})
                    end
                end
            end
        end
    end

    return moves
end

local function updateCastlingRightsForMove(state, piece, move, capturedPiece, capturedR, capturedC)
    -- 王移動後，兩邊易位權都消失
    if piece == "♔" then
        state.castlingRights.wK = false
        state.castlingRights.wQ = false
    elseif piece == "♚" then
        state.castlingRights.bK = false
        state.castlingRights.bQ = false
    end

    -- 車從原位移動，對應易位權消失
    if piece == "♖" then
        if move.fr == 8 and move.fc == 1 then state.castlingRights.wQ = false end
        if move.fr == 8 and move.fc == 8 then state.castlingRights.wK = false end
    elseif piece == "♜" then
        if move.fr == 1 and move.fc == 1 then state.castlingRights.bQ = false end
        if move.fr == 1 and move.fc == 8 then state.castlingRights.bK = false end
    end

    -- 原位的車被吃掉，也要移除易位權
    if capturedPiece == "♖" then
        if capturedR == 8 and capturedC == 1 then state.castlingRights.wQ = false end
        if capturedR == 8 and capturedC == 8 then state.castlingRights.wK = false end
    elseif capturedPiece == "♜" then
        if capturedR == 1 and capturedC == 1 then state.castlingRights.bQ = false end
        if capturedR == 1 and capturedC == 8 then state.castlingRights.bK = false end
    end
end

local function applyMove(b, state, move)
    local newBoard = copyBoard(b)
    local newState = copyState(state)

    local piece = newBoard[move.fr][move.fc]
    local capturedPiece = ""
    local capturedR = move.tr
    local capturedC = move.tc

    if move.enPassant then
        capturedR = move.epCaptureR
        capturedC = move.epCaptureC
        capturedPiece = newBoard[capturedR][capturedC]
        newBoard[capturedR][capturedC] = ""
    else
        capturedPiece = newBoard[move.tr][move.tc]
    end

    newBoard[move.fr][move.fc] = ""

    if move.castle == "K" then
        -- 王：e 到 g，車：h 到 f
        newBoard[move.tr][move.tc] = piece
        newBoard[move.tr][6] = newBoard[move.tr][8]
        newBoard[move.tr][8] = ""
    elseif move.castle == "Q" then
        -- 王：e 到 c，車：a 到 d
        newBoard[move.tr][move.tc] = piece
        newBoard[move.tr][4] = newBoard[move.tr][1]
        newBoard[move.tr][1] = ""
    else
        newBoard[move.tr][move.tc] = move.promotion or piece
    end

    updateCastlingRightsForMove(newState, piece, move, capturedPiece, capturedR, capturedC)

    -- 每走一步後，先清掉吃過路兵目標
    newState.enPassantTarget = nil

    -- 如果兵走兩格，設定下一手可以吃過路兵的目標格
    if move.doublePawn then
        newState.enPassantTarget = {
            r = (move.fr + move.tr) / 2,
            c = move.fc,
        }
    end

    return newBoard, newState
end

local function generateLegalMoves(b, side, state)
    local pseudo = generatePseudoMoves(b, side, state)
    local legal = {}

    for _, move in ipairs(pseudo) do
        local newBoard, _ = applyMove(b, state, move)
        if not inCheck(newBoard, side) then
            table.insert(legal, move)
        end
    end

    return legal
end

local function evaluateBoard(b)
    local score = 0

    for r = 1, 8 do
        for c = 1, 8 do
            local piece = b[r][c]
            local value = pieceValue[piece] or 0
            if whitePieces[piece] then
                score += value
            elseif blackPieces[piece] then
                score -= value
            end
        end
    end

    return score
end

local function minimax(b, state, depth, alpha, beta, side)
    local moves = generateLegalMoves(b, side, state)

    if depth <= 0 then
        return evaluateBoard(b)
    end

    if #moves == 0 then
        if inCheck(b, side) then
            return side == "w" and (-999999 - depth) or (999999 + depth)
        end
        return 0
    end

    if side == "w" then
        local best = -math.huge
        for _, move in ipairs(moves) do
            local newBoard, newState = applyMove(b, state, move)
            local score = minimax(newBoard, newState, depth - 1, alpha, beta, "b")
            best = math.max(best, score)
            alpha = math.max(alpha, best)
            if beta <= alpha then
                break
            end
        end
        return best
    else
        local best = math.huge
        for _, move in ipairs(moves) do
            local newBoard, newState = applyMove(b, state, move)
            local score = minimax(newBoard, newState, depth - 1, alpha, beta, "w")
            best = math.min(best, score)
            beta = math.min(beta, best)
            if beta <= alpha then
                break
            end
        end
        return best
    end
end

local function getBestMove()
    local moves = generateLegalMoves(board, sideToMove, gameState)
    if #moves == 0 then
        return nil, nil
    end

    local bestMove = nil
    local bestScore = sideToMove == "w" and -math.huge or math.huge

    for _, move in ipairs(moves) do
        local newBoard, newState = applyMove(board, gameState, move)
        local score = minimax(newBoard, newState, searchDepth - 1, -math.huge, math.huge, otherSide(sideToMove))

        -- 同分時稍微偏好特殊走法，讓推薦比較有感
        if move.castle then
            score += sideToMove == "w" and 25 or -25
        end
        if move.enPassant then
            score += sideToMove == "w" and 20 or -20
        end
        if move.promotion then
            score += sideToMove == "w" and 800 or -800
        end

        if sideToMove == "w" then
            if score > bestScore then
                bestScore = score
                bestMove = move
            end
        else
            if score < bestScore then
                bestScore = score
                bestMove = move
            end
        end
    end

    return bestMove, bestScore
end

local function updateTurnButton()
    suggestBtn.Text = "顯示" .. sideName(sideToMove) .. "推薦步"
end

local function markKingIfInCheck(side)
    local kr, kc = findKing(board, side)
    if kr and inCheck(board, side) then
        local cell = cells[getCellIndex(kr, kc)]
        if cell then
            cell.Button.BackgroundColor3 = checkColor
        end
    end
end

local function showBestMove()
    local move, score = getBestMove()

    if move then
        drawArrow(move.fr, move.fc, move.tr, move.tc)
        currentBestMove = move
        setStatus(sideName(sideToMove) .. "推薦步：" .. moveToText(move) .. "，分數：" .. tostring(score))
        return move
    else
        clearArrows()
        if inCheck(board, sideToMove) then
            setStatus(sideName(sideToMove) .. "已被將死，沒有推薦步")
        else
            setStatus(sideName(sideToMove) .. "沒有合法步，和棋")
        end
        return nil
    end
end

local function afterSuccessfulMove(moveText)
    sideToMove = otherSide(sideToMove)
    updateTurnButton()

    local legalMoves = generateLegalMoves(board, sideToMove, gameState)

    if #legalMoves == 0 then
        if inCheck(board, sideToMove) then
            setStatus(moveText .. "；" .. sideName(sideToMove) .. "被將死")
        else
            setStatus(moveText .. "；和棋，沒有合法步")
        end
    elseif inCheck(board, sideToMove) then
        resetSquareColors()
        markKingIfInCheck(sideToMove)
        setStatus(moveText .. "；將軍！輪到 " .. sideName(sideToMove))
    else
        setStatus(moveText .. "；輪到 " .. sideName(sideToMove))
    end
end

local function doMove(fr, fc, tr, tc)
    if board[fr][fc] == "" then
        setStatus("這格沒有棋子")
        return false
    end

    local movingSide = getPieceSide(board[fr][fc])
    if movingSide ~= sideToMove then
        setStatus("現在輪到 " .. sideName(sideToMove))
        return false
    end

    local legalMoves = generateLegalMoves(board, sideToMove, gameState)
    local chosenMove = nil

    for _, move in ipairs(legalMoves) do
        if move.fr == fr and move.fc == fc and move.tr == tr and move.tc == tc then
            chosenMove = move
            break
        end
    end

    if not chosenMove then
        setStatus("這步不合法，可能會讓自己的王被將軍")
        return false
    end

    local userMoveText = moveToText(chosenMove)
    board, gameState = applyMove(board, gameState, chosenMove)
    updateBoardDisplay()

    local prefix
    if currentBestMove and sameMove(chosenMove, currentBestMove) then
        prefix = "你照推薦步移動了：" .. userMoveText
    else
        prefix = "移動：" .. userMoveText
    end

    clearArrows() -- 你動完之後，推薦箭頭立刻消失
    selectedCell = nil
    afterSuccessfulMove(prefix)
    return true
end

for r = 1, gridSize do
    for c = 1, gridSize do
        local btn = Instance.new("TextButton", boardFrame)
        btn.Size = UDim2.new(0, cellPixel, 0, cellPixel)
        btn.Position = UDim2.new(0, (c - 1) * cellPixel, 0, (r - 1) * cellPixel)
        btn.BackgroundColor3 = getSquareColor(r, c)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = ""
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.BorderSizePixel = 1
        btn.ZIndex = 2

        table.insert(cells, {
            Button = btn,
            row = r,
            col = c,
        })
    end
end

for _, cell in ipairs(cells) do
    cell.Button.MouseButton1Click:Connect(function()
        if not selectedCell then
            if board[cell.row][cell.col] == "" then
                setStatus("請選有棋子的格子")
                return
            end

            if getPieceSide(board[cell.row][cell.col]) ~= sideToMove then
                setStatus("現在輪到 " .. sideName(sideToMove))
                return
            end

            selectedCell = {
                row = cell.row,
                col = cell.col,
            }

            resetSquareColors()
            markKingIfInCheck(sideToMove)
            cell.Button.BackgroundColor3 = selectedColor
            setStatus("選擇起點：" .. rcToAlg(cell.row, cell.col))
        else
            -- 如果第二次點到同邊棋子，就改選那顆
            if board[cell.row][cell.col] ~= "" and getPieceSide(board[cell.row][cell.col]) == sideToMove then
                selectedCell = {
                    row = cell.row,
                    col = cell.col,
                }
                resetSquareColors()
                markKingIfInCheck(sideToMove)
                cell.Button.BackgroundColor3 = selectedColor
                setStatus("改選起點：" .. rcToAlg(cell.row, cell.col))
                return
            end

            local fr = selectedCell.row
            local fc = selectedCell.col
            local tr = cell.row
            local tc = cell.col
            doMove(fr, fc, tr, tc)
            resetSquareColors()
            markKingIfInCheck(sideToMove)
        end
    end)
end

local function resetGameState()
    gameState = {
        castlingRights = {
            wK = true,
            wQ = true,
            bK = true,
            bQ = true,
        },
        enPassantTarget = nil,
    }
end

local function initBoard()
    board = {
        {"♜", "♞", "♝", "♛", "♚", "♝", "♞", "♜"},
        {"♟", "♟", "♟", "♟", "♟", "♟", "♟", "♟"},
        {"", "", "", "", "", "", "", ""},
        {"", "", "", "", "", "", "", ""},
        {"", "", "", "", "", "", "", ""},
        {"", "", "", "", "", "", "", ""},
        {"♙", "♙", "♙", "♙", "♙", "♙", "♙", "♙"},
        {"♖", "♘", "♗", "♕", "♔", "♗", "♘", "♖"},
    }

    sideToMove = "w"
    selectedCell = nil
    currentBestMove = nil
    resetGameState()
    clearArrows()
    updateBoardDisplay()
    updateTurnButton()
    setStatus("遊戲已初始化，白棋先走")
end

suggestBtn.MouseButton1Click:Connect(function()
    showBestMove()
end)

resetBtn.MouseButton1Click:Connect(function()
    initBoard()
end)

initBoard()

--[[
使用方式：
1. 按「顯示白棋推薦步 / 顯示黑棋推薦步」。
2. 棋盤上會出現紅色箭頭，起點和目標格會變色。
3. 你手動點起點，再點終點。
4. 移動成功後，箭頭會自動消失。

已支援：
- 王車易位：短易位、長易位
- 吃過路兵：只在對方兵剛走兩格後的下一手有效
- 將軍保護：不能走讓自己王被將軍的步
- 將軍顯示：被將軍的王會變紅色格
- 升變：兵到最後一排會自動升變皇后

限制：
- AI 是簡化 minimax，不是 Stockfish 等級。
- UI 棋盤版使用 Unicode 棋子，不是 3D 模型版。
]]
