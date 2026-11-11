-- NullScript by Jimbet69
-- Nullscape Auto-Collect Script
-- Runtime: KRNL / Synapse X / Fluxus

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp               = Players.LocalPlayer
local char             = lp.Character or lp.CharacterAdded:Wait()
local root             = char:WaitForChild("HumanoidRootPart")
local hum              = char:WaitForChild("Humanoid")

local NAME = "Jimbet69"

local CFG = {
    AutoCollect     = false,
    TeleportCollect = true,
    ShowESP         = false,
    InfJump         = false,
    AntiFall        = false,
    SpeedBoost      = false,
    NoclipEnabled   = false,
    CollectRadius   = 60,
    Speed           = 100,
    Delay           = 0.1,
    ESPColor        = Color3.fromRGB(0, 255, 180),
}

-- ╔══════════════════════════════╗
-- ║         UTILITIES            ║
-- ╚══════════════════════════════╝
local Keywords = {
    "Gift",
    "GiftShell",
    "GoldenGift",
    "GoldenGiftShell",
}

local function isKeyword(name)
    local low = name:lower()
    for _, kw in ipairs(Keywords) do
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
    if r then r.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
end

local function fireTouch(part)
    local r = getRoot()
    if not r then return end
    local old = r.CFrame
    r.CFrame = part.CFrame + Vector3.new(0,2,0)
    task.wait(0.05)
    r.CFrame = old
end

local function tryProximity(obj)
    local p = obj:FindFirstChildOfClass("ProximityPrompt")
        or (obj.Parent and obj.Parent:FindFirstChildOfClass("ProximityPrompt"))
    if p then pcall(fireproximityprompt, p) return true end
    return false
end

-- ╔══════════════════════════════╗
-- ║         ESP                  ║
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
    if espCache[obj] then espCache[obj]:Destroy() espCache[obj] = nil end
end

local function clearESP()
    for obj, hl in pairs(espCache) do hl:Destroy() espCache[obj] = nil end
end

-- ╔══════════════════════════════╗
-- ║         SCANNER              ║
-- ╚══════════════════════════════╝
local function scanWorkspace()
    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if isKeyword(obj.Name) then
                local part = obj:IsA("Model")
                    and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                    or obj
                if part then table.insert(items, {obj=obj, part=part}) end
            end
        end
    end
    return items
end

-- ╔══════════════════════════════╗
-- ║         COLLECT LOOP         ║
-- ╚══════════════════════════════╝
local function collectLoop()
    while CFG.AutoCollect do
        local r = getRoot()
        if r then
            for _, entry in ipairs(scanWorkspace()) do
                if not CFG.AutoCollect then break end
                local part, obj = entry.part, entry.obj
                if distanceTo(part) <= CFG.CollectRadius then
                    if CFG.ShowESP then addHighlight(obj) end
                    if CFG.TeleportCollect then teleportTo(part.Position) end
                    if not tryProximity(obj) then fireTouch(part) end
                    task.wait(CFG.Delay)
                    removeHighlight(obj)
                end
            end
        end
        task.wait(CFG.Delay)
    end
end

