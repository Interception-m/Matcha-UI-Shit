local ok, Library = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Interception-m/gamesense_matcha/refs/heads/main/gamesense_lib.lua"))()
    return _G.Library
end)
if not ok or type(Library) ~= "table" then
    warn("gamesense_lib.lua failed to load: " .. tostring(Library))
    return
end

local ALWAYS = "Always on"
local DEGREE = "\194\176"

local function Unpack(Value)
    local R = Value % 256
    local G = math.floor(Value / 256) % 256
    local B = math.floor(Value / 65536) % 256
    local A = math.floor(Value / 16777216) % 256
    return Color3.fromRGB(R, G, B), 1 - A / 255
end

local function Pick(Owner, Flag, Value, Callback)
    local Color, Alpha = Unpack(Value)
    return Owner:ColorPicker({ Flag = Flag, Default = Color, Alpha = Alpha, ShowAlpha = true, Callback = Callback })
end

local function Key(Owner, Flag, Mode, Default)
    return Owner:Keybind({ Flag = Flag, Mode = Mode, Default = Default })
end

local function Has(List, Name)
    for _, Value in ipairs(List) do
        if Value == Name then return true end
    end
    return false
end

local function Box(Tab, Name, Column, ColumnSpan, Row, RowSpan, Fixed)
    return Tab:Section({
        Name = Name,
        Grid = { Column, ColumnSpan, Row, RowSpan },
        Movable = not Fixed,
        Resizable = not Fixed,
    })
end

Library.UI.Name = "gamesneeze"
Library.UI.NameSplit = 4
Library.UI.WatermarkClock = false
local Window = Library:Window({ CloseBind = Enum.KeyCode.Insert })
local Visuals = Window:CreateTab({ Icon = "visuals", Name = "VISUALS" })
local Nades = Window:CreateTab({ Icon = "grenade", Name = "NADES" })
local Misc = Window:CreateTab({ Icon = "misc", Name = "SETTINGS" })
local Skins = Window:CreateTab({ Icon = "skins", Name = "SKINS" })
local Shared = {}

Window:SetTab(1)

local Esp = { Cfg = {} }

