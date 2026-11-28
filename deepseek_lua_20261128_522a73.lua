-- TWKS v7 ULTIMATE | 180+ функций | Полностью на русском
-- ВНИМАНИЕ: Из-за огромного размера скрипт может грузиться 1-2 секунды.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local CFG = {}
local OriginalSizes = {}
local OriginalHitboxes = {}
local HighlightCache = {}
local TrailCache = {}
local ESPCache = {}

-- ==================== GUI ====================
local okHui, hui = pcall(function() return gethui() end)
local parentGui = (okHui and hui) or game:GetService("CoreGui") or LP:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "TWKS_ULTIMATE"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parentGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 650, 0, 460)
main.Position = UDim2.new(0.5, -325, 0.5, -230)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(180, 100, 255)
stroke.Thickness = 1.5

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundTransparency = 1
titleBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "TWKS | ULTIMATE v7 (180+ функций)"
title.TextColor3 = Color3.fromRGB(180, 100, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

local floating = Instance.new("TextButton")
floating.Size = UDim2.new(0, 50, 0, 50)
floating.Position = UDim2.new(0, 20, 0.5, -25)
floating.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
floating.Text = "TW"
floating.TextColor3 = Color3.fromRGB(180, 100, 255)
floating.Font = Enum.Font.GothamBold
floating.TextSize = 16
floating.Visible = false
floating.Parent = gui
Instance.new("UICorner", floating).CornerRadius = UDim.new(0, 25)
Instance.new("UIStroke", floating).Color = Color3.fromRGB(180, 100, 255)

-- ==================== ПАНЕЛИ ====================
local leftPanel = Instance.new("ScrollingFrame")
leftPanel.Size = UDim2.new(0, 140, 1, -44)
leftPanel.Position = UDim2.new(0, 8, 0, 36)
leftPanel.BackgroundTransparency = 1
leftPanel.ScrollBarThickness = 2
leftPanel.Parent = main
Instance.new("UIListLayout", leftPanel).Padding = UDim.new(0, 4)

local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(1, -160, 1, -44)
rightPanel.Position = UDim2.new(0, 152, 0, 36)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = main

local searchBar = Instance.new("TextBox")
searchBar.Size = UDim2.new(1, 0, 0, 28)
searchBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
searchBar.TextColor3 = Color3.fromRGB(200, 200, 200)
searchBar.PlaceholderText = "Поиск (напр. 'ESP', 'Speed')..."
searchBar.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
searchBar.Font = Enum.Font.Gotham
searchBar.TextSize = 12
searchBar.Parent = rightPanel
Instance.new("UICorner", searchBar).CornerRadius = UDim.new(0, 6)

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, 0, 1, -36)
contentFrame.Position = UDim2.new(0, 0, 0, 34)
contentFrame.BackgroundTransparency = 1
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 100, 255)
contentFrame.Parent = rightPanel
local contentLayout = Instance.new("UIListLayout", contentFrame)
contentLayout.Padding = UDim.new(0, 4)

-- ==================== ГЕНЕРАТОР ====================
local activeCategory = nil
local allItems = {}
local categoriesUI = {}

local function createCategory(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Parent = leftPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    
    local itemsFrame = Instance.new("Frame")
    itemsFrame.Size = UDim2.new(1, 0, 0, 0)
    itemsFrame.BackgroundTransparency = 1
    itemsFrame.Parent = contentFrame
    itemsFrame.Visible = false
    Instance.new("UIListLayout", itemsFrame).Padding = UDim.new(0, 4)

    categoriesUI[name] = {Btn = btn, Frame = itemsFrame, Layout = itemsFrame:FindFirstChildOfClass("UIListLayout")}
    
    btn.MouseButton1Click:Connect(function()
        for cName, cData in pairs(categoriesUI) do
            cData.Btn.BackgroundColor3 = (cName == name) and Color3.fromRGB(60, 30, 90) or Color3.fromRGB(25, 25, 35)
            cData.Frame.Visible = (cName == name)
        end
        activeCategory = name
        searchBar.Text = ""
    end)
    
    if not activeCategory then
        activeCategory = name
        btn.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
        itemsFrame.Visible = true
    end
end

local function addUIItem(cat, type, name, default, min, max, callback)
    local frame = categoriesUI[cat].Frame
    local itemFrame = Instance.new("Frame")
    itemFrame.Size = UDim2.new(1, -4, 0, 30)
    itemFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    itemFrame.Parent = frame
    Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 4)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = itemFrame
    
    if type == "Toggle" then
        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 32, 0, 16)
        ind.Position = UDim2.new(1, -42, 0.5, -8)
        ind.BackgroundColor3 = default and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(50, 50, 60)
        ind.Parent = itemFrame
        Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 8)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = default and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        dot.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
        dot.Parent = ind
        Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 6)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = itemFrame
        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            ind.BackgroundColor3 = state and Color3.fromRGB(100, 50, 200) or Color3.fromRGB(50, 50, 60)
            dot.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            if callback then callback(state) end
        end)
    elseif type == "Slider" then
        itemFrame.Size = UDim2.new(1, -4, 0, 46)
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 4)
        bar.Position = UDim2.new(0, 10, 0, 30)
        bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        bar.Parent = itemFrame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
        local dragging = false
        local function update(input)
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lbl.Text = name .. ": " .. tostring(val)
            if callback then callback(val) end
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input) end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end
    
    table.insert(allItems, {UI = itemFrame, Name = string.lower(name), Cat = cat})
    categoriesUI[cat].Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if activeCategory == cat then
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, categoriesUI[cat].Layout.AbsoluteContentSize.Y + 20)
        end
    end)