-- ╔══════════════════════════════╗
-- ║         NOCLIP               ║
-- ╚══════════════════════════════╝
local noclipConn
local function applyNoclip()
    if CFG.NoclipEnabled then
        noclipConn = RunService.Stepped:Connect(function()
            if lp.Character then
                for _, p in ipairs(lp.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        if lp.Character then
            for _, p in ipairs(lp.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- ╔══════════════════════════════╗
-- ║         INF JUMP             ║
-- ╚══════════════════════════════╝
UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump and lp.Character then
        local h = lp.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ╔══════════════════════════════╗
-- ║         ANTI FALL            ║
-- ╚══════════════════════════════╝
hum.StateChanged:Connect(function(_, new)
    if CFG.AntiFall and new == Enum.HumanoidStateType.Freefall then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end)

-- ╔══════════════════════════════╗
-- ║         RESPAWN              ║
-- ╚══════════════════════════════╝
lp.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
    hum  = newChar:WaitForChild("Humanoid")
    if CFG.SpeedBoost then hum.WalkSpeed = CFG.Speed end
    clearESP()
end)

-- ╔══════════════════════════════════════════════════╗
-- ║                    GUI                           ║
-- ╚══════════════════════════════════════════════════╝
pcall(function()
    if game.CoreGui:FindFirstChild("NullscapeUI") then
        game.CoreGui.NullscapeUI:Destroy()
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NullscapeUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game.CoreGui

-- ── MINIMIZED BUBBLE ─────────────────────────
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.new(0, 46, 0, 46)
bubble.Position = UDim2.new(0, 14, 0, 14)
bubble.BackgroundColor3 = Color3.fromRGB(0, 220, 160)
bubble.Text = "N"
bubble.TextColor3 = Color3.fromRGB(0, 0, 0)
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 20
bubble.BorderSizePixel = 0
bubble.Visible = false
bubble.ZIndex = 20
bubble.Parent = gui
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1,0)

-- ── MAIN WINDOW ──────────────────────────────
local win = Instance.new("Frame")
win.Size = UDim2.new(0, 260, 0, 420)
win.Position = UDim2.new(0, 14, 0, 14)
win.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
win.BorderSizePixel = 0
win.ZIndex = 10
win.Active = true
win.Parent = gui
Instance.new("UICorner", win).CornerRadius = UDim.new(0,10)
local winStroke = Instance.new("UIStroke", win)
winStroke.Color = Color3.fromRGB(0, 220, 160)
winStroke.Thickness = 1.5

-- ── TITLE BAR ────────────────────────────────
local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 11
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)
local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1,0,0,10)
titleFix.Position = UDim2.new(0,0,1,-10)
titleFix.BackgroundColor3 = Color3.fromRGB(0,150,100)
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 11

-- name label in title
local titleTxt = Instance.new("TextLabel", titleBar)
titleTxt.Size = UDim2.new(1,-42,1,0)
titleTxt.Position = UDim2.new(0,10,0,0)
titleTxt.BackgroundTransparency = 1
titleTxt.Text = "⬡ "..NAME.."  |  NullScript"
titleTxt.TextColor3 = Color3.fromRGB(255,255,255)
titleTxt.Font = Enum.Font.GothamBold
titleTxt.TextSize = 13
titleTxt.TextXAlignment = Enum.TextXAlignment.Left
titleTxt.ZIndex = 12

-- minimize button
local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0,26,0,26)
minBtn.Position = UDim2.new(1,-32,0.5,-13)
minBtn.BackgroundColor3 = Color3.fromRGB(220,60,60)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255,255,255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 13
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1,0)

-- ── CREDIT LINE ──────────────────────────────
local credit = Instance.new("TextLabel", win)
credit.Size = UDim2.new(1,0,0,18)
credit.Position = UDim2.new(0,0,0,38)
credit.BackgroundColor3 = Color3.fromRGB(0,100,70)
credit.BackgroundTransparency = 0.4
credit.Text = "  made by "..NAME
credit.TextColor3 = Color3.fromRGB(180,255,220)
credit.Font = Enum.Font.Gotham
credit.TextSize = 11
credit.TextXAlignment = Enum.TextXAlignment.Left
credit.BorderSizePixel = 0
credit.ZIndex = 12

-- ── SCROLL CONTENT ───────────────────────────
local scroll = Instance.new("ScrollingFrame", win)
scroll.Size = UDim2.new(1,0,1,-58)
scroll.Position = UDim2.new(0,0,0,58)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(0,220,160)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 11

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local pad = Instance.new("UIPadding", scroll)
pad.PaddingTop = UDim.new(0,8)
pad.PaddingBottom = UDim.new(0,8)
pad.PaddingLeft = UDim.new(0,10)
pad.PaddingRight = UDim.new(0,10)

-- ── SECTION LABEL ────────────────────────────
local function makeSection(text)
    local lbl = Instance.new("TextLabel", scroll)
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── "..text.." ──"
    lbl.TextColor3 = Color3.fromRGB(0,220,160)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.ZIndex = 12
end