do
    local Section = Box(Visuals, "Player ESP", 0, 12, 0, 24)
    local Other = Box(Visuals, "Other ESP", 12, 12, 0, 24)

    local Cfg = Esp.Cfg
    local Target = Section
    local function Check(Name, Flag, Field, ColorFlag, Value)
        Cfg[Field] = false
        local Toggle = Target:Toggle({ Name = Name, Flag = Flag, Callback = function(State)
            Cfg[Field] = State == true
            Cfg.dirty = true
        end })
        if ColorFlag then
            local Color, Alpha = Unpack(Value)
            Cfg[Field .. "_color"] = Color
            Cfg[Field .. "_alpha"] = 1 - Alpha
            Pick(Toggle, ColorFlag, Value, function(Picked, Transparency)
                if Picked then Cfg[Field .. "_color"] = Picked end
                Cfg[Field .. "_alpha"] = 1 - (tonumber(Transparency) or 0)
                Cfg.dirty = true
            end)
        end
        return Toggle
    end

    Esp.Key = Key(Section:Label({ Message = "Activation type" }), "esp_activation", ALWAYS, "LeftShift")
    Check("Teammates", "esp_teammates", "team")
    Check("Dormant", "esp_dormant", "dormant")
    Cfg.box_corners = false
    Check("Bounding box", "esp_bounding_box", "box", "esp_box_color", 0x82FFFFFF):Tie(
        Section:Dropdown({
            Name = "", Flag = "esp_box_style", Content = { "Full", "Corners" }, Default = "Full",
            Callback = function(Value)
                Cfg.box_corners = Value == "Corners"
                Cfg.dirty = true
            end,
        })
    )
    Check("Health bar", "esp_health_bar", "health", "esp_health_color", 0xFF50E178)
    Check("Name", "esp_name", "name", "esp_name_color", 0xC8FFFFFF)
    Check("Flags", "esp_flags", "flags")
    Check("Weapon text", "esp_weapon_text", "weapon")
    Cfg.get_icons = false
    Esp.WeaponIcon = Check("Weapon icon", "esp_weapon_icon", "wicon", "esp_weapon_icon_color", 0xC8FFFFFF)
    Check("Ammo text", "esp_ammo", "ammo", "esp_ammo_color", 0xE6C88C50)
    Check("Ammo bar", "esp_ammo_bar", "ammobar", "esp_ammo_bar_color", 0xE6C88C50)
    Check("Distance", "esp_distance", "distance")
    Check("Money", "esp_money", "money")
    Check("Skeleton", "esp_skeleton", "skeleton", "esp_skeleton_color", 0xFFAAFFFF)

    Target = Other
    do
        local Color, Alpha = Unpack(0xC8FFFFFF)
        Cfg.drop_color, Cfg.drop_alpha = Color, 1 - Alpha
        Cfg.drop_icon, Cfg.drop_text, Cfg.drop_ammo, Cfg.drop_distance, Cfg.drop = false, false, false, false, false
        Esp.DropBox = Other:MultiBox({
            Name = "Dropped weapons", Flag = "esp_dropped_weapons", Content = { "Icon", "Text", "Ammo", "Distance" },
            Callback = function(List)
                if type(List) ~= "table" then List = {} end
                Cfg.drop_icon, Cfg.drop_text = Has(List, "Icon"), Has(List, "Text")
                Cfg.drop_ammo, Cfg.drop_distance = Has(List, "Ammo"), Has(List, "Distance")
                Cfg.drop = #List > 0
                Cfg.dirty = true
            end,
        })
        Pick(Esp.DropBox, "esp_dropped_weapon_color", 0xC8FFFFFF, function(Picked, Transparency)
            if Picked then Cfg.drop_color = Picked end
            Cfg.drop_alpha = 1 - (tonumber(Transparency) or 0)
        end)
        Cfg.warn_icon, Cfg.warn_text, Cfg.warn_distance, Cfg.warn = false, false, false, false
        Esp.WarnBox = Other:MultiBox({
            Name = "Grenade warnings", Flag = "esp_grenade_warnings", Content = { "Icon", "Text", "Distance" },
            Callback = function(List)
                if type(List) ~= "table" then List = {} end
                Cfg.warn_icon, Cfg.warn_text, Cfg.warn_distance = Has(List, "Icon"), Has(List, "Text"), Has(List, "Distance")
                Cfg.warn = #List > 0
                Cfg.dirty = true
            end,
        })
    end
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
    Settings:Toggle({ Name = "Get icons", Flag = "settings_get_icons", Risky = true, Callback = function(State)
        local On = State == true
        Esp.Cfg.get_icons = On
        Esp.Cfg.dirty = true
        if Esp.WeaponIcon then Esp.WeaponIcon:SetEnabled(On) end
        if Esp.DropBox then Esp.DropBox:SetOptionEnabled("Icon", On) end
        if Esp.WarnBox then Esp.WarnBox:SetOptionEnabled("Icon", On) end
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
    local Nade = {}
    Shared.Nade = Nade
    local function Call(Name)
        return function(A, B)
            local Handler = Nade[Name]
            if Handler then return Handler(A, B) end
        end
    end

    local Create = Box(Nades, "Create Lineup", 0, 12, 0, 13)
    Create:Label({ Message = "To" })
    Nade.To = Create:TextBox({ Flag = "nade_to", Max = 16 })
    Nade.To.NoConfig = true
    Nade.Throw = Create:Dropdown({
        Name = "Throw type", Flag = "nade_throw_type",
        Content = { "Throw", "Jump throw" }, Default = "Throw",
    })
    Nade.CreateLabel = Create:Label({ Message = "Create lineup", Callback = Call("OnCreate") })
    Nade.CreateLabel:Keybind({ Flag = "nade_create_key", UseMode = false })
    Create:Button({ Name = "Save lineup", Callback = Call("OnSave") })
    Nade.Status = Create:Label({ Message = "" })

    local Helper = Box(Nades, "Helper", 0, 12, 13, 11)
    Nade.Helper = Helper:Toggle({ Name = "Grenade helper", Flag = "nade_helper" })
    Nade.HelperKey = Nade.Helper:Keybind({ Flag = "nade_helper_key", Mode = "Toggle" })
    Nade.Distance = Helper:Slider({ Name = "Distance", Flag = "nade_helper_distance", Min = 1, Max = 100, Default = 30, Ending = "m" })
    Nade.FilterKey = Helper:Label({ Message = "Override filter" }):Keybind({ Flag = "nade_helper_filter_key", Mode = "On hotkey" })

    local Lineups = Box(Nades, "Lineups", 12, 12, 0, 24)
    local List = Lineups:List({ Flag = "nade_lineup", Size = 325, Search = false, Bound = true, Callback = Call("OnSelect") })
    List.NoConfig = true
    Nade.List = List
    Lineups:Button({ Name = "Delete", Confirmation = true, Callback = Call("OnDelete") })
    Lineups:Button({ Name = "Load defaults", Callback = Call("OnDefaults") })
    Nade.ListStatus = Lineups:Label({ Message = "" })
end

do
    Box(Skins, "Model options", 0, 12, 0, 24, true)
    Box(Skins, "Weapon skin", 12, 12, 0, 24, true)
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

local function EspCore(E)
    local mr, up, sub, match, abs = memory_read, string.unpack, string.sub, string.match, math.abs
    local LO, HI, TWO32 = 0x10000, 0x7FFFFFFFFFFF, 4294967296
    local T = {}
    local Off = { ready = false }
    E.Off = Off

    local function ptr(a)
        local p = mr("uintptr", a)
        if p and p > LO and p < HI then return p end
        return nil
    end

    local function str(a)
        local b = mr("buffer", a, 32)
        if type(b) ~= "string" or #b < 32 then return nil end
        local size, sh, cap, ch = up("<I4I4I4I4", b, 17)
        if sh ~= 0 or ch ~= 0 or size > 4096 or cap < size then return nil end
        if size == 0 then return "" end
        if cap < 16 then return sub(b, 1, size) end
        local lo, hi = up("<I4I4", b, 1)
        local p = lo + hi * TWO32
        if p <= LO or p >= HI then return nil end
        local d = mr("buffer", p, size)
        if type(d) ~= "string" or #d < size then return nil end
        return d
    end

    local function vec(a)
        local b = mr("buffer", a, 12)
        if type(b) ~= "string" or #b < 12 then return nil end
        local x, y, z = up("<fff", b)
        if x ~= x or y ~= y or z ~= z then return nil end
        if x > 1e5 or x < -1e5 or y > 1e5 or y < -1e5 or z > 1e5 or z < -1e5 then return nil end
        return x, y, z
    end

    local function walk(addr)
        local h = { map = {}, stale = false, at = os.clock(), ok = false }
        local cm = addr and ptr(addr + 0x38)
        if not cm then return h end
        local first, last = ptr(cm), ptr(cm + 8)
        if not first or not last or last <= first then return h end
        local count = math.floor((last - first) / 16)
        if count > 16 then count = 16 end
        for i = 0, count - 1 do
            local payload = ptr(first + i * 16)
            local hb = payload and mr("buffer", payload, 32)
            if type(hb) == "string" and #hb >= 32 then
                local n = up("<I4", hb, 9)
                local lo, hi = up("<I4I4", hb, 25)
                local recs = lo + hi * TWO32
                if n >= 1 and n < 1024 and recs > LO and recs < HI then
                    local key = ptr(recs)
                    local name = key and str(key)
                    if name and match(name, "^[%a_][%w_]*$") then
                        local rb = mr("buffer", recs, n * 0x58)
                        if type(rb) == "string" and #rb >= n * 0x58 then
                            local map = h.map
                            for k = 0, n - 1 do
                                local o = k * 0x58
                                local klo, khi, tlo, thi = up("<I4I4I4I4", rb, o + 1)
                                local kp = klo + khi * TWO32
                                if kp > LO and kp < HI then
                                    local nm = str(kp)
                                    if nm then map[nm] = { rec = recs + o, key = kp, ty = tlo + thi * TWO32 } end
                                end
                            end
                            h.cm, h.first, h.cell, h.payload, h.recs = cm, first, first + i * 16, payload, recs
                            h.ok = true
                            return h
                        end
                    end
                end
            end
        end
        return h
    end

    local function get(h, name)
        if not h then return nil end
        local en = h.map[name]
        if not en then return nil end
        local rec = en.rec
        if mr("uintptr", rec) ~= en.key then
            h.stale = true
            return nil
        end
        local ty = en.ty
        if ty == T.num then return mr("double", rec + 0x18) end
        if ty == T.str then return str(rec + 0x18) end
        if ty == T.bool then return mr("byte", rec + 0x18) ~= 0 end
        return nil
    end

    local function moved(h)
        if not h or not h.ok or not h.cm then return false end
        if mr("uintptr", h.cm) ~= h.first then return true end
        if mr("uintptr", h.cell) ~= h.payload then return true end
        return mr("uintptr", h.payload + 24) ~= h.recs
    end

    local function attr(inst, name)
        local ok, value = pcall(function() return inst:GetAttribute(name) end)
        if ok then return value end
        return nil
    end

    local function learn(inst)
        local h = walk(inst.Address)
        if not h.ok then return false, "no attribute records" end
        local function pick(names)
            for _, n in ipairs(names) do
                local en = h.map[n]
                if en then return en.ty, n end
            end
            return nil
        end
        local tn, nn = pick({ "Health", "Money", "Kills", "Ping" })
        local ts, sn = pick({ "Team", "Armor", "CurrentEquipped" })
        local tb, bn = pick({ "Dead", "IsSpectating", "HasDefuseKit" })
        if not tn or not ts or not tb or tn == ts or tn == tb or ts == tb then return false, "types not found" end
        T.num, T.str, T.bool = tn, ts, tb
        local checked = 0
        for _, n in ipairs({ nn, sn, bn, "Money", "Health", "Team", "Dead" }) do
            local want = attr(inst, n)
            if want ~= nil then
                local got = get(h, n)
                local same = want == got
                if type(want) == "number" and type(got) == "number" then same = abs(want - got) < 1e-6 end
                if not same then
                    T.num, T.str, T.bool = nil, nil, nil
                    return false, "mismatch on " .. n
                end
                checked = checked + 1
            end
        end
        if checked < 3 then
            T.num, T.str, T.bool = nil, nil, nil
            return false, "too few values"
        end
        return true
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
        Off.fprim = grab("BasePart", "Primitive")
        Off.fpos = grab("Primitive", "Position")
        Off.fparent = grab("Instance", "Parent")
        Off.fatt = grab("Attachment", "Position")
        Off.fsound = grab("Sound", "SoundId")
        Off.fsize = grab("Primitive", "Size")
        Off.fkids = grab("Instance", "ChildrenStart")
        Off.ftrans = grab("BasePart", "Transparency")
        if missing then return false, "the offset feed has no " .. missing end
        local okv, ver = pcall(getrbxversion)
        Off.version = okv and type(ver) == "string" and #ver > 4 and string.find(text, ver, 1, true) ~= nil
        return true
    end

    local function validate(root, modelAddr)
        local okp, pos = pcall(function() return root.Position end)
        local oka, ra = pcall(function() return root.Address end)
        if not okp or not oka or not pos or not ra then return false end
        local p = ptr(ra + Off.fprim)
        local x, y, z
        if p then x, y, z = vec(p + Off.fpos) end
        local parent = mr("uintptr", modelAddr + Off.fparent)
        local wrong
        if not x or abs(x - pos.X) >= 0.05 or abs(y - pos.Y) >= 0.05 or abs(z - pos.Z) >= 0.05 then
            wrong = "position"
        elseif not parent or (parent ~= E.charsAddr and parent ~= E.culledAddr) then
            wrong = "parent"
        end
        if wrong then
            Off.bad = (Off.bad or 0) + 1
            if Off.bad >= 20 then E.fail("the " .. wrong .. " offset does not match this Roblox version") end
            return false
        end
        Off.prim, Off.pos, Off.parent, Off.ready = Off.fprim, Off.fpos, Off.fparent, true
        return true
    end

    local Seen = {}
    function E.report(err)
        local text = tostring(err)
        local now = os.clock()
        if now - (Seen[text] or -10) < 10 then return end
        Seen[text] = now
        warn("Blox Strike ESP: " .. text)
    end

    E.ptr, E.str, E.vec, E.walk, E.get, E.attr, E.moved = ptr, str, vec, walk, get, attr, moved
    E.learn, E.feed, E.validate = learn, feed, validate
end

local function EspWorld(E)
    local mr, clock, floor, match, find = memory_read, os.clock, math.floor, string.match, string.find
    local ptr, vec, walk, get, Off = E.ptr, E.vec, E.walk, E.get, E.Off
    local Service = { Players = game:GetService("Players"), Storage = game:GetService("ReplicatedStorage") }
    local LP = Service.Players.LocalPlayer
    local W = { stateAt = 0 }
    local ents, skip, list, pending = {}, {}, {}, {}
    local State = { tick = 0, cursor = 0 }
    E.W, E.list, E.pending, E.LP = W, list, pending, LP
    local moved = E.moved
    local Death = { zones = {} }
    E.Death = Death
    local bind
    local TNAME, CTNAME = "Terrorists", "Counter-Terrorists"
    local PARTS = {
        "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }
    local PIDX = {}
    for Index, Name in ipairs(PARTS) do PIDX[Name] = Index end
    local COLOR = {
        white = Color3.fromRGB(255, 255, 255), bot = Color3.fromRGB(190, 190, 190), kit = Color3.fromRGB(120, 190, 255),
        bomb = Color3.fromRGB(255, 70, 70), zoom = Color3.fromRGB(110, 200, 255), blind = Color3.fromRGB(255, 220, 90),
        act = Color3.fromRGB(255, 120, 60),
    }
    local maxRounds = {}

    local function kidsOf(inst) return inst:GetChildren() end
    local function childOf(inst, name) return inst:FindFirstChild(name) end
    local function find1(inst, name)
        if not inst then return nil end
        local ok, child = pcall(childOf, inst, name)
        if ok then return child end
        return nil
    end

    local function rootPos(ent)
        local p = ent.prim[1]
        if not p then return nil end
        return vec(p + Off.pos)
    end

    local function sample(ent, now, src)
        local x, y, z = rootPos(ent)
        if x and y > -500 then
            ent.lx, ent.ly, ent.lz = x, y, z
            ent.fx, ent.fy, ent.fz = x, y, z
            ent.seenAt, ent.from, ent.hasPos = now, src, true
        else
            ent.hasPos = false
            ent.from = "spawn"
        end
    end

    local function reset(ent, now)
        ent.everLive = false
        ent.resetAt = now
        if ent.hidden then sample(ent, now, "spawn") end
    end

    local function track(ent, now)
        local hidden
        local p = mr("uintptr", ent.addr + Off.parent)
        if p == E.culledAddr then
            hidden = true
        elseif p == E.charsAddr then
            hidden = false
        else
            ent.gone = true
            return
        end
        if hidden then
            if ent.hidden ~= true then
                ent.hidden = true
                sample(ent, now, ent.everLive and not ent.dead and "seen" or "spawn")
            end
        else
            ent.hidden = false
            ent.everLive = true
        end
    end

    local function handleVal(ent, key, addr, name)
        local h = ent[key]
        if not h then return nil end
        local x = get(h, name)
        if x == nil and h.stale and addr and clock() - h.at > 0.2 then
            h = walk(addr)
            ent[key] = h
            x = get(h, name)
        end
        return x
    end
    local function val(ent, name)
        local x
        if ent.isBot then
            x = handleVal(ent, "ma", ent.addr, name)
            if x == nil then x = handleVal(ent, "sa", ent.srcAddr, name) end
        else
            x = handleVal(ent, "sa", ent.srcAddr, name)
            if x == nil then x = handleVal(ent, "ma", ent.addr, name) end
        end
        return x
    end
    local function shaky(ent)
        local a, b = ent.sa, ent.ma
        if a == nil or b == nil then return true end
        return a.stale or b.stale or not a.ok or not b.ok
    end

    local function deathZone(x, y, z, now, name, seenAt)
        if not x then return end
        local zones = Death.zones
        if #zones >= 12 then table.remove(zones, 1) end
        local zone = { at = now, x = x, y = y, z = z, name = name, seenAt = seenAt }
        zones[#zones + 1] = zone
        if E.undoSound then E.undoSound(zone, now) end
    end

    local function died(ent, now)
        if ent.hidden then
            if ent.hasPos then
                deathZone(ent.lx, ent.ly, ent.lz, now, ent.name, ent.seenAt)
            else
                deathZone(ent.fx, ent.fy, ent.fz, now, ent.name, nil)
            end
        else
            deathZone(ent.vx, ent.vy, ent.vz, now, ent.name, nil)
        end
    end

    local function life(ent, now)
        local sh, sd = handleVal(ent, "sa", ent.srcAddr, "Health"), handleVal(ent, "sa", ent.srcAddr, "Dead")
        local mh, md = handleVal(ent, "ma", ent.addr, "Health"), handleVal(ent, "ma", ent.addr, "Dead")
        if type(sh) ~= "number" then sh = nil end
        if type(mh) ~= "number" then mh = nil end
        local hp
        if ent.isBot then hp = mh or sh else hp = sh or mh end
        if sh == nil and sd == nil and mh == nil and md == nil then return hp, ent.dead end
        local srcDead = sd == true or (sh ~= nil and sh <= 0)
        local modelDead = md == true or (mh ~= nil and mh <= 0)
        if srcDead == modelDead then return hp, srcDead end
        if modelDead then
            if sh == nil and sd == nil then return hp, true end
            if ent.hidden then
                local sg, mg = get(ent.sa, "CharacterGeneration"), get(ent.ma, "CharacterGeneration")
                if type(sg) == "number" and type(mg) == "number" and sg ~= mg then return sh or hp, false end
            end
            return hp, true
        end
        if mh == nil and md == nil then return hp, true end
        if ent.isBot then
            local cid = get(ent.ma, "CombatantId")
            if cid == nil then cid = get(ent.ma, "ActorId") end
            if type(cid) == "number" and ent.cid ~= nil and cid ~= ent.cid then
                if now - ent.bindAt > 0.3 then bind(ent, now) end
                return hp, false
            end
        end
        return sh or hp, true
    end

    local function fast(ent, now)
        if ent.hidden and not ent.dead and not ent.gone then
            local sa, ma = ent.sa, ent.ma
            if sa and now - sa.at > 0.2 and moved(sa) then ent.sa = walk(ent.srcAddr) end
            if ma and now - ma.at > 0.2 and moved(ma) then ent.ma = walk(ent.addr) end
        end
        local hp, isDead = life(ent, now)
        local mx = val(ent, "MaxHealth")
        local gen = val(ent, "CharacterGeneration")
        ent.hp = hp
        ent.maxhp = (type(mx) == "number" and mx > 0) and mx or 100
        if isDead ~= ent.dead then
            if isDead and ent.ready then died(ent, now) end
            ent.dead = isDead
            reset(ent, now)
        end
        if not isDead and not ent.hidden and not ent.gone then
            local x, y, z = rootPos(ent)
            if x then ent.vx, ent.vy, ent.vz = x, y, z end
        end
        if gen ~= nil and gen ~= ent.gen then
            if ent.gen ~= nil then
                reset(ent, now)
                if ent.ready and not ent.queued then
                    ent.stage = 0
                    ent.queued = true
                    pending[#pending + 1] = ent
                end
            end
            ent.gen = gen
        end
        if ent.hidden and not ent.dead then
            local x, y, z = rootPos(ent)
            if x then
                local moved = not ent.hasPos
                if not moved and ent.fx then
                    local dx, dy, dz = x - ent.fx, y - ent.fy, z - ent.fz
                    moved = dx * dx + dy * dy + dz * dz > 0.25
                end
                if moved and (ent.fx == nil or x ~= ent.fx or y ~= ent.fy or z ~= ent.fz) then
                    if y > -500 then
                        local fresh = ent.everLive and now - (ent.resetAt or 0) > 3 and now - W.stateAt > 3
                        ent.fx, ent.fy, ent.fz = x, y, z
                        ent.lx, ent.ly, ent.lz = x, y, z
                        ent.seenAt, ent.hasPos = now, true
                        ent.from = fresh and "seen" or "spawn"
                    else
                        ent.fx, ent.fy, ent.fz = x, y, z
                        ent.hasPos = false
                        ent.from = "spawn"
                    end
                end
            end
        end
    end

    local function slow(ent, now)
        local team = val(ent, "Team")
        if team == nil then team = val(ent, "team") end
        if team == nil then
            local cn = val(ent, "CharacterName")
            if cn ~= nil and cn == W.tchar then team = TNAME elseif cn ~= nil and cn == W.ctchar then team = CTNAME end
        end
        if team == nil and ent.team ~= nil and shaky(ent) then team = ent.team end
        ent.team = team
        local known = team == TNAME or team == CTNAME
        local my = W.myTeam
        if ent.isSelf then
            ent.enemy = false
        elseif W.mode == "Deathmatch" then
            ent.enemy = true
        elseif not known then
            ent.enemy = false
        elseif my == TNAME or my == CTNAME then
            ent.enemy = team ~= my
        else
            ent.enemy = true
        end

        local ft, fc, n = ent.ft, ent.fc, 0
        local armor = val(ent, "Armor")
        if type(armor) == "string" and armor ~= "" then
            local ah = tonumber(match(armor, "\"Health\":(%d+)")) or 0
            local kind = match(armor, "\"Type\":\"([^\"]*)\"") or ""
            if ah > 0 then
                n = n + 1
                ft[n], fc[n] = find(kind, "Helmet", 1, true) and "HK" or "K", COLOR.white
            end
        end
        if ent.isBot then
            n = n + 1
            ft[n], fc[n] = "BOT", COLOR.bot
        end
        local equipped = val(ent, "CurrentEquipped")
        local weapon, rounds, capacity
        if type(equipped) == "string" and equipped ~= "" then
            weapon = match(equipped, "\"Name\":\"([^\"]*)\"")
            rounds = tonumber(match(equipped, "\"Rounds\":(%d+)"))
            capacity = tonumber(match(equipped, "\"Capacity\":(%d+)"))
        end
        if ent.isBot and not ent.dead then
            local wn = val(ent, "WeaponName")
            if type(wn) == "string" and wn ~= "" and weapon == nil then weapon = wn end
        end
        if weapon == "" or ent.dead then weapon = nil end
        ent.weapon = weapon
        if weapon and rounds then
            local top = maxRounds[weapon]
            if not top or rounds > top then
                top = rounds
                maxRounds[weapon] = top
            end
            ent.ammoFrac = top > 0 and rounds / top or 0
            if rounds ~= ent.rounds or capacity ~= ent.capacity then
                ent.ammoText = capacity and (rounds .. "/" .. capacity) or tostring(rounds)
            end
        else
            ent.ammoFrac, ent.ammoText = nil, nil
        end
        ent.rounds, ent.capacity = rounds, capacity
        if weapon and rounds then
            if ent.heldW ~= weapon then
                ent.prevW, ent.prevR, ent.prevC, ent.prevAt = ent.heldW, ent.heldR, ent.heldC, now
            end
            ent.heldW, ent.heldR, ent.heldC, ent.heldAt = weapon, rounds, capacity, now
        end
        local money = val(ent, "Money")
        if type(money) == "number" then
            if money ~= ent.money then ent.moneyText = "$" .. floor(money + 0.5) end
        else
            ent.moneyText = nil
        end
        ent.money = money
        if val(ent, "HasDefuseKit") == true then
            n = n + 1
            ft[n], fc[n] = "KIT", COLOR.kit
        end
        local slot5 = val(ent, "Slot5")
        if weapon == "C4" or (type(slot5) == "string" and find(slot5, "\"Weapon\":\"C4\"", 1, true)) then
            n = n + 1
            ft[n], fc[n] = "C4", COLOR.bomb
        end
        local scope = val(ent, "ScopeIncrement")
        if type(scope) == "number" and scope > 0 then
            n = n + 1
            ft[n], fc[n] = "ZOOM", COLOR.zoom
        end
        local flashed = val(ent, "FlashedUntil")
        if type(flashed) == "number" and flashed > os.time() then
            n = n + 1
            ft[n], fc[n] = "BLIND", COLOR.blind
        end
        local action = val(ent, "ObjectiveAction")
        if type(action) ~= "string" then action = "" end
        if val(ent, "IsDefusingBomb") == true or find(action, "Defus", 1, true) then
            n = n + 1
            ft[n], fc[n] = "DEFUSE", COLOR.act
        elseif val(ent, "IsPlantingBomb") == true or find(action, "Plant", 1, true) then
            n = n + 1
            ft[n], fc[n] = "PLANT", COLOR.act
        end
        if n > 6 then n = 6 end
        ent.fn = n
    end

    function bind(ent, now)
        ent.bindAt = now
        local src
        if ent.isSelf then
            src = LP
        elseif not ent.isBot then
            src = find1(Service.Players, ent.name)
            if not src and get(ent.ma, "Bot") == true then ent.isBot = true end
        end
        if ent.isBot then
            local cid = get(ent.ma, "CombatantId")
            if cid == nil then cid = get(ent.ma, "ActorId") end
            if type(cid) == "number" then ent.cid = cid end
            if ent.cid then src = find1(E.combatants, string.format("%d", ent.cid)) end
        end
        if not src then
            ent.srcAddr, ent.sa = nil, nil
            if not ent.isBot or E.combatants then
                ent.lostN = (ent.lostN or 0) + 1
                if ent.lostN == 2 then ent.lost = true end
            end
            return
        end
        ent.lostN, ent.lost = 0, false
        local ok, a = pcall(function() return src.Address end)
        if not ok or not a then return end
        if a ~= ent.srcAddr then
            ent.srcAddr = a
            ent.sa = walk(a)
        end
    end

    local function drop(a, ent)
        ents[a] = nil
        if ent.ready and not ent.dead then died(ent, clock()) end
        ent.dropped = true
        ent.ready = false
        if ent.slot then
            E.freeSlot(ent.slot)
            ent.slot = nil
        end
        for i = #list, 1, -1 do
            if list[i] == ent then table.remove(list, i) end
        end
    end

    local function folders()
        local chars = find1(workspace, "Characters")
        local culled = find1(Service.Storage, "_PVS_CulledCharacters")
        E.chars, E.culled = chars, culled
        E.charsAddr = chars and chars.Address or nil
        E.culledAddr = culled and culled.Address or nil
        E.combatants = find1(Service.Storage, "Combatants")
        local cam = workspace.CurrentCamera
        E.cam = cam
        if cam then
            local size = cam.ViewportSize
            if size and size.X > 100 then E.vw, E.vh = size.X, size.Y end
        end
    end

    local function roster(now)
        State.tick = State.tick + 1
        local tick = State.tick
        for index = 1, 2 do
            local folder = index == 1 and E.chars or E.culled
            local ok, kids = false, nil
            if folder then ok, kids = pcall(kidsOf, folder) end
            if ok and type(kids) == "table" then
                for i = 1, #kids do
                    local child = kids[i]
                    local a = child.Address
                    if a then
                        local ent = ents[a]
                        if ent then
                            ent.tick = tick
                            ent.gone = false
                        elseif skip[a] then
                            skip[a] = tick
                        elseif child.ClassName == "Model" then
                            ent = {
                                model = child, addr = a, stage = 0, prim = {}, ft = {}, fc = {}, fn = 0,
                                tick = tick, resetAt = now, tries = 0, bindAt = 0, queued = true,
                                dead = false, maxhp = 100,
                            }
                            ents[a] = ent
                            pending[#pending + 1] = ent
                        else
                            skip[a] = tick
                        end
                    end
                end
            end
        end
        for a, ent in pairs(ents) do
            if ent.tick ~= tick then drop(a, ent) end
        end
        for a, seen in pairs(skip) do
            if seen ~= tick then skip[a] = nil end
        end
    end

    local function resolve(now)
        local ent = pending[1]
        if ent.dropped then
            table.remove(pending, 1)
            return false
        end
        if ent.retryAt and now < ent.retryAt then
            table.remove(pending, 1)
            pending[#pending + 1] = ent
            return false
        end
        local stage = ent.stage
        if stage == 0 then
            local model = ent.model
            if not ent.name then
                ent.name = model.Name
                ent.isSelf = ent.name == LP.Name
            end
            ent.kids, ent.ki, ent.parts, ent.found, ent.newRoot = kidsOf(model), 1, {}, 0, nil
            ent.stage = 1
        elseif stage == 1 then
            local kids, parts = ent.kids, ent.parts
            local i, count = ent.ki, #kids
            local limit = clock() + 0.0006
            while i <= count and ent.found < 16 do
                local child = kids[i]
                local index = PIDX[child.Name]
                if index and not parts[index] then
                    parts[index] = child.Address
                    ent.found = ent.found + 1
                    if index == 1 then ent.newRoot = child end
                end
                i = i + 1
                if clock() > limit then break end
            end
            ent.ki = i
            if i > count or ent.found >= 16 then
                local root = ent.newRoot
                ent.kids, ent.newRoot = nil, nil
                if not root then
                    ent.tries = ent.tries + 1
                    ent.retryAt = now + (ent.tries > 20 and 5 or 0.3)
                    ent.stage = 0
                    return true
                end
                if not Off.ready and not E.validate(root, ent.addr) then
                    ent.retryAt = now + 0.3
                    ent.stage = 0
                    return true
                end
                local prim = {}
                for k = 1, 16 do
                    local pa = parts[k]
                    prim[k] = pa and ptr(pa + Off.prim) or nil
                end
                ent.prim = prim
                ent.parts = nil
                ent.bad = 0
                ent.stage = ent.ready and 6 or 2
            end
        elseif stage == 2 then
            ent.ma = walk(ent.addr)
            ent.isBot = get(ent.ma, "Bot") == true
            ent.cid = ent.isBot and get(ent.ma, "CombatantId") or nil
            if ent.isBot and ent.cid == nil then ent.cid = get(ent.ma, "ActorId") end
            ent.stage = 3
        elseif stage == 3 then
            bind(ent, now)
            ent.stage = 4
        elseif stage == 4 then
            if not ent.slot then ent.slot = E.takeSlot() end
            if E.buildSlot(ent.slot) then ent.stage = 5 end
        elseif stage == 5 then
            fast(ent, now)
            slow(ent, now)
            track(ent, now)
            ent.ready = true
            list[#list + 1] = ent
            ent.stage = 6
        end
        if ent.stage == 6 then
            ent.queued = false
            table.remove(pending, 1)
        end
        return true
    end

    local function world(now)
        local h = W.lp
        if not h or h.stale or now - h.at > 5 then
            W.lp = walk(LP.Address)
        elseif not W.ws or W.ws.stale or now - W.ws.at > 10 then
            W.ws = walk(workspace.Address)
        end
        local team = get(W.lp, "Team")
        if team == nil then team = get(W.lp, "team") end
        if team ~= nil or (W.lp.ok and not W.lp.stale) then W.myTeam = team end
        local gs, mode = get(W.ws, "GameState"), get(W.ws, "Gamemode")
        W.tchar, W.ctchar = get(W.ws, "TCharacter"), get(W.ws, "CTCharacter")
        if gs == nil then gs = W.state end
        if mode == nil then mode = W.mode end
        W.mode = mode
        if gs ~= W.state then
            W.state = gs
            W.stateAt = now
            for i = 1, #list do reset(list[i], now) end
        end
    end

    local function slot(now)
        State.cursor = State.cursor + 1
        if State.cursor > #list then State.cursor = 0 end
        if State.cursor == 0 then
            world(now)
            return
        end
        local ent = list[State.cursor]
        if not ent or not ent.ready then return end
        if now - ent.bindAt > 2 then
            bind(ent, now)
        else
            local key, h, addr = "ma", ent.ma, ent.addr
            local sa = ent.sa
            if sa and (sa.stale or not h or (not h.stale and sa.at < h.at)) then key, h, addr = "sa", sa, ent.srcAddr end
            if ent.srcAddr and not sa then
                ent.sa = walk(ent.srcAddr)
            elseif not h or h.stale or not h.ok or now - h.at > 1.5 then
                ent[key] = walk(addr)
            end
        end
        slow(ent, now)
    end

    local function quick(now)
        for i = 1, #list do
            local ent = list[i]
            if ent.ready then
                track(ent, now)
                fast(ent, now)
                if not ent.hidden and not ent.gone and (ent.bad or 0) > 30 and not ent.queued then
                    ent.stage = 0
                    ent.queued = true
                    pending[#pending + 1] = ent
                end
            end
        end
    end

    E.rootPos, E.track, E.roster, E.resolve, E.slot, E.quick, E.find1 = rootPos, track, roster, resolve, slot, quick, find1
    E.world, E.folders, E.deathZone = world, folders, deathZone
end

local function EspSound(E)
    local sqrt, log, min, sub = math.sqrt, math.log, math.min, string.sub
    local vec, str, Off, rootPos, list = E.vec, E.str, E.Off, E.rootPos, E.list
    local S = { on = false, voices = {}, byAddr = {}, kind = {}, known = 0, good = 0, scanAt = -10, pass = 0, i = 1 }
    local NOT_PLAYER = {
        Interface = true, Store = true, Miscellaneous = true, Terrorists = true, ["Counter-Terrorists"] = true,
        ["Main Menu"] = true, Deathmatch = true, Cutout = true, Finishers = true, Tutorial = true, Grenade = true,
        BreakableDoor = true, Bullet = true, Round = true, ArmsDealer = true, Hostage = true, Survival = true,
        ZombieSurvival = true, C4 = true, Flashbang = true, Molotov = true, Incendiary = true,
    }
    local roots = { n = 0 }

    local function soundKind(top, second)
        if top == "FloorSounds" then return "step" end
        if top == "Character" then
            if second == "Fall Damage" then return "step" end
            if second == "Character Death Grunt" then return "death" end
            return nil
        end
        if not top or NOT_PLAYER[top] or string.find(top, "Grenade", 1, true) then return nil end
        if second == "Shoot" then return "shot" end
        return "gear"
    end

    local function catalogue()
        if not Off.version then return end
        local root = E.find1(game:GetService("ReplicatedStorage"), "Sounds")
        if not root then return end
        local stack = { { root, nil, nil, 0 } }
        local budget = 0
        while #stack > 0 and E.alive do
            local node = table.remove(stack)
            local kids = node[1]:GetChildren()
            local depth = node[4]
            for i = 1, #kids do
                local child = kids[i]
                local name, class = child.Name, child.ClassName
                local top, second = node[2], node[3]
                if depth == 0 then top = name elseif depth == 1 then second = name end
                if class == "Sound" then
                    local id = str(child.Address + Off.fsound)
                    if id and id ~= "" then
                        if S.kind[id] ~= "death" then S.kind[id] = soundKind(top, second) or false end
                        S.known = S.known + 1
                        if sub(id, 1, 13) == "rbxassetid://" then S.good = S.good + 1 end
                    end
                elseif depth < 6 then
                    stack[#stack + 1] = { child, top, second, depth + 1 }
                end
                budget = budget + 1
                if budget >= 8 then
                    budget = 0
                    task.wait(0.03)
                    if not E.alive then return end
                end
            end
        end
        S.on = S.good > 0 and S.good >= S.known * 0.9
    end

    local DEATH_R2, DEATH_T, UNDO_T = 25, 2.5, 1.2

    function E.undoSound(zone, now)
        for i = 1, #list do
            local ent = list[i]
            local at = ent.sAt
            if at and now - at < UNDO_T and ent.seenAt == at and ent.hidden and ent.uAt and ent.name ~= zone.name then
                local dx, dy, dz = ent.lx - zone.x, ent.ly - zone.y, ent.lz - zone.z
                if dx * dx + dy * dy + dz * dz < DEATH_R2 then
                    ent.lx, ent.ly, ent.lz = ent.ux, ent.uy, ent.uz
                    ent.seenAt, ent.from = ent.uSeen, ent.uFrom
                    ent.sAt = nil
                end
            end
        end
    end

    local function onSound(px, py, pz, kind, now)
        if kind == "death" then
            E.deathZone(px, py, pz, now, nil, nil)
            return
        end
        if roots.at ~= now then
            roots.at = now
            local n = 0
            local low = 1e9
            for i = 1, #list do
                local ent = list[i]
                if ent.ready and not ent.hidden and not ent.gone and not ent.dead then
                    local x, y, z = rootPos(ent)
                    if x then
                        roots[n + 1], roots[n + 2], roots[n + 3] = x, y, z
                        n = n + 3
                        if y < low then low = y end
                    end
                elseif ent.ready and ent.hidden and ent.hasPos and ent.fy and ent.fy < low then
                    low = ent.fy
                end
            end
            roots.n = n
            roots.low = low
        end
        if py < roots.low - 25 then return end
        for i = 1, roots.n, 3 do
            local dx, dz = px - roots[i], pz - roots[i + 2]
            local dy = py - roots[i + 1]
            if dx * dx + dz * dz < 16 and dy < 7 and dy > -7 then return end
        end
        local zones = E.Death.zones
        local ghost, ghostScore
        for i = #zones, 1, -1 do
            local zone = zones[i]
            if now - zone.at > DEATH_T then
                table.remove(zones, i)
            else
                local dx, dy, dz = px - zone.x, py - zone.y, pz - zone.z
                local d2 = dx * dx + dy * dy + dz * dz
                if d2 < DEATH_R2 then return end
                if zone.seenAt then
                    local age = now - zone.seenAt
                    local d = sqrt(d2)
                    if d <= min(6 + 24 * age, 150) then
                        local spread = 4 + 10 * age
                        local score = 2 * log(spread) + d2 / (2 * spread * spread)
                        if not ghost or score < ghostScore then ghost, ghostScore = zone, score end
                    end
                end
            end
        end
        local best, bestScore
        for i = 1, #list do
            local ent = list[i]
            if ent.ready and ent.hidden and ent.hasPos and not ent.dead and not ent.isSelf and not ent.lost then
                local age = now - ent.seenAt
                local dx, dy, dz = px - ent.lx, py - ent.ly, pz - ent.lz
                local d = sqrt(dx * dx + dy * dy + dz * dz)
                if d <= min(6 + 24 * age, 150) then
                    local spread = 4 + 10 * age
                    local score = 2 * log(spread) + d * d / (2 * spread * spread)
                    if not best or score < bestScore then best, bestScore = ent, score end
                end
            end
        end
        if ghost and (not best or ghostScore < bestScore) then return end
        if best then
            if now - (best.uAt or -10) > UNDO_T then
                best.ux, best.uy, best.uz = best.lx, best.ly, best.lz
                best.uSeen, best.uFrom, best.uAt = best.seenAt, best.from, now
            end
            best.sAt = now
            best.lx, best.ly, best.lz = px, py, pz
            best.seenAt, best.from = now, kind
        end
    end

    local function poll(now)
        if not S.on then return end
        local voices = S.voices
        local ao = Off.fatt
        for i = 1, #voices do
            local v = voices[i]
            local x, y, z = vec(v.att + ao)
            if x then
                local lx = v.x
                if lx then
                    local dx, dy, dz = x - lx, y - v.y, z - v.z
                    if dx * dx + dy * dy + dz * dz > 0.0025 then
                        local id = v.snd and str(v.snd + Off.fsound)
                        local kind = id and S.kind[id]
                        if kind then onSound(x, y, z, kind, now) end
                    end
                end
                v.x, v.y, v.z = x, y, z
            end
        end
    end

    local function voiceStep(now)
        if not S.on then return end
        if not S.scan then
            if now - S.scanAt < 5 then return end
            S.scanAt = now
            local terrain = E.find1(workspace, "Terrain")
            if not terrain then return end
            S.scan = terrain:GetChildren()
            S.i = 1
            S.pass = S.pass + 1
            return
        end
        local kids, n = S.scan, 0
        while S.i <= #kids and n < 6 do
            local child = kids[S.i]
            S.i = S.i + 1
            local a = child.Address
            if a then
                local v = S.byAddr[a]
                if v == nil then
                    n = n + 3
                    if child.Name == "SoundVoice" then
                        local snd = child:FindFirstChild("Sound")
                        v = { att = a, snd = snd and snd.Address or nil }
                    else
                        v = { skip = true }
                    end
                    S.byAddr[a] = v
                else
                    n = n + 1
                end
                v.pass = S.pass
            end
        end
        if S.i > #kids then
            S.scan = nil
            local voices = {}
            for a, v in pairs(S.byAddr) do
                if v.pass ~= S.pass then
                    S.byAddr[a] = nil
                elseif not v.skip then
                    voices[#voices + 1] = v
                end
            end
            S.voices = voices
        end
    end

    E.catalogue, E.poll, E.voiceStep = catalogue, poll, voiceStep
end

local function EspDraw(E)
    local Cfg, Off, list = E.Cfg, E.Off, E.list
    local W2S, V3 = WorldToScreen, Vector3.new
    local floor, sqrt, clock = math.floor, math.sqrt, os.clock
    local vec, track, rootPos = E.vec, E.track, E.rootPos
    local WHITE, BLACK, GREY = Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(150, 150, 150)
    local MONEY = Color3.fromRGB(150, 200, 60)
    local FONT = (Drawing.Fonts and Drawing.Fonts.UI) or 0
    local DORMANT_TIME = 20
    local BA = { 2, 3, 3, 5, 6, 3, 8, 9, 4, 11, 12, 4, 14, 15 }
    local BB = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 }
    local R = {
        last = 0, frame = 0, basisFrame = -1, camAt = 0, cx = 0, cy = 0, cz = 0, fitAt = 0, fitX = {}, fitY = {},
        shown = false,
    }
    E.R = R
    local slots, free = {}, {}
    local box = { 0, 0, 0, 0 }
    local DIST, hpCache = {}, { color = nil }
    local P = { x = 0, y = 0 }
    local Draw = {}
    E.D = Draw

    local Shadows = {}
    local Z = { fix = nil, n = 200 }
    local function nextZ()
        if Z.fix then return Z.fix end
        if Z.n < 996 then Z.n = Z.n + 2 end
        return Z.n
    end
    local SHX = { -1, 1, 0, 0 }
    local SHY = { 0, 0, -1, 1 }
    local function shadowSync(d)
        local sh = d.sh
        if not sh then return end
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
    local function shadowMake(size, center, z)
        local sh = {}
        for i = 1, 4 do
            local o = Drawing.new("Text")
            o.Visible = false
            o.ZIndex = z - 1
            o.Size = size
            o.Center = center
            o.Outline = false
            o.Font = FONT
            o.Color = BLACK
            sh[i] = o
            Shadows[#Shadows + 1] = o
        end
        sh.vis = false
        return sh
    end

    local function vis(d, v)
        if d.vis ~= v then
            d.vis = v
            d.o.Visible = v
            if d.sh then shadowSync(d) end
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
    local function pos(d, x, y)
        if d.x ~= x or d.y ~= y then
            d.x, d.y = x, y
            P.x, P.y = x, y
            d.o.Position = P
            if d.shOn then shadowSync(d) end
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
            if d.text then
                local outline = a >= 0.995
                if d.ol ~= outline then
                    d.ol = outline
                    d.o.Outline = outline
                    d.shOn = not outline
                end
                if d.sh then shadowSync(d) end
            end
        end
    end
    local function txt(d, s)
        if d.s ~= s then
            d.s = s
            d.o.Text = s
            if d.shOn then shadowSync(d) end
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

    local function square(filled, color)
        local o = Drawing.new("Square")
        o.Visible = false
        o.ZIndex = nextZ()
        o.Filled = filled
        o.Thickness = 1
        o.Color = color
        return { o = o, vis = false, c = color }
    end
    local function text(size, center)
        local z = nextZ()
        local sh = shadowMake(size, center, z)
        local o = Drawing.new("Text")
        o.Visible = false
        o.ZIndex = z
        o.Size = size
        o.Center = center
        o.Outline = true
        o.Font = FONT
        o.Color = WHITE
        return { o = o, vis = false, c = WHITE, text = true, ol = true, sh = sh }
    end
    local function line()
        local o = Drawing.new("Line")
        o.Visible = false
        o.ZIndex = nextZ()
        o.Thickness = 1
        o.Color = WHITE
        return { o = o, vis = false, c = WHITE }
    end

    local SPEC = {}
    do
        local function add(field, kind, a, b, index)
            SPEC[#SPEC + 1] = { field, kind, a, b, index }
        end
        add("boxO", "square", false, BLACK)
        add("boxI", "square", false, BLACK)
        add("box", "square", false, WHITE)
        for i = 1, 8 do add("cb", "square", true, BLACK, i) end
        for i = 1, 8 do add("cf", "square", true, WHITE, i) end
        add("hpB", "square", true, BLACK)
        add("hpF", "square", true, WHITE)
        add("amB", "square", true, BLACK)
        add("amF", "square", true, WHITE)
        add("name", "text", 13, true)
        add("dist", "text", 13, true)
        add("weap", "text", 13, true)
        add("ammo", "text", 13, true)
        for i = 1, 7 do add("fl", "text", 12, false, i) end
        for i = 1, 14 do add("bone", "line", nil, nil, i) end
    end

    local function newSlot()
        local s = { on = false, all = {}, px = {}, py = {}, pok = {}, fl = {}, bone = {}, cb = {}, cf = {}, step = 1 }
        slots[#slots + 1] = s
        s.par = #slots % 2
        return s
    end

    function E.buildSlot(s)
        local limit = clock() + 0.0006
        local all = s.all
        while s.step <= #SPEC do
            local spec = SPEC[s.step]
            local d
            Z.fix = s.step * 2
            if spec[2] == "square" then
                d = square(spec[3], spec[4])
            elseif spec[2] == "text" then
                d = text(spec[3], spec[4])
            else
                d = line()
            end
            Z.fix = nil
            all[#all + 1] = d
            if spec[5] then s[spec[1]][spec[5]] = d else s[spec[1]] = d end
            s.step = s.step + 1
            if clock() > limit then break end
        end
        return s.step > #SPEC
    end

    local function hide(s)
        s.rel = false
        if not s.on then return end
        s.on = false
        local all = s.all
        for i = 1, #all do
            local d = all[i]
            if d.vis then vis(d, false) end
        end
    end

    function E.takeSlot()
        return table.remove(free) or newSlot()
    end
    function E.freeSlot(s)
        hide(s)
        free[#free + 1] = s
    end
    function E.hideAll()
        for i = 1, #slots do hide(slots[i]) end
    end
    function E.removeAll()
        for i = 1, #slots do
            local all = slots[i].all
            for k = 1, #all do
                local o = all[k].o
                pcall(function() o.Visible = false end)
                pcall(function() o:Remove() end)
            end
            slots[i].all = {}
        end
        slots, free = {}, {}
        for i = 1, #Shadows do
            local o = Shadows[i]
            pcall(function() o.Visible = false end)
            pcall(function() o:Remove() end)
        end
        Shadows = {}
    end

    E.cornerQ = {}

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

    local function basis()
        if R.basisFrame == R.frame then return R.basisOk end
        R.basisFrame = R.frame
        R.basisOk = false
        local cam = E.cam
        if not cam then return false end
        local cf = cam.CFrame
        if not cf then return false end
        local p, r, u, l = cf.Position, cf.RightVector, cf.UpVector, cf.LookVector
        local ux, uy, uz = u.X, u.Y, u.Z
        local ul = sqrt(ux * ux + uy * uy + uz * uz)
        if ul < 0.01 then return false end
        R.bx, R.by, R.bz = p.X, p.Y, p.Z
        R.rx, R.ry, R.rz = r.X, r.Y, r.Z
        R.ux, R.uy, R.uz = ux / ul, uy / ul, uz / ul
        R.lx, R.ly, R.lz = l.X, l.Y, l.Z
        R.basisOk = true
        return true
    end

    local function median(ring)
        local copy = {}
        for i = 1, #ring do copy[i] = ring[i] end
        table.sort(copy)
        return copy[floor((#copy + 1) / 2)]
    end

    local function fit(x, y, z, sx, sy, now)
        R.fitAt = now
        if not basis() then return end
        local hw, hh = (E.vw or 1920) / 2, (E.vh or 1080) / 2
        local dx, dy, dz = x - R.bx, y - R.by, z - R.bz
        local zz = dx * R.lx + dy * R.ly + dz * R.lz
        if zz < 1 then return end
        local xx = dx * R.rx + dy * R.ry + dz * R.rz
        local yy = dx * R.ux + dy * R.uy + dz * R.uz
        local ax, ay = xx / zz, yy / zz
        if ax > 0.05 or ax < -0.05 then
            local f = (sx - hw) / ax
            if f > 200 and f < 6000 then
                local ring = R.fitX
                ring[#ring + 1] = f
                if #ring > 9 then table.remove(ring, 1) end
                if #ring >= 3 then R.fx = median(ring) end
            end
        end
        if ay > 0.05 or ay < -0.05 then
            local f = (hh - sy) / ay
            if f > 200 and f < 6000 then
                local ring = R.fitY
                ring[#ring + 1] = f
                if #ring > 9 then table.remove(ring, 1) end
                if #ring >= 3 then R.fy = median(ring) end
            end
        end
    end

    local function project(x, y, z)
        local s, on = W2S(V3(x, y, z))
        if on then return s.X, s.Y, true end
        if R.fx and R.fy and basis() then
            local dx, dy, dz = x - R.bx, y - R.by, z - R.bz
            local zz = dx * R.lx + dy * R.ly + dz * R.lz
            if zz > 0.3 then
                local xx = dx * R.rx + dy * R.ry + dz * R.rz
                local yy = dx * R.ux + dy * R.uy + dz * R.uz
                return (E.vw or 1920) / 2 + xx / zz * R.fx, (E.vh or 1080) / 2 - yy / zz * R.fy, true
            end
        end
        return 0, 0, false
    end

    Draw.vis, Draw.rect, Draw.pos, Draw.col, Draw.alp, Draw.txt, Draw.seg = vis, rect, pos, col, alp, txt, seg
    Draw.square, Draw.text, Draw.line, Draw.basis, Draw.fit, Draw.DIST = square, text, line, basis, fit, DIST

    local function grow(sx, sy)
        if sx < box[1] then box[1] = sx end
        if sx > box[2] then box[2] = sx end
        if sy < box[3] then box[3] = sy end
        if sy > box[4] then box[4] = sy end
    end

    local function drawEnt(ent, now)
        local s = ent.slot
        if not s then return end
        if not ent.ready or ent.dead or ent.isSelf or (not ent.enemy and not Cfg.team) then
            hide(s)
            return
        end
        track(ent, now)
        if ent.gone then
            hide(s)
            return
        end
        local dormant = ent.hidden == true
        local x, y, z
        local fade = 1
        if dormant then
            if not Cfg.dormant or not ent.hasPos or ent.from == "spawn" or ent.lost then
                hide(s)
                return
            end
            local age = now - ent.seenAt
            if age > DORMANT_TIME then
                hide(s)
                return
            end
            fade = floor((0.85 - 0.7 * age / DORMANT_TIME) * 20 + 0.5) / 20
            x, y, z = ent.lx, ent.ly, ent.lz
        else
            x, y, z = rootPos(ent)
            if not x then
                ent.bad = (ent.bad or 0) + 1
                hide(s)
                return
            end
        end
        local dx, dy, dz = x - R.cx, y - R.cy, z - R.cz
        local range = sqrt(dx * dx + dy * dy + dz * dz)
        if range < 2.5 then
            hide(s)
            return
        end
        local rs, ron = W2S(V3(x, y, z))
        if not ron then
            hide(s)
            return
        end
        local rsx, rsy = rs.X, rs.Y
        if now - R.fitAt > 0.1 then fit(x, y, z, rsx, rsy, now) end

        local px, py, pok = s.px, s.py, s.pok
        local have = false
        local light = false
        local x0, y0, x1, y1
        if not dormant and s.rel and s.relFrame == R.frame - 1 and (R.frame + s.par) % 2 == 1 then
            x0, x1, y0, y1 = rsx + s.rx0, rsx + s.rx1, rsy + s.ry0, rsy + s.ry1
            have, light = true, true
        elseif not dormant then
            local prim, po = ent.prim, Off.pos
            local n = 0
            box[1], box[2], box[3], box[4] = 1e9, -1e9, 1e9, -1e9
            for i = 2, 16 do
                local p = prim[i]
                local ok = false
                if p then
                    local ax, ay, az = vec(p + po)
                    if ax then
                        local sx, sy, on = project(ax, ay, az)
                        if on then
                            ok = true
                            px[i], py[i] = sx, sy
                            n = n + 1
                            grow(sx, sy)
                            if i == 2 then
                                local tx, ty, ton = project(ax, ay + 0.75, az)
                                if ton then grow(tx, ty) end
                            elseif i == 13 or i == 16 then
                                local tx, ty, ton = project(ax, ay - 0.3, az)
                                if ton then grow(tx, ty) end
                            end
                        end
                    else
                        ent.bad = (ent.bad or 0) + 1
                    end
                end
                pok[i] = ok
            end
            if n >= 3 then
                local w, h = box[2] - box[1], box[4] - box[3]
                local pad = w * 0.08 + h * 0.03
                x0, x1, y0, y1 = box[1] - pad, box[2] + pad, box[3], box[4]
                local least = h * 0.3
                if x1 - x0 < least then
                    local mid = (x0 + x1) / 2
                    x0, x1 = mid - least / 2, mid + least / 2
                end
                have = true
                s.rel, s.relFrame = true, R.frame
                s.rx0, s.rx1, s.ry0, s.ry1 = x0 - rsx, x1 - rsx, y0 - rsy, y1 - rsy
                if n >= 12 then ent.bad = 0 end
            else
                s.rel = false
            end
        else
            s.rel = false
            for i = 2, 16 do pok[i] = false end
        end
        if not have then
            local tx, ty, ton = project(x, y + 2.15, z)
            local bx2, by2, bon = project(x, y - 3.05, z)
            if not ton or not bon then
                hide(s)
                return
            end
            local h = by2 - ty
            local w = h * 0.5
            local mid = (tx + bx2) / 2
            x0, x1, y0, y1 = mid - w / 2, mid + w / 2, ty, by2
        end
        local bx, by = floor(x0 + 0.5), floor(y0 + 0.5)
        local bw, bh = floor(x1 - x0 + 0.5), floor(y1 - y0 + 0.5)
        if bw < 2 then bw = 2 end
        if bh < 3 then
            hide(s)
            return
        end
        s.on = true
        local mid = bx + floor(bw / 2)

        if Cfg.box and Cfg.box_corners then
            local a = dormant and fade or Cfg.box_alpha
            local c = dormant and GREY or Cfg.box_color
            local lw, lh = floor(bw / 4), floor(bh / 4)
            if lw < 3 then lw = 3 end
            if lh < 3 then lh = 3 end
            local rx, ry = bx + bw - 1, by + bh - 1
            local cb, cf = s.cb, s.cf
            local q = E.cornerQ
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
                local d = cb[i]
                rect(d, q[k + 1] - 1, q[k + 2] - 1, q[k + 3] + 2, q[k + 4] + 2)
                alp(d, a)
                vis(d, true)
                d = cf[i]
                rect(d, q[k + 1], q[k + 2], q[k + 3], q[k + 4])
                col(d, c)
                alp(d, a)
                vis(d, true)
            end
            vis(s.box, false)
            vis(s.boxO, false)
            vis(s.boxI, false)
        elseif Cfg.box then
            local cb, cf = s.cb, s.cf
            for i = 1, 8 do
                vis(cb[i], false)
                vis(cf[i], false)
            end
            local a = dormant and fade or Cfg.box_alpha
            local d = s.box
            rect(d, bx, by, bw, bh)
            col(d, dormant and GREY or Cfg.box_color)
            alp(d, a)
            vis(d, true)
            d = s.boxO
            rect(d, bx - 1, by - 1, bw + 2, bh + 2)
            alp(d, a)
            vis(d, true)
            d = s.boxI
            rect(d, bx + 1, by + 1, bw - 2, bh - 2)
            alp(d, a)
            vis(d, true)
        else
            vis(s.box, false)
            vis(s.boxO, false)
            vis(s.boxI, false)
            local cb, cf = s.cb, s.cf
            for i = 1, 8 do
                vis(cb[i], false)
                vis(cf[i], false)
            end
        end

        local hp = ent.hp
        if Cfg.health and hp then
            local frac = hp / ent.maxhp
            if frac > 1 then frac = 1 elseif frac < 0 then frac = 0 end
            local fh = floor(bh * frac + 0.5)
            local a = dormant and fade or Cfg.health_alpha
            local d = s.hpB
            rect(d, bx - 6, by - 1, 4, bh + 2)
            alp(d, a)
            vis(d, true)
            d = s.hpF
            rect(d, bx - 5, by + bh - fh, 2, fh)
            col(d, dormant and GREY or hpColor(frac))
            alp(d, a)
            vis(d, true)
        else
            vis(s.hpB, false)
            vis(s.hpF, false)
        end

        if Cfg.name then
            local d = s.name
            txt(d, ent.name)
            pos(d, mid, by - 12)
            col(d, dormant and GREY or Cfg.name_color)
            alp(d, dormant and fade or Cfg.name_alpha)
            vis(d, true)
        else
            vis(s.name, false)
        end

        local yb = by + bh + 2
        if Cfg.ammobar and ent.ammoFrac then
            local a = dormant and fade or Cfg.ammobar_alpha
            local fw = floor(bw * ent.ammoFrac + 0.5)
            local d = s.amB
            rect(d, bx - 1, yb, bw + 2, 4)
            alp(d, a)
            vis(d, true)
            d = s.amF
            rect(d, bx, yb + 1, fw, 2)
            col(d, dormant and GREY or Cfg.ammobar_color)
            alp(d, a)
            vis(d, fw > 0)
            yb = yb + 11
        else
            vis(s.amB, false)
            vis(s.amF, false)
            yb = by + bh + 8
        end
        if Cfg.distance then
            local feet = floor(range * 0.28 + 0.5)
            local label = DIST[feet]
            if not label then
                label = feet .. "m"
                DIST[feet] = label
            end
            local d = s.dist
            txt(d, label)
            pos(d, mid, yb)
            col(d, dormant and GREY or WHITE)
            alp(d, fade)
            vis(d, true)
            yb = yb + 12
        else
            vis(s.dist, false)
        end
        local wd = s.wicon
        local wic = nil
        if Cfg.wicon and Cfg.get_icons and ent.weapon and E.iconOf then wic = E.iconOf(ent.weapon) end
        if wic then
            if not wd then
                local o = Drawing.new("Image")
                o.Visible = false
                o.ZIndex = 190
                wd = { o = o, vis = false }
                s.wicon = wd
                s.all[#s.all + 1] = wd
            end
            if s.wiconOf ~= wic then
                s.wiconOf = wic
                wd.o.Data = wic.data
            end
            rect(wd, mid - floor(wic.w / 2), yb - 3, wic.w, wic.h)
            col(wd, dormant and GREY or Cfg.wicon_color)
            alp(wd, dormant and fade or Cfg.wicon_alpha)
            vis(wd, true)
            yb = yb + wic.h + 4
        elseif wd then
            vis(wd, false)
        end
        if Cfg.weapon and ent.weapon then
            local d = s.weap
            txt(d, ent.weapon)
            pos(d, mid, yb)
            col(d, dormant and GREY or WHITE)
            alp(d, fade)
            vis(d, true)
            yb = yb + 12
        else
            vis(s.weap, false)
        end
        if Cfg.ammo and ent.ammoText then
            local d = s.ammo
            txt(d, ent.ammoText)
            pos(d, mid, yb)
            col(d, dormant and GREY or Cfg.ammo_color)
            alp(d, dormant and fade or Cfg.ammo_alpha)
            vis(d, true)
        else
            vis(s.ammo, false)
        end

        local k = 0
        local fl = s.fl
        local fx, fy = bx + bw + 5, by - 2
        if Cfg.money and ent.moneyText then
            k = k + 1
            local d = fl[k]
            txt(d, ent.moneyText)
            pos(d, fx, fy)
            col(d, dormant and GREY or MONEY)
            alp(d, fade)
            vis(d, true)
        end
        if Cfg.flags then
            local ft, fc = ent.ft, ent.fc
            for i = 1, ent.fn do
                k = k + 1
                local d = fl[k]
                txt(d, ft[i])
                pos(d, fx, fy + (k - 1) * 11)
                col(d, dormant and GREY or fc[i])
                alp(d, fade)
                vis(d, true)
            end
        end
        for i = k + 1, 7 do vis(fl[i], false) end

        local bone = s.bone
        if light and Cfg.skeleton then
            light = true
        elseif Cfg.skeleton and not dormant and have then
            local c, a = Cfg.skeleton_color, Cfg.skeleton_alpha
            px[1], py[1], pok[1] = rsx, rsy, true
            for i = 1, 14 do
                local d = bone[i]
                local a1, b1 = BA[i], BB[i]
                if pok[a1] and pok[b1] then
                    seg(d, floor(px[a1] + 0.5), floor(py[a1] + 0.5), floor(px[b1] + 0.5), floor(py[b1] + 0.5))
                    col(d, c)
                    alp(d, a)
                    vis(d, true)
                else
                    vis(d, false)
                end
            end
        else
            for i = 1, 14 do vis(bone[i], false) end
        end

    end

    local function active()
        if not E.any then return false end
        local key = E.Key
        if not key then return true end
        if key.Mode == "Always on" or not key.Key then return true end
        return key.State == true
    end

    local function players(now)
        for i = 1, #list do
            local ent = list[i]
            if ent then drawEnt(ent, now) end
        end
        R.shown = true
    end

    local function frame(now)
        local show = active()
        local other = E.other
        local nade = E.nade
        if not show then
            if R.shown then
                R.shown = false
                E.hideAll()
            end
            if not other and not nade then
                if E.O.shown then E.otherHide() end
                if E.N.shown then E.nadeHide() end
                return
            end
        end
        R.frame = R.frame + 1
        if now - R.camAt > 0.03 then
            R.camAt = now
            local cam = E.cam
            if cam then
                local p = cam.Position
                if p then R.cx, R.cy, R.cz = p.X, p.Y, p.Z end
            end
        end
        if show then players(now) end
        if other then
            E.otherFrame(now)
        elseif E.O.shown then
            E.otherHide()
        end
        if nade then
            E.nadeFrame(now)
        elseif E.N.shown then
            E.nadeHide()
        end
    end

    function E.render()
        local now = clock()
        if now - R.last < E.GATE then return end
        R.last = now
        if not E.alive then return end
        local ok, err = pcall(frame, now)
        if not ok then
            E.report(err)
            pcall(E.hideAll)
            pcall(E.otherHide)
            pcall(E.nadeHide)
        end
    end
end

local function EspRun(E)
    local clock = os.clock
    local Cfg, Off = E.Cfg, E.Off
    local Timer = { quick = 0, roster = -1, slot = 0, init = 0, learn = -10, tries = 0, folders = 0 }
    local API = {}
    E.GATE = 1 / 120
    E.alive = true

    local function features()
        Cfg.dirty = false
        local on = not E.failed
        E.any = on and (Cfg.box or Cfg.health or Cfg.name or Cfg.flags or Cfg.weapon or Cfg.wicon or Cfg.ammo or Cfg.ammobar or Cfg.distance or Cfg.money or Cfg.skeleton) or false
        E.other = on and (Cfg.drop or Cfg.warn) or false
    end

    local function tell(text)
        warn("Blox Strike: " .. text)
        pcall(function() Library:Notify({ Message = text, Delay = 8 }) end)
    end

    function E.fail(reason)
        if E.failed then return end
        E.failed = true
        Cfg.dirty = true
        tell("ESP is off: " .. tostring(reason) .. ". Reload the script to try again.")
    end

    function API.stop()
        if not E.alive then return end
        E.alive = false
        if E.conn then
            pcall(function() E.conn:Disconnect() end)
            E.conn = nil
        end
        pcall(E.removeAll)
        pcall(E.otherRemove)
        pcall(E.nadeRemove)
        if _G.BloxStrikeESP == API then _G.BloxStrikeESP = nil end
    end

    local function tick(now)
        if Cfg.dirty or E.any == nil then features() end
        E.nadeTick(now)
        if E.failed or (not E.any and not E.other and not E.nade) then return end
        if Timer.init == 0 then
            if now - Timer.learn < 3 then return end
            Timer.learn = now
            local ok, why = E.learn(E.LP)
            if ok then
                Timer.init = 1
            else
                Timer.tries = Timer.tries + 1
                if Timer.tries == 3 then tell("ESP is waiting for your player data (" .. tostring(why) .. "). It starts by itself once you are in the match.") end
            end
            return
        end
        if Timer.init == 2 or Timer.init == 3 then
            Timer.init = Timer.init + 1
            E.world(now)
            return
        end
        if Timer.init == 1 then
            local ok, why = E.feed()
            if not ok then
                E.fail(why)
                return
            end
            Timer.init = 2
            task.spawn(function()
                local ok, err = pcall(E.catalogue)
                if not ok then E.report("sounds: " .. tostring(err)) end
            end)
            return
        end
        if Cfg.dormant then E.poll(now) end
        if now - Timer.quick >= 0.1 then
            Timer.quick = now
            E.quick(now)
        end
        if E.other and Off.ready then
            local start = clock()
            if E.otherTick(now) and clock() - start > 0.0003 then return end
        end
        local busy = false
        if not E.chars then
            Timer.folders = now
            E.folders()
            busy = true
        elseif now - Timer.roster >= 0.25 then
            Timer.roster = now
            E.roster(now)
            busy = true
        elseif #E.pending > 0 then
            busy = E.resolve(now)
        end
        if busy then return end
        if now - Timer.folders >= 2 then
            Timer.folders = now
            E.folders()
        elseif now - Timer.slot >= 0.05 then
            Timer.slot = now
            E.slot(now)
        elseif Cfg.dormant then
            E.voiceStep(now)
        end
    end

    local Old = _G.BloxStrikeESP
    if type(Old) == "table" and type(Old.stop) == "function" then pcall(Old.stop) end
    _G.BloxStrikeESP = API

    local okc, conn = pcall(function()
        return game:GetService("RunService").RenderStepped:Connect(E.render)
    end)
    if okc then E.conn = conn end

    task.spawn(function()
        while E.alive do
            if Library.Unloaded or not Library.Running then
                API.stop()
                break
            end
            local now = clock()
            local ok, err = pcall(tick, now)
            if not ok then E.report(err) end
            task.wait((E.any or E.other or E.nade) and 0.03 or 0.25)
        end
    end)
end

local function EspOther(E)
    local mr, up, clock, floor, sqrt, sub, abs = memory_read, string.unpack, os.clock, math.floor, math.sqrt, string.sub, math.abs
    local Cfg, Off, D, R, list = E.Cfg, E.Off, E.D, E.R, E.list
    local ptr, vec, find1, attr, rootPos = E.ptr, E.vec, E.find1, E.attr, E.rootPos
    local vis, rect, pos, col, alp, txt = D.vis, D.rect, D.pos, D.col, D.alp, D.txt
    local W2S, V3 = WorldToScreen, Vector3.new
    local TWO32 = 4294967296
    local WHITE, BLACK = Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)
    local BOMB = Color3.fromRGB(255, 70, 70)
    local UNIT = 0.28 / 0.0254
    local SHOW, BURN = 400 / UNIT, 150 / UNIT
    local O = {
        known = {}, queue = {}, drops = {}, nades = {}, areas = {}, stamp = 0, pollAt = 0, classAt = 0, nadeAt = 0, areaAt = 0,
        slots = {}, free = {}, wslots = {}, wfree = {}, all = {}, icons = {}, want = {}, fuse = {}, life = {}, shown = false,
        warnShown = 0, ni = 0, netAt = -10, urlsAt = -100, meAt = -10, iconGen = 0, aimAt = -10, aimOk = false,
    }
    E.O = O
    local WEAPON = {
        ["AK-47"] = { "83097083839889", 30 }, ["AUG"] = { "119885531832389", 30 }, ["AWP"] = { "79794264811775", 5 },
        ["C4"] = { "109858795365969" }, ["Decoy Grenade"] = { "81385239843859" }, ["Desert Eagle"] = { "122477921917392", 7 },
        ["Dual Berettas"] = { "111854065134079", 30 }, ["FAMAS"] = { "125469152582044", 25 }, ["Five-SeveN"] = { "90570942481875", 20 },
        ["Flashbang"] = { "132038996524430" }, ["Galil AR"] = { "75166557697975", 35 }, ["Glock-18"] = { "101406018897044", 20 },
        ["HE Grenade"] = { "111110976385167" }, ["Incendiary Grenade"] = { "81255981095065" }, ["M4A1-S"] = { "113144230602399", 20 },
        ["M4A4"] = { "93053662997899", 30 }, ["MAC-10"] = { "83671879972945", 30 }, ["MP9"] = { "135384625641866", 30 },
        ["Molotov"] = { "95390644612614" }, ["Negev"] = { "134163874921903", 150 }, ["Nova"] = { "127273982496076", 8 },
        ["P250"] = { "73666032770570", 13 }, ["P90"] = { "82724138944322", 50 }, ["Tec-9"] = { "119232881698906", 18 },
        ["SG 553"] = { "133547075528778", 30 }, ["SSG 08"] = { "112132914334737", 10 }, ["XM1014"] = { "115344320193773", 7 },
        ["Smoke Grenade"] = { "137305344844339" }, ["USP-S"] = { "131658947857971", 12 }, ["MAG-7"] = { "86291171438206", 5 },
        ["Zeus x27"] = { "71464446190434", 1 }, ["Sawed-Off"] = { "117478678996500", 7 }, ["R8 Revolver"] = { "112745953600473", 8 },
    }
    local NADE = {
        ["HE Grenade"] = { tag = "FRAG", fuse = 1.5, show = SHOW, sigma = 6 },
        ["Flashbang"] = { tag = "FLASH", fuse = 1.5, show = 120 },
        ["Molotov"] = { tag = "MOLLY", show = SHOW, burn = true },
        ["Incendiary Grenade"] = { tag = "MOLLY", show = SHOW, burn = true },
        ["Smoke Grenade"] = { tag = "SMOKE", show = SHOW, neutral = true },
        ["Decoy Grenade"] = { tag = "DECOY", show = SHOW, neutral = true },
    }
    for name, spec in pairs(NADE) do spec.icon = WEAPON[name][1] end
    local AREA = {
        fire = { tag = "MOLLY", show = SHOW, burn = true, life = 7, fixed = true, icon = WEAPON["Molotov"][1] },
        smoke = { tag = "SMOKE", show = SHOW, neutral = true, life = 18, fixed = true, icon = WEAPON["Smoke Grenade"][1] },
    }
    local HOT = Color3.fromRGB(255, 70, 70)

    local function kidsOf(inst) return inst:GetChildren() end

    local function keep(d)
        O.all[#O.all + 1] = d
        return d
    end
    local function image()
        local o = Drawing.new("Image")
        o.Visible = false
        o.ZIndex = 998
        return keep({ o = o, vis = false })
    end
    local function dropSlot()
        local s = table.remove(O.free)
        if s then return s end
        if #O.slots >= 24 then return nil end
        s = { on = false }
        s.name = keep(D.text(13, true))
        s.dist = keep(D.text(13, true))
        s.ammo = keep(D.text(13, true))
        s.amB = keep(D.square(true, BLACK))
        s.amF = keep(D.square(true, WHITE))
        O.slots[#O.slots + 1] = s
        return s
    end
    local function hideDrop(s)
        if not s.on then return end
        s.on = false
        vis(s.name, false)
        vis(s.dist, false)
        vis(s.ammo, false)
        vis(s.amB, false)
        vis(s.amF, false)
        if s.img then vis(s.img, false) end
    end
    local function warnSlot()
        local s = table.remove(O.wfree)
        if s then return s end
        if #O.wslots >= 12 then return nil end
        s = { on = false, imgs = {} }
        s.barB = keep(D.square(true, BLACK))
        s.barF = keep(D.square(true, WHITE))
        s.dist = keep(D.text(13, true))
        s.label = keep(D.text(13, true))
        O.wslots[#O.wslots + 1] = s
        return s
    end
    local function hideWarn(s)
        if not s.on then return end
        s.on = false
        vis(s.barB, false)
        vis(s.barF, false)
        vis(s.dist, false)
        vis(s.label, false)
        if s.img then vis(s.img, false) end
    end

    local function ipos(it)
        local p = it.prim
        if not p and it.partAddr then
            p = ptr(it.partAddr + Off.prim)
            it.prim = p
        end
        if p then return vec(p + Off.pos) end
        return nil
    end

    local function median(ring)
        local copy = {}
        for i = 1, #ring do copy[i] = ring[i] end
        table.sort(copy)
        return copy[floor((#copy + 1) / 2)]
    end
    local function push(store, key, value)
        local ring = store[key]
        if not ring then
            ring = {}
            store[key] = ring
        end
        ring[#ring + 1] = value
        if #ring > 5 then table.remove(ring, 1) end
    end
    local function removeFrom(arr, it)
        for i = #arr, 1, -1 do
            if arr[i] == it then table.remove(arr, i) end
        end
    end

    local function fuseOf(name)
        local spec = NADE[name]
        if not spec or not spec.fuse then return nil end
        local ring = O.fuse[name]
        if ring and #ring >= 2 then
            local m = median(ring)
            if m > 0.4 and m < 6 and abs(m - 0.05 - spec.fuse) > 0.25 then return m - 0.05 end
        end
        return spec.fuse
    end

    local function finish(it, now, seen)
        if it.done then return end
        it.done = true
        if it.wslot then
            hideWarn(it.wslot)
            O.wfree[#O.wfree + 1] = it.wslot
            it.wslot = nil
        end
        if seen and it.spec.fuse then push(O.fuse, it.name, now - it.born) end
    end

    local function release(it, now)
        it.gone = true
        local kind = it.kind
        if kind == "maybe" or ((kind == "drop" or kind == "nade") and it.stage ~= 3) then return end
        if kind == "drop" then
            removeFrom(O.drops, it)
            if it.slot then
                hideDrop(it.slot)
                O.free[#O.free + 1] = it.slot
                it.slot = nil
            end
            return
        end
        if kind == "nade" then
            removeFrom(O.nades, it)
            finish(it, now, false)
        elseif kind then
            removeFrom(O.areas, it)
            push(O.life, kind, now - it.born)
        end
        if it.wslot then
            hideWarn(it.wslot)
            O.wfree[#O.wfree + 1] = it.wslot
            it.wslot = nil
        end
    end

    local function enqueue(child, a, now)
        local e = { inst = child, addr = a, stamp = O.stamp, born = now, tries = 0, miss = 0 }
        O.known[a] = e
        O.queue[#O.queue + 1] = e
    end

    local function poll(now)
        local debris = O.debris
        if not debris or now - (O.debrisAt or -10) > 5 then
            debris = find1(workspace, "Debris")
            O.debrisAt = now
            local a = debris and debris.Address or nil
            if a ~= O.debrisAddr then
                for addr, e in pairs(O.known) do
                    O.known[addr] = nil
                    if e.kind then release(e, now) end
                end
                O.queue = {}
                O.childOff = nil
            end
            O.debris, O.debrisAddr = debris, a
        end
        if not debris then return end
        O.stamp = O.stamp + 1
        local stamp, known, base = O.stamp, O.known, O.debrisAddr
        local kids
        local co = O.childOff
        if co == nil then
            local ok, got = pcall(kidsOf, debris)
            if not ok or type(got) ~= "table" then return end
            kids = got
            if #kids > 0 then
                co = false
                local fk = Off.fkids
                local p = ptr(base + fk)
                local b, e = p and ptr(p), p and ptr(p + 8)
                if b and e and e - b == #kids * 16 and mr("uintptr", b) == kids[1].Address and mr("uintptr", e - 16) == kids[#kids].Address then
                    co = fk
                end
                O.childOff = co
            end
        end
        local done = false
        if co then
            local p = ptr(base + co)
            local b, e = p and mr("uintptr", p), p and mr("uintptr", p + 8)
            if b and e and e >= b and e - b <= 32000 then
                local n = floor((e - b) / 16)
                done = true
                if n >= 1 then
                    local buf = mr("buffer", b, n * 16)
                    if type(buf) == "string" and #buf >= n * 16 then
                        for i = 1, n do
                            local lo, hi = up("<I4I4", buf, (i - 1) * 16 + 1)
                            local a = lo + hi * TWO32
                            local e2 = known[a]
                            if e2 then
                                e2.stamp = stamp
                                e2.miss = 0
                            else
                                if not kids then
                                    local ok, got = pcall(kidsOf, debris)
                                    kids = ok and type(got) == "table" and got or {}
                                end
                                local child = kids[i]
                                if child and #kids == n and child.Address == a then enqueue(child, a, now) end
                            end
                        end
                    else
                        done = false
                    end
                end
            end
        end
        if not done then
            if not kids then
                local ok, got = pcall(kidsOf, debris)
                if not ok or type(got) ~= "table" then return end
                kids = got
            end
            for i = 1, #kids do
                local child = kids[i]
                local a = child.Address
                if a then
                    local e2 = known[a]
                    if e2 then
                        e2.stamp = stamp
                        e2.miss = 0
                    else
                        enqueue(child, a, now)
                    end
                end
            end
        end
        for a, e in pairs(known) do
            if e.stamp ~= stamp then
                e.miss = e.miss + 1
                if e.miss >= 2 then
                    known[a] = nil
                    e.gone = true
                    if e.kind then release(e, now) end
                end
            end
        end
    end

    local function partOf(model)
        local w = find1(model, "Weapon")
        if not w then return nil end
        local part = find1(w, "Handle") or find1(w, "Body") or find1(w, "Hitbox")
        if part then return part end
        local kids = kidsOf(w)
        local inner
        for i = 1, #kids do
            local cn = kids[i].ClassName
            if cn == "Part" or cn == "MeshPart" then return kids[i] end
            if cn == "Model" and not inner then inner = kids[i] end
        end
        if inner then
            kids = kidsOf(inner)
            for i = 1, #kids do
                local cn = kids[i].ClassName
                if cn == "Part" or cn == "MeshPart" then return kids[i] end
            end
        end
        return nil
    end

    local function again(e, now, limit)
        e.tries = e.tries + 1
        if e.tries < limit then
            e.retryAt = now + (e.tries == 1 and 0.03 or 0.2)
            O.queue[#O.queue + 1] = e
        else
            e.kind = nil
        end
    end

    local TPL = { names = { "HE Grenade", "Flashbang", "Molotov", "Incendiary Grenade", "Smoke Grenade", "Decoy Grenade" }, i = 1, data = {}, done = false, at = 0, phase = 0 }

    local function sizeOf(part)
        local p = ptr(part.Address + Off.prim)
        if p then return vec(p + Off.fsize) end
        return nil
    end

    local function surface(handle)
        local kids = kidsOf(handle)
        for i = 1, #kids do
            if kids[i].ClassName == "SurfaceAppearance" then return kids[i].Address end
        end
        return nil
    end

    local function alike(a, b)
        return abs(a[1] - b[1]) < 0.01 and abs(a[2] - b[2]) < 0.01 and abs(a[3] - b[3]) < 0.01
    end

    local function template(name)
        local phase = TPL.phase
        if phase == 0 then
            if not TPL.assets then
                TPL.assets = find1(game:GetService("ReplicatedStorage"), "Assets")
                return TPL.assets == nil
            end
            if not TPL.root then
                TPL.root = find1(TPL.assets, "Weapons")
                return TPL.root == nil
            end
            if not TPL.entry then
                TPL.entry = find1(TPL.root, name)
                return TPL.entry == nil
            end
            TPL.model = find1(TPL.entry, "Character")
            TPL.entry = nil
            TPL.phase = 1
            return false
        end
        if phase == 1 then
            TPL.handle = find1(find1(TPL.model, "Weapon"), "Handle")
            TPL.phase = TPL.handle and 2 or 9
            return TPL.handle == nil
        end
        if phase == 2 then
            local x, y, z = sizeOf(TPL.handle)
            if not x then return true end
            TPL.data[name] = { x, y, z, {} }
            TPL.sa = surface(TPL.handle)
            TPL.phase = TPL.sa and 3 or 9
            TPL.scan = 0x100
            return TPL.sa == nil
        end
        local marks = TPL.data[name][4]
        local last = TPL.scan + 0x38
        for off = TPL.scan, last, 8 do
            local text = E.str(TPL.sa + off)
            if text and #text > 12 and string.find(text, "rbxasset", 1, true) then marks[off] = text end
        end
        TPL.scan = last + 8
        return TPL.scan > 0x200
    end

    local function tplStep(now)
        TPL.at = now
        local names, data = TPL.names, TPL.data
        local name = names[TPL.i]
        local ok, finished = pcall(template, name)
        if ok and not finished then return end
        TPL.i = TPL.i + 1
        TPL.phase = 0
        if TPL.i <= #names then return end
        TPL.done = true
        TPL.model, TPL.handle, TPL.sa = nil, nil, nil
        for off = 0x100, 0x200, 8 do
            local good, pairs_ = true, 0
            for a = 1, #names do
                for b = a + 1, #names do
                    local A, B = data[names[a]], data[names[b]]
                    if A and B and alike(A, B) then
                        pairs_ = pairs_ + 1
                        if not A[4][off] or not B[4][off] or A[4][off] == B[4][off] then good = false end
                    end
                end
            end
            if good and pairs_ > 0 then
                TPL.off = off
                break
            end
        end
    end

    local function identify(handle)
        local x, y, z = sizeOf(handle)
        if not x then return nil end
        local probe = { x, y, z }
        local names, data = TPL.names, TPL.data
        local found, count = nil, 0
        for i = 1, #names do
            local t = data[names[i]]
            if t and alike(t, probe) then
                count = count + 1
                if not found then found = names[i] end
            end
        end
        if count > 1 and TPL.off then
            local sa = surface(handle)
            local text = sa and E.str(sa + TPL.off)
            if text then
                for i = 1, #names do
                    local t = data[names[i]]
                    if t and alike(t, probe) and t[4][TPL.off] == text then return names[i] end
                end
            end
        end
        return found
    end

    local function classify(e, now)
        local child = e.inst
        if e.stage == 2 then
            if e.kind == "drop" then
                e.slot = dropSlot()
                O.drops[#O.drops + 1] = e
            else
                e.wslot = warnSlot()
                O.nades[#O.nades + 1] = e
            end
            e.stage = 3
            return
        end
        if e.stage == 1 then
            local part = partOf(child)
            if not part then
                again(e, now, 5)
                return
            end
            if e.kind == "maybe" then
                if not TPL.done then
                    e.retryAt = now + 0.1
                    O.queue[#O.queue + 1] = e
                    return
                end
                if type(attr(child, "Weapon")) == "string" then
                    e.kind, e.stage = nil, nil
                    table.insert(O.queue, 1, e)
                    return
                end
                local name = nil
                if part.Name == "Handle" then name = identify(part) end
                if not name then
                    again(e, now, 3)
                    return
                end
                e.kind, e.name, e.spec = "nade", name, NADE[name]
            end
            e.partAddr = part.Address
            e.stage = 2
            table.insert(O.queue, 1, e)
            return
        end
        local cn = child.ClassName
        if cn == "Folder" then
            local name = child.Name
            local kind = (sub(name, 1, 10) == "VoxelFire_" and "fire") or (sub(name, 1, 11) == "VoxelSmoke_" and "smoke") or nil
            if not kind then return end
            e.kind, e.spec, e.name, e.scanAt = kind, AREA[kind], name, 0
            e.wslot = warnSlot()
            O.areas[#O.areas + 1] = e
            return
        end
        if cn ~= "Model" then return end
        local weapon = attr(child, "Weapon")
        local grenade = nil
        if type(weapon) ~= "string" then
            weapon = nil
            grenade = attr(child, "GrenadeName")
            if type(grenade) ~= "string" then grenade = nil end
        end
        if not weapon and not grenade then
            e.kind = "maybe"
        elseif weapon then
            local w = WEAPON[weapon]
            e.kind, e.name, e.isC4 = "drop", weapon, weapon == "C4"
            e.icon, e.mag = w and w[1] or nil, w and w[2] or nil
            e.ammoDue = e.mag and now + 1 or nil
        else
            e.kind, e.name = "nade", grenade
            e.spec = NADE[grenade] or { tag = "NADE", show = SHOW }
        end
        e.stage = 1
        table.insert(O.queue, 1, e)
    end

    local function ammoFor(it, now)
        local x, y, z = ipos(it)
        if not x then return end
        local best, bestD
        for i = 1, #list do
            local ent = list[i]
            local r, c
            if ent.heldW == it.name and (ent.dead or ent.weapon ~= it.name) and now - (ent.heldAt or -10) < 6 then
                r, c = ent.heldR, ent.heldC
            elseif ent.prevW == it.name and now - (ent.prevAt or -10) < 6 then
                r, c = ent.prevR, ent.prevC
            end
            if r then
                local px, py, pz = rootPos(ent)
                if not px or py < -500 then px, py, pz = ent.lx, ent.ly, ent.lz end
                if px then
                    local dx, dy, dz = px - x, py - y, pz - z
                    local d = dx * dx + dy * dy + dz * dz
                    if d < 144 and (not bestD or d < bestD) then
                        best, bestD = ent, d
                        it.rounds, it.capacity = r, c
                    end
                end
            end
        end
        if best then
            local top = it.mag
            if it.rounds > top then top = it.rounds end
            it.ammoFrac = top > 0 and it.rounds / top or 0
            it.ammoText = it.capacity and (it.rounds .. "/" .. it.capacity) or tostring(it.rounds)
        end
    end

    local function areaStep(it, now)
        local sc = it.scan
        if not sc then
            sc = { kids = kidsOf(it.inst), i = 1, n = 0, sx = 0, sy = 0, sz = 0, x0 = 1e9, x1 = -1e9, z0 = 1e9, z1 = -1e9 }
            it.scan = sc
            return
        end
        local kids = sc.kids
        local last = sc.i + 9
        if last > #kids then last = #kids end
        for i = sc.i, last do
            local a = kids[i].Address
            local p = a and ptr(a + Off.prim)
            local x, y, z
            if p then x, y, z = vec(p + Off.pos) end
            if x and y > -5000 then
                sc.n = sc.n + 1
                sc.sx, sc.sy, sc.sz = sc.sx + x, sc.sy + y, sc.sz + z
                if x < sc.x0 then sc.x0 = x end
                if x > sc.x1 then sc.x1 = x end
                if z < sc.z0 then sc.z0 = z end
                if z > sc.z1 then sc.z1 = z end
            end
        end
        sc.i = last + 1
        if sc.i > #kids then
            if sc.n > 0 then
                it.x, it.y, it.z = sc.sx / sc.n, sc.sy / sc.n, sc.sz / sc.n
                local ex, ez = (sc.x1 - sc.x0) / 2, (sc.z1 - sc.z0) / 2
                it.ext = (ex > ez and ex or ez) + 2
            end
            it.scan = nil
            it.scanAt = now + 0.5
        end
    end

    function E.otherTick(now)
        local live = Cfg.warn
        local rate = live and (O.childOff and 0.05 or 0.1) or 0.25
        if now - O.pollAt >= rate then
            O.pollAt = now
            local ok, err = pcall(poll, now)
            if not ok then E.report(err) end
            if #O.queue == 0 or clock() - now > 0.0004 then return true end
        end
        local drops = O.drops
        for i = 1, #drops do
            local it = drops[i]
            if it.ammoDue and now >= it.ammoDue then
                it.ammoDue = nil
                pcall(ammoFor, it, now)
            end
        end
        if #O.queue > 0 and now - O.classAt >= 0.03 then
            O.classAt = now
            local e = table.remove(O.queue, 1)
            if e.gone then return true end
            if e.retryAt and now < e.retryAt then
                O.queue[#O.queue + 1] = e
            else
                local ok, err = pcall(classify, e, now)
                if not ok then E.report(err) end
                return true
            end
        end
        local nades = O.nades
        local ft = Off.ftrans
        if not TPL.done and now - TPL.at >= 0.04 then
            tplStep(now)
            return true
        end
        for i = 1, #nades do
            local it = nades[i]
            if not it.done then
                if it.partAddr then
                    local t = mr("float", it.partAddr + ft)
                    if t and t >= 0.99 and t <= 1.001 then finish(it, now, true) end
                end
                if now - it.born > 12 then finish(it, now, false) end
            end
        end
        if live and #nades > 0 and now - O.nadeAt >= 0.25 then
            for k = 1, #nades do
                O.ni = O.ni % #nades + 1
                local it = nades[O.ni]
                if not it.done then
                    O.nadeAt = now
                    if attr(it.inst, "SimulationFinished") == true then finish(it, now, true) end
                    return true
                end
            end
        end
        local areas = O.areas
        if live and #areas > 0 and now - O.areaAt >= 0.06 then
            for i = 1, #areas do
                local it = areas[i]
                if it.scan or now >= it.scanAt then
                    O.areaAt = now
                    local ok = pcall(areaStep, it, now)
                    if not ok then
                        it.scan = nil
                        it.scanAt = now + 1
                    end
                    return true
                end
            end
        end
        return false
    end

    local function drawDrops()
        local drops = O.drops
        local wi, wt, wa, wd = Cfg.drop_icon and Cfg.get_icons, Cfg.drop_text, Cfg.drop_ammo, Cfg.drop_distance
        local po, da = Off.parent, O.debrisAddr
        local base = Cfg.drop_alpha
        local DIST = D.DIST
        for i = 1, #drops do
            local it = drops[i]
            local s = it.slot
            if not s then
                s = dropSlot()
                it.slot = s
            end
            if s then
                local x, y, z, sx, sy, range
                if mr("uintptr", it.addr + po) == da then x, y, z = ipos(it) end
                if x then
                    local dx, dy, dz = x - R.cx, y - R.cy, z - R.cz
                    range = sqrt(dx * dx + dy * dy + dz * dz)
                    if range < 250 then
                        local sv, on = W2S(V3(x, y, z))
                        if on then sx, sy = floor(sv.X + 0.5), floor(sv.Y + 0.5) end
                    end
                end
                if not sx then
                    hideDrop(s)
                else
                    s.on = true
                    local a = base
                    if range > 120 then a = base * (1 - 0.6 * (range - 120) / 130) end
                    a = floor(a * 20 + 0.5) / 20
                    local c = it.isC4 and BOMB or Cfg.drop_color
                    local yy = sy - 8
                    local named = wt
                    local ic = wi and it.icon and O.icons[it.icon] or nil
                    if ic and ic.data then
                        local d = s.img
                        if not d then
                            d = image()
                            s.img = d
                        end
                        if s.imgOf ~= ic then
                            s.imgOf = ic
                            d.o.Data = ic.data
                        end
                        rect(d, sx - floor(ic.w / 2), yy, ic.w, ic.h)
                        col(d, c)
                        alp(d, a)
                        vis(d, true)
                        yy = yy + ic.h + 2
                    else
                        if wi then
                            named = true
                            if it.icon and not ic then O.want[it.icon] = true end
                        end
                        if s.img then vis(s.img, false) end
                    end
                    if named then
                        local d = s.name
                        txt(d, it.name)
                        pos(d, sx, yy + 6)
                        col(d, c)
                        alp(d, a)
                        vis(d, true)
                        yy = yy + 14
                    else
                        vis(s.name, false)
                    end
                    if wd then
                        local metres = floor(range * 0.28 + 0.5)
                        local label = DIST[metres]
                        if not label then
                            label = metres .. "m"
                            DIST[metres] = label
                        end
                        local d = s.dist
                        txt(d, label)
                        pos(d, sx, yy + 6)
                        col(d, c)
                        alp(d, a)
                        vis(d, true)
                        yy = yy + 14
                    else
                        vis(s.dist, false)
                    end
                    if wa and it.ammoFrac then
                        local fw = floor(30 * it.ammoFrac + 0.5)
                        local d = s.amB
                        rect(d, sx - 16, yy + 1, 32, 4)
                        alp(d, a)
                        vis(d, true)
                        d = s.amF
                        rect(d, sx - 15, yy + 2, fw, 2)
                        col(d, Cfg.ammo_color or WHITE)
                        alp(d, a)
                        vis(d, fw > 0)
                        d = s.ammo
                        txt(d, it.ammoText)
                        pos(d, sx, yy + 13)
                        col(d, Cfg.ammo_color or WHITE)
                        alp(d, a)
                        vis(d, true)
                    else
                        vis(s.amB, false)
                        vis(s.amF, false)
                        vis(s.ammo, false)
                    end
                end
            end
        end
    end

    local function warnOne(it, x, y, z, frac)
        local s = it.wslot
        if not s then return 0 end
        local spec = it.spec
        local dx, dy, dz = x - R.cx, y - R.cy, z - R.cz
        local range = sqrt(dx * dx + dy * dy + dz * dz)
        if it.ext then
            range = range - it.ext + 2
            if range < 0 then range = 0 end
        end
        if range > spec.show then
            hideWarn(s)
            return 0
        end
        local vw, vh = E.vw or 1920, E.vh or 1080
        local mx, my
        local sv, on = W2S(V3(x, y, z))
        if on then
            mx, my = floor(sv.X + 0.5), floor(sv.Y + 0.5)
        else
            if spec.neutral then
                hideWarn(s)
                return 0
            end
            local now = R.last
            if now - O.aimAt > 0.03 then
                O.aimAt = now
                O.aimOk = D.basis()
            end
            if not O.aimOk then
                hideWarn(s)
                return 0
            end
            local ex, ey, ez = x - R.bx, y - R.by, z - R.bz
            local zz = ex * R.lx + ey * R.ly + ez * R.lz
            local az = zz < 0 and -zz or zz
            if az < 0.001 then az = 0.001 end
            mx = floor(vw / 2 + (ex * R.rx + ey * R.ry + ez * R.rz) / az * (R.fx or 900) + 0.5)
            my = vh
            if zz > 0 then my = floor(vh / 2 - (ex * R.ux + ey * R.uy + ez * R.uz) / az * (R.fy or 900) + 0.5) end
        end
        if mx > vw - 50 then mx = vw - 50 end
        if mx < 50 then mx = 50 end
        if my > vh - 50 then my = vh - 50 end
        if my < 50 then my = 50 end
        local metres = floor(range * 0.28 + 0.5)
        local fade = 1
        if it.ext and frac then
            local left = frac < 0.1 and 0.1 or (frac > 1 and 1 or frac)
            fade = floor(sqrt(left) * 20 + 0.5) / 20
        end
        local hot = false
        if spec.sigma then
            hot = range < spec.sigma * 2
        elseif spec.burn then
            hot = range < BURN
        end
        local fill = -1
        if frac and frac > 0 then
            if frac > 1 then frac = 1 end
            fill = floor(24 * frac + 0.5)
        end
        local mode = O.mode
        if s.on and s.kx == mx and s.ky == my and s.kl == hot and s.kd == metres and s.ka == fade and s.km == mode and s.kf == fill then return 1 end
        s.on = true
        s.kx, s.ky, s.kl, s.kd, s.ka, s.km, s.kf = mx, my, hot, metres, fade, mode, fill
        local c = hot and HOT or WHITE
        local y = my - 14
        local shown = nil
        local named = Cfg.warn_text
        if Cfg.warn_icon and Cfg.get_icons then
            local id = spec.icon
            local ic = id and O.icons[id] or nil
            if ic and ic.data then
                shown = s.imgs[id]
                if not shown then
                    shown = image()
                    shown.o.Data = ic.data
                    s.imgs[id] = shown
                end
                local iw = floor(ic.ww * 20 / 32 + 0.5)
                rect(shown, mx - floor(iw / 2), y, iw, 20)
                col(shown, c)
                alp(shown, fade)
                vis(shown, true)
                y = y + 22
            else
                if id and not ic then O.want[id] = true end
                named = true
            end
        end
        if s.img and s.img ~= shown then vis(s.img, false) end
        s.img = shown
        local d = s.label
        if named then
            txt(d, spec.tag)
            pos(d, mx, y + 6)
            col(d, c)
            alp(d, fade)
            vis(d, true)
            y = y + 15
        else
            vis(d, false)
        end
        if fill >= 0 then
            d = s.barB
            rect(d, mx - 13, y, 26, 4)
            alp(d, fade)
            vis(d, true)
            d = s.barF
            rect(d, mx - 12, y + 1, fill, 2)
            col(d, c)
            alp(d, fade)
            vis(d, fill > 0)
            y = y + 6
        else
            vis(s.barB, false)
            vis(s.barF, false)
        end
        d = s.dist
        if Cfg.warn_distance then
            local label = D.DIST[metres]
            if not label then
                label = metres .. "m"
                D.DIST[metres] = label
            end
            txt(d, label)
            pos(d, mx, y + 6)
            col(d, c)
            alp(d, fade)
            vis(d, true)
        else
            vis(d, false)
        end
        return 1
    end

    local function hideWarns()
        for i = 1, #O.wslots do hideWarn(O.wslots[i]) end
        O.warnShown = 0
        O.warnOn = false
    end

    local function drawWarn(now)
        if now - O.meAt > 0.25 then
            O.meAt = now
            local me = O.me
            if not me or me.dropped then
                me = nil
                for i = 1, #list do
                    if list[i].isSelf then me = list[i] end
                end
                O.me = me
            end
            O.dead = me ~= nil and me.dead == true
        end
        if O.dead then
            if O.warnOn then hideWarns() end
            return
        end
        O.mode = (Cfg.warn_icon and 1 or 0) + (Cfg.warn_text and 2 or 0) + (Cfg.warn_distance and 4 or 0) + 8 * O.iconGen
        local shown = 0
        local nades, areas = O.nades, O.areas
        local po, da = Off.parent, O.debrisAddr
        local hold = O.warnShown >= 3 and R.frame % 2 or -1
        for i = 1, #nades do
            local it = nades[i]
            local s = it.wslot
            if not s and not it.done then
                s = warnSlot()
                it.wslot = s
            end
            if s then
                local x, y, z
                if not it.done and mr("uintptr", it.addr + po) == da then x, y, z = ipos(it) end
                if x and s.on and hold == i % 2 then
                    shown = shown + 1
                elseif x then
                    if it.fuse == nil then it.fuse = fuseOf(it.name) or false end
                    shown = shown + warnOne(it, x, y, z, it.fuse and (1 - (now - it.born) / it.fuse) or nil)
                else
                    hideWarn(s)
                end
            end
        end
        for i = 1, #areas do
            local it = areas[i]
            local s = it.wslot
            if not s then
                s = warnSlot()
                it.wslot = s
            end
            if s then
                if it.x and s.on and hold == (i + #nades) % 2 and (not it.life or now - it.born < it.life) then
                    shown = shown + 1
                elseif it.x then
                    if not it.life then
                        local ring = O.life[it.kind]
                        it.life = (not it.spec.fixed and ring and median(ring)) or it.spec.life
                    end
                    local left = 1 - (now - it.born) / it.life
                    if left > 0 then
                        shown = shown + warnOne(it, it.x, it.y, it.z, left)
                    else
                        hideWarn(s)
                    end
                else
                    hideWarn(s)
                end
            end
        end
        O.warnShown = shown
        O.warnOn = true
    end

    local function hideDrops()
        for i = 1, #O.slots do hideDrop(O.slots[i]) end
        O.dropOn = false
    end
    function E.otherFrame(now)
        O.shown = true
        if Cfg.warn and now - R.fitAt > 0.1 then
            R.fitAt = now
            if D.basis() then
                local x = R.bx + R.lx * 10 + R.rx * 3 + R.ux * 2
                local y = R.by + R.ly * 10 + R.ry * 3 + R.uy * 2
                local z = R.bz + R.lz * 10 + R.rz * 3 + R.uz * 2
                local sv, on = W2S(V3(x, y, z))
                if on then D.fit(x, y, z, sv.X, sv.Y, now) end
            end
        end
        if Cfg.drop then
            O.dropOn = true
            drawDrops()
        elseif O.dropOn then
            hideDrops()
        end
        if Cfg.warn then
            drawWarn(now)
        elseif O.warnOn then
            hideWarns()
        end
    end

    function E.otherHide()
        O.shown = false
        hideDrops()
        hideWarns()
    end

    function E.otherRemove()
        local all = O.all
        for i = 1, #all do
            local o = all[i].o
            pcall(function() o.Visible = false end)
            pcall(function() o:Remove() end)
        end
        O.all, O.slots, O.free, O.wslots, O.wfree = {}, {}, {}, {}, {}
    end

    local function accept(ic, data)
        if type(data) ~= "string" or #data < 32 or sub(data, 1, 4) ~= "\137PNG" then return false end
        local w, h = up(">I4I4", data, 17)
        if w < 1 or h < 1 or w > 4096 or h > 4096 then return false end
        local width = floor(14 * w / h + 0.5)
        if width < 6 then width = 6 elseif width > 64 then width = 64 end
        ic.data, ic.w, ic.h, ic.state = data, width, 14, "ok"
        width = floor(32 * w / h + 0.5)
        ic.ww = width < 8 and 8 or (width > 56 and 56 or width)
        O.iconGen = O.iconGen + 1
        return true
    end

    function E.iconOf(name)
        local w = WEAPON[name]
        local id = w and w[1]
        if not id then return nil end
        local ic = O.icons[id]
        if not ic then
            O.want[id] = true
            return nil
        end
        if ic.data then return ic end
        return nil
    end

    function O.iconStep(now)
        if not Cfg.get_icons then return false end
        if O.preload and next(O.want) == nil then O.preload = false end
        if not (Cfg.drop_icon or Cfg.warn_icon or Cfg.wicon or O.preload) then return false end
        for id in pairs(O.want) do
            local ic = O.icons[id]
            if not ic then
                ic = { state = "net", tries = 0, retryAt = 0 }
                O.icons[id] = ic
                local ok, data = pcall(function()
                    local path = Library.Folder .. "/Icons/" .. id .. ".txt"
                    if not isfile(path) then return nil end
                    local hex = readfile(path)
                    if type(hex) ~= "string" or #hex < 16 then return nil end
                    return (string.gsub(hex, "%x%x", function(h) return string.char(tonumber(h, 16)) end))
                end)
                if ok and accept(ic, data) then O.want[id] = nil end
                return true
            end
            if ic.state ~= "net" then
                O.want[id] = nil
                return false
            end
            if now - O.netAt >= (O.preload and 0 or 2) and now >= ic.retryAt then
                if not O.urls or (not O.urls[id] and now - O.urlsAt > 30) then
                    local ids = {}
                    for _, w in pairs(WEAPON) do ids[#ids + 1] = w[1] end
                    local ok, body = pcall(httpget, "https://thumbnails.roblox.com/v1/assets?assetIds=" .. table.concat(ids, ",") .. "&size=150x150&format=Png")
                    O.urls = O.urls or {}
                    if ok and type(body) == "string" then
                        for obj in string.gmatch(body, "{[^{}]*}") do
                            local target = string.match(obj, "\"targetId\"%s*:%s*(%d+)")
                            local url = string.match(obj, "\"imageUrl\"%s*:%s*\"([^\"]+)\"")
                            if target and url then O.urls[target] = url end
                        end
                    end
                    O.urlsAt = clock()
                    O.netAt = clock()
                    return true
                end
                local url = O.urls[id]
                local good = false
                if url then
                    local ok, data = pcall(httpget, url)
                    if ok and accept(ic, data) then
                        good = true
                        O.want[id] = nil
                        pcall(function()
                            local hex = string.gsub(data, ".", function(ch) return string.format("%02x", string.byte(ch)) end)
                            writefile(Library.Folder .. "/Icons/" .. id .. ".txt", hex)
                        end)
                    end
                end
                if not good then
                    ic.tries = ic.tries + 1
                    ic.retryAt = clock() + 5 * ic.tries
                    if ic.tries >= 4 then
                        ic.state = "failed"
                        O.want[id] = nil
                    end
                end
                O.netAt = clock()
                return true
            end
        end
        return false
    end

    for _, w in pairs(WEAPON) do
        if w[1] then O.want[tostring(w[1])] = true end
    end
    O.preload = true

    task.spawn(function()
        task.wait(0.2)
        while E.alive do
            local ok, busy = pcall(O.iconStep, clock())
            if not ok then E.report("icons: " .. tostring(busy)) end
            task.wait((O.preload and ok and busy) and 0 or (ok and busy and 0.05 or 0.25))
        end
    end)
end

local function NadeLogic()
    local sqrt, abs, floor, match, gsub, lower, find = math.sqrt, math.abs, math.floor, string.match, string.gsub, string.lower, string.find
    local L = { VERSION = 1, backed = {}, DEFAULTS = {} }
    L.SPOT_R, L.SPOT_KEEP, L.SPOT_Y = 0.5, 0.65, 1.0
    L.GROUP_R, L.GROUP_Y = 0.75, 1.5
    L.AIM_DEG, L.FEET = 0.25, 3
    L.MAX_SPOTS, L.MAX_AIMS = 8, 4
    L.GRENADES = {
        ["HE Grenade"] = { group = "he", tag = "HE" },
        ["Flashbang"] = { group = "flash", tag = "Flash" },
        ["Smoke Grenade"] = { group = "smoke", tag = "Smoke" },
        ["Molotov"] = { group = "fire", tag = "Molly" },
        ["Incendiary Grenade"] = { group = "fire", tag = "Molly" },
        ["Decoy Grenade"] = { group = "decoy", tag = "Decoy" },
    }

    local function num(v)
        return type(v) == "number" and v == v and v < 1e6 and v > -1e6
    end
    local function vec3(t)
        if type(t) ~= "table" then return nil end
        local x, y, z = t[1], t[2], t[3]
        if num(x) and num(y) and num(z) then return x, y, z end
        return nil
    end
    local function trim(s)
        if type(s) ~= "string" then return "" end
        return match(s, "^%s*(.-)%s*$") or ""
    end
    L.trim = trim

    function L.round(v, places)
        local m = 10 ^ places
        return floor(v * m + 0.5) / m
    end

    function L.heldName(equipped)
        if type(equipped) ~= "string" or equipped == "" then return nil end
        return match(equipped, "\"Name\":\"([^\"]*)\"")
    end

    function L.groupOf(name)
        local g = name and L.GRENADES[name]
        return g and g.group or nil
    end

    function L.fileName(map)
        if type(map) ~= "string" then return nil end
        local s = trim((gsub(map, "[^%w %-_]", "")))
        if s == "" then return nil end
        return s
    end

    function L.instruction(throw, crouch)
        local s = "THROW"
        if type(throw) == "string" and find(lower(throw), "jump", 1, true) then s = "JUMP THROW" end
        if crouch then s = "CROUCH + " .. s end
        return s
    end

    function L.inspect(entry, shift)
        if type(entry) ~= "table" then return nil end
        local x, y, z = vec3(entry.pos)
        local lx, ly, lz = vec3(entry.look)
        if not x or not lx then return nil end
        local len = sqrt(lx * lx + ly * ly + lz * lz)
        if len < 0.99 or len > 1.01 then return nil end
        local g = type(entry.grenade) == "string" and L.GRENADES[entry.grenade] or nil
        if not g or type(entry.throw) ~= "string" then return nil end
        local low = lower(entry.throw)
        local crouch = entry.crouch == true or find(low, "crouch", 1, true) ~= nil
        local to = trim(entry.to)
        if to == "" then to = trim(entry.from) end
        if to == "" then to = "?" end
        if shift then x, y, z = x + shift[1], y + shift[2], z + shift[3] end
        return {
            entry = entry, x = x, y = y, z = z, lx = lx / len, ly = ly / len, lz = lz / len,
            grenade = entry.grenade, group = g.group, tag = g.tag, crouch = crouch,
            jump = find(low, "jump", 1, true) ~= nil, throw = entry.throw,
            text = L.instruction(entry.throw, crouch), to = to, on = false,
        }
    end

    function L.rows(items, shift)
        local order = {}
        for i = 1, #items do
            local e = items[i]
            local created = type(e) == "table" and type(e.created) == "number" and e.created or 0
            order[i] = { entry = e, index = i, created = created }
        end
        table.sort(order, function(a, b)
            if a.created ~= b.created then return a.created < b.created end
            return a.index < b.index
        end)
        local seen, used, rows = {}, {}, {}
        for i = 1, #order do
            local o = order[i]
            local meta = L.inspect(o.entry, shift)
            local base
            if meta then
                base = meta.tag .. (meta.jump and " jump: " or ": ") .. meta.to
            else
                base = "(invalid)"
                if type(o.entry) == "table" then
                    local to = trim(o.entry.to)
                    if to == "" then to = trim(o.entry.from) end
                    if to ~= "" then base = "(invalid) " .. to end
                end
            end
            local n = (seen[base] or 0) + 1
            local row = n > 1 and (base .. " #" .. n) or base
            while used[row] do
                n = n + 1
                row = base .. " #" .. n
            end
            seen[base] = n
            used[row] = true
            rows[i] = { entry = o.entry, meta = meta, row = row, index = o.index }
        end
        return rows
    end

    function L.onSpot(m, x, y, z)
        local dx, dz, dy = x - m.x, z - m.z, y - m.y
        local lim = m.on and L.SPOT_KEEP or L.SPOT_R
        local on = dx * dx + dz * dz <= lim * lim and dy <= L.SPOT_Y and dy >= -L.SPOT_Y
        m.on = on
        return on
    end

    function L.aimDeg(dx, dy, fx, fy)
        local ax, ay = dx / fx, dy / fy
        return math.deg(math.atan(sqrt(ax * ax + ay * ay)))
    end

    function L.filter(rows, o)
        local range2 = o.range * o.range
        local gr2 = L.GROUP_R * L.GROUP_R
        local spots = {}
        for i = 1, #rows do
            local m = rows[i].meta
            if m then
                local pick = o.selected ~= nil and rows[i].entry == o.selected
                local dx, dy, dz = m.x - o.x, m.y - o.y, m.z - o.z
                local d2 = dx * dx + dy * dy + dz * dz
                local pass = (o.all or (o.group ~= nil and m.group == o.group)) and d2 <= range2
                if pass or pick then
                    local spot
                    for k = 1, #spots do
                        local s = spots[k]
                        local ax, az, ay = m.x - s.x, m.z - s.z, m.y - s.y
                        if ax * ax + az * az <= gr2 and abs(ay) <= L.GROUP_Y then
                            spot = s
                            break
                        end
                    end
                    if not spot then
                        spot = { x = m.x, y = m.y, z = m.z, fy = m.y - L.FEET, list = {}, d2 = d2, order = i, count = 0, groups = {}, tags = {} }
                        spots[#spots + 1] = spot
                    end
                    spot.count = spot.count + 1
                    if #spot.list < L.MAX_AIMS then
                        spot.list[#spot.list + 1] = m
                    elseif pick then
                        spot.list[L.MAX_AIMS] = m
                    end
                    if pick then spot.selected = true end
                    if not spot.groups[m.group] then
                        spot.groups[m.group] = true
                        spot.tags[#spot.tags + 1] = m.tag
                    end
                end
            end
        end
        if #spots > L.MAX_SPOTS then
            table.sort(spots, function(a, b)
                if (a.selected == true) ~= (b.selected == true) then return a.selected == true end
                if a.d2 ~= b.d2 then return a.d2 < b.d2 end
                return a.order < b.order
            end)
            for i = #spots, L.MAX_SPOTS + 1, -1 do spots[i] = nil end
            table.sort(spots, function(a, b) return a.order < b.order end)
        end
        for i = 1, #spots do
            local s = spots[i]
            local first = s.list[1]
            s.grenade = first.grenade
            if s.count > 1 then
                s.name = first.to .. " +" .. (s.count - 1)
            else
                s.name = first.to
            end
            local foreign = o.all or #s.tags > 1 or first.group ~= o.group
            s.prefix = foreign and (table.concat(s.tags, "/") .. " ") or ""
        end
        return spots
    end

    local function rotation(geometry)
        if type(geometry) ~= "string" then return nil end
        local parts = {}
        for field in string.gmatch(geometry, "[^|]+") do parts[#parts + 1] = field end
        if #parts < 13 then return nil end
        return table.concat(parts, "|", 5, 13)
    end

    function L.compareCheck(stored, cur)
        if type(stored) ~= "table" then return "ok", 0, 0, 0, nil end
        local sx, sy, sz = vec3(stored.ref)
        if not sx then return "ok", 0, 0, 0, nil end
        if type(cur) ~= "table" then cur = {} end
        local cx, cy, cz = vec3(cur.ref)
        if not cx then
            if type(stored.geometry) == "string" and stored.geometry == cur.geometry then return "ok", 0, 0, 0, nil end
            return "blocked", 0, 0, 0, "No map reference: lineups hidden"
        end
        local dx, dy, dz = cx - sx, cy - sy, cz - sz
        if abs(dx) <= 0.05 and abs(dy) <= 0.05 and abs(dz) <= 0.05 then
            local a, b = stored.fingerprint, cur.fingerprint
            if type(a) == "number" and type(b) == "number" and a ~= b then
                return "ok", 0, 0, 0, "Map has changed since saving"
            end
            return "ok", 0, 0, 0, nil
        end
        local ra, rb = rotation(stored.geometry), rotation(cur.geometry)
        if ra and rb and ra == rb then return "shift", dx, dy, dz, "Map moved: lineups shifted" end
        return "blocked", 0, 0, 0, "Map differs: lineups hidden"
    end

    function L.newEntry(c, to, throw, shift, seq, stamp, salt)
        local x, y, z = c.x, c.y, c.z
        if shift then x, y, z = x - shift[1], y - shift[2], z - shift[3] end
        local atan2 = math.atan2 or math.atan
        return {
            id = stamp .. "-" .. seq .. "-" .. salt,
            grenade = c.grenade, to = to, throw = throw,
            pos = { L.round(x, 3), L.round(y, 3), L.round(z, 3) },
            look = { L.round(c.lx, 6), L.round(c.ly, 6), L.round(c.lz, 6) },
            yaw = L.round(math.deg(atan2(-c.lx, -c.lz)), 3),
            pitch = L.round(math.deg(math.asin(c.ly > 1 and 1 or (c.ly < -1 and -1 or c.ly))), 3),
            crouch = c.crouch == true, created = stamp, builtin = false,
        }
    end

    function L.same(items, d)
        local x, y, z = vec3(d.pos)
        local lx, ly, lz = vec3(d.look)
        if not x or not lx then return false end
        for i = 1, #items do
            local e = items[i]
            if type(e) == "table" and e.grenade == d.grenade and e.throw == d.throw then
                local ex, ey, ez = vec3(e.pos)
                local ax, ay, az = vec3(e.look)
                if ex and ax and abs(ex - x) <= 0.05 and abs(ey - y) <= 0.05 and abs(ez - z) <= 0.05
                    and abs(ax - lx) <= 0.001 and abs(ay - ly) <= 0.001 and abs(az - lz) <= 0.001 then
                    return true
                end
            end
        end
        return false
    end

    function L.merge(items, defaults, map)
        local ids = {}
        for i = 1, #items do
            local e = items[i]
            if type(e) == "table" and e.id ~= nil then ids[tostring(e.id)] = true end
        end
        local added = 0
        for n = 1, #defaults do
            local d = defaults[n]
            local id = "d-" .. map .. "-" .. n
            if type(d) == "table" and not ids[id] and not L.same(items, d) then
                local e = {}
                for k, v in pairs(d) do e[k] = v end
                e.id, e.builtin = id, true
                if type(e.created) ~= "number" then e.created = n end
                items[#items + 1] = e
                ids[id] = true
                added = added + 1
            end
        end
        return added
    end

    function L.remove(items, entry)
        for i = #items, 1, -1 do
            if items[i] == entry then
                table.remove(items, i)
                return true
            end
        end
        return false
    end

    function L.load(io, map)
        local name = L.fileName(map)
        if not name then return nil end
        local store = {
            map = map, path = io.folder .. "/" .. name .. ".json", bak = io.folder .. "/" .. name .. ".bak.json",
            state = "new", readonly = false,
        }
        local ok, exists, text = pcall(function()
            if io.isfile(store.path) then return true, io.readfile(store.path) end
            return false, nil
        end)
        if not ok or (exists and type(text) ~= "string") then
            store.state = "bad"
            store.note = "Lineup file unreadable"
        elseif exists and trim(text) ~= "" then
            local okd, data = pcall(io.decode, text)
            if okd and type(data) == "table" and (data.lineups == nil or type(data.lineups) == "table") then
                store.state = "clean"
                store.text = text
                if type(data.version) ~= "number" then data.version = L.VERSION end
                if data.version > L.VERSION then
                    store.readonly = true
                    store.note = "Newer lineup file: read-only"
                end
                if type(data.lineups) ~= "table" then data.lineups = {} end
                if type(data.check) ~= "table" then data.check = nil end
                store.data = data
            else
                store.state = "bad"
                store.note = "Lineup file damaged: not touched"
            end
        end
        if not store.data then store.data = { version = L.VERSION, map = map, lineups = {} } end
        store.items = store.data.lineups
        return store
    end

    function L.save(io, store)
        if not store then return false, "no map" end
        if store.state == "bad" then return false, store.note or "lineup file is damaged" end
        if store.readonly then return false, "file is read-only (newer version)" end
        local oke, text = pcall(io.encode, store.data)
        if not oke or type(text) ~= "string" or text == "" then return false, "could not encode" end
        local okd, back = pcall(io.decode, text)
        local count = -1
        if okd and type(back) == "table" then
            count = type(back.lineups) == "table" and #back.lineups or 0
        end
        if count ~= #store.items then return false, "verify failed" end
        pcall(function()
            if not io.isfolder(io.folder) then io.makefolder(io.folder) end
        end)
        if store.state == "clean" and type(store.text) == "string" and L.backed[store.path] ~= store.text then
            pcall(io.writefile, store.bak, store.text)
        end
        local okw, err = pcall(io.writefile, store.path, text)
        if not okw then return false, "write failed: " .. tostring(err) end
        L.backed[store.path] = text
        store.text = text
        store.state = "clean"
        return true, nil
    end

    return L
end

local function EspNade(E)
    local mr, clock, floor, sqrt = memory_read, os.clock, math.floor, math.sqrt
    local Cfg, Off, D, R, W, LP = E.Cfg, E.Off, E.D, E.R, E.W, E.LP
    local ptr, vec, get, walk, attr, find1 = E.ptr, E.vec, E.get, E.walk, E.attr, E.find1
    local vis, rect, pos, col, txt, seg = D.vis, D.rect, D.pos, D.col, D.txt, D.seg
    local W2S, V3 = WorldToScreen, Vector3.new
    local UI = Shared.Nade
    local L = NadeLogic()
    local WHITE, BLACK, GOOD = Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(110, 235, 110)
    local RING, RADIUS, STUD = 24, 0.9, 0.28
    local COS, SIN = {}, {}
    for i = 1, RING do
        local a = (i - 1) / RING * math.pi * 2
        COS[i], SIN[i] = math.cos(a) * RADIUS, math.sin(a) * RADIUS
    end
    local PX, PY, POK = {}, {}, {}
    local AIM = { m = {}, x = {}, y = {}, on = {}, ang = {}, ux = {}, uy = {} }
    local N = {
        shown = false, on = false, rows = {}, byRow = {}, near = {}, count = 0, drawable = 0,
        slots = {}, aims = {}, all = {}, checkState = "wait", checkAt = 0, checkTries = 0,
        mapAt = -10, instAt = -10, rootAt = -10, heldAt = 0, filterAt = 0, capAt = -10, seq = 0,
        basisAt = -10, dead = false, blocked = false,
    }
    E.N = N
    E.nade = false
    local Http = game:GetService("HttpService")
    local io = {
        folder = Library.Folder .. "/Lineups",
        isfile = isfile, readfile = readfile, writefile = writefile, isfolder = isfolder, makefolder = makefolder,
        encode = function(value) return Http:JSONEncode(value) end,
        decode = function(text) return Http:JSONDecode(text) end,
    }
    local function readPos(part) return part.Position end
    local function addrOf(inst) return inst.Address end

    local function say(where, text, toast)
        text = tostring(text)
        local label = where == "list" and UI.ListStatus or UI.Status
        if label then label:SetText(text) end
        if toast then
            pcall(function() Library:Notify({ Message = text, Delay = 3 }) end)
        end
    end

    local function createText()
        local p = N.pending
        if not p then return "Create lineup" end
        return p.meta.tag .. " captured" .. (p.crouch and " (crouch)" or "")
    end
    local function createShow(text, hold)
        N.createUntil = hold and (clock() + 3) or nil
        UI.CreateLabel:SetText(text or createText())
    end

    local function listStatus()
        if not N.map then
            say("list", "No map")
            return
        end
        local text = N.map .. ": " .. N.count .. (N.count == 1 and " lineup" or " lineups")
        if N.count > N.drawable then text = text .. ", " .. (N.count - N.drawable) .. " invalid" end
        if N.checkState == "blocked" then text = N.map .. ": hidden (map differs)" end
        local store = N.store
        if store and store.state == "bad" then text = N.map .. ": file damaged" end
        if store and store.readonly then text = text .. " (read-only)" end
        say("list", text)
    end

    local function rebuild(keep)
        local store = N.store
        local items = store and store.items or {}
        local rows = L.rows(items, N.shift)
        local byRow, drawable = {}, 0
        local list = UI.List
        list:Clear()
        for i = 1, #rows do
            local r = rows[i]
            byRow[r.row] = r
            list:AddValue(r.row)
            if r.meta then drawable = drawable + 1 end
        end
        N.rows, N.byRow, N.count, N.drawable = rows, byRow, #rows, drawable
        listStatus()
        keep = keep or N.selected
        N.selected = nil
        if keep ~= nil then
            for i = 1, #rows do
                if rows[i].entry == keep then
                    N.selected = keep
                    list:Select(rows[i].row)
                    break
                end
            end
        end
    end

    local function ownRoot()
        local p = N.prim
        if p then
            local x, y, z = vec(p + Off.pos)
            if x then return x, y, z end
        end
        N.rootBad = true
        return nil
    end

    local function rootFind()
        local chars = find1(workspace, "Characters")
        local model = chars and find1(chars, LP.Name)
        return model and find1(model, "HumanoidRootPart") or nil
    end

    local function rootResolve()
        N.rootBad = false
        N.rootAddr, N.prim = nil, nil
        if not Off.ready then return end
        local root = rootFind()
        if not root then return end
        local ok, a = pcall(addrOf, root)
        if ok and a then N.rootAddr, N.prim = a, ptr(a + Off.prim) end
    end

    local function helperOn()
        local toggle, key = UI.Helper, UI.HelperKey
        if not toggle or toggle:Get() ~= true then return false end
        if not key or not key.Key or key.Mode == "Always on" then return true end
        return key.State == true
    end
    local function overrideOn()
        local key = UI.FilterKey
        if not key then return false end
        return key.Mode == "Always on" or (key.Key ~= nil and key.State == true)
    end

    local function refilter()
        local x, y, z = ownRoot()
        local ready = N.on and N.map and x and (N.checkState == "ok" or N.checkState == "shift")
        if not ready then
            if #N.near > 0 then N.near = {} end
            return
        end
        local range = (tonumber(UI.Distance:Get()) or 30) / STUD
        N.near = L.filter(N.rows, {
            x = x, y = y, z = z, range = range, group = N.group, all = overrideOn(),
            selected = Window.Visible and N.selected or nil,
        })
    end

    local function readCheck()
        local inst = find1(workspace, "Map")
        if not inst then return nil end
        local geo = attr(inst, "MovementV2CanonicalGeometry")
        if geo == nil then geo = attr(workspace, "MovementV2CanonicalGeometry") end
        local fp = attr(inst, "MovementV2CollisionFingerprint")
        if fp == nil then fp = attr(workspace, "MovementV2CollisionFingerprint") end
        local cur = {}
        if type(geo) == "string" then cur.geometry = geo end
        if type(fp) == "number" then cur.fingerprint = fp end
        local ref = find1(find1(inst, "Reference"), "Reference")
        if ref then
            local ok, v = pcall(readPos, ref)
            if ok and v and v.X == v.X then cur.ref = { L.round(v.X, 4), L.round(v.Y, 4), L.round(v.Z, 4) } end
        end
        return cur
    end

    local function checkStep()
        local store = N.store
        if not store then return end
        local ok, cur = pcall(readCheck)
        if not ok then cur = nil end
        N.checkTries = N.checkTries + 1
        if (not cur or (not cur.ref and not cur.geometry)) and N.checkTries < 5 then return end
        N.cur = cur
        local state, dx, dy, dz, note = L.compareCheck(store.data.check, cur)
        N.checkState = state
        N.shift = state == "shift" and { dx, dy, dz } or nil
        rebuild()
        if note then say("list", note, true) end
    end

    local function loadMap(map)
        N.map = map
        N.store, N.shift, N.cur = nil, nil, nil
        N.checkState, N.checkAt, N.checkTries = "wait", 0, 0
        N.selected = nil
        N.near = {}
        if map then
            N.store = L.load(io, map)
            if not N.store then N.map = nil end
            local p = N.pending
            if p and p.map ~= map then
                N.pending, N.pendSpot = nil, nil
                createShow(nil, false)
                say("create", "Capture dropped: map changed", true)
            end
        end
        rebuild()
        local store = N.store
        if store and store.note then say("list", store.note, true) end
    end

    local function mapPoll(now, force)
        local name
        local h = W.ws
        if h and h.ok and not h.stale and not force and N.map then name = get(h, "Map") end
        if name == nil or name ~= N.map then name = attr(workspace, "Map") end
        if type(name) ~= "string" or name == "" then name = nil end
        if force or now - N.instAt >= 2 then
            N.instAt = now
            local inst = find1(workspace, "Map")
            local addr = nil
            if inst then
                local ok, a = pcall(addrOf, inst)
                if ok then addr = a end
            end
            if addr ~= N.mapAddr or (inst and N.mapName ~= name) then
                N.mapAddr = addr
                local mn = inst and attr(inst, "MapName") or nil
                N.mapName = (type(mn) == "string" and mn ~= "") and mn or nil
            end
        end
        local agreed = (name ~= nil and name == N.mapName) and name or nil
        if agreed ~= N.map then loadMap(agreed) end
    end

    local function heldPoll(now)
        local h = W.lp
        local eq, dead, spec
        if h and not h.ok and now - h.at > 0.2 then
            h = walk(LP.Address)
            W.lp = h
        end
        if h and h.ok then
            eq = get(h, "CurrentEquipped")
            if eq == nil and h.stale and now - h.at > 0.2 then
                h = walk(LP.Address)
                W.lp = h
                eq = get(h, "CurrentEquipped")
            end
            dead, spec = get(h, "Dead"), get(h, "IsSpectating")
        end
        local name = L.heldName(eq)
        local group = L.groupOf(name)
        if group then
            N.group, N.groupAt = group, now
        elseif N.group and now - (N.groupAt or 0) > 0.5 then
            N.group = nil
        end
        N.dead = dead == true or spec == true
        local gs = W.state
        N.blocked = gs == "Map Voting" or gs == "Game Ending"
    end

    local function sample()
        local root = rootFind()
        local cam = workspace.CurrentCamera
        if not root or not cam then return nil end
        local p = root.Position
        local cf = cam.CFrame
        if not p or not cf then return nil end
        local l, c = cf.LookVector, cf.Position
        return { x = p.X, y = p.Y, z = p.Z, lx = l.X, ly = l.Y, lz = l.Z, cy = c.Y }
    end

    local function refuse(why)
        createShow(why, true)
        say("create", why, true)
        return false, why
    end

    local function captureBegin(now)
        mapPoll(now, true)
        local gs = W.state
        if not N.map or gs == "Map Voting" or gs == "Game Ending" then return refuse("No map right now") end
        if attr(LP, "Dead") == true then return refuse("You are dead") end
        if attr(LP, "IsSpectating") == true then return refuse("You are spectating") end
        local held = L.heldName(attr(LP, "CurrentEquipped"))
        local spec = held and L.GRENADES[held]
        if not spec then return refuse("Not holding a grenade") end
        local oka, a = pcall(sample)
        if not oka or not a then return refuse("No character") end
        N.cap = { a = a, at = now, map = N.map, held = held, spec = spec }
        E.nade = true
        createShow("Hold still...", true)
        return true, "sampling"
    end

    local function captureEnd(c)
        if c.map ~= N.map then return refuse("No map right now") end
        local a = c.a
        local okb, b = pcall(sample)
        if not okb or not b then return refuse("No character") end
        if attr(LP, "Dead") == true then return refuse("You are dead") end
        local cur = L.heldName(attr(LP, "CurrentEquipped"))
        if cur ~= c.held then return refuse("Not holding a grenade") end
        local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
        if dx * dx + dz * dz >= 0.0004 then return refuse("Moving: stand still") end
        if dy >= 0.02 or dy <= -0.02 or attr(LP, "IsJumping") == true then return refuse("In the air: stand still") end
        local ex, ey, ez = b.lx - a.lx, b.ly - a.ly, b.lz - a.lz
        if ex * ex + ey * ey + ez * ez > 2e-7 then return refuse("View moving: hold the aim") end
        local len = sqrt(b.lx * b.lx + b.ly * b.ly + b.lz * b.lz)
        if len < 0.99 or len > 1.01 then return refuse("No camera") end
        local held, spec = c.held, c.spec
        local crouch = (a.cy - a.y < 1.15 and b.cy - b.y < 1.15) or attr(LP, "IsCrouching") == true
        local p = {
            map = c.map, grenade = held, x = b.x, y = b.y, z = b.z, lx = b.lx / len, ly = b.ly / len, lz = b.lz / len,
            crouch = crouch, at = clock(),
        }
        p.meta = {
            x = p.x, y = p.y, z = p.z, lx = p.lx, ly = p.ly, lz = p.lz, grenade = held, group = spec.group, tag = spec.tag,
            crouch = crouch, text = L.instruction(UI.Throw:Get(), crouch), to = "NEW", on = false,
        }
        N.pending = p
        N.pendSpot = {
            x = p.x, y = p.y, z = p.z, fy = p.y - L.FEET, list = { p.meta }, count = 1, grenade = held,
            name = "NEW " .. spec.tag, prefix = "", preview = true,
        }
        createShow(nil, false)
        say("create", "Captured: name it, then save", true)
        return true, nil
    end

    local function guarded(fn, arg)
        local ok, good, why = pcall(fn, arg)
        if not ok then
            E.report(good)
            refuse("Capture failed")
            return false, tostring(good)
        end
        return good, why
    end

    function UI.OnCreate()
        local now = clock()
        if now - N.capAt < 0.3 or (N.cap and now - N.capAt < 2) then return end
        N.capAt = now
        N.cap = nil
        guarded(captureBegin, now)
    end

    local function captureStep(now)
        local c = N.cap
        if not c or now - c.at < 0.15 then return end
        N.cap = nil
        guarded(captureEnd, c)
    end

    function UI.OnSave()
        local p = N.pending
        if not p then
            say("create", "Nothing captured: press the key", true)
            return false
        end
        local store = N.store
        if not N.map or not store or p.map ~= N.map then
            say("create", "No map right now", true)
            return false
        end
        local to = L.trim(UI.To:Get())
        if to == "" then
            say("create", "Type To first", true)
            return false
        end
        if store.state == "bad" or store.readonly then
            say("create", store.note or "Lineup file is read-only", true)
            return false
        end
        if N.checkState == "blocked" or N.checkState == "wait" then
            say("create", N.checkState == "wait" and "Map check running: try again" or "Map differs: cannot save here", true)
            return false
        end
        N.seq = N.seq + 1
        local entry = L.newEntry(p, to, tostring(UI.Throw:Get()), N.shift, N.seq, os.time(), math.random(1000, 9999))
        store.items[#store.items + 1] = entry
        if store.data.check == nil and N.cur and (N.cur.ref or N.cur.geometry) then store.data.check = N.cur end
        local ok, why = L.save(io, store)
        if not ok then
            L.remove(store.items, entry)
            say("create", "Not saved: " .. tostring(why), true)
            return false
        end
        N.pending, N.pendSpot = nil, nil
        createShow(nil, false)
        rebuild(entry)
        refilter()
        say("create", "Saved: " .. to)
        return true
    end

    function UI.OnSelect(row)
        local r = row and N.byRow[row] or nil
        N.selected = r and r.entry or nil
        if not r then return end
        local m = r.meta
        if m then
            say("list", m.tag .. ", " .. m.throw .. (m.crouch and ", crouch" or ""))
        else
            say("list", "Invalid entry: delete only")
        end
    end

    function UI.OnDelete()
        local row = UI.List:Get()
        local r = row and N.byRow[row] or nil
        local store = N.store
        if not r or not store then
            say("list", "Select a lineup first", true)
            return false
        end
        if store.state == "bad" or store.readonly then
            say("list", store.note or "Lineup file is read-only", true)
            return false
        end
        local items, at = store.items, nil
        for i = 1, #items do
            if items[i] == r.entry then
                at = i
                break
            end
        end
        if at then
            table.remove(items, at)
            local ok, why = L.save(io, store)
            if not ok then
                table.insert(items, at, r.entry)
                say("list", "Not deleted: " .. tostring(why), true)
                return false
            end
        end
        N.selected = nil
        rebuild()
        refilter()
        say("list", "Deleted. " .. tostring(N.map) .. ": " .. N.count .. (N.count == 1 and " lineup" or " lineups"))
        return true
    end

    function UI.OnDefaults()
        local store = N.store
        if not N.map or not store then
            say("list", "No map", true)
            return false
        end
        local defaults = L.DEFAULTS[N.map]
        if type(defaults) ~= "table" or #defaults == 0 then
            say("list", N.map .. ": no built-in lineups yet", true)
            return false
        end
        if store.state == "bad" or store.readonly then
            say("list", store.note or "Lineup file is read-only", true)
            return false
        end
        local added = L.merge(store.items, defaults, N.map)
        if added == 0 then
            say("list", "Defaults already loaded", true)
            return true
        end
        local ok, why = L.save(io, store)
        rebuild()
        refilter()
        say("list", ok and ("Added " .. added .. " built-in lineups") or ("Added, not written: " .. tostring(why)), true)
        return ok
    end

    local function tickBody(now)
        if N.createUntil and now > N.createUntil then createShow(nil, false) end
        if N.cap then captureStep(now) end
        local p = N.pending
        if p then
            if now - p.at > 300 then
                N.pending, N.pendSpot = nil, nil
                createShow(nil, false)
                say("create", "Capture expired")
            else
                p.meta.text = L.instruction(UI.Throw:Get(), p.crouch)
            end
        end
        N.on = helperOn()
        if not N.on and #N.near > 0 then N.near = {} end
        local want = N.on or N.pending ~= nil or N.cap ~= nil
        E.nade = want
        if now - N.mapAt >= ((want or Window.Visible) and 1 or 3) then
            N.mapAt = now
            mapPoll(now, false)
            return
        end
        if N.map and N.checkState == "wait" and now - N.checkAt >= 1 then
            N.checkAt = now
            checkStep()
            return
        end
        if not want then return end
        if now - N.rootAt >= 1 or (N.rootBad and now - N.rootAt >= 0.2) then
            N.rootAt = now
            rootResolve()
            return
        end
        local ra = N.rootAddr
        if ra and N.prim and mr("uintptr", ra + Off.prim) ~= N.prim then N.rootBad = true end
        if now - N.heldAt >= 0.045 then
            N.heldAt = now
            heldPoll(now)
        end
        if now - N.filterAt >= 0.1 then
            N.filterAt = now
            refilter()
        end
    end

    function E.nadeTick(now)
        local ok, err = pcall(tickBody, now)
        if not ok then E.report(err) end
    end

    local function keep(d)
        N.all[#N.all + 1] = d
        return d
    end
    local function newSlot()
        local s = { on = false, ring = {} }
        for i = 1, RING do
            local d = keep(D.line())
            d.o.Thickness = 2
            s.ring[i] = d
        end
        s.dot = keep(D.square(true, WHITE))
        s.name = keep(D.text(13, true))
        s.info = keep(D.text(13, true))
        N.slots[#N.slots + 1] = s
        return s
    end
    local function newAim()
        local a = { on = false, arrow = {} }
        a.o = keep(D.square(false, BLACK))
        a.m = keep(D.square(false, WHITE))
        a.i = keep(D.square(false, BLACK))
        a.c = keep(D.square(true, WHITE))
        a.to = keep(D.text(13, true))
        a.ins = keep(D.text(13, true))
        for i = 1, 3 do
            local d = keep(D.line())
            d.o.Thickness = 2
            a.arrow[i] = d
        end
        N.aims[#N.aims + 1] = a
        return a
    end

    local function hideLabel(s)
        vis(s.name, false)
        vis(s.info, false)
        if s.img then vis(s.img, false) end
    end
    local function hideSpot(s)
        s.sp = nil
        if not s.on then return end
        s.on = false
        local ring = s.ring
        for i = 1, RING do vis(ring[i], false) end
        vis(s.dot, false)
        hideLabel(s)
    end
    local function hideAim(a)
        if not a.on then return end
        a.on = false
        vis(a.o, false)
        vis(a.m, false)
        vis(a.i, false)
        vis(a.c, false)
        vis(a.to, false)
        vis(a.ins, false)
        for i = 1, 3 do vis(a.arrow[i], false) end
    end

    local function drawSpot(s, sp, x, y, z, any, accent)
        s.sp, s.any = sp, any
        local cx, cy, cz = sp.x, sp.fy, sp.z
        local dx, dy, dz = cx - R.cx, cy - R.cy, cz - R.cz
        local camd = sqrt(dx * dx + dy * dy + dz * dz)
        local sv, on = W2S(V3(cx, cy, cz))
        if not on and camd > 10 then
            hideSpot(s)
            s.sp = sp
            return
        end
        s.on = true
        local color = any and GOOD or ((sp.selected or sp.preview) and WHITE or accent)
        local step = camd > 50 and 2 or 1
        local count = RING / step
        for k = 1, count do
            local i = (k - 1) * step + 1
            local pv, pon = W2S(V3(cx + COS[i], cy, cz + SIN[i]))
            POK[k] = pon
            if pon then PX[k], PY[k] = floor(pv.X + 0.5), floor(pv.Y + 0.5) end
        end
        local ring = s.ring
        for k = 1, count do
            local b = k % count + 1
            local d = ring[k]
            if POK[k] and POK[b] then
                seg(d, PX[k], PY[k], PX[b], PY[b])
                col(d, color)
                vis(d, true)
            else
                vis(d, false)
            end
        end
        for k = count + 1, RING do vis(ring[k], false) end
        if not on then
            vis(s.dot, false)
            hideLabel(s)
            return
        end
        local sx, sy = floor(sv.X + 0.5), floor(sv.Y + 0.5)
        local d = s.dot
        rect(d, sx - 1, sy - 1, 3, 3)
        col(d, color)
        vis(d, true)
        if any then
            hideLabel(s)
            return
        end
        local ex, ey, ez = sp.x - x, sp.y - y, sp.z - z
        local metres = floor(sqrt(ex * ex + ey * ey + ez * ez) * STUD + 0.5)
        local yy = sy - 34
        local ic = Cfg.get_icons and E.iconOf and E.iconOf(sp.grenade) or nil
        local prefix = ic and "" or sp.prefix
        if s.im ~= metres or s.ip ~= prefix then
            s.im, s.ip = metres, prefix
            s.it = prefix .. metres .. "m"
        end
        if ic then
            local di = s.img
            if not di then
                local o = Drawing.new("Image")
                o.Visible = false
                o.ZIndex = 998
                di = keep({ o = o, vis = false })
                s.img = di
            end
            if s.imgOf ~= ic then
                s.imgOf = ic
                di.o.Data = ic.data
            end
            yy = sy - 50
            rect(di, sx - floor(ic.w / 2), yy, ic.w, ic.h)
            col(di, color)
            vis(di, true)
            yy = yy + 16
        elseif s.img then
            vis(s.img, false)
        end
        d = s.name
        txt(d, sp.name)
        pos(d, sx, yy + 6)
        col(d, sp.selected and accent or WHITE)
        vis(d, true)
        d = s.info
        txt(d, s.it)
        pos(d, sx, yy + 20)
        vis(d, true)
    end

    local function drawAims(count, accent, now)
        local aims = N.aims
        if count == 0 then
            for i = 1, #aims do hideAim(aims[i]) end
            N.aimed = false
            return
        end
        local vw, vh = E.vw or 1920, E.vh or 1080
        local hx, hy = vw / 2, vh / 2
        if now - R.fitAt > 0.25 then
            R.fitAt = now
            if D.basis() then
                local fx3 = R.bx + R.lx * 10 + R.rx * 3 + R.ux * 2
                local fy3 = R.by + R.ly * 10 + R.ry * 3 + R.uy * 2
                local fz3 = R.bz + R.lz * 10 + R.rz * 3 + R.uz * 2
                local fv, fon = W2S(V3(fx3, fy3, fz3))
                if fon then D.fit(fx3, fy3, fz3, fv.X, fv.Y, now) end
            end
        end
        local fy = R.fy or hy / 0.7002075
        local fx = R.fx or fy * 1.256
        local best, bestAng = 0, 1e9
        for i = 1, count do
            local m = AIM.m[i]
            local sv, on = W2S(V3(R.cx + m.lx * 1000, R.cy + m.ly * 1000, R.cz + m.lz * 1000))
            local ang
            if on then
                AIM.x[i], AIM.y[i] = floor(sv.X + 0.5), floor(sv.Y + 0.5)
                ang = L.aimDeg(sv.X - hx, sv.Y - hy, fx, fy)
            else
                if now - N.basisAt > 0.03 then
                    N.basisAt = now
                    N.basisOk = D.basis()
                end
                ang = 180
                AIM.ux[i], AIM.uy[i] = 0, 1
                if N.basisOk then
                    local rx = m.lx * R.rx + m.ly * R.ry + m.lz * R.rz
                    local uy = m.lx * R.ux + m.ly * R.uy + m.lz * R.uz
                    local zz = m.lx * R.lx + m.ly * R.ly + m.lz * R.lz
                    local len = sqrt(rx * rx + uy * uy)
                    if len > 1e-4 then AIM.ux[i], AIM.uy[i] = rx / len, -uy / len end
                    if zz > 1 then zz = 1 elseif zz < -1 then zz = -1 end
                    ang = math.deg(math.acos(zz))
                    if ang < 2 then ang = 2 end
                end
            end
            AIM.on[i], AIM.ang[i] = on, ang
            if ang < bestAng then best, bestAng = i, ang end
        end
        N.aimed = bestAng <= L.AIM_DEG
        for i = 1, count do
            local m = AIM.m[i]
            local a = aims[i] or newAim()
            a.on = true
            local near = i == best
            if AIM.on[i] then
                local mx, my = AIM.x[i], AIM.y[i]
                local aimed = near and N.aimed
                local c = aimed and GOOD or accent
                local d = a.o
                rect(d, mx - 5, my - 5, 11, 11)
                vis(d, true)
                d = a.m
                rect(d, mx - 4, my - 4, 9, 9)
                col(d, c)
                vis(d, true)
                d = a.i
                rect(d, mx - 3, my - 3, 7, 7)
                vis(d, true)
                d = a.c
                if aimed then
                    rect(d, mx - 1, my - 1, 3, 3)
                    col(d, c)
                    vis(d, true)
                else
                    vis(d, false)
                end
                d = a.to
                txt(d, m.to)
                pos(d, mx, my + 16)
                col(d, aimed and GOOD or WHITE)
                vis(d, true)
                d = a.ins
                if near then
                    txt(d, m.text)
                    pos(d, mx, my + 30)
                    col(d, aimed and GOOD or WHITE)
                    vis(d, true)
                else
                    vis(d, false)
                end
                for k = 1, 3 do vis(a.arrow[k], false) end
            else
                vis(a.o, false)
                vis(a.m, false)
                vis(a.i, false)
                vis(a.c, false)
                vis(a.ins, false)
                local ux, uy = AIM.ux[i], AIM.uy[i]
                local tx, ty = floor(hx + ux * 115 + 0.5), floor(hy + uy * 115 + 0.5)
                local bx, by = hx + ux * 105, hy + uy * 105
                local d = a.arrow[1]
                seg(d, floor(hx + ux * 90 + 0.5), floor(hy + uy * 90 + 0.5), tx, ty)
                col(d, accent)
                vis(d, true)
                d = a.arrow[2]
                seg(d, floor(bx - uy * 6 + 0.5), floor(by + ux * 6 + 0.5), tx, ty)
                col(d, accent)
                vis(d, true)
                d = a.arrow[3]
                seg(d, floor(bx + uy * 6 + 0.5), floor(by - ux * 6 + 0.5), tx, ty)
                col(d, accent)
                vis(d, true)
                local whole = floor(AIM.ang[i] + 0.5)
                if a.om ~= m or a.oa ~= whole then
                    a.om, a.oa = m, whole
                    a.ot = m.to .. " " .. whole .. DEGREE
                end
                d = a.to
                txt(d, a.ot)
                pos(d, floor(hx + ux * 135 + 0.5), floor(hy + uy * 135 + 0.5) + 6)
                col(d, WHITE)
                vis(d, true)
            end
        end
        for i = count + 1, #aims do hideAim(aims[i]) end
    end

    local function hideAll()
        local slots, aims = N.slots, N.aims
        for i = 1, #slots do hideSpot(slots[i]) end
        for i = 1, #aims do hideAim(aims[i]) end
        N.aimed = false
    end

    local function frameBody(now)
        local x, y, z
        if N.map and not N.dead and not N.blocked then x, y, z = ownRoot() end
        if not x then
            hideAll()
            return
        end
        local spots, pend = N.near, N.pendSpot
        local n = #spots
        local total = n + (pend and 1 or 0)
        local hold = total >= 3 and R.frame % 2 or -1
        local accent = Library.Theme.Default.Accent or WHITE
        local slots = N.slots
        local count, built = 0, false
        for i = 1, total do
            local sp = i <= n and spots[i] or pend
            local list = sp.list
            local any = false
            for k = 1, #list do
                local m = list[k]
                if L.onSpot(m, x, y, z) then
                    any = true
                    if count < L.MAX_AIMS then
                        count = count + 1
                        AIM.m[count] = m
                    end
                end
            end
            local s = slots[i]
            if not s and not built and #slots == i - 1 then
                s = newSlot()
                built = true
            end
            if s and not (s.sp == sp and s.any == any and hold == i % 2) then
                drawSpot(s, sp, x, y, z, any, accent)
            end
        end
        for i = total + 1, #slots do hideSpot(slots[i]) end
        drawAims(count, accent, now)
    end

    function E.nadeFrame(now)
        N.shown = true
        local ok, err = pcall(frameBody, now)
        if not ok then
            E.report(err)
            pcall(hideAll)
        end
    end

    function E.nadeHide()
        N.shown = false
        hideAll()
    end

    function E.nadeRemove()
        local all = N.all
        for i = 1, #all do
            local o = all[i].o
            pcall(function() o.Visible = false end)
            pcall(function() o:Remove() end)
        end
        N.all, N.slots, N.aims = {}, {}, {}
        for _, name in ipairs({ "OnCreate", "OnSave", "OnSelect", "OnDelete", "OnDefaults" }) do UI[name] = nil end
    end

end

do
    local E = { Cfg = Esp.Cfg, Key = Esp.Key }
    local ok, err = pcall(function()
        EspCore(E)
        EspWorld(E)
        EspSound(E)
        EspDraw(E)
        EspOther(E)
        EspNade(E)
        EspRun(E)
    end)
    if not ok then warn("Blox Strike ESP failed to start: " .. tostring(err)) end
end
