--============================================================
--  CloudClient v1.0
--  Тёмная UI-библиотека для Roblox
--============================================================

--========== СЕРВИСЫ ==========
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local GuiService       = game:GetService("GuiService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

--========== ПАЛИТРА ==========
local C = {
    bg        = Color3.fromRGB(0x12, 0x12, 0x1A),
    panel     = Color3.fromRGB(0x1A, 0x1A, 0x24),
    panel2    = Color3.fromRGB(0x1E, 0x1E, 0x2E),
    accent    = Color3.fromRGB(0x7A, 0xA2, 0xF7),
    accent2   = Color3.fromRGB(0xBB, 0x9A, 0xF7),
    text      = Color3.fromRGB(0xC0, 0xCA, 0xF5),
    textDim   = Color3.fromRGB(0x56, 0x5F, 0x89),
    success   = Color3.fromRGB(0x9E, 0xCE, 0x6A),
    error     = Color3.fromRGB(0xF7, 0x76, 0x8E),
    track     = Color3.fromRGB(0x2A, 0x2A, 0x3A),
    hover     = Color3.fromRGB(0x3A, 0x3A, 0x4A),
    divider   = Color3.fromRGB(0x2A, 0x2A, 0x3A),
}
local FONT  = Enum.Font.Gotham
local FONTB = Enum.Font.GothamBold

--========== УТИЛИТЫ ==========
local function tw(o, t, goal, style, dir)
    local ti = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tween = TweenService:Create(o, ti, goal)
    tween:Play()
    return tween
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, p)
    local u = Instance.new("UIPadding")
    p = p or 10
    u.PaddingTop    = UDim.new(0, p)
    u.PaddingBottom = UDim.new(0, p)
    u.PaddingLeft   = UDim.new(0, p)
    u.PaddingRight  = UDim.new(0, p)
    u.Parent = parent
    return u
end

local function newFrame(name, parent, size, pos, bg, radius)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = size or UDim2.fromOffset(100, 100)
    f.Position = pos or UDim2.fromOffset(0, 0)
    f.BackgroundColor3 = bg or C.panel
    f.BorderSizePixel = 0
    if parent then f.Parent = parent end
    if radius then corner(f, radius) end
    return f
end

local function newLabel(name, parent, text, size, pos, color, font, textSize)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.BackgroundTransparency = 1
    l.Size = size or UDim2.fromOffset(100, 20)
    l.Position = pos or UDim2.fromOffset(0, 0)
    l.Text = text or ""
    l.TextColor3 = color or C.text
    l.Font = font or FONT
    l.TextSize = textSize or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

--========== СОХРАНЕНИЕ ПОЗИЦИИ ИКОНКИ ==========
local SAVE_FILE = "CloudClient_pos.json"
local function savePos(pos)
    if writefile then
        pcall(function()
            writefile(SAVE_FILE, string.format('{"x":%d,"y":%d}', pos.X.Offset, pos.Y.Offset))
        end)
    end
end
local function loadPos()
    if isfile and isfile(SAVE_FILE) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(SAVE_FILE))
        end)
        if ok and data and data.x and data.y then
            return UDim2.fromOffset(data.x, data.y)
        end
    end
    return nil
end

--========== GUI ==========
local old = PG:FindFirstChild("CloudClient")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CloudClient"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PG

--========== ОСНОВНОЕ ОКНО ==========
local WIN_W, WIN_H = 480, 340

local Window = newFrame("Window", ScreenGui, UDim2.fromOffset(WIN_W, WIN_H),
    UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2), C.bg, 10)
Window.ClipsDescendants = false

-- тень: несколько слоёв
for i = 1, 3 do
    local sh = newFrame("Shadow"..i, Window, UDim2.new(1, i*8, 1, i*8),
        UDim2.fromOffset(-i*4, -i*4), C.bg, 12)
    sh.ZIndex = Window.ZIndex - i
    sh.BackgroundTransparency = 0.6 + i*0.1
    local st = stroke(sh, C.bg, 1, 1)
end

local WinStroke = stroke(Window, C.accent, 1, 0.85)

-- верхняя полоса заголовка
local TitleBar = newFrame("TitleBar", Window, UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 0), C.panel, 10)
corner(TitleBar, 10)
TitleBar.ClipsDescendants = true

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.panel),
    ColorSequenceKeypoint.new(1, C.bg),
})
TitleGrad.Parent = TitleBar

