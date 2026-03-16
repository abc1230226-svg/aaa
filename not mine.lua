--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TrollRemote = Remotes:WaitForChild("Troll")

local SetSkipperRemotes = {}
for _, child in pairs(ReplicatedStorage:GetChildren()) do
    if child.Name == "SetSkipper" and child:IsA("RemoteEvent") then
        table.insert(SetSkipperRemotes, child)
    end
end

local devProductIds = {
    Kill = 3366469408,
    Freeze = 3366469411,
    Explode = 3366469414,
    Kick = 3346104134,
    Fling = 3366469412,
    Flashbang = 3397573126,
    GiftSkip = 3397585585
}

local commandHistory = {}
local historyIndex = 0

local activeLoops = {
    kill = {},
    freeze = {},
    explode = {},
    kick = {},
    fling = {},
    flashbang = {},
    skip = {}
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdminCommandsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 50)
MainFrame.Position = UDim2.new(0.5, -175, 1, -100)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = ScreenGui

local InputContainer = Instance.new("Frame")
InputContainer.Size = UDim2.new(1, 0, 1, 0)
InputContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
InputContainer.BackgroundTransparency = 0.3
InputContainer.BorderSizePixel = 2
InputContainer.BorderColor3 = Color3.fromRGB(255, 255, 255)
InputContainer.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputContainer

local CommandTextBox = Instance.new("TextBox")
CommandTextBox.Size = UDim2.new(1, -60, 1, 0)
CommandTextBox.Position = UDim2.new(0, 10, 0, 0)
CommandTextBox.BackgroundTransparency = 1
CommandTextBox.Font = Enum.Font.GothamBold
CommandTextBox.TextSize = 16
CommandTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CommandTextBox.TextXAlignment = Enum.TextXAlignment.Left
CommandTextBox.PlaceholderText = "Type command..."
CommandTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
CommandTextBox.Text = ""
CommandTextBox.ClearTextOnFocus = false
CommandTextBox.Parent = InputContainer

local ExecuteButton = Instance.new("TextButton")
ExecuteButton.Size = UDim2.new(0, 40, 0, 40)
ExecuteButton.Position = UDim2.new(1, -45, 0.5, -20)
ExecuteButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ExecuteButton.BorderSizePixel = 0
ExecuteButton.Font = Enum.Font.GothamBold
ExecuteButton.Text = "→"
ExecuteButton.TextSize = 24
ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteButton.Parent = InputContainer

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = ExecuteButton

local AutofillFrame = Instance.new("ScrollingFrame")
AutofillFrame.Size = UDim2.new(1, 0, 0, 0)
AutofillFrame.Position = UDim2.new(0, 0, 1, 5)
AutofillFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
AutofillFrame.BackgroundTransparency = 0.2
AutofillFrame.BorderSizePixel = 2
AutofillFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
AutofillFrame.Visible = false
AutofillFrame.ScrollBarThickness = 6
AutofillFrame.Parent = MainFrame

local AutofillCorner = Instance.new("UICorner")
AutofillCorner.CornerRadius = UDim.new(0, 8)
AutofillCorner.Parent = AutofillFrame

local AutofillLayout = Instance.new("UIListLayout")
AutofillLayout.SortOrder = Enum.SortOrder.LayoutOrder
AutofillLayout.Padding = UDim.new(0, 2)
AutofillLayout.Parent = AutofillFrame

local dragging, dragInput, mousePos, framePos = false, nil, nil, nil

CommandTextBox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, mousePos, framePos = true, input.Position, MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

CommandTextBox.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        MainFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

local isTypingInChat, manualSemicolon = false, false

UserInputService.TextBoxFocused:Connect(function(textbox)
    if textbox.Name == "ChatBar" or textbox:IsDescendantOf(game:GetService("Chat")) then isTypingInChat = true end
end)

UserInputService.TextBoxFocusReleased:Connect(function(textbox)
    if textbox.Name == "ChatBar" or textbox:IsDescendantOf(game:GetService("Chat")) then isTypingInChat = false end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftBracket and not isTypingInChat and not gameProcessed then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then CommandTextBox:CaptureFocus() end
    end
    if input.KeyCode == Enum.KeyCode.Semicolon and not isTypingInChat and MainFrame.Visible and not CommandTextBox:IsFocused() then
        manualSemicolon = true
        CommandTextBox:CaptureFocus()
        task.wait()
        CommandTextBox.Text, CommandTextBox.CursorPosition = ";", 2
    end
end)

local function getPlayer(partialName)
    if not partialName or partialName == "" then return nil end
    partialName = partialName:lower()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower():find(partialName) or player.DisplayName:lower():find(partialName) then return player end
    end
end

