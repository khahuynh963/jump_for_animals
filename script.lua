--[[
    ===================================================================
    🦘 JUMP FOR ANIMALS! - ULTIMATE AUTO HUB V1.0
    Tự động chơi toàn diện cho tựa game Jump for Animals! trên Roblox (AnimalByte)
    
    Tính năng chính:
    1. 🦘 Auto Jump & Stack Power (Tự động nhảy liên tục tích điểm)
    2. 🏆 Auto Teleport Top Tower (Dịch chuyển lên đỉnh tháp lấy Pet / Win)
    3. 🥚 Auto Hatch & Instant Egg Prompt (Mở trứng siêu tốc 0s hold)
    4. 💰 Auto Collect Coins & Gems (Tự hút tiền xu & kim cương)
    5. 🔄 Auto Rebirth (Tự động chuyển sinh tăng Multiplier)
    6. 🏃‍♂️ Super WalkSpeed & CFrame Step Multiplier (Chạy siêu tốc & Lướt CFrame)
    7. 🦘 Infinite Jump & Noclip (Nhảy vô hạn & Xuyên tường)
    8. 🛡️ Anti-AFK Treo Máy 24/7 Xuyên Đêm
    ===================================================================
--]]

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ── Safe GUI Container Helper ──
local function getGuiContainer()
    local container = nil
    pcall(function()
        if gethui then
            container = gethui()
        elseif syn and syn.protect_gui then
            local f = Instance.new("Folder")
            syn.protect_gui(f)
            f.Parent = game:GetService("CoreGui")
            container = f
        elseif game:GetService("CoreGui") then
            container = game:GetService("CoreGui")
        end
    end)
    if not container then
        pcall(function()
            container = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    return container
end

-- Clear old GUI instances
pcall(function()
    local c = getGuiContainer()
    if c and c:FindFirstChild("JumpForAnimalsGui") then
        c.JumpForAnimalsGui:Destroy()
    end
    if game:GetService("CoreGui"):FindFirstChild("JumpForAnimalsGui") then
        game:GetService("CoreGui").JumpForAnimalsGui:Destroy()
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("JumpForAnimalsGui") then
        LocalPlayer.PlayerGui.JumpForAnimalsGui:Destroy()
    end
end)

-- ── State Variables ──
local AutoJumpEnabled = false
local AutoTpTopEnabled = false
local AutoHatchEgg = false
local AutoCollectCoins = false
local AutoRebirth = false
local AutoInstantPrompt = false
local AntiAFK = true

local SpeedEnabled = false
local CustomWalkSpeed = 60
local UseCFrameBoost = false
local CFrameMultiplierIndex = 1
local ALL_CFRAME_MULTIPLIERS = {2, 5, 10, 25, 50}

local InfJumpEnabled = false
local NoclipEnabled = false

-- ── Anti-AFK Setup ──
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if AntiAFK then
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

-- ── Instant ProximityPrompt Optimizer ──
local function optimizePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
        prompt.Enabled = true
    end)
end

local function triggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    optimizePrompt(prompt)
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
            fireproximityprompt(prompt, 100)
            fireproximityprompt(prompt)
        end
    end)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.02)
        prompt:InputHoldEnd()
    end)
end

-- Safe Instant Proximity Prompt Background Loop
task.spawn(function()
    while true do
        task.wait(1.0)
        if AutoInstantPrompt then
            pcall(function()
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.RequiresLineOfSight = false
                        prompt.HoldDuration = 0
                    end
                end
            end)
        end
    end
end)

-- ── Stepped Loop: WalkSpeed, CFrame Step Boost & Noclip ──
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if hum and SpeedEnabled then
        if hum.WalkSpeed ~= CustomWalkSpeed then
            hum.WalkSpeed = CustomWalkSpeed
        end
    end

    if UseCFrameBoost and hrp and hum and hum.MoveDirection.Magnitude > 0 then
        local mult = ALL_CFRAME_MULTIPLIERS[CFrameMultiplierIndex] or 2
        hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (mult * 0.3))
    end

    if NoclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump Request
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Maintain speed on spawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    if SpeedEnabled and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = CustomWalkSpeed
    end
end)