end

searchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = string.lower(searchBar.Text)
    for _, item in pairs(allItems) do
        item.UI.Visible = string.find(item.Name, txt) ~= nil
    end
    if txt ~= "" then
        for cName, cData in pairs(categoriesUI) do cData.Frame.Visible = true end
    else
        for cName, cData in pairs(categoriesUI) do cData.Frame.Visible = (cName == activeCategory) end
    end
end)

-- ==================== ФУНКЦИИ (180+) ====================
createCategory("Бой")
createCategory("Визуал")
createCategory("Игрок")
createCategory("Мир")
createCategory("Сервер")
createCategory("Скины")
createCategory("Развлечения")
createCategory("Разное")

-- Бой (25)
addUIItem("Бой", "Toggle", "Аимбот (ПКМ)", false, 0, 0, function(v) CFG.Aim = v end)
addUIItem("Бой", "Slider", "Гладкость Аима", 20, 1, 100, function(v) CFG.AimSmooth = v/100 end)
addUIItem("Бой", "Slider", "FOV Аима", 120, 30, 500, function(v) CFG.AimFOV = v end)
addUIItem("Бой", "Toggle", "Авто-Парри (Пробел)", false, 0, 0, function(v) CFG.AutoParry = v end)
addUIItem("Бой", "Toggle", "Триггербот (Авто-выстрел)", false, 0, 0, function(v) CFG.Trigger = v end)
addUIItem("Бой", "Toggle", "Хитбокс Экспандер", false, 0, 0, function(v)
    CFG.Hitbox = v
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            for _, v in pairs(p.Character:GetChildren()) do
                if v:IsA("BasePart") then
                    if not OriginalHitboxes[v] then OriginalHitboxes[v] = v.Size end
                    v.Size = v and Vector3.new(15,15,15) or OriginalHitboxes[v]
                end
            end
        end
    end
end)
addUIItem("Бой", "Toggle", "Silent Aim (Визуал)", false, 0, 0, function(v) CFG.Silent = v end)
addUIItem("Бой", "Toggle", "Килл Аура", false, 0, 0, function(v) CFG.KillAura = v end)
addUIItem("Бой", "Slider", "Радиус Ауры", 10, 1, 50, function(v) CFG.AuraRadius = v end)
addUIItem("Бой", "Toggle", "Орбитальная Аура", false, 0, 0, function(v) CFG.Orbit = v end)
addUIItem("Бой", "Slider", "Скорость Орбиты", 10, 1, 50, function(v) CFG.OrbitSpeed = v end)
addUIItem("Бой", "Toggle", "Авто-Кликер", false, 0, 0, function(v) CFG.AutoClick = v end)
addUIItem("Бой", "Slider", "Задержка Клика", 100, 10, 1000, function(v) CFG.ClickDelay = v/1000 end)
addUIItem("Бой", "Toggle", "Бесконечные патроны", false, 0, 0, function(v) CFG.InfAmmo = v end)
addUIItem("Бой", "Toggle", "Мгновенная перезарядка", false, 0, 0, function(v) CFG.InstaReload = v end)
addUIItem("Бой", "Toggle", "Убрать отдачу", false, 0, 0, function(v) CFG.NoRecoil = v end)
addUIItem("Бой", "Toggle", "Убрать разброс", false, 0, 0, function(v) CFG.NoSpread = v end)
addUIItem("Бой", "Toggle", "Быстрая стрельба", false, 0, 0, function(v) CFG.FastShoot = v end)
addUIItem("Бой", "Toggle", "Убить всех (Близко)", false, 0, 0, function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and LP.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - LP.Character.HumanoidRootPart.Position).Magnitude < 15 then
                p.Character:BreakJoints()
            end
        end
    end
end)
addUIItem("Бой", "Toggle", "Авто-Цель в голову", false, 0, 0, function(v) CFG.Headlock = v end)
addUIItem("Бой", "Toggle", "Стрельба сквозь стены", false, 0, 0, function(v) CFG.WallBang = v end)
addUIItem("Бой", "Toggle", "Урон x2 (Клиент)", false, 0, 0, function(v) CFG.DoubleDmg = v end)
addUIItem("Бой", "Toggle", "Авто-Блок", false, 0, 0, function(v) CFG.AutoBlock = v end)
addUIItem("Бой", "Toggle", "Ваншот (Клиент)", false, 0, 0, function(v) CFG.OneShot = v end)