-- название с "свечением"
local GlowTitle = newLabel("Glow", TitleBar, "CloudClient",
    UDim2.fromOffset(200, 36), UDim2.fromOffset(15, 1), C.accent, FONTB, 15)
GlowTitle.TextTransparency = 0.5
local Title = newLabel("Title", TitleBar, "CloudClient",
    UDim2.fromOffset(200, 36), UDim2.fromOffset(14, 0), C.text, FONTB, 15)

-- точка статуса
local StatusDot = newFrame("Status", TitleBar, UDim2.fromOffset(6, 6), UDim2.fromOffset(120, 15), C.success, 3)
local dotPulse = TweenService:Create(StatusDot,
    TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {BackgroundTransparency = 0.4})
dotPulse:Play()

-- крестик
local CloseBtn = newFrame("Close", TitleBar, UDim2.fromOffset(24, 24),
    UDim2.new(1, -32, 0, 6), C.track, 12)
CloseBtn.AutoButtonColor = false
local CloseLbl = newLabel("X", CloseBtn, "✕", UDim2.fromScale(1,1), UDim2.fromScale(0,0), C.textDim, FONTB, 13)
CloseLbl.TextXAlignment = Enum.TextXAlignment.Center
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, 0.1, {BackgroundColor3 = C.error}) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, 0.1, {BackgroundColor3 = C.track}) end)

-- версия
newLabel("Ver", Window, "v1.0", UDim2.fromOffset(40, 14),
    UDim2.new(1, -48, 1, -18), C.textDim, FONT, 11)

--========== ВКЛАДКИ ==========
local TabBar = newFrame("Tabs", Window, UDim2.fromOffset(110, WIN_H - 36 - 20),
    UDim2.fromOffset(10, 46), C.bg)
TabBar.BackgroundTransparency = 1

local Content = newFrame("Content", Window,
    UDim2.new(1, -130, 1, -36 - 20),
    UDim2.fromOffset(120, 46), C.bg)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true

local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 4)
TabList.Parent = TabBar

local tabButtons = {}
local tabPages = {}
local activeTab = nil

local function createTab(name, icon)
    local btn = newFrame(name.."Tab", TabBar, UDim2.new(1, 0, 0, 38), nil, C.bg, 6)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true

    local marker = newFrame("Marker", btn, UDim2.new(0, 3, 0, 18), UDim2.new(0, 0, 0.5, -9), C.accent, 3)
    marker.BackgroundTransparency = 1

    local lbl = newLabel("Lbl", btn, icon .. "  " .. name,
        UDim2.new(1, -10, 1, 0), UDim2.fromOffset(10, 0), C.textDim, FONT, 13)

    local page = newFrame(name.."Page", Content, UDim2.fromScale(1, 1), nil, C.bg)
    page.BackgroundTransparency = 1
    page.Visible = false

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.Parent = page
    pad(page, 0)

    tabButtons[name] = {btn = btn, lbl = lbl, marker = marker, page = page}
    tabPages[name] = page

    btn.MouseEnter:Connect(function()
        if activeTab ~= name then
            tw(btn, 0.12, {BackgroundColor3 = C.panel2, BackgroundTransparency = 0})
            tw(lbl, 0.12, {TextColor3 = C.text})
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= name then
            tw(btn, 0.12, {BackgroundTransparency = 1})
            tw(lbl, 0.12, {TextColor3 = C.textDim})
        end
    end)
    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)

    return page
end

function selectTab(name)
    if activeTab == name then return end
    for n, t in pairs(tabButtons) do
        if n == name then
            tw(t.btn, 0.12, {BackgroundColor3 = C.accent, BackgroundTransparency = 0.85})
            tw(t.lbl, 0.12, {TextColor3 = C.text})
            t.marker.BackgroundTransparency = 0
            t.page.Visible = true
            t.page.BackgroundTransparency = 1
            for _, d in ipairs(t.page:GetDescendants()) do
                if d:IsA("GuiObject") then
                    local oldT = d.Transparency
                    if d:IsA("TextLabel") or d:IsA("TextButton") then
                        d.TextTransparency = 1
                        tw(d, 0.1, {TextTransparency = 0})
                    end
                end
            end
        else
            tw(t.btn, 0.12, {BackgroundTransparency = 1})
            tw(t.lbl, 0.12, {TextColor3 = C.textDim})
            t.marker.BackgroundTransparency = 1
            t.page.Visible = false
        end
    end
    activeTab = name