-- ── Helper Function: Find Top Platform / Win Zone ──
local function getTopTowerPosition()
    local highestY = -99999
    local topTargetPos = nil

    -- 1. Quét tìm các nút / phần thưởng / checkpoint có chiều cao Y cao nhất
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local oName = string.lower(obj.Name)
                if string.find(oName, "win") or string.find(oName, "finish") or string.find(oName, "top")
                   or string.find(oName, "reward") or string.find(oName, "egg") or string.find(oName, "animal")
                   or string.find(oName, "checkpoint") or string.find(oName, "stage") then
                    if obj.Position.Y > highestY then
                        highestY = obj.Position.Y
                        topTargetPos = obj.CFrame + Vector3.new(0, 4, 0)
                    end
                end
            end
        end
    end)

    -- 2. Fallback: Nếu không thấy tên cụ thể, quét bất kỳ BasePart nào ở vùng cao nhất của Map
    if not topTargetPos then
        pcall(function()
            for _, part in pairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") and part.Size.Y >= 1 and part.Size.X >= 3 and part.Size.Z >= 3 then
                    if part.Position.Y > highestY then
                        highestY = part.Position.Y
                        topTargetPos = part.CFrame + Vector3.new(0, 4, 0)
                    end
                end
            end
        end)
    end

    return topTargetPos, highestY
end

-- ═══════════════════════════════════════════════════════════
-- 🎨 GIAO DIỆN ĐIỀU KHIỂN (JUMP FOR ANIMALS HUB UI)
-- ═══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JumpForAnimalsGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiContainer()

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 310, 0, 430)
MainFrame.Position = UDim2.new(0.5, -155, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 230, 118) -- Neon Lime Green
MainStroke.Thickness = 1.8
MainStroke.Parent = MainFrame

-- Topbar Header
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 32, 40)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 12)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🦘 JUMP FOR ANIMALS! HUB V1.0"
Title.TextColor3 = Color3.fromRGB(0, 230, 118)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Buttons on TopBar (Minimize & Close)
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -62, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 48, 58)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 220, 240)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 13
MinBtn.Parent = TopBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 25, 25)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TopBar
local clsCorner = Instance.new("UICorner")
clsCorner.CornerRadius = UDim.new(0, 6)
clsCorner.Parent = CloseBtn

-- Floating Icon (Tùy chọn ẩn/hiện nhanh)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 48, 0, 48)
FloatingBtn.Position = UDim2.new(0, 15, 0.35, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 25, 30)
FloatingBtn.Text = "🦘"
FloatingBtn.TextSize = 24
FloatingBtn.Visible = false
FloatingBtn.Parent = ScreenGui
local fltCorner = Instance.new("UICorner")
fltCorner.CornerRadius = UDim.new(1, 0)
fltCorner.Parent = FloatingBtn
local fltStroke = Instance.new("UIStroke")
fltStroke.Color = Color3.fromRGB(0, 230, 118)
fltStroke.Thickness = 2
fltStroke.Parent = FloatingBtn

MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

FloatingBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatingBtn.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Draggable Function
local function makeDraggable(guiObject, handle)
    handle = handle or guiObject
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(MainFrame, TopBar)
makeDraggable(FloatingBtn)

-- Live Status Bar
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, -20, 0, 26)
StatusFrame.Position = UDim2.new(0, 10, 0, 46)
StatusFrame.BackgroundColor3 = Color3.fromRGB(24, 34, 44)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame
local sfCorner = Instance.new("UICorner")
sfCorner.CornerRadius = UDim.new(0, 6)
sfCorner.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -12, 1, 0)
StatusLabel.Position = UDim2.new(0, 6, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "🟢 Trạng thái: Đang chờ lệnh..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 229, 255)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusFrame

local function setStatus(msg)
    StatusLabel.Text = "🟢 " .. msg
end

-- Scroll Content Frame
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -85)
Scroll.Position = UDim2.new(0, 10, 0, 78)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 230, 118)
Scroll.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)
UIList.Parent = Scroll

UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 15)
end)

-- Helper Helper: Create Section Header
local function createSectionHeader(titleText)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "─── " .. string.upper(titleText) .. " ───"
    lbl.TextColor3 = Color3.fromRGB(0, 230, 118)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 11
    lbl.Parent = Scroll
end

-- Helper: Create Toggle Button
local function createToggle(titleText, defaultVal, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 32)
    btn.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 160, 90) or Color3.fromRGB(28, 38, 48)
    btn.Text = titleText .. ": " .. (defaultVal and "ON" or "OFF")
    btn.TextColor3 = defaultVal and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 210, 220)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = Scroll

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = defaultVal and Color3.fromRGB(0, 230, 118) or Color3.fromRGB(45, 58, 70)
    bStroke.Parent = btn

    local state = defaultVal
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 160, 90) or Color3.fromRGB(28, 38, 48)
        btn.Text = titleText .. ": " .. (state and "ON" or "OFF")
        btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 210, 220)
        bStroke.Color = state and Color3.fromRGB(0, 230, 118) or Color3.fromRGB(45, 58, 70)
        callback(state)
    end)

    return btn
end

-- ═══════════════════════════════════════════════════════════
-- 🎛️ BUILD CONTROLS & FEATURES
-- ═══════════════════════════════════════════════════════════

createSectionHeader("🌾 TỰ ĐỘNG CẢY GAME (AUTO FARM)")