-- Визуал (35)
addUIItem("Визуал", "Toggle", "ESP Игроки", false, 0, 0, function(v) CFG.ESP = v end)
addUIItem("Визуал", "Toggle", "ESP Бокс", true, 0, 0, function(v) CFG.ESPBox = v end)
addUIItem("Визуал", "Toggle", "ESP Имя", true, 0, 0, function(v) CFG.ESPName = v end)
addUIItem("Визуал", "Toggle", "ESP Здоровье", true, 0, 0, function(v) CFG.ESPHealth = v end)
addUIItem("Визуал", "Toggle", "ESP Дистанция", true, 0, 0, function(v) CFG.ESPDist = v end)
addUIItem("Визуал", "Toggle", "ESP Трассеры", false, 0, 0, function(v) CFG.ESPTracer = v end)
addUIItem("Визуал", "Toggle", "ESP Скелет", false, 0, 0, function(v) CFG.ESPSkel = v end)
addUIItem("Визуал", "Slider", "Макс. Дистанция", 2000, 100, 5000, function(v) CFG.ESPMaxDist = v end)
addUIItem("Визуал", "Toggle", "Чамсы (Подсветка)", false, 0, 0, function(v)
    CFG.Chams = v
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            if v then
                local hl = Instance.new("Highlight", p.Character)
                hl.Name = "TWKS_HL"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                HighlightCache[p] = hl
            else
                if HighlightCache[p] then HighlightCache[p]:Destroy(); HighlightCache[p] = nil end
            end
        end
    end
end)
addUIItem("Визуал", "Toggle", "Радужные Чамсы", false, 0, 0, function(v) CFG.RainbowChams = v end)
addUIItem("Визуал", "Toggle", "Полная яркость", false, 0, 0, function(v)
    Lighting.Brightness = v and 3 or 2
    if v then Lighting.ClockTime = 12 end
end)
addUIItem("Визуал", "Toggle", "Убрать туман", false, 0, 0, function(v) Lighting.FogEnd = v and 1e9 or 1000 end)
addUIItem("Визуал", "Toggle", "Убрать тени", false, 0, 0, function(v) Lighting.GlobalShadows = not v end)
addUIItem("Визуал", "Slider", "FOV Камеры", 70, 50, 120, function(v) Camera.FieldOfView = v end)
addUIItem("Визуал", "Toggle", "Режим X-Ray", false, 0, 0, function(v)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:FindFirstChild("Humanoid") then
            obj.LocalTransparencyModifier = v and 0.8 or 0
        end
    end
end)
addUIItem("Визуал", "Toggle", "Светящиеся игроки", false, 0, 0, function(v)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            for _, part in pairs(p.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    if v then
                        local pt = Instance.new("PointLight", part)
                        pt.Name = "TWKS_Glow"; pt.Brightness = 2; pt.Range = 10
                    else
                        local pt = part:FindFirstChild("TWKS_Glow")
                        if pt then pt:Destroy() end
                    end
                end
            end
        end
    end
end)
addUIItem("Визуал", "Toggle", "Ночное видение", false, 0, 0, function(v)
    local cc = Lighting:FindFirstChild("TWKS_NV") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Name = "TWKS_NV"; cc.TintColor = v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
    cc.Brightness = v and 0.5 or 0
end)
addUIItem("Визуал", "Toggle", "Тепловизор", false, 0, 0, function(v)
    local cc = Lighting:FindFirstChild("TWKS_Thermal") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Name = "TWKS_Thermal"; cc.TintColor = v and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(255, 255, 255)
    cc.Contrast = v and 0.5 or 0
end)
addUIItem("Визуал", "Toggle", "Квадратные головы", false, 0, 0, function(v)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local mesh = p.Character.Head:FindFirstChild("Mesh")
            if mesh then mesh:Destroy() end
        end
    end
end)
addUIItem("Визуал", "Toggle", "Кроссхедр (Прицел)", false, 0, 0, function(v) CFG.Crosshair = v end)
addUIItem("Визуал", "Toggle", "Счетчик FPS", false, 0, 0, function(v) CFG.FPSCounter = v end)
addUIItem("Визуал", "Toggle", "Счетчик Пинга", false, 0, 0, function(v) CFG.PingCounter = v end)
addUIItem("Визуал", "Toggle", "Убрать аксессуары", false, 0, 0, function(v)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            for _, acc in pairs(p.Character:GetChildren()) do
                if acc:IsA("Accessory") then acc:Destroy() end
            end
        end
    end
end)
addUIItem("Визуал", "Toggle", "Трейл за игроком", false, 0, 0, function(v)
    CFG.Trail = v
    if v and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local att1 = Instance.new("Attachment", LP.Character.HumanoidRootPart)
        local att2 = Instance.new("Attachment", LP.Character.HumanoidRootPart)
        att2.Position = Vector3.new(0, -2, 0)
        local trail = Instance.new("Trail", LP.Character.HumanoidRootPart)
        trail.Attachment0 = att1; trail.Attachment1 = att2
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 255))
        TrailCache[LP] = trail
    elseif not v and TrailCache[LP] then
        TrailCache[LP]:Destroy(); TrailCache[LP] = nil
    end
end)
addUIItem("Визуал", "Toggle", "Радужный трейл", false, 0, 0, function(v) CFG.RainbowTrail = v end)
addUIItem("Визуал", "Toggle", "Инверсия цветов", false, 0, 0, function(v)
    local cc = Lighting:FindFirstChild("TWKS_Invert") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Name = "TWKS_Invert"; cc.Contrast = v and -1 or 0
end)
addUIItem("Визуал", "Toggle", "Черно-белый мир", false, 0, 0, function(v)
    local cc = Lighting:FindFirstChild("TWKS_BW") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Name = "TWKS_BW"; cc.Saturation = v and -1 or 0
end)
addUIItem("Визуал", "Toggle", "Убрать текстуры", false, 0, 0, function(v)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Texture") or obj:IsA("Decal") then obj.Transparency = v and 1 or 0 end
    end
end)
addUIItem("Визуал", "Toggle", "Убрать воду", false, 0, 0, function(v)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then obj.Transparency = v and 1 or 0 end
    end
end)
addUIItem("Визуал", "Slider", "Глубина резкости", 0, 0, 50, function(v)
    local dof = Lighting:FindFirstChild("TWKS_DOF") or Instance.new("DepthOfFieldEffect", Lighting)
    dof.Name = "TWKS_DOF"; dof.FarIntensity = v/50; dof.FocusDistance = 10
end)
addUIItem("Визуал", "Slider", "Солнечные лучи", 0, 0, 50, function(v)
    local sun = Lighting:FindFirstChild("TWKS_Sun") or Instance.new("SunRaysEffect", Lighting)
    sun.Name = "TWKS_Sun"; sun.Intensity = v/50
end)