end

--========== КАРТОЧКИ / ЭЛЕМЕНТЫ ==========
local function card(page, title)
    local c = newFrame("Card", page, UDim2.new(1, -2, 0, 0), nil, C.panel, 8)
    c.AutomaticSize = Enum.AutomaticSize.Y
    c.Size = UDim2.new(1, -2, 0, 0)

    local padU = Instance.new("UIPadding")
    padU.PaddingTop = UDim.new(0, 10)
    padU.PaddingBottom = UDim.new(0, 10)
    padU.PaddingLeft = UDim.new(0, 10)
    padU.PaddingRight = UDim.new(0, 10)
    padU.Parent = c

    local lst = Instance.new("UIListLayout")
    lst.Padding = UDim.new(0, 8)
    lst.SortOrder = Enum.SortOrder.LayoutOrder
    lst.Parent = c

    if title then
        local l = newLabel("CardTitle", c, string.upper(title),
            UDim2.new(1, 0, 0, 14), nil, C.textDim, FONTB, 11)
        l.LayoutOrder = 0
    end

    local glowStroke = stroke(c, C.accent, 1, 1)
    c.MouseEnter:Connect(function() tw(glowStroke, 0.15, {Transparency = 0.7}) end)
    c.MouseLeave:Connect(function() tw(glowStroke, 0.15, {Transparency = 1}) end)

    return c
end

local function addToggle(parent, text, default, callback)
    local row = newFrame("ToggleRow", parent, UDim2.new(1, 0, 0, 28), nil, C.panel)
    row.BackgroundTransparency = 1

    local lbl = newLabel("Lbl", row, text, UDim2.new(1, -50, 1, 0), nil, C.text, FONT, 13)

    local tgl = newFrame("Tgl", row, UDim2.fromOffset(36, 20), UDim2.new(1, -36, 0.5, -10), C.track, 10)
    local knob = newFrame("Knob", tgl, UDim2.fromOffset(16, 16), UDim2.fromOffset(2, 2), Color3.new(1,1,1), 8)

    local state = default or false
    local function update(anim)
        if state then
            tw(tgl, anim and 0.15 or 0, {BackgroundColor3 = C.accent})
            tw(knob, anim and 0.15 or 0, {Position = UDim2.new(1, -18, 0, 2)})
        else
            tw(tgl, anim and 0.15 or 0, {BackgroundColor3 = C.track})
            tw(knob, anim and 0.15 or 0, {Position = UDim2.fromOffset(2, 2)})
        end
    end
    update(false)

    tgl.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state = not state
            update(true)
            if callback then callback(state) end
        end
    end)
    return {Set = function(v) state = v; update(true) end, Get = function() return state end}
end

local function addSlider(parent, text, min, max, default, callback)
    local row = newFrame("SliderRow", parent, UDim2.new(1, 0, 0, 40), nil, C.panel)
    row.BackgroundTransparency = 1

    local lbl = newLabel("Lbl", row, text, UDim2.new(0.5, 0, 0, 16), nil, C.text, FONT, 13)
    local valLbl = newLabel("Val", row, tostring(default),
        UDim2.new(0.5, -10, 0, 16), UDim2.new(0.5, 0, 0, 0), C.accent, FONTB, 13)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = newFrame("Track", row, UDim2.new(1, 0, 0, 4),
        UDim2.new(0, 0, 0, 28), C.track, 2)
    local fill = newFrame("Fill", track, UDim2.new(0, 0, 1, 0), nil, C.accent, 2)
    local knob = newFrame("Knob", track, UDim2.fromOffset(14, 14),
        UDim2.new(0, 0, 0.5, -7), Color3.new(1,1,1), 7)
    local knobStroke = stroke(knob, C.accent, 2, 0)

    local value = default
    local dragging = false

    local function setFromX(x)
        local abs = track.AbsolutePosition.X
        local w = track.AbsoluteSize.X
        local p = math.clamp((x - abs) / w, 0, 1)
        value = math.floor(min + (max - min) * p + 0.5)
        local alpha = (value - min) / (max - min)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, -7, 0.5, -7)
        valLbl.Text = tostring(value)
        if callback then callback(value) end
    end

    local alpha0 = (default - min) / (max - min)
    fill.Size = UDim2.new(alpha0, 0, 1, 0)
    knob.Position = UDim2.new(alpha0, -7, 0.5, -7)

    local function beginInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end
    track.InputBegan:Connect(beginInput)
    knob.InputBegan:Connect(beginInput)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {Set = function(v) value = v; setFromX(track.AbsolutePosition.X + track.AbsoluteSize.X * ((v-min)/(max-min))) end}