-- 1. AUTO JUMP POWER
createToggle("🦘 Auto Jump Tích Power", false, function(val)
    AutoJumpEnabled = val
end)

-- 2. AUTO TP TOP TOWER
createToggle("🏆 Auto Dịch Chuyển Lên Đỉnh Tháp (TP Top)", false, function(val)
    AutoTpTopEnabled = val
end)

-- 3. AUTO COLLECT COINS & GEMS
createToggle("💰 Auto Hút Tiền Xu & Kim Cương", false, function(val)
    AutoCollectCoins = val
end)

-- 4. AUTO HATCH EGGS
createToggle("🥚 Auto Mở Trứng (Auto Hatch Best Egg)", false, function(val)
    AutoHatchEgg = val
end)

-- 5. AUTO REBIRTH
createToggle("🔄 Auto Chuyển Sinh (Auto Rebirth)", false, function(val)
    AutoRebirth = val
end)

createSectionHeader("🏃 TỐC ĐỘ & DỊCH CHUYỂN (MOVEMENT)")

-- 6. WALK SPEED BOOST
createToggle("⚡ Bật Tốc Độ Chạy Cao (Custom WalkSpeed)", false, function(val)
    SpeedEnabled = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val and CustomWalkSpeed or 16
    end
end)

-- Speed Presets
local SpeedPresetFrame = Instance.new("Frame")
SpeedPresetFrame.Size = UDim2.new(1, -4, 0, 28)
SpeedPresetFrame.BackgroundTransparency = 1
SpeedPresetFrame.Parent = Scroll

local spdLayout = Instance.new("UIListLayout")
spdLayout.FillDirection = Enum.FillDirection.Horizontal
spdLayout.Padding = UDim.new(0, 4)
spdLayout.Parent = SpeedPresetFrame

local speeds = {32, 60, 100, 200, 500}
for _, spd in ipairs(speeds) do
    local sBtn = Instance.new("TextButton")
    sBtn.Size = UDim2.new(0.18, 0, 1, 0)
    sBtn.BackgroundColor3 = Color3.fromRGB(30, 42, 54)
    sBtn.Text = tostring(spd)
    sBtn.TextColor3 = Color3.fromRGB(0, 230, 118)
    sBtn.Font = Enum.Font.SourceSansBold
    sBtn.TextSize = 10
    sBtn.Parent = SpeedPresetFrame
    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 4)
    sCorner.Parent = sBtn

    sBtn.MouseButton1Click:Connect(function()
        CustomWalkSpeed = spd
        setStatus("Tốc độ đã chỉnh: " .. spd)
        if SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = CustomWalkSpeed
        end
    end)
end

-- 7. CFRAME BOOST
local btnCFrame = Instance.new("TextButton")
btnCFrame.Size = UDim2.new(1, -4, 0, 30)
btnCFrame.BackgroundColor3 = Color3.fromRGB(28, 38, 48)
btnCFrame.Text = "🌀 Lướt Siêu Âm CFrame: [ OFF ]"
btnCFrame.TextColor3 = Color3.fromRGB(200, 210, 220)
btnCFrame.Font = Enum.Font.SourceSansBold
btnCFrame.TextSize = 11
btnCFrame.Parent = Scroll
local cfCorner = Instance.new("UICorner")
cfCorner.CornerRadius = UDim.new(0, 6)
cfCorner.Parent = btnCFrame

btnCFrame.MouseButton1Click:Connect(function()
    if not UseCFrameBoost then
        UseCFrameBoost = true
        CFrameMultiplierIndex = 1
    else
        CFrameMultiplierIndex = CFrameMultiplierIndex + 1
        if CFrameMultiplierIndex > #ALL_CFRAME_MULTIPLIERS then
            UseCFrameBoost = false
            CFrameMultiplierIndex = 1
        end
    end

    if UseCFrameBoost then
        local mult = ALL_CFRAME_MULTIPLIERS[CFrameMultiplierIndex]
        btnCFrame.Text = "🌀 Lướt Siêu Âm CFrame: [ ON " .. tostring(mult) .. "x ]"
        btnCFrame.TextColor3 = Color3.fromRGB(0, 230, 118)
    else
        btnCFrame.Text = "🌀 Lướt Siêu Âm CFrame: [ OFF ]"
        btnCFrame.TextColor3 = Color3.fromRGB(200, 210, 220)
    end
end)

-- 8. INFINITE JUMP
createToggle("🦘 Nhảy Vô Hạn (Infinite Jump)", false, function(val)
    InfJumpEnabled = val
end)

-- 9. NOCLIP
createToggle("👻 Đi Xuyên Tường (Noclip)", false, function(val)
    NoclipEnabled = val
end)