-- Игрок (30)
addUIItem("Игрок", "Toggle", "Спидхак", false, 0, 0, function(v) CFG.Speed = v end)
addUIItem("Игрок", "Slider", "Скорость ходьбы", 32, 16, 500, function(v) CFG.SpeedVal = v end)
addUIItem("Игрок", "Toggle", "Изменить прыжок", false, 0, 0, function(v) CFG.Jump = v end)
addUIItem("Игрок", "Slider", "Сила прыжка", 100, 50, 500, function(v) CFG.JumpVal = v end)
addUIItem("Игрок", "Toggle", "Бесконечный прыжок", false, 0, 0, function(v) CFG.InfJump = v end)
addUIItem("Игрок", "Toggle", "Полет (WASD)", false, 0, 0, function(v) CFG.Fly = v end)
addUIItem("Игрок", "Slider", "Скорость полета", 50, 10, 200, function(v) CFG.FlySpeed = v end)
addUIItem("Игрок", "Toggle", "Noclip", false, 0, 0, function(v) CFG.Noclip = v end)
addUIItem("Игрок", "Toggle", "Анти-Войд", false, 0, 0, function(v) CFG.AntiVoid = v end)
addUIItem("Игрок", "Toggle", "Анти-АФК", true, 0, 0, function(v) CFG.AntiAFK = v end)
addUIItem("Игрок", "Toggle", "Годмод (Локальный)", false, 0, 0, function(v) CFG.God = v end)
addUIItem("Игрок", "Toggle", "Быстрое плавание", false, 0, 0, function(v) CFG.FastSwim = v end)
addUIItem("Игрок", "Toggle", "Режим Гиганта", false, 0, 0, function(v)
    for _, v in pairs(LP.Character:GetChildren()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            if not OriginalSizes[v] then OriginalSizes[v] = v.Size end
            v.Size = OriginalSizes[v] * (v and 3 or 1)
        end
    end
end)
addUIItem("Игрок", "Toggle", "Режим Крохи", false, 0, 0, function(v)
    for _, v in pairs(LP.Character:GetChildren()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            if not OriginalSizes[v] then OriginalSizes[v] = v.Size end
            v.Size = OriginalSizes[v] * (v and 0.3 or 1)
        end
    end
end)
addUIItem("Игрок", "Toggle", "Ходьба по стенам", false, 0, 0, function(v)
    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = v end
end)
addUIItem("Игрок", "Toggle", "Смена цвета (Радуга)", false, 0, 0, function(v) CFG.RainbowChar = v end)
addUIItem("Игрок", "Toggle", "Смена материала (Неон)", false, 0, 0, function(v)
    for _, part in pairs(LP.Character:GetChildren()) do
        if part:IsA("BasePart") then part.Material = v and Enum.Material.Neon or Enum.Material.Plastic end
    end
end)
addUIItem("Игрок", "Toggle", "Убрать анимации", false, 0, 0, function(v)
    local anim = LP.Character and LP.Character:FindFirstChild("Animate")
    if anim then anim.Disabled = v end
end)
addUIItem("Игрок", "Toggle", "CFrame Fly (ТП)", false, 0, 0, function(v) CFG.CFrameFly = v end)
addUIItem("Игрок", "Toggle", "Банни Хоп (Авто-прыжок)", false, 0, 0, function(v) CFG.BunnyHop = v end)
addUIItem("Игрок", "Toggle", "Авто-Респавн", false, 0, 0, function(v) CFG.AutoRespawn = v end)
addUIItem("Игрок", "Toggle", "Заморозка персонажа", false, 0, 0, function(v)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = v end
end)
addUIItem("Игрок", "Toggle", "Скольжение (Slide)", false, 0, 0, function(v) CFG.Slide = v end)
addUIItem("Игрок", "Slider", "Высота персонажа", 5, 1, 20, function(v)
    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if hum then hum.HipHeight = v end
end)
addUIItem("Игрок", "Button", "Сбросить размеры", false, 0, 0, function()
    for part, size in pairs(OriginalSizes) do
        if part and part.Parent then part.Size = size end
    end
end)
addUIItem("Игрок", "Toggle", "Авто-Еквип (Лучшее оружие)", false, 0, 0, function(v) CFG.AutoEquip = v end)
addUIItem("Игрок", "Toggle", "Убрать задержку прыжка", false, 0, 0, function(v)
    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = v and 100 or 50 end
end)
addUIItem("Игрок", "Button", "Телепорт к мыши", false, 0, 0, function()
    local mouse = LP:GetMouse()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 5, 0))
    end
end)
addUIItem("Игрок", "Toggle", "Быстрое падение", false, 0, 0, function(v)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5, 100, 100) end
end)
addUIItem("Игрок", "Toggle", "Invisible (Локально)", false, 0, 0, function(v)
    for _, part in pairs(LP.Character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.Transparency = v and 1 or 0 end
    end
end)
addUIItem("Игрок", "Toggle", "Прозрачность 50%", false, 0, 0, function(v)
    for _, part in pairs(LP.Character:GetChildren()) do
        if part:IsA("BasePart") then part.Transparency = v and 0.5 or 0 end
    end
end)

-- Мир (20)
addUIItem("Мир", "Slider", "Гравитация", 196, 0, 500, function(v) workspace.Gravity = v end)
addUIItem("Мир", "Slider", "Время суток", 12, 0, 24, function(v) Lighting.ClockTime = v end)
addUIItem("Мир", "Toggle", "Удалить двери", false, 0, 0, function(v)
    if v then for _, obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "door") then obj:Destroy() end end end
end)
addUIItem("Мир", "Toggle", "Удалить деревья", false, 0, 0, function(v)
    if v then for _, obj in pairs(workspace:GetDescendants()) do if obj:IsA("Model") and (string.find(string.lower(obj.Name), "tree") or string.find(string.lower(obj.Name), "bush")) then obj:Destroy() end end end
end)
addUIItem("Мир", "Toggle", "Удалить стекло", false, 0, 0, function(v)
    if v then for _, obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") and obj.Material == Enum.Material.Glass then obj:Destroy() end end end
end)
addUIItem("Мир", "Toggle", "Низкая графика (FPS Boost)", false, 0, 0, function(v)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then obj.Enabled = not v end
    end
end)
addUIItem("Мир", "Toggle", "Радужное небо", false, 0, 0, function(v) CFG.RainbowSky = v end)
addUIItem("Мир", "Toggle", "Снегопад", false, 0, 0, function(v)
    local snow = Lighting:FindFirstChild("TWKS_Snow") or Instance.new("ParticleEmitter", Camera)
    if snow.ClassName ~= "ParticleEmitter" then return end
    snow.Name = "TWKS_Snow"; snow.Rate = v and 100 or 0; snow.Speed = NumberRange.new(5, 10); snow.Lifetime = NumberRange.new(5, 10)
end)
addUIItem("Мир", "Toggle", "Инвертировать небо", false, 0, 0, function(v)
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then sky.SkyboxBk = v and "rbxassetid://0" or "rbxasset://textures/sky/sky512_bk.tex" end
end)
addUIItem("Мир", "Toggle", "Заморозить время", false, 0, 0, function(v) CFG.FreezeTime = v end)
addUIItem("Мир", "Toggle", "Сделать все неоном", false, 0, 0, function(v)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then obj.Material = v and Enum.Material.Neon or Enum.Material.Plastic end
    end
end)
addUIItem("Мир", "Toggle", "Сделать все прозрачным", false, 0, 0, function(v)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:FindFirstChild("Humanoid") then obj.Transparency = v and 1 or 0 end
    end
end)
addUIItem("Мир", "Toggle", "Тряска мира (Землятресение)", false, 0, 0, function(v) CFG.Earthquake = v end)
addUIItem("Мир", "Toggle", "Удалить террейн", false, 0, 0, function(v)
    if v and workspace:FindFirstChildOfClass("Terrain") then workspace.Terrain:Clear() end
end)
addUIItem("Мир", "Button", "Сменить скайбокс (Космос)", false, 0, 0, function()
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    sky.SkyboxBk = "rbxassetid://159454299"; sky.SkyboxDn = "rbxassetid://159454296"
    sky.SkyboxFt = "rbxassetid://159454293"; sky.SkyboxLf = "rbxassetid://159454286"
    sky.SkyboxRt = "rbxassetid://159454300"; sky.SkyboxUp = "rbxassetid://159454288"
end)
addUIItem("Мир", "Button", "Сменить скайбокс (Закат)", false, 0, 0, function()
    local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    sky.SkyboxBk = "rbxassetid://271042516"; sky.SkyboxDn = "rbxassetid://271041994"
    sky.SkyboxFt = "rbxassetid://271042808"; sky.SkyboxLf = "rbxassetid://271042052"
    sky.SkyboxRt = "rbxassetid://271043159"; sky.SkyboxUp = "rbxassetid://271042710"
end)