end

local function addDropdown(parent, text, options, default, callback)
    local row = newFrame("DropRow", parent, UDim2.new(1, 0, 0, 60), nil, C.panel)
    row.BackgroundTransparency = 1
    row.ClipsDescendants = false

    local lbl = newLabel("Lbl", row, text, UDim2.new(1, 0, 0, 16), nil, C.text, FONT, 13)

    local btn = newFrame("DropBtn", row, UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 22), C.track, 6)
    local btnLbl = newLabel("Cur", btn, default or options[1], UDim2.new(1, -24, 1, 0),
        UDim2.fromOffset(8, 0), C.text, FONT, 13)
    local arrow = newLabel("Arrow", btn, "▼", UDim2.fromOffset(20, 28),
        UDim2.new(1, -22, 0, 0), C.textDim, FONT, 11)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local list = newFrame("List", row, UDim2.new(1, 0, 0, 0), UDim2.fromOffset(0, 52), C.panel2, 6)
    list.Visible = false
    list.ClipsDescendants = true
    list.ZIndex = 10
    stroke(list, C.divider, 1, 0.3)

    local listPad = Instance.new("UIPadding")
    listPad.PaddingTop = UDim.new(0, 4)
    listPad.PaddingBottom = UDim.new(0, 4)
    listPad.Parent = list
    local listLay = Instance.new("UIListLayout")
    listLay.Padding = UDim.new(0, 2)
    listLay.Parent = list

    local current = default or options[1]
    local items = {}

    local function buildItems()
        for _, ch in ipairs(list:GetChildren()) do
            if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end
        end
        for _, opt in ipairs(options) do
            local it = Instance.new("TextButton")
            it.Size = UDim2.new(1, 0, 0, 26)
            it.BackgroundColor3 = C.panel2
            it.BorderSizePixel = 0
            it.Text = ""
            it.AutoButtonColor = false
            it.ZIndex = 11
            it.Parent = list
            corner(it, 4)
            local ol = newLabel("T", it, (current == opt and "✓ " or "") .. opt,
                UDim2.new(1, -8, 1, 0), UDim2.fromOffset(8, 0), current == opt and C.accent or C.text, FONT, 12)
            ol.ZIndex = 12
            it.MouseEnter:Connect(function() tw(it, 0.1, {BackgroundColor3 = C.accent}) ; ol.TextColor3 = C.bg end)
            it.MouseLeave:Connect(function() tw(it, 0.1, {BackgroundColor3 = C.panel2}) ; ol.TextColor3 = current == opt and C.accent or C.text end)
            it.MouseButton1Click:Connect(function()
                current = opt
                btnLbl.Text = opt
                list.Visible = false
                arrow.Text = "▼"
                if callback then callback(opt) end
                buildItems()
            end)
        end
        local count = #options
        list.Size = UDim2.new(1, 0, 0, count * 28 + 8)
    end
    buildItems()

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        arrow.Text = list.Visible and "▲" or "▼"
    end)

    return {Get = function() return current end}
end

local function addButton(parent, text, danger, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.BackgroundColor3 = danger and C.error or C.track
    b.BackgroundTransparency = danger and 0.2 or 0
    b.BorderSizePixel = 0
    b.Font = FONTB
    b.TextSize = 13
    b.TextColor3 = danger and Color3.new(1,1,1) or C.text
    b.Text = text
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 6)
    local hovC = danger and C.error or C.hover
    b.MouseEnter:Connect(function() tw(b, 0.12, {BackgroundColor3 = hovC}) end)
    b.MouseLeave:Connect(function() tw(b, 0.12, {BackgroundColor3 = danger and C.error or C.track}) end)
    b.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return b
end

--========== КОНТЕНТ ВКЛАДОК ==========
local mainPage = createTab("Main", "☁")
local visualPage = createTab("Visual", "✦")
local miscPage = createTab("Misc", "⚙")

-- MAIN
local c1 = card(mainPage, "Features")
addToggle(c1, "Auto Farm", false, function(v) print("AutoFarm:", v) end)
addToggle(c1, "Kill Aura", false, function(v) print("KillAura:", v) end)
addToggle(c1, "Anti AFK", true, function(v) print("AntiAFK:", v) end)

