-- Nullscape Auto-Collect Script
-- Runtime: KRNL / Synapse X / Fluxus
-- Targets: ores, essences, drops, interactables in Nullscape
-- HttpGet compatible — host on GitHub and loadstring it

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

-- ADD THIS BLOCK anywhere after the services section (after line 13)
-- replaces nothing — paste it in as a new section

-- ╔══════════════════════════════╗
-- ║         NAME UI              ║
-- ╚══════════════════════════════╝
local NAME = "Jimbet69"  -- ← change this to whatever you want displayed

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NullscapeUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 36)
frame.Position = UDim2.new(0, 12, 0, 12)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 255, 180)
stroke.Thickness = 1.5
stroke.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "⬡ " .. NAME .. "  |  NullScript"
label.TextColor3 = Color3.fromRGB(0, 255, 180)
label.TextStrokeTransparency = 0.6
label.Font = Enum.Font.GothamBold
label.TextSize = 15
label.Parent = frame

-- status line below the name
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 220, 0, 24)
statusFrame.Position = UDim2.new(0, 12, 0, 52)
statusFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
statusFrame.BackgroundTransparency = 0.3
statusFrame.BorderSizePixel = 0
statusFrame.Parent = screenGui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusFrame

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(0, 255, 180)
statusStroke.Thickness = 1
statusStroke.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "● collect: ON   ● esp: ON"
statusLabel.TextColor3 = Color3.fromRGB(180, 255, 220)
statusLabel.TextStrokeTransparency = 0.8
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.Parent = statusFrame

-- ╔══════════════════════════════╗
-- ║   UPDATE STATUS ON TOGGLE    ║
-- ╚══════════════════════════════╝
-- replace your existing keybind block with this one
-- it updates the status label when you press F or G

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        CFG.AutoCollect = not CFG.AutoCollect
        if CFG.AutoCollect then
            task.spawn(collectLoop)
        else
            clearESP()
        end
        statusLabel.Text = "● collect: " .. (CFG.AutoCollect and "ON" or "OFF")
            .. "   ● esp: " .. (CFG.ShowESP and "ON" or "OFF")
    end
    if input.KeyCode == Enum.KeyCode.G then
        CFG.ShowESP = not CFG.ShowESP
        if not CFG.ShowESP then clearESP() end
        statusLabel.Text = "● collect: " .. (CFG.AutoCollect and "ON" or "OFF")
            .. "   ● esp: " .. (CFG.ShowESP and "ON" or "OFF")
    end
end)

-- ╔══════════════════════════════╗
-- ║         CONFIG               ║
-- ╚══════════════════════════════╝
local CFG = {
    AutoCollect     = true,       -- main toggle
    CollectRadius   = 60,         -- stud range to scan for items
    TeleportCollect = true,       -- teleport to item instead of walking
    Speed           = 100,        -- walkspeed while collecting
    Delay           = 0.1,        -- seconds between each collect loop
    AutoRespawn     = true,       -- re-attach after character respawn
    ShowESP         = true,       -- highlight collectible items
    ESPColor        = Color3.fromRGB(0, 255, 180),

    -- item name keywords to target (lowercase match)
    Keywords = {
        "ore", "essence", "void", "shard", "fragment",
        "crystal", "drop", "collect", "pickup", "item",
        "resource", "node", "gem", "rune", "core"
    },
}

-- ╔══════════════════════════════╗
-- ║         UTILITIES            ║
-- ╚══════════════════════════════╝
local function isKeyword(name)
    local low = name:lower()
    for _, kw in ipairs(CFG.Keywords) do
        if low:find(kw) then return true end
    end
    return false
end

local function getRoot()
    char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function distanceTo(part)
    local r = getRoot()
    if not r then return math.huge end
    return (part.Position - r.Position).Magnitude
end

local function teleportTo(pos)
    local r = getRoot()
    if r then
        r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

local function fireTouch(part)
    -- fires touched event client-side to trigger pickup
    local r = getRoot()
    if not r then return end
    local oldCF = r.CFrame
    r.CFrame = part.CFrame + Vector3.new(0, 2, 0)
    task.wait(0.05)
    r.CFrame = oldCF