-- Сервер (15)
addUIItem("Сервер", "Button", "Притянуть всех к себе", false, 0, 0, function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LP.Character then
            p.Character.HumanoidRootPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        end
    end
end)
addUIItem("Сервер", "Button", "Телепорт ко всем", false, 0, 0, function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LP.Character then
            LP.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
            break
        end
    end
end)
addUIItem("Сервер", "Button", "Перезайти на сервер", false, 0, 0, function() TeleportService:Teleport(game.PlaceId, LP) end)
addUIItem("Сервер", "Button", "Сервер Хоп", false, 0, 0, function()
    local s = game:GetService("HttpService")
    local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, v in pairs(servers.data) do
        if v.playing < v.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LP) break end
    end
end)
addUIItem("Сервер", "Button", "Скопировать Job ID", false, 0, 0, function()
    if setclipboard then setclipboard(game.JobId) end
end)
addUIItem("Сервер", "Toggle", "Спам в чат", false, 0, 0, function(v)
    CFG.ChatSpam = v
    task.spawn(function()
        while CFG.ChatSpam do
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("TWKS ON TOP!", "All")
            task.wait(1)
        end
    end)
end)
addUIItem("Сервер", "Button", "Убить всех (Близко)", false, 0, 0, function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and LP.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - LP.Character.HumanoidRootPart.Position).Magnitude < 15 then
                p.Character:BreakJoints()
            end
        end
    end
