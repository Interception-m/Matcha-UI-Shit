local ok, Library = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Interception-m/Matcha-UI-Shit/refs/heads/main/gamesense_lib.lua"))()
    return _G.Library
end)
if not ok or type(Library) ~= "table" then
    warn("gamesense_lib.lua failed to load: " .. tostring(Library))
    return
end

local Players = game:GetService("Players")

local HOLD, ALWAYS = "On hotkey", "Always on"
local DEGREE = "\194\176"
local INFINITY = "\226\136\158"
local HITBOXES = { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" }

local function Unpack(Value)
    local R = Value % 256
    local G = math.floor(Value / 256) % 256
    local B = math.floor(Value / 65536) % 256
    local A = math.floor(Value / 16777216) % 256
    return Color3.fromRGB(R, G, B), 1 - A / 255
end

local function Pick(Owner, Flag, Value, Callback)
    local Color, Alpha = Unpack(Value)
    return Owner:ColorPicker({ Flag = Flag, Default = Color, Alpha = Alpha, Callback = Callback })
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

local Window = Library:Window({ CloseBind = Enum.KeyCode.Insert })
local Rage = Window:CreateTab({ Icon = "rage", Name = "RAGE" })
local AntiAim = Window:CreateTab({ Icon = "aa", Name = "AA" })
local Legit = Window:CreateTab({ Icon = "legit", Name = "LEGIT" })
local Visuals = Window:CreateTab({ Icon = "visuals", Name = "VISUALS" })
local Misc = Window:CreateTab({ Icon = "misc", Name = "MISC" })
local Skins = Window:CreateTab({ Icon = "skins", Name = "SKINS" })
local PlayersTab = Window:CreateTab({ Icon = "players", Name = "PLAYERS" })
local Config = Window:CreateTab({ Icon = "config", Name = "CONFIG" })
local Lua = Window:CreateTab({ Name = "Lua", Hidden = true })
local Shared = {}

Window:SetTab(1)

do
    local Selector = Rage:ImageDropdown({
        Name = "Weapon type",
        Flag = "rage_weapon_group",
        Default = "Global",
        Options = {
            "Global", "G3SG1 / SCAR-20", "SSG 08", "AWP", "R8 Revolver", "Desert Eagle",
            "Pistol", "Zeus", "Rifle", "Shotgun", "SMG", "Machine gun",
        },
    })
    local Aim = Box(Rage, "Aimbot", 0, 12, 0, 24, true)
    local Other = Box(Rage, "Other", 12, 12, 0, 24, true)
    Aim:BindGroups(Selector)

    local C = {}
    local function Rule()
        if not C.Ready then return end
        local Selected = C.Hitbox:Get()
        local Allowed = Has(Selected, "Head") and (Has(Selected, "Chest") or Has(Selected, "Stomach"))
        if not Allowed and C.PreferBody:Get() then C.PreferBody:Set(false) end
        C.PreferBody:SetVisible(Allowed)
        C.PointScale:SetVisible(#C.MultiPoint:Get() > 0)
    end
    local function Damage(Value)
        if Value > 100 then return "HP+" .. (Value - 100) end
    end

    Key(Aim:Toggle({ Name = "Enabled", Flag = "rage_enabled" }), "rage_activation", HOLD, 0x06)
    Aim:Dropdown({
        Name = "Target selection", Flag = "rage_target_selection",
        Content = { "Highest damage", "Cycle", "Cycle (2x)", "Near crosshair", "Best hit chance" }, Default = "Cycle",
    })
    C.Hitbox = Aim:MultiBox({
        Name = "Target hitbox", Flag = "rage_target_hitboxes", Content = HITBOXES, Default = { "Head" },
        RequireOne = true, Callback = Rule,
    })
    C.MultiPoint = Aim:MultiBox({ Name = "Multi-point", Flag = "rage_multipoint", Content = HITBOXES, Callback = Rule })
    Key(C.MultiPoint, "rage_multipoint_key", ALWAYS)
    C.PointScale = Aim:Slider({
        Name = "Multi-point scale", Flag = "rage_multipoint_scale", Min = 24, Max = 100, Default = 90,
        Ending = "%", ValueLabels = { [24] = "Auto" }, Hidden = true,
    })
    Aim:Slider({
        Name = "Minimum hit chance", Flag = "rage_minimum_hit_chance", Min = 0, Max = 100, Default = 50,
        Ending = "%", ValueLabels = { [0] = "Off" },
    })
    Aim:Slider({
        Name = "Minimum damage", Flag = "rage_minimum_damage", Min = 0, Max = 126, Default = 10,
        ValueLabels = { [0] = "Auto" }, Formatter = Damage,
    })
    local Override = Aim:Toggle({ Name = "Minimum damage override", Flag = "rage_damage_override" })
    Key(Override, "rage_damage_override_key", HOLD)
    Override:Tie(Aim:Slider({
        Name = "", Flag = "rage_override_damage", Min = 0, Max = 126, Default = 10,
        ValueLabels = { [0] = "Auto" }, Formatter = Damage,
    }))
    Aim:Toggle({ Name = "Prefer safe point", Flag = "rage_prefer_safe_point" })
    Key(Aim:Label({ Message = "Force safe point" }), "rage_force_safe_point", HOLD)
    Aim:MultiBox({ Name = "Avoid unsafe hitboxes", Flag = "rage_avoid_unsafe_hitboxes", Content = HITBOXES })
    C.PreferBody = Aim:Toggle({ Name = "Prefer body aim", Flag = "rage_prefer_body_aim", Hidden = true })
    C.PreferBody:Tie(Aim:MultiBox({
        Name = "Prefer body aim disablers", Flag = "rage_body_aim_disablers",
        Content = { "Low inaccuracy", "Target shot fired", "Target resolved", "Safe point headshot" },
    }))
    Key(Aim:Label({ Message = "Force body aim" }), "rage_force_body_aim", HOLD)
    Aim:Toggle({ Name = "Force body aim on peek", Flag = "rage_force_body_aim_on_peek" })
    local Stop = Aim:Toggle({ Name = "Quick stop", Flag = "rage_quick_stop" })
    Key(Stop, "rage_quick_stop_key", ALWAYS)
    Stop:Tie(Aim:MultiBox({
        Name = "", Flag = "rage_quick_stop_options",
        Content = { "Early", "Slow motion", "Duck", "Fake duck", "Move between shots", "Ignore molotov", "Taser", "Jump scout" },
    }))
    local DoubleTap = Aim:Toggle({ Name = "Double tap", Flag = "rage_double_tap", Risky = true })
    Key(DoubleTap, "rage_double_tap_key", HOLD)
    DoubleTap:Tie(
        Aim:Dropdown({ Name = "", Flag = "rage_double_tap_mode", Content = { "Offensive", "Defensive" }, Default = "Offensive" }),
        Aim:Slider({ Name = "Double tap hit chance", Flag = "rage_double_tap_hit_chance", Min = 0, Max = 100, Default = 50, Ending = "%" }),
        Aim:Slider({ Name = "Double tap fake lag limit", Flag = "rage_double_tap_fake_lag_limit", Min = 1, Max = 10, Default = 2 }),
        Aim:MultiBox({ Name = "Double tap quick stop", Flag = "rage_double_tap_quick_stop", Content = { "Slow motion", "Duck", "Move between shots" } })
    )
    Aim:Toggle({ Name = "Automatic scope", Flag = "rage_automatic_scope" })
    C.Ready = true
    Rule()

    Other:Dropdown({ Name = "Accuracy boost", Flag = "rage_accuracy_boost", Content = { "Low", "Medium", "High", "Maximum" }, Default = "Low" })
    Other:Toggle({ Name = "Anti-aim correction", Flag = "rage_anti_aim_correction" })
    Other:Toggle({ Name = "Automatic fire", Flag = "rage_automatic_fire" })
    Other:Toggle({ Name = "Automatic penetration", Flag = "rage_automatic_penetration" })
    Other:Toggle({ Name = "Silent aim", Flag = "rage_silent_aim" })
    Other:Toggle({ Name = "Remove recoil", Flag = "rage_remove_recoil" })
    Other:Toggle({ Name = "Delay shot", Flag = "rage_delay_shot" })
    local Peek = Other:Toggle({ Name = "Quick peek assist", Flag = "quick_peek_enabled" })
    Key(Peek, "quick_peek_hotkey", HOLD)
    local PeekMode = Other:MultiBox({
        Name = "Quick peek assist mode", Flag = "quick_peek_mode",
        Content = { "Retreat on shot", "Retreat on key release" }, Default = { "Retreat on shot", "Retreat on key release" },
    })
    Pick(PeekMode, "quick_peek_color", 0x4D0000FF)
    Peek:Tie(PeekMode, Other:Slider({
        Name = "Quick peek assist distance", Flag = "quick_peek_distance", Min = 16, Max = 201, Default = 201,
        Ending = "in", ValueLabels = { [201] = INFINITY },
    }))
    Key(Other:Label({ Message = "Duck peek assist" }), "rage_duck_peek_assist", HOLD)
    Other:Toggle({ Name = "Reduce aim step", Flag = "rage_reduce_aim_step" })
    Other:Slider({ Name = "Reduce aim step limit", Flag = "rage_aim_step_limit", Min = 2, Max = 29, Default = 15, Ending = DEGREE, Hidden = true })
    Other:Slider({ Name = "Maximum FOV", Flag = "rage_maximum_fov", Min = 1, Max = 180, Default = 180, Ending = DEGREE })
    Other:Toggle({ Name = "Log misses due to spread", Flag = "rage_log_spread_misses", Default = true })
    Other:MultiBox({
        Name = "Low FPS mitigations", Flag = "rage_low_fps_mitigations",
        Content = {
            "Force low accuracy boost", "Disable multipoint: feet", "Disable multipoint: arms", "Disable multipoint: legs",
            "Disable hitbox: feet", "Lower hit chance precision", "Limit targets per tick",
        },
    })
    local Rework = Other:Toggle({ Name = "Extrapolation rework", Flag = "rage_extrapolation_rework", Risky = true })
    Rework:Tie(Other:Toggle({ Name = "Visualize", Flag = "rage_extrapolation_visualize" }))
end

do
    local Angles = Box(AntiAim, "Anti-aimbot angles", 0, 12, 0, 24)
    local FakeLag = Box(AntiAim, "Fake lag", 12, 12, 0, 12)
    local Other = Box(AntiAim, "Other", 12, 12, 12, 12)

    local C = { Yaw = {}, Body = {} }
    local function Rule()
        if not C.Ready then return end
        local Yaw, Jitter, Body = C.YawMode:Get(), C.Jitter:Get(), C.BodyMode:Get()
        C.Pitch:SetVisible(C.PitchMode:Get() == "Custom")
        for Name, Slider in pairs(C.Yaw) do Slider:SetVisible(Yaw == Name) end
        C.Jitter:SetVisible(Yaw ~= "Off")
        C.JitterOffset:SetVisible(Yaw ~= "Off" and Jitter ~= "Off")
        for Name, Slider in pairs(C.Body) do Slider:SetVisible(Body == Name) end
        C.FreestandingBody:SetVisible(Body ~= "Off")
    end
    local function Offset(Flag, Min, Max, Default)
        return Angles:Slider({ Name = "", Flag = Flag, Min = Min, Max = Max, Default = Default, Ending = DEGREE, Hidden = true })
    end

    Angles:Toggle({ Name = "Enabled", Flag = "aa_enabled" })
    C.PitchMode = Angles:Dropdown({
        Name = "Pitch", Flag = "aa_pitch", Default = "Off", Callback = Rule,
        Content = { "Off", "Default", "Up", "Down", "Minimal", "Random", "Custom" },
    })
    C.Pitch = Offset("aa_custom_pitch", -89, 89, 0)
    Angles:Dropdown({ Name = "Yaw base", Flag = "aa_yaw_base", Content = { "Local view", "At targets" }, Default = "Local view" })
    C.YawMode = Angles:Dropdown({
        Name = "Yaw", Flag = "aa_yaw", Default = "Off", Callback = Rule,
        Content = { "Off", "180", "Spin", "Static", "180 Z", "Crosshair" },
    })
    C.Yaw["180"] = Offset("aa_yaw_offset_180", -180, 180, -12)
    C.Yaw["Spin"] = Offset("aa_yaw_offset_spin", -180, 180, 80)
    C.Yaw["Static"] = Offset("aa_yaw_offset_static", -180, 180, 0)
    C.Yaw["180 Z"] = Offset("aa_yaw_offset_180z", -180, 180, 0)
    C.Yaw["Crosshair"] = Offset("aa_yaw_offset_crosshair", -180, 180, 0)
    C.Jitter = Angles:Dropdown({
        Name = "Yaw jitter", Flag = "aa_yaw_jitter", Default = "Off", Hidden = true, Callback = Rule,
        Content = { "Off", "Offset", "Center", "Random", "Skitter" },
    })
    C.JitterOffset = Offset("aa_yaw_jitter_offset", -180, 180, 0)
    C.BodyMode = Angles:Dropdown({
        Name = "Body yaw", Flag = "aa_body_yaw", Default = "Off", Callback = Rule,
        Content = { "Off", "Opposite", "Jitter", "Static" },
    })
    C.Body["Jitter"] = Offset("aa_body_yaw_offset_jitter", -180, 180, 0)
    C.Body["Static"] = Offset("aa_body_yaw_offset_static", -180, 180, 0)
    C.FreestandingBody = Angles:Toggle({ Name = "Freestanding body yaw", Flag = "aa_freestanding_body_yaw", Hidden = true })
    Angles:Toggle({ Name = "Edge yaw", Flag = "aa_edge_yaw" })
    Key(Angles:Toggle({ Name = "Freestanding", Flag = "aa_freestanding" }), "aa_freestanding_hotkey", ALWAYS)
    Angles:Slider({ Name = "Roll", Flag = "aa_roll", Min = -45, Max = 45, Default = 0, Ending = DEGREE })
    C.Ready = true
    Rule()

    Key(FakeLag:Toggle({ Name = "Enabled", Flag = "fake_lag_enabled" }), "fake_lag_hotkey", ALWAYS)
    FakeLag:Dropdown({ Name = "Amount", Flag = "fake_lag_amount", Content = { "Dynamic", "Maximum", "Fluctuate" }, Default = "Dynamic" })
    FakeLag:Slider({ Name = "Variance", Flag = "fake_lag_variance", Min = 0, Max = 100, Default = 0, Ending = "%" })
    FakeLag:Slider({ Name = "Limit", Flag = "fake_lag_limit", Min = 1, Max = 15, Default = 13 })

    Key(Other:Toggle({ Name = "Slow motion", Flag = "aa_slow_motion" }), "aa_slow_motion_key", HOLD, 0x14)
    Other:Dropdown({ Name = "Leg movement", Flag = "aa_leg_movement", Content = { "Off", "Always slide", "Never slide" }, Default = "Off" })
    Key(Other:Toggle({ Name = "On shot anti-aim", Flag = "aa_on_shot_anti_aim", Risky = true }), "aa_on_shot_key", ALWAYS)
    Key(Other:Toggle({ Name = "Fake peek", Flag = "aa_fake_peek", Risky = true }), "aa_fake_peek_key", HOLD, 0x58)
end

do
    local Strip = Legit:ImageStrip({
        Name = "Weapon type",
        Flag = "legit_weapon",
        Default = "Pistol",
        CellWidth = 86,
        Options = { "Pistol", "SMG", "Rifle", "Shotgun", "Machine gun", "Sniper" },
    })
    Strip.sets["Shotgun"] = { legit_head = false }
    Strip.sets["Sniper"] = { legit_head = false, legit_recoil_pitch = 0, legit_recoil_yaw = 0 }

    local Aim = Box(Legit, "Aimbot", 0, 12, 0, 24)
    local Trigger = Box(Legit, "Triggerbot", 12, 12, 0, 16)
    local Other = Box(Legit, "Other", 12, 12, 16, 8)
    Aim:BindGroups(Strip)
    Trigger:BindGroups(Strip)
    Other:BindGroups(Strip)

    local C = {}
    local function Rule()
        if not C.Ready then return end
        local Instant = C.Reaction:Get() == 0
        if not Instant and C.Penetration:Get() then C.Penetration:Set(false) end
        C.Penetration:SetEnabled(Instant)
        C.Range:SetVisible(C.Accuracy:Get() ~= "Off")
    end

    Key(Aim:Toggle({ Name = "Enabled", Flag = "legit_enabled" }), "legit_aim_key", HOLD, 0x06)
    Aim:Slider({ Name = "Speed", Flag = "legit_speed", Min = 0, Max = 7, Decimal = 0.01, Default = 0.65 })
    Aim:Slider({ Name = "Speed (in attack)", Flag = "legit_attack_speed", Min = 0, Max = 7, Decimal = 0.01, Default = 0.65 })
    Aim:Slider({ Name = "Speed scale - FOV", Flag = "legit_speed_scale_fov", Min = 1, Max = 100, Default = 100, Ending = "%" })
    Aim:Slider({
        Name = "Maximum lock-on time", Flag = "legit_maximum_lock_time", Min = 1, Max = 1001, Default = 1001,
        Ending = "ms", ValueLabels = { [1001] = INFINITY },
    })
    Aim:Slider({ Name = "Reaction time", Flag = "legit_reaction_time", Min = 0, Max = 200, Default = 100, Ending = "ms" })
    Aim:Slider({ Name = "Maximum FOV", Flag = "legit_maximum_fov", Min = 0.1, Max = 90, Decimal = 0.1, Default = 10, Ending = DEGREE })
    Aim:Label({ Message = "Recoil compensation (P/Y)" })
    Aim:Slider({ Name = "", Flag = "legit_recoil_pitch", Min = 0, Max = 125, Default = 100, Ending = "%" })
    Aim:Slider({ Name = "", Flag = "legit_recoil_yaw", Min = 0, Max = 100, Default = 75, Ending = "%" })
    Aim:Toggle({ Name = "Quick stop", Flag = "legit_quick_stop" })
    Aim:Toggle({ Name = "Aim through smoke", Flag = "legit_through_smoke" })
    Aim:Toggle({ Name = "Aim while blind", Flag = "legit_while_blind" })
    Aim:Toggle({ Name = "Head", Flag = "legit_head", Default = true })
    Aim:Toggle({ Name = "Chest", Flag = "legit_chest", Default = true })
    Aim:Toggle({ Name = "Stomach", Flag = "legit_stomach", Default = true })
    Aim:Slider({
        Name = "First shot delay range", Flag = "legit_first_shot_delay", Min = 0, Max = 64, Default = 0,
        Ending = "in", ValueLabels = { [0] = "Off" }, Hidden = true,
    })

    Key(Trigger:Toggle({ Name = "Enabled", Flag = "legit_trigger_enabled" }), "legit_trigger_key", HOLD, 0x06)
    Trigger:Slider({ Name = "Minimum hit chance", Flag = "legit_minimum_hit_chance", Min = 0, Max = 100, Default = 75, Ending = "%" })
    C.Reaction = Trigger:Slider({ Name = "Reaction time", Flag = "legit_trigger_reaction", Min = 0, Max = 200, Default = 0, Ending = "ms", Callback = Rule })
    local Burst = Trigger:Toggle({ Name = "Burst fire", Flag = "legit_burst_fire" })
    Burst:Tie(Trigger:Slider({ Name = "", Flag = "legit_burst_time", Min = 1, Max = 500, Default = 250, Ending = "ms" }))
    Trigger:Slider({ Name = "Minimum damage", Flag = "legit_minimum_damage", Min = 1, Max = 100, Default = 1 })
    C.Penetration = Trigger:Toggle({ Name = "Automatic penetration", Flag = "legit_penetration" })
    Trigger:Toggle({ Name = "Shoot through smoke", Flag = "legit_shoot_smoke" })
    Trigger:Toggle({ Name = "Shoot while blind", Flag = "legit_shoot_blind" })
    Trigger:Toggle({ Name = "Head", Flag = "legit_trigger_head", Default = true })
    Trigger:Toggle({ Name = "Chest", Flag = "legit_trigger_chest", Default = true })
    Trigger:Toggle({ Name = "Stomach", Flag = "legit_trigger_stomach", Default = true })

    C.Accuracy = Other:Dropdown({ Name = "Accuracy boost", Flag = "legit_accuracy_boost", Content = { "Off", "Low", "High" }, Default = "Off", Callback = Rule })
    C.Range = Other:Slider({
        Name = "Accuracy boost range", Flag = "legit_accuracy_range", Min = 1, Max = 64, Default = 32,
        Ending = "in", ValueLabels = { [64] = INFINITY }, Hidden = true,
    })
    Other:Toggle({ Name = "Standalone recoil compensation", Flag = "legit_standalone_recoil" })
    C.Ready = true
    Rule()
end

do
    local Esp = Box(Visuals, "Player ESP", 0, 12, 0, 13)
    local Models = Box(Visuals, "Colored models", 0, 12, 13, 11)
    local Other = Box(Visuals, "Other ESP", 12, 12, 0, 12)
    local Effects = Box(Visuals, "Effects", 12, 12, 12, 12)

    local function Check(Section, Name, Flag, ColorFlag, Value)
        local Toggle = Section:Toggle({ Name = Name, Flag = Flag })
        if ColorFlag then Pick(Toggle, ColorFlag, Value) end
        return Toggle
    end

    Key(Esp:Label({ Message = "Activation type" }), "esp_activation", ALWAYS, "LeftShift")
    Check(Esp, "Teammates", "esp_teammates")
    Check(Esp, "Dormant", "esp_dormant")
    Check(Esp, "Bounding box", "esp_bounding_box", "esp_box_color", 0x82FFFFFF)
    Check(Esp, "Health bar", "esp_health_bar", "esp_health_color", 0xFF50E178)
    Check(Esp, "Name", "esp_name", "esp_name_color", 0xC8FFFFFF)
    Check(Esp, "Flags", "esp_flags")
    Check(Esp, "Weapon text", "esp_weapon_text")
    Check(Esp, "Weapon icon", "esp_weapon_icon", "esp_weapon_icon_color", 0xC8FFFFFF)
    Check(Esp, "Ammo", "esp_ammo", "esp_ammo_color", 0xE6C88C50)
    Check(Esp, "Distance", "esp_distance")
    Check(Esp, "Glow", "esp_glow", "esp_glow_color", 0x99783CB4)
    Check(Esp, "Hit marker", "esp_hit_marker")
    Check(Esp, "Hit marker sound", "esp_hit_marker_sound")
    Check(Esp, "Visualize aimbot", "esp_visualize_aimbot", "esp_visualize_aimbot_color", 0xCEE55200)
    Check(Esp, "Visualize aimbot (safe point)", "esp_visualize_safe_point", "esp_visualize_safe_point_color", 0x920000FF)
    Check(Esp, "Visualize sounds", "esp_visualize_sounds", "esp_sound_color", 0xFF3F3FFA)
    Check(Esp, "Line of sight", "esp_line_of_sight", "esp_sight_color", 0xFF0000FF)
    Check(Esp, "Money", "esp_money")
    Check(Esp, "Skeleton", "esp_skeleton", "esp_skeleton_color", 0xFFAAFFFF)
    Check(Esp, "Out of FOV arrow", "esp_out_of_fov", "esp_arrow_color", 0xFFFFFFFF):Tie(
        Esp:Slider({ Name = "", Flag = "esp_arrow_size", Min = 1, Max = 30, Default = 12, Ending = "px" }),
        Esp:Slider({ Name = "", Flag = "esp_arrow_distance", Min = 1, Max = 100, Default = 100, Ending = "%" })
    )

    local MATERIALS = { "Default", "Solid", "Shaded", "Metallic", "Glow", "Bubble", "Original" }
    local TINTED = { Shaded = true, Metallic = true, Glow = true, Bubble = true }
    local function Group(Spec)
        local G = {}
        local function Rule()
            if not G.Ready then return end
            local Active = G.Primary:Get() or (G.Behind ~= nil and G.Behind:Get())
            G.Material:SetVisible(Active)
            G.Secondary:SetVisible(Active and TINTED[G.Material:Get()] == true)
            if G.Duration then G.Duration:SetVisible(Active) end
        end
        local Flag = Spec.Flag
        G.Primary = Models:Toggle({ Name = Spec.Name, Flag = Flag, Callback = Rule })
        Pick(G.Primary, Flag .. "_color", Spec.Color)
        if Spec.Behind then
            G.Behind = Models:Toggle({ Name = Spec.Name .. " behind wall", Flag = Flag .. "_behind_wall", Callback = Rule })
            Pick(G.Behind, Flag .. "_behind_wall_color", Spec.Behind)
        end
        G.Material = Models:Dropdown({ Name = "", Flag = Flag .. "_material", Content = MATERIALS, Default = Spec.Material, Hidden = true, Callback = Rule })
        G.Secondary = Pick(G.Material, Flag .. "_secondary_color", Spec.Secondary)
        if Spec.Duration then
            G.Duration = Models:Slider({ Name = "", Flag = Flag .. "_duration", Min = 0.2, Max = 10, Decimal = 0.1, Default = 2, Ending = "s", Hidden = true })
        end
        G.Ready = true
        Rule()
    end

    Group({ Name = "Player", Flag = "models_player", Color = 0xFF3CC896, Behind = 0xB2B4783C, Material = "Default", Secondary = 0xFF00B2FF })
    Group({ Name = "Teammate", Flag = "models_teammate", Color = 0xFF323232, Behind = 0xB2FFFFFF, Material = "Glow", Secondary = 0xFF3B2D09 })
    Group({ Name = "Local player", Flag = "models_local_player", Color = 0xFF323232, Material = "Glow", Secondary = 0xFF3B2D09 })
    Models:MultiBox({ Name = "Local player transparency", Flag = "models_local_transparency", Content = { "Grenade", "Scoped" } })
    Group({ Name = "Local player fake", Flag = "models_local_fake", Color = 0x78000000, Material = "Solid", Secondary = 0xFF00B2FF })
    Group({ Name = "On shot", Flag = "models_on_shot", Color = 0xFF323232, Material = "Bubble", Secondary = 0xFFFFFFFF, Duration = true })
    Check(Models, "Ragdolls", "models_ragdolls")
    Group({ Name = "Hands", Flag = "models_hands", Color = 0xFFFFFFFF, Material = "Bubble", Secondary = 0xFFA49E54 })
    Group({ Name = "Weapon viewmodel", Flag = "models_weapon_viewmodel", Color = 0xFF6E1032, Material = "Metallic", Secondary = 0xFFA49E54 })
    Group({ Name = "Weapons", Flag = "models_weapons", Color = 0xFF6E1032, Material = "Metallic", Secondary = 0xFFA49E54 })
    Check(Models, "Disable model occlusion", "models_disable_model_occlusion")
    Check(Models, "Shadow", "models_shadow", "models_shadow_color", 0x78000000)
    Check(Models, "Props", "models_props", "models_props_color", 0xFFFFFFFF)

    Check(Other, "Radar", "esp_radar")
    Pick(Other:MultiBox({
        Name = "Dropped weapons", Flag = "esp_dropped_weapons", Content = { "Icon", "Text", "Glow", "Ammo", "Distance" },
    }), "esp_dropped_weapon_color", 0xC8FFFFFF)
    Check(Other, "Grenades", "esp_grenades", "esp_grenade_color", 0x00000000)
    Check(Other, "Inaccuracy overlay", "esp_inaccuracy", "esp_inaccuracy_color", 0x3C1E1E1E)
    Check(Other, "Recoil overlay", "esp_recoil")
    Check(Other, "Crosshair", "esp_crosshair")
    Check(Other, "Bomb", "esp_bomb", "esp_bomb_color", 0xFF3CC896)
    local Trajectory = Check(Other, "Grenade trajectory", "esp_grenade_trajectory", "esp_trajectory_color", 0xB33232FF)
    local Hit = Other:Label({ Message = "Grenade trajectory (hit)" })
    Pick(Hit, "esp_trajectory_secondary_color", 0xFF3BC896)
    Trajectory:Tie(Hit)
    Check(Other, "Grenade proximity warning", "esp_proximity_warning")
    Check(Other, "Spectators", "esp_spectators")
    Check(Other, "Penetration reticle", "esp_penetration_reticle")
    Check(Other, "Hostages", "esp_hostages", "esp_hostage_color", 0xC8FC9F38)
    Other:MultiBox({
        Name = "Feature indicators", Flag = "esp_feature_indicators",
        Content = {
            "Force safe point", "Force body aim", "Ping spike", "Double tap", "Duck peek assist",
            "Freestanding", "On shot anti-aim", "Minimum damage override",
        },
    })
    Shared.Esp = Check(Other, "Shared ESP", "esp_shared_enabled")
    Key(Shared.Esp, "esp_shared_activation", ALWAYS)
    Shared.Esp:Tie(
        Check(Other, "Shared ESP with other team", "esp_shared_other_team"),
        Check(Other, "Restrict shared ESP updates", "esp_shared_restrict_updates")
    )
    Check(Other, "Upgrade tablet", "esp_upgrade_tablet")
    local DangerZone = Check(Other, "Danger Zone items", "esp_danger_zone_items")
    local ITEMS = {
        { "Drone gun", "drone_gun", 0xFF3CC896 }, { "Blackhawk", "blackhawk", 0xFF00E0FF },
        { "Drone", "drone", 0xFF3CC896 }, { "Random case", "random_case", 0xFFF0138F },
        { "Tool case", "tool_case", 0xFFFFDC00 }, { "Pistol case", "pistol_case", 0xFF505050 },
        { "Explosive case", "explosive_case", 0xFF0082FF }, { "Heavy weapon case", "heavy_weapon_case", 0xFF0000FF },
        { "Light weapon case", "light_weapon_case", 0xFF3CC896 }, { "Dufflebag", "dufflebag", 0xFF3B7FC8 },
        { "Jammer", "jammer", 0xFF00006E }, { "Ammobox", "ammobox", 0xFF3B7FC8 },
        { "Armor", "armor", 0xFFC8843B }, { "Parachute pack", "parachute_pack", 0xFFFFDC00 },
        { "Briefcase", "briefcase", 0xFF3B7FC8 }, { "Tablet upgrade zone", "tablet_upgrade_zone", 0xFFFFF0AA },
        { "Tablet upgrade drone", "tablet_upgrade_drone", 0xFFFFF0AA }, { "Cash stack", "cash_stack", 0xFF00FF00 },
    }
    for _, Item in ipairs(ITEMS) do
        DangerZone:Tie(Check(Other, Item[1], "esp_" .. Item[2], "esp_" .. Item[2] .. "_color", Item[3]))
    end

    Check(Effects, "Remove flashbang effects", "effects_remove_flash")
    Check(Effects, "Remove smoke grenades", "effects_remove_smoke")
    Check(Effects, "Remove fog", "effects_remove_fog")
    Check(Effects, "Remove skybox", "effects_remove_sky")
    Effects:Dropdown({ Name = "Visual recoil adjustment", Flag = "effects_visual_recoil", Content = { "Off", "Remove shake", "Remove all" }, Default = "Off" })
    Effects:Slider({ Name = "Transparent walls", Flag = "effects_wall_transparency", Min = 1, Max = 100, Default = 100, Ending = "%" })
    Effects:Slider({ Name = "Transparent props", Flag = "effects_prop_transparency", Min = 1, Max = 100, Default = 100, Ending = "%" })
    local Night
    local Brightness = Effects:Dropdown({
        Name = "Brightness adjustment", Flag = "effects_brightness", Content = { "Off", "Fullbright", "Night mode" }, Default = "Off",
        Callback = function(Value)
            if Night then Night:SetVisible(Value == "Night mode") end
        end,
    })
    Night = Pick(Brightness, "effects_night_color", 0xFF2E292B)
    Night:SetVisible(false)
    Check(Effects, "Remove scope overlay", "effects_remove_scope")
    Check(Effects, "Instant scope", "effects_instant_scope")
    Check(Effects, "Disable post processing", "effects_disable_post_processing")
    Key(Check(Effects, "Force third person (alive)", "effects_third_person_alive"), "effects_third_person_key", ALWAYS)
    Check(Effects, "Force third person (dead)", "effects_third_person_dead")
    Check(Effects, "Disable rendering of teammates", "effects_disable_teammates")
    Check(Effects, "Disable rendering of ragdolls", "effects_disable_ragdolls")
    Check(Effects, "Bullet tracers", "effects_bullet_tracers", "effects_tracer_color", 0xFFFF8296)
    Check(Effects, "Bullet impacts", "effects_bullet_impacts"):Tie(
        Effects:Slider({ Name = "", Flag = "effects_impact_duration", Min = 1, Max = 20, Default = 4, Ending = "s" })
    )
    Check(Effects, "Modulate harmless molotovs", "effects_harmless_molotovs", "effects_harmless_molotov_color", 0xFFFF5800):Tie(
        Effects:Slider({ Name = "", Flag = "effects_molotov_percent", Min = 0, Max = 100, Default = 65, Ending = "%" })
    )
end

do
    local Main = Box(Misc, "Miscellaneous", 0, 12, 0, 24)
    local Movement = Box(Misc, "Movement", 12, 12, 0, 12)
    local Settings = Box(Misc, "Settings", 12, 12, 12, 12)

    Main:Slider({ Name = "Override FOV", Flag = "misc_fov", Min = 1, Max = 135, Default = 90, Ending = DEGREE })
    Main:Slider({ Name = "Override zoom FOV", Flag = "misc_zoom_fov", Min = 0, Max = 100, Default = 100, Ending = "%" })
    Main:Toggle({ Name = "Knifebot", Flag = "misc_knifebot" }):Tie(
        Main:MultiBox({ Name = "", Flag = "misc_knifebot_mode", Content = { "Swing", "Full stab" }, Default = { "Swing", "Full stab" } })
    )
    Main:Toggle({ Name = "Zeusbot", Flag = "misc_zeusbot" })
    Main:Toggle({ Name = "Automatic weapons", Flag = "misc_automatic_weapons" }):Tie(
        Main:Slider({ Name = "", Flag = "misc_automatic_weapons_delay", Min = 0, Max = 200, Default = 0, Ending = "ms" })
    )
    Main:Toggle({ Name = "Quick switch", Flag = "misc_quick_switch" })
    Main:Toggle({ Name = "Reveal competitive ranks", Flag = "misc_reveal_ranks" })
    Main:Toggle({ Name = "Reveal Overwatch players", Flag = "misc_reveal_overwatch" })
    Main:Toggle({ Name = "Auto-accept matchmaking", Flag = "misc_auto_accept", Default = true })
    Main:Toggle({ Name = "Clan tag spammer", Flag = "misc_clan_tag" })
    Main:Toggle({ Name = "Log weapon purchases", Flag = "misc_log_purchases" })
    local Damage = { Last = false }
    Damage.Toggle = Main:Toggle({ Name = "Log damage dealt", Flag = "misc_log_damage", Callback = function()
        local State = Damage.Toggle ~= nil and Damage.Toggle:Get()
        if State and not Damage.Last then
            local c = Library.Theme.Default.Accent
            local R, G, B = math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)
            Library:Notify({
                Message = ("hit <font color='rgb(%d, %d, %d)'>matcha</font> in the <font color='rgb(%d, %d, %d)'>head</font> for <font color='rgb(%d, %d, %d)'>100</font> damage (0 health remaining)"):format(R, G, B, R, G, B, R, G, B),
                Position = "Middle",
                Delay = 3,
            })
        end
        Damage.Last = State
    end })
    local Release = Main:Toggle({ Name = "Automatic grenade release", Flag = "misc_automatic_release" })
    Key(Release, "misc_release_key", ALWAYS)
    Release:Tie(Main:Slider({ Name = "Minimum grenade damage", Flag = "misc_minimum_grenade_damage", Min = 1, Max = 50, Default = 50 }))
    Main:Toggle({ Name = "Super toss", Flag = "misc_super_toss" })
    local Ping = Main:Toggle({ Name = "Ping spike", Flag = "misc_ping_spike" })
    Key(Ping, "misc_ping_spike_key", HOLD)
    Ping:Tie(Main:Slider({ Name = "", Flag = "misc_ping_spike_milliseconds", Min = 1, Max = 200, Default = 100, Ending = "ms" }))
    Key(Main:Label({ Message = "Free look" }), "misc_free_look_key", HOLD)
    Main:Toggle({ Name = "Persistent kill feed", Flag = "misc_persistent_kill_feed" })
    Key(Main:Label({ Message = "Last second defuse" }), "misc_last_second_defuse", HOLD, 0x52)
    Main:Toggle({ Name = "Disable sv_pure", Flag = "misc_disable_pure" })
    Main:Toggle({ Name = "Rebuy fix", Flag = "misc_rebuy_fix" })
    Main:Toggle({ Name = "Draw console output", Flag = "misc_console_output" })
    Main:Button({ Name = "Steal player name" })
    Main:Button({ Name = "Dump MM wins" })

    local C = {}
    local function Rule()
        if not C.Ready then return end
        local Strafe = C.Strafe:Get()
        C.Direction:SetVisible(Strafe)
        C.Smoothing:SetVisible(Strafe)
        C.Avoid:SetVisible(Strafe)
        C.Hop:SetVisible(Strafe)
        C.Speed:SetVisible(Strafe)
        local Hop = Strafe and C.Hop:Get()
        C.HopFirst:SetVisible(Hop)
        C.HopSecond:SetVisible(Hop)
    end
    Movement:Toggle({ Name = "Standalone quick stop", Flag = "movement_standalone_quick_stop" })
    Movement:Toggle({ Name = "Infinite duck", Flag = "movement_infinite_duck", Risky = true })
    Movement:Toggle({ Name = "Easy strafe", Flag = "movement_easy_strafe" })
    Movement:Toggle({ Name = "Bunny hop", Flag = "movement_bunny_hop" })
    C.Strafe = Movement:Toggle({ Name = "Air strafe", Flag = "movement_air_strafe", Callback = Rule })
    C.Direction = Movement:MultiBox({
        Name = "Air strafe direction", Flag = "movement_air_strafe_direction",
        Content = { "View angles", "Movement keys" }, Default = { "View angles" }, Hidden = true,
    })
    C.Smoothing = Movement:Slider({ Name = "Air strafe smoothing", Flag = "movement_air_strafe_smoothing", Min = 0, Max = 100, Default = 70, Ending = "%", Hidden = true })
    C.Avoid = Movement:Toggle({ Name = "Avoid collisions", Flag = "movement_avoid_collisions", Hidden = true })
    C.Hop = Movement:Toggle({ Name = "Z-Hop", Flag = "movement_z_hop", Hidden = true, Callback = Rule })
    Key(C.Hop, "movement_z_hop_key", HOLD, 0x54)
    C.HopFirst = Movement:Slider({ Name = "", Flag = "movement_z_hop_first", Min = 10, Max = 30, Decimal = 0.1, Default = 17.5, Hidden = true })
    C.HopSecond = Movement:Slider({ Name = "", Flag = "movement_z_hop_second", Min = 10, Max = 50, Decimal = 0.1, Default = 20, Hidden = true })
    C.Speed = Movement:Toggle({ Name = "Pre-speed", Flag = "movement_pre_speed", Hidden = true })
    Key(C.Speed, "movement_pre_speed_key", HOLD, 0x46)
    Pick(Movement:Toggle({ Name = "No fall damage", Flag = "movement_no_fall_damage" }), "movement_no_fall_damage_color", 0x00FF8E00)
    Movement:Dropdown({ Name = "Air duck", Flag = "movement_air_duck", Content = { "Off", "On", "Spam", "Fake", "On land" }, Default = "Off" })
    Key(Movement:Toggle({ Name = "Blockbot", Flag = "movement_blockbot" }), "movement_blockbot_hotkey", HOLD)
    Key(Movement:Toggle({ Name = "Jump at edge", Flag = "movement_jump_at_edge" }), "movement_edge_jump", HOLD, 0x06)
    Movement:Toggle({ Name = "Fast walk", Flag = "movement_fast_walk" })
    C.Ready = true
    Rule()

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
    Local(Settings:Dropdown({
        Name = "DPI scale", Flag = "settings_dpi_scale", Content = { "100%", "125%", "150%", "175%", "200%" }, Default = "100%",
        Callback = function(Value)
            local Scale = (tonumber(string.match(tostring(Value), "%d+")) or 100) / 100
            if Library:GetScale() ~= Scale then Library:SetScale(Scale) end
        end,
    }))
    Settings:Toggle({ Name = "Anti-untrusted", Flag = "settings_anti_untrusted", Default = true })
    Settings:Toggle({ Name = "Allow custom game events", Flag = "settings_allow_custom_events", Default = true, Risky = true, Hidden = true })
    Settings:Toggle({ Name = "Hide from OBS", Flag = "settings_hide_from_obs" })
    Settings:Toggle({ Name = "Low FPS warning", Flag = "settings_low_fps_warning" })
    local Lock = { Ready = false }
    Lock.Toggle = Local(Settings:Toggle({ Name = "Lock menu layout", Flag = "settings_lock_layout", Default = true, Callback = function()
        if Lock.Ready then Library:SetLayoutLocked(Lock.Toggle:Get()) end
    end }))
    Lock.Ready = true
    Library:SetLayoutLocked(true)
    Local(Settings:Toggle({ Name = "Multithreading", Flag = "settings_multithreading", Default = true, Hidden = true }))
    Settings:Button({ Name = "Reset menu layout", Callback = function() Library:ResetLayout() end })
    Settings:Button({ Name = "Unload", Callback = Library.Unload })
    Local(Settings:Slider({ Name = "sv_maxunlag2", Flag = "settings_maximum_unlag", Min = 200, Max = 1000, Default = 200, Ending = "ms", Hidden = true }))
    Local(Settings:Slider({ Name = "sv_maxusrcmdprocessticks2", Flag = "settings_maximum_usercmd_ticks", Min = 4, Max = 62, Default = 16, Hidden = true }))
    Local(Settings:Slider({ Name = "sv_clockcorrection_msecs2", Flag = "settings_clock_correction", Min = 0, Max = 1000, Default = 30, Ending = "ms", Hidden = true }))
    Local(Settings:Toggle({ Name = "sv_maxusrcmdprocessticks_holdaim", Flag = "settings_hold_aim", Default = true, Hidden = true }))
    Local(Settings:Toggle({ Name = "Fix viewmodel lag", Flag = "settings_fix_viewmodel_lag", Default = true, Hidden = true }))
    Local(Settings:Toggle({ Name = "Fix networking", Flag = "settings_fix_networking", Default = true, Hidden = true }))
    Local(Settings:Toggle({ Name = "Fix animations", Flag = "settings_fix_animations", Default = true, Hidden = true }))
    Local(Settings:Toggle({ Name = "Faster grenade toss", Flag = "settings_faster_grenade_toss", Default = true, Hidden = true }))
end

do
    local Models = Box(Skins, "Model options", 0, 12, 0, 24, true)
    local Weapon = Box(Skins, "Weapon skin", 12, 12, 0, 24, true)

    local KNIVES = {
        "Bayonet", "Flip", "Gut", "Karambit", "M9 Bayonet", "Tactical", "Butterfly", "Falchion", "Shadow dagger",
        "Survival bowie", "Ursus", "Navaja", "Stiletto", "Talon", "Classic knife", "Paracord", "Survival", "Nomad", "Skeleton",
    }
    local MASKS = {
        "Hoxton", "Doll", "Samurai", "Clown", "Wolf", "Sheep", "Gold bunny", "Anaglyph", "Japanese", "Dallas", "Pumpkin",
        "Bloody sheep", "Devil", "Boar", "Chains", "Tiki", "Bunny", "Gold sheep", "Zombie", "Chicken", "Gold skull",
    }
    local GLOVES = {
        { "Bloodhound", { "Bronzed", "Charred", "Guerrilla", "Snakebite" } },
        { "Sport", { "Arid", "Hedge maze", "Pandora's box", "Superconductor" } },
        { "Driver", { "Convoy", "Crimson weave", "Diamondback", "Lunar weave" } },
        { "Hand wraps", { "Badlands", "Leather", "Slaughter", "Spruce DDPAT" } },
        { "Moto", { "Boom!", "Cool mint", "Eclipse", "Spearmint" } },
        { "Specialist", { "Crimson kimono", "Emerald web", "Forest DDPAT", "Foundation" } },
        { "Hydra", { "Case hardened", "Emerald", "Mangrove", "Rattler" } },
    }
    local AGENTS_T = { "Dragomir", "Maximus", "Osiris", "Rezan The Ready", "Slingshot", "The Elite Mr. Muhlik" }
    local AGENTS_CT = { "B Squadron Officer", "Buckshot", "Lt. Commander Ricksaw", "Michael Syfers", "Seal Team 6 Soldier", "Special Agent Ava" }
    local PAINTS = {
        "Asiimov", "Atomic Alloy", "Blaze", "Blue Steel", "Bright Water", "Case Hardened", "Crimson Web", "Damascus Steel",
        "Doppler", "Fade", "Forest DDPAT", "Fuel Injector", "Gamma Doppler", "Hyper Beast", "Marble Fade", "Night",
        "Printstream", "Redline", "Safari Mesh", "Slaughter", "Tiger Tooth", "Ultraviolet", "Urban Masked", "Vulcan",
        "Wasteland Rebel", "Water Elemental",
    }
    local FILTERED = { "Asiimov", "Blue Steel", "Case Hardened", "Fuel Injector", "Redline", "Safari Mesh", "Vulcan", "Wasteland Rebel" }

    Models:Slider({ Name = "Team", Flag = "skins_team", Min = 2, Max = 3, Default = 3, Hidden = true })
    Models:Toggle({ Name = "Knife changer", Flag = "skins_knife" }):Tie(
        Models:Dropdown({ Name = "", Flag = "skins_knife_model", Content = KNIVES, Default = "Bayonet" })
    )
    local Models_, Paints = {}, {}
    for Index, Entry in ipairs(GLOVES) do
        Models_[Index] = Entry[1]
        Paints[Entry[1]] = Entry[2]
    end
    local Paint
    local Glove = Models:Toggle({ Name = "Glove changer", Flag = "skins_glove" })
    local Model = Models:Dropdown({
        Name = "", Flag = "skins_glove_model", Content = Models_, Default = Models_[1],
        Callback = function(Value)
            if Paint and Paints[Value] then Paint:Refresh(Paints[Value]) end
        end,
    })
    Paint = Models:Dropdown({ Name = "", Flag = "skins_glove_paint", Content = Paints[Models_[1]], Default = Paints[Models_[1]][1] })
    Glove:Tie(Model, Paint)
    Models:Toggle({ Name = "Mask changer", Flag = "skins_mask" }):Tie(
        Models:Dropdown({ Name = "", Flag = "skins_mask_model", Content = MASKS, Default = "Hoxton" })
    )
    local Agent = Models:Toggle({ Name = "Agent changer", Flag = "skins_agent" })
    Models:Dropdown({ Name = "", Flag = "skins_agent_model_t", Content = AGENTS_T, Default = AGENTS_T[1], Hidden = true })
    Agent:Tie(Models:Dropdown({ Name = "", Flag = "skins_agent_model_ct", Content = AGENTS_CT, Default = AGENTS_CT[1] }))

    Weapon:Slider({ Name = "Weapon", Flag = "skins_weapon", Min = 0, Max = 1000, Default = 0, Hidden = true })
    Weapon:Toggle({ Name = "Enabled", Flag = "skins_enabled" })
    Weapon:Toggle({ Name = "StatTrak", Flag = "skins_stattrak" })
    Weapon:Slider({ Name = "Quality", Flag = "skins_quality", Min = 0, Max = 100, Default = 100, Ending = "%" })
    Weapon:Slider({ Name = "Seed", Flag = "skins_seed", Min = 0, Max = 1000, Default = 0 })
    local List
    local function Fill(Filter)
        if not List then return end
        local Current = List:Get()
        List:Clear()
        local Source = Filter and FILTERED or PAINTS
        for _, Name in ipairs(Source) do List:AddValue(Name) end
        List:Select(Has(Source, Current) and Current or Source[1])
    end
    local Filter = { Last = false }
    Filter.Toggle = Weapon:Toggle({ Name = "Filter by weapon", Flag = "skins_filter_by_weapon", Callback = function()
        local State = Filter.Toggle ~= nil and Filter.Toggle:Get()
        if State ~= Filter.Last then
            Filter.Last = State
            Fill(State)
        end
    end })
    List = Weapon:List({ Flag = "skins_paintkit", Size = 322, Search = true, Bound = true })
    Fill(false)
end

do
    local PlayerBox = Box(PlayersTab, "Players", 0, 12, 0, 24)
    local Adjust = Box(PlayersTab, "Adjustments", 12, 12, 0, 24)

    local Records, Controls = {}, {}
    local State = { Current = nil, Loading = false }
    local function Add(Field, Default, Control)
        Control.NoConfig = true
        Control.NoGroup = true
        Controls[#Controls + 1] = { Field = Field, Default = Default, Control = Control }
        return Control
    end
    local function Store()
        local Name = State.Current
        if not Name or State.Loading then return end
        local Record = {}
        for _, Entry in ipairs(Controls) do Record[Entry.Field] = Entry.Control:Get() end
        Records[Name] = Record
    end
    local function Load(Name)
        State.Loading = true
        local Record = Name and Records[Name] or {}
        for _, Entry in ipairs(Controls) do
            local Value = Record[Entry.Field]
            if Value == nil then Value = Entry.Default end
            Entry.Control:Set(Value)
        end
        State.Loading = false
    end

    local List = PlayerBox:List({
        Flag = "players_selected", Size = 425, Bound = true,
        Callback = function(Name)
            if Name == State.Current then return end
            Store()
            State.Current = Name
            Load(Name)
        end,
    })
    List.NoConfig = true
    local Reset = PlayerBox:Button({ Name = "Reset all", Callback = function()
        Records = {}
        Load(State.Current)
    end })

    Add("whitelist", false, Adjust:Toggle({ Name = "Add to whitelist", Flag = "players_whitelist", Callback = Store }))
    local SharedUpdates = Add("allow_shared_esp", false, Adjust:Toggle({ Name = "Allow shared ESP updates", Flag = "players_allow_shared_esp", Callback = Store }))
    Add("disable_visuals", false, Adjust:Toggle({ Name = "Disable visuals", Flag = "players_disable_visuals", Callback = Store }))
    Add("high_priority", false, Adjust:Toggle({ Name = "High priority", Flag = "players_high_priority", Callback = Store }))
    Add("force_pitch", false, Adjust:Toggle({ Name = "Force pitch", Flag = "players_force_pitch", Callback = Store })):Tie(
        Add("pitch", 0, Adjust:Slider({ Name = "Force pitch value", Flag = "players_pitch", Min = -90, Max = 90, Default = 0, MaxWidth = 176, Callback = Store }))
    )
    Add("force_body_yaw", false, Adjust:Toggle({ Name = "Force body yaw", Flag = "players_force_body_yaw", Callback = Store })):Tie(
        Add("body_yaw", 0, Adjust:Slider({ Name = "Force body yaw value", Flag = "players_body_yaw", Min = -60, Max = 60, Default = 0, MaxWidth = 176, Callback = Store }))
    )
    Add("correction_active", false, Adjust:Toggle({ Name = "Correction active", Flag = "players_correction_active", Callback = Store }))
    Add("prefer_body_aim", "-", Adjust:Dropdown({ Name = "Override prefer body aim", Flag = "players_prefer_body_aim", Content = { "-", "Off", "On", "Force" }, Default = "-", Callback = Store }))
    Add("safe_point", "-", Adjust:Dropdown({ Name = "Override safe point", Flag = "players_safe_point", Content = { "-", "Off", "On" }, Default = "-", Callback = Store }))
    local Apply = Adjust:Button({ Name = "Apply to all", Callback = function()
        local Name = State.Current
        if not Name then return end
        Store()
        local Source = Records[Name]
        for _, Other in ipairs(List:GetValues()) do
            local Copy = {}
            for Field, Value in pairs(Source) do Copy[Field] = Value end
            Records[Other] = Copy
        end
    end })

    local Known = {}
    function Shared.Players()
        local Seen = {}
        for _, Player in ipairs(Players:GetPlayers()) do
            local Name = Player.Name
            Seen[Name] = true
            if not Known[Name] then
                Known[Name] = true
                List:AddValue(Name)
            end
        end
        for Name in pairs(Known) do
            if not Seen[Name] then
                Known[Name] = nil
                Records[Name] = nil
                if State.Current == Name then State.Current = nil end
                List:RemoveValue(Name)
            end
        end
        if not List:Get() then
            local First = List:GetValues()[1]
            if First then List:Select(First) end
        end
    end
    function Shared.PlayerState()
        local Active = State.Current ~= nil
        List:SetEnabled(Active)
        Reset:SetEnabled(Active)
        Apply:SetEnabled(Active)
        for _, Entry in ipairs(Controls) do Entry.Control:SetEnabled(Active) end
        local Sharing = Active and Shared.Esp ~= nil and Shared.Esp:Get() == true
        if not Sharing and SharedUpdates:Get() then SharedUpdates:Set(false) end
        SharedUpdates:SetEnabled(Sharing)
    end
    Shared.PlayerState()
end

do
    local Presets = Box(Config, "Presets", 0, 12, 0, 24)
    local Scripts = Box(Config, "Lua", 12, 12, 0, 24)

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
    Presets:Button({ Name = "Import from clipboard", Callback = function()
        local Data = Library:GetClipboard()
        if type(Data) ~= "string" or not string.find(Data, "\"__groups\"", 1, true) then return end
        if Library:LoadConfig(Data) then Mark(nil) end
    end })
    Presets:Button({ Name = "Export to clipboard", Callback = function()
        Library:SetClipboard(Library:GetConfig(true))
    end })
    for _, Preset in ipairs(Library:ListConfigs()) do List:AddValue(Preset) end
    function Shared.Baseline()
        Baseline = Library:GetConfig(true)
    end

    local Loaded, Startup = {}, {}
    local C = {}
    local function Selection()
        if not C.Ready then return end
        local Script = C.Enabled:Get() and C.List:Get() or nil
        C.Load:SetVisible(Script ~= nil and not Loaded[Script])
        C.Unload:SetVisible(Script ~= nil and Loaded[Script] == true)
        C.Busy = true
        C.Startup:Set(Script ~= nil and Startup[Script] == true)
        C.Busy = false
    end
    local function Power()
        if not C.Ready then return end
        local State = C.Enabled:Get()
        for _, Control in ipairs(C.Rest) do Control:SetEnabled(State) end
        Selection()
    end
    C.Enabled = Scripts:Toggle({ Name = "Enabled", Flag = "scripts_enabled", Default = true, Callback = Power })
    C.Unsafe = Scripts:Toggle({ Name = "Allow unsafe scripts", Flag = "scripts_allow_unsafe" })
    C.Reload = Scripts:Button({ Name = "Reload active scripts" })
    C.List = Scripts:List({ Flag = "scripts_selected", Size = 325, Search = true, Bound = false, Callback = Selection })
    C.Updated = Scripts:Label({ Message = " " })
    C.Startup = Scripts:Toggle({ Name = "Load on startup", Flag = "scripts_load_on_startup", Callback = function()
        local Script = C.List and C.List:Get()
        if C.Ready and not C.Busy and Script then Startup[Script] = C.Startup:Get() end
    end })
    C.Load = Scripts:Button({ Name = "Load script", Hidden = true, Callback = function()
        local Script = C.List:Get()
        if not Script then return end
        Loaded[Script] = true
        C.List:SetMarked(Script, true)
        Selection()
    end })
    C.Unload = Scripts:Button({ Name = "Unload script", Hidden = true, Callback = function()
        local Script = C.List:Get()
        if not Script then return end
        Loaded[Script] = nil
        C.List:SetMarked(Script, false)
        Selection()
    end })
    C.Rest = { C.Unsafe, C.Reload, C.List, C.Updated, C.Startup, C.Load, C.Unload }
    for _, Control in ipairs({ C.Enabled, C.Unsafe, C.List, C.Startup }) do Control.NoConfig = true end
    C.Ready = true
    Power()

    function Shared.Scripts()
        if not C.Enabled:Get() then return end
        local Found, Order = {}, {}
        for _, Folder in ipairs({ "", ".", Library.Folder .. "/Scripts" }) do
            local Listed, Files = pcall(function() return listfiles(Folder) end)
            if Listed and type(Files) == "table" then
                for _, Path in ipairs(Files) do
                    local File = string.match((string.gsub(tostring(Path), "\\", "/")), "([^/]+)$")
                    local Script = File and (string.match(File, "^(.+)%.luau$") or string.match(File, "^(.+)%.lua$"))
                    if Script and not Found[Script] then
                        Found[Script] = true
                        Order[#Order + 1] = Script
                    end
                end
            end
        end
        table.sort(Order)
        for _, Script in ipairs(C.List:GetValues()) do
            if not Found[Script] then
                Loaded[Script], Startup[Script] = nil, nil
                C.List:RemoveValue(Script)
            end
        end
        for _, Script in ipairs(Order) do
            if not C.List:Find(Script) then C.List:AddValue(Script) end
        end
        Selection()
    end
end

do
    Box(Lua, "A", 0, 12, 0, 24)
    Box(Lua, "B", 12, 12, 0, 24)
end

Shared.Baseline()
Shared.Scripts()
Library:Init()

task.spawn(function()
    local Tick, Shown = 0, false
    while Library.Running do
        if Tick % 8 == 0 then pcall(Shared.Players) end
        pcall(Shared.PlayerState)
        local Open = Window.CurrentTab == Config
        if Open and not Shown then pcall(Shared.Scripts) end
        Shown = Open
        Tick = Tick + 1
        task.wait(0.25)
    end
end)
