-- TWKS // Delta Executor // Mobile-Ready Rust-Style Menu
-- Работает на телефоне. Крестик закрывает меню → появляется иконка для открытия.

if _G.TWKS_LOADED then return end
_G.TWKS_LOADED = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- === ПАПКА ДЛЯ GUI (Delta-safe) ===
local guiParent
pcall(function()
    guiParent = gethui and gethui() or game:GetService("CoreGui")
end)
if not guiParent then
    guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- === УДАЛЕНИЕ СТАРОГО ===
for _, v in pairs(guiParent:GetChildren()) do
    if v.Name == "TWKS_Menu" or v.Name == "TWKS_Icon" then
        v:Destroy()
    end
end

-- === СОСТОЯНИЯ ===
local State = {
    Aimbot = false,
    AimbotSmooth = 0.15,
    AimbotFOV = 120,
    ESP = false,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    WalkSpeed = 16,
    JumpPower = 50,
    FunSpin = false,
    FunRainbow = false,
}

-- ============================================================
-- ГЛАВНОЕ МЕНЮ (горизонтальное, закруглённое, минималистичное)
-- ============================================================
local Menu = Instance.new("Frame")
Menu.Name = "TWKS_Menu"
Menu.Parent = guiParent
Menu.Size = UDim2.new(0, 320, 0, 220)
Menu.Position = UDim2.new(0.5, -160, 0.4, -110)
Menu.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
Menu.BorderSizePixel = 0
Menu.Active = true
Menu.Draggable = true
Menu.Visible = true

local MenuCorner = Instance.new("UICorner", Menu)
MenuCorner.CornerRadius = UDim.new(0, 16)

local MenuStroke = Instance.new("UIStroke", Menu)
MenuStroke.Color = Color3.fromRGB(50, 50, 55)
MenuStroke.Thickness = 1

-- Заголовок / верхняя полоса
local TopBar = Instance.new("Frame", Menu)
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "TWKS // RUST"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- КРЕСТИК (закрывает меню → появляется иконка)
local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 38)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(0, 8)

-- === ИКОНКА (появляется после закрытия меню) ===
local Icon = Instance.new("TextButton")
Icon.Name = "TWKS_Icon"
Icon.Parent = guiParent
Icon.Size = UDim2.new(0, 44, 0, 44)
Icon.Position = UDim2.new(0, 16, 0.5, -22)
Icon.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
Icon.Text = "⚡"
Icon.TextColor3 = Color3.fromRGB(200, 200, 200)
Icon.TextSize = 22
Icon.Font = Enum.Font.GothamBold
Icon.BorderSizePixel = 0
Icon.Visible = false
Icon.Active = true
Icon.Draggable = true

local IconCorner = Instance.new("UICorner", Icon)
IconCorner.CornerRadius = UDim.new(0, 12)

local IconStroke = Instance.new("UIStroke", Icon)
IconStroke.Color = Color3.fromRGB(50, 50, 55)
IconStroke.Thickness = 1

-- Логика: крестик → скрыть меню, показать иконку
CloseBtn.MouseButton1Click:Connect(function()
    Menu.Visible = false
    Icon.Visible = true
end)

-- Логика: иконка → показать меню, скрыть иконку
Icon.MouseButton1Click:Connect(function()
    Menu.Visible = true
    Icon.Visible = false
end)

-- ============================================================
-- КОНТЕНТ: ГОРИЗОНТАЛЬНЫЕ ВКЛАДКИ
-- ============================================================
local TabBar = Instance.new("Frame", Menu)
TabBar.Size = UDim2.new(1, -24, 0, 30)
TabBar.Position = UDim2.new(0, 12, 0, 40)
TabBar.BackgroundTransparency = 1

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Контейнер контента
local Content = Instance.new("Frame", Menu)
Content.Size = UDim2.new(1, -24, 1, -80)
Content.Position = UDim2.new(0, 12, 0, 74)
Content.BackgroundTransparency = 1

local Pages = {}

-- Создание вкладки
local function MakeTab(name, layoutOrder)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 70, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = layoutOrder

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 10)

    local page = Instance.new("ScrollingFrame", Content)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 0)

    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder

    Pages[name] = { Button = btn, Page = page }

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(Pages) do
            p.Page.Visible = false
            p.Button.BackgroundColor3 = Color3.fromRGB(30, 30, 33)
            p.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
        btn.TextColor3 = Color3.fromRGB(18, 18, 20)
    end)

    return page
end