-- ── TOGGLE FACTORY ───────────────────────────
local function makeToggle(label, initState, callback)
    local state = initState
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1,0,0,36)
    row.BackgroundColor3 = Color3.fromRGB(14,16,30)
    row.BorderSizePixel = 0
    row.ZIndex = 12
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-58,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210,255,235)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 13

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0,46,0,24)
    btn.Position = UDim2.new(1,-52,0.5,-12)
    btn.BackgroundColor3 = state
        and Color3.fromRGB(0,200,120)
        or  Color3.fromRGB(70,70,70)
    btn.Text = state and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.ZIndex = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state
            and Color3.fromRGB(0,200,120)
            or  Color3.fromRGB(70,70,70)
        btn.Text = state and "ON" or "OFF"
        callback(state)
    end)
end

-- ── TOGGLES ──────────────────────────────────
makeSection("COLLECT")
makeToggle("⬡  Auto Collect", CFG.AutoCollect, function(v)
    CFG.AutoCollect = v
    if v then task.spawn(collectLoop) else clearESP() end
end)
makeToggle("Teleport To Items", CFG.TeleportCollect, function(v)
    CFG.TeleportCollect = v
end)

makeSection("VISUAL")
makeToggle("ESP Highlights", CFG.ShowESP, function(v)
    CFG.ShowESP = v
    if not v then clearESP() end
end)

makeSection("MOVEMENT")
makeToggle("Speed Boost", CFG.SpeedBoost, function(v)
    CFG.SpeedBoost = v
    local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v and CFG.Speed or 16 end
end)
makeToggle("Infinite Jump", CFG.InfJump, function(v)
    CFG.InfJump = v
end)
makeToggle("Noclip", CFG.NoclipEnabled, function(v)
    CFG.NoclipEnabled = v
    applyNoclip()
end)
makeToggle("Anti Fall Damage", CFG.AntiFall, function(v)
    CFG.AntiFall = v
end)

-- ── RESIZE HANDLE ────────────────────────────
local resizeHandle = Instance.new("TextButton", win)
resizeHandle.Size = UDim2.new(0,18,0,18)
resizeHandle.Position = UDim2.new(1,-18,1,-18)
resizeHandle.BackgroundColor3 = Color3.fromRGB(0,220,160)
resizeHandle.Text = ""
resizeHandle.BorderSizePixel = 0
resizeHandle.ZIndex = 15

local resizing, resizeStart, startSize = false, nil, nil
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        startSize = win.Size
    end
end)

-- ── DRAG ─────────────────────────────────────
local dragging, dragStart, winStart = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        winStart = win.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        if dragging and dragStart then
            local d = input.Position - dragStart
            win.Position = UDim2.new(
                winStart.X.Scale, winStart.X.Offset + d.X,
                winStart.Y.Scale, winStart.Y.Offset + d.Y
            )
        end
        if resizing and resizeStart then
            local d = input.Position - resizeStart
            win.Size = UDim2.new(0,
                math.clamp(startSize.X.Offset + d.X, 200, 500), 0,
                math.clamp(startSize.Y.Offset + d.Y, 180, 600)
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        resizing = false
    end
end)

-- ── MINIMIZE / RESTORE ───────────────────────
minBtn.MouseButton1Click:Connect(function()
    win.Visible = false
    bubble.Visible = true
end)

bubble.MouseButton1Click:Connect(function()
    bubble.Visible = false
    win.Visible = true
end)

-- bubble drag
local bDrag, bDragStart, bStartPos = false, nil, nil
bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        bDrag = true
        bDragStart = input.Position
        bStartPos = bubble.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if bDrag and (
        input.UserInputType == Enum.UserInputType.MouseMovement or
        input.UserInputType == Enum.UserInputType.Touch
    ) then
        local d = input.Position - bDragStart
        bubble.Position = UDim2.new(
            bStartPos.X.Scale, bStartPos.X.Offset + d.X,
            bStartPos.Y.Scale, bStartPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        bDrag = false
    end
end)

-- ╔══════════════════════════════╗
-- ║         START                ║
-- ╚══════════════════════════════╝
print("[NullScript by "..NAME.."] loaded.")