end

-- ╔══════════════════════════════╗
-- ║         ESP HIGHLIGHTS       ║
-- ╚══════════════════════════════╝
local espCache = {}

local function addHighlight(obj)
    if espCache[obj] then return end
    local hl = Instance.new("SelectionBox")
    hl.Color3 = CFG.ESPColor
    hl.LineThickness = 0.04
    hl.SurfaceTransparency = 0.6
    hl.SurfaceColor3 = CFG.ESPColor
    hl.Adornee = obj
    hl.Parent = game.CoreGui
    espCache[obj] = hl
end

local function removeHighlight(obj)
    if espCache[obj] then
        espCache[obj]:Destroy()
        espCache[obj] = nil
    end
end

local function clearESP()
    for obj, hl in pairs(espCache) do
        hl:Destroy()
        espCache[obj] = nil
    end
end

-- ╔══════════════════════════════╗
-- ║         ITEM SCANNER         ║
-- ╚══════════════════════════════╝
local function scanWorkspace()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name
            if isKeyword(name) then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
                if part then
                    table.insert(items, { obj = obj, part = part })
                end
            end
        end
    end
    return items
end

-- ╔══════════════════════════════╗
-- ║         PROXIMITY TRIGGER    ║
-- ╚══════════════════════════════╝
local function tryProximity(obj)
    -- attempt to fire ProximityPrompt if present
    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
        or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
    if prompt then
        fireproximityprompt(prompt)  -- executor API
        return true
    end
    return false
end

-- ╔══════════════════════════════╗
-- ║         MAIN COLLECT LOOP    ║
-- ╚══════════════════════════════╝
local collecting = false

local function collectLoop()
    while CFG.AutoCollect do
        local r = getRoot()
        if r then
            local items = scanWorkspace()

            for _, entry in ipairs(items) do
                if not CFG.AutoCollect then break end
                local part = entry.part
                local obj  = entry.obj
                local dist = distanceTo(part)

                if dist <= CFG.CollectRadius then
                    if CFG.ShowESP then addHighlight(obj) end

                    if CFG.TeleportCollect then
                        teleportTo(part.Position)
                    end

                    -- try proximity prompt first, fallback to touch
                    if not tryProximity(obj) then
                        fireTouch(part)
                    end

                    task.wait(CFG.Delay)
                    removeHighlight(obj)
                end
            end
        end
        task.wait(CFG.Delay)
    end
end

-- ╔══════════════════════════════╗
-- ║         AUTO RESPAWN         ║
-- ╚══════════════════════════════╝
if CFG.AutoRespawn then
    lp.CharacterAdded:Connect(function(newChar)
        char = newChar
        root = newChar:WaitForChild("HumanoidRootPart")
        hum  = newChar:WaitForChild("Humanoid")
        hum.WalkSpeed = CFG.Speed
        clearESP()
    end)
end

-- ╔══════════════════════════════╗
-- ║         WALKSPEED            ║
-- ╚══════════════════════════════╝
hum.WalkSpeed = CFG.Speed

-- ╔══════════════════════════════╗
-- ║         KEYBINDS             ║
-- ╚══════════════════════════════╝
-- F = toggle auto-collect on/off
-- G = toggle ESP highlights
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        CFG.AutoCollect = not CFG.AutoCollect
        if CFG.AutoCollect then
            task.spawn(collectLoop)
            print("[Nullscape] auto-collect ON")
        else
            clearESP()
            print("[Nullscape] auto-collect OFF")
        end
    end
    if input.KeyCode == Enum.KeyCode.G then
        CFG.ShowESP = not CFG.ShowESP
        if not CFG.ShowESP then clearESP() end
        print("[Nullscape] ESP " .. (CFG.ShowESP and "ON" or "OFF"))
    end
end)

-- ╔══════════════════════════════╗
-- ║         START                ║
-- ╚══════════════════════════════╝
task.spawn(collectLoop)
print("[Nullscape] loaded. F=collect toggle | G=ESP toggle")