-- Создание тоггла
local function MakeToggle(parent, text, stateKey, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -6, 0, 34)
    f.BackgroundColor3 = Color3.fromRGB(26, 26, 28)
    f.BorderSizePixel = 0

    local c = Instance.new("UICorner", f)
    c.CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -54, 0.5, -11)
    btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(60, 200, 80) or Color3.fromRGB(45, 45, 48)
    btn.Text = State[stateKey] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0

    local bc = Instance.new("UICorner", btn)
    bc.CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        btn.BackgroundColor3 = State[stateKey] and Color3.fromRGB(60, 200, 80) or Color3.fromRGB(45, 45, 48)
        btn.Text = State[stateKey] and "ON" or "OFF"
        if callback then callback(State[stateKey]) end
    end)
end

-- Создание кнопки
local function MakeButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -6, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 35)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(callback)
end

-- ============================================================
-- ВКЛАДКИ
-- ============================================================
local CombatPage = MakeTab("Combat", 1)
local MovementPage = MakeTab("Move", 2)
local VisualsPage = MakeTab("Visuals", 3)
local FunPage = MakeTab("Fun", 4)

-- Показываем первую вкладку
Pages["Combat"].Page.Visible = true
Pages["Combat"].Button.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
Pages["Combat"].Button.TextColor3 = Color3.fromRGB(18, 18, 20)

-- === COMBAT ===
MakeToggle(CombatPage, "Aimbot (hold RMB)", "Aimbot")
MakeToggle(CombatPage, "ESP Players", "ESP")

-- === MOVEMENT ===
MakeToggle(MovementPage, "Fly", "Fly", function(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if on then
        local body = Instance.new("BodyVelocity", hrp)
        body.Name = "TWKS_Fly"
        body.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        body.Velocity = Vector3.zero

        RunService.RenderStepped:Connect(function()
            if not State.Fly then
                body:Destroy()
                return
            end
            local cam = workspace.CurrentCamera
            local move = Vector3.zero
            local dir = cam.CFrame.LookVector
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + dir end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - dir end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if move.Magnitude > 0 then move = move.Unit * State.FlySpeed end
            body.Velocity = move
        end)
    else
        local old = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if old then
            local b = old:FindFirstChild("TWKS_Fly")
            if b then b:Destroy() end
        end
    end
end)

MakeToggle(MovementPage, "Noclip", "Noclip", function(on)
    task.spawn(function()
        while State.Noclip do
            task.wait(0.1)
            local char = LocalPlayer.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end)
end)

-- === VISUALS ===
MakeToggle(VisualsPage, "Fullbright", "FunRainbow", function(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.Brightness = 1
    end
end)

-- === FUN ===
MakeToggle(FunPage, "Spin (rotate character)", "FunSpin", function(on)
    task.spawn(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        while State.FunSpin and hrp do
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(15), 0)
            task.wait(0.05)
        end
    end)
end)

MakeButton(FunPage, "Rainbow Character", function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        end
    end
end)

MakeButton(FunPage, "Fling All (chaos)", function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(math.random(-500,500), math.random(200,800), math.random(-500,500))
            end
        end
    end
end)

-- ============================================================
-- AIMBOT (RMB hold, closest to cursor, FOV)
-- ============================================================
local AimbotConnection = RunService.RenderStepped:Connect(function()
    if not State.Aimbot then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cam = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, State.AimbotFOV

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local thrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            if thrp and hum and hum.Health > 0 then
                local screenPos, onScreen = cam:WorldToScreenPoint(thrp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = thrp
                    end
                end
            end
        end
    end

    if closest then
        local targetPos = closest.Position + Vector3.new(0, 2, 0) -- голова
        local dir = (targetPos - cam.CFrame.Position).Unit
        local newCF = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + dir)
        cam.CFrame = cam.CFrame:Lerp(newCF, State.AimbotSmooth)
    end
end)

-- ============================================================
-- ESP (простой бокс через Highlight)
-- ============================================================
local ESPHighlights = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPHighlights[player] then return end

    local hl = Instance.new("Highlight")
    hl.Name = "TWKS_ESP"
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.FillTransparency = 0.7
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineTransparency = 0
    hl.Adornee = player.Character
    hl.Parent = player.Character
    ESPHighlights[player] = hl
end

local function RemoveESP(player)
    if ESPHighlights[player] then
        ESPHighlights[player]:Destroy()
        ESPHighlights[player] = nil
    end
end

RunService.Heartbeat:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if State.ESP and p ~= LocalPlayer and p.Character then
            CreateESP(p)
        elseif not State.ESP then
            RemoveESP(p)
        end
    end
end)

-- Применяем WalkSpeed / JumpPower (если нужно — можно добавить слайдеры, но сейчас фикс)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.JumpPower = State.JumpPower
    end
end)

print("[TWKS] Menu loaded. Close with X → icon appears.")