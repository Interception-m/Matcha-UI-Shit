local ok, Library = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Interception-m/Matcha-UI-Shit/refs/heads/main/gamesense_lib.lua"))()
    return _G.Library
end)
if not ok or type(Library) ~= "table" then
    warn("gamesense_lib.lua failed to load: " .. tostring(Library))
    return
end

local function Unpack(Value)
    local R = Value % 256
    local G = math.floor(Value / 256) % 256
    local B = math.floor(Value / 65536) % 256
    local A = math.floor(Value / 16777216) % 256
    return Color3.fromRGB(R, G, B), 1 - A / 255
end

local function Box(Tab, Name, Column, ColumnSpan, Row, RowSpan, Fixed)
    return Tab:Section({
        Name = Name,
        Grid = { Column, ColumnSpan, Row, RowSpan },
        Movable = not Fixed,
        Resizable = not Fixed,
    })
end

Library.ConfigFolder = "gamesense/Aegis"
pcall(function()
    if not isfolder(Library.ConfigFolder) then makefolder(Library.ConfigFolder) end
end)

Library.UI.Name = "gamesneeze"
Library.UI.NameSplit = 4
Library.UI.WatermarkClock = false
local Window = Library:Window({ CloseBind = Enum.KeyCode.Insert })
local Visuals = Window:CreateTab({ Icon = "visuals", Name = "VISUALS" })
local Misc = Window:CreateTab({ Icon = "misc", Name = "SETTINGS" })
local Shared = {}

Window:SetTab(1)

local ALWAYS = "Always on"
local Cfg = { team = false, health = false, skeleton = false }

do
    local Section = Box(Visuals, "Player ESP", 0, 12, 0, 24)
    local Other = Box(Visuals, "Other ESP", 12, 12, 0, 24)
    do
        local Color, Alpha = Unpack(0xC8FFFFFF)
        Cfg.gun, Cfg.gun_text, Cfg.gun_distance = false, false, false
        Cfg.gun_color, Cfg.gun_alpha = Color, 1 - Alpha
        local Guns = Other:MultiBox({
            Name = "Dropped weapons", Flag = "esp_dropped_weapons", Content = { "Text", "Distance" },
            Callback = function(List)
                if type(List) ~= "table" then List = {} end
                local Text, Distance = false, false
                for _, Value in ipairs(List) do
                    if Value == "Text" then Text = true elseif Value == "Distance" then Distance = true end
                end
                Cfg.gun_text, Cfg.gun_distance = Text, Distance
                Cfg.gun = Text or Distance
            end,
        })
        Guns:ColorPicker({ Flag = "esp_dropped_weapon_color", Default = Color, Alpha = Alpha, ShowAlpha = true, Callback = function(Picked, Transparency)
            if Picked then Cfg.gun_color = Picked end
            Cfg.gun_alpha = 1 - (tonumber(Transparency) or 0)
        end })
        Cfg.ammo, Cfg.ammo_text, Cfg.ammo_distance = false, false, false
        Cfg.ammo_color, Cfg.ammo_alpha = Color, 1 - Alpha
        local Drops = Other:MultiBox({
            Name = "Ammo drops", Flag = "esp_ammo_drops", Content = { "Text", "Distance" },
            Callback = function(List)
                if type(List) ~= "table" then List = {} end
                local Text, Distance = false, false
                for _, Value in ipairs(List) do
                    if Value == "Text" then Text = true elseif Value == "Distance" then Distance = true end
                end
                Cfg.ammo_text, Cfg.ammo_distance = Text, Distance
                Cfg.ammo = Text or Distance
            end,
        })
        Drops:ColorPicker({ Flag = "esp_ammo_drop_color", Default = Color, Alpha = Alpha, ShowAlpha = true, Callback = function(Picked, Transparency)
            if Picked then Cfg.ammo_color = Picked end
            Cfg.ammo_alpha = 1 - (tonumber(Transparency) or 0)
        end })
        Cfg.nade, Cfg.nade_text, Cfg.nade_distance = false, false, false
        Other:MultiBox({
            Name = "Grenade warnings", Flag = "esp_grenade_warnings", Content = { "Text", "Distance" },
            Callback = function(List)
                if type(List) ~= "table" then List = {} end
                local Text, Distance = false, false
                for _, Value in ipairs(List) do
                    if Value == "Text" then Text = true elseif Value == "Distance" then Distance = true end
                end
                Cfg.nade_text, Cfg.nade_distance = Text, Distance
                Cfg.nade = Text or Distance
            end,
        })
    end

    local function Check(Name, Flag, Field, ColorFlag, Value)
        Cfg[Field] = false
        local Toggle = Section:Toggle({ Name = Name, Flag = Flag, Callback = function(State)
            Cfg[Field] = State == true
        end })
        if ColorFlag then
            local Color, Alpha = Unpack(Value)
            Cfg[Field .. "_color"] = Color
            Cfg[Field .. "_alpha"] = 1 - Alpha
            Toggle:ColorPicker({ Flag = ColorFlag, Default = Color, Alpha = Alpha, ShowAlpha = true, Callback = function(Picked, Transparency)
                if Picked then Cfg[Field .. "_color"] = Picked end
                Cfg[Field .. "_alpha"] = 1 - (tonumber(Transparency) or 0)
            end })
        end
        return Toggle
    end

    Shared.Key = Section:Label({ Message = "Activation type" }):Keybind({ Flag = "esp_activation", Mode = ALWAYS, Default = "LeftShift" })
    Check("Teammates", "esp_teammates", "team")
    Cfg.box_corners = false
    Check("Bounding box", "esp_bounding_box", "box", "esp_box_color", 0x82FFFFFF):Tie(
        Section:Dropdown({
            Name = "", Flag = "esp_box_style", Content = { "Full", "Corners" }, Default = "Full",
            Callback = function(Value)
                Cfg.box_corners = Value == "Corners"
            end,
        })
    )
    Check("Health bar", "esp_health_bar", "health", "esp_health_color", 0xFF50E178)
    Check("Name", "esp_name", "name", "esp_name_color", 0xC8FFFFFF)
    Check("Flags", "esp_flags", "flags")
    Check("Weapon text", "esp_weapon_text", "weapon")
    Check("Distance", "esp_distance", "distance")
    Check("Skeleton", "esp_skeleton", "skeleton", "esp_skeleton_color", 0xFFAAFFFF)
end

do
    local Settings = Box(Misc, "Settings", 12, 12, 0, 24)

    local function Local(Control)
        Control.NoConfig = true
        return Control
    end
    Local(Settings:Label({ Message = "Menu key" }):Keybind({
        Flag = "settings_menu_key", Default = 0x2D, UseMode = false,
        Callback = function(Value) Library.UI.CloseBind = Value end,
    }))
    Local(Settings:Label({ Message = "Menu color" }):ColorPicker({
        Flag = "settings_menu_color", Default = Library.Theme.Default.Accent,
        Callback = function(Color) Library:UpdateColor("Accent", Color) end,
    }))
    Settings:Toggle({ Name = "Watermark", Flag = "settings_watermark", Default = true, Callback = function(State)
        Library:ToggleWatermark(State)
    end })
    local Lock = { Ready = false }
    Lock.Toggle = Local(Settings:Toggle({ Name = "Lock menu layout", Flag = "settings_lock_layout", Default = true, Callback = function()
        if Lock.Ready then Library:SetLayoutLocked(Lock.Toggle:Get()) end
    end }))
    Lock.Ready = true
    Library:SetLayoutLocked(true)
    Settings:Button({ Name = "Reset menu layout", Callback = function() Library:ResetLayout() end })
end