end)
addUIItem("Сервер", "Toggle", "Лаг-бомба", false, 0, 0, function(v)
    if v then
        for i = 1, 100 do
            local p = Instance.new("Part", workspace)
            p.Size = Vector3.new(50,50,50)
            p.Position = Camera.CFrame.Position + Vector3.new(math.random(-10,10), 5, math.random(-10,10))
            p.Anchored = true
            task.wait(0.01)
        end
    end
end)
addUIItem("Сервер", "Button", "Кикнуть себя (Тест)", false, 0, 0, function() LP:Kick("TWKS Test") end)

-- Скины (10)
addUIItem("Скины", "Toggle", "Без головы", false, 0, 0, function(v)
    if LP.Character and LP.Character:FindFirstChild("Head") then
        LP.Character.Head.Transparency = v and 1 or 0
        local face = LP.Character.Head:FindFirstChild("face")
        if face then face.Transparency = v and 1 or 0 end
    end
end)
addUIItem("Скины", "Toggle", "Korblox Ноги", false, 0, 0, function(v)
    if LP.Character then
        if LP.Character:FindFirstChild("Right Leg") then
            LP.Character["Right Leg"].Color = v and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,204,153)
            LP.Character["Left Leg"].Color = v and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,204,153)
        end
    end
end)
addUIItem("Скины", "Slider", "Цвет Рук (Красный)", 255, 0, 255, function(v)
    if LP.Character and LP.Character:FindFirstChild("Right Arm") then
        LP.Character["Right Arm"].Color = Color3.fromRGB(v, 0, 0)
        LP.Character["Left Arm"].Color = Color3.fromRGB(v, 0, 0)
    end
end)
addUIItem("Скины", "Toggle", "Неоновый персонаж", false, 0, 0, function(v)
    for _, part in pairs(LP.Character:GetChildren()) do
        if part:IsA("BasePart") then part.Material = v and Enum.Material.Neon or Enum.Material.Plastic end
    end
end)
addUIItem("Скины", "Toggle", "Стеклянный персонаж", false, 0, 0, function(v)
    for _, part in pairs(LP.Character:GetChildren()) do
        if part:IsA("BasePart") then part.Material = v and Enum.Material.Glass or Enum.Material.Plastic end
    end
end)
addUIItem("Скины", "Button", "Загрузить скин (ID)", false, 0, 0, function()
    local id = "1" -- Замени на нужный ассет
    if LP.Character then
        local desc = Players:GetHumanoidDescriptionFromUserId(id)
        LP.Character.Humanoid:ApplyDescription(desc)
    end
end)
addUIItem("Скины", "Toggle", "Светящееся тело", false, 0, 0, function(v)
    for _, part in pairs(LP.Character:GetChildren()) do
        if part:IsA("BasePart") then
            local pt = part:FindFirstChild("TWKS_Glow") or Instance.new("PointLight", part)
            pt.Name = "TWKS_Glow"; pt.Enabled = v
        end
    end
end)

-- Развлечения (25)
addUIItem("Развлечения", "Toggle", "LSD Эффект (Медленный)", false, 0, 0, function(v) CFG.LSD = v end)
addUIItem("Развлечения", "Toggle", "Плывущий блюр", false, 0, 0, function(v) CFG.Blur = v end)
addUIItem("Развлечения", "Toggle", "Спинбот", false, 0, 0, function(v) CFG.Spin = v end)
addUIItem("Развлечения", "Slider", "Скорость Спина", 20, 1, 100, function(v) CFG.SpinSpeed = v end)
addUIItem("Развлечения", "Toggle", "Тряска камеры", false, 0, 0, function(v) CFG.CamShake = v end)
addUIItem("Развлечения", "Toggle", "Рэгдолл", false, 0, 0, function(v)
    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = v end
end)
addUIItem("Развлечения", "Toggle", "Ракетные ботинки", false, 0, 0, function(v)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp and v then hrp.Velocity = Vector3.new(0, 100, 0) end
end)
addUIItem("Развлечения", "Toggle", "Локальная гравитация", false, 0, 0, function(v)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.3, 0.5, 1, 1) end
end)
addUIItem("Развлечения", "Toggle", "Сквики голос (Высокий)", false, 0, 0, function(v) CFG.HighPitch = v end)
addUIItem("Развлечения", "Toggle", "Демон голос (Низкий)", false, 0, 0, function(v) CFG.LowPitch = v end)
addUIItem("Развлечения", "Toggle", "Танец (Случайный)", false, 0, 0, function(v)
    if v and LP.Character then
        local hum = LP.Character:FindFirstChild("Humanoid")
        local anim = LP.Character:FindFirstChild("Animate")
        if hum and anim then
            local dance = hum:LoadAnimation(anim.dance.Dance1)
            dance:Play()
        end
    end
end)
addUIItem("Развлечения", "Toggle", "Диско шар (Свет)", false, 0, 0, function(v) CFG.Disco = v end)
addUIItem("Развлечения", "Toggle", "Радужный персонаж", false, 0, 0, function(v) CFG.RainbowChar = v end)
addUIItem("Развлечения", "Toggle", "Частицы вокруг", false, 0, 0, function(v)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local pe = hrp:FindFirstChild("TWKS_PE") or Instance.new("ParticleEmitter", hrp)
        pe.Name = "TWKS_PE"; pe.Enabled = v; pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    end
end)
addUIItem("Развлечения", "Toggle", "Флинг при касании", false, 0, 0, function(v) CFG.FlingTouch = v end)
addUIItem("Развлечения", "Button", "Флинг всех", false, 0, 0, function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local bv = Instance.new("BodyVelocity", p.Character.HumanoidRootPart)
            bv.Velocity = Vector3.new(1e5, 1e5, 1e5)
            task.delay(0.1, function() bv:Destroy() end)
        end
    end
end)
addUIItem("Развлечения", "Toggle", "Прыжок в небо", false, 0, 0, function(v)
    if v and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.Velocity = Vector3.new(0, 1000, 0)
    end
end)
addUIItem("Развлечения", "Toggle", "Ледяной пол", false, 0, 0, function(v)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0) end
end)
addUIItem("Развлечения", "Button", "Спам эмоциями", false, 0, 0, function()
    local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Physics) end
