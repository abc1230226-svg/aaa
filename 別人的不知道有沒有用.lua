--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local LP = Players.LocalPlayer

local FE = ReplicatedStorage:WaitForChild('FE')
local ToggleRagdollRF = FE:WaitForChild('ToggleRagdoll')

local camera = workspace.CurrentCamera

local function ragdoll()
    local call = ToggleRagdollRF:InvokeServer()
    if call == 'Success' then
        return true
    else
        return false, call
    end
end

local function constraintsTPer(folder, tog)
    for _, v in pairs(folder:GetChildren()) do
        if v:IsA('HingeConstraint') or v:IsA('BallSocketConstraint') then
            if v.Name == 'NeckRagdollConstraint' or v.Name == 'WaistRagdollConstraint' then continue end
            v.Enabled = tog
        end
    end
end

local function emulatePart(targetPart)
    local fakePart = Instance.new('Part', workspace)
    fakePart.Size = Vector3.new(1, 1, 1)
    fakePart.CanCollide = false
    fakePart:PivotTo(targetPart:GetPivot())
    fakePart.Name = targetPart.Name
    
    local weld = Instance.new('WeldConstraint', targetPart)
    weld.Part0 = fakePart
    weld.Part1 = targetPart

    return fakePart
end

local function ghostChar(char, bool)
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA('BasePart') then
            v.CanCollide = bool
        end
    end
end

local function attempt(targetPlr)
    if not targetPlr then
        return false, 'target player not found'
    end
    local char = LP.Character
    local targetChar = targetPlr.Character

    local ragdollConstraints = char:FindFirstChild('RagdollConstraints')
    local hum = char:FindFirstChildOfClass('Humanoid')
    local hrp = char:FindFirstChild('HumanoidRootPart')
    local head = char:FindFirstChild('Head')
    local head_neckRigAttachment = head:FindFirstChild('NeckRigAttachment')

    local oldOriginalPivot = char:GetPivot()

    local ragdollCall, err = ragdoll()
    if not ragdollCall then
        return false, 'when trying to ragdoll it didnt succeed: ' .. err
    end

    constraintsTPer(ragdollConstraints, false)
    hum.RequiresNeck = false

    local parts = {}
    local garbage_parts = {}
    for _, v in pairs(char:GetChildren()) do
        if not v:IsA('BasePart') then continue end

        if v.Name == 'Head' or v.Name == 'HumanoidRootPart' or v.Name == 'UpperTorso' or v.Name == 'LowerTorso' then
            local part = emulatePart(v)
            part.Anchored = false

            table.insert(parts, part)
        else
            local part = emulatePart(v)
            part.Anchored = false

            table.insert(garbage_parts, part)
        end
    end

    local targetHead = targetChar:FindFirstChild('Head')
    local connection = RunService.Heartbeat:Connect(function()
        hum.Jump = true
        ghostChar(char, false)

        for _, v in pairs(char:GetChildren()) do
            if v:IsA('BasePart') then
                v.AssemblyLinearVelocity = Vector3.zero
            end
        end

        head_neckRigAttachment.CFrame = CFrame.new(0, -10, 0)
        for _, part in pairs(parts) do
            if part.Name == 'Head' then
                part:PivotTo(CFrame.new(oldOriginalPivot.Position.X, targetHead:GetPivot().Position.Y + Options, oldOriginalPivot.Position.Z))
            else
                part:PivotTo(targetChar:GetPivot() * CFrame.new(0, -10, 0))
            end
        end

        for _, part in pairs(garbage_parts) do
            part:PivotTo(oldOriginalPivot)
        end
    end)
    RunService:BindToRenderStep('rav_spycam', 250, function()
        local rotation = camera.CFrame - camera.CFrame.Position
        local offset = -camera.CFrame.LookVector * 15
        camera.CFrame = CFrame.new(targetChar:GetPivot().Position + offset) * rotation
    end)

    return true, function()
        ghostChar(char, true)
        constraintsTPer(ragdollConstraints, true)
        hum.RequiresNeck = true
        ragdoll()
        connection:Disconnect()
        for _, part in pairs(parts) do
            part:Destroy()
        end
        for _, part in pairs(garbage_parts) do
            part:Destroy()
        end

        char:PivotTo(oldOriginalPivot)
        RunService:UnbindFromRenderStep('rav_spycam')
    end
end

local targetPlr = Players:FindFirstChild('Chaosxmetal')
local succ, stopFunc = attempt(targetPlr)
if not succ then
    print('failed to forcechat: ' .. stopFunc)
    return
end
task.wait(5)
stopFunc()