do
    local Presets = Box(Misc, "Presets", 0, 12, 0, 24)

    local Store, Baseline = {}, nil
    local List, Name
    local function Typed()
        local Text = Name:Get()
        if type(Text) ~= "string" or Text == "" or #Text >= 64 then return nil end
        return Text
    end
    local function Mark(Active)
        List:SetMarked(nil)
        if Active then List:SetMarked(Active, true) end
    end
    local function Read(Preset)
        if Store[Preset] then return Store[Preset] end
        local Path = Library:ConfigPath(Preset)
        local Found, Data = pcall(function()
            if isfile(Path) then return readfile(Path) end
            return nil
        end)
        if Found and type(Data) == "string" and Data ~= "" then return Data end
        return nil
    end

    List = Presets:List({
        Flag = "config_presets", Size = 126, Bound = false,
        Callback = function(Selected)
            if Name and type(Selected) == "string" and #Selected <= 63 then Name:Set(Selected) end
        end,
    })
    List.NoConfig = true
    Name = Presets:TextBox({ Flag = "config_name" })
    Name.NoConfig = true
    Presets:Button({ Name = "Load", Callback = function()
        local Preset = Typed()
        local Data = Preset and Read(Preset)
        if not Data then return end
        if Library:LoadConfig(Data) then Mark(Preset) end
    end })
    Presets:Button({ Name = "Save", Callback = function()
        local Preset = Typed()
        if not Preset then return end
        local Data = Library:GetConfig(true)
        Store[Preset] = Data
        pcall(writefile, Library:ConfigPath(Preset), Data)
        if not List:Find(Preset) then List:AddValue(Preset) end
        List:Select(Preset)
        Mark(Preset)
    end })
    Presets:Button({ Name = "Delete", Callback = function()
        local Preset = Name:Get()
        if type(Preset) ~= "string" or Preset == "" then return end
        Store[Preset] = nil
        pcall(delfile, Library:ConfigPath(Preset))
        List:RemoveValue(Preset)
    end })
    Presets:Button({ Name = "Reset", Callback = function()
        if Baseline then Library:LoadConfig(Baseline) end
        Mark(nil)
    end })
    for _, Preset in ipairs(Library:ListConfigs()) do List:AddValue(Preset) end
    function Shared.Baseline()
        Baseline = Library:GetConfig(true)
    end
end

Shared.Baseline()
Library:Init()

