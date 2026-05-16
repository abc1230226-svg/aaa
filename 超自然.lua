--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")

local function createHighlight(obj)
	if obj then
		local highlight = Instance.new("Highlight")
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.4
		highlight.Parent = obj
		return highlight
	end
	return nil
end

local mannequin = workspace:FindFirstChild("Mannequin")
local items = workspace:FindFirstChild("Items")
local buddy = workspace:FindFirstChild("Buddy")

local mannequinHighlight = createHighlight(mannequin)
local itemsHighlight = createHighlight(items)
local buddyHighlight = createHighlight(buddy)

local hue = 0
local speed = 0.5

runService.RenderStepped:Connect(function(deltaTime)
	hue = (hue + deltaTime * speed) % 1
	
	if mannequinHighlight then
		mannequinHighlight.FillColor = Color3.fromHSV(hue, 1, 1)
	end
	
	if itemsHighlight then
		itemsHighlight.FillColor = Color3.fromHSV((hue + 0.33) % 1, 1, 1)
	end
	
	if buddyHighlight then
		buddyHighlight.FillColor = Color3.fromHSV((hue + 0.67) % 1, 1, 1)
	end
end)
