--[[ ============================================================
  TWKS Executor v2 — ЕДИНЫЙ СКРИПТ
  UI + ESP + Silent Aim | Roblox Executor
  Строго по menu.txt / esp.txt / aim.txt
  Lua, Drawing API, RunService, UIS, Players, Camera, TweenService
  ============================================================ ]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")
local Camera       = Workspace.CurrentCamera
local LP           = Players.LocalPlayer
local VPS          = Camera.ViewportSize

--============================================================
-- 0. ПАЛИТРА / КОНСТАНТЫ
--============================================================
local COL = {
    bg      = Color3.fromRGB(10,10,10),
    panel   = Color3.fromRGB(18,18,18),
    hover   = Color3.fromRGB(26,26,26),
    border  = Color3.fromRGB(42,42,42),
    divider = Color3.fromRGB(31,31,31),
    text    = Color3.fromRGB(255,255,255),
    textSec = Color3.fromRGB(138,138,138),
    textDis = Color3.fromRGB(102,102,102),
    black   = Color3.fromRGB(0,0,0),
    search  = Color3.fromRGB(15,15,15),
}
local FONT_REG  = 0 -- Gotham
local FONT_MED  = 2 -- GothamMedium
local FONT_SEMI = 3 -- GothamSemibold

local WIN_W, WIN_H = 800, 500
local HEADER_H, SIDEBAR_W = 56, 180

--============================================================
-- 1. УТИЛИТЫ
--============================================================
local function new(cls, p) local d = Drawing.new(cls); for k,v in pairs(p or {}) do d[k]=v end; return d end
local function lerp(a,b,t) return a+(b-a)*t end
local function lerpV(a,b,t) return Vector2.new(lerp(a.X,b.X,t), lerp(a.Y,b.Y,t)) end
local function lerpC(a,b,t) return Color3.new(lerp(a.R,b.R,t), lerp(a.G,b.G,t), lerp(a.B,b.B,t)) end
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end
local function safe(f, ...) local ok, r = pcall(f, ...); return ok and r or nil end
local function pointInRect(p,x,y,w,h) return p.X>=x and p.X<=x+w and p.Y>=y and p.Y<=y+h end

-- ручной твинер для Drawing (TweenService не работает с Drawing)
local ANIM = {}
local function anim(obj, prop, to, dur, style, cb)
    table.insert(ANIM, {obj=obj,prop=prop,from=obj[prop],to=to,t=0,dur=dur or 0.2,style=style or "QuadOut",cb=cb})
end
local function ease(style, t)
    if style=="QuadOut" then return 1-(1-t)*(1-t) end
    if style=="QuadIn"  then return t*t end
    if style=="ExpoOut" then return t==1 and 1 or 1-2^(-10*t) end
    if style=="BackOut" then
        local c1,c3=1.70158,2.70158
        return 1+c3*(t-1)^3+c1*(t-1)^2
    end
    return t
end
RunService.RenderStepped:Connect(function(dt)
    for i=#ANIM,1,-1 do
        local a=ANIM[i]; a.t=math.min(1,a.t+dt/math.max(a.dur,0.0001))
        local e=ease(a.style,a.t)
        local v
        if typeof(a.from)=="number" then v=lerp(a.from,a.to,e)
        elseif typeof(a.from)=="Vector2" then v=lerpV(a.from,a.to,e)
        elseif typeof(a.from)=="Color3" then v=lerpC(a.from,a.to,e)
        else v=a.to end
        pcall(function() a.obj[a.prop]=v end)
        if a.t>=1 then if a.cb then a.cb() end; table.remove(ANIM,i) end
    end
end)

--============================================================
-- 2. СОСТОЯНИЕ (полное, из ТЗ)
--============================================================
local S = {
    open=false, animating=false, activeTab="AIM",
    winPos=Vector2.new(0,0),
    fabPos=Vector2.new(0,0), fabSide="right",
    -- AIM
    aim = {
        enable=false, keybind="None",
        fov=150, smooth=1.0, target="Head", vischeck=true,
        mode="silent", prediction=true, interpDelay=0.10,
        leadMultiplier=1.15, pingSmoothing=0.90, velocitySmoothing=0.40,
        skipJumping=true, skipFalling=true, skipPingSpike=1.5,
    },
    -- VISUALS
    visuals = {
        esp=false, box=false, boxStyle="2D", skeleton=false,
        health=false, healthPos="Top", nameTags=false, distance=false,
        maxDist=1000, tracer=false, chams=false, chamsMode="Drawing",
    },
    -- MISC
    misc = {
        fovChg=false, fovVal=70, third=false, fps=false,
        speed=false, speedVal=16, jump=false, jumpVal=50, antiafk=false,
    },
}
local CFG_PATH = "TWKS_config.txt"

--============================================================
-- 3. CONFIG SAVE/LOAD
--============================================================
local function saveCfg()
    local o = {}
    for k,v in pairs(S.aim)     do o["aim_"..k]=v end
    for k,v in pairs(S.visuals) do o["vis_"..k]=v end
    for k,v in pairs(S.misc)    do o["misc_"..k]=v end
    o.tab = S.activeTab; o.fabSide = S.fabSide
    o.fabX = S.fabPos.X; o.fabY = S.fabPos.Y
    o.winX = S.winPos.X; o.winY = S.winPos.Y
    local lines = {}
    for k,v in pairs(o) do lines[#lines+1] = k.."="..tostring(v) end
    pcall(writefile, CFG_PATH, table.concat(lines, "\n"))
end
local function loadCfg()
    local ok, c = pcall(readfile, CFG_PATH); if not ok or not c then return end
    for line in c:gmatch("[^\n]+") do
        local k,v = line:match("([^=]+)=(.+)")
        if k and v then
            local n = tonumber(v)
            local b = (v=="true") and true or (v=="false") and false or nil
            local tbl,key = k:match("^(aim|vis|misc)_(.+)$")
            if tbl then
                local ref = (tbl=="aim" and S.aim) or (tbl=="vis" and S.visuals) or S.misc
                if b ~= nil then ref[key] = b
                elseif n then ref[key] = n
                else ref[key] = v end
            elseif k=="tab" then S.activeTab=v
            elseif k=="fabSide" then S.fabSide=v
            elseif k=="fabX" and n then S.fabPos=Vector2.new(n,S.fabPos.Y)
            elseif k=="fabY" and n then S.fabPos=Vector2.new(S.fabPos.X,n)
            elseif k=="winX" and n then S.winPos=Vector2.new(n,S.winPos.Y)
            elseif k=="winY" and n then S.winPos=Vector2.new(S.winPos.X,n) end
        end
    end
end
loadCfg()

--============================================================
-- 4. ESP MODULE
--============================================================
local ESP = { enabled=false, players={}, Config={
    BoxColor=Color3.fromRGB(255,255,255), BoxOutline=Color3.fromRGB(0,0,0),
    Skeleton=Color3.fromRGB(255,255,255), Tracer=Color3.fromRGB(255,255,255),
    Name=Color3.fromRGB(255,255,255), Distance=Color3.fromRGB(200,200,200),
    Chams=Color3.fromRGB(255,255,255), ChamsMode="Drawing",
    Enemy=Color3.fromRGB(255,80,80), Team=Color3.fromRGB(80,255,80), Neutral=Color3.fromRGB(255,255,255),
}}
local R15_PAIRS = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local R6_PAIRS = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local function teamColor(char)
    local plr = Players:GetPlayerFromCharacter(char)
    if plr and LP.Team and plr.Team==LP.Team then return ESP.Config.Team end
    if plr and plr.Team then return ESP.Config.Enemy end
    return ESP.Config.Neutral
end

local function createESP(plr)
    if plr==LP or ESP.players[plr] then return end
    local D = {
        boxOuter = new("Square",{Thickness=2,Color=ESP.Config.BoxOutline,Filled=false,Transparency=0.8,Visible=false}),
        boxInner = new("Square",{Thickness=1,Color=ESP.Config.BoxColor,Filled=false,Transparency=0.9,Visible=false}),
        tracer   = new("Line",{Thickness=1,Transparency=0.9,Visible=false}),
        name     = new("Text",{Center=true,Outline=true,Font=FONT_MED,Size=14,Color=ESP.Config.Name,Visible=false}),
        dist     = new("Text",{Center=true,Outline=true,Font=FONT_REG,Size=12,Color=ESP.Config.Distance,Visible=false}),
        skel = {},
        fade=1,
    }
    for i=1,20 do D.skel[i]=new("Line",{Thickness=1,Transparency=0.9,Visible=false}) end
    -- chams variant
    if ESP.Config.ChamsMode=="Highlight" and plr.Character then
        D.hl = safe(function()
            local h=Instance.new("Highlight"); h.Parent=plr.Character
            h.FillColor=ESP.Config.Chams; h.FillTransparency=0.5
            h.OutlineColor=Color3.new(1,1,1); h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            return h
        end)
    end
    ESP.players[plr]=D
end
local function destroyESP(plr)
    local D = ESP.players[plr]; if not D then return end
    for _,k in ipairs({"boxOuter","boxInner","tracer","name","dist"}) do safe(function() D[k]:Remove() end) end
    for _,l in ipairs(D.skel) do safe(function() l:Remove() end) end
    if D.hl then safe(function() D.hl:Destroy() end) end
    ESP.players[plr]=nil
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(destroyESP)
for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
task.spawn(function()
    while true do
        task.wait(1)
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and not ESP.players[p] then createESP(p) end
        end
    end
end)

local function updateESP(plr, dt, fps)
    local D = ESP.players[plr]; if not D then return end
    local char = plr.Character
    local ok=false
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if hum and hrp and head and hum.Health>0 then ok=true end
    end
    if not ok or not ESP.enabled then
        D.fade = clamp(D.fade+0.25, 0, 1)
    else
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        if dist > S.visuals.maxDist then D.fade=clamp(D.fade+0.25,0,1)
        else
            local hp = head.Position + Vector3.new(0,0.5,0)
            local headVP, on = Camera:WorldToViewportPoint(hp)
            D.fade = clamp(D.fade + (on and -0.25 or 0.25), 0, 1)
            if on and D.fade < 1 then
                local col = teamColor(char)
                -- Box 2D
                if S.visuals.box then
                    local tv,to_ = Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
                    local bv,bo_ = Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
                    if to_ and bo_ then
                        local h = math.abs(tv.Y-bv.Y)
                        local w = h*0.55
                        D.boxOuter.Position=Vector2.new(tv.X-w/2-1, tv.Y-1)
                        D.boxOuter.Size=Vector2.new(w+2,h+2)
                        D.boxOuter.Color=ESP.Config.BoxOutline
                        D.boxOuter.Transparency=0.8+(1-0.8)*D.fade
                        D.boxOuter.Visible=true
                        D.boxInner.Position=Vector2.new(tv.X-w/2, tv.Y)
                        D.boxInner.Size=Vector2.new(w,h)
                        D.boxInner.Color=col
                        D.boxInner.Transparency=0.9+(1-0.9)*D.fade
                        D.boxInner.Visible=true
                    else D.boxOuter.Visible=false; D.boxInner.Visible=false end
                else D.boxOuter.Visible=false; D.boxInner.Visible=false end
                -- Skeleton
                local pairs_ = hum.RigType==Enum.HumanoidRigType.R15 and R15_PAIRS or R6_PAIRS
                if S.visuals.skeleton then
                    local i=1
                    for _,pair in ipairs(pairs_) do
                        local a=char:FindFirstChild(pair[1]); local b=char:FindFirstChild(pair[2])
                        local line=D.skel[i]; i=i+1
                        if a and b then
                            local av,aOn=Camera:WorldToViewportPoint(a.Position)
                            local bv,bOn=Camera:WorldToViewportPoint(b.Position)
                            if aOn and bOn then
                                line.From=Vector2.new(av.X,av.Y); line.To=Vector2.new(bv.X,bv.Y)
                                line.Color=col; line.Thickness=clamp(120/dist,0.5,2.5)
                                line.Transparency=0.9+(1-0.9)*D.fade; line.Visible=true
                            else line.Visible=false end
                        else line.Visible=false end
                    end
                    for j=i,#D.skel do D.skel[j].Visible=false end
                else for j=1,#D.skel do D.skel[j].Visible=false end end
                -- Tracer
                if S.visuals.tracer then
                    D.tracer.From=Vector2.new(VPS.X/2,VPS.Y)
                    D.tracer.To=Vector2.new(headVP.X,headVP.Y)
                    D.tracer.Color=col
                    D.tracer.Thickness=clamp(100/dist,0.5,2)
                    D.tracer.Transparency=0.9+(1-0.9)*D.fade
                    D.tracer.Visible=true
                else D.tracer.Visible=false end
                -- Nametag
                if S.visuals.nameTags then
                    D.name.Text=plr.Name
                    D.name.Position=Vector2.new(headVP.X, headVP.Y-18)
                    D.name.Color=col
                    D.name.Transparency=1-D.fade; D.name.Visible=true
                    if S.visuals.distance then
                        D.dist.Text=string.format("[%dm]", math.floor(dist))
                        D.dist.Position=Vector2.new(headVP.X, headVP.Y-2)
                        D.dist.Transparency=1-D.fade; D.dist.Visible=true
                    else D.dist.Visible=false end
                else D.name.Visible=false; D.dist.Visible=false end
            else
                for _,k in ipairs({"boxOuter","boxInner","tracer","name","dist"}) do D[k].Visible=false end
                for _,l in ipairs(D.skel) do l.Visible=false end
            end
        end
    end
    if D.fade >= 1 then
        for _,k in ipairs({"boxOuter","boxInner","tracer","name","dist"}) do D[k].Visible=false end
        for _,l in ipairs(D.skel) do l.Visible=false end
    end
end

--============================================================
-- 5. AIM MODULE (silent aim, EMA, prediction, hook)
--============================================================
local AIM = {
    enabled=false, currentTarget=nil, smoothedPing=0.1,
    targets={},
    cfg = {
        fovRadius=150, hitPart="AimPoint", prediction=true,
        interpDelay=0.10, leadMultiplier=1.15,
        pingSmoothing=0.90, velocitySmoothing=0.4,
        targetHysteresis=25, skipJumping=true, skipFalling=true,
        skipPingSpike=1.5, smoothness=1.0, aimMode="silent",
    },
}

local function aimSelect()
    local center = Vector2.new(VPS.X/2, VPS.Y/2)
    local cands = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local char = plr.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local hrp  = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                if hum and hrp and head and hum.Health>0 then
                    if not (LP.Team and plr.Team==LP.Team) then
                        local aimPt = head.Position + Vector3.new(0,0.5,0)
                        local aimObj = head:FindFirstChild("AimPoint")
                        if AIM.cfg.hitPart=="AimPoint" and aimObj then aimPt = aimObj.Position end
                        local vp, on = Camera:WorldToViewportPoint(aimPt)
                        if on then
                            local dc = (Vector2.new(vp.X,vp.Y)-center).Magnitude
                            if dc <= AIM.cfg.fovRadius then
                                local now = tick()
                                local prev = AIM.targets[plr]
                                local rawV = Vector3.new(0,0,0)
                                if prev and prev.lastPos then
                                    local dT = math.max(now-prev.lastPosTime, 1/60)
                                    rawV = (hrp.Position-prev.lastPos)/dT
                                end
                                local vel = rawV
                                if prev then vel = prev.vel:Lerp(rawV, AIM.cfg.velocitySmoothing) end
                                AIM.targets[plr] = {
                                    head=head, humanoid=hum, char=char, hrp=hrp,
                                    aimPt=aimPt, lastPos=hrp.Position, lastPosTime=now,
                                    vel=vel, onScreen=on, dCenter=dc,
                                }
                                local vy = hrp.AssemblyLinearVelocity.Y
                                local score = dc + vel.Magnitude*8 + (hrp.Position-Camera.CFrame.Position).Magnitude*0.3 + (vy>5 and 500 or 0)
                                cands[#cands+1] = {plr=plr, score=score, dc=dc}
                            end
                        end
                    end
                end
            end
        end
    end
    -- hysteresis
    if AIM.currentTarget and AIM.targets[AIM.currentTarget] then
        local t=AIM.targets[AIM.currentTarget]
        if t.dCenter <= AIM.cfg.fovRadius + AIM.cfg.targetHysteresis then
            return AIM.currentTarget
        end
    end
    table.sort(cands, function(a,b) return a.score<b.score end)
    return cands[1] and cands[1].plr or nil
end

local function aimCompute(plr)
    local t=AIM.targets[plr]; if not t then return nil end
    local ping = LP:GetNetworkPing() or 0.1
    AIM.smoothedPing = AIM.smoothedPing*AIM.cfg.pingSmoothing + ping*(1-AIM.cfg.pingSmoothing)
    local total = AIM.smoothedPing/2 + AIM.cfg.interpDelay
    local goal = t.aimPt + t.vel*total*AIM.cfg.leadMultiplier
    local off = goal - t.aimPt
    if off.Magnitude > 50 then goal = t.aimPt + off.Unit*50 end
    return goal
end

local function aimBlock(plr)
    local t=AIM.targets[plr]; if not t then return true end
    local vy=t.hrp.AssemblyLinearVelocity.Y
    if AIM.cfg.skipJumping and vy>5 then return true end
    if AIM.cfg.skipFalling and vy<-5 then return true end
    local ping=LP:GetNetworkPing() or 0
    if ping > AIM.smoothedPing*AIM.cfg.skipPingSpike then return true end
    return false
end

local function aimVisible(plr)
    local t=AIM.targets[plr]; if not t then return false end
    local origin = Camera.CFrame.Position
    local goal = aimCompute(plr) or t.aimPt
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LP.Character}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = Workspace:Raycast(origin, goal-origin, rp)
    if not res then return true end
    return res.Instance == t.head or res.Instance:IsDescendantOf(t.char)
end

-- hook
if getrawmetatable and getnamecallmethod and setreadonly and newcclosure then
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method=="Raycast" or method=="FindPartOnRay") and not checkcaller() then
                if AIM.enabled and AIM.currentTarget
                    and not aimBlock(AIM.currentTarget) and aimVisible(AIM.currentTarget) then
                    local goal = aimCompute(AIM.currentTarget)
                    if goal then
                        local origin = Camera.CFrame.Position
                        return old(self, origin, goal-origin, ...)
                    end
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

local function aimCamera()
    if AIM.cfg.aimMode ~= "camera" then return end
    local t = AIM.currentTarget and AIM.targets[AIM.currentTarget]
    if not t then return end
    local goal = aimCompute(AIM.currentTarget); if not goal then return end
    local cur = Camera.CFrame
    Camera.CFrame = cur:Lerp(CFrame.lookAt(cur.Position, goal), AIM.cfg.smoothness)
end

--============================================================
-- 6. UI — DRAWING WINDOW
--============================================================
local UI = { all={}, winX=0, winY=0, scale=1, alpha=1 }
local function mk(cls, p) local d=new(cls,p); table.insert(UI.all, d); return d end

-- backdrop
local backDrop = mk("Square", {Filled=true, Color=COL.black, Transparency=1, Position=Vector2.new(0,0), Size=Vector2.new(VPS.X,VPS.Y), Visible=false})
-- window
local winBG   = mk("Square", {Filled=true, Color=COL.bg, Transparency=0.08, Visible=false})
local winBord = mk("Square", {Filled=false, Color=COL.border, Thickness=1, Transparency=0.6, Visible=false})
local headerBG= mk("Square", {Filled=true, Color=COL.panel, Transparency=0.15, Visible=false})
local sideBG  = mk("Square", {Filled=true, Color=COL.panel, Transparency=0.15, Visible=false})
local logo    = mk("Text", {Text="TWKS", Font=FONT_SEMI, Size=16, Color=COL.text, Visible=false})
local logoIcon= mk("Text", {Text="T", Font=FONT_SEMI, Size=18, Color=COL.text, Visible=false, Center=true})
local closeBtn= mk("Text", {Text="X", Font=FONT_MED, Size=15, Color=COL.textSec, Visible=false, Center=true})
local searchBg= mk("Square", {Filled=true, Color=COL.search, Transparency=0.3, Visible=false})
local searchIc= mk("Text", {Text="o", Font=FONT_SEMI, Size=12, Color=COL.textSec, Visible=false, Center=true})
local searchPl= mk("Text", {Text="Search element", Font=FONT_REG, Size=13, Color=COL.textDis, Visible=false})

-- tabs
local TABS = { {id="AIM", name="AIM"}, {id="VISUALS", name="VISUALS"}, {id="MISC", name="MISC"} }
local tabObjs = {}
for i,t in ipairs(TABS) do
    tabObjs[i] = {
        id=t.id,
        name=mk("Text", {Text=t.name, Font=FONT_MED, Size=13, Color=COL.textDis, Visible=false}),
        bar =mk("Square", {Filled=true, Color=COL.text, Transparency=1, Size=Vector2.new(3,20), Visible=false}),
    }
end

-- content area: сетка 2 колонки. Разделитель.
local divider = mk("Square", {Filled=true, Color=COL.divider, Transparency=0.5, Size=Vector2.new(1,1), Visible=false})

-- ===== UI COMPONENTS (Drawing) =====
-- Каждый компонент — контейнер объектов + биндинг к S.*
local comps = { toggles={}, sliders={}, dropdowns={}, keybinds={} }

-- Toggle
local function createToggle(parent, x, y, label, getFn, setFn)
    local t = {
        x=x, y=y, w=parent.w, h=28, label=label,
        bg  = mk("Circle", {Filled=true, Radius=10, Transparency=0.9, Visible=false}),
        knob= mk("Circle", {Filled=true, Radius=7, Transparency=1, Visible=false}),
        txt = mk("Text", {Text=label, Font=FONT_REG, Size=13, Color=COL.textSec, Visible=false}),
        val = false, anim=0,
        get = getFn, set = setFn,
    }
    t.val = getFn()
    t.anim = t.val and 1 or 0
    comps.toggles[#comps.toggles+1] = t
    return t
end

local function createSlider(parent, x, y, label, mn, mx, getFn, setFn)
    local s = {
        x=x, y=y, w=parent.w, h=36, label=label,
        min=mn, max=mx, val=getFn(),
        trackBg = mk("Square", {Filled=true, Color=COL.border, Transparency=0.5, Visible=false}),
        fill    = mk("Square", {Filled=true, Color=COL.text, Transparency=1, Visible=false}),
        knob    = mk("Circle", {Filled=true, Color=COL.text, Transparency=1, Radius=6, Visible=false}),
        txt     = mk("Text", {Text=label, Font=FONT_REG, Size=13, Color=COL.textSec, Visible=false}),
        numTxt  = mk("Text", {Text=tostring(s.val), Font=FONT_MED, Size=12, Color=COL.text, Visible=false}),
        dragging=false,
        get=getFn, set=setFn,
    }
    comps.sliders[#comps.sliders+1] = s
    return s
end

local function createDropdown(parent, x, y, label, opts, getFn, setFn)
    local d = {
        x=x, y=y, w=parent.w, h=28, label=label,
        opts=opts, open=false,
        bg  = mk("Square", {Filled=true, Color=COL.panel, Transparency=0.3, Visible=false}),
        txt = mk("Text", {Text=label..": "..getFn(), Font=FONT_REG, Size=13, Color=COL.textSec, Visible=false}),
        arrow = mk("Text", {Text="v", Font=FONT_SEMI, Size=12, Color=COL.textDis, Visible=false, Center=true}),
        list = {},
        get=getFn, set=setFn,
    }
    for i,opt in ipairs(opts) do
        d.list[i] = {
            bg = mk("Square", {Filled=true, Color=COL.panel, Transparency=0.3, Visible=false}),
            txt= mk("Text", {Text=opt, Font=FONT_REG, Size=13, Color=COL.textSec, Visible=false}),
            opt=opt,
        }
    end
    comps.dropdowns[#comps.dropdowns+1] = d
    return d
end

local function createKeybind(parent, x, y, label, getFn, setFn)
    local k = {
        x=x, y=y, w=parent.w, h=28, label=label,
        bg  = mk("Square", {Filled=true, Color=COL.panel, Transparency=0.3, Visible=false}),
        txt = mk("Text", {Text=label..": "..getFn(), Font=FONT_REG, Size=13, Color=COL.textSec, Visible=false}),
        waiting=false,
        get=getFn, set=setFn,
    }
    comps.keybinds[#comps.keybinds+1] = k
    return k
end

-- Строительство содержимого (вкладки) — очищаем прежние Drawing-компоненты (кроме тех, что живут всё время)
local function clearComps()
    for _,grp in pairs(comps) do
        for _,c in ipairs(grp) do
            for _,v in pairs(c) do
                if type(v)=="userdata" then pcall(function() v:Remove() end)
                elseif type(v)=="table" then for _,vv in pairs(v) do if type(vv)=="userdata" then pcall(function() vv:Remove() end) end end end
            end
        end
    end
    comps = { toggles={}, sliders={}, dropdowns={}, keybinds={} }
    pcall(function() divider:Remove() end)
    divider = mk("Square", {Filled=true, Color=COL.divider, Transparency=0.5, Size=Vector2.new(1,1), Visible=false})
end

-- Layout content
local function buildContent()
    clearComps()
    local wx, wy, w, h = 0, 0, WIN_W*UI.scale, WIN_H*UI.scale
    local cx = wx + (SIDEBAR_W+1)*UI.scale
    local cy = wy + (HEADER_H+1)*UI.scale
    local colW = (w - (SIDEBAR_W+1)*UI.scale) / 2 - 20*UI.scale
    local colL = cx + 20*UI.scale
    local colR = cx + colW + 40*UI.scale

    if S.activeTab == "AIM" then
        createToggle({w=colW}, colL, cy+20*UI.scale, "Enable Aim", function() return S.aim.enable end, function(v) S.aim.enable=v end)
        createKeybind({w=colW}, colL, cy+60*UI.scale, "Keybind", function() return S.aim.keybind end, function(v) S.aim.keybind=v end)
        createSlider({w=colW}, colL, cy+100*UI.scale, "FOV", 0, 360, function() return S.aim.fov end, function(v) S.aim.fov=v end)
        createSlider({w=colW}, colL, cy+150*UI.scale, "Smoothness", 0, 100, function() return S.aim.smooth*100 end, function(v) S.aim.smooth=v/100 end)
        createDropdown({w=colW}, colL, cy+200*UI.scale, "Target", {"Head","Body","Nearest"}, function() return S.aim.target end, function(v) S.aim.target=v end)
        createToggle({w=colW}, colL, cy+240*UI.scale, "Visibility Check", function() return S.aim.vischeck end, function(v) S.aim.vischeck=v end)
    elseif S.activeTab == "VISUALS" then
        createToggle({w=colW}, colL, cy+20*UI.scale, "ESP Master", function() return S.visuals.esp end, function(v) S.visuals.esp=v end)
        createToggle({w=colW}, colL, cy+60*UI.scale, "Box", function() return S.visuals.box end, function(v) S.visuals.box=v end)
        createDropdown({w=colW}, colL, cy+100*UI.scale, "Box Style", {"2D","3D","Corner"}, function() return S.visuals.boxStyle end, function(v) S.visuals.boxStyle=v end)
        createToggle({w=colW}, colL, cy+140*UI.scale, "Skeleton", function() return S.visuals.skeleton end, function(v) S.visuals.skeleton=v end)
        createToggle({w=colL}, colR, cy+20*UI.scale, "Health Bar", function() return S.visuals.health end, function(v) S.visuals.health=v end)
        createDropdown({w=colW}, colR, cy+60*UI.scale, "Health Pos", {"Top","Bottom","Left"}, function() return S.visuals.healthPos end, function(v) S.visuals.healthPos=v end)
        createToggle({w=colW}, colR, cy+100*UI.scale, "Name Tags", function() return S.visuals.nameTags end, function(v) S.visuals.nameTags=v end)
        createToggle({w=colW}, colR, cy+140*UI.scale, "Distance", function() return S.visuals.distance end, function(v) S.visuals.distance=v end)
        createSlider({w=colW}, colR, cy+180*UI.scale, "Max Distance", 0, 1000, function() return S.visuals.maxDist end, function(v) S.visuals.maxDist=v end)
        createToggle({w=colW}, colR, cy+230*UI.scale, "Tracer", function() return S.visuals.tracer end, function(v) S.visuals.tracer=v end)
        createToggle({w=colW}, colR, cy+270*UI.scale, "Chams", function() return S.visuals.chams end, function(v) S.visuals.chams=v end)
        createDropdown({w=colW}, colR, cy+310*UI.scale, "Chams Mode", {"Drawing","Highlight"}, function() return S.visuals.chamsMode end, function(v) S.visuals.chamsMode=v end)
    elseif S.activeTab == "MISC" then
        createToggle({w=colW}, colL, cy+20*UI.scale, "FOV Changer", function() return S.misc.fovChg end, function(v) S.misc.fovChg=v end)
        createSlider({w=colW}, colL, cy+60*UI.scale, "FOV Value", 70, 120, function() return S.misc.fovVal end, function(v) S.misc.fovVal=v end)
        createToggle({w=colW}, colL, cy+110*UI.scale, "Third Person", function() return S.misc.third end, function(v) S.misc.third=v end)
        createToggle({w=colW}, colL, cy+150*UI.scale, "FPS Unlocker", function() return S.misc.fps end, function(v) S.misc.fps=v end)
        createToggle({w=colR}, colR, cy+20*UI.scale, "Walk Speed", function() return S.misc.speed end, function(v) S.misc.speed=v end)
        createSlider({w=colW}, colR, cy+60*UI.scale, "Speed Value", 16, 50, function() return S.misc.speedVal end, function(v) S.misc.speedVal=v end)
        createToggle({w=colW}, colR, cy+110*UI.scale, "Jump Power", function() return S.misc.jump end, function(v) S.misc.jump=v end)
        createSlider({w=colW}, colR, cy+150*UI.scale, "Jump Value", 50, 100, function() return S.misc.jumpVal end, function(v) S.misc.jumpVal=v end)
        createToggle({w=colW}, colL, cy+200*UI.scale, "Anti-AFK", function() return S.misc.antiafk end, function(v) S.misc.antiafk=v end)
    end

    divider.Position = Vector2.new(cx + (w - (SIDEBAR_W+1)*UI.scale)/2, cy + 10*UI.scale)
    divider.Size = Vector2.new(1, h - cy - 20*UI.scale)
end

-- Update drawing widgets
local function updateComps(dt)
    local wx, wy, w, h = UI.winX, UI.winY, WIN_W*UI.scale, WIN_H*UI.scale
    -- divider
    divider.Visible = UI.alpha > 0.01
    divider.Transparency = UI.alpha * 0.5

    -- toggles
    for _,t in ipairs(comps.toggles) do
        t.val = t.get() and true or false
        t.anim = lerp(t.anim, t.val and 1 or 0, clamp(dt*10,0,1))
        local x, y = wx + t.x, wy + t.y
        t.txt.Position = Vector2.new(x, y+4*UI.scale)
        t.txt.Visible = UI.alpha > 0.01
        t.txt.Transparency = UI.alpha
        t.bg.Position = Vector2.new(x+t.w-46*UI.scale, y+6*UI.scale)
        t.bg.Radius = 10*UI.scale
        t.bg.Color = t.anim>0.5 and COL.text or COL.border
        t.bg.Transparency = UI.alpha*(t.anim>0.5 and 1 or 0.6)
        t.bg.Visible = UI.alpha > 0.01
        t.knob.Position = Vector2.new(x+t.w-46*UI.scale + 4*UI.scale + t.anim*12*UI.scale, y+16*UI.scale)
        t.knob.Radius = 7*UI.scale
        t.knob.Color = t.anim>0.5 and COL.black or COL.textDis
        t.knob.Transparency = UI.alpha
        t.knob.Visible = UI.alpha > 0.01
    end
    -- sliders
    for _,s in ipairs(comps.sliders) do
        local x, y = wx + s.x, wy + s.y
        local trackW = s.w - 100*UI.scale
        s.txt.Position = Vector2.new(x, y)
        s.txt.Visible = UI.alpha > 0.01; s.txt.Transparency = UI.alpha
        s.numTxt.Position = Vector2.new(x+trackW+8*UI.scale, y)
        s.numTxt.Text = string.format("%.2f", s.val)
        s.numTxt.Visible = UI.alpha > 0.01; s.numTxt.Transparency = UI.alpha
        local frac = (s.val-s.min)/math.max(s.max-s.min,0.0001)
        s.trackBg.Position = Vector2.new(x, y+22*UI.scale)
        s.trackBg.Size = Vector2.new(trackW, 4*UI.scale)
        s.trackBg.Visible = UI.alpha > 0.01; s.trackBg.Transparency = UI.alpha*0.5
        s.fill.Position = Vector2.new(x, y+22*UI.scale)
        s.fill.Size = Vector2.new(trackW*frac, 4*UI.scale)
        s.fill.Visible = UI.alpha > 0.01; s.fill.Transparency = UI.alpha
        s.knob.Position = Vector2.new(x + trackW*frac, y+24*UI.scale)
        s.knob.Radius = 6*UI.scale
        s.knob.Visible = UI.alpha > 0.01; s.knob.Transparency = UI.alpha
    end
    -- dropdowns
    for _,d in ipairs(comps.dropdowns) do
        local x, y = wx + d.x, wy + d.y
        d.bg.Position = Vector2.new(x, y+16*UI.scale)
        d.bg.Size = Vector2.new(d.w, 24*UI.scale)
        d.bg.Visible = UI.alpha > 0.01; d.bg.Transparency = UI.alpha*0.3
        d.txt.Position = Vector2.new(x+8*UI.scale, y+19*UI.scale)
        d.txt.Text = d.label..": "..d.get()
        d.txt.Visible = UI.alpha > 0.01; d.txt.Transparency = UI.alpha
        d.arrow.Position = Vector2.new(x+d.w-12*UI.scale, y+22*UI.scale)
        d.arrow.Visible = UI.alpha > 0.01; d.arrow.Transparency = UI.alpha
        for i,item in ipairs(d.list) do
            item.bg.Position = Vector2.new(x, y+42*UI.scale + (i-1)*22*UI.scale)
            item.bg.Size = Vector2.new(d.w, 22*UI.scale)
            item.bg.Visible = d.open and UI.alpha>0.01 or false
            item.bg.Transparency = UI.alpha*0.3
            item.txt.Position = Vector2.new(x+8*UI.scale, y+44*UI.scale + (i-1)*22*UI.scale)
            item.txt.Visible = d.open and UI.alpha>0.01 or false
            item.txt.Transparency = UI.alpha
        end
    end
    -- keybinds
    for _,k in ipairs(comps.keybinds) do
        local x, y = wx + k.x, wy + k.y
        k.bg.Position = Vector2.new(x, y+16*UI.scale)
        k.bg.Size = Vector2.new(k.w, 24*UI.scale)
        k.bg.Visible = UI.alpha>0.01; k.bg.Transparency = UI.alpha*0.3
        k.txt.Position = Vector2.new(x+8*UI.scale, y+19*UI.scale)
        k.txt.Text = k.waiting and (k.label..": ...") or (k.label..": "..k.get())
        k.txt.Visible = UI.alpha>0.01; k.txt.Transparency = UI.alpha
    end
end

-- Layout / apply window
local function applyWindow()
    local scale = UI.scale
    local alpha = UI.alpha
    local w = WIN_W*scale
    local h = WIN_H*scale
    -- position: если сохранено — использовать; иначе центр
    local wx = S.winPos.X ~= 0 and S.winPos.X or (VPS.X/2 - w/2)
    local wy = S.winPos.Y ~= 0 and S.winPos.Y or (VPS.Y/2 - h/2)
    UI.winX, UI.winY = wx, wy

    backDrop.Transparency = 1 - (1-0.4)*alpha
    backDrop.Visible = alpha > 0.01

    winBG.Position = Vector2.new(wx, wy); winBG.Size = Vector2.new(w, h)
    winBG.Transparency = 0.08 + (1-0.08)*(1-alpha); winBG.Visible = alpha>0.01
    winBord.Position = Vector2.new(wx, wy); winBord.Size = Vector2.new(w, h)
    winBord.Transparency = 0.6 + (1-0.6)*(1-alpha); winBord.Visible = alpha>0.01
    headerBG.Position = Vector2.new(wx, wy); headerBG.Size = Vector2.new(w, HEADER_H*scale)
    headerBG.Transparency = 0.15 + (1-0.15)*(1-alpha); headerBG.Visible = alpha>0.01
    sideBG.Position = Vector2.new(wx, wy+HEADER_H*scale); sideBG.Size = Vector2.new(SIDEBAR_W*scale, h-HEADER_H*scale)
    sideBG.Transparency = 0.15 + (1-0.15)*(1-alpha); sideBG.Visible = alpha>0.01

    logo.Position = Vector2.new(wx + 42*scale, wy + 20*scale)
    logo.Transparency = alpha; logo.Visible = alpha>0.01
    logoIcon.Position = Vector2.new(wx + 24*scale, wy + 20*scale)
    logoIcon.Transparency = alpha; logoIcon.Visible = alpha>0.01

    closeBtn.Position = Vector2.new(wx + w - 24*scale, wy + 20*scale)
    closeBtn.Transparency = alpha; closeBtn.Visible = alpha>0.01

    local sw = 300*scale
    searchBg.Position = Vector2.new(wx + (w-sw)/2, wy + 14*scale)
    searchBg.Size = Vector2.new(sw, 28*scale)
    searchBg.Transparency = 0.3 + (1-0.3)*(1-alpha); searchBg.Visible = alpha>0.01
    searchIc.Position = Vector2.new(wx + (w-sw)/2 + 14*scale, wy + 22*scale)
    searchIc.Transparency = alpha; searchIc.Visible = alpha>0.01
    searchPl.Position = Vector2.new(wx + (w-sw)/2 + 30*scale, wy + 20*scale)
    searchPl.Transparency = alpha; searchPl.Visible = alpha>0.01

    -- tabs
    for i,t in ipairs(tabObjs) do
        local ty = wy + HEADER_H*scale + 20*scale + (i-1)*40*scale
        t.name.Position = Vector2.new(wx + 30*scale, ty + 2*scale)
        local active = (S.activeTab == t.id)
        t.name.Color = active and COL.text or COL.textDis
        t.name.Transparency = alpha; t.name.Visible = alpha>0.01
        t.bar.Position = Vector2.new(wx + 16*scale, ty + 2*scale)
        t.bar.Visible = active and alpha>0.01 or false
        t.bar.Transparency = alpha
    end

    updateComps(1/60)
end

-- build content once + on tab change
buildContent()

--==== FAB ====
local FAB = {
    bg   = new("Circle", {Filled=true, Color=COL.panel, Transparency=0.05, Radius=24, Visible=false}),
    bord = new("Circle", {Filled=false, Color=COL.border, Thickness=1, Transparency=0.5, Radius=24, Visible=false}),
    icon = new("Text", {Text="T", Font=FONT_SEMI, Size=18, Color=COL.text, Center=true, Visible=false}),
    pos = S.fabPos.X ~= 0 and S.fabPos or Vector2.new(VPS.X - 72, VPS.Y - 72),
    side = S.fabSide, scale=0, visible=false,
    dragging=false, dragOff=Vector2.new(0,0), hover=false,
}
local function updateFab()
    local r = 24 * FAB.scale
    FAB.bg.Position = FAB.pos; FAB.bg.Radius = math.max(r,0.1)
    FAB.bg.Color = FAB.hover and COL.hover or COL.panel
    FAB.bg.Visible = FAB.scale > 0.01
    FAB.bg.Transparency = 0.05
    FAB.bord.Position = FAB.pos; FAB.bord.Radius = math.max(r,0.1)
    FAB.bord.Color = FAB.hover and COL.text or COL.border
    FAB.bord.Visible = FAB.scale > 0.01
    FAB.icon.Position = Vector2.new(FAB.pos.X, FAB.pos.Y - 9)
    FAB.icon.Visible = FAB.scale > 0.3
end
local function fabShow()
    if FAB.visible then return end
    FAB.visible = true
    anim(FAB, "scale", 1, 0.25, "BackOut")
end
local function fabHide()
    if not FAB.visible then return end
    FAB.visible = false
    anim(FAB, "scale", 0, 0.15, "QuadIn")
end

--==== OPEN / CLOSE ====
local function openMenu()
    if S.open or S.animating then return end
    S.open = true
    S.animating = true
    UI.scale = 0.85
    UI.alpha = 0
    applyWindow()
    -- показать всё
    for _,d in ipairs(UI.all) do pcall(function() d.Visible = true end) end
    for _,grp in pairs(comps) do for _,c in ipairs(grp) do
        for _,v in pairs(c) do if type(v)=="userdata" then pcall(function() v.Visible=true end) end end
    end end
    FAB.hover = false
    fabHide()
    -- анимация
    task.spawn(function()
        local t0 = tick()
        while tick()-t0 < 0.35 do
            local t = (tick()-t0)/0.35
            local e = ease("ExpoOut", t)
            UI.scale = lerp(0.85, 1.0, e)
            UI.alpha = e
            applyWindow()
            task.wait()
        end
        UI.scale = 1.0; UI.alpha = 1
        applyWindow()
        S.animating = false
    end)
end
local function closeMenu()
    if not S.open or S.animating then return end
    S.open = false
    S.animating = true
    task.spawn(function()
        local t0 = tick()
        while tick()-t0 < 0.25 do
            local t = (tick()-t0)/0.25
            local e = ease("QuadIn", t)
            UI.scale = lerp(1.0, 0.85, e)
            UI.alpha = lerp(1.0, 0, e)
            applyWindow()
            task.wait()
        end
        UI.alpha = 0
        for _,d in ipairs(UI.all) do pcall(function() d.Visible=false end) end
        for _,grp in pairs(comps) do for _,c in ipairs(grp) do
            for _,v in pairs(c) do if type(v)=="userdata" then pcall(function() v.Visible=false end) end end
        end end
        -- снять фокус
        task.wait(0.15)
        fabShow()
        S.animating = false
        saveCfg()
    end)
end

--==== INPUT ====
local mousePos = Vector2.new(0,0)
UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        mousePos = Vector2.new(input.Position.X, input.Position.Y)
        FAB.hover = (mousePos-FAB.pos).Magnitude < 26*FAB.scale + 4
        updateFab()
    end
end)

-- Sliders drag
local activeSlider = nil
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    local mb = input.UserInputType == Enum.UserInputType.MouseButton1
    local tb = input.UserInputType == Enum.UserInputType.Touch
    if not (mb or tb) then
        -- keybind захват
        for _,k in ipairs(comps.keybinds) do
            if k.waiting then
                if input.KeyCode == Enum.KeyCode.Escape then
                    k.waiting = false
                else
                    k.set(input.KeyCode.Name); k.waiting = false
                end
                return
            end
        end
        return
    end
    local p = Vector2.new(input.Position.X, input.Position.Y)
    -- FAB
    if not S.open and FAB.visible and FAB.scale>0.5 and (p-FAB.pos).Magnitude<=26*FAB.scale then
        FAB.dragging = true; FAB.dragOff = p - FAB.pos; FAB.dragStart = p
        return
    end
    if not S.open or S.animating then return end
    -- close
    if pointInRect(p, UI.winX + WIN_W*UI.scale - 40*UI.scale, UI.winY + 8*UI.scale, 32*UI.scale, 32*UI.scale) then
        closeMenu(); return
    end
    -- tabs
    for i,t in ipairs(tabObjs) do
        local ty = UI.winY + HEADER_H*UI.scale + 20*UI.scale + (i-1)*40*UI.scale
        if p.X >= UI.winX and p.X <= UI.winX + SIDEBAR_W*UI.scale and p.Y >= ty-4 and p.Y <= ty+28*UI.scale then
            if S.activeTab ~= t.id then
                S.activeTab = t.id
                buildContent()
                applyWindow()
                saveCfg()
            end
            return
        end
    end
    -- toggles
    for _,t in ipairs(comps.toggles) do
        local bx = UI.winX + t.x + t.w - 46*UI.scale
        local by = UI.winY + t.y + 6*UI.scale
        if pointInRect(p, bx, by, 36*UI.scale, 20*UI.scale) then
            t.set(not t.get()); return
        end
    end
    -- sliders
    for _,s in ipairs(comps.sliders) do
        local x = UI.winX + s.x
        local y = UI.winY + s.y + 22*UI.scale
        local trackW = s.w - 100*UI.scale
        if p.Y >= y-8*UI.scale and p.Y <= y+10*UI.scale
            and p.X >= x-4*UI.scale and p.X <= x+trackW+4*UI.scale then
            local frac = clamp((p.X - x)/trackW, 0, 1)
            s.set(s.min + (s.max-s.min)*frac)
            activeSlider = s
            return
        end
    end
    -- dropdowns
    for _,d in ipairs(comps.dropdowns) do
        local x = UI.winX + d.x
        local y = UI.winY + d.y
        if pointInRect(p, x, y+16*UI.scale, d.w, 24*UI.scale) then
            d.open = not d.open; return
        end
        if d.open then
            for i,item in ipairs(d.list) do
                local iy = y+42*UI.scale + (i-1)*22*UI.scale
                if pointInRect(p, x, iy, d.w, 22*UI.scale) then
                    d.set(item.opt); d.open = false; return
                end
            end
            d.open = false
        end
    end
    -- keybinds
    for _,k in ipairs(comps.keybinds) do
        local x = UI.winX + k.x
        local y = UI.winY + k.y
        if pointInRect(p, x, y+16*UI.scale, k.w, 24*UI.scale) then
            k.waiting = true
            return
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if FAB.dragging then
            FAB.dragging = false
            local side = FAB.pos.X < VPS.X/2 and "left" or "right"
            local goal = Vector2.new(side=="left" and 72 or VPS.X-72, FAB.pos.Y)
            task.spawn(function()
                local t0 = tick()
                local from = FAB.pos
                while tick()-t0 < 0.2 do
                    local a = (tick()-t0)/0.2
                    FAB.pos = lerpV(from, goal, ease("QuadOut", a))
                    updateFab(); task.wait()
                end
                FAB.pos = goal; FAB.side = side
                S.fabPos = FAB.pos; S.fabSide = side
                saveCfg()
            end)
        end
        activeSlider = nil
    end
end)

UIS.InputChanged:Connect(function(input)
    if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local p = Vector2.new(input.Position.X, input.Position.Y)
        local x = UI.winX + activeSlider.x
        local trackW = activeSlider.w - 100*UI.scale
        local frac = clamp((p.X - x)/trackW, 0, 1)
        activeSlider.set(activeSlider.min + (activeSlider.max-activeSlider.min)*frac)
    elseif FAB.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local p = Vector2.new(input.Position.X, input.Position.Y)
        FAB.pos = Vector2.new(
            clamp(p.X - FAB.dragOff.X, 32, VPS.X-32),
            clamp(p.Y - FAB.dragOff.Y, 32, VPS.Y-32))
        updateFab()
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if S.open then closeMenu() else openMenu() end
    elseif input.KeyCode == Enum.KeyCode.Escape then
        if S.open then closeMenu() end
    end
end)

--==== MAIN LOOP ====
RunService.RenderStepped:Connect(function(dt)
    -- ESP
    ESP.enabled = S.visuals.esp
    if ESP.enabled then
        for plr,_ in pairs(ESP.players) do updateESP(plr, dt, 60) end
    else
        for _,D in pairs(ESP.players) do
            for _,k in ipairs({"boxOuter","boxInner","tracer","name","dist"}) do D[k].Visible=false end
            for _,l in ipairs(D.skel) do l.Visible=false end
        end
    end
    -- AIM
    AIM.enabled = S.aim.enable
    AIM.cfg.fovRadius = S.aim.fov
    AIM.cfg.hitPart   = S.aim.target
    AIM.cfg.aimMode   = S.aim.mode
    AIM.cfg.smoothness= S.aim.smooth
    AIM.currentTarget = aimSelect()
    aimCamera()
    -- FAB visuals
    updateFab()
    -- UI comps
    if S.open and not S.animating then updateComps(dt) end
    -- misc (визуальные только)
    if S.misc.fovChg and Camera then Camera.FieldOfView = S.misc.fovVal end
end)

--==== BOOT ====
task.wait(0.1)
buildContent()
applyWindow()
task.wait(0.05)
fabShow()

-- cleanup
game:BindToClose(function()
    saveCfg()
    for plr,_ in pairs(ESP.players) do destroyESP(plr) end
    for _,d in ipairs(UI.all) do safe(function() d:Remove() end) end
    for _,d in ipairs({FAB.bg,FAB.bord,FAB.icon}) do safe(function() d:Remove() end) end
end)