do
    local mr, up, clock, floor, match = memory_read, string.unpack, os.clock, math.floor, string.match
    local W2S, V3 = WorldToScreen, Vector3.new
    local LP = game:GetService("Players").LocalPlayer
    local MY = LP.UserId
    local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
    local GOLD, GREY = Color3.fromRGB(255, 220, 80), Color3.fromRGB(200, 200, 200)
    local FONT = (Drawing.Fonts and Drawing.Fonts.UI) or 0
    local BONES = {
        "gf2_Head_M", "gf2_Neck_M", "gf2_Chest_M", "gf2_Root_M",
        "gf2_Shoulder_L", "gf2_Elbow_L", "gf2_Wrist_L",
        "gf2_Shoulder_R", "gf2_Elbow_R", "gf2_Wrist_R",
        "gf2_Hip_L", "gf2_Knee_L", "gf2_Ankle_L", "gf2_Toes_L",
        "gf2_Hip_R", "gf2_Knee_R", "gf2_Ankle_R", "gf2_Toes_R",
    }
    local LINKS = {
        { 1, 2 }, { 2, 3 }, { 3, 4 },
        { 2, 5 }, { 5, 6 }, { 6, 7 },
        { 2, 8 }, { 8, 9 }, { 9, 10 },
        { 4, 11 }, { 11, 12 }, { 12, 13 }, { 13, 14 },
        { 4, 15 }, { 15, 16 }, { 16, 17 }, { 17, 18 },
    }
    local NB, NL = #BONES, #LINKS
    local GATE, POSE = 1 / 240, 1 / 60
    local INDEX = {}
    for i = 1, NB do INDEX[BONES[i]] = i end

    local E = { alive = true, ready = false, failed = false, ents = {}, models = {}, hp = {}, team = {}, names = {}, inv = {}, stores = {} }
    local Off = {}
    local Str = {}
    local SX, SY, OK = {}, {}, {}
    local P = { x = 0, y = 0 }
    local Timer = { init = -100, tries = 0, ents = 0, team = 0, scan = 0, strings = 0, warn = 0 }

    local function report(text)
        local now = clock()
        if now - Timer.warn < 10 then return end
        Timer.warn = now
        warn("Aegis ESP: " .. tostring(text))
    end

    local function tell(text)
        warn("Aegis: " .. text)
        pcall(function() Library:Notify({ Message = text, Delay = 8 }) end)
    end

    local function str(ts)
        local s = Str[ts]
        if s ~= nil then return s end
        s = false
        local len = mr("int", ts + 0x14)
        if type(len) == "number" and len > 0 and len <= 48 then
            local b = mr("buffer", ts + 0x18, len)
            if type(b) == "string" and #b == len then s = b end
        end
        Str[ts] = s
        return s
    end

    local function each(tbl, fn, ctx)
        local lsz = mr("byte", tbl + 4)
        if type(lsz) ~= "number" or lsz > 9 then return false end
        local node = mr("uintptr", tbl + 0x28)
        if type(node) ~= "number" or node < 65536 then return false end
        local count = 2 ^ lsz
        local buf = mr("buffer", node, count * 32)
        if type(buf) ~= "string" or #buf < count * 32 then return false end
        for i = 0, count - 1 do
            local o = i * 32 + 1
            local vlo, vhi, _, vtt, klo, khi, _, kx = up("<I4I4I4I4I4I4I4I4", buf, o)
            local ktt = kx % 16
            if ktt ~= 0 and vtt ~= 0 then
                fn(ctx, buf, o, vtt, vhi * 4294967296 + vlo, ktt, khi * 4294967296 + klo, node + i * 32)
            end
        end
        return true
    end

    local function onUser(ctx, buf, o, vtt, v, ktt)
        if ktt == 3 and vtt == 6 then ctx[up("<d", buf, o + 16)] = v end
    end

    local function onAny(ctx, buf, o, vtt, v)
        if vtt == 6 then ctx[#ctx + 1] = v end
    end

    local function onThrow(t, buf, o, vtt, v, ktt, k)
        if ktt ~= 5 then return end
        local name = str(k)
        if name == "kind" then
            if vtt == 5 then t.kind = str(v) end
        elseif name == "itemId" then
            if vtt == 3 then t.item = up("<d", buf, o) end
        elseif name == "time" then
            if vtt == 3 then t.time = up("<d", buf, o) end
        elseif name == "deadline" then
            if vtt == 3 then t.deadline = up("<d", buf, o) end
        elseif name == "start" then
            if vtt == 3 then t.start = up("<d", buf, o) end
        elseif name == "id" then
            t.id = vtt .. ":" .. v
        end
    end

    local function onWorld(ctx, buf, o, vtt, v, ktt, k)
        if ktt == 5 and vtt == 6 and str(k) == "entries" then ctx.entries = v end
    end

    local function onRecord(ent, buf, o, vtt, v, ktt, k, node)
        if ktt ~= 5 then return end
        local name = str(k)
        if name == "characterModel" then
            if vtt == 6 then ent.cm = v end
        elseif name == "position" then
            if vtt == 4 then ent.posAddr = node end
        end
    end

    local function onModel(ent, buf, o, vtt, v, ktt, k)
        if ktt ~= 5 then return end
        local name = str(k)
        if name == "model" then
            if vtt == 8 then ent.ud = v end
        elseif name == "ragdollLatched" then
            ent.rag = vtt == 1 and v % 256 ~= 0
        elseif name == "origBodyPlayer" then
            if vtt == 6 then ent.body = v end
        elseif name == "remoteWeaponModel" then
            if vtt == 8 then ent.gun = v end
        end
    end

    local function onBody(ent, buf, o, vtt, v, ktt, k)
        if ktt == 5 and vtt == 5 and str(k) == "weaponKey" then ent.weapon = str(v) or nil end
    end

    local function onLife(h, buf, o, vtt, v, ktt, k)
        if ktt ~= 5 then return end
        local name = str(k)
        if name == "hitPoints" then
            if vtt == 3 then h.hp = up("<d", buf, o) end
        elseif name == "maxHitPoints" then
            if vtt == 3 then h.max = up("<d", buf, o) end
        elseif name == "phase" then
            if vtt == 5 then h.phase = str(v) end
        end
    end

    local function onGhost(ent, buf, o, vtt, v, ktt, k)
        if ktt == 5 and vtt == 4 and str(k) == "pos" then ent.gx, ent.gy, ent.gz = up("<fff", buf, o) end
    end

    local function latest()
        local tbl = E.snaps
        if not tbl then return nil end
        local cap = mr("int", tbl + 8)
        local arr = mr("uintptr", tbl + 0x20)
        if type(cap) ~= "number" or cap < 1 or cap > 1024 or type(arr) ~= "number" or arr < 65536 then return nil end
        local buf = mr("buffer", arr, cap * 16)
        if type(buf) ~= "string" or #buf < cap * 16 then return nil end
        for i = cap - 1, 0, -1 do
            local lo, hi, _, tt = up("<I4I4I4I4", buf, i * 16 + 1)
            if tt == 6 then return hi * 4294967296 + lo end
        end
        return nil
    end

    local function onSnap(ctx, buf, o, vtt, v, ktt, k)
        if ktt ~= 5 then return end
        local name = str(k)
        if name == "charData" then
            if vtt == 6 then ctx.data = v end
        elseif name == "serverTime" then
            if vtt == 3 then ctx.time = up("<d", buf, o) end
        end
    end

    local function onTeam(ctx, buf, o, vtt, v, ktt, k)
        if ktt ~= 5 then return end
        local name = str(k)
        if name == "team" then
            ctx.team = vtt .. ":" .. v
        elseif name == "name" then
            if vtt == 5 then ctx.name = str(v) or nil end
        elseif name == "invincible" then
            ctx.inv = vtt == 1 and v % 256 ~= 0
        end
    end

    local function feed()
        local ok, text = pcall(function() return httpget("https://offsets.imtheo.lol/Offsets.hpp") end)
        if not ok or type(text) ~= "string" or #text < 1000 then return false, "the offset feed could not be fetched" end
        local missing
        local function grab(ns, field)
            local block = match(text, "namespace " .. ns .. "%s*{(.-)}")
            local hex = block and match(block, "[^%w_]" .. field .. "%s*=%s*0x(%x+)")
            local value = hex and tonumber(hex, 16)
            if not value and not missing then missing = ns .. "::" .. field end
            return value
        end
        Off.prim = grab("BasePart", "Primitive")
        Off.rot = grab("Primitive", "Rotation")
        Off.pos = grab("Primitive", "Position")
        local att = grab("Attachment", "Position")
        if missing then return false, "the offset feed has no " .. missing end
        if Off.pos - Off.rot ~= 36 then return false, "the part layout changed" end
        Off.bone = att + 0x70
        return true
    end

    local function locate()
        local chars, players, snaps
        local hits = getgc("playerDataByUserId")
        for _, hit in ipairs(type(hits) == "table" and hits or {}) do
            local a = hit.addr
            if not chars and type(a) == "number" and mr("int", a + 12) == 6 then
                local tbl = mr("uintptr", a)
                for i = -160, 160 do
                    local n = a + i * 32
                    local okk, kx = pcall(mr, "int", n + 28)
                    if okk and type(kx) == "number" and kx % 16 == 5 then
                        local oks, name = pcall(function() return str(mr("uintptr", n + 16)) end)
                        if oks and name == "characters" and mr("int", n + 12) == 6 then
                            local found = mr("uintptr", n)
                            if each(found, onUser, {}) and each(tbl, onUser, {}) then
                                chars, players = found, tbl
                            end
                        elseif oks and name == "snapshots" and mr("int", n + 12) == 6 then
                            snaps = mr("uintptr", n)
                        elseif oks and name == "estimatedServerTime" and mr("int", n + 12) == 3 then
                            E.clockNode = n
                        end
                    end
                end
            end
        end
        if not chars then return false end
        E.chars, E.players, E.snaps = chars, players, snaps
        local stores = {}
        local lives = getgc("IsAlive")
        for _, hit in ipairs(type(lives) == "table" and lives or {}) do
            local a = hit.addr
            if type(a) == "number" and mr("int", a + 12) == 7 then
                local fn = mr("uintptr", a)
                if mr("byte", fn + 4) == 1 and mr("int", fn + 0x2c) == 15 then
                    local cell = mr("uintptr", fn + 0x20)
                    if type(cell) == "number" and cell > 65536 then stores[#stores + 1] = cell end
                end
            end
        end
        E.stores = stores
        local throws
        local marks = getgc("Cancellations")
        for _, hit in ipairs(type(marks) == "table" and marks or {}) do
            local a = hit.addr
            if not throws and type(a) == "number" and mr("int", a + 12) == 6 then
                for i = -8, 8 do
                    local n = a + i * 32
                    local okk, kx = pcall(mr, "int", n + 28)
                    if okk and type(kx) == "number" and kx % 16 == 5 then
                        local oks, name = pcall(function() return str(mr("uintptr", n + 16)) end)
                        if oks and name == "World" and mr("int", n + 12) == 6 then
                            local ctx = {}
                            if each(mr("uintptr", n), onWorld, ctx) and ctx.entries then throws = ctx.entries end
                        end
                    end
                end
            end
        end
        E.throws = throws
        return true
    end

    local function storeTable()
        if E.store then
            local v = mr("uintptr", E.store + 8)
            if type(v) == "number" and v > 65536 and mr("int", v + 12) == 6 then return mr("uintptr", v) end
            return nil
        end
        for _, cell in ipairs(E.stores) do
            local v = mr("uintptr", cell + 8)
            if type(v) == "number" and v > 65536 and mr("int", v + 12) == 6 then
                local tbl = mr("uintptr", v)
                local users = {}
                if each(tbl, onUser, users) then
                    for _, rec in pairs(users) do
                        local h = {}
                        each(rec, onLife, h)
                        if h.hp and h.max then
                            E.store = cell
                            return tbl
                        end
                        break
                    end
                end
            end
        end
        return nil
    end

    local function square(z)
        local o = Drawing.new("Square")
        o.Visible = false
        o.ZIndex = z
        o.Filled = true
        o.Thickness = 1
        o.Color = BLACK
        return { o = o, vis = false, c = BLACK }
    end
    local function outline(z, color)
        local o = Drawing.new("Square")
        o.Visible = false
        o.ZIndex = z
        o.Filled = false
        o.Thickness = 1
        o.Color = color
        return { o = o, vis = false, c = color }
    end
    local SHX = { -1, 1, 0, 0 }
    local SHY = { 0, 0, -1, 1 }
    local function shadowSync(d)
        local sh = d.sh
        local on = d.shOn and d.vis and true or false
        for i = 1, 4 do
            local o = sh[i]
            if sh.vis ~= on then o.Visible = on end
            if on then
                if sh.s ~= d.s then o.Text = d.s or "" end
                if sh.x ~= d.x or sh.y ~= d.y then
                    P.x, P.y = (d.x or 0) + SHX[i], (d.y or 0) + SHY[i]
                    o.Position = P
                end
                if sh.a ~= d.a then o.Transparency = d.a or 1 end
            end
        end
        sh.vis = on
        if on then sh.s, sh.x, sh.y, sh.a = d.s, d.x, d.y, d.a end
    end
    local function text(size, center, color)
        local sh = {}
        for i = 1, 4 do
            local o = Drawing.new("Text")
            o.Visible = false
            o.ZIndex = 13
            o.Size = size
            o.Center = center
            o.Outline = false
            o.Font = FONT
            o.Color = BLACK
            sh[i] = o
        end
        sh.vis = false
        local o = Drawing.new("Text")
        o.Visible = false
        o.ZIndex = 14
        o.Size = size
        o.Center = center
        o.Outline = true
        o.Font = FONT
        o.Color = color
        return { o = o, vis = false, c = color, ol = true, sh = sh }
    end
    local function txt(d, value)
        if d.s ~= value then
            d.s = value
            d.o.Text = value
            if d.shOn then shadowSync(d) end
        end
    end
    local function pos(d, x, y)
        if d.x ~= x or d.y ~= y then
            d.x, d.y = x, y
            P.x, P.y = x, y
            d.o.Position = P
            if d.shOn then shadowSync(d) end
        end
    end
    local hpCache = {}
    local function hpColor(frac)
        local full = Cfg.health_color or WHITE
        if hpCache.color ~= full then
            hpCache = { color = full }
        end
        local index = floor(frac * 20 + 0.5)
        local c = hpCache[index]
        if not c then
            local t = index / 20
            c = Color3.new(1 + (full.R - 1) * t, 0.2 + (full.G - 0.2) * t, 0.2 + (full.B - 0.2) * t)
            hpCache[index] = c
        end
        return c
    end
    local function line()
        local o = Drawing.new("Line")
        o.Visible = false
        o.ZIndex = 10
        o.Thickness = 1
        return { o = o, vis = false }
    end
    local function vis(d, on)
        if d.vis ~= on then
            d.vis = on
            d.o.Visible = on
            if d.sh then shadowSync(d) end
        end
    end
    local function col(d, c)
        if d.c ~= c then
            d.c = c
            d.o.Color = c
        end
    end
    local function alp(d, a)
        if d.a ~= a then
            d.a = a
            d.o.Transparency = a
            if d.sh then
                local solid = a >= 0.995
                if d.ol ~= solid then
                    d.ol = solid
                    d.o.Outline = solid
                    d.shOn = not solid
                end
                shadowSync(d)
            end
        end
    end
    local function seg(d, x1, y1, x2, y2)
        if d.x ~= x1 or d.y ~= y1 then
            d.x, d.y = x1, y1
            P.x, P.y = x1, y1
            d.o.From = P
        end
        if d.w ~= x2 or d.h ~= y2 then
            d.w, d.h = x2, y2
            P.x, P.y = x2, y2
            d.o.To = P
        end
    end
    local function rect(d, x, y, w, h)
        if d.x ~= x or d.y ~= y then
            d.x, d.y = x, y
            P.x, P.y = x, y
            d.o.Position = P
        end
        if d.w ~= w or d.h ~= h then
            d.w, d.h = w, h
            P.x, P.y = w, h
            d.o.Size = P
        end
    end

    local function hideLines(ent)
        local lines = ent.lines
        if lines and ent.linesOn then
            ent.linesOn = false
            for i = 1, NL do vis(lines[i], false) end
        end
    end
    local function hideBar(ent)
        local d = ent.d
        if d and ent.barOn then
            ent.barOn = false
            for i = 1, #d.all do vis(d.all[i], false) end
        end
    end
    local function info(ent)
        local d = ent.d
        if d then return d end
        d = {
            boxo = outline(11, BLACK), box = outline(12, WHITE), boxi = outline(11, BLACK),
            bg = square(11), fill = square(12),
            name = text(13, true, WHITE), weapon = text(13, true, WHITE), dist = text(13, true, WHITE),
            inv = text(12, false, GOLD), bot = text(12, false, GREY),
        }
        txt(d.inv, "INV")
        txt(d.bot, "BOT")
        d.all = { d.boxo, d.box, d.boxi, d.bg, d.fill, d.name, d.weapon, d.dist, d.inv, d.bot }
        ent.d = d
        return d
    end
    local function corners(d)
        if d.cb then return end
        d.cb, d.cf = {}, {}
        for i = 1, 8 do
            d.cb[i] = square(11)
            d.cf[i] = square(12)
            d.all[#d.all + 1] = d.cb[i]
            d.all[#d.all + 1] = d.cf[i]
        end
    end
    local Q = {}
    local function kill(o)
        pcall(function() o:Remove() end)
    end
    local Pool = {}
    local function wipe(kit)
        if kit.lines then
            for i = 1, NL do kill(kit.lines[i].o) end
        end
        if kit.d then
            for _, d in ipairs(kit.d.all) do
                kill(d.o)
                if d.sh then
                    for i = 1, 4 do kill(d.sh[i]) end
                end
            end
        end
    end
    local function drop(ent)
        if not ent.lines and not ent.d then return end
        if ent.lines then
            for i = 1, NL do vis(ent.lines[i], false) end
        end
        if ent.d then
            for _, d in ipairs(ent.d.all) do vis(d, false) end
        end
        Pool[#Pool + 1] = { lines = ent.lines, d = ent.d }
        ent.lines, ent.d, ent.linesOn, ent.barOn = nil, nil, false, false
    end
    local function spawn(uid)
        local ent = { uid = uid }
        local kit = table.remove(Pool)
        if kit then ent.lines, ent.d = kit.lines, kit.d end
        return ent
    end

    local function bind(list, now)
        local want
        for i = 1, #list do
            local inst = list[i].inst
            if inst and not E.models[inst] then
                want = want or {}
                want[inst] = true
            end
        end
        if not want or now - Timer.scan < 0.3 then return end
        Timer.scan = now
        for _, child in ipairs(workspace:GetChildren()) do
            local a = child.Address
            if want[a] then
                local root = child:FindFirstChild("Gf2Root")
                if root then
                    local prim = mr("uintptr", root.Address + Off.prim)
                    if type(prim) == "number" and prim > 65536 then
                        local bones = {}
                        for i = 1, NB do bones[i] = false end
                        for _, d in ipairs(root:GetDescendants()) do
                            local i = INDEX[d.Name]
                            if i then bones[i] = d.Address end
                        end
                        E.models[a] = { prim = prim, b = bones, bad = 0 }
                    end
                end
            end
        end
    end

    local Held = {}
    local function refresh(now)
        local seen = {}
        if not each(E.chars, onUser, seen) then return end
        local list = {}
        local held = {}
        for uid, rec in pairs(seen) do
            if uid ~= MY then
                local item = { uid = uid, rag = false }
                each(rec, onRecord, item)
                if item.cm then each(item.cm, onModel, item) end
                item.inst = item.ud and mr("uintptr", item.ud + 0x10) or nil
                local gun = item.gun and mr("uintptr", item.gun + 0x10) or nil
                if gun then held[gun] = true end
                if not item.body then
                    Held[uid] = nil
                elseif Cfg.weapon then
                    local w = Held[uid]
                    if not w or now - w.at >= 0.5 then
                        local got = {}
                        each(item.body, onBody, got)
                        w = { at = now, name = got.weapon }
                        Held[uid] = w
                    end
                    item.weapon = w.name
                end
                list[#list + 1] = item
            end
        end
        local snap = latest()
        if snap then
            local ctx, ghosts = {}, {}
            each(snap, onSnap, ctx)
            if E.snapTime == nil then
                E.snapTime = ctx.time
            elseif ctx.time ~= E.snapTime then
                E.snapTime = ctx.time
                E.snapAt = now
            end
            if ctx.data and E.snapAt and now - E.snapAt < 1 then each(ctx.data, onUser, ghosts) end
            for uid, rec in pairs(ghosts) do
                if uid ~= MY and not seen[uid] then
                    local item = { uid = uid, rag = false }
                    each(rec, onGhost, item)
                    list[#list + 1] = item
                end
            end
        end
        bind(list, now)
        local tbl = storeTable()
        if tbl then
            local users, fresh = {}, {}
            if each(tbl, onUser, users) then
                for uid, rec in pairs(users) do
                    local h = {}
                    each(rec, onLife, h)
                    fresh[uid] = h
                end
                E.hp = fresh
            end
        end
        if now - Timer.team >= 1 then
            Timer.team = now
            local users, fresh, names, inv = {}, {}, {}, {}
            if each(E.players, onUser, users) then
                for uid, rec in pairs(users) do
                    local t = {}
                    each(rec, onTeam, t)
                    fresh[uid] = t.team
                    names[uid] = t.name
                    inv[uid] = t.inv
                end
                E.team, E.names, E.inv = fresh, names, inv
            end
        end
        if now - Timer.strings >= 30 then
            Timer.strings = now
            Str = {}
        end
        E.held = held
        E.pub = list
    end

    local function draw(ent, h)
        local M = ent.model
        if not M and ent.inst then
            M = E.models[ent.inst]
            ent.model = M
        end
        local placed = false
        local minx, miny, maxx, maxy
        local wx, wy, wz
        if ent.posAddr then
            local pb = mr("buffer", ent.posAddr, 12)
            if type(pb) == "string" and #pb >= 12 then
                wx, wy, wz = up("<fff", pb)
                if wx ~= wx or wy < -300 then wx = nil end
            end
        elseif ent.gx then
            wx, wy, wz = ent.gx, ent.gy, ent.gz
            if wx ~= wx or wy < -300 then wx = nil end
        end
        if M and wx then
            local now = E.now
            if now - (ent.poseAt or 0) >= POSE then
                ent.poseAt = now
                ent.posed = false
                local bxs, bys, bzs = ent.bx, ent.by, ent.bz
                if not bxs then
                    bxs, bys, bzs = {}, {}, {}
                    ent.bx, ent.by, ent.bz = bxs, bys, bzs
                end
                local buf = mr("buffer", M.prim + Off.rot, 48)
                if type(buf) == "string" and #buf >= 48 then
                    local r00, r01, r02, r10, r11, r12, r20, r21, r22, px, py, pz = up("<ffffffffffff", buf)
                    local near = false
                    local hip = M.b[4]
                    if hip and py == py then
                        local hb = mr("buffer", hip + Off.bone, 12)
                        if type(hb) == "string" and #hb >= 12 then
                            local x, y, z = up("<fff", hb)
                            local dx = wx - (px + r00 * x + r01 * y + r02 * z)
                            local dy = wy + 1.2 - (py + r10 * x + r11 * y + r12 * z)
                            local dz = wz - (pz + r20 * x + r21 * y + r22 * z)
                            near = x == x and dx == dx and dy == dy and dz == dz
                            if near and (dx * dx + dz * dz > 9 or dy > 3 or dy < -3) then
                                px, py, pz = px + dx, py + dy, pz + dz
                            end
                        end
                    end
                    if near then
                        ent.posed = true
                        local good = 0
                        local bones = M.b
                        for i = 1, NB do
                            local a = bones[i]
                            local keep = false
                            if a then
                                local bb = mr("buffer", a + Off.bone, 12)
                                if type(bb) == "string" and #bb >= 12 then
                                    local x, y, z = up("<fff", bb)
                                    if x == x and x > -100000 and x < 100000 and y > -100000 and y < 100000 and z > -100000 and z < 100000 then
                                        good = good + 1
                                        local bx = px + r00 * x + r01 * y + r02 * z
                                        local by = py + r10 * x + r11 * y + r12 * z
                                        local bz = pz + r20 * x + r21 * y + r22 * z
                                        local ex, ey, ez = bx - wx, by - wy - 1.2, bz - wz
                                        if ex > -7 and ex < 7 and ey > -7 and ey < 7 and ez > -7 and ez < 7 then
                                            bxs[i], bys[i], bzs[i] = bx, by, bz
                                            keep = true
                                        end
                                    end
                                end
                            end
                            if not keep then bxs[i] = false end
                        end
                        if good == 0 then
                            M.bad = M.bad + 1
                            if M.bad > 60 then
                                E.models[ent.inst] = nil
                                ent.model = nil
                            end
                        else
                            M.bad = 0
                        end
                    end
                end
            end
            if ent.posed then
                placed = true
                local bxs, bys, bzs = ent.bx, ent.by, ent.bz
                for i = 1, NB do
                    local bx = bxs[i]
                    local on = false
                    if bx then
                        local by, bz = bys[i], bzs[i]
                        local sv, vs = W2S(V3(bx, by, bz))
                        if vs then
                            on = true
                            local sx, sy = sv.X, sv.Y
                            SX[i], SY[i] = floor(sx + 0.5), floor(sy + 0.5)
                            if not minx then
                                minx, maxx, miny, maxy = sx, sx, sy, sy
                            else
                                if sx < minx then minx = sx elseif sx > maxx then maxx = sx end
                                if sy < miny then miny = sy elseif sy > maxy then maxy = sy end
                            end
                            if i == 1 then
                                local tv, ton = W2S(V3(bx, by + 0.9, bz))
                                if ton and tv.Y < miny then miny = tv.Y end
                            end
                        end
                    end
                    OK[i] = on
                end
            end
        end
        if Cfg.skeleton and placed and minx then
            local lines = ent.lines
            if not lines then
                lines = {}
                for i = 1, NL do lines[i] = line() end
                ent.lines = lines
            end
            ent.linesOn = true
            local color, alpha = Cfg.skeleton_color, Cfg.skeleton_alpha
            for i = 1, NL do
                local link = LINKS[i]
                local a, b = link[1], link[2]
                local d = lines[i]
                if OK[a] and OK[b] then
                    seg(d, SX[a], SY[a], SX[b], SY[b])
                    col(d, color)
                    alp(d, alpha)
                    vis(d, true)
                else
                    vis(d, false)
                end
            end
        else
            hideLines(ent)
        end
        local x0, y0, x1, y1
        if placed and minx and maxy - miny >= 6 then
            local tall = maxy - miny
            local pad = tall * 0.08
            local wide = maxx - minx + pad * 2
            if wide < tall * 0.4 then wide = tall * 0.4 end
            local mid = (minx + maxx) * 0.5
            x0, x1, y0, y1 = mid - wide * 0.5, mid + wide * 0.5, miny, maxy + pad * 0.5
        elseif not minx and wx then
            local fv, fon = W2S(V3(wx, wy - 2.5, wz))
            local tv, ton = W2S(V3(wx, wy + 3.7, wz))
            if fon and ton and fv.Y - tv.Y >= 6 then
                local tall = fv.Y - tv.Y
                x0, x1, y0, y1 = fv.X - tall * 0.22, fv.X + tall * 0.22, tv.Y, fv.Y
            end
        end
        if not x0 or not E.info then
            hideBar(ent)
            return
        end
        local bx, by = floor(x0 + 0.5), floor(y0 + 0.5)
        local bw, bh = floor(x1 - x0 + 0.5), floor(y1 - y0 + 0.5)
        if bw < 2 then bw = 2 end
        if bh < 3 then
            hideBar(ent)
            return
        end
        x0, y0 = bx, by
        local mid = bx + floor(bw / 2)
        local d = info(ent)
        ent.barOn = true
        local full = Cfg.box and not Cfg.box_corners
        local cut = Cfg.box and Cfg.box_corners
        if cut then
            corners(d)
            local a, c = Cfg.box_alpha, Cfg.box_color
            local lw, lh = floor(bw / 4), floor(bh / 4)
            if lw < 3 then lw = 3 end
            if lh < 3 then lh = 3 end
            local rx, ry = bx + bw - 1, by + bh - 1
            local q = Q
            q[1], q[2], q[3], q[4] = bx, by, lw, 1
            q[5], q[6], q[7], q[8] = bx, by, 1, lh
            q[9], q[10], q[11], q[12] = rx - lw + 1, by, lw, 1
            q[13], q[14], q[15], q[16] = rx, by, 1, lh
            q[17], q[18], q[19], q[20] = bx, ry, lw, 1
            q[21], q[22], q[23], q[24] = bx, ry - lh + 1, 1, lh
            q[25], q[26], q[27], q[28] = rx - lw + 1, ry, lw, 1
            q[29], q[30], q[31], q[32] = rx, ry - lh + 1, 1, lh
            for i = 1, 8 do
                local k = (i - 1) * 4
                local e = d.cb[i]
                rect(e, q[k + 1] - 1, q[k + 2] - 1, q[k + 3] + 2, q[k + 4] + 2)
                alp(e, a)
                vis(e, true)
                e = d.cf[i]
                rect(e, q[k + 1], q[k + 2], q[k + 3], q[k + 4])
                col(e, c)
                alp(e, a)
                vis(e, true)
            end
        elseif d.cb then
            for i = 1, 8 do
                vis(d.cb[i], false)
                vis(d.cf[i], false)
            end
        end
        if full then
            local a = Cfg.box_alpha
            rect(d.box, bx, by, bw, bh)
            col(d.box, Cfg.box_color)
            alp(d.box, a)
            vis(d.box, true)
            rect(d.boxo, bx - 1, by - 1, bw + 2, bh + 2)
            alp(d.boxo, a)
            vis(d.boxo, true)
            rect(d.boxi, bx + 1, by + 1, bw - 2, bh - 2)
            alp(d.boxi, a)
            vis(d.boxi, true)
        else
            vis(d.boxo, false)
            vis(d.box, false)
            vis(d.boxi, false)
        end
        if Cfg.health and h and h.hp and h.max and h.max > 0 then
            local frac = h.hp / h.max
            if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
            local fh = floor(bh * frac + 0.5)
            local a = Cfg.health_alpha
            rect(d.bg, bx - 6, by - 1, 4, bh + 2)
            alp(d.bg, a)
            vis(d.bg, true)
            rect(d.fill, bx - 5, by + bh - fh, 2, fh)
            col(d.fill, hpColor(frac))
            alp(d.fill, a)
            vis(d.fill, true)
        else
            vis(d.bg, false)
            vis(d.fill, false)
        end
        local uid = ent.uid
        local label = Cfg.name and E.names[uid] or nil
        if label then
            txt(d.name, label)
            col(d.name, Cfg.name_color)
            alp(d.name, Cfg.name_alpha)
            pos(d.name, mid, y0 - 12)
            vis(d.name, true)
        else
            vis(d.name, false)
        end
        local yb = y0 + bh + 8
        if Cfg.distance and wx and E.cx then
            local dx, dy, dz = wx - E.cx, wy - E.cy, wz - E.cz
            local metres = floor(math.sqrt(dx * dx + dy * dy + dz * dz) * 0.28 + 0.5)
            if ent.metres ~= metres then
                ent.metres = metres
                txt(d.dist, metres .. "m")
            end
            pos(d.dist, mid, yb)
            vis(d.dist, true)
            yb = yb + 12
        else
            vis(d.dist, false)
        end
        local held = Cfg.weapon and ent.weapon or nil
        if held then
            txt(d.weapon, held)
            pos(d.weapon, mid, yb)
            vis(d.weapon, true)
        else
            vis(d.weapon, false)
        end
        local fy = y0 - 2
        if Cfg.flags and E.inv[uid] then
            pos(d.inv, x0 + bw + 5, fy)
            vis(d.inv, true)
            fy = fy + 11
        else
            vis(d.inv, false)
        end
        if Cfg.flags and uid < 0 then
            pos(d.bot, x0 + bw + 5, fy)
            vis(d.bot, true)
        else
            vis(d.bot, false)
        end
    end

    local Drops = { items = {}, bodies = {}, guns = {}, pool = {}, at = 0, shown = false, stamp = 0 }
    Drops.names = {
        [51003] = "M4", [51004] = "X12", [51005] = "Vector", [51006] = "DesertEagle", [51007] = "AK",
        [51008] = "Bryson890", [51009] = "Icarus556", [51010] = "Signal50", [51011] = "EBR14", [51012] = "HCR56",
        [51013] = "MCPR300", [51014] = "Minibak", [51015] = "Basilisk", [51016] = "Lockwood300", [51017] = "Vel46",
        [51018] = "FTacSiege", [51020] = "M7", [51021] = "FnScarL", [51022] = "LAB330", [51023] = "BASP",
        [51024] = "SO14", [51025] = "LachmannSub", [51026] = "Kastov74u", [51027] = "P890", [51028] = "MXGuardian",
    }
    local function dropWipe(kit)
        kill(kit.label.o)
        kill(kit.dist.o)
        for i = 1, 4 do
            kill(kit.label.sh[i])
            kill(kit.dist.sh[i])
        end
    end
    local function dropScan()
        local list, bodies = {}, {}
        local folder = Cfg.ammo and workspace:FindFirstChild("AmmoDrops")
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                local a = model.Address
                local body = Drops.bodies[a] or model:FindFirstChild("Body")
                if body then
                    bodies[a] = body
                    local p = body.Position
                    if p then list[#list + 1] = { a = a, x = p.X, y = p.Y, z = p.Z, gun = false, label = "Ammo" } end
                end
            end
        end
        Drops.bodies = bodies
        local guns = {}
        local names = Drops.names
        folder = Cfg.gun and workspace:FindFirstChild("DroppedWeapons")
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                local a = model.Address
                local g = Drops.guns[a]
                if not g then
                    g = { drop = string.sub(model.Name, 1, 4) == "Drop" }
                    if g.drop then
                        g.root = model:FindFirstChild("Root")
                        g.id = model:GetAttribute("GunsmithItemId")
                    end
                end
                guns[a] = g
                if g.drop and g.root then
                    local p = g.root.Position
                    if p and p.Y > -300 then
                        list[#list + 1] = { a = a, x = p.X, y = p.Y, z = p.Z, gun = true, label = g.id and names[g.id] or "Weapon" }
                    end
                end
            end
        end
        Drops.guns = guns
        Drops.pub = list
    end
    local function dropHide(it)
        vis(it.label, false)
        vis(it.dist, false)
    end
    local function dropDraw()
        local items = Drops.items
        if not (Cfg.ammo or Cfg.gun) or clock() - E.beat >= 1 then
            if Drops.shown then
                Drops.shown = false
                for _, it in pairs(items) do dropHide(it) end
            end
            return
        end
        Drops.shown = true
        local list = Drops.pub
        if list and list ~= Drops.cur then
            Drops.cur = list
            local stamp = Drops.stamp + 1
            Drops.stamp = stamp
            for i = 1, #list do
                local src = list[i]
                local it = items[src.a]
                if not it then
                    it = table.remove(Drops.pool)
                    if it then
                        it.metres = nil
                    else
                        it = { label = text(13, true, WHITE), dist = text(13, true, WHITE) }
                    end
                    items[src.a] = it
                end
                it.x, it.y, it.z, it.stamp, it.gun = src.x, src.y, src.z, stamp, src.gun
                txt(it.label, src.label)
            end
            for a, it in pairs(items) do
                if it.stamp ~= stamp then
                    dropHide(it)
                    Drops.pool[#Drops.pool + 1] = it
                    items[a] = nil
                end
            end
        end
        local cx, cy, cz
        if Cfg.ammo_distance or Cfg.gun_distance then
            local cam = workspace.CurrentCamera
            local cp = cam and cam.CFrame.Position
            if cp then cx, cy, cz = cp.X, cp.Y, cp.Z end
        end
        for _, it in pairs(items) do
            local gun = it.gun
            local enabled, named, ranged, color, alpha
            if gun then
                enabled, named, ranged, color, alpha = Cfg.gun, Cfg.gun_text, Cfg.gun_distance, Cfg.gun_color, Cfg.gun_alpha
            else
                enabled, named, ranged, color, alpha = Cfg.ammo, Cfg.ammo_text, Cfg.ammo_distance, Cfg.ammo_color, Cfg.ammo_alpha
            end
            local sv, on
            if enabled then sv, on = W2S(V3(it.x, it.y, it.z)) end
            if on then
                local x, y = floor(sv.X + 0.5), floor(sv.Y + 0.5)
                if named then
                    pos(it.label, x, y)
                    col(it.label, color)
                    alp(it.label, alpha)
                    vis(it.label, true)
                    y = y + 12
                else
                    vis(it.label, false)
                end
                if cx and ranged then
                    local dx, dy, dz = it.x - cx, it.y - cy, it.z - cz
                    local metres = floor(math.sqrt(dx * dx + dy * dy + dz * dz) * 0.28 + 0.5)
                    if it.metres ~= metres then
                        it.metres = metres
                        txt(it.dist, metres .. "m")
                    end
                    pos(it.dist, x, y)
                    col(it.dist, color)
                    alp(it.dist, alpha)
                    vis(it.dist, true)
                else
                    vis(it.dist, false)
                end
            else
                dropHide(it)
            end
        end
    end

    local FLY = { CS2_Flash = "Flash", CS2_Smoke = "Smoke" }
    local SMOKE_LIFE = 21
    local SMOKE_COLOR, FLY_COLOR = Color3.fromRGB(200, 200, 200), Color3.fromRGB(255, 235, 120)
    local Nades = { items = {}, known = {}, fuses = {}, pool = {}, at = 0, shown = false, stamp = 0 }
    local function nadeWipe(kit)
        kill(kit.label.o)
        kill(kit.dist.o)
        kill(kit.bg.o)
        kill(kit.fill.o)
        for i = 1, 4 do
            kill(kit.label.sh[i])
            kill(kit.dist.sh[i])
        end
    end
    local function nadeScan(now)
        local known, list, seen = Nades.known, {}, {}
        local heldNow = E.held
        for _, c in ipairs(workspace:GetChildren()) do
            local name = c.Name
            local fly = FLY[name]
            if fly or name == "ThrowableEffect" then
                local a = c.Address
                seen[a] = true
                local k = known[a]
                if not k then
                    k = { born = now, tries = 0 }
                    known[a] = k
                end
                if not k.kind and k.tries < 12 then
                    k.tries = k.tries + 1
                    if fly then
                        if c:FindFirstChild("Gf2Root") or c:FindFirstChild("Humanoid") then
                            k.kind = "held"
                        else
                            local root = c:FindFirstChild("Root")
                            if root then
                                k.kind, k.label, k.part = "fly", fly, root
                            end
                        end
                    elseif c:FindFirstChild("Smoke") then
                        local p = c.Position
                        if p then k.kind, k.x, k.y, k.z = "smoke", p.X, p.Y, p.Z end
                    end
                end
                local kind = k.kind
                if kind == "fly" then
                    if not (heldNow and heldNow[a]) then
                        local p = k.part.Position
                        if p then
                            list[#list + 1] = { id = a, label = k.label, color = FLY_COLOR, part = k.part, x = p.X, y = p.Y, z = p.Z, seen = k.born }
                        end
                    end
                elseif kind == "smoke" then
                    list[#list + 1] = { id = a, label = "Smoke", color = SMOKE_COLOR, x = k.x, y = k.y, z = k.z, born = k.born, life = SMOKE_LIFE }
                end
            end
        end
        for a in pairs(known) do
            if not seen[a] then known[a] = nil end
        end
        if E.throws then
            local records, live = {}, {}
            if each(E.throws, onAny, records) then
                local gnow
                if E.clockNode then
                    local g = mr("double", E.clockNode)
                    if type(g) == "number" and g == g then gnow = g end
                end
                for i = 1, #records do
                    local t = {}
                    each(records[i], onThrow, t)
                    if t.kind == "Spawn" and t.item == 53001 and t.id and t.time and t.deadline then
                        live[t.id] = true
                        local f = Nades.fuses[t.id]
                        if not f then
                            f = { first = now }
                            Nades.fuses[t.id] = f
                        end
                        if f.rec ~= records[i] then
                            f.rec = records[i]
                            local guess = t.time - now
                            if not Nades.offset or guess > Nades.offset then Nades.offset = guess end
                        end
                        local left
                        if gnow and gnow - t.time > -1 and gnow - t.time < 4 then
                            left = t.deadline - gnow
                        else
                            left = t.deadline - (now + Nades.offset)
                        end
                        f.ends = now + left
                        f.total = t.deadline - (t.start or t.time)
                    end
                end
            end
            for id in pairs(Nades.fuses) do
                if not live[id] then Nades.fuses[id] = nil end
            end
            local flying, fuses = {}, {}
            for i = 1, #list do
                if list[i].label == "Flash" and list[i].part then flying[#flying + 1] = list[i] end
            end
            for _, f in pairs(Nades.fuses) do fuses[#fuses + 1] = f end
            if #flying > 0 and #fuses > 0 then
                table.sort(flying, function(a, b) return a.seen < b.seen end)
                table.sort(fuses, function(a, b) return a.first < b.first end)
                for i = 1, #flying do
                    local f = fuses[i]
                    if f and f.total > 0 then flying[i].ends, flying[i].total = f.ends, f.total end
                end
            end
        end
        Nades.pub = list
    end
    local function nadeHide(it)
        vis(it.label, false)
        vis(it.dist, false)
        vis(it.bg, false)
        vis(it.fill, false)
    end
    local function nadeDraw()
        local items = Nades.items
        if not Cfg.nade or clock() - E.beat >= 1 then
            if Nades.shown then
                Nades.shown = false
                for _, it in pairs(items) do nadeHide(it) end
            end
            return
        end
        Nades.shown = true
        local list = Nades.pub
        if list and list ~= Nades.cur then
            Nades.cur = list
            local stamp = Nades.stamp + 1
            Nades.stamp = stamp
            for i = 1, #list do
                local src = list[i]
                local it = items[src.id]
                if not it then
                    it = table.remove(Nades.pool)
                    if it then
                        it.metres = nil
                    else
                        it = { label = text(13, true, WHITE), dist = text(13, true, WHITE), bg = square(13), fill = square(14) }
                    end
                    items[src.id] = it
                end
                it.x, it.y, it.z, it.stamp = src.x, src.y, src.z, stamp
                it.part, it.born, it.life, it.color = src.part, src.born, src.life, src.color
                it.ends, it.total = src.ends, src.total
                txt(it.label, src.label)
            end
            for id, it in pairs(items) do
                if it.stamp ~= stamp then
                    nadeHide(it)
                    Nades.pool[#Nades.pool + 1] = it
                    items[id] = nil
                end
            end
        end
        local cx, cy, cz
        if Cfg.nade_distance then
            local cam = workspace.CurrentCamera
            local cp = cam and cam.CFrame.Position
            if cp then cx, cy, cz = cp.X, cp.Y, cp.Z end
        end
        local now = E.now or clock()
        for _, it in pairs(items) do
            if it.part then
                local ok, p = pcall(function() return it.part.Position end)
                if ok and p then it.x, it.y, it.z = p.X, p.Y, p.Z end
            end
            local sv, on = W2S(V3(it.x, it.y, it.z))
            if on then
                local x, y = floor(sv.X + 0.5), floor(sv.Y + 0.5)
                local color = it.color
                if Cfg.nade_text then
                    pos(it.label, x, y)
                    col(it.label, color)
                    vis(it.label, true)
                    y = y + 9
                else
                    vis(it.label, false)
                end
                local frac
                if it.ends then
                    frac = (it.ends - now) / it.total
                elseif it.life then
                    frac = 1 - (now - it.born) / it.life
                end
                if frac then
                    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end
                    local fw = floor(24 * frac + 0.5)
                    rect(it.bg, x - 13, y, 26, 4)
                    vis(it.bg, true)
                    if fw > 0 then
                        rect(it.fill, x - 12, y + 1, fw, 2)
                        col(it.fill, color)
                        vis(it.fill, true)
                    else
                        vis(it.fill, false)
                    end
                    y = y + 12
                else
                    vis(it.bg, false)
                    vis(it.fill, false)
                    if Cfg.nade_text then y = y + 3 end
                end
                if cx then
                    local dx, dy, dz = it.x - cx, it.y - cy, it.z - cz
                    local metres = floor(math.sqrt(dx * dx + dy * dy + dz * dz) * 0.28 + 0.5)
                    if it.metres ~= metres then
                        it.metres = metres
                        txt(it.dist, metres .. "m")
                    end
                    pos(it.dist, x, y)
                    vis(it.dist, true)
                else
                    vis(it.dist, false)
                end
            else
                nadeHide(it)
            end
        end
    end

    local function wanted()
        E.info = Cfg.box or Cfg.health or Cfg.name or Cfg.flags or Cfg.weapon or Cfg.distance or false
        return E.info or Cfg.skeleton
    end

    local function active()
        local key = Shared.Key
        if not key then return true end
        if key.Mode == ALWAYS or not key.Key then return true end
        return key.State == true
    end

    local function render()
        if not E.alive then return end
        dropDraw()
        nadeDraw()
        if not E.ready then return end
        local ents = E.ents
        local any = wanted() and active() and clock() - E.beat < 1
        if not any then
            if E.shown then
                E.shown = false
                for _, ent in pairs(ents) do
                    hideLines(ent)
                    hideBar(ent)
                end
            end
            return
        end
        E.shown = true
        local list = E.pub
        if list and list ~= E.cur then
            E.cur = list
            local stamp = (E.stamp or 0) + 1
            E.stamp = stamp
            for i = 1, #list do
                local item = list[i]
                local uid = item.uid
                local ent = ents[uid]
                if not ent then
                    ent = spawn(uid)
                    ents[uid] = ent
                end
                ent.posAddr, ent.gx, ent.gy, ent.gz = item.posAddr, item.gx, item.gy, item.gz
                ent.rag, ent.weapon, ent.stamp = item.rag, item.weapon, stamp
                if item.inst ~= ent.inst then
                    ent.inst = item.inst
                    ent.model = nil
                    ent.posed, ent.poseAt = false, nil
                end
            end
            for uid, ent in pairs(ents) do
                if ent.stamp ~= stamp then
                    drop(ent)
                    ents[uid] = nil
                end
            end
        end
        E.cx = nil
        if Cfg.distance then
            local cam = workspace.CurrentCamera
            local cp = cam and cam.CFrame.Position
            if cp then E.cx, E.cy, E.cz = cp.X, cp.Y, cp.Z end
        end
        local mine = E.team[MY]
        local hp = E.hp
        for uid, ent in pairs(ents) do
            local h = hp[uid]
            local show = not ent.rag or (h ~= nil and h.phase == "Alive")
            if show and h and h.phase and h.phase ~= "Alive" then show = false end
            if show and not Cfg.team and mine ~= nil and E.team[uid] == mine then show = false end
            if show then
                draw(ent, h)
            else
                hideLines(ent)
                hideBar(ent)
            end
        end
    end

    local API = {}
    function API.stop()
        if not E.alive then return end
        E.alive = false
        if E.conn then
            pcall(function() E.conn:Disconnect() end)
            E.conn = nil
        end
        for _, ent in pairs(E.ents) do drop(ent) end
        E.ents = {}
        for _, kit in ipairs(Pool) do wipe(kit) end
        Pool = {}
        for _, it in pairs(Drops.items) do dropWipe(it) end
        Drops.items = {}
        for _, kit in ipairs(Drops.pool) do dropWipe(kit) end
        Drops.pool = {}
        for _, it in pairs(Nades.items) do nadeWipe(it) end
        Nades.items = {}
        for _, kit in ipairs(Nades.pool) do nadeWipe(kit) end
        Nades.pool = {}
        if _G.AegisESP == API then _G.AegisESP = nil end
    end

    local function start(now)
        if E.failed or now - Timer.init < 15 then return end
        Timer.init = now
        if not Off.bone then
            local ok, why = feed()
            if not ok then
                E.failed = true
                tell("ESP is off: " .. tostring(why) .. ". Reload the script to try again.")
                return
            end
        end
        if Timer.tries == 0 then
            tell("Loading. The game freezes for a few seconds, once.")
            task.wait(0.15)
        end
        Timer.tries = Timer.tries + 1
        local ok, found = pcall(locate)
        if ok and found then
            E.ready = true
        elseif Timer.tries >= 4 then
            E.failed = true
            tell("ESP is off: the game's player list was not found. Reload the script in a match to try again.")
        end
    end

    local Old = _G.AegisESP
    if type(Old) == "table" and type(Old.stop) == "function" then pcall(Old.stop) end
    _G.AegisESP = API

    E.beat = clock()

    local okc, conn = pcall(function()
        return game:GetService("RunService").RenderStepped:Connect(function()
            if E.rendering then return end
            local now = clock()
            if now - (E.now or 0) < GATE then return end
            E.now = now
            E.rendering = true
            local ok, err = pcall(render)
            E.rendering = false
            if not ok then report(err) end
        end)
    end)
    if okc then E.conn = conn end

    task.spawn(function()
        while E.alive do
            if Library.Unloaded or not Library.Running then
                API.stop()
                break
            end
            local now = clock()
            E.beat = now
            local any = wanted()
            if (Cfg.ammo or Cfg.gun) and now - Drops.at >= 0.5 then
                Drops.at = now
                local ok, err = pcall(dropScan)
                if not ok then report(err) end
            end
            if Cfg.nade and now - Nades.at >= 0.05 then
                Nades.at = now
                local ok, err = pcall(nadeScan, now)
                if not ok then report(err) end
            end
            if not E.ready then
                start(now)
            elseif any and now - Timer.ents >= 0.1 then
                Timer.ents = now
                local ok, err = pcall(refresh, now)
                if not ok then report(err) end
            end
            task.wait((any or Cfg.ammo or Cfg.gun or Cfg.nade) and 0.03 or 0.25)
        end
    end)
end