local function promptDevProduct(productId)
    if not productId then warn("[Admin] Dev Product ID is nil!") return end
    pcall(function() game:GetService("MarketplaceService"):SignalPromptProductPurchaseFinished(localPlayer.UserId, productId, true) end)
end

local function fireTrollCommand(username, productId)
    if not productId then warn("[Admin] Dev Product ID is nil!") return end
    pcall(function() TrollRemote:FireServer(username, productId) end)
end

local function handleSkip(targetPlayer)
    for _, remote in ipairs(SetSkipperRemotes) do pcall(function() remote:FireServer(targetPlayer.Name) end) end
    task.wait(0.1)
    promptDevProduct(devProductIds.GiftSkip)
end

local commands = {}

local function createTrollCommand(cmdName, productKey)
    commands[cmdName] = function(args)
        local target = args[1]
        if target == "all" then
            for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then fireTrollCommand(p.Name, devProductIds[productKey]) task.wait(0.05) end end
            fireTrollCommand(localPlayer.Name, devProductIds[productKey])
        elseif target == "others" then
            for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then fireTrollCommand(p.Name, devProductIds[productKey]) task.wait(0.05) end end
        else
            local p = getPlayer(target)
            if p then fireTrollCommand(p.Name, devProductIds[productKey]) end
        end
    end
    
    commands["loop"..cmdName] = function(args)
        local target = args[1]
        if target == "all" then
            if activeLoops[cmdName].all then return end
            activeLoops[cmdName].all = true
            task.spawn(function()
                while activeLoops[cmdName].all do
                    for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then fireTrollCommand(p.Name, devProductIds[productKey]) end end
                    fireTrollCommand(localPlayer.Name, devProductIds[productKey])
                    task.wait(0.5)
                end
            end)
        elseif target == "others" then
            if activeLoops[cmdName].others then return end
            activeLoops[cmdName].others = true
            task.spawn(function()
                while activeLoops[cmdName].others do
                    for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then fireTrollCommand(p.Name, devProductIds[productKey]) end end
                    task.wait(0.5)
                end
            end)
        else
            local p = getPlayer(target)
            if p then
                if activeLoops[cmdName][p.UserId] then return end
                activeLoops[cmdName][p.UserId] = true
                task.spawn(function()
                    while activeLoops[cmdName][p.UserId] and p.Parent do
                        fireTrollCommand(p.Name, devProductIds[productKey])
                        task.wait(0.5)
                    end
                    activeLoops[cmdName][p.UserId] = nil
                end)
            end
        end
    end
    
    commands["unloop"..cmdName] = function(args)
        local target = args[1]
        if target == "all" then activeLoops[cmdName] = {}
        elseif target == "others" then activeLoops[cmdName].others = false
        else
            local p = getPlayer(target)
            if p then activeLoops[cmdName][p.UserId] = false end
        end
    end
end

createTrollCommand("kill", "Kill")
createTrollCommand("freeze", "Freeze")
createTrollCommand("explode", "Explode")
createTrollCommand("kick", "Kick")
createTrollCommand("fling", "Fling")
createTrollCommand("flashbang", "Flashbang")

commands.skip = function(args)
    local target = args[1]
    if target == "me" then
        promptDevProduct(devProductIds.GiftSkip)
    elseif target == "all" then
        for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then handleSkip(p) task.wait(0.1) end end
        handleSkip(localPlayer)
    elseif target == "others" then
        for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then handleSkip(p) task.wait(0.1) end end
    else
        local p = getPlayer(target)
        if p then handleSkip(p) end
    end
end

commands.loopskip = function(args)
    local target = args[1]
    if target == "all" then
        if activeLoops.skip.all then return end
        activeLoops.skip.all = true
        task.spawn(function()
            while activeLoops.skip.all do
                for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then handleSkip(p) end end
                handleSkip(localPlayer)
                task.wait(0.5)
            end
        end)
    elseif target == "others" then
        if activeLoops.skip.others then return end
        activeLoops.skip.others = true
        task.spawn(function()
            while activeLoops.skip.others do
                for _, p in pairs(Players:GetPlayers()) do if p ~= localPlayer then handleSkip(p) end end
                task.wait(0.5)
            end
        end)
    else
        local p = getPlayer(target)
        if p then
            if activeLoops.skip[p.UserId] then return end
            activeLoops.skip[p.UserId] = true
            task.spawn(function()
                while activeLoops.skip[p.UserId] and p.Parent do
                    handleSkip(p)
                    task.wait(0.5)
                end
                activeLoops.skip[p.UserId] = nil
            end)
        end
    end
end

commands.unloopskip = function(args)
    local target = args[1]
    if target == "all" then activeLoops.skip = {}
    elseif target == "others" then activeLoops.skip.others = false
    else
        local p = getPlayer(target)
        if p then activeLoops.skip[p.UserId] = false end
    end