local c2 = card(mainPage, "Speed")
addSlider(c2, "WalkSpeed", 16, 200, 16, function(v) end)
addSlider(c2, "JumpPower", 50, 300, 50, function(v) end)

-- VISUAL
local c3 = card(visualPage, "Visual")
addToggle(c3, "ESP", false)
addToggle(c3, "Fullbright", false)
addDropdown(c3, "Theme", {"Cloud", "Lavender", "Midnight"}, "Cloud", function(v) end)

local c4 = card(visualPage, "Colors")
addSlider(c4, "Accent Hue", 0, 360, 220, function(v) end)

-- MISC
local c5 = card(miscPage, "Actions")
addButton(c5, "Reset Character", true, function()
    if LP.Character then LP.Character:BreakJoints() end
end)
addButton(c5, "Rejoin Server", false, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)
newLabel("Soon", miscPage, "скоро...", UDim2.new(1, 0, 0, 20), nil, C.textDim, FONT, 12)

selectTab("Main")

--========== ДРАГ ОКНА ==========
local dragging = false
local dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        Window.Position = newPos
    end
end)

--========== АНИМАЦИЯ ОТКРЫТИЯ/ЗАКРЫТИЯ ==========
local function openMenu()
    Window.Visible = true
    Window.Size = UDim2.fromOffset(WIN_W * 0.9, WIN_H * 0.9)
    for _, d in ipairs(Window:GetDescendants()) do
        if d:IsA("GuiObject") then
            if d.BackgroundTransparency < 1 then d.BackgroundTransparency = 1 end
        end
    end
    Window.BackgroundTransparency = 1
    -- упрощённое появление
    tw(Window, 0.2, {Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundTransparency = 0}, Enum.EasingStyle.Quad)
end

local function closeMenu()
    tw(Window, 0.15, {Size = UDim2.fromOffset(WIN_W * 0.9, WIN_H * 0.9), BackgroundTransparency = 1})
    task.wait(0.15)
    Window.Visible = false
    if FAB then FAB.Visible = true end
end

--========== ПЛАВАЮЩАЯ ИКОНКА (FAB) ==========
local FAB = Instance.new("TextButton")
FAB.Name = "FAB"
FAB.Size = UDim2.fromOffset(48, 48)
FAB.BackgroundColor3 = C.panel
FAB.BorderSizePixel = 0
FAB.Text = "C"
FAB.Font = FONTB
FAB.TextSize = 20
FAB.TextColor3 = C.accent
FAB.AutoButtonColor = false
FAB.Visible = false
FAB.Parent = ScreenGui
corner(FAB, 24)
local fabStroke = stroke(FAB, C.accent, 2, 0)

-- пульсация
local fabPulse = TweenService:Create(fabStroke,
    TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.2})
fabPulse:Play()

local savedPos = loadPos()
FAB.Position = savedPos or UDim2.new(0, 20, 0.5, -24)

-- драг FAB + клик
local fabDragging = false
local fabStart, fabOrig
local moved = false
FAB.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fabDragging = true
        moved = false
        fabStart = input.Position
        fabOrig = FAB.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if fabDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - fabStart
        if delta.Magnitude > 4 then moved = true end
        FAB.Position = UDim2.new(fabOrig.X.Scale, fabOrig.X.Offset + delta.X,
                                 fabOrig.Y.Scale, fabOrig.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if fabDragging and moved then
            savePos(FAB.Position)
        end
        fabDragging = false
    end
end)
FAB.MouseButton1Click:Connect(function()
    if moved then return end
    FAB.Visible = false
    openMenu()
end)

--========== КНОПКА ЗАКРЫТИЯ ==========
CloseBtn.MouseButton1Click:Connect(function()
    closeMenu()
    task.wait(0.16)
    FAB.Visible = true
end)

--========== СТАРТ ==========
Window.Visible = true
FAB.Visible = false

-- опционально: звук закрытия
local closeSound = Instance.new("Sound")
closeSound.SoundId = "rbxassetid://6895079853"
closeSound.Volume = 0.3
closeSound.Parent = ScreenGui
CloseBtn.MouseButton1Click:Connect(function()
    pcall(function() closeSound:Play() end)
end)

print("[CloudClient] v1.0 loaded")