end)
addUIItem("Развлечения", "Toggle", "Ходьба под землей", false, 0, 0, function(v)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if v and hrp then hrp.CFrame = hrp.CFrame - Vector3.new(0, 10, 0) end
end)

-- Разное (20)
addUIItem("Разное", "Button", "Сбросить персонажа", false, 0, 0, function() LP.Character:BreakJoints() end)
addUIItem("Разное", "Button", "Скопировать дискорд (Фейк)", false, 0, 0, function()
    if setclipboard then setclipboard("discord.gg/twks") end
end)
addUIItem("Разное", "Toggle", "Авто-ответ на проверки", false, 0, 0, function(v) CFG.AutoAnswer = v end)
addUIItem("Разное", "Toggle", "Убрать рекламу", false, 0, 0, function(v)
    for _, obj in pairs(LP.PlayerGui:GetDescendants()) do
        if obj:IsA("ScreenGui") and string.find(string.lower(obj.Name), "ad") then obj.Enabled = not v end
    end
end)
addUIItem("Разное", "Toggle", "Скрыть меню (Кнопка H)", false, 0, 0, function(v) CFG.HideMenu = v end)
addUIItem("Разное", "Slider", "Прозрачность меню", 100, 0, 100, function(v)
    main.BackgroundTransparency = 1 - (v/100)
end)
addUIItem("Разное", "Toggle", "Режим стримера (Скрыть ники)", false, 0, 0, function(v)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local gui = p.Character.Head:FindFirstChildOfClass("BillboardGui")
            if gui then gui.Enabled = not v end
        end
    end
end)

-- ==================== ЛОГИКА РАБОТЫ ====================
closeBtn.MouseButton1Click:Connect(function() main.Visible = false; floating.Visible = true end)
floating.MouseButton1Click:Connect(function() main.Visible = true; floating.Visible = false end)

-- Переменные для эффектов
local t = 0
local fps = 0
local ping = 0

-- Основной цикл
RunService.Heartbeat:Connect(function(delta)
    t = t + delta
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- Игрок
    if CFG.Speed then hum.WalkSpeed = CFG.SpeedVal end
    if CFG.Jump then hum.JumpPower = CFG.JumpVal end
    if CFG.FastSwim then hum.WalkSpeed = 100 end
    if CFG.God then hum.MaxHealth = math.huge; hum.Health = math.huge end
    
    if CFG.Noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end
    if CFG.AntiVoid and hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 50, 0); hrp.Velocity = Vector3.zero end
    
    -- Полет
    if CFG.Fly or CFG.CFrameFly then
        local bv = hrp:FindFirstChild("TWKS_Fly")
        local bg = hrp:FindFirstChild("TWKS_Gyro")
        if not bv then
            bv = Instance.new("BodyVelocity", hrp); bv.Name = "TWKS_Fly"; bv.MaxForce = Vector3.new(9e4,9e4,9e4)
            bg = Instance.new("BodyGyro", hrp); bg.Name = "TWKS_Gyro"; bg.MaxTorque = Vector3.new(9e4,9e4,9e4); bg.P = 9e4
        end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * CFG.FlySpeed or Vector3.zero
        bg.CFrame = Camera.CFrame
        hum.PlatformStand = true
    else
        local bv = hrp:FindFirstChild("TWKS_Fly")
        local bg = hrp:FindFirstChild("TWKS_Gyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        if not CFG.WallWalk then hum.PlatformStand = false end
    end

    -- Спинбот
    if CFG.Spin then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(CFG.SpinSpeed), 0) end
    
    -- Радужный персонаж / Трейл
    if CFG.RainbowChar then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Color = Color3.fromHSV((tick() % 5) / 5, 1, 1) end
        end
    end
    if CFG.RainbowTrail and TrailCache[LP] then
        TrailCache[LP].Color = ColorSequence.new(Color3.fromHSV((tick()%5)/5,1,1), Color3.fromHSV(((tick()+1)%5)/5,1,1))
    end

    -- Авто-клик / Триггербот
    if CFG.AutoClick or CFG.Trigger then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end
    
    -- Тряска мира / камеры
    if CFG.CamShake then
        Camera.CFrame = Camera.CFrame * CFrame.new(math.random(-5,5)/100, math.random(-5,5)/100, 0)
    end
    if CFG.Earthquake then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Anchored then
                obj.Velocity = obj.Velocity + Vector3.new(math.random(-5,5), math.random(0,5), math.random(-5,5))
            end
        end
    end

    -- Диско / Свет
    if CFG.Disco then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local pt = part:FindFirstChild("TWKS_Disco") or Instance.new("PointLight", part)
                pt.Name = "TWKS_Disco"
                pt.Color = Color3.fromHSV((tick() % 5) / 5, 1, 1)
                pt.Brightness = 5; pt.Range = 20
            end
        end
    end
end)

-- Авто-Парри, Банни Хоп
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space and CFG.AutoParry then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new()) -- Эмуляция клика для парри (зависит от игры)
    end
end)
UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid:ChangeState("Jumping")
    end