end

local function executeCommand(commandText)
    if not commandText or commandText == "" or commandText:sub(1,1) ~= ";" then return end
    if commandText ~= commandHistory[#commandHistory] then
        table.insert(commandHistory, commandText)
        if #commandHistory > 50 then table.remove(commandHistory, 1) end
    end
    historyIndex = #commandHistory + 1
    local parts = {}
    for word in commandText:sub(2):gmatch("%S+") do table.insert(parts, word:lower()) end
    if #parts == 0 then return end
    local commandName, args = parts[1], {}
    for i = 2, #parts do table.insert(args, parts[i]) end
    if commands[commandName] and #args > 0 then commands[commandName](args) end
end

local function getAutofillSuggestions(text)
    local suggestions = {}
    if not text or text == "" or not text:find(";") then return suggestions end
    local parts = {}
    for word in text:sub(2):gmatch("%S+") do table.insert(parts, word:lower()) end
    if #parts < 1 then return suggestions end
    local commandName, searchTerm = parts[1], parts[2] or ""
    if not commands[commandName] then return suggestions end
    if commandName ~= "skip" and not commandName:find("skip") then
        if searchTerm == "" or string.find("all", searchTerm, 1, true) then table.insert(suggestions, {display = "all", value = "all"}) end
        if searchTerm == "" or string.find("others", searchTerm, 1, true) then table.insert(suggestions, {display = "others", value = "others"}) end
    end
    if (commandName == "skip" or commandName:find("skip")) and (searchTerm == "" or string.find("me", searchTerm, 1, true)) then
        table.insert(suggestions, {display = "me", value = "me"})
    end
    for _, player in pairs(Players:GetPlayers()) do
        if #suggestions >= 10 then break end
        if searchTerm == "" or player.Name:lower():find(searchTerm) or player.DisplayName:lower():find(searchTerm) then
            table.insert(suggestions, {display = player.DisplayName .. " (" .. player.Name .. ")", value = player.Name})
        end
    end
    return suggestions
end

local function updateAutofill()
    for _, child in pairs(AutofillFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local suggestions = getAutofillSuggestions(CommandTextBox.Text)
    if #suggestions == 0 then AutofillFrame.Visible = false return end
    AutofillFrame.Visible = true
    local maxHeight = math.min(#suggestions * 32, 300)
    AutofillFrame.CanvasSize = UDim2.new(0, 0, 0, #suggestions * 32)
    AutofillFrame.Size = UDim2.new(1, 0, 0, maxHeight)
    local screenSize = workspace.CurrentCamera.ViewportSize
    local spaceBelow = screenSize.Y - (MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y)
    local spaceAbove = MainFrame.AbsolutePosition.Y
    AutofillFrame.Position = (spaceBelow < maxHeight + 10 and spaceAbove > spaceBelow) and UDim2.new(0, 0, 0, -(maxHeight + 5)) or UDim2.new(0, 0, 1, 5)
    for i, sug in ipairs(suggestions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Text = "  " .. sug.display
        btn.LayoutOrder = i
        btn.Parent = AutofillFrame
        btn.MouseButton1Click:Connect(function()
            local parts = {}
            for word in CommandTextBox.Text:sub(2):gmatch("%S+") do table.insert(parts, word) end
            parts[2] = sug.value
            CommandTextBox.Text = ";" .. table.concat(parts, " ")
            AutofillFrame.Visible = false
            CommandTextBox:CaptureFocus()
        end)
        btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.1 end)
        btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.3 end)
    end
end

CommandTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    if manualSemicolon and CommandTextBox.Text == ";;" then
        CommandTextBox.Text, CommandTextBox.CursorPosition, manualSemicolon = ";", 2, false
    end
    updateAutofill()
end)

CommandTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then executeCommand(CommandTextBox.Text) CommandTextBox.Text = "" AutofillFrame.Visible = false end
end)

UserInputService.InputBegan:Connect(function(input)
    if CommandTextBox:IsFocused() then
        if input.KeyCode == Enum.KeyCode.Up then
            historyIndex = math.max(1, historyIndex - 1)
            CommandTextBox.Text = commandHistory[historyIndex] or ""
        elseif input.KeyCode == Enum.KeyCode.Down then
            historyIndex = math.min(#commandHistory + 1, historyIndex + 1)
            CommandTextBox.Text = commandHistory[historyIndex] or ""
        end
    end
end)

ExecuteButton.MouseButton1Click:Connect(function()
    executeCommand(CommandTextBox.Text)
    CommandTextBox.Text = ""
    AutofillFrame.Visible = false
end)

localPlayer.Chatted:Connect(executeCommand)
MainFrame.Visible = false