createSectionHeader("🛠️ TIỆN ÍCH KHÁC (UTILITIES)")

-- 10. TELEPORT INSTANT TO TOP
local btnTpNow = Instance.new("TextButton")
btnTpNow.Size = UDim2.new(1, -4, 0, 32)
btnTpNow.BackgroundColor3 = Color3.fromRGB(0, 150, 120)
btnTpNow.Text = "🚀 DỊCH CHUYỂN TỨC THỜI LÊN ĐỈNH (TP NOW)"
btnTpNow.TextColor3 = Color3.fromRGB(255, 255, 255)
btnTpNow.Font = Enum.Font.SourceSansBold
btnTpNow.TextSize = 11
btnTpNow.Parent = Scroll
local tpNowCorner = Instance.new("UICorner")
tpNowCorner.CornerRadius = UDim.new(0, 6)
tpNowCorner.Parent = btnTpNow

btnTpNow.MouseButton1Click:Connect(function()
    pcall(function()
        local topCFrame = getTopTowerPosition()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and topCFrame then
            hrp.CFrame = topCFrame
            setStatus("🚀 Đã dịch chuyển tức thời lên Đỉnh Tháp!")
        else
            setStatus("⚠️ Không tìm thấy đỉnh tháp!")
        end
    end)
end)

-- 11. INSTANT PROMPT TOGGLE
createToggle("⚡ Mở Trứng / Nhặt Đồ 0s Hold (Instant Prompt)", false, function(val)
    AutoInstantPrompt = val
end)

-- ═══════════════════════════════════════════════════════════
-- ⚙️ ĐỘNG CƠ XỬ LÝ NỀN (BACKGROUND LOOPS)
-- ═══════════════════════════════════════════════════════════

-- 1. Auto Jump Loop
task.spawn(function()
    while true do
        task.wait(0.15)
        if AutoJumpEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Jump = true
                    setStatus("🦘 Đang tự động nhảy tích điểm Jump...")
                end
            end)
        end
    end
end)

-- 2. Auto TP Top Tower Loop
task.spawn(function()
    while true do
        task.wait(1.5)
        if AutoTpTopEnabled then
            pcall(function()
                local topCFrame = getTopTowerPosition()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and topCFrame then
                    hrp.CFrame = topCFrame
                    setStatus("🏆 Auto TP Đỉnh Tháp: Đã đưa nhân vật lên đỉnh!")
                end
            end)
        end
    end
end)

-- 3. Auto Collect Coins & Gems Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoCollectCoins then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                for _, part in pairs(workspace:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local pName = string.lower(part.Name)
                        if string.find(pName, "coin") or string.find(pName, "gem") or string.find(pName, "cash")
                           or string.find(pName, "reward") or string.find(pName, "drop") then
                            if (part.Position - hrp.Position).Magnitude <= 50 then
                                if firetouchinterest then
                                    firetouchinterest(hrp, part, 0)
                                    task.wait(0.01)
                                    firetouchinterest(hrp, part, 1)
                                else
                                    part.CFrame = hrp.CFrame
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 4. Auto Hatch Egg Loop
task.spawn(function()
    while true do
        task.wait(0.8)
        if AutoHatchEgg then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = string.lower(prompt.ActionText or "")
                        local obj = string.lower(prompt.ObjectText or "")
                        local pName = prompt.Parent and string.lower(prompt.Parent.Name) or ""

                        if string.find(act, "egg") or string.find(obj, "egg") or string.find(pName, "egg")
                           or string.find(act, "hatch") or string.find(act, "open") or string.find(act, "buy")
                           or string.find(act, "pet") or string.find(obj, "pet") then
                            
                            local pPart = prompt.Parent
                            local pPos = pPart and (pPart:IsA("BasePart") and pPart.Position or (pPart:IsA("Model") and pPart.PrimaryPart and pPart.PrimaryPart.Position))
                            
                            if hrp and pPos and (pPos - hrp.Position).Magnitude <= 30 then
                                setStatus("🥚 Đang tự động mở Trứng: " .. (prompt.ObjectText ~= "" and prompt.ObjectText or prompt.Parent.Name))
                                triggerPrompt(prompt)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- 5. Auto Rebirth Loop
task.spawn(function()
    while true do
        task.wait(2.0)
        if AutoRebirth then
            pcall(function()
                for _, prompt in pairs(workspace:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = string.lower(prompt.ActionText or "")
                        local obj = string.lower(prompt.ObjectText or "")
                        if string.find(act, "rebirth") or string.find(obj, "rebirth") or string.find(act, "prestige") then
                            setStatus("🔄 Đang thực hiện Auto Rebirth...")
                            triggerPrompt(prompt)
                        end
                    end
                end
            end)
        end
    end
end)

setStatus("Đã khởi tạo thành công Jump for Animals Hub!")