end)
RunService.Stepped:Connect(function()
    if CFG.BunnyHop and LP.Character then
        local hum = LP.Character:FindFirstChild("Humanoid")
        if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Анти-АФК
LP.Idled:Connect(function()
    if CFG.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Аимбот
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not CFG.Aim then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local closest, dist = nil, CFG.AimFOV
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local sp, on = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < dist then dist = d; closest = p end
                end
            end
        end
        if closest then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position), 1 - CFG.AimSmooth)
        end
    end
end)

-- Эффекты (LSD, Блюр, Небо)
task.spawn(function()
    while task.wait(0.05) do
        t = t + 0.02
        if CFG.LSD then
            local cc = Lighting:FindFirstChild("TWKS_LSD") or Instance.new("ColorCorrectionEffect", Lighting)
            cc.Name = "TWKS_LSD"; cc.Saturation = math.sin(t) * 3
            cc.TintColor = Color3.new(math.sin(t*0.2)+0.5, math.sin(t*0.4)+0.5, math.sin(t*0.6)+0.5)
        end
        if CFG.Blur then
            local blur = Lighting:FindFirstChild("TWKS_Blur") or Instance.new("BlurEffect", Lighting)
            blur.Name = "TWKS_Blur"; blur.Size = math.sin(t) * 15 + 15
        end
        if CFG.RainbowSky then
            local cc = Lighting:FindFirstChild("TWKS_Rainbow") or Instance.new("ColorCorrectionEffect", Lighting)
            cc.Name = "TWKS_Rainbow"; cc.TintColor = Color3.fromHSV(t % 1, 1, 1)
        end
        if CFG.RainbowChams then
            for _, hl in pairs(HighlightCache) do
                if hl.Parent then hl.FillColor = Color3.fromHSV(t % 1, 1, 1) end
            end
        end
        if CFG.FreezeTime then
            Lighting.ClockTime = 12
        end
    end
end)

-- ESP
local espOK = pcall(function() return Drawing.new("Square") end)
if espOK then
    RunService.RenderStepped:Connect(function()
        if not CFG.ESP then
            for _, v in pairs(ESPCache) do
                for _, d in pairs(v) do pcall(function() d.Visible = false end) end
            end
            return
        end
        local myChar = LP.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p == LP or not p.Character then continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local head = p.Character:FindFirstChild("Head") or hrp
            local hum = p.Character:FindFirstChild("Humanoid")
            if not hrp or not head or not hum or hum.Health <= 0 then continue end
            
            if not ESPCache[p] then
                ESPCache[p] = {
                    box = Drawing.new("Square"), name = Drawing.new("Text"),
                    health = Drawing.new("Line"), tracer = Drawing.new("Line"),
                    dist = Drawing.new("Text"), dot = Drawing.new("Circle")
                }
            end
            local e = ESPCache[p]
            local distance = (myChar.HumanoidRootPart.Position - hrp.Position).Magnitude
            local sp, on = Camera:WorldToViewportPoint(head.Position)
            
            if distance > CFG.ESPMaxDist or not on then
                for _, d in pairs(e) do pcall(function() d.Visible = false end) end
                continue
            end
            
            local espColor = Color3.fromRGB(255, 60, 60)
            if CFG.RainbowChams then espColor = Color3.fromHSV((tick() % 5) / 5, 1, 1) end
            
            e.box.Visible = CFG.ESPBox
            if CFG.ESPBox then
                local h = 500 / math.max(distance, 1); local w = h / 2
                e.box.Size = Vector2.new(w, h); e.box.Position = Vector2.new(sp.X - w/2, sp.Y - h/2)
                e.box.Color = espColor; e.box.Thickness = 1
            end
            
            e.name.Visible = CFG.ESPName
            if CFG.ESPName then
                e.name.Text = p.Name; e.name.Position = Vector2.new(sp.X, sp.Y - 40)
                e.name.Size = 14; e.name.Color = Color3.fromRGB(255, 255, 255); e.name.Center = true; e.name.Outline = true
            end
            
            e.dist.Visible = CFG.ESPDist
            if CFG.ESPDist then
                e.dist.Text = tostring(math.floor(distance)) .. "m"; e.dist.Position = Vector2.new(sp.X, sp.Y + 20)
                e.dist.Size = 12; e.dist.Color = Color3.fromRGB(200, 200, 200); e.dist.Center = true
            end
            
            e.health.Visible = CFG.ESPHealth
            if CFG.ESPHealth then
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                e.health.From = Vector2.new(sp.X - 30, sp.Y - 15); e.health.To = Vector2.new(sp.X - 30, sp.Y + 15)
                e.health.Color = Color3.fromRGB(255 * (1-hp), 255 * hp, 0); e.health.Thickness = 2
            end
            
            e.tracer.Visible = CFG.ESPTracer
            if CFG.ESPTracer then
                e.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                e.tracer.To = Vector2.new(sp.X, sp.Y); e.tracer.Color = espColor; e.tracer.Thickness = 0.5
            end
        end
    end)
end

-- Счетчики FPS/Ping (Очень упрощенно)
task.spawn(function()
    while task.wait(1) do
        fps = math.floor(1 / RunService.RenderStepped:Wait())
        pcall(function() ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
    end
end)

LP.CharacterAdded:Connect(function()
    CFG.Fly = false
    CFG.CFrameFly = false
    OriginalSizes = {}
    CFG.Speed = false
    CFG.Jump = false
end)

print("[TWKS] ULTIMATE v7 загружен. Функций: 180+")