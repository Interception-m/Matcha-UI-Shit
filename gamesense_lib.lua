if type(_G.Library) == "table" and _G.Library.__gamesense and _G.Library.Unload then
    pcall(function() _G.Library:Unload() end)
end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local sub, fmt, rep = string.sub, string.format, string.rep
local now = os.clock

local function clamp(v, a, b)
    if v < a then return a elseif v > b then return b end
    return v
end

local function round(v)
    return floor(v + 0.5)
end

local function rgb(r, g, b)
    return r * 65536 + g * 256 + b
end

local function unrgb(c)
    return floor(c / 65536), floor(c / 256) % 256, c % 256
end

local function gray(v)
    v = floor(v)
    return v * 65536 + v * 256 + v
end

local function mix(c1, c2, t)
    if t <= 0 then return c1 elseif t >= 1 then return c2 end
    local r1, g1, b1 = unrgb(c1)
    local r2, g2, b2 = unrgb(c2)
    return rgb(floor(r1 + (r2 - r1) * t + 0.5), floor(g1 + (g2 - g1) * t + 0.5), floor(b1 + (b2 - b1) * t + 0.5))
end

local C3 = { n = 0, map = {} }
local function c3(c)
    local v = C3.map[c]
    if not v then
        if C3.n > 6000 then C3.map = {} C3.n = 0 end
        v = Color3.fromRGB(unrgb(c))
        C3.map[c] = v
        C3.n = C3.n + 1
    end
    return v
end

local function pk(c)
    if type(c) == "number" then return c end
    local ok, v = pcall(function()
        return rgb(clamp(round(c.R * 255), 0, 255), clamp(round(c.G * 255), 0, 255), clamp(round(c.B * 255), 0, 255))
    end)
    if ok then return v end
    return rgb(255, 255, 255)
end

local function hsv2rgb(h, s, v)
    if s <= 0 then return v, v, v end
    h = (h % 1) * 6
    local i = floor(h)
    local f = h - i
    local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v end
    return v, p, q
end

local function rgb2hsv(r, g, b)
    local mx, mn = max(r, g, b), min(r, g, b)
    local d = mx - mn
    local h = 0
    if d > 0 then
        if mx == r then h = ((g - b) / d) % 6
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, (mx > 0) and (d / mx) or 0, mx
end

local CW, CH = 7, 13
local KEY_TEXT_SIZE = 13
local FONT = (Drawing.Fonts and Drawing.Fonts.UI) or 0

local C = {
    b12 = gray(12), b20 = gray(20), b23 = gray(23), b24 = gray(24), b25 = gray(25), b35 = gray(35),
    b40 = gray(40), b50 = gray(50), b60 = gray(60), b65 = gray(65), b100 = gray(100), black = 0,
    white = gray(255), t198 = gray(198), t205 = gray(205), t208 = gray(208), t152 = gray(152),
    t117 = gray(117), t176 = gray(176), red = rgb(255, 0, 0),
}

local Library = {
    __gamesense = true,
    Connections = {},
    Errors = {},
    Flags = {},
    Windows = {},
    Keybinds = {},
    UnnamedFlags = 0,
    Build = "Beta",
    UID = "1",
    Folder = "gamesense",
    ConfigFolder = "gamesense/Configs",
    ConfigExt = ".cfg",
    Running = false,
    InitTime = now(),
    UI = {
        Name = "gamesense",
        CloseBind = "Insert",
        WatermarkRefreshRate = 1,
        Initialized = false,
        Faded = false,
        LastCopiedColor = nil,
        TabIndex = 0,
        Viewing = false,
        Resizing = false,
        TweenSpeed = 0.15,
        FontSize = 13,
        Watermark = false,
        WatermarkText = nil,
        LockLayout = true,
        Scale = 1,
        NotifyErrors = false,
        Notifications = { TopLeft = {}, Middle = {} },
        Keys = {
            LeftShift = "SHF", RightShift = "SHF", LeftControl = "CTR", RightControl = "CTR",
            LeftAlt = "ALT", RightAlt = "ALT", CapsLock = "CAP", Space = "SPC",
            One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7",
            Eight = "8", Nine = "9", Zero = "0",
            KeypadOne = "KP1", KeypadTwo = "KP2", KeypadThree = "KP3", KeypadFour = "KP4",
            KeypadFive = "KP5", KeypadSix = "KP6", KeypadSeven = "KP7", KeypadEight = "KP8",
            KeypadNine = "KP9", KeypadZero = "KP0",
            KeypadMultiply = "KP*", KeypadPlus = "KP+", KeypadMinus = "KP-", KeypadPeriod = "KP.", KeypadDivide = "KP/",
            Insert = "INS", Delete = "DEL", Home = "HOM", End = "END", PageUp = "PGU", PageDown = "PGD",
            Minus = "-", Equals = "+", LeftBracket = "[{", RightBracket = "]}", Semicolon = ";:",
            Quote = "'\"", BackSlash = "\\|", Comma = ",", Period = ".", Slash = "/?", Backquote = "`~",
            Tab = "TAB", Return = "ENT", Backspace = "BCK", Up = "UP", Down = "DOW", Left = "LEF", Right = "RIG",
            MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", MouseButton4 = "M4", MouseButton5 = "M5",
            NumLock = "NUM", ScrollLock = "SCR", Pause = "PAU", LeftSuper = "WIN", RightSuper = "WIN", Print = "PS",
        },
    },
    Theme = {
        Default = {
            Accent = Color3.fromRGB(159, 202, 43),
            SecondAccent = Color3.fromRGB(119, 162, 3),
            TextColor = Color3.fromRGB(205, 205, 205),
            Risky = Color3.fromRGB(240, 240, 130),
        },
    },
}
Library.__index = Library
Library.Sections = {}
Library.Sections.__index = Library.Sections
local Sections = Library.Sections

local T = { acc = 0, acc2 = 0, accS = 0, text = 0, risky = 0 }
local UI = { dt = 0.01, last = now(), vw = 1920, vh = 1080, fps = 60, fpsN = 0, fpsAt = now(), uid = 0, sc = 1 }
UI.RowH = {
    First = 20, Gap = 5,
    Toggle = 13, Label = 12, Slider = 25, SliderBare = 10, Dropdown = 35, DropdownBare = 20,
    TextBox = 20, List = 0, Button = 28,
}

local function Z(v)
    local x = v * UI.sc
    local f = floor(x)
    local d = x - f
    if d > 0.5 or (d == 0.5 and f % 2 == 1) then return f + 1 end
    return f
end
local I = { mx = 0, my = 0, m1 = false, m1p = false, m1r = false, m2 = false, m2p = false, used = false, used2 = false }

local function nextId()
    UI.uid = UI.uid + 1
    return UI.uid
end

local D = { sq = {}, tx = {}, tr = {}, im = {}, imList = {}, nsq = 0, ntx = 0, ntr = 0, psq = 0, ptx = 0, ptr = 0, z = 1000, frame = 0, dead = false, alpha = 1 }

D.vgc, D.vgk, D.vgn, D.nvg = {}, {}, 0, 0

function D.begin()
    D.nsq, D.ntx, D.ntr = 0, 0, 0
    D.nvg = 0
    D.z = 1000
    D.frame = D.frame + 1
end

function D.rect(x, y, w, h, c, a)
    if D.dead then return end
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)
    if w <= 0 or h <= 0 then return end
    a = (a or 1) * D.alpha
    if a <= 0 then return end
    local n = D.nsq + 1
    D.nsq = n
    local o = D.sq[n]
    if not o then
        local d = Drawing.new("Square")
        d.Visible = false
        d.Filled = true
        d.Thickness = 1
        o = { d = d, v = false }
        D.sq[n] = o
    end
    local d = o.d
    if o.x ~= x or o.y ~= y then d.Position = Vector2.new(x, y) o.x, o.y = x, y end
    if o.w ~= w or o.h ~= h then d.Size = Vector2.new(w, h) o.w, o.h = w, h end
    if o.c ~= c then d.Color = c3(c) o.c = c end
    if o.a ~= a then d.Transparency = a o.a = a end
    local z = D.z + 1
    D.z = z
    if o.z ~= z then d.ZIndex = z o.z = z end
    if not o.v then d.Visible = true o.v = true end
end

function D.text(x, y, s, c, a, outline, size, font)
    if D.dead or s == nil or s == "" then return end
    size = size or CH
    font = font or D.font or FONT
    x, y = floor(x), floor(y)
    a = (a or 1) * D.alpha
    if a <= 0 then return end
    outline = outline and true or false
    local n = D.ntx + 1
    D.ntx = n
    local o = D.tx[n]
    if not o then
        local d = Drawing.new("Text")
        d.Visible = false
        d.Size = size
        d.Font = font
        d.Center = false
        d.Outline = false
        o = { d = d, v = false, ol = false, sz = size, f = font }
        D.tx[n] = o
    end
    local d = o.d
    if o.sz ~= size then d.Size = size o.sz = size end
    if o.f ~= font then d.Font = font o.f = font end
    if o.s ~= s then d.Text = s o.s = s end
    if o.x ~= x or o.y ~= y then d.Position = Vector2.new(x, y) o.x, o.y = x, y end
    if o.c ~= c then d.Color = c3(c) o.c = c end
    if o.a ~= a then d.Transparency = a o.a = a end
    if o.ol ~= outline then d.Outline = outline o.ol = outline end
    local z = D.z + 1
    D.z = z
    if o.z ~= z then d.ZIndex = z o.z = z end
    if not o.v then d.Visible = true o.v = true end
end

function D.tri(x1, y1, x2, y2, x3, y3, c, a)
    if D.dead then return end
    a = (a or 1) * D.alpha
    if a <= 0 then return end
    local n = D.ntr + 1
    D.ntr = n
    local o = D.tr[n]
    if not o then
        local d = Drawing.new("Triangle")
        d.Visible = false
        d.Filled = true
        d.Thickness = 1
        o = { d = d, v = false }
        D.tr[n] = o
    end
    local d = o.d
    if o.x1 ~= x1 or o.y1 ~= y1 or o.x2 ~= x2 or o.y2 ~= y2 or o.x3 ~= x3 or o.y3 ~= y3 then
        d.PointA = Vector2.new(x1, y1)
        d.PointB = Vector2.new(x2, y2)
        d.PointC = Vector2.new(x3, y3)
        o.x1, o.y1, o.x2, o.y2, o.x3, o.y3 = x1, y1, x2, y2, x3, y3
    end
    if o.c ~= c then d.Color = c3(c) o.c = c end
    if o.a ~= a then d.Transparency = a o.a = a end
    local z = D.z + 1
    D.z = z
    if o.z ~= z then d.ZIndex = z o.z = z end
    if not o.v then d.Visible = true o.v = true end
end

local Img = { cache = {}, queue = {}, busy = false, gen = {} }

function D.image(key, src, x, y, w, h, tint, a)
    if D.dead or not src then return false end
    local data = Img.get(src)
    if not data then return false end
    local o = D.im[key]
    if not o then
        local d = Drawing.new("Image")
        d.Visible = false
        o = { d = d, v = false }
        D.im[key] = o
        D.imList[#D.imList + 1] = o
    end
    local d = o.d
    if o.src ~= src then
        local ok = pcall(function() d.Data = data end)
        if not ok then return false end
        o.src = src
    end
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)
    a = (a or 1) * D.alpha
    if a <= 0 then return true end
    if o.x ~= x or o.y ~= y then d.Position = Vector2.new(x, y) o.x, o.y = x, y end
    if o.w ~= w or o.h ~= h then d.Size = Vector2.new(w, h) o.w, o.h = w, h end
    if tint and o.c ~= tint then pcall(function() d.Color = c3(tint) end) o.c = tint end
    if o.a ~= a then d.Transparency = a o.a = a end
    local z = D.z + 1
    D.z = z
    if o.z ~= z then d.ZIndex = z o.z = z end
    if not o.v then d.Visible = true o.v = true end
    o.used = D.frame
    return true
end

function D.label(x, y, s, c, a, bold, shadow, outline)
    if s == nil or s == "" then return 0 end
    a = a or 1
    local bf = bold and D.boldFont or nil
    if bf then
        if shadow then
            local sa = (a > 0.5) and 0.5 or a
            D.text(x + 1, y + 1, s, 0, sa, false, nil, bf)
        end
        D.text(x, y, s, c, a, outline, nil, bf)
        return #s * CW + 1
    end
    if shadow then
        local sa = (a > 0.5) and 0.5 or a
        D.text(x + 1, y + 1, s, 0, sa)
        if bold then D.text(x + 2, y + 1, s, 0, sa) end
    end
    if bold and outline then D.text(x + 1, y, s, c, a, true) end
    D.text(x, y, s, c, a, outline)
    if bold then D.text(x + 1, y, s, c, a) end
    return #s * CW + (bold and 1 or 0)
end

function D.outline(x, y, w, h, c, a)
    D.rect(x, y, w, 1, c, a)
    D.rect(x, y + h - 1, w, 1, c, a)
    D.rect(x, y + 1, 1, h - 2, c, a)
    D.rect(x + w - 1, y + 1, 1, h - 2, c, a)
end

function D.arrow(x, y, down, a, ta)
    local st = down and 1 or -1
    a = a or 1
    ta = (ta or 200 / 255) * a
    D.rect(x, y - st, 5, 1, 0, a)
    D.rect(x, y, 5, 1, 16777215, ta)
    D.rect(x + 1, y + st, 3, 1, 16777215, ta)
    D.rect(x + 2, y + st * 2, 1, 1, 16777215, ta)
end

function D.vgrad(key, x, y, w, h, c1, c2, a)
    local n = D.nvg + 1
    D.nvg = n
    if w <= 0 or h <= 0 then return end
    if c1 == c2 or h == 1 then
        D.rect(x, y, w, h, c1, a)
        return
    end
    local t = D.vgc[c1]
    if not t then
        t = {}
        D.vgc[c1] = t
    end
    local k = c2 * 1024 + h
    local src = t[k]
    if not src then
        D.vgn = D.vgn + 1
        if D.vgn > 2000 then
            D.vgc = {}
            D.vgn = 0
            t = {}
            D.vgc[c1] = t
        end
        src = "gen:vg:" .. c1 .. ":" .. c2 .. ":" .. h
        t[k] = src
    end
    local id = D.vgk[n]
    if not id then
        id = "vg" .. n
        D.vgk[n] = id
    end
    if D.image(id, src, x, y, w, h, nil, a) then return end
    for i = 0, h - 1 do
        D.rect(x, y + i, w, 1, mix(c1, c2, (i + 0.5) / h), a)
    end
end

function D.finish()
    for i = D.nsq + 1, D.psq do
        local o = D.sq[i]
        if o.v then o.d.Visible = false o.v = false end
    end
    D.psq = D.nsq
    for i = D.ntx + 1, D.ptx do
        local o = D.tx[i]
        if o.v then o.d.Visible = false o.v = false end
    end
    D.ptx = D.ntx
    for i = D.ntr + 1, D.ptr do
        local o = D.tr[i]
        if o.v then o.d.Visible = false o.v = false end
    end
    D.ptr = D.ntr
    for i = 1, #D.imList do
        local o = D.imList[i]
        if o.v and o.used ~= D.frame then o.d.Visible = false o.v = false end
    end
end

function D.destroy()
    if D.dead then return end
    D.dead = true
    local function kill(list)
        for i = 1, #list do
            local o = list[i]
            pcall(function() o.d.Visible = false end)
            pcall(function() o.d:Remove() end)
        end
    end
    kill(D.sq) kill(D.tx) kill(D.tr) kill(D.imList)
    D.sq, D.tx, D.tr, D.im, D.imList = {}, {}, {}, {}, {}
end

local Png = {}
do
    local band, bxor, rshift = bit32.band, bit32.bxor, bit32.rshift
    local crcT = {}
    for i = 0, 255 do
        local c = i
        for _ = 1, 8 do
            if band(c, 1) == 1 then c = bxor(0xEDB88320, rshift(c, 1)) else c = rshift(c, 1) end
        end
        crcT[i] = c
    end
    local function crc32(s)
        local c = 0xFFFFFFFF
        for i = 1, #s do
            c = bxor(crcT[band(bxor(c, string.byte(s, i)), 0xFF)], rshift(c, 8))
        end
        return bxor(c, 0xFFFFFFFF)
    end
    local function adler32(s)
        local a, b = 1, 0
        for i = 1, #s do
            a = (a + string.byte(s, i)) % 65521
            b = (b + a) % 65521
        end
        return b * 65536 + a
    end
    local function be32(n)
        return string.char(band(rshift(n, 24), 255), band(rshift(n, 16), 255), band(rshift(n, 8), 255), band(n, 255))
    end
    local function chunk(kind, data)
        return be32(#data) .. kind .. data .. be32(crc32(kind .. data))
    end
    function Png.encode(width, height, pixel)
        local rows = {}
        for y = 0, height - 1 do
            local row = { "\0" }
            for x = 0, width - 1 do
                local r, g, b, a = pixel(x, y)
                row[x + 2] = string.char(floor(r), floor(g), floor(b), floor(a))
            end
            rows[y + 1] = table.concat(row)
        end
        return Png.pack(width, height, table.concat(rows))
    end
    function Png.pack(width, height, raw)
        local out = { "\120\1" }
        local pos, total = 1, #raw
        while pos <= total do
            local len = min(65535, total - pos + 1)
            local final = (pos + len > total) and 1 or 0
            local nlen = 65535 - len
            out[#out + 1] = string.char(final, len % 256, floor(len / 256), nlen % 256, floor(nlen / 256))
            out[#out + 1] = sub(raw, pos, pos + len - 1)
            pos = pos + len
        end
        out[#out + 1] = be32(adler32(raw))
        return "\137PNG\r\n\26\n"
            .. chunk("IHDR", be32(width) .. be32(height) .. "\8\6\0\0\0")
            .. chunk("IDAT", table.concat(out))
            .. chunk("IEND", "")
    end
end

Img.builders = {
    ["gen:svwhite"] = function()
        return Png.encode(150, 1, function(x) return 255, 255, 255, 255 * (1 - x / 149) end)
    end,
    ["gen:svblack"] = function()
        return Png.encode(1, 150, function(_, y) return 0, 0, 0, 255 * y / 149 end)
    end,
    ["gen:hue"] = function()
        return Png.encode(1, 150, function(_, y)
            local i = min(floor(y / 25), 5)
            local t = (y - i * 25 + 0.5) / 25
            local r1, g1, b1 = unrgb(Img.HUES[i + 1])
            local r2, g2, b2 = unrgb(Img.HUES[i + 2])
            return r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t, 255
        end)
    end,
    ["gen:checker"] = function()
        return Png.encode(150, 10, function(x, y)
            local v = ((floor(x / 5) + floor(y / 5)) % 2 == 0) and 255 or 190
            return v, v, v, 255
        end)
    end,
    ["gen:fadebar"] = function()
        return Png.encode(256, 1, function(x)
            local t = min(x, 255 - x) / 64
            if t > 1 then t = 1 end
            t = t * t * (3 - 2 * t)
            return 0, 0, 0, 255 * t
        end)
    end,
    ["gen:fadetop"] = function()
        return Png.encode(1, 20, function(_, y) return 23, 23, 23, 255 * (1 - (y + 0.5) / 20) end)
    end,
    ["gen:fadebot"] = function()
        return Png.encode(1, 20, function(_, y) return 23, 23, 23, 255 * (y + 0.5) / 20 end)
    end,
    ["gen:rainbow"] = function()
        return Png.encode(256, 1, function(x)
            local t = x / 255
            local r1, g1, b1, r2, g2, b2
            if t < 0.5 then
                t = t * 2
                r1, g1, b1, r2, g2, b2 = 55, 177, 218, 204, 70, 205
            else
                t = (t - 0.5) * 2
                r1, g1, b1, r2, g2, b2 = 204, 70, 205, 204, 227, 53
            end
            return r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t, 255
        end)
    end,
}

local function isImageData(s)
    if type(s) ~= "string" or #s < 16 then return false end
    local b1, b2, b3, b4 = string.byte(s, 1, 4)
    if b1 == 137 and b2 == 80 and b3 == 78 and b4 == 71 then return true end
    if b1 == 255 and b2 == 216 then return true end
    return false
end

local function assetId(src)
    if type(src) ~= "string" or #src > 200 then return nil end
    if string.match(src, "^headshot:") or string.match(src, "^gen:") or string.match(src, "^icon:") then return nil end
    if string.match(src, "^https?://") and not string.find(src, "roblox.com/asset", 1, true) then return nil end
    return string.match(src, "(%d+)%s*$") or string.match(src, "%d+")
end

local function isImageSrc(src)
    if type(src) ~= "string" then return false end
    if isImageData(src) then return true end
    if string.match(src, "^rbxasset") or string.match(src, "^https?://") or string.match(src, "^headshot:") or string.match(src, "^gen:") or string.match(src, "^icon:") then return true end
    return string.match(src, "^%d+$") ~= nil
end

Img.icons = {
    rage = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f9870000049f4944415478daed996d485b5718c7e32c485229ce4a692b545ca61b948d8028d26229d2d1cab062b45f1ad466b155576dd548d5e964cad86abad8e25b0c25753010e707b5d42a122c54448c89af6d69a52f5f5a28946e94aea32fb89efe9fec5e8892977be3f5ea460efc38c77bef79eef3bf39e739cf392a18638aff328a908090809080ff99005f6571713106e4810ba097c30c4e83fd40112c424b5002f0821dc002de03e60ba7d3f904f5f760db5a04e0ef4fc1c7920880a123e085a7a35d5d5d2c8090bfc7c6c674c10840fb00d9686868f87a7878f838da0ea00a4a003a1ef574aca4a48425262632954ac53232325c6ab59af5f6f6fa14d2dede6e0b4240dee4e4e4bdcaca4ab70d87c3f154a9543a714b254a003aefe61d292f2f678585856ec771eb07f0258804872d16cbb7fe7e8dfefefe79d4567019b4009307347f7ee1ea6af009a7236f7c7cfc5d5f5fdf7df2193c044ab1020678270a0a0ae8e27950cb39bea214151555b5b5b5f91d5642c1179fe27e79557171f1cbbababa7b6837008360017878276fb0b5b595d150415fa3bfe8303838f89b14020883c1b0049347e7e6e6863cafe39a41a880137c27abd5ca301e6fa3f35e3fe19504bff3e7d4c2c202c390600303036c68686805232323ee7bf9f9f92c2c2c8c1c6515151514f54ea27d35323292454545b17f7f0061024cab1dd0ebf597fd083884c8331d48405c5cdc7b3c3e07e883dc5fc523ee5ee5fcfc3c451ff7d7371a8d16ee35dbc076a1027e5dedc0f4f4347d81235e9c4f153a344a4b4bc946628028b4859e4518be8ba8778bda985f574485516f0288acacacb7a87f069f712fbb039e091540c3253c3cfcc7400bd9ececec195a6bd0bcd9d9d9793d333393da67c508b8e0cf1197cbf5163cf0bc46eb415555156b6a6a623333333efb464444d070f948402a510a46b97623c81723e094d0af8af1ca7273731917af5dc09c9090f03bbef68ab4a3b9b999555757f39334625d732118fc4aa8006e6e2c83539e0e6135bdc63f939a9aea16989e9e6e477d0984adb780adf8b2af858ae8e8e85846fd3908e732565a55973de23771086d0deafdb264a310e014bb00a1cf73d46fbc4d5ed49d400dd31a5904785b0bd64a5959d90d9856cb25205b6a01b5b5b564fc1bb904ecc2eaf98f940290e393f136d9766458501e4829202727878c5b651300c31352393f3535c5b03121e327e514b024d6518a38b4f9494e4e661a8d86a5a4a4309bcde65ec860f22fb055ae39b027d026de1b6969698ccb2e69f37310ecaba9a9316ab55aca407b643b9580d163c10c15bbddce5a5a5a2ea2cde73bdbc179acc65a98d5ca29e0a7358ef93f50df04afb057b0735bd21d720a906c02633ebc86c9ebb21e6cc1a84e0ae77b7a7af85ce880ec27732693c9b616e72726265874743419746cd8d1627d7dfd956027734c4c0c19fbd3dfd897e56c14394cab580174ca80ae8fc1ce0d3fdca5a2d3e9ce8d8e8e8a12919494b4b4294ea7f9121f1fbfcf6c36bf12e23c42278b8d8d2563c99b46005794d9d9d937babbbb7d3a4fc78c9cf3143ee3379b00be6420d771e9f57a779adcd8d8e8ce81b0a1e7c3e635a1ce6f9400bed049f5394a93810d7c07be50ac5309fd932f2420242024202440723e00519d788e333093ba0000000049454e44ae426082",
    aa = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f987000008184944415478daed5909505555186615244c72692647110d2313ac691ad70a31051207461095c544a1a01c45514012034c40df980816ab31ac4f84021405d9644776590cc132973205b749d229176edfffe6bce6f5e62df7c153a78933f3cdbbcbbbe7fcdf3dff7e35388ed3f82f436384c008811102521786303a3b3ba7016ec0d74019d00bf4315c002a8078601d3003d09004dfa1560258781413ba1cb8dadadada7ee2c489c27dfbf6e5797a7a16d8dbdb97d9d9d9d5ad5ab5aad1cfcfaf393e3ebeb3b4b4f44a7373731fd08467bc0083e742008b7a005d1d1d1de7525252122d2c2cbec5e5a3403ce00f380396c03b0cef014e809f9999599aafaf6fdba953a7fa1b1a1a7e05994d984bfb9910c042af3275b87ce8d0a1683d3dbd145c4e06d600af48ab863c60bcaca5a5e5e4e5e5751ae35e7575f585c6c6c6d94f950016fe00b87be6cc999c891327c6e25216b01cd0e12bb80c229a93274fb68b8a8aea696b6b7b24140a3f7d2a04b09835703f3f3f3f09a7054010f082c4fd6101434f2010e441250741264cad04b08015f018e0acadaddb71e900bd39a9ff0c9780688044024870e1e1e1bbd44280b9c73f0a0a0a0e6fdebcf9624b4bcba0a3a363216ed94b925017011af0564944c2dbdbfba36111c0c49a401d743e0fa745c0bea0a0a0aeb367cf0e3a3b3b1749925027011ad9d9d9c5f052f74d4c4ccc8643602dd06f64649480d36026ac4370707037a9938b8b4b899884ba09905badafafbf151818d84c4e4265022c48fd0857198553da81d16c0e1189d0d0d09ef6f67652a762b8d21538f6c1ff0b815a201df804301e2a011a98d3a1b6b6f6c1d4a953d70d85802bf4f0275d5ddd4c9cda49cd4d24ec030202bab10887dfc19898188ef496764612555555293c08cc06a28035808be44250df9ead5bb792e330509540556a6a2aa94e06202b4a6a3a3838ec8a8c8ce488c4b265cb06f5f5f539c4072e3131f15f244e9e3c791dbf0b81b781378099c02c263805bf97cacbcbf3908a3cc48e06606e1709555a575c5c7c1b41cf993701b6f5d710f2c51156a68ed21b3f78f0e0e30d1b3670306ccec9c9a905b756438899717171d7a577431e20780b7cff9bf072b5dbb76f7f9895951521b18e11528d9b73e7ce2535d6e44bc01d51b1030f7c47215f0e8195b4385c1ea7adadfd3824244464d848dc4a49bd6a6a6a76cb12b6a2a282835a70c88144a8ababe30e1c38c0191a1a36e5e5e505c4c6c61e879328c71c1bc56be1e5546ddbb68dd4683a5f02b1f0fbe4261315a415df8885a2b78d4b2be062c92606e19daaf6efdfdf276d1324b08181010775b801d2f774747406f01ce12e02572ffe3fb071e346721a21c01689b5223333337b2941e44ba03c222222976595f2081c96140ee9729ba5a5a5efce9d3baf904decd8b1839365d850af3ff1b821b32b728fbab84eb954545858581508d0fd0fa5d672c1ce5d21627c09f47878781c67e9af3c021162a1c442d22f090df222c3463d40b1e29ffb74cdcdcd8dbcc47a196e94c8d0db0f04be905a6b515353d335d208be046e5231c272787904ec65e93809bb65cb160e2f4024b0abab6b27914a4e4e26d5e1c68d1bf7048ffbaa5291e1fe1cd8641f0e33f912b805b758cf0a1179934ea0cc511e091f1f9f81bd7bf7dea6737f7f7f8a159cadad6d176c631439065509c09089400e5f0217e0121b1511a081b7f2833cd72856a73d7bf6887602062e3ab7b1b1592fab7e5042e07db8daabe415f912a8841a34e18177954c2c50e4dfc524e06144c764d8a6a6a66403d35524b01ad55a0f0e857c092452014eae51c9c42b94052969128b172f26029f4b27804ad6f9b2acacac0687497c0978e001da323f25137b2a12fed8b163dc82050b387373736edebc791c8291e83a0cbc5a3a8b55b24e497474740e0e77f325301de1fbd6b469d352954c9ca38800222b377efcf80bf8ab0ddca79385854516e2453fed0422f66949120ad63004ae60e7d228ade19dcc517e82dce42c0ec7cbcb8580477c721d18f12ff8bd337ffefcb7685731bac8b011234aa52b3b19ebac02e16e44ed6c9cbea64a36ea0535a22cd051413257c437614392f63b1ebb03bc484283443b1f1254110a85426a2450fb464b1502a311fdfaa1af950ade9076464646bf32e1919cd1a48470712b459284bbbb7bb92c12ac8dd33f69d2a4c3387553b9a40481cf90553e408e6fa3c81690ccfda688809595154d1a27dd0f6245510733ec4a198d82eedcdcdc585611be38949a5807e9ee25a4bb1729e9524402d1b64d1e0104459ad44156538b8446903bc7d4a942c2b069b72e8d1933860aaab5436eaba026b5a014592010e42bf1481a709591e42ab3b3b3b9c2c24251adb064c912b1fa7c2caf334742a36ceca075a89ec05a51ac6910897b47a8e935acc6d6912347bcc9f551d3491101269029b09f320d8076ae98b25a65ed4522b169d3a656f1ae61d705b8463b324b2dad45948ea1f486121212921411184e8f146bc490f09e9e9ebd4c786bb5367791e7ef427c7872f4e851729fa3d448408bd205e02f64ab5f31e1973f95f63ad2e4f52837a91d7e1dd1da590d046c017200e7e14ea9982f95f5e6d5fa81c3d8d878264ac786cacaca0118f939f6b163820a421bb11ed0694a1372727212c68e1d4b1d104a5dcc9fd527261d1313930d0846ad454545fd88197da80f2aa900a7ae06eb68cf615844752d539353c0cfb0a7aeb4b4b4a42953a6c4b12f3bd4c8d57fa6dfc8d8a06f044e0b172efc9e0afbf4f4f41e14e097a98605a11ba8a46e5031827cfe7c49494915b2caeca54b97a6234511e239fa2ce50a183d978f7c32c60c60252bcac9e5525b9292304a8585ac4d13ca9a65af2b4ae2864560e443f70881ff1981bf019176052e040933170000000049454e44ae426082",
    legit = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f987000006424944415478daed5a7b4c535718e75dd80015989b15d800138760dc23cb020c912c19208fc124ce256064fc21444d1660c675889b096412c27894051ce0c056273450a42defc70091f2286d111fdb20d34d3335b2c56c80c684fdbee59230a3e5de5edaaad9497ec9f9ee29e79edfbddff9ceeffb2e560b0b0b564f33ac9e19027c9a5eaf7f143603338f19fb0fb836731158a756ab27313cf34413c0026c801780442017380df4007a9d4e372b9148eea22b01be0062813580b5c509e0c66ecc824e01c343434392929292ca949494fa909090b684848409954a351f10103087be3e333373b4a6a646dbd7d777056f46323e3e1e89bf5b657602b8a113b013383b3a3ada919797972f140a1b9c9c9c466d6c6c2af193fdc0fb494949f158e8efe85f02deb0b7b7ffc0cdcdeda09f9f5fddeeddbba76532d9f5d6d6d6be9696169acbd62c0470a30d408d56ab1d10894405b874165001bb80b58013b0e81ede78da75b0a797b88a0df01ce009a4eed9b3e7627373f39dc6c64655575797b749096001ef905ff7f4f4480402c1495cea03120c6c621aa2455519dac0dededefbc462f11dbc8ddbc5c5c5112621801bbd07dcacaeae2e24132803ec978942ac81b62a272767a2b7b7f73ede6cf28a12c00d42815bf9f9f979306f02fb5886512e04fe6dd9d9d9ca8e8e8e076969691fad0801c6e7f5cc93bfc5f8ba95a908502b2d2d5520f4ce45464686f22280899f074ec0e7a58cdbece378901945809a542ad51d3e7cf89aafafef3a3e041211abcf3b3b3bd7c2fcc68893d86802b8e6ded4d4742b36369682851d6702cc6979f6d0a1435fc11c60c2a3d90850c35e380077ba6d6b6b1b6a0c81581c526d4c9c8f33520bf12280eb2e08ad93616161ad74b67025f07d6e6e6e3eba0a1e628e2f01eb73e7ce651615155d87f9366b02f8c3b5c008e4811ce6879622404da3d16cc1097dd5d1d1f10417023b0607074f42bb8c32f2c0620430e68128a8841b5d86e9c096402e54651584d9f1a5a7ad850838404f1dc301a785b98d2d8133105924c20e3cbc793812f002caf96664c3c3c3e990e1e3e88ad812e80a0e0eee60137d9621b001aaf5370c97f32180f178a5523981ee098304f0c38d0cf4f1f1f1fad4d4d41df4148d20e0c9cc138950fc33f4ff0dc6f6e018857c98bf4bebefef9f4262f403d986088c8f8c8c5cc4539b4392313f3030300d75588fdf7b7124503e36367681168fb9eec9e5f2399a179aff287eeac181801c734c62ae6b5004f3389967691e0c6d34e442e3b5b5b577376dda34873eed7cf2bd4aae2e446ee3e9e979018ba67966997908fb39ba903c2a2a6aaaa2a2e26ff4ff5a9c67b93d20450e4bbbfe75be6515bc813f313cc6730fecc55b6c47b799ed26fe322323630c61348127018fbababa3c3e65158c0980a3858585b2a59eb01c81180a5b50a1593cc3280d793cce6d581278116fb13e2626a61a66165b026b7078fc88e87106a6c0c207d95bd8c41a3b3b3b3a9782588b39ec76497272f234533db09898030ee20ca007a9066cb9a8d188fafa7a52811f5b900015ce7a915a16c12ce12aa75ddbdadafa9392922e5890c0276ab59ad2d9de872322ab94120412150ac58c8f8fcf5e7313c0b5f554ae8c8e8ea6e259b5b139b143434383422c16cfc05c6d66024ae401c7acadad87a92c6974590504bca86206393b612e02b08b810e5757574a253f7f5428e754d8426e108eb07a3f272747616a024c09fe8abfbf3fb90d2962e715292de20deceaecec7c505a5aaa341501e6c95f0e0a0a12c3bc02bcbca2c5ddf4f4f49d1289645e2a956ae9845c4102af000aa0333030f03b4644be6a92f23a8ef4d023478efc4a4527ec8d4cdc74b50102a4e7e58f19b366beea7c0aa8dbdbdb0bdcdddda98cd309f89af4038750285c17171777aaacacec36485cc6fec8c222b6002f31e26b7191eb21037e2249ccd88e8090e401b3f0bea1a121e9f6eddb8b9993361b5863ae4f4cb6028160dbd6ad5bdba1146f20e4fdd2ddddad4202944f392c161747999446a3b91a1111718dfaa42a9198c890a48c411e9cc6f5af1126e91b4315f0a6a53ef2d93045a7caf0f0f04b2291488b8448a352a92691d14d61c1f7aaaaaa66a1e7db0a0a0a64787394d792b6390f9044788dade235cb6756b47781cf2801777171e994c96494491128a67f0b6402214fcb77e2cd3a9dee0ff2ef27fe43b781b69932b2959ef4d9fc5f89ff095808ff006e4aa2c0c5934b9b0000000049454e44ae426082",
    visuals = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f987000006644944415478dad59a6b4c145714c71151decbf252203c4cb1ad123e148b980056d444f18390a018c826882d826004b4abacac064adc2008013f91a00920226151013520589e4a35cadb686a6aa295545b1fb8d6824ac5dbffd9cc9a2dedeab0cc6cbb93fc32bbb3f7de39ff3bf79e73e6deb5b0e08e919111a109034d603d9ff2b33e44109005984aa5fa09cdaf374701fb48407a7a3a43f385e628600f09484b4b23012ab315909a9a4a02be3347013924202b2b8b04e4fe57021601a99102beeeebeb7bb575eb5612503a5301b8660ffc6723c017fc0c237eccc9c9f9cc1811ab56ad52a0690df8762602f05d027a8687879f2995ca75c60a90c0f8011a06f5f5f5e37171717c455872bd474f6e7e44444410ce0edcf58f0ac0676bd04cf76d6969197771717986cb4b8d1a4272b9dca7baba5a438dd5d4d4bcd8bc79b3e7078c580632c0693088defb05bcc6e7b74343430f060707db7096e3fb72430270b602e7e87e4d4d4d1a3737371a7eb7809bd19378dbb66dde30fe29357ae6cc194d5555d5e7d3caac016a304565f4e9eaea7a7bead4a9a9f6f6f6bf5defeeeeeec179c3b476a873dae9f7c6c6c631a9544ac65f071eb3f6425bb66c5970e2c48927d4786464e46d14a7f9e102cac1e474c375646464306b6beb473e3e3e034141414f64321953abd5ef7fc710e9c4d9432ff560757575cfedededc9f86bc05530375a5454e481f17c1545d9ead5ab1370ed9a21c3757031201fd8006f10e2eeeebe6fd3a64df73b3a3ab465dadada34478e1c09231b140a452ac63cd5e9028e82c7011c527896687c1efe98f17a6944eebfb4e3101c1c9c969f9f3fc13d89373b76ec58cb99120e168815c8c8bdf5f3315e4f80ea031de285debf49655b5b5b27e3e3e383c58ec4657c8de72340476565e56d2a7ff4e8d19746f53e4f015f81776208a0b8d1d3d3334e75a2a3a3bbc51060c9f9772692008bcecece78aa73ecd831269148360a2d20004c8829808e2b57aedc43f0632b56ac20ff3f4f4801e93335de1801382753bde4e4e477f8ba5c280173409d890450def4eef8f1e36ceedcb90785124089599f89042c4402f908a906432a4193d9928fe12bc17e70106473e48114300fd8625cde379180f9fdfdfdd7a92e12b9a79e9e9ecef89c040ee9d9760028c15a5da516430620efc9a3c904010f4d21800e64ac941f313b3b3b8648bddc50db087c0f507cadf609ecddbbf74e4a4a0a4b4a4ad2b273e74e161b1bcbacacacd8e2c58b8351e69ea99e00e8a5ba9413f9fafa4a90012b76eddaf5de364c70b67dfb76f254d4f6559df095603fa08993cd41bd9f525a5a2a45af0c9a6a0ee0693fe8eded9d747070605c54a679f00d38a467db01a0d43e013e5e08e3f2b429bd10de395e595a5a3ec6252741e2009e8049e3008608c581765e5e886f24c62be1a409040cd113080c0c64dc10112e1742b2d526a600104375f0e6f712ce43d048ace5c68d1b1194a788958d8251aa131e1e4e75be173a17d272e1c2854691045453f9929292717a65051b447b236b6e6e7e2cb080622a8b74fa776767672a5f2beadae8e1c3873f3d7ffefc840002bc4005b7fc32e6e5e54565ef0277b10438736f6516d9d9d9cbd46af538cf5589e90268954e067ee35625c6fcfcfca8dc9db2b2b2580a666208b0d5e54c797979b4ba6611131313585050f0ebc0c0804101999999f476458998370801999cabd4fe5e5858f8cad5d5958cbf595c5c1c47d72e5fbe3c181515e52fa40047d04a8d9f3d7bf6393244ba6124e7bb9d71b373454545538813ff10402b72172f5e7c08eff548ff7a7979b9262c2c8c7113b61a2ca4052eb86a6ddaded0d0f0223737d74f0801b440abf5ffb5b5b5cf6c6c6ce8863f702b73fa41684d484848ab4c269b424f6a57df2e5dbac4e07a19098390d730fa754242020b0808d019dea8eb085d2043f2e65d5151f184ebac3f944ae5d2d90890e856dfd0231a474747c68577bb0f44d32f90c364a06c839393d330deaa4691944dd8dadafe89ebf7f07b33d803be34944eab542afb93274f6ae7073cde0432d000a3f70790038dc2f78f73e394d62aa53cd38239c01eaf86cb70b60212fa4eb90d9ffd010c49f7fafafa310c29b664c992bb46af4ecbe5f2504cc251fc3ccc8dd319edd0801770b9f9c6ec132726267af8fbfbd3eac453a3f707b88617515a6bec1e9942a17833d31d1abd839eda27ff875dca1273df27ce1d31f39d7ab3dc27d6fe5762f7eedd66bb531f8af8712b3434940414882e40a4231434817562dde02f938a9a2fb21516680000000049454e44ae426082",
    misc = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f9870000068e4944415478daed590b4c965518669440c84d04143398dc2a221c52e854744302a75018ce2487695318b8c2b8e86a73818ed1c0d594456cf61b0c18170792110ae4859b72c901cecb6acb3257662d25af332ea7e775e773a7c3f7ffdff7ebeff6bbf16dcffe8f73cefb9ef739df39efe560c318b3799261334960928085083cca73e6cc9987c5f3c0b74086a4cf056806d2d5e6b316029f004c415c5c5c91a0af57693f7af4e845fcfa5923810b2281cece4e565f5f5f8cf73ab19d101c1c3c8869fcac8dc022d95035141616927184606b2360d3dbdb7b518b80bfbf3f19576dd12d04c56f00df71b4f1dfcd66186f0b2c06861543b76ddbc6e6cf9fcf121313596b6beb03029999992c2828689ea50974cb2b75ead4a911746991580f7c0f5c1665d7ad5ba76c93cf80657e7e7e5b4f9c3831aaf4f7f5f5dd1d1a1a3a8ff72ab30940c85ba5ed924c001330171797eb92c19e80b3f077ab2c07e314e3df17e7e8eaea2a50db52e8aad24500839f0106817b6d6d6d1f4b7daafbd5d3d3731cdd6edcd878e0e6e0e0e05583c110c2db9a64999e9e1e9afcb6cafc1f1821c0340960a003704e142c2f2fa76d130d341a238031ecc081031bf1be556c3f79f2e4584242c23cbcbf8df77bb2dc92254beea8101810c79c3e7d9a5557576b13c0e019b2b02570fcf8f1b1ecececa069d3a6bd131212722d3939f9be51ca57d8bd7b7721de038108a045912b2e2e66111111ccdddd9d8cbc07f46b1148b6b4f10ab66fdf7e0b5378020e40587b7bfbef5a3238d064dc21200af0d23cc49487207cff6069e33b3a3a98b7b7374d54c8cf833f70474b2e232383645e34cb8dc6c4c478363636de34a5f8e0c183aca0a080eddcb9935555559934024e4009487f013e9c409b3c2e2f2f8fd5d5d54d90c7962b313b0ee0b0ad5133e6c891232c323252717de7804a603f82d0d98a8a0a5502b9b9b934f632a503824bad17c7c4c6c6ded73965ca94afe0424784f8a290f7358b80da0a61cf325757571afc0bb0424e25f02ca8acac1c96e5285173707030c8812d2929a987a22ead3c5f90353c06841e3b766c6cc78e1dccd1d191da6f002f9924c05de4477c6586d4563234349494fd09b89bc8856ce1554664d9c3870f8f222694e33d138853c623f82541c5af8041d4e9e3e313869fdf8052c049730b691da6b2b23265951668257330344f4bdff2e5cb370b5fcece482260afbba081a27f4d4d989e9e4ec677e8cc46976911080808207dfe9c80598f3102374c4db869d3269a304f2781c55a04e6cc9943fa422c49c0e48439393934e1873a09bcaea50f2932e97bc192043a29a3343621b94fc87eaa9340b529e3c92b79797991be508b11a0c7d7d7b70f89d538e5e76a13a7a5a55dd341205c4d965c2212bafb790d778d7f03cfa22f1698ada293da1d1ee656c20758595252d2aa66c8962d5b2a4c1078955268b52c957b3072891b29afa9a9a9a1ecb48c67ab97d0365bd0f71eaf15fe405f12de1dcd8ec4104a33b6059a9a9a28b57e1398c90b96d7802f8c8ddfbb772f4dd0297da9b3e2983d7bf60c735d2b65f9b56bd7e640de51370108bd028c6b1d44f8fb519c9b9b3a33d1f312815c794c7f7fff04578e88ccecededc9c0305d04789678fb71a4d3a807eac4888dedf18f964c747434197785a7e0ba08443eae7a000468a2f502891fc5dab8b4b494353434fc4f263c3c9c6412cd3a0348c83e5733007582a69134a6b7b777423b2a2e3675ea54969a9a4a77a139c037e2219f3e7dba521bb7c0db5d11b7506d6d2d2582297419a6fb10efdab5ab514c69972e5dcaecececd8ead5abaf9b8ad63466d6ac595791d78fc9b76bf9f9f91754ce11f3f0f0a0fe2e6086323f6aeb412345fd22ddd72aa8479be9b3f2a043296d1c2558a8656fa92977767656a2352561cfeddbb7ef3a8c565c680dc634c832ddddddd4370acc941c49aa1a595db712d243572a2d147404e5ed6a04dcdcdc9870ada2649a8d4039fffb6b5966606080b6d6b08a1bffd2c81718b5c4cd5cadacb8b9b95959690f1337736159595967a90ca5f18a6c5151d1b898f3f3abcb718520dd4ce05c500afe505f408d40404a4a4adfaa55ab9882c0c04052f293d6bd28f7e7d95486a21a7b50f8b4b4b45020db0f1c1217262a2a8af48ef09b895ce02d4bdd4e0700ef4a78d9cc1b6acddbe9850b17927109d6f80f8e2c3db103a5287372725a618d047e160d45f2c85007b3f8f8f80924e6ce9d4bb5f1d3d646200601f32ec518ba0bb2b5b525239a814083c17088da29286ed8b081be00f5853f36028ff0c400ed3cc60c004f097df9bc9d569fb25157930426ffd13d496092c09389ff0044f2054b20afdb240000000049454e44ae426082",
    skins = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f987000003584944415478daedd9514853511807f011e9982318cc18248443992f6ee05e87a1d82807f6107bb1107d490a318806050d8d91b80d13438c39dc83ce48a1e1969b3ad91603270ed77042af51d0434105516650edf47de35eb88ce5eeb46bf7c0fde0cfbd77771ececf9d9d73bcca0821329a239300124002702e98dadddd6d8028653c0bde7ba454526501d0e019c86c5d5d5d135c2a6904d872b9dc77389d8554d108c842f0628fba21048d5563e7314aa592d00838c702743a1d024ed106b8cd022c160b020cb4017c2c6078781801576803c458402c1643809736c04b1680d1ebf51f680364b90087c3819f82912640920bd8d9d9212a95ca4f13608e0bc0b85cae7cb9e9544c803bc5004c7b7b7b941680a91460636383b4b4b49869009c8071ffb51422140afd321a8da745bf9903c0e35200ccf2f2f28fb5b535add877a367ff06c06c6d6dfd5e5c5cbc265a00562a950a1c84c0442291141cf5a20440a3aa720036f1787c098ef721372155a2006041c7faf922d828148a5bf8579c280058c16030c5b7f3939393d8001115002b1c0e7fe403181a1ac2069e8b660871be0ff2d5d5d5fd72005827b08169d101b0464646d4309cca223a3b3bdf891280e5f7fbf57c86d2fcfcfc33385a21d721374403c0f2783cbd369b8d040201de33d3cccccc3a0e433e00386f84f43069f8e700a67053f7b0adadedb5cfe7e385d8dcdcfc065b94109ce39a8133db8522840e1229feb94422312704805be7ed76fb9b4ad70b4c341a45c85d880792c7d7c6c7c7dfc22f8674777793edededc2fbdc6e77464840a14647475f1c06c18dd56acd33ebc834e4527373f33d16a1d56a1f090ac06100633d7dd8cea7d3697611ece7b60baf87f17e474707ded3080ac0180c8627030303646565a52240369b25b5b5b57b25da2d3c64989a9a2235353556c101cc8cd20871582c96f7636363b8fde685585858c8c36a6e64dac3ed88937bbfafaf2f07b74e0a0e28c25cd66834c1aeaeae7da7d3893bd703113053e53399cc2b38ffc2998689d96c266ab51a3bd87bac000e440db92a97cb9fb6b6b67ec261e6f57a4932993c68fdf8693299d8ef4602824348f35f0045986a662d71c0b88ec36cf3193e21323838482626260acf64ebebebd98eaf432e0a3e8d1eb114ccd3bf1ec803c812f34cb6a9e29558fa37ab04900012e0d8f3075f20fb26e526cb3f0000000049454e44ae426082",
    players = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f987000002664944415478daed993f685a511487a5c5452999ab4bc031ede012cce6a04484a4b163200e9a455c85560c4483528284404533d46010226a0c311442511405a943269d1c3ab5591248e6522837e780179290c43ff7bd775ee05df87883727ebf8fa7be7b51c718d3bd64749a8026a0093cf3e298abdfefdfe53db00e6c0cf103ef1ebce71ecf2d25059c401d608ff113165c1d6a15d87eaaf843cae57251550250e0ebb8e539e974fa5c150210fe71d2f21cafd7fb9d5400825f0397d30a349b4da6d7eb3d94022bd396e7389dce1b18f58a4a604f5420128960c83295c00f51814c268321692a81a6a840369bc590332a81235181643289210d2a81b0a880cfe7c3901295804554c0643261c827b20759a7d3399db67c2291c0006496f2493cd3ed76ff4e5abedd6e33a3d1880179f2bd50a1505868341affc72d5fafd799c562c1e157c01b55ec46ad56abad52a9fc1b55be582c3283c18083ff00736ad98dae0287bd5eef629440ad5663a954ea1a3e423ef2dd2804bb80f369bfc4ad56eb175c1749042639c08ca2044b5101083d96aa3c077e08068a0840d889d4e539b95cee42560108f92257794e2c161bc82200c317e42ecf71b95c393904064a0954ab550c9e974c00867e50aafc9dbbf05b4a8196d202c383ce92b0000c332b5d9e63369b3b5208ac5109b8dd6ebc0b6f450576a90442a1100aac8a0a1c5009c0330105764405f6a904a2d1280aec8b0ae4a904e2f1380a7c131558a112b0dbed287020fc1c8093d699d2e5c3e1303ff02f4bb295f0783ca77ebf9f0583411608046401676386cd66e3e553526fa71dc067600bd89489ad61864392ad84f637ab26a0096802b2730b3541367406815e2c0000000049454e44ae426082",
    config = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f987000002354944415478daed994d4b024118c7bdd57790b2103a98b740f05087a24347914e5e4dc39347a98b572f5e14212fe129d00e11d125c54bb8f8b2f8f21582e898a5bdea4ecf033bb1c814343bbbb9300b3f4665f83ffe649c9d997511425c4ec62505a480149002f32b30180c568033e01e18ea8c01229807e00458142600614bc033ab603c1efff0f97c4404a150e83bb75eaf0f2b95ca9a8b71f1085c6068bfdfff06df974a258279c031b02102c8d5a844a3d198a6d3e96d11022396403e9fc72f7f4b83e13353e8199fb416b6ad564b4b26937b66055e5802c5621105ae38049499a1b8631098186be16b4551b44824b2654660f88bc00d87c0ad5120100860ce0e4b80d6aa56ab53bfdfbf3acf02db3f09d07a994c66045d161c2ba0aa2af63b75ac00fca1b1dfbb6305605ac57ee37910508d02c160f02f028fc20472b91caf007657f59b2065d7768172b98c8197826f649a2d0234341a8dde41bb218843561d4b052c40b34dc04e840a58f4cb33112e806d381cd6bc5e2fb19a4422418c754d0b20bd5e8f4e7b07c0bad540bda9617f605ea0dd6e63c884b55312318d32329f850a743a1d0c79b551606c85c09b14900252400a480129e02481977910d04f25b804c6336ba1b7ff580b359b4dee53894b1ad2ed76ed5e0bbdd3da8542016b8f78049655559dd0a0582c864bdc7d206c21987f641cba6eb71b05aeb99ed0a452a9cd6c363ba9d56ab6eec814457982bac4e3f1d0a1bbca25a05f5ea002dccf9ce9580dd63b07d6b84ea7e5534a2920059cc1176ff41d542fa7e2bd0000000049454e44ae426082",
    grenade = "89504e470d0a1a0a0000000d49484452000000300000003008060000005702f987000004204944415478daed9a4b6c15551cc67f33030d8f561ebe90965795166b140c09cac247dc6882d144591963e25676ea969d894b176ed41034b2118d0b359254a08956250513ddf01016221a424c35a2020df7f1b9f03bc9c9157be7ce9dde7b899d643277ee3d73ceef3be7ff3ad32692b89e8f94ebfc9817d0ed634187c74b0001f70143c065df578063c01f519b7c1d76d08903d88386ff0cb80864c0b0bffb0298e945130af0370323c07e60da333f039c00ce039ba2f63d2700cff249a0168d9d7815ce0203c0c2564ca8d34e9c01572241a9616bc05f5e917a2fae4098d16960adefeb3e33e02e6007b01d58e6dfd35e74e20c7818f811f80d180506813eaf403ff018b0cb1129b5c89e08a32950057e015e02a68045b6fd5f81e5c071e04f602ff0bc3fcf2a22ed60bea9015b807d0e9f53c005479f043805fc0c4c026f03ef7b45eaddf681059ef931601cd8681b7f1cf806b86a11e71c52ef062680372d6449370504f84d4e5cb7008b8197edcca3c069e0276029b019f8c12bf5357004f8b45b3e90197e143868670df13f055e70dcaf18748b9f39eee7266d662bbb2120ccfc88e1870c9f456155c073fefe9243ec0ab77d037805580dec9e3d404b659f99af1b259dd33f4755ff3eea926abebe2e69b3a485920e4bba3fef7865e781cc337a0770d8761ecffcb5129cbc5abbbd62673dfb7d7e569d0aa32154de6eb369061f925b62d817813551355af3d991301a1c76183804accf011f8ba803b75ac00ee089bccfa7259acd8602f031470db8d391e969e0a63c855d5a12fc7ac36f28001ff72527b2eddef8a8595f6909f0eb0c3f6c33cadae8b3667f38ea3ec3ca941e4643a85c2be9cc2ca1b295a3e2eb9e689ca4194b3bf06b249d2e09feaaaf7bdd779a07be8880003f28e954c9f0ef46632479998ac0af9674b261d9db85dfdfeaccb79a8983c3ae72861db3c3b6534b55bc81ff18782acaca2afbb54a801f749d3ee6fb76e0ab863f00ec8cb2adca7eb518e08781f75ce354da0c95158b1ff7cc57a36c5ce07541733b1b947450d25649bb1a6cb768a81c97b428b2fbc2d56fb306b749fa5ed287beef933451d08143fb43921697019f47c064142a9ff477434deafcd9e027242d290b3e8f807dde74d4245d303c92ee95f47b4e1101fe73494bcb84cf23e001ef9802c49168061f9274b18988f0dc979206ca86cf2320f1e075493386f9204a36db249dff0fc78e45df3017f07933f1231150807aa761ef7bb4619f1bda4d495a3e57f0790404c8b7a2590e701f495ae6dffb25bdd6b002c724ad68e8a7e30212cf5c9f7341a388ef9c1f42fb7b247deb42efc6b986cf6b4289cffe484435b2f92b925e95b452d298a44f5c6acf397c2bd5681a25b23dd7a82625695ad25792463a05df6a391d97b93b259d68b0f93392d67512bec88bad24daa70e00cf02cff8a5eda37e299535ddc796f95793f9ff959817f03f17f037176434c2b5c507f10000000049454e44ae426082",
}
Img.HUES = { rgb(220, 30, 30), rgb(220, 30, 220), rgb(30, 30, 220), rgb(30, 220, 220), rgb(30, 220, 30), rgb(220, 190, 30), rgb(220, 30, 30) }
Img.vgN = 0
Img.bgRows = { { 20, 20, 12, 20 }, { 12, 20, 12, 20 }, { 12, 20, 20, 20 }, { 12, 20, 12, 20 } }

function Img.dynamic(src)
    local name = string.match(src, "^icon:(%w+)$")
    if name then
        local hex = Img.icons[name]
        if not hex then return nil end
        return function()
            return (string.gsub(hex, "%x%x", function(h) return string.char(tonumber(h, 16)) end))
        end
    end
    local g1, g2, gh = string.match(src, "^gen:vg:(%d+):(%d+):(%d+)$")
    if g1 then
        g1, g2, gh = tonumber(g1), tonumber(g2), tonumber(gh)
        if gh < 1 or gh > 512 then return nil end
        return function()
            local r1, gg1, b1 = unrgb(g1)
            local r2, gg2, b2 = unrgb(g2)
            return Png.encode(1, gh, function(_, yy)
                local t = (yy + 0.5) / gh
                return r1 + (r2 - r1) * t + 0.5, gg1 + (gg2 - gg1) * t + 0.5, b1 + (b2 - b1) * t + 0.5, 255
            end)
        end
    end
    local bw, bh = string.match(src, "^gen:bg:(%d+)x(%d+)$")
    if bw then
        bw, bh = tonumber(bw), tonumber(bh)
        return function()
            local rows = {}
            for r = 1, 4 do
                local px = {}
                for i = 1, 4 do
                    local v = Img.bgRows[r][i]
                    px[i] = string.char(v, v, v, 255)
                end
                rows[r] = "\0" .. sub(rep(table.concat(px), floor(bw / 4) + 1), 1, bw * 4)
            end
            local out = {}
            for yy = 0, bh - 1 do out[yy + 1] = rows[yy % 4 + 1] end
            return Png.pack(bw, bh, table.concat(out))
        end
    end
    return nil
end

function Img.drawBg(win, x, y, w, h)
    local tiles = win.bgTiles
    if not tiles or win.bgW ~= w or win.bgH ~= h then
        if tiles then
            for i = 1, #tiles do
                local src = tiles[i][1]
                if src ~= "gen:bg:128x128" then Img.cache[src] = nil end
            end
        end
        tiles = {}
        win.bgTiles, win.bgW, win.bgH = tiles, w, h
        local nx, ny = floor(w / 128), floor(h / 128)
        for j = 0, ny do
            local th = (j < ny) and 128 or (h - ny * 128)
            for i = 0, nx do
                local tw_ = (i < nx) and 128 or (w - nx * 128)
                if th > 0 and tw_ > 0 then
                    tiles[#tiles + 1] = { "gen:bg:" .. tw_ .. "x" .. th, "bg" .. win.id .. "_" .. (#tiles + 1), i * 128, j * 128, tw_, th }
                end
            end
        end
    end
    for i = 1, #tiles do
        local t = tiles[i]
        if not D.image(t[2], t[1], x + t[3], y + t[4], t[5], t[6]) then
            D.rect(x + t[3], y + t[4], t[5], t[6], 1118481)
        end
    end
end

function Img.diskPath(id)
    return Library.Folder .. "/Icons/" .. id .. ".txt"
end

function Img.diskLoad(id)
    local ok, data = pcall(function()
        local path = Img.diskPath(id)
        if not isfile(path) then return nil end
        local hex = readfile(path)
        if type(hex) ~= "string" or #hex < 16 then return nil end
        return (string.gsub(hex, "%x%x", function(h) return string.char(tonumber(h, 16)) end))
    end)
    if ok and isImageData(data) then return data end
    return nil
end

function Img.diskSave(id, data)
    pcall(function()
        local hex = string.gsub(data, ".", function(c) return fmt("%02x", string.byte(c)) end)
        writefile(Img.diskPath(id), hex)
    end)
end

function Img.resolve(kind, ids)
    local out = {}
    local i = 1
    while i <= #ids do
        local part = {}
        for j = i, min(#ids, i + 29) do part[#part + 1] = ids[j] end
        i = i + 30
        local url
        if kind == "asset" then
            url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. table.concat(part, ",") .. "&size=150x150&format=Png"
        else
            url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. table.concat(part, ",") .. "&size=48x48&format=Png"
        end
        local ok, body = pcall(httpget, url)
        if ok and type(body) == "string" and #body > 2 then
            for obj in string.gmatch(body, "{[^{}]*}") do
                local id = string.match(obj, '"targetId"%s*:%s*(%d+)')
                local img = string.match(obj, '"imageUrl"%s*:%s*"([^"]+)"')
                if id and img then out[id] = img end
            end
        end
        task.wait(0.02)
    end
    return out
end

function Img.work()
    while #Img.queue > 0 and Library.Running do
        local batch = Img.queue
        Img.queue = {}
        local assets, heads, jobs = {}, {}, {}
        for _, src in ipairs(batch) do
            local head = string.match(src, "^headshot:(%d+)")
            if head then
                heads[#heads + 1] = head
                jobs[#jobs + 1] = { src = src, kind = "head", id = head }
            elseif string.match(src, "^https?://") and not string.find(src, "roblox.com/asset", 1, true) then
                jobs[#jobs + 1] = { src = src, url = src }
            else
                local id = string.match(src, "(%d+)%s*$") or string.match(src, "%d+")
                if id then
                    assets[#assets + 1] = id
                    jobs[#jobs + 1] = { src = src, kind = "asset", id = id }
                end
            end
        end
        local amap = (#assets > 0) and Img.resolve("asset", assets) or {}
        local hmap = (#heads > 0) and Img.resolve("head", heads) or {}
        for _, job in ipairs(jobs) do
            if not Library.Running then break end
            local url = job.url
            if job.kind == "asset" then url = amap[job.id] elseif job.kind == "head" then url = hmap[job.id] end
            if url then
                local ok, data = pcall(httpget, url)
                if ok and isImageData(data) then
                    Img.cache[job.src].data = data
                    if job.kind == "asset" then Img.diskSave(job.id, data) end
                end
                task.wait()
            end
        end
        for _, src in ipairs(batch) do
            local e = Img.cache[src]
            if e and not e.data then
                e.pending = false
                e.tries = (e.tries or 0) + 1
                e.retryAt = now() + 3 * e.tries
            end
        end
    end
    Img.busy = false
end

function Img.kick()
    if Img.busy then return end
    Img.busy = true
    task.spawn(function()
        task.wait()
        local ok = pcall(Img.work)
        if not ok then Img.busy = false end
    end)
end

function Img.get(src)
    local e = Img.cache[src]
    if e then
        if not e.data and e.pending == false and (e.tries or 0) < 5 and now() > (e.retryAt or 0) then
            e.pending = true
            Img.queue[#Img.queue + 1] = src
            Img.kick()
        end
        return e.data
    end
    if sub(src, 1, 7) == "gen:vg:" then
        Img.vgN = Img.vgN + 1
        if Img.vgN > 400 then
            Img.vgN = 1
            for k in pairs(Img.cache) do
                if sub(k, 1, 7) == "gen:vg:" then Img.cache[k] = nil end
            end
        end
    end
    e = { pending = true }
    Img.cache[src] = e
    if isImageData(src) then
        e.data = src
        return src
    end
    local b = Img.builders[src] or Img.dynamic(src)
    if b then
        local ok, data = pcall(b)
        if ok then e.data = data end
        return e.data
    end
    local id = assetId(src)
    if id then
        local data = Img.diskLoad(id)
        if data then
            e.data = data
            e.pending = false
            return data
        end
    end
    Img.queue[#Img.queue + 1] = src
    Img.kick()
    return nil
end

local K = { toVk = {}, byVk = {}, list = {}, chars = {}, textKeys = {}, tstate = {}, rs = {} }
do
    local function defk(name, vk)
        K.toVk[name] = vk
        if not K.byVk[vk] then
            K.byVk[vk] = name
            K.list[#K.list + 1] = vk
        end
    end
    for i = 0, 25 do defk(string.char(65 + i), 0x41 + i) end
    local DIG = { "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }
    for i = 0, 9 do
        defk(DIG[i + 1], 0x30 + i)
        defk("Keypad" .. DIG[i + 1], 0x60 + i)
    end
    for i = 1, 24 do defk("F" .. i, 0x6F + i) end
    local other = {
        Insert = 0x2D, Delete = 0x2E, Home = 0x24, End = 0x23, PageUp = 0x21, PageDown = 0x22,
        LeftShift = 0xA0, RightShift = 0xA1, LeftControl = 0xA2, RightControl = 0xA3, LeftAlt = 0xA4, RightAlt = 0xA5,
        CapsLock = 0x14, Space = 0x20, Tab = 0x09, Return = 0x0D, Backspace = 0x08, Escape = 0x1B,
        Minus = 0xBD, Equals = 0xBB, LeftBracket = 0xDB, RightBracket = 0xDD, Semicolon = 0xBA, Quote = 0xDE,
        BackSlash = 0xDC, Comma = 0xBC, Period = 0xBE, Slash = 0xBF, Backquote = 0xC0,
        Up = 0x26, Down = 0x28, Left = 0x25, Right = 0x27,
        MouseButton1 = 0x01, MouseButton2 = 0x02, MouseButton3 = 0x04, MouseButton4 = 0x05, MouseButton5 = 0x06,
        KeypadMultiply = 0x6A, KeypadPlus = 0x6B, KeypadMinus = 0x6D, KeypadPeriod = 0x6E, KeypadDivide = 0x6F,
        NumLock = 0x90, ScrollLock = 0x91, Pause = 0x13, LeftSuper = 0x5B, RightSuper = 0x5C, Print = 0x2C,
    }
    for name, vk in pairs(other) do defk(name, vk) end
    table.sort(K.list)

    local function defc(vk, lo, up)
        K.chars[vk] = { lo, up }
        K.textKeys[#K.textKeys + 1] = vk
    end
    for i = 0, 25 do defc(0x41 + i, string.char(97 + i), string.char(65 + i)) end
    local shifted = ")!@#$%^&*("
    for i = 0, 9 do
        defc(0x30 + i, tostring(i), sub(shifted, i + 1, i + 1))
        defc(0x60 + i, tostring(i), tostring(i))
    end
    defc(0x20, " ", " ") defc(0xBD, "-", "_") defc(0xBB, "=", "+") defc(0xDB, "[", "{") defc(0xDD, "]", "}")
    defc(0xDC, "\\", "|") defc(0xBA, ";", ":") defc(0xDE, "'", "\"") defc(0xBC, ",", "<") defc(0xBE, ".", ">")
    defc(0xBF, "/", "?") defc(0xC0, "`", "~") defc(0x6E, ".", ".") defc(0x6D, "-", "-")
    K.textKeys[#K.textKeys + 1] = 0x08
    K.textKeys[#K.textKeys + 1] = 0x0D
    K.textKeys[#K.textKeys + 1] = 0x1B
end

function K.name(key)
    if key == nil or key == false then return nil end
    if type(key) == "number" then return K.byVk[key] end
    local s = tostring(key)
    local n = string.match(s, "([%w_]+)$")
    if n and K.toVk[n] then return n end
    return nil
end

function K.vk(key)
    if type(key) == "number" then return key end
    local n = K.name(key)
    return n and K.toVk[n] or nil
end

function K.enum(name)
    local ok, v = pcall(function()
        if sub(name, 1, 11) == "MouseButton" then return Enum.UserInputType[name] end
        return Enum.KeyCode[name]
    end)
    if ok and v ~= nil then return v end
    return name
end

function K.display(name)
    if not name or name == "Escape" then return "-" end
    local keys = Library.UI.Keys
    local d = keys[name] or keys[K.enum(name)]
    if d then return sub(tostring(d), 1, 3) end
    return string.upper(sub(name, 1, 3))
end

function K.raw(vk)
    if vk == 0x01 and ismouse1pressed() == true then return true end
    if vk == 0x02 and ismouse2pressed() == true then return true end
    return iskeypressed(vk) == true
end

function K.down(vk)
    return UI.active and K.raw(vk)
end

function K.rep(vk)
    if not K.down(vk) then
        K.rs[vk] = nil
        return false
    end
    local t = now()
    local at = K.rs[vk]
    if not at then
        K.rs[vk] = t + 0.4
        return true
    end
    if t > at then
        K.rs[vk] = t + 0.04
        return true
    end
    return false
end

function K.typed(prime)
    local out = {}
    local act = UI.active and true or false
    local shift = act and iskeypressed(0x10) == true
    for i = 1, #K.textKeys do
        local vk = K.textKeys[i]
        local d = act and iskeypressed(vk) == true
        if d and not K.tstate[vk] and not prime then
            if vk == 0x08 then out[#out + 1] = "\8"
            elseif vk == 0x0D then out[#out + 1] = "\r"
            elseif vk == 0x1B then out[#out + 1] = "\27"
            else
                local ch = K.chars[vk]
                out[#out + 1] = shift and ch[2] or ch[1]
            end
        end
        K.tstate[vk] = d
    end
    if K.tstate[0x08] and not prime then
        if not K.bsAt then K.bsAt = now() + 0.4
        elseif now() > K.bsAt then
            out[#out + 1] = "\8"
            K.bsAt = now() + 0.04
        end
    else
        K.bsAt = nil
    end
    return out
end

local function report(err, name)
    err = tostring(err)
    if Library.Errors[err] then return end
    Library.Errors[err] = true
    warn("[gamesense] " .. tostring(name or "error") .. ": " .. err)
    if Library.Notify and Library.UI.NotifyErrors and not Library.Unloaded then
        pcall(function()
            Library:Notify({ Message = "[ERROR] " .. tostring(name or "") .. ": " .. err, Delay = 8 })
        end)
    end
end

local function safecall(fn, a, b)
    if type(fn) ~= "function" then return end
    task.spawn(function()
        local ok, err = pcall(fn, a, b)
        if not ok then report(err, "callback") end
    end)
end

local function approach(v, t, speed)
    if v == nil then return t end
    local sp = speed or Library.UI.TweenSpeed or 0
    if sp <= 0 then return t end
    local k = UI.dt * 4 / sp
    if k >= 1 then return t end
    v = v + (t - v) * k
    if abs(t - v) < 0.004 then return t end
    return v
end

local function inside(x, y, w, h)
    local mx, my = I.mx, I.my
    return mx >= x and mx < x + w and my >= y and my < y + h
end

local function over(x, y, w, h)
    if UI.drag or UI.capture or UI.noInput then return false end
    if not UI.inPop then
        local pr = UI.popRect
        if pr and inside(pr[1], pr[2], pr[3], pr[4]) then return false end
        if UI.clip0 and (I.my < UI.clip0 or I.my >= UI.clip1) then return false end
    end
    return inside(x, y, w, h)
end

local function click()
    if I.m1p and not I.used then
        I.used = true
        return true
    end
    return false
end

local function rclick()
    if I.m2p and not I.used2 then
        I.used2 = true
        return true
    end
    return false
end

local function anchor(o, x, y, w, h)
    o.ax, o.ay, o.aw, o.ahh, o.seen = x, y, w, h, D.frame
end

local function openPop(owner, kind)
    local p = UI.pop
    if p and p.owner == owner and p.kind == kind then
        UI.pop = nil
    else
        UI.pop = { owner = owner, kind = kind, born = D.frame }
    end
    UI.popRect = nil
end

local function closePop(owner)
    if UI.pop and (owner == nil or UI.pop.owner == owner) then
        UI.pop = nil
        UI.popRect = nil
    end
end

local function tw(s)
    return #s * CW
end

local function clampText(s, maxW)
    s = tostring(s)
    local n = floor(maxW / CW)
    if #s <= n then return s end
    if n <= 3 then return sub(s, 1, max(n, 0)) end
    return sub(s, 1, n - 3) .. "..."
end

local function num14(v)
    return fmt("%.14g", v)
end

local function parseRich(s, base)
    s = tostring(s)
    local lines = { {} }
    local stack = {}
    local cur = base
    local function push(text)
        local start = 1
        while true do
            local nl = string.find(text, "\n", start, true)
            local part = sub(text, start, (nl or (#text + 1)) - 1)
            if part ~= "" then
                local line = lines[#lines]
                line[#line + 1] = { t = part, c = cur }
            end
            if not nl then break end
            lines[#lines + 1] = {}
            start = nl + 1
        end
    end
    local pos = 1
    while true do
        local a, b, tag = string.find(s, "<(/?[^<>]+)>", pos)
        push(sub(s, pos, (a or (#s + 1)) - 1))
        if not a then break end
        local word = string.lower(string.match(tag, "^/?(%a+)") or "")
        if sub(tag, 1, 1) == "/" then
            if word == "font" then
                if #stack > 0 then
                    cur = stack[#stack]
                    stack[#stack] = nil
                end
            elseif not (word == "b" or word == "i" or word == "u" or word == "stroke") then
                push(sub(s, a, b))
            end
        elseif word == "font" then
            stack[#stack + 1] = cur
            local r, g, bl = string.match(tag, "rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)")
            if r then cur = rgb(min(tonumber(r), 255), min(tonumber(g), 255), min(tonumber(bl), 255)) end
        elseif word == "br" then
            push("\n")
        elseif not (word == "b" or word == "i" or word == "u" or word == "stroke") then
            push(sub(s, a, b))
        end
        pos = b + 1
    end
    local w = 0
    for _, line in ipairs(lines) do
        local n = 0
        for _, seg in ipairs(line) do n = n + #seg.t end
        line.n = n
        if n > w then w = n end
    end
    lines.w = w * CW
    return lines
end

local function drawRich(lines, x, y, a, outline)
    for li = 1, #lines do
        local line = lines[li]
        local cx = x
        for si = 1, #line do
            local seg = line[si]
            D.text(cx, y + (li - 1) * CH, seg.t, seg.c or C.t208, a, outline)
            cx = cx + #seg.t * CW
        end
    end
end

local function softBar(x, y, w, h, a, key)
    if key and D.image(key, "gen:fadebar", x, y, w, h, nil, 0.42 * a) then return end
    local e = floor(w * 0.25)
    local steps = 16
    local sw = e / steps
    D.rect(x + e, y, w - e * 2, h, 0, 0.42 * a)
    for i = 0, steps - 1 do
        local o = 0.42 * a * (i + 0.5) / steps
        local x0 = floor(x + i * sw)
        local x1 = floor(x + (i + 1) * sw)
        D.rect(x0, y, x1 - x0, h, 0, o)
        local rx0 = floor(x + w - (i + 1) * sw)
        local rx1 = floor(x + w - i * sw)
        D.rect(rx0, y, rx1 - rx0, h, 0, o)
    end
end

function Library:Validate(Defaults, Options)
    Options = Options or {}
    for k, v in pairs(Defaults) do
        if Options[k] == nil then Options[k] = v end
    end
    return Options
end

function Library:NewFlag()
    Library.UnnamedFlags = Library.UnnamedFlags + 1
    return "UnknownFlag" .. tostring(Library.UnnamedFlags)
end

function Library:Connection(Signal, Func, Name)
    if not Signal then return nil end
    local conn
    local ok, res = pcall(function()
        return Signal:Connect(function(...)
            local ok2, err = pcall(Func, ...)
            if not ok2 then
                report(err, Name or "Unknown")
                if conn then pcall(function() conn:Disconnect() end) end
            end
        end)
    end)
    if not ok then return nil end
    conn = res
    Library.Connections[#Library.Connections + 1] = conn
    return conn
end

function Library:ClampString(String, MaxWidth)
    return clampText(String, MaxWidth)
end

function Library:GetTableLength(Table)
    local n = 0
    for _ in pairs(Table) do n = n + 1 end
    return n
end

function Library:GetTableIndexes(Table, Custom)
    local out = {}
    for k, v in pairs(Table) do
        if Custom then out[v[1]] = k else out[#out + 1] = k end
    end
    return out
end

function Library:SetTableVisible(Table, State, Ignored)
    for _, e in pairs(Table) do
        local skip = false
        if Ignored then
            for _, ig in pairs(Ignored) do if ig == e then skip = true end end
        end
        if not skip and type(e) == "table" and e.SetVisible then e:SetVisible(State) end
    end
end

function Library:UpdateColor(ColorType, ColorValue)
    if ColorValue == nil then return end
    Library.Theme.Default[ColorType] = ColorValue
end

function Library:ViewPlayer(Player)
    local ok = pcall(function()
        local cam = workspace.CurrentCamera
        local target = Library.UI.Viewing and Players.LocalPlayer or Player
        cam.CameraSubject = target.Character:FindFirstChild("Humanoid")
        Library.UI.Viewing = not Library.UI.Viewing
    end)
    if not ok then
        Library:Notify({ Message = "View player is not supported by this executor", Delay = 3 })
    end
end

local Json = {}
function Json.encode(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "0" end
        return num14(v)
    end
    if t == "string" then
        local s = string.gsub(v, '[%c"\\]', function(ch)
            if ch == '"' then return '\\"' elseif ch == "\\" then return "\\\\" elseif ch == "\n" then return "\\n" end
            return fmt("\\u%04x", string.byte(ch))
        end)
        return '"' .. s .. '"'
    end
    if t == "table" then
        local n = #v
        local isArr = true
        for k in pairs(v) do
            if type(k) ~= "number" then isArr = false break end
        end
        local out = {}
        if isArr then
            for i = 1, n do out[i] = Json.encode(v[i]) end
            return "[" .. table.concat(out, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = tostring(k) end
        table.sort(keys)
        for _, k in ipairs(keys) do
            out[#out + 1] = Json.encode(k) .. ":" .. Json.encode(v[k])
        end
        return "{" .. table.concat(out, ",") .. "}"
    end
    return "null"
end

function Library:GetConfig(NoLayout)
    local cfg = {}
    for flag, obj in pairs(Library.Flags) do
        if type(obj) == "table" and obj.Get and not obj.NoConfig and not string.find(flag, "_Status", 1, true) then
            local ok, v = pcall(function() return obj:Get() end)
            if ok and v ~= nil then
                if type(v) == "table" and v.Color and v.Transparency then
                    cfg[flag] = { obj.Hue or 0, obj.Saturation and obj.Saturation[1] or 0, obj.Saturation and obj.Saturation[2] or 0, v.Transparency }
                elseif obj.isKeybind then
                    cfg[flag] = { v, obj.Mode }
                else
                    cfg[flag] = v
                end
            end
        end
    end
    if not NoLayout and Library.GetLayout and #Library.Windows > 0 then
        local ok, layout = pcall(function() return Library:GetLayout() end)
        if ok then cfg.__layout = layout end
    end
    if UI.sels and UI.W then
        local groups = {}
        for _, sel in ipairs(UI.sels) do
            if sel.lastGroup ~= nil and sel.sections then sel.sets[sel.lastGroup] = UI.W.gSnap(sel) end
            local g = { current = sel.lastGroup, sets = sel.sets }
            if not sel.isStrip then g.enabled = sel:Values() end
            groups[sel.Flag] = g
        end
        cfg.__groups = groups
    end
    return Json.encode(cfg)
end

function Library:LoadConfig(Config)
    local ok, cfg = pcall(function() return HttpService:JSONDecode(Config) end)
    if not ok or type(cfg) ~= "table" then return false end
    if type(cfg.__layout) == "table" and Library.SetLayout then
        local ok2, err = pcall(function() Library:SetLayout(cfg.__layout) end)
        if not ok2 then report(err, "LoadConfig layout") end
    end
    if UI.sels and UI.W and type(cfg.__groups) == "table" then
        for _, sel in ipairs(UI.sels) do
            local g = cfg.__groups[sel.Flag]
            if type(g) == "table" then
                UI.W.gBase(sel)
                if type(g.sets) == "table" then sel.sets = g.sets end
                if type(g.enabled) == "table" then
                    for i, it in ipairs(sel.Items) do
                        local v = g.enabled[it.Name]
                        if v ~= nil then it.CurrentValue = (v and true or false) or (sel.LockFirst and i == 1) end
                    end
                end
                local it = type(g.current) == "string" and sel:Find(g.current) or nil
                if it then
                    sel.CurrentItem = it
                    sel.lastGroup = it.Name
                    if sel.isStrip then sel.Value = it.Name end
                end
            end
        end
    end
    for flag, value in pairs(cfg) do
        local obj = Library.Flags[flag]
        if flag ~= "__layout" and flag ~= "__groups" and type(obj) == "table" and obj.Set and not obj.NoConfig then
            local ok2, err = pcall(function()
                if obj.isKeybind and type(value) == "table" then
                    obj:Set(value[1] or "None")
                    if value[2] ~= nil then obj:SetMode(value[2]) end
                else
                    obj:Set(value)
                end
            end)
            if not ok2 then report(err, "LoadConfig " .. tostring(flag)) end
        end
    end
    return true
end

function Library:ConfigPath(Name)
    return Library.ConfigFolder .. "/" .. tostring(Name) .. Library.ConfigExt
end

function Library:SaveConfig(Name)
    local ok, err = pcall(writefile, Library:ConfigPath(Name), Library:GetConfig())
    if not ok then report(err, "SaveConfig") end
    return ok
end

function Library:LoadConfigFile(Name)
    local path = Library:ConfigPath(Name)
    local ok, data = pcall(function()
        if isfile(path) then return readfile(path) end
        return nil
    end)
    if ok and type(data) == "string" then return Library:LoadConfig(data) end
    return false
end

function Library:ListConfigs()
    local out = {}
    local ok, files = pcall(listfiles, Library.ConfigFolder)
    if not ok or type(files) ~= "table" then return out end
    for _, path in ipairs(files) do
        local name = string.gsub(tostring(path), "\\", "/")
        name = string.match(name, "([^/]+)$") or name
        local ext = Library.ConfigExt
        if sub(name, -#ext) == ext then
            out[#out + 1] = sub(name, 1, #name - #ext)
        end
    end
    table.sort(out)
    return out
end

function Library:UpdateConfigList(List, Type)
    if not List then return end
    if Type == "Remove" then
        if List.Clear then List:Clear() end
        return
    end
    for _, name in ipairs(Library:ListConfigs()) do
        List:AddValue(name)
    end
end

function Library:HeadshotImage(UserId)
    return "headshot:" .. fmt("%.0f", tonumber(UserId) or 0)
end

function Library:Disable()
    for _, obj in pairs(Library.Flags) do
        if type(obj) == "table" and obj.Set then
            pcall(function() obj:Set(false) end)
        end
    end
end

function Library:Unload()
    if not Library.Running and D.dead then return end
    Library.Running = false
    Library.Unloaded = true
    UI.gen = (UI.gen or 0) + 1
    for _, conn in ipairs(Library.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Library.Connections = {}
    if not UI.inStep then D.destroy() end
    if _G.Library == Library then _G.Library = nil end
end

local W = { CMENU = { "Copy", "Paste" } }
UI.W = W
local POP = {}
local SB = {}

function W.cut(s, maxW, bold)
    s = tostring(s)
    local nl = string.find(s, "\n", 1, true)
    if nl then s = sub(s, 1, nl - 1) end
    if not maxW then return s end
    local n = floor((maxW - 1 - (bold and 1 or 0)) / CW)
    if n < 0 then n = 0 end
    if #s <= n then return s end
    return sub(s, 1, n)
end

function W.mid(y, h)
    return y + floor((h - CH) / 2)
end

function W.top(y)
    return y + floor((Z(11) - CH) / 2)
end

function W.cw(w, cap)
    return clamp(w + Z(20) * 2 - Z(100), Z(40), Z(tonumber(cap) or 200))
end

function W.len(s)
    local n = 0
    for i = 1, #s do
        local b = string.byte(s, i)
        if b < 128 or b >= 192 then n = n + 1 end
    end
    return n
end

function W.addc(c, d)
    local r, g, b = unrgb(c)
    return rgb(clamp(r + d, 0, 255), clamp(g + d, 0, 255), clamp(b + d, 0, 255))
end

function W.copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = W.copy(x) end
    return out
end

function W.blur(e, entered)
    if UI.focus ~= e then return end
    UI.focus = nil
    e.Focused = false
    if e.CheckIfPressedEnter and not entered then return end
    Library.Flags[e.Flag] = e
    safecall(e.Callback, e.Text)
end

function UI.take(o)
    if UI.focus and UI.focus ~= o then W.blur(UI.focus, false) end
    local p = UI.pop
    if p and p.owner ~= o then closePop() end
    UI.kf = o
end

function W.tap(o, hov)
    if I.m1p then
        if hov and not I.used then
            I.used = true
            UI.held = o
            UI.take(o)
        end
        return false
    end
    if I.m1r and UI.held == o then
        UI.held = nil
        return hov and true or false
    end
    return false
end

function W.rtap(o, hov)
    if I.m2p then
        if hov and not I.used2 then
            I.used2 = true
            UI.held2 = o
        end
        return false
    end
    if I.m2r and UI.held2 == o then
        UI.held2 = nil
        return hov and true or false
    end
    return false
end

function W.marker(x, y, w, h, oc, oa)
    D.outline(x, y, w, h, oc, oa)
    D.rect(x + 1, y + 1, w - 2, h - 2, C.white, 120 / 255)
end

W.WIDE = { T = true, W = true, M = true, m = true, w = true }

function W.label(e, x, y, maxW, text)
    local s = W.cut(text or e.Name or "", maxW)
    if s == "" then return 0 end
    local c, a = T.text, 1
    if e.Risky then c, a = T.risky, 187 / 255 end
    if e.Enabled == false then
        if not e.Risky then c = C.white end
        a = 70 / 255
    end
    if W.WIDE[sub(s, 1, 1)] and not D.font then x = x + 1 end
    D.text(x, W.top(y), s, c, a)
    return #s * CW
end

function W.frame(sx, sy, Wd, S, name, bg, border)
    if name and name ~= "" then
        name = W.cut(name, Wd - 40, true)
        local nw = #name * CW + 1
        D.rect(sx + 2, sy + 2, Wd - 3, S - 3, bg)
        D.rect(sx, sy, 10, 1, C.b12)
        D.rect(sx + 1, sy + 1, 9, 1, border)
        D.rect(sx + 17 + nw, sy, Wd - nw - 16, 1, C.b12)
        D.rect(sx + 17 + nw, sy + 1, Wd - nw - 16, 1, border)
        D.rect(sx, sy, 1, S, C.b12)
        D.rect(sx + 1, sy + 1, 1, S, border)
        D.rect(sx + Wd, sy, 1, S, C.b12)
        D.rect(sx + Wd - 1, sy + 1, 1, S, border)
        D.rect(sx, sy + S, Wd + 1, 1, C.b12)
        D.rect(sx + 1, sy + S - 1, Wd - 1, 1, border)
        D.label(sx + 14, sy - floor(CH / 2), name, C.white, 200 / 255, true, true)
    else
        D.outline(sx, sy, Wd, S, C.b12)
        D.outline(sx + 1, sy + 1, Wd - 2, S - 2, border)
        D.rect(sx + 2, sy + 2, Wd - 4, S - 4, bg)
    end
end

function SB.thumb(sc, vw, vh, content, width)
    local sw = Z(width)
    local h = floor(vh * vh / content)
    if h < 20 then h = 20 end
    local ty = 2
    local travel, extent = vh - h - 4, content - vh
    if travel >= 0 and extent > 0 then ty = floor(sc.pos * travel / extent) + 2 end
    return vw - sw, ty, sw - 2, h
end

function SB.clamp(sc, vh, content, delta)
    local p = sc.pos + (delta or 0)
    local mx = content - vh
    if p < 0 then p = 0 elseif p > mx then p = mx end
    sc.pos = p
end

function SB.mouse(sc, ox, oy, vw, vh, content, ok)
    local ly = I.my - oy
    if sc.drag and UI.drag ~= sc then sc.drag = false end
    if sc.drag then
        if I.m1 then
            local _, _, _, th = SB.thumb(sc, vw, vh, content, 14)
            local yy = ly - (sc.grab or 0)
            if yy < 1 then
                sc.pos = 0
            elseif th + 1 + yy > vh then
                sc.pos = content - vh
            elseif vh > th then
                sc.pos = floor((content - vh) * (yy - 1) / (vh - th))
            end
            return true
        end
        sc.drag = false
        UI.drag = nil
        return false
    end
    if ok and I.m1p and not I.used then
        local lx = I.mx - ox
        local tx, ty, tw_, th = SB.thumb(sc, vw, vh, content, 14)
        if lx >= tx and lx <= tx + tw_ and ly >= ty and ly <= ty + th then
            I.used = true
            sc.drag = true
            sc.grab = ly - ty
            UI.drag = sc
            return true
        end
        local w14 = Z(14)
        if lx >= vw - w14 - 1 and lx <= vw - 1 and ly >= 1 and ly <= vh - 1 then
            I.used = true
            SB.clamp(sc, vh, content, (ly < ty) and (1 - vh) or (vh - 1))
            return true
        end
    end
    return false
end

function SB.draw(sc, ox, oy, vw, vh, content, a)
    local sw = Z(7)
    D.rect(ox + vw - sw - 1, oy + 1, sw, vh - 2, C.b40, a)
    local tx, ty, tw_, th = SB.thumb(sc, vw, vh, content, 7)
    D.rect(ox + tx, oy + ty, tw_, th, C.b65, a)
end

function W.menu(st, x, y, rows, sel)
    local w, rh = Z(100), Z(20)
    local h = rh * #rows
    D.rect(x, y, w, h, C.b12)
    D.rect(x + 1, y + 1, w - 2, h - 2, C.b35)
    local hi = -1
    if over(x, y, w, h) then hi = floor((I.my - y) / rh) end
    for i = 1, #rows do
        local ry = y + (i - 1) * rh
        local hot = hi == i - 1
        if hot then D.rect(x + 1, ry + 1, w - 2, rh - 2, C.b25) end
        local on = sel == i
        D.label(x + 10, W.mid(ry, rh), W.cut(rows[i], w - 10, hot), on and T.acc or C.white, on and 1 or 200 / 255, hot)
    end
    local picked
    if I.m1p and hi >= 0 and not I.used then
        I.used = true
        st.mheld = true
    end
    if I.m1r and st.mheld then
        st.mheld = false
        if hi >= 0 then picked = hi + 1 end
    end
    if not I.m1 and not I.m1r then st.mheld = false end
    return x, y, w, h, picked
end

function W.room(e)
    local list = e.addons
    if not list then return 0 end
    for i = 1, #list do
        local a = list[i]
        if a.shown then
            if a.isKeybind then
                local size = round(KEY_TEXT_SIZE * UI.sc)
                return Z(20) + #(a.label or "[-]") * floor(7 * size / 13 + 0.5) - 7
            end
            return Z(37) - 5
        end
    end
    return 0
end

function W.lim(e, w)
    local r = W.room(e)
    if r > 0 then return w - 8 - r end
    return w - 4
end

function W.addons(e, x, y, w)
    local list = e.addons
    if not list then return end
    local ax = x + w - Z(17)
    local iy = y
    for i = 1, #list do
        local a = list[i]
        if a.shown then
            a:drawAddon(ax, iy + 1)
            iy = iy + 5 + Z(11)
        end
    end
end

function Library:SetClipboard(Text)
    Text = tostring(Text)
    Library.UI.Clipboard = Text
    pcall(function() setclipboard(Text) end)
    return Text
end

function Library:GetClipboard()
    return Library.UI.Clipboard
end

local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker:Update()
    local r, g, b = hsv2rgb(self.Hue, self.Saturation[1], self.Saturation[2])
    self.Color = Color3.new(r, g, b)
    local R, G, B = round(r * 255), round(g * 255), round(b * 255)
    self.c1 = rgb(R, G, B)
    self.c2 = rgb(max(R - 23, 0), max(G - 23, 0), max(B - 23, 0))
    self.sw1 = W.addc(self.c1, 20)
    self.sw2 = W.addc(self.c1, -20)
    local hr, hg, hb = hsv2rgb(self.Hue, 1, 1)
    self.hueC = rgb(round(hr * 255), round(hg * 255), round(hb * 255))
    Library.Flags[self.Flag] = self
    safecall(self.Callback, self.Color, self.Alpha)
end

function ColorPicker:Set(Color, Transparency)
    local t = type(Color)
    if t == "boolean" or Color == nil then return end
    if t == "table" and Color.R == nil then
        self.Hue = tonumber(Color[1]) or 0
        self.Saturation = { tonumber(Color[2]) or 0, tonumber(Color[3]) or 0 }
        self.Alpha = tonumber(Color[4]) or 0
    else
        local ok, h, s, v = pcall(function() return rgb2hsv(Color.R, Color.G, Color.B) end)
        if not ok then return end
        self.Hue, self.Saturation = h, { s, v }
        self.Alpha = tonumber(Transparency) or self.Alpha or 0
    end
    self:Update()
end

function ColorPicker:Get()
    return { Color = self.Color, Transparency = self.Alpha }
end

function ColorPicker:UpdateHue(p) self.Hue = clamp(tonumber(p) or 0, 0, 1) self:Update() end
function ColorPicker:UpdateAlpha(p) self.Alpha = clamp(tonumber(p) or 0, 0, 1) self:Update() end
function ColorPicker:UpdateSaturation(px, py)
    self.Saturation = { clamp(tonumber(px) or 0, 0, 1), 1 - clamp(tonumber(py) or 0, 0, 1) }
    self:Update()
end

function ColorPicker:SetVisible(b)
    self.shown = b and true or false
    if not self.shown then closePop(self) end
end

function ColorPicker:SetEnabled(b)
    self.Enabled = b and true or false
    if not self.Enabled then closePop(self) end
end

function ColorPicker:Toggle()
    openPop(self, "color")
end

function ColorPicker:ToHex()
    local r, g, b = unrgb(self.c1)
    return fmt("%02X%02X%02X%02X", r, g, b, clamp(round((1 - self.Alpha) * 255), 0, 255))
end

function ColorPicker:Copy()
    local text = self:ToHex()
    Library.UI.LastCopiedColor = { Hue = self.Hue, S = self.Saturation[1], V = self.Saturation[2], Alpha = self.Alpha, Color = self.Color, Text = text }
    Library:SetClipboard(text)
    return text
end

function ColorPicker:Paste(Text)
    if Text == nil then Text = Library:GetClipboard() end
    if type(Text) == "string" and #Text == 8 and not string.find(Text, "%X") then
        local r, g, b, a = tonumber(sub(Text, 1, 2), 16), tonumber(sub(Text, 3, 4), 16), tonumber(sub(Text, 5, 6), 16), tonumber(sub(Text, 7, 8), 16)
        self:Set(Color3.fromRGB(r, g, b), 1 - a / 255)
        return true
    end
    local c = Library.UI.LastCopiedColor
    if Text == nil and type(c) == "table" then
        if c.Hue then self:Set({ c.Hue, c.S, c.V, c.Alpha }) return true end
        if c.Color then self:Set(c.Color, c.Alpha) return true end
    end
    return false
end

function ColorPicker:drawAddon(ax, iy)
    local w17, h11 = Z(17), Z(11)
    D.rect(ax + 1, iy + 1, w17, h11 - 2, C.b12)
    D.vgrad("sw" .. self.id, ax + 2, iy + 2, w17 - 2, h11 - 4, self.sw1, self.sw2, 1)
    anchor(self, ax, iy, w17, h11)
    if not self.Enabled then return end
    local hov = over(ax, iy, w17, h11)
    if W.tap(self, hov) then openPop(self, "color") end
    if W.rtap(self, hov) then
        UI.pop = { owner = self, kind = "cmenu", born = D.frame }
        UI.popRect = nil
    end
end

function W.pickAt(cp, part, tx, ty, ts, ax, hy)
    if part == "sv" then
        local s = clamp((I.mx - tx) / ts, 0, 1)
        local v = 1 - clamp((I.my - ty) / ts, 0, 1)
        if s ~= cp.Saturation[1] or v ~= cp.Saturation[2] then
            cp.Saturation = { s, v }
            cp:Update()
        end
    elseif part == "hue" then
        local h = 1 - clamp((I.my - hy) / ts, 0, 1)
        if h ~= cp.Hue then
            cp.Hue = h
            cp:Update()
        end
    elseif part == "alpha" then
        local req = floor((I.mx - ax) / ts * 255 + 0.5)
        if req < 0 then req = 0 elseif req >= 251 then req = 255 end
        local al = 1 - req / 255
        if al ~= cp.Alpha then
            cp.Alpha = al
            cp:Update()
        end
    end
end

function POP.color(p)
    local cp = p.owner
    local px, py = cp.ax, cp.ay + cp.ahh
    local ts, hw, ah = Z(150), Z(15), Z(10)
    local showAlpha = cp.ShowAlpha and true or false
    local pw, ph = ts + hw + 15, showAlpha and (ah + ts + 15) or (ts + 10)
    D.rect(px, py, pw, ph, C.b12)
    D.rect(px + 1, py + 1, pw - 2, ph - 2, C.b60)
    D.rect(px + 2, py + 2, pw - 4, ph - 4, C.b40)
    local tx, ty = px + 5, py + 5
    D.rect(tx - 1, ty - 1, ts + 2, ts + 2, C.b12)
    D.rect(tx, ty, ts, ts, cp.hueC)
    D.image("cp_white", "gen:svwhite", tx, ty, ts, ts)
    D.image("cp_black", "gen:svblack", tx, ty, ts, ts)
    W.marker(tx - 2 + floor(ts * cp.Saturation[1]), ty - 2 + floor((1 - cp.Saturation[2]) * ts), 4, 4, C.b12, 1)
    local ax, ay = px + 5, py + ts + 10
    local op = clamp(1 - cp.Alpha, 0, 1)
    if showAlpha then
        D.rect(ax - 1, ay - 1, ts + 2, ah + 2, C.b12)
        D.rect(ax, ay, ts, ah, C.b40)
        D.rect(ax, ay, ts, ah, cp.c1, op)
        W.marker(ax - 2 + floor(op * ts + 0.5), ay, 4, ah, C.b12, 1)
    end
    local hx, hy = px + ts + 10, py + 5
    D.rect(hx - 1, hy - 1, hw + 2, ts + 2, C.b12)
    if not D.image("cp_hue", "gen:hue", hx, hy, hw, ts) then
        local bh = floor(ts / 6 + 0.5)
        for i = 0, 5 do
            D.rect(hx, hy + i * bh, hw, bh, mix(Img.HUES[i + 1], Img.HUES[i + 2], 0.5))
        end
    end
    W.marker(hx, hy - 2 + floor((1 - cp.Hue) * ts), hw, 4, 0, 150 / 255)

    if UI.drag == cp then
        if I.m1 then
            W.pickAt(cp, UI.dragPart, tx, ty, ts, ax, hy)
        else
            UI.drag = nil
        end
    elseif I.m1p and not I.used and over(px, py, pw, ph) then
        I.used = true
        local part
        if inside(tx, ty, ts, ts) then part = "sv"
        elseif inside(hx, hy, hw, ts) then part = "hue"
        elseif showAlpha and inside(ax, ay, ts, ah) then part = "alpha" end
        if part then
            UI.drag = cp
            UI.dragPart = part
            W.pickAt(cp, part, tx, ty, ts, ax, hy)
        end
    end
    return px, py, pw, ph
end

function POP.cmenu(p)
    local cp = p.owner
    local x, y, w, h, picked = W.menu(p, cp.ax - Z(100), cp.ay + 12, W.CMENU, nil)
    if picked then
        if picked == 1 then cp:Copy() else cp:Paste() end
        closePop()
    end
    return x, y, w, h
end

function Library:ColorPicker(Options)
    Options = Library:Validate({
        Name = "Preview Color Picker",
        Default = Library.Theme.Default.Accent,
        Alpha = 0,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local cp = setmetatable({
        id = nextId(),
        isPicker = true,
        Name = Options.Name,
        Flag = Options.Flag,
        Callback = Options.Callback,
        Default = Options.Default,
        DefaultAlpha = Options.Alpha,
        ShowAlpha = Options.ShowAlpha and true or false,
        Alpha = Options.Alpha,
        Hue = 0,
        Saturation = { 0, 1 },
        shown = true,
        Enabled = true,
        Active = false,
    }, ColorPicker)
    local ok, h, s, v = pcall(function() return rgb2hsv(Options.Default.R, Options.Default.G, Options.Default.B) end)
    if ok then cp.Hue, cp.Saturation = h, { s, v } end
    Library.Flags[cp.Flag] = cp
    cp:Update()
    return cp
end

local Keybind = {}
Keybind.__index = Keybind
W.KMODES = { "Always on", "On hotkey", "Toggle", "Off hotkey" }

function Keybind:Set(Key)
    if self.Hiding or type(Key) == "boolean" then return end
    local name = K.name(Key)
    if name then
        for _, bl in pairs(self.Blacklisted) do
            if K.name(bl) == name then name = nil break end
        end
    end
    self.Key = name
    self.RegKeybind = name and K.enum(name) or nil
    self.Keybind = name and K.display(name) or "[-]"
    self.down = name and K.down(K.toVk[name]) or false
    self.label = "[" .. (name and K.display(name) or "-") .. "]"
    Library.Flags[self.Flag] = self
    if name then safecall(self.Callback, self.RegKeybind) end
end

function Keybind:width()
    return Z(17)
end

function Keybind:Get()
    return self.Key or "None"
end

function Keybind:GetMode()
    return self.Mode
end

function Keybind:Toggle(Bool)
    if self.Hiding then return end
    local owner = self.Owner
    if Bool == nil then
        if self.ChangeToggle and owner and owner.IsToggle then
            self.State = not owner.State
        else
            self.State = not self.State
        end
    else
        self.State = Bool and true or false
    end
    if owner then
        if self.ChangeToggle and owner.Set and owner.IsToggle then
            owner:Set(self.State)
        elseif owner.GetCallback then
            owner:GetCallback(self.State)
        end
    end
end

function Keybind:Active()
    if not self.Key then return true end
    return self.State
end

function Keybind:SetMode(Mode)
    if type(Mode) == "number" then Mode = W.KMODES[Mode] end
    local known = false
    for i = 1, #W.KMODES do
        if W.KMODES[i] == Mode then known = true end
    end
    if not known then return end
    self.Mode = Mode
    if Mode == "Always on" then
        self:Toggle(true)
    elseif Mode == "On hotkey" then
        self:Toggle(self.Key ~= nil and self.down == true)
    elseif Mode == "Off hotkey" then
        self:Toggle(not (self.Key ~= nil and self.down == true))
    end
end

function Keybind:SetVisible(b)
    self.shown = b and true or false
    self.Hiding = not self.shown
    if not self.shown then closePop(self) end
end

function Keybind:SetEnabled(b)
    self.Enabled = b and true or false
    if not self.Enabled then
        closePop(self)
        if UI.capture == self then UI.capture = nil end
    end
end

function Keybind:drawAddon(ax, iy)
    local w17, h11 = Z(17), Z(11)
    local label = self.label or "[-]"
    local size = round(KEY_TEXT_SIZE * UI.sc)
    local kw = floor(7 * size / 13 + 0.5)
    local capturing = UI.capture == self
    anchor(self, ax, iy, w17, h11)
    local en = self.Enabled
    local hov = en and over(ax - w17, iy, w17 + 26, h11 + 1)
    local a = capturing and 1 or (hov and 130 / 255 or 100 / 255)
    D.text(ax + w17 - #label * kw, iy + 1 + floor((Z(10) - size) / 2), label, capturing and C.red or C.white, a, true, size)
    if not en then return end
    if W.tap(self, hov) then
        UI.capture = self
        UI.capHeld = {}
        for i = 1, #K.list do
            local vk = K.list[i]
            if K.raw(vk) then UI.capHeld[vk] = true end
        end
        closePop()
    end
    if self.UseMode and W.rtap(self, over(ax, iy, w17, h11)) then
        UI.pop = { owner = self, kind = "keymode", born = D.frame }
        UI.popRect = nil
    end
end

function POP.keymode(p)
    local kb = p.owner
    local sel
    for i = 1, #W.KMODES do
        if W.KMODES[i] == kb.Mode then sel = i end
    end
    local x, y, w, h, picked = W.menu(p, kb.ax - Z(100), kb.ay + 12, W.KMODES, sel)
    if picked then
        kb:SetMode(W.KMODES[picked])
        closePop()
    end
    return x, y, w, h
end

function Library:Keybind(Options)
    Options = Library:Validate({
        Mode = "Toggle",
        UseMode = true,
        HideFromList = false,
        Blacklisted = {},
        Hiding = false,
        ChangeToggle = false,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local kb = setmetatable({
        id = nextId(),
        isKeybind = true,
        Flag = Options.Flag,
        Callback = Options.Callback,
        Mode = Options.Mode,
        UseMode = Options.UseMode,
        Blacklisted = Options.Blacklisted,
        ChangeToggle = Options.ChangeToggle,
        Owner = Options.Toggle,
        State = false,
        Keybind = "[-]",
        shown = true,
        Enabled = true,
        Hiding = false,
        down = false,
    }, Keybind)
    Library.Flags[kb.Flag] = kb
    Library.Keybinds[#Library.Keybinds + 1] = kb
    if Options.Default ~= nil then
        local cb = kb.Callback
        kb.Callback = nil
        kb:Set(Options.Default)
        kb.Callback = cb
        if kb.Key then
            task.spawn(function()
                task.wait(0.2)
                if not Library.Unloaded and kb.Key then safecall(kb.Callback, kb.RegKeybind) end
            end)
        end
    end
    if kb.Mode == "Always on" then kb:Toggle(true) end
    if kb.Mode == "Off hotkey" then kb.State = true end
    if Options.Hiding then kb:SetVisible(false) end
    return kb
end

local function attachAddons(e)
    e.addons = {}
    e.ColorPickers = {}
    e.KeybindState = false
    local function addPicker(self, Options)
        Options = Options or {}
        local cp = Library:ColorPicker(Options)
        self.ColorPickers[#self.ColorPickers + 1] = cp
        self.addons[#self.addons + 1] = cp
        return cp
    end
    local function addKeybind(self, Options)
        Options = Options or {}
        Options.Toggle = self
        self.KeybindState = true
        local kb = Library:Keybind(Options)
        self.addons[#self.addons + 1] = kb
        return kb
    end
    e.ColorPicker = addPicker
    e.AddColorPicker = addPicker
    e.Colorpicker = addPicker
    e.Keybind = addKeybind
    e.AddKeybind = addKeybind
end

local function addElem(section, e, h, draw)
    e.id = e.id or nextId()
    e.h = h
    e.draw = draw
    e.shown = true
    e.Hiding = false
    e.Enabled = true
    e.section = section
    if not e.SetVisible then
        e.SetVisible = function(self, b)
            self.shown = b and true or false
            self.Hiding = not self.shown
            if not self.shown then
                closePop(self)
                if UI.kf == self then UI.kf = nil end
                if UI.focus == self then W.blur(self, false) end
            end
        end
    end
    e.SetEnabled = function(self, b)
        self.Enabled = b and true or false
        if not self.Enabled then
            closePop(self)
            if UI.kf == self then UI.kf = nil end
            if UI.focus == self then W.blur(self, false) end
            if UI.drag == self then UI.drag = nil end
        end
    end
    e.IsEnabled = function(self) return self.Enabled end
    if section and section.items then
        section.items[#section.items + 1] = e
    end
    return e
end

function W.toggle(e, x, y, w)
    local en = e.Enabled
    local bs = Z(8)
    local hov = en and over(x, y, Z(150), Z(13))
    if W.tap(e, hov) then e:Set(not e.State) end
    local c1, c2, a = gray(100), gray(60), 187 / 255
    if e.State then c1, c2, a = T.acc, T.acc2, 1 end
    if not en then a = 70 / 255 end
    if hov then c1, c2 = W.addc(c1, 10), W.addc(c2, 10) end
    D.outline(x, y + 3, bs, bs, C.b12)
    D.vgrad("cb" .. e.id, x + 1, y + 4, bs - 2, bs - 2, c1, c2, a)
    W.label(e, x + Z(20), y, W.lim(e, w))
    W.addons(e, x, y, w)
end

function Library:Toggle(Options, section)
    Options = Library:Validate({
        Default = false,
        Name = "Preview Toggle",
        Risky = false,
        Hidden = false,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local e = {
        IsToggle = true,
        Name = Options.Name,
        Risky = Options.Risky,
        Flag = Options.Flag,
        Callback = Options.Callback,
        State = false,
        tied = {},
        SectionName = Options.SectionName or (section and section.Name),
    }
    function e:ToggleGUI(v)
        if v == nil then v = not self.State end
        self.State = v and true or false
        Library.Flags[self.Flag] = self
        local tied = self.tied
        for i = 1, #tied do
            local t = tied[i]
            if type(t) == "table" and t.SetVisible then t:SetVisible(self.State) end
        end
        safecall(self.Callback, self.State)
    end
    function e:Set(v) self:ToggleGUI(v) end
    function e:Get() return self.State end
    function e:GetState() return self.State end
    function e:GetName() return self.Name end
    function e:GetFlag() return self.Flag end
    function e:GetSection() return self.SectionName end
    function e:GetCallback(b) safecall(self.Callback, b) end
    function e:SetName(s) self.Name = tostring(s) end
    function e:Tie(...)
        local list = { ... }
        if #list == 1 and type(list[1]) == "table" and list[1].SetVisible == nil then list = list[1] end
        for _, t in ipairs(list) do
            if type(t) == "table" and t.SetVisible then
                self.tied[#self.tied + 1] = t
                t:SetVisible(self.State)
            end
        end
        return self
    end
    attachAddons(e)
    addElem(section, e, UI.RowH.Toggle, W.toggle)
    Library.Flags[e.Flag] = e
    e:ToggleGUI(Options.Default)
    if type(Options.Tied) == "table" then e:Tie(Options.Tied) end
    if Options.Hidden then e:SetVisible(false) end
    return e
end

function W.labelRow(e, x, y, w)
    local s = W.cut(e.Message, (e.Side == "Left") and W.lim(e, w) or nil)
    local tx = x + Z(20)
    if e.Side == "Right" then
        tx = x + w - #s * CW - ((#e.addons > 0) and (Z(17) + 5) or 0)
    elseif e.Side == "Center" then
        tx = x + floor((w - #s * CW) / 2)
    end
    W.label(e, tx, y, nil, s)
    W.addons(e, x, y, w)
end

function Library:Label(Options, section)
    Options = Library:Validate({
        Message = "Preview Label",
        Side = "Left",
        Risky = false,
        Hidden = false,
        Callback = function() end,
    }, Options)
    local e = {
        Message = tostring(Options.Message),
        Side = tostring(Options.Side),
        Risky = Options.Risky,
        Callback = Options.Callback,
        State = true,
        SectionName = Options.SectionName or (section and section.Name),
    }
    e.Side = string.match(e.Side, "([%a]+)$") or "Left"
    function e:GetName() return self.Message end
    function e:GetState() return self.State end
    function e:GetSection() return self.SectionName end
    function e:GetCallback(b) self.State = b safecall(self.Callback, b) end
    function e:SetText(s) self.Message = tostring(s) end
    e.Set = nil
    attachAddons(e)
    addElem(section, e, UI.RowH.Label, W.labelRow)
    if Options.Hidden then e:SetVisible(false) end
    return e
end

function W.fmtValue(e, v)
    local vl = e.ValueLabels
    if type(vl) == "table" then
        local s = vl[v]
        if s == nil then s = vl[tostring(v)] end
        if s ~= nil then return tostring(s) end
    end
    if type(e.Formatter) == "function" then
        local ok, s = pcall(e.Formatter, v)
        if not ok then report(s, "slider formatter") elseif s ~= nil then return tostring(s) end
    end
    local dis = e.Disable
    if dis and dis[1] and ((dis[2] and v <= dis[2]) or (dis[3] and v >= dis[3])) then
        return tostring(dis[1])
    end
    local s
    local step = e.Decimal
    if step < 1 then
        s = fmt((step <= 0.001) and "%.3f" or "%.2f", v)
        while #s > 1 and sub(s, -1) == "0" and sub(s, -2, -2) ~= "." do s = sub(s, 1, -2) end
    elseif v == floor(v) then
        s = fmt("%d", v)
    else
        s = num14(v)
    end
    return s .. e.Ending
end

function W.sliderAt(e, cx, cw)
    local range = e.MaxV - e.MinV
    local step = e.Decimal
    local v = e.MinV + floor((I.mx - cx) / cw * range / step) * step
    return clamp(v, e.MinV, e.MaxV)
end

function W.slider(e, x, y, w)
    local en = e.Enabled
    local cx, cw = x + Z(20), W.cw(w, e.MaxWidth)
    local named = e.Name ~= ""
    local rowH = Z(named and 25 or 10)
    local ly = y
    if named then
        W.label(e, cx, y, w - 4)
        ly = y + Z(14)
    end
    local top = ly + 2
    local th = Z(6)
    local range = e.MaxV - e.MinV
    local hov = en and over(cx - 10, y - 2, cw + 21, rowH + 5)
    if UI.drag == e then
        if I.m1 and en then
            e:SetValue(W.sliderAt(e, cx, cw))
        else
            UI.drag = nil
        end
    elseif hov and I.m1p and not I.used then
        I.used = true
        UI.take(e)
        if I.mx < cx then
            e:SetValue(e.CurrentValue - e.Decimal)
        elseif I.mx > cx + cw then
            e:SetValue(e.CurrentValue + e.Decimal)
        else
            UI.drag = e
            e:SetValue(W.sliderAt(e, cx, cw))
        end
    end
    if en and UI.kf == e and not UI.focus then
        local st = e.Decimal * ((K.down(0x10) or K.down(0xA0) or K.down(0xA1)) and 5 or 1)
        if K.rep(0x25) then e:SetValue(e.CurrentValue - st) end
        if K.rep(0x27) then e:SetValue(e.CurrentValue + st) end
    end
    local cur = clamp(e.CurrentValue, e.MinV, e.MaxV)
    if e.UseIcons and cw < abs(range) / e.Decimal then
        if cur ~= e.MinV then D.rect(cx - 5, top + 3, 3, 1, C.b100) end
        if cur ~= e.MaxV then
            D.rect(cx + cw + 4, top + 3, 3, 1, C.b100)
            D.rect(cx + cw + 5, top + 2, 1, 3, C.b100)
        end
    end
    D.rect(cx, top, cw, th + 1, C.b12)
    local u, l = 50, 70
    if not en then u, l = 20, 40 elseif hov or UI.drag == e then u, l = 60, 80 end
    D.vgrad("st" .. e.id, cx + 1, top + 1, cw - 2, th - 1, gray(u), gray(l), 1)
    local fw = 0
    if range ~= 0 then fw = floor(cw / range * (cur - e.MinV)) end
    D.vgrad("sf" .. e.id, cx + 1, top + 1, min(fw, cw - 2), th - 1, T.acc, T.accS, en and 1 or 1 / 3)
    if e.ShowValue then
        local s = W.cut(e.Display, cw, true)
        D.label(cx + fw - floor((W.len(s) * CW + 1) / 2), top + th - floor(CH / 2), s, C.white, en and 187 / 255 or 80 / 255, true, false, true)
    end
end

function Library:Slider(Options, section)
    Options = Library:Validate({
        Name = "Preview Slider",
        Min = 0,
        Max = 100,
        Default = 1,
        Decimal = 1,
        UseIcons = true,
        ShowValue = true,
        Ending = "",
        Disable = {},
        Hidden = false,
        Risky = false,
        OverrideLimit = false,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local e = {
        Name = tostring(Options.Name),
        MinV = Options.Min,
        MaxV = Options.Max,
        Decimal = (Options.Decimal and Options.Decimal > 0) and Options.Decimal or 1,
        Ending = tostring(Options.Ending),
        Disable = Options.Disable,
        ValueLabels = Options.ValueLabels,
        Formatter = Options.Formatter,
        UseIcons = Options.UseIcons,
        ShowValue = Options.ShowValue,
        MaxWidth = tonumber(Options.MaxWidth),
        Risky = Options.Risky,
        OverrideLimit = Options.OverrideLimit,
        Flag = Options.Flag,
        Callback = Options.Callback,
        CurrentValue = -9999,
        Display = "",
    }
    function e:SetValue(Value, IgnoreLimit, Force)
        Value = tonumber(Value)
        if not Value then return end
        local step = self.Decimal
        Value = step * round(Value / step)
        if self.OverrideLimit and IgnoreLimit then
            Value = max(Value, self.MinV)
        else
            Value = clamp(Value, self.MinV, self.MaxV)
        end
        Value = tonumber(num14(Value))
        self.Display = W.fmtValue(self, Value)
        local changed = Value ~= self.CurrentValue
        self.CurrentValue = Value
        Library.Flags[self.Flag] = self
        if changed or Force then safecall(self.Callback, Value) end
    end
    function e:Set(v)
        if v == nil or v == false or v == true then return end
        self:SetValue(v, self.OverrideLimit, true)
    end
    function e:Get() return self.CurrentValue end
    function e:Max() return self.MaxV end
    function e:Min() return self.MinV end
    function e:GetName() return self.Name end
    function e:SetFormatter(fn)
        self.Formatter = fn
        self.Display = W.fmtValue(self, self.CurrentValue)
    end
    function e:SetValueLabels(t)
        self.ValueLabels = t
        self.Display = W.fmtValue(self, self.CurrentValue)
    end
    addElem(section, e, (e.Name ~= "") and UI.RowH.Slider or UI.RowH.SliderBare, W.slider)
    Library.Flags[e.Flag] = e
    e:SetValue(Options.Default)
    if Options.Hidden then e:SetVisible(false) end
    return e
end

function W.box(e, x, y, w, text)
    local en = e.Enabled
    local cx, cw = x + Z(20), W.cw(w)
    local rh = Z(20)
    local by = y
    if e.Name ~= "" then
        W.label(e, cx, y, W.lim(e, w))
        by = y + Z(14)
        e.popOff = e.isMulti and (rh + 1) or (Z(35) + 1 - Z(14))
        e.popFix = e.isMulti and 0 or 1
    else
        e.popOff = rh + 1
        e.popFix = 1
    end
    local open = UI.pop ~= nil and UI.pop.owner == e
    local hov = en and over(cx, by, cw, rh)
    local c1, c2, a = 31, 36, 1
    if hov or open then c1, c2 = 41, 46 elseif not en then a = 80 / 255 end
    D.vgrad("bx" .. e.id, cx + 1, by + 1, cw - 2, rh - 2, gray(c1), gray(c2), a)
    D.outline(cx, by, cw, rh, C.b12)
    local ta = en and 136 / 255 or 50 / 255
    D.text(cx + Z(7), W.mid(by, rh), W.cut(text, cw - Z(20)), C.white, ta)
    D.arrow(cx + cw - Z(12), by + floor((rh - 4) / 2), true, 1, ta)
    anchor(e, cx, by, cw, rh)
    if e.addons then W.addons(e, x, y, w) end
    if not en then
        e.held = false
        return
    end
    if I.m1p and hov and not I.used then
        I.used = true
        UI.take(e)
        e.held = true
    end
    if I.m1r and e.held and hov then
        e.held = false
        openPop(e, "list")
    end
    if not I.m1 and not I.m1r then e.held = false end
end

function POP.list(p)
    local e = p.owner
    local items = e.Content
    local n = #items
    local rh = Z(20)
    local rows = min(8, n)
    local x, w = e.ax, e.aw
    local y = e.ay + (e.popOff or (rh + 1))
    local h = rh * rows
    D.rect(x, y, w, h, C.b12)
    D.rect(x + 1, y + 1, w - 2, h - 2, C.b35)
    local sc = e.sc
    local scroll = n > 8
    local content = n * rh
    if scroll then SB.clamp(sc, h, content, 0) else sc.pos = 0 end
    local used = scroll and SB.mouse(sc, x, y, w, h, content, true)
    local off = scroll and floor(sc.pos / rh) or 0
    local fix = e.popFix or 1
    local inp = over(x, y - fix, w, h + fix)
    local hi = -1
    if inp then
        hi = floor((I.my - y + fix) / rh)
        if hi < 0 or hi >= rows then hi = -1 end
    end
    for r = 0, rows - 1 do
        local name = items[off + r + 1]
        if not name then break end
        local ry = y + r * rh
        local dead = e.Off ~= nil and e.Off[name] == true
        local hot = hi == r and not dead
        if hot then D.rect(x + 1, ry + 1, w - 2, rh - 2, C.b25) end
        local sel = e:IsSelected(name)
        local bold = (sel or (hot and not e.isMulti)) and not dead
        if dead then
            D.label(x + Z(7), W.mid(ry, rh), W.cut(name, w - Z(20), false), C.white, 50 / 255, false)
        else
            D.label(x + Z(7), W.mid(ry, rh), W.cut(name, w - Z(20), bold), sel and T.acc or C.white, sel and 1 or 200 / 255, bold)
        end
    end
    if scroll then SB.draw(sc, x, y, w, h, content, 1) end
    if not used then
        if I.m1p and inp and not I.used then
            I.used = true
            e.held = true
        end
        local name = (hi >= 0) and items[off + hi + 1] or nil
        if name and e.Off ~= nil and e.Off[name] == true then name = nil end
        if e.isMulti then
            if I.m1r and e.held then
                e.held = false
                if name then e:Pick(name) elseif inp then closePop(e) end
            end
        else
            if e.held and name and (I.m1 or I.m1r) and e.Value ~= name then e:Set(name) end
            if I.m1r and e.held then
                e.held = false
                if inp then closePop(e) end
            end
        end
    end
    return x, y, w, h
end

function Library:Dropdown(Options, section)
    Options = Library:Validate({
        Name = "Preview Dropdown",
        Content = {},
        Hiding = false,
        Risky = false,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local e = {
        Name = tostring(Options.Name),
        Risky = Options.Risky,
        Flag = Options.Flag,
        Callback = Options.Callback,
        Content = {},
        Value = "None",
        Items = {},
        sc = { pos = 0 },
    }
    function e:IsSelected(name) return self.Value == name end
    function e:SetOptionEnabled(name, state)
        self.Off = self.Off or {}
        self.Off[name] = (state == false) and true or nil
    end
    function e:Pick(name)
        closePop(self)
        self:Set(name)
    end
    function e:Set(State)
        if State == nil or type(State) == "boolean" or type(State) == "table" then return end
        State = tostring(State)
        if not self.Items[State] then return end
        self.auto = false
        if self.Value == State then return end
        self.Value = State
        Library.Flags[self.Flag] = self
        safecall(self.Callback, State)
    end
    function e:Get() return self.Value end
    function e:First()
        local first = self.Content[1]
        if first and self.Value ~= first then
            self:Set(first)
            self.auto = true
        end
    end
    function e:AddValue(Value)
        Value = tostring(Value)
        if self.Items[Value] then return end
        self.Items[Value] = true
        self.Content[#self.Content + 1] = Value
        if not self.Ready then return end
        if self.Value == "None" or not self.Items[self.Value] then
            self:First()
        elseif self.auto and Value == self.DefaultValue then
            self:Set(Value)
        end
    end
    function e:RemoveValue(Value)
        Value = tostring(Value)
        self.Items[Value] = nil
        for i = #self.Content, 1, -1 do
            if self.Content[i] == Value then table.remove(self.Content, i) end
        end
        if self.Value == Value then
            self.Value = "None"
            self:First()
        end
    end
    function e:Refresh(List)
        self.Content, self.Items = {}, {}
        self.sc.pos = 0
        local ready = self.Ready
        self.Ready = false
        for _, v in ipairs(List or {}) do self:AddValue(v) end
        self.Ready = ready
        if not self.Items[self.Value] then
            self.Value = "None"
            self:First()
        end
    end
    function e:Toggle() openPop(self, "list") end
    for _, v in ipairs(Options.Content) do e:AddValue(v) end
    attachAddons(e)
    addElem(section, e, (e.Name ~= "") and UI.RowH.Dropdown or UI.RowH.DropdownBare, function(self, x, y, w)
        W.box(self, x, y, w, (self.Value ~= "None" or self.Items["None"]) and self.Value or "")
    end)
    Library.Flags[e.Flag] = e
    e.DefaultValue = (Options.Default ~= nil) and tostring(Options.Default) or nil
    e.Ready = true
    if e.DefaultValue and e.Items[e.DefaultValue] then e:Set(e.DefaultValue) else e:First() end
    if Options.Hiding or Options.Hidden then e:SetVisible(false) end
    return e
end

function Library:MultiBox(Options, section)
    Options = Library:Validate({
        Default = {},
        Name = "Preview MultiBox",
        Content = {},
        Hiding = false,
        Risky = false,
        RequireOne = false,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local e = {
        isMulti = true,
        Name = tostring(Options.Name),
        Risky = Options.Risky,
        RequireOne = Options.RequireOne and true or false,
        Flag = Options.Flag,
        Callback = Options.Callback,
        Content = {},
        Items = {},
        Selected = {},
        Value = {},
        Text = "-",
        sc = { pos = 0 },
    }
    function e:IsSelected(name) return self.Selected[name] == true end
    function e:SetOptionEnabled(name, state)
        self.Off = self.Off or {}
        self.Off[name] = (state == false) and true or nil
    end
    function e:UpdateValue(silent)
        local out = {}
        for _, name in ipairs(self.Content) do
            if self.Selected[name] then out[#out + 1] = name end
        end
        self.Value = out
        self.Text = (#out > 0) and table.concat(out, ", ") or "-"
        Library.Flags[self.Flag] = self
        if not silent then
            local copy = {}
            for i, v in ipairs(out) do copy[i] = v end
            safecall(self.Callback, copy)
        end
    end
    function e:Pick(name)
        if not self.Items[name] then return end
        if self.Selected[name] then
            if self.RequireOne and #self.Value <= 1 then return end
            self.Selected[name] = nil
        else
            self.Selected[name] = true
        end
        self:UpdateValue()
    end
    function e:Set(Values)
        if type(Values) ~= "table" then
            if Values == false then
                self.Selected = {}
                self:UpdateValue()
            end
            return
        end
        self.Selected = {}
        for _, name in ipairs(Values) do
            name = tostring(name)
            if self.Items[name] then self.Selected[name] = true end
        end
        self:UpdateValue()
    end
    function e:Get()
        local copy = {}
        for i, v in ipairs(self.Value) do copy[i] = v end
        return copy
    end
    function e:AddValue(Value)
        Value = tostring(Value)
        if self.Items[Value] then return end
        self.Items[Value] = true
        self.Content[#self.Content + 1] = Value
    end
    function e:RemoveValue(Value)
        self.Items[Value] = nil
        self.Selected[Value] = nil
        for i = #self.Content, 1, -1 do
            if self.Content[i] == Value then table.remove(self.Content, i) end
        end
        self:UpdateValue(true)
    end
    function e:Toggle() openPop(self, "list") end
    for _, v in ipairs(Options.Content) do e:AddValue(v) end
    attachAddons(e)
    addElem(section, e, (e.Name ~= "") and UI.RowH.Dropdown or UI.RowH.DropdownBare, function(self, x, y, w)
        W.box(self, x, y, w, self.Text)
    end)
    Library.Flags[e.Flag] = e
    if type(Options.Default) == "table" then
        for _, name in ipairs(Options.Default) do
            name = tostring(name)
            if e.Items[name] then e.Selected[name] = true end
        end
    end
    e:UpdateValue()
    if Options.Hiding or Options.Hidden then e:SetVisible(false) end
    return e
end

function W.textbox(e, x, y, w)
    local cx, cw = x + Z(20), W.cw(w)
    local h = Z(20)
    anchor(e, cx, y, cw, h)
    D.rect(cx, y, cw, h, C.b12)
    if not e.Enabled then
        D.rect(cx + 1, y + 1, cw - 2, h - 2, C.b35, 80 / 255)
        if UI.focus == e then W.blur(e, false) end
        return
    end
    D.rect(cx + 1, y + 1, cw - 2, h - 2, C.b50)
    D.rect(cx + 2, y + 2, cw - 4, h - 4, gray(16))
    D.rect(cx + 3, y + 3, cw - 6, h - 6, C.b25)
    local focused = UI.focus == e
    local hov = over(cx, y, cw, h)
    if I.m1p and hov and not I.used then
        I.used = true
        if not focused then
            UI.take(e)
            UI.focus = e
            e.Focused = true
            focused = true
            if e.ClearOnFocus then e.Text = "" end
            K.typed(true)
        end
    elseif focused and I.m1p then
        W.blur(e, false)
        focused = false
    end
    if focused then
        local keys = K.typed(false)
        local ctrl = K.down(0x11) or K.down(0xA2) or K.down(0xA3)
        local changed = false
        for i = 1, #keys do
            local k = keys[i]
            if k == "\8" then
                if #e.Text > 0 then
                    e.Text = ctrl and "" or sub(e.Text, 1, #e.Text - 1)
                    changed = true
                end
            elseif k == "\r" then
                W.blur(e, true)
                focused = false
                break
            elseif k == "\27" then
                W.blur(e, false)
                focused = false
                break
            elseif k ~= "`" and #e.Text < e.MaxLen then
                if not e.NumbersOnly or string.match(k, "[%d%.%-]") then
                    e.Text = e.Text .. k
                    changed = true
                end
            end
        end
        if changed then
            if e.OnTyped then safecall(e.OnTyped, e.Text) end
            if e.TypedCheck then
                Library.Flags[e.Flag] = e
                safecall(e.Callback, e.Text)
            end
        end
    end
    D.text(cx + 5, W.mid(y, h), W.cut(e.Text .. "_", cw - 10), focused and T.acc or T.text)
end

local function newTextBox(Options)
    Options = Library:Validate({
        Default = "",
        Name = "Preview TextBox",
        Max = 63,
        NumbersOnly = false,
        ClearOnFocus = false,
        Hidden = false,
        TypedCheck = false,
        CheckIfPressedEnter = false,
        Risky = false,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local e = {
        Name = Options.Name,
        Text = tostring(Options.Default or ""),
        MaxLen = tonumber(Options.Max) or 63,
        NumbersOnly = Options.NumbersOnly,
        ClearOnFocus = Options.ClearOnFocus,
        TypedCheck = Options.TypedCheck,
        CheckIfPressedEnter = Options.CheckIfPressedEnter,
        Flag = Options.Flag,
        Callback = Options.Callback,
        Focused = false,
    }
    function e:Get() return self.Text end
    function e:Set(v)
        if type(v) ~= "string" and type(v) ~= "number" then return end
        self.Text = sub(tostring(v), 1, self.MaxLen)
        Library.Flags[self.Flag] = self
        safecall(self.Callback, self.Text)
    end
    return e, Options
end

function Library:TextBox(Options, section)
    local e, opts = newTextBox(Options)
    e.isTextBox = true
    addElem(section, e, UI.RowH.TextBox, W.textbox)
    Library.Flags[e.Flag] = e
    if opts.Hidden then e:SetVisible(false) end
    return e
end

local function udimOffsets(v, dx, dy)
    if v == nil then return dx, dy end
    if type(v) == "table" then
        return tonumber(v[1] or v.X or v.x) or dx, tonumber(v[2] or v.Y or v.y) or dy
    end
    local ok, a, b = pcall(function() return v.X.Offset, v.Y.Offset end)
    if ok and type(a) == "number" and type(b) == "number" then return a, b end
    return dx, dy
end

function W.listPick(e, it, always)
    if not it then return end
    if e.CurrentValue == it and not always then return end
    e.CurrentValue = it
    e.CurrentValueName = it.Name
    Library.Flags[e.Flag] = e
    safecall(e.Callback, it.Name)
end

function W.listKeys(e, f, count, vis, rh, vh, content, scroll)
    local sc = e.sc
    local pos = 0
    for i = 1, count do
        if f[i] == e.CurrentValue then pos = i break end
    end
    if K.rep(0x26) and pos > 1 then
        W.listPick(e, f[pos - 1], true)
        if scroll and (pos - 2) * rh < floor(sc.pos / rh) * rh then sc.pos = (pos - 2) * rh end
    end
    if K.rep(0x28) and pos < count then
        W.listPick(e, f[pos + 1], true)
        if scroll and pos >= floor(sc.pos / rh) + vis then
            sc.pos = (pos - vis + 1) * rh
            SB.clamp(sc, vh, content, 0)
        end
    end
    local pu, pd = K.rep(0x21), K.rep(0x22)
    if scroll and count >= vis then
        if pu then SB.clamp(sc, vh, content, (1 - vis) * rh) end
        if pd then SB.clamp(sc, vh, content, (vis - 1) * rh) end
    end
    if e.ShowSearch and e.searchActive then
        local keys = K.typed(false)
        local sr = e.Search
        for i = 1, #keys do
            local k = keys[i]
            if k == "\8" then
                if #sr.Text > 0 then sr.Text = sub(sr.Text, 1, #sr.Text - 1) end
            elseif k == "`" then
                e.searchActive = false
                break
            elseif k ~= "\r" and k ~= "\27" and #sr.Text < 16 then
                sr.Text = sr.Text .. k
            end
        end
    end
end

function W.list(e, x, y, w)
    local en = e.Enabled
    local cx, cw = x + Z(20), W.cw(w)
    local h, rh = Z(e.h), Z(18)
    local a = en and 1 or 80 / 255
    local search = e.ShowSearch
    local focused = UI.kf == e
    if not focused then e.searchActive = false end
    D.outline(cx, y, cw, h, C.b12)
    D.rect(cx + 1, y + 1, cw - 2, h - 2, C.b35, a)
    anchor(e, cx, y, cw, h)
    local py = y
    if search then
        D.outline(cx + 1, y + 1, cw - 2, rh, C.b50, a)
        D.outline(cx + 2, y + 2, cw - 4, rh - 2, gray(16), a)
        D.rect(cx + 3, y + 3, cw - 6, rh - 4, C.b25, a)
        local act = e.searchActive
        D.text(cx + 5, W.mid(y, rh), W.cut(e.Search.Text .. "_", cw), act and T.acc or C.white, (act and 1 or 200 / 255) * a)
        py = y + rh
    end
    local q = search and string.lower(e.Search.Text) or ""
    if e.fq ~= q or e.fdirty then
        local f = {}
        for _, it in ipairs(e.Items) do
            if q == "" or string.find(string.lower(it.Name), q, 1, true) then f[#f + 1] = it end
        end
        if e.fq ~= q then e.sc.pos = 0 end
        e.filtered, e.fq, e.fdirty = f, q, false
    end
    local f = e.filtered
    local count = #f
    local vis = floor(h / rh) - (search and 1 or 0)
    local vh = search and (h - rh) or h
    local scroll = vis < count
    local content = (count + 1) * rh
    local sc = e.sc
    if scroll then SB.clamp(sc, vh, content, 0) end
    local hov = en and over(cx, y, cw, h)
    local used = scroll and en and SB.mouse(sc, cx, py, cw, vh, content, hov)
    if not used and hov and I.m1p and not I.used then
        I.used = true
        UI.take(e)
        focused = true
        local rel = I.my - py
        if rel < 0 then
            if not e.searchActive then K.typed(true) end
            e.searchActive = true
        else
            local base = scroll and floor(sc.pos / rh) * rh or 0
            W.listPick(e, f[floor((base + rel) / rh) + 1], true)
        end
    end
    if focused and en and #e.Items > 0 then W.listKeys(e, f, count, vis, rh, vh, content, scroll) end
    local off = scroll and floor(sc.pos / rh) or 0
    for r = 0, vis - 1 do
        local it = f[off + r + 1]
        if not it then break end
        local ry = py + r * rh
        local sel = e.CurrentValue == it
        if sel then D.rect(cx + 1, ry + 1, cw - 2, rh - 2, gray(26)) end
        local tx = cx + 10
        if it.Icon and it.Icon.Image then
            local ic = it.Icon
            if not ic.px then
                ic.px, ic.py = udimOffsets(ic.Position, 7, 0)
                ic.sw, ic.sh = udimOffsets(ic.Size, 13, 13)
                ic.tint = ic.Color and pk(ic.Color) or C.white
            end
            local iy = ry + floor(rh / 2) - floor(ic.sh / 2) + ic.py
            local ok = D.image("list" .. e.id .. "_" .. r, ic.Image, cx + 1 + ic.px, iy, ic.sw, ic.sh, ic.tint, a)
            if not ok and ic.Color then D.rect(cx + 1 + ic.px, iy, ic.sw, ic.sh, ic.tint, a) end
            tx = cx + 26
        end
        local acc = it.Marked or (e.Bound and sel)
        D.label(tx, W.mid(ry, rh), W.cut(it.Name, cw - 20 - (tx - cx - 10), sel), acc and T.acc or C.white, (acc and 1 or 200 / 255) * a, sel)
    end
    if scroll then
        local pixels = off * rh
        if pixels > 0 then D.arrow(cx + cw - 20, py + 8, false, a) end
        if vis + pixels < count then D.arrow(cx + cw - 20, y + h - 9, true, a) end
        SB.draw(sc, cx, py, cw, vh, content, a)
    end
end

function Library:List(Options, section)
    Options = Library:Validate({
        Size = 100,
        Hidden = false,
        Search = false,
        Bound = true,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local e = {
        id = nextId(),
        isList = true,
        Flag = Options.Flag,
        Callback = Options.Callback,
        ShowSearch = Options.Search and true or false,
        Bound = Options.Bound and true or false,
        Items = {},
        filtered = {},
        fdirty = true,
        sc = { pos = 0 },
        Search = { Text = "" },
        CurrentValue = nil,
        CurrentValueName = nil,
    }
    function e:Get() return self.CurrentValueName end
    function e:Find(name)
        for _, it in ipairs(self.Items) do
            if it.Name == name then return it end
        end
        return nil
    end
    function e:Select(name)
        if type(name) ~= "string" then
            if not name then self.CurrentValue, self.CurrentValueName = nil, nil end
            return
        end
        W.listPick(self, self:Find(name), false)
    end
    function e:SetMarked(name, state)
        if name == nil then
            for _, it in ipairs(self.Items) do it.Marked = false end
            return
        end
        local it = self:Find(tostring(name))
        if it then it.Marked = (state ~= false) end
    end
    function e:IsMarked(name)
        local it = self:Find(tostring(name))
        return it ~= nil and it.Marked == true
    end
    function e:SetSearch(state) self.ShowSearch = state and true or false end
    function e:AddValue(Value, Icon)
        Value = tostring(Value)
        local it = self:Find(Value)
        if it then
            if Icon then it.Icon = Icon end
            return
        end
        self.Items[#self.Items + 1] = { Name = Value, Icon = Icon }
        self.fdirty = true
    end
    function e:RemoveValue(Value)
        for i = #self.Items, 1, -1 do
            if self.Items[i].Name == Value then
                if self.CurrentValue == self.Items[i] then self.CurrentValue, self.CurrentValueName = nil, nil end
                table.remove(self.Items, i)
            end
        end
        self.fdirty = true
    end
    function e:Clear()
        self.Items = {}
        self.CurrentValue, self.CurrentValueName = nil, nil
        self.fdirty = true
        self.sc.pos = 0
    end
    function e:GetValues()
        local out = {}
        for i, it in ipairs(self.Items) do out[i] = it.Name end
        return out
    end
    function e:UpdateSection() end
    addElem(section, e, max(36, tonumber(Options.Size) or 100) + UI.RowH.List, W.list)
    Library.Flags[e.Flag] = e
    if Options.Hidden then e:SetVisible(false) end
    return e
end

function W.button(e, x, y, w)
    local en = e.Enabled
    local cx, cw = x + Z(20), W.cw(w)
    local h = Z(28) - 3
    local hov = en and over(cx, y, cw, Z(28))
    if UI.held == e and not hov then UI.held = nil end
    if e.Waiting and now() > e.ConfirmUntil then e.Waiting = false end
    if W.tap(e, hov) then
        if e.Confirmation and not e.Waiting then
            e.Waiting = true
            e.ConfirmUntil = now() + 3
        else
            e.Waiting = false
            safecall(e.Callback)
        end
    end
    local t, b = 34, 30
    if UI.held == e then t, b = 30, 20 elseif hov then t, b = 39, 35 end
    D.rect(cx, y, cw, h, C.b12)
    D.rect(cx + 1, y + 1, cw - 2, h - 2, C.b50)
    D.vgrad("bt" .. e.id, cx + 2, y + 2, cw - 4, h - 4, gray(t), gray(b), 1)
    local s = W.cut(e.Waiting and "Are you sure?" or e.Name, cw - 6)
    local col, a = C.white, 200 / 255
    if not en then col, a = C.b60, 1 elseif e.Risky then col, a = T.risky, 187 / 255 end
    D.label(cx + floor(cw / 2) - floor(#s * CW / 2), y + floor(h / 2) - floor(CH / 2), s, col, a, false, true)
end

function Library:Button(Options, section)
    Options = Library:Validate({
        Name = "Preview Button",
        Confirmation = false,
        Hidden = false,
        Risky = false,
        Callback = function() end,
    }, Options)
    local e = {
        Name = tostring(Options.Name),
        Confirmation = Options.Confirmation,
        Risky = Options.Risky,
        Callback = Options.Callback,
        Waiting = false,
        ConfirmUntil = 0,
    }
    function e:ConfirmationStart()
        self.Waiting = true
        self.ConfirmUntil = now() + 3
    end
    function e:SetName(s) self.Name = tostring(s) end
    function e:UpdateSize() end
    function e:UpdatePosition() end
    addElem(section, e, UI.RowH.Button, W.button)
    if Options.Hidden then e:SetVisible(false) end
    return e
end

function W.gEls(sel)
    local out = {}
    local list = sel.sections
    if not list then return out end
    for _, s in ipairs(list) do
        for _, e in ipairs(s.items) do
            if e.Flag and e.Set and e.Get and not e.NoGroup then out[#out + 1] = e end
            if e.addons and not e.NoGroup then
                for _, a in ipairs(e.addons) do out[#out + 1] = a end
            end
        end
    end
    return out
end

function W.gPack(o)
    if o.isKeybind then return { o.Key or false, o.Mode } end
    if o.isPicker then return { o.Hue, o.Saturation[1], o.Saturation[2], o.Alpha } end
    return W.copy(o:Get())
end

function W.gApply(o, v)
    if v == nil then return end
    if o.isKeybind then
        if type(v) ~= "table" then return end
        o:Set(v[1] or "None")
        if v[2] then o:SetMode(v[2]) end
        return
    end
    o:Set(W.copy(v))
end

function W.gSnap(sel)
    local t = {}
    for _, o in ipairs(W.gEls(sel)) do t[o.Flag] = W.gPack(o) end
    return t
end

function W.gBase(sel)
    local base = sel.base
    if not base then
        base = {}
        sel.base = base
    end
    for _, o in ipairs(W.gEls(sel)) do
        if base[o.Flag] == nil then base[o.Flag] = W.gPack(o) end
    end
    return base
end

function W.gLoad(sel, set)
    local base = W.gBase(sel)
    for _, o in ipairs(W.gEls(sel)) do
        local v
        if type(set) == "table" then v = set[o.Flag] end
        if v == nil then v = base[o.Flag] end
        local ok, err = pcall(W.gApply, o, v)
        if not ok then report(err, "group value") end
    end
end

function W.gSwitch(sel, name, force)
    local prev = sel.lastGroup
    if prev == name and not force then return end
    sel.lastGroup = name
    if not sel.sections then return end
    W.gBase(sel)
    if prev ~= nil and prev ~= name then sel.sets[prev] = W.gSnap(sel) end
    W.gLoad(sel, sel.sets[name])
end

function W.gCopy(sel, name)
    local set
    if name == sel.lastGroup then
        set = W.gSnap(sel)
    else
        set = W.copy(sel.sets[name] or W.gBase(sel))
    end
    Library.UI.GroupClipboard = set
    Library:SetClipboard(Json.encode(set))
    return set
end

function W.gPaste(sel, name)
    local set = Library.UI.GroupClipboard
    if type(set) ~= "table" then return false end
    set = W.copy(set)
    sel.sets[name] = set
    if name == sel.lastGroup then W.gLoad(sel, set) end
    return true
end

function Sections:BindGroups(Selector)
    if type(Selector) ~= "table" or not Selector.sets then return self end
    Selector.sections = Selector.sections or {}
    for _, s in ipairs(Selector.sections) do
        if s == self then return self end
    end
    Selector.sections[#Selector.sections + 1] = self
    self.groupSel = Selector
    return self
end

function Sections:Toggle(Options) return Library:Toggle(Options or {}, self) end
function Sections:Slider(Options) return Library:Slider(Options or {}, self) end
function Sections:Dropdown(Options) return Library:Dropdown(Options or {}, self) end
function Sections:MultiBox(Options) return Library:MultiBox(Options or {}, self) end
function Sections:Label(Options) return Library:Label(Options or {}, self) end
function Sections:TextBox(Options) return Library:TextBox(Options or {}, self) end
function Sections:List(Options) return Library:List(Options or {}, self) end
function Sections:Button(Options) return Library:Button(Options or {}, self) end

local Grid = { res = {} }

function Grid.f32(x)
    local frexp, ldexp = math.frexp, math.ldexp
    if x == 0 or not frexp or not ldexp then return x end
    local m, e = frexp(x)
    return ldexp(floor(m * 16777216 + 0.5) / 16777216, e)
end

function Grid.place(it, res, left, top, right, bottom, m)
    local f32 = Grid.f32
    local at = (res[it.col] or 0) + top
    local width, height = right - left, bottom - at
    local bh
    if it.rspan == -1 then
        bh = Z(it.fixed or 50) + m * 2
        for c = it.col, min(23, it.col + it.cspan - 1) do res[c] = bh end
    else
        bh = floor(f32(f32(it.rspan / 24) * height))
    end
    local bw = floor(f32(f32(it.cspan / 24) * width))
    local bx = floor(f32(f32(it.col * f32(width / 24)) + left)) + m
    local by = floor(f32(f32(f32(height / 24) * it.row) + at)) + m
    bw, bh = bw - m * 2, bh - m * 2
    if it.cspan + it.col >= 24 and bw + bx ~= right - m then bw = right - m - bx end
    if it.rspan + it.row >= 24 and bh + by ~= bottom - m then bh = bottom - m - by end
    it.bx, it.by, it.bw, it.bh = bx, by, bw, bh
end

function Grid.auto(page, win)
    if not page.dirty then return end
    page.dirty = false
    local reserved = { 0, 0 }
    local function reserve(p)
        local r = (p.fixed or 50) + 20
        if p.col < 12 then reserved[1] = r end
        if p.col + p.cspan > 12 then reserved[2] = r end
    end
    for _, p in ipairs(page.pre) do reserve(p) end
    for _, s in ipairs(page.list) do
        if s.rspan == -1 and not s.auto then reserve(s) end
    end
    for side = 1, 2 do
        local unit = ((win.baseH or 560) - 36 - reserved[side]) / 24
        if unit < 1 then unit = 1 end
        local list, fixed, fills = {}, 0, 0
        for _, s in ipairs(page.list) do
            if s.auto and s.side == side then
                list[#list + 1] = s
                if s.fill then
                    fills = fills + 1
                else
                    s.arows = clamp(round((max(50, s.size) + 20) / unit), 2, 24)
                    fixed = fixed + s.arows
                end
            end
        end
        local room = 24 - fills * 2
        while fixed > room do
            local big
            for _, s in ipairs(list) do
                if not s.fill and s.arows > 2 and (not big or s.arows > big.arows) then big = s end
            end
            if not big then break end
            big.arows = big.arows - 1
            fixed = fixed - 1
        end
        local free = max(0, 24 - fixed)
        local each = (fills > 0) and max(2, floor(free / fills)) or 0
        local row, seen = 0, 0
        for _, s in ipairs(list) do
            local rows = s.arows
            if s.fill then
                seen = seen + 1
                rows = each
                if seen == fills then rows = max(2, free - each * (fills - 1)) end
            end
            if row > 22 then row = 22 end
            if row + rows > 24 then rows = 24 - row end
            local def = s.def
            def[1], def[2], def[3], def[4] = (side - 1) * 12, 12, row, rows
            if not s.custom then s.col, s.cspan, s.row, s.rspan = def[1], def[2], def[3], def[4] end
            row = row + rows
        end
    end
end

function Grid.layout(win, page)
    Grid.auto(page, win)
    local tpad, m = Z(10), Z(10)
    local left, top = Z(75) + tpad + 7, 10 + tpad
    local right, bottom = win.w - (7 + tpad), win.h - (6 + tpad)
    local res = Grid.res
    for c = 0, 23 do res[c] = 0 end
    for _, p in ipairs(page.pre) do Grid.place(p, res, left, top, right, bottom, m) end
    for _, s in ipairs(page.list) do Grid.place(s, res, left, top, right, bottom, m) end
end

function Grid.move(s, win, page)
    local dx, dy = I.mx - s.ox, I.my - s.oy
    local nc, nr = s.col, s.row
    if abs(dx) >= floor((win.w - 105) / 24) then
        nc = s.col + ((dx > 0) and 1 or -1)
        if nc < 0 then nc = 0 elseif nc > 24 - s.cspan then nc = 24 - s.cspan end
    end
    if abs(dy) >= floor((win.h - 35) / 24) then
        nr = s.row + ((dy > 0) and 1 or -1)
        if nr < 0 then nr = 0 elseif nr > 24 - s.rspan then nr = 24 - s.rspan end
    end
    if nc == s.col and nr == s.row then return end
    local hit
    for _, o in ipairs(page.list) do
        if o ~= s and max(nc, o.col) < min(nc + s.cspan, o.col + o.cspan)
            and max(nr, o.row) < min(nr + s.rspan, o.row + o.rspan) then
            hit = o
            break
        end
    end
    if hit then
        s.col, hit.col = hit.col, s.col
        s.cspan, hit.cspan = hit.cspan, s.cspan
        s.row, hit.row = hit.row, s.row
        s.rspan, hit.rspan = hit.rspan, s.rspan
        hit.custom = true
    else
        s.col, s.row = nc, nr
    end
    s.custom = true
    s.ox, s.oy = I.mx, I.my
end

function Grid.resize(s, win)
    local dx, dy = I.mx - s.ox, I.my - s.oy
    if abs(dx) >= floor((win.w - 105) / 24) then
        local n = s.cspan + ((dx > 0) and 1 or -1)
        if n < 3 then n = 3 elseif n > 24 - s.col then n = 24 - s.col end
        if n ~= s.cspan then
            s.cspan = n
            s.ox = I.mx
            s.custom = true
        end
    end
    if abs(dy) >= floor((win.h - 35) / 24) then
        local n = s.rspan + ((dy > 0) and 1 or -1)
        if n < 2 then n = 2 elseif n > 24 - s.row then n = 24 - s.row end
        if n ~= s.rspan then
            s.rspan = n
            s.oy = I.my
            s.custom = true
        end
    end
end

function Grid.pages(tab)
    local out = { tab.page }
    if tab.Sub then
        for _, item in ipairs(tab.Sub.Items) do out[#out + 1] = item.page end
    end
    return out
end

function Grid.each(fn)
    for _, win in ipairs(Library.Windows) do
        for _, tab in ipairs(win.Tabs) do
            for _, page in ipairs(Grid.pages(tab)) do
                Grid.auto(page, win)
                for _, s in ipairs(page.list) do fn(s, page, win) end
            end
        end
    end
end

function Grid.valid(c, cs, r, rs)
    c, cs, r, rs = tonumber(c), tonumber(cs), tonumber(r), tonumber(rs)
    if not (c and cs and r and rs) then return nil end
    c, cs, r, rs = floor(c), floor(cs), floor(r), floor(rs)
    if c < 0 or c > 23 or r < 0 or r > 23 then return nil end
    if cs < 1 or c + cs > 24 then return nil end
    if rs ~= -1 and (rs < 1 or r + rs > 24) then return nil end
    return c, cs, r, rs
end

function Library:GetLayout()
    local out = { windows = {}, boxes = {} }
    for i, win in ipairs(Library.Windows) do
        out.windows[i] = { round(win.w / UI.sc), round(win.h / UI.sc) }
    end
    Grid.each(function(s)
        out.boxes[s.key] = { s.col, s.cspan, s.row, s.rspan }
    end)
    return out
end

function Library:SetLayout(Layout)
    if type(Layout) ~= "table" then return false end
    if type(Layout.windows) == "table" then
        for i, win in ipairs(Library.Windows) do
            local sz = Layout.windows[i]
            if type(sz) == "table" and tonumber(sz[1]) and tonumber(sz[2]) then
                win.w = clamp(Z(tonumber(sz[1])), Z(win.minW), max(Z(win.minW), win.maxW))
                win.h = clamp(Z(tonumber(sz[2])), Z(win.minH), max(Z(win.minH), win.maxH))
            end
        end
    end
    if type(Layout.boxes) == "table" then
        Grid.each(function(s)
            local g = Layout.boxes[s.key]
            if type(g) == "table" and s.rspan ~= -1 then
                local c, cs, r, rs = Grid.valid(g[1], g[2], g[3], g[4])
                if c and rs ~= -1 then
                    s.col, s.cspan, s.row, s.rspan = c, cs, r, rs
                    s.custom = true
                end
            end
        end)
    end
    return true
end

function Library:ResetLayout()
    if UI.drag and (UI.dragPart == "grip" or UI.dragPart == "move") then UI.drag = nil end
    Grid.each(function(s, page)
        local def = s.def
        s.col, s.cspan, s.row, s.rspan = def[1], def[2], def[3], def[4]
        s.custom = false
        page.dirty = true
    end)
end

function Library:SetLayoutLocked(State)
    Library.UI.LockLayout = State and true or false
    if Library.UI.LockLayout and UI.drag and (UI.dragPart == "grip" or UI.dragPart == "move" or UI.dragPart == "size") then
        UI.drag = nil
        Library.UI.Resizing = false
    end
end

function Library:GetScale()
    return UI.sc
end

function Library:SetScale(Scale)
    Scale = tonumber(Scale) or 1
    if Scale > 3 then Scale = Scale / 100 end
    local best = 1
    for _, v in ipairs({ 1, 1.25, 1.5, 1.75, 2 }) do
        if abs(v - Scale) < abs(best - Scale) then best = v end
    end
    if best == UI.sc then return best end
    UI.sc = best
    Library.UI.Scale = best
    CH = round(13 * best)
    CW = round(7 * best)
    Library.UI.FontSize = CH
    closePop()
    UI.drag = nil
    for _, win in ipairs(Library.Windows) do
        win.w, win.h = Z(win.baseW), Z(win.baseH)
    end
    return best
end

local function sectionContentHeight(s)
    local sum = Z(UI.RowH.First)
    for _, e in ipairs(s.items) do
        if e.shown and e.h > 0 then sum = sum + Z(e.h) + UI.RowH.Gap end
    end
    return sum + Z(UI.RowH.First)
end

local function drawSection(s, win, page)
    local sx, sy, Wd, S = win.x + s.bx, win.y + s.by, s.bw, s.bh
    if Wd < 24 or S < 8 then return end
    local resizing = UI.drag == s and UI.dragPart == "grip"
    local moving = UI.drag == s and UI.dragPart == "move"
    local border = resizing and T.acc or C.b40
    local titled = s.showTitle and s.Name ~= ""

    local items = s.items
    local count = #items
    local pad, gap = Z(UI.RowH.First), UI.RowH.Gap
    local total = pad
    for i = 1, count do
        local e = items[i]
        if e.shown and e.h > 0 then total = total + Z(e.h) + gap end
    end
    local scrolling = count >= 2 and total > S - 5
    local content = pad + total
    local maxScroll = scrolling and max(0, content - S) or 0
    s.scroll = clamp(s.scroll or 0, 0, maxScroll)
    s.maxScroll = maxScroll

    if titled then
        local name = W.cut(s.Name, Wd - 40, true)
        local nw = tw(name) + 1
        D.rect(sx + 2, sy + 2, Wd - 3, S - 3, C.b23)
        D.rect(sx, sy, 10, 1, C.b12)
        D.rect(sx + 1, sy + 1, 9, 1, border)
        D.rect(sx + 17 + nw, sy, Wd - nw - 16, 1, C.b12)
        D.rect(sx + 17 + nw, sy + 1, Wd - nw - 16, 1, border)
        D.rect(sx, sy, 1, S, C.b12)
        D.rect(sx + 1, sy + 1, 1, S, border)
        D.rect(sx + Wd, sy, 1, S, C.b12)
        D.rect(sx + Wd - 1, sy + 1, 1, S, border)
        D.rect(sx, sy + S, Wd + 1, 1, C.b12)
        D.rect(sx + 1, sy + S - 1, Wd - 1, 1, border)
        if moving then
            D.label(sx + 14, sy - floor(CH / 2), name, T.acc, 1, true, true)
        else
            D.label(sx + 14, sy - floor(CH / 2), name, C.white, 200 / 255, true, true)
        end
        if not scrolling and s.resizable then
            local qx, qy = sx + Wd - 1, sy + S - 1
            D.tri(qx - 5, qy, qx, qy - 5, qx, qy, border)
        end
    else
        D.outline(sx, sy, Wd, S, C.b12)
        D.outline(sx + 1, sy + 1, Wd - 2, S - 2, border)
        D.rect(sx + 2, sy + 2, Wd - 4, S - 4, C.b23)
    end

    local c0, c1 = UI.clip0, UI.clip1
    local lo, hi = sy, sy + S
    if scrolling then
        UI.clip0, UI.clip1 = sy + 20, sy + S - 9
        lo, hi = sy + 7, sy + S - 2
    else
        UI.clip0, UI.clip1 = sy, sy + S + 1
    end
    local rx, rw = sx + pad, Wd - pad * 2
    local cy = sy + pad - s.scroll
    for i = 1, count do
        local e = items[i]
        if e.shown then
            local eh = Z(e.h)
            if cy >= lo and cy + eh <= hi then
                e:draw(rx, cy, rw)
            end
            if eh > 0 then cy = cy + eh + gap end
        end
    end
    UI.clip0, UI.clip1 = c0, c1

    if moving then
        if I.m1 and not Library.UI.LockLayout then Grid.move(s, win, page) else UI.drag = nil end
    elseif resizing then
        if I.m1 and not Library.UI.LockLayout then
            Grid.resize(s, win)
            Library.UI.Resizing = true
        else
            UI.drag = nil
            Library.UI.Resizing = false
        end
    elseif I.m1p and not I.used and not Library.UI.LockLayout and over(sx, sy, Wd, S) then
        local lx, ly = I.mx - sx, I.my - sy
        local g = 15 * UI.sc
        if s.resizable and lx > Wd - floor(g) and ly > S - floor(g) then
            I.used = true
            UI.take(s)
            UI.drag, UI.dragPart = s, "grip"
            s.ox, s.oy = I.mx, I.my
        elseif s.movable and ly < g then
            I.used = true
            UI.take(s)
            UI.drag, UI.dragPart = s, "move"
            s.ox, s.oy = I.mx, I.my
        end
    end

    if not scrolling then return end

    local th = max(20, floor(S * S / content))
    local travel = S - th - 4
    local ty = 2
    if travel >= 0 and maxScroll > 0 then ty = floor(s.scroll * travel / maxScroll) + 2 end
    local hw = Z(14)
    if UI.drag == s and UI.dragPart == "scroll" then
        if I.m1 then
            local yy = (I.my - sy) - (s.grab or 0)
            if yy < 1 then
                s.scroll = 0
            elseif th + 1 + yy > S then
                s.scroll = maxScroll
            elseif S > th then
                s.scroll = clamp(floor(maxScroll * (yy - 1) / (S - th)), 0, maxScroll)
            end
        else
            UI.drag = nil
        end
    elseif I.m1p and not I.used and over(sx, sy, Wd + 1, S) then
        local lx, ly = I.mx - sx, I.my - sy
        if lx >= Wd - hw and lx < Wd - 2 and ly >= ty and ly < ty + th then
            I.used = true
            UI.take(s)
            UI.drag, UI.dragPart = s, "scroll"
            s.grab = ly - ty
        elseif lx >= Wd - hw - 1 and lx < Wd - 1 and ly >= 1 and ly < S - 1 then
            I.used = true
            UI.take(s)
            s.scroll = clamp(s.scroll + ((ly < ty) and (1 - S) or (S - 1)), 0, maxScroll)
        end
    end
    local pu, pd = K.down(0x21), K.down(0x22)
    if over(sx, sy, Wd, S) and not (UI.kf and UI.kf.isList) then
        if pu and not s.pgu then s.scroll = max(0, s.scroll - Z(80)) end
        if pd and not s.pgd then s.scroll = min(maxScroll, s.scroll + Z(80)) end
    end
    s.pgu, s.pgd = pu, pd
    s.scrollTarget = s.scroll

    if s.scroll > 0 then
        if not D.image("fadeT" .. s.id, "gen:fadetop", sx + 2, sy + 7, Wd - 9, 20) then
            for i = 0, 19 do D.rect(sx + 2, sy + 7 + i, Wd - 9, 1, C.b23, 1 - (i + 0.5) / 20) end
        end
        D.arrow(sx + Wd - Z(17), sy + Z(9), false)
    end
    if s.scroll < maxScroll then
        if not D.image("fadeB" .. s.id, "gen:fadebot", sx + 2, sy + S - 21, Wd - 9, 20) then
            for i = 0, 19 do D.rect(sx + 2, sy + S - 21 + i, Wd - 9, 1, C.b23, (i + 0.5) / 20) end
        end
        D.arrow(sx + Wd - Z(17), sy + S - Z(9), true)
    end
    local tw7 = Z(7)
    if travel >= 0 and maxScroll > 0 then ty = floor(s.scroll * travel / maxScroll) + 2 end
    D.rect(sx + Wd - tw7, sy + 1, tw7, S - 2, C.b40)
    D.rect(sx + 1 + Wd - tw7, sy + ty, tw7 - 2, th, C.b65)
end

local function newSection(tab, Options, page, lists)
    Options = Library:Validate({
        Name = "Preview Section",
        Side = "Left",
        Fill = false,
        Size = 40,
    }, Options)
    local side = (tostring(Options.Side) == "Right") and "Right" or "Left"
    tab.secN = (tab.secN or 0) + 1
    local s = setmetatable({
        id = nextId(),
        Name = tostring(Options.Name),
        Side = side,
        side = (side == "Right") and 2 or 1,
        fill = Options.Fill and true or false,
        size = (type(Options.Size) == "number") and Options.Size or 40,
        items = {},
        scroll = 0,
        scrollTarget = 0,
        maxScroll = 0,
        tab = tab,
        page = page,
        Visible = true,
        auto = true,
        custom = false,
        col = (side == "Right") and 12 or 0, cspan = 12, row = 0, rspan = 24,
        def = { (side == "Right") and 12 or 0, 12, 0, 24 },
        movable = Options.Movable ~= false,
        resizable = Options.Resizable ~= false,
        showTitle = Options.ShowTitle ~= false,
        key = tostring(tab.Window.index or 1) .. ":" .. tostring(tab.Index) .. ":" .. tostring(tab.secN),
    }, Sections)
    local g = Options.Grid
    if type(g) == "table" then
        local c, cs, r, rs = Grid.valid(
            g[1] or g.Column or g.column or 0, g[2] or g.ColumnSpan or g.columnSpan or 12,
            g[3] or g.Row or g.row or 0, g[4] or g.RowSpan or g.rowSpan or 24)
        if c then
            s.auto = false
            s.col, s.cspan, s.row, s.rspan = c, cs, r, rs
            s.def = { c, cs, r, rs }
            s.side = (c >= 12) and 2 or 1
            s.Side = (c >= 12) and "Right" or "Left"
            if rs == -1 then
                s.fixed = tonumber(Options.Height) or 50
                s.movable, s.resizable = false, false
            end
        end
    end
    s.Elements = { Name = s.Name, ContentHolder = s }
    page.list[#page.list + 1] = s
    page.dirty = true
    if lists then
        s.list = lists[s.Side]
        s.list[#s.list + 1] = s
    end
    function s:UpdateSection() end
    function s:SetName(n) self.Name = tostring(n) end
    function s:SetVisible(b) self.Visible = b and true or false end
    function s:GetGrid() return self.col, self.cspan, self.row, self.rspan end
    function s:SetGrid(c, cs, r, rs)
        c, cs, r, rs = Grid.valid(c, cs, r, rs)
        if not c or rs == -1 or self.rspan == -1 then return false end
        self.col, self.cspan, self.row, self.rspan = c, cs, r, rs
        self.custom = true
        return true
    end
    function s:ContentHeight() return sectionContentHeight(self) end
    return s
end

local ImageDropdown = {}
ImageDropdown.__index = ImageDropdown

function ImageDropdown:Get()
    local it = self.CurrentItem
    if not it then return nil end
    return { Name = it.Name, Value = it.CurrentValue }
end

function ImageDropdown:GetGroup()
    return self.CurrentItem and self.CurrentItem.Name or nil
end

function ImageDropdown:Find(name)
    for _, it in ipairs(self.Items) do
        if it.Name == name then return it end
    end
    return nil
end

function ImageDropdown:Select(name)
    local it = self:Find(name)
    if not it then return nil end
    self.CurrentItem = it
    Library.Flags[self.Flag] = self
    W.gSwitch(self, it.Name)
    return it
end

function ImageDropdown:SetItem(name, state)
    local it = self:Find(name)
    if not it then return end
    if self.LockFirst and it == self.Items[1] then state = true end
    it.CurrentValue = state and true or false
    Library.Flags[self.Flag] = self
    safecall(self.Callback, it.Name, it.CurrentValue)
end

function ImageDropdown:Set(v)
    if type(v) == "table" and v.Name then
        local it = self:Select(v.Name)
        if it then
            it.CurrentValue = (v.Value and true or false) or (self.LockFirst and it == self.Items[1])
            safecall(self.Callback, it.Name, it.CurrentValue)
        end
    elseif type(v) == "string" then
        local it = self:Select(v)
        if it then safecall(self.Callback, it.Name, it.CurrentValue) end
    elseif v == false then
        for i, it in ipairs(self.Items) do
            if it.CurrentValue and not (self.LockFirst and i == 1) then
                it.CurrentValue = false
                if it == self.CurrentItem then safecall(self.Callback, it.Name, false) end
            end
        end
    end
end

function ImageDropdown:Values()
    local out = {}
    for _, it in ipairs(self.Items) do out[it.Name] = it.CurrentValue end
    return out
end

function ImageDropdown:SetEnabled(b)
    self.Enabled = b and true or false
    if not self.Enabled then closePop(self) end
end

function ImageDropdown:CopyGroup(name)
    return W.gCopy(self, name or self:GetGroup())
end

function ImageDropdown:PasteGroup(name)
    return W.gPaste(self, name or self:GetGroup())
end

function W.wsOption(d, it, px, py, w, h, bold, key)
    if it.Icon then
        local iw, ih = Z(d.iconW), Z(d.iconH)
        local iy = (ih < h) and (py + floor((h - ih) / 2)) or py
        D.image(key, it.Icon, px + w - iw - Z(40), iy, iw, ih, C.white, bold and 200 / 255 or 80 / 255)
    end
    local bs = Z(8)
    local bx = px + Z(13)
    local by = py + floor((h - bs) / 2)
    local on = it.CurrentValue
    D.outline(bx, by, bs, bs, C.b12)
    D.vgrad(key .. "c", bx + 1, by + 1, bs - 2, bs - 2, on and T.acc or gray(100), on and T.acc2 or gray(60), on and 1 or 187 / 255)
    D.label(bx + Z(20), W.mid(py + 1, h), W.cut(it.Name, w - Z(20), bold), C.white, 200 / 255, bold)
end

function W.wsDraw(d, x, y, w, h)
    local p = UI.pop
    local mine = p ~= nil and p.owner == d
    local en = d.Enabled
    local hov = en and over(x, y, w, h)
    W.frame(x, y, w, h, d.ShowTitle and d.Name or "", (hov or (mine and p.list)) and C.b25 or C.b23, C.b40)
    local it = d.CurrentItem
    if it then W.wsOption(d, it, x + Z(7), y, w, h, true, "idd_h" .. d.id) end
    D.arrow(x + w - Z(12), y + floor((h - 4) / 2), true, 1, en and 136 / 255 or 50 / 255)
    anchor(d, x, y, w, h)
    if not en then
        d.held = false
        return
    end
    if I.m1p and hov and not I.used then
        I.used = true
        UI.take(d)
        d.held = true
        if mine then p.ctx = nil end
    end
    if I.m1r and d.held and hov then
        d.held = false
        if mine and p.list then
            closePop(d)
        else
            UI.pop = { owner = d, kind = "imagedd", born = D.frame, list = true }
            UI.popRect = nil
        end
    end
    if not I.m1 and not I.m1r then d.held = false end
    if I.m2r and hov and it then
        local ctx = { x = I.mx, y = I.my, item = it }
        if mine and UI.pop == p then
            p.ctx = ctx
        else
            UI.pop = { owner = d, kind = "imagedd", born = D.frame, list = false, ctx = ctx }
            UI.popRect = nil
        end
    end
end

function POP.imagedd(p)
    local d = p.owner
    local x, y, w = d.ax, d.ay + d.ahh + 1, d.aw
    local ctx = p.ctx
    local cw_, ch_ = Z(100), Z(20) * #W.CMENU
    local inCtx = ctx ~= nil and inside(ctx.x, ctx.y, cw_, ch_)
    local x0, y0, x1, y1
    if p.list then
        local items = d.Items
        local n = #items
        local rh = Z(30)
        local rows = min(8, n)
        local h = rh * rows
        x0, y0, x1, y1 = x, y, x + w, y + h
        D.rect(x, y, w, h, C.b12)
        D.rect(x + 1, y + 1, w - 2, h - 2, C.b35)
        local sc = d.sc
        local scroll = n > 8
        local content = n * rh
        if scroll then SB.clamp(sc, h, content, 0) else sc.pos = 0 end
        local used = scroll and SB.mouse(sc, x, y, w, h, content, not inCtx)
        local off = scroll and floor(sc.pos / rh) or 0
        local inp = (not inCtx) and over(x, y - 1, w, h + 1)
        local hi = -1
        if inp then
            hi = floor((I.my - y + 1) / rh)
            if hi < 0 or hi >= rows then hi = -1 end
        end
        for r = 0, rows - 1 do
            local it = items[off + r + 1]
            if not it then break end
            local ry = y + r * rh
            local hot = hi == r
            if hot then D.rect(x + 1, ry + 1, w - 2, rh - 2, C.b25) end
            W.wsOption(d, it, x + Z(7), ry, w, rh, hot or it == d.CurrentItem, "idd_r" .. d.id .. "_" .. r)
        end
        if scroll then SB.draw(sc, x, y, w, h, content, 1) end
        if not used and not inCtx then
            if I.m1p and inp and not I.used then
                I.used = true
                d.held = true
                p.ctx = nil
                ctx = nil
            end
            local it = (hi >= 0) and items[off + hi + 1] or nil
            local keep = false
            if d.held and it then
                if I.mx - d.ax < Z(50) then
                    keep = true
                    if I.m1r then
                        d.held = false
                        if not (d.LockFirst and it == items[1]) then
                            it.CurrentValue = not it.CurrentValue
                            Library.Flags[d.Flag] = d
                            safecall(d.Callback, it.Name, it.CurrentValue)
                        end
                    end
                elseif d.CurrentItem ~= it then
                    d:Select(it.Name)
                    safecall(d.Callback, it.Name, it.CurrentValue)
                end
            end
            if I.m1r and d.held and not keep then
                d.held = false
                if inp then p.list = false end
            end
            if I.m2r and inp and it then
                ctx = { x = I.mx, y = I.my, item = it }
                p.ctx = ctx
            end
        end
    end
    if ctx then
        local mx_, my_, mw, mh, picked = W.menu(ctx, ctx.x, ctx.y, W.CMENU, nil)
        if picked then
            if picked == 1 then d:CopyGroup(ctx.item.Name) else d:PasteGroup(ctx.item.Name) end
            p.ctx = nil
        end
        if x0 then
            x0, y0, x1, y1 = min(x0, mx_), min(y0, my_), max(x1, mx_ + mw), max(y1, my_ + mh)
        else
            x0, y0, x1, y1 = mx_, my_, mx_ + mw, my_ + mh
        end
    end
    if not p.list and not p.ctx then
        closePop(d)
        return x, y, 0, 0
    end
    return x0, y0, x1 - x0, y1 - y0
end

local ImageStrip = {}
ImageStrip.__index = ImageStrip

function ImageStrip:Get() return self.Value end
function ImageStrip:GetGroup() return self.Value end

function ImageStrip:Find(name)
    for _, it in ipairs(self.Items) do
        if it.Name == name then return it end
    end
    return nil
end

function ImageStrip:Select(name, silent)
    local it = self:Find(name)
    if not it then return nil end
    if self.Value == it.Name then return it end
    self.Value = it.Name
    self.CurrentItem = it
    Library.Flags[self.Flag] = self
    W.gSwitch(self, it.Name)
    if not silent then safecall(self.Callback, it.Name) end
    return it
end

function ImageStrip:Set(v)
    if type(v) == "table" then v = v.Name end
    if type(v) == "string" then self:Select(v) end
end

function ImageStrip:SetEnabled(b) self.Enabled = b and true or false end
function ImageStrip:CopyGroup(name) return W.gCopy(self, name or self.Value) end
function ImageStrip:PasteGroup(name) return W.gPaste(self, name or self.Value) end

function W.stripDraw(st, x, y, w, h)
    W.frame(x, y, w, h, st.ShowTitle and st.Name or "", C.b23, C.b40)
    local items = st.Items
    local n = #items
    if n == 0 then return end
    local cell = Z(st.cell)
    local sx = x + Z(10)
    local en = st.Enabled
    local hov = en and over(sx, y, w, h)
    local hi = -1
    if hov then hi = min(floor((I.mx - sx) / cell), n - 1) end
    if I.m1p and hov and not I.used then
        I.used = true
        UI.take(st)
        st.held = true
    end
    if st.held and hi >= 0 then st:Select(items[hi + 1].Name) end
    if not I.m1 then st.held = false end
    for i = 1, n do
        local it = items[i]
        local a = 80
        if it.Name == st.Value then a = 200 elseif hi == i - 1 then a = 120 end
        local cx = sx + (i - 1) * cell
        local drawn = false
        if it.Icon then
            local iw, ih = Z(st.iconW), Z(st.iconH)
            local ix = (iw < cell) and (cx + floor((cell - iw) / 2)) or cx
            local iy = (ih < h) and (y + floor((h - ih) / 2)) or y
            drawn = D.image("strip" .. st.id .. "_" .. i, it.Icon, ix, iy, iw, ih, C.white, a / 255)
        end
        if not drawn and cx + cell <= x + w then
            local s = W.cut(it.Name, cell - 4)
            D.text(cx + floor((cell - #s * CW) / 2), W.mid(y, h), s, C.white, a / 255)
        end
    end
end

function W.selItems(Options, lockFirst)
    local items = {}
    local src = Options.Options or {}
    if #src > 0 then
        for i, v in ipairs(src) do
            local it = { CurrentValue = false, Order = i }
            if type(v) == "table" then
                it.Name = tostring(v.Name or v[1] or i)
                it.Icon = v.Icon or v[2]
                it.CurrentValue = v.Enabled and true or false
            else
                it.Name = tostring(v)
            end
            items[#items + 1] = it
        end
    else
        for name, v in pairs(src) do
            local it = { Name = tostring(name), CurrentValue = false }
            if type(v) == "table" then
                it.Icon = v.Icon
                it.Order = tonumber(v.Order) or 0
                it.CurrentValue = v.Enabled and true or false
            else
                it.Icon = v
                it.Order = 0
            end
            items[#items + 1] = it
        end
        table.sort(items, function(a, b)
            if a.Order ~= b.Order then return a.Order < b.Order end
            return a.Name < b.Name
        end)
    end
    for _, it in ipairs(items) do
        if it.Icon ~= nil and not isImageSrc(it.Icon) then it.Icon = nil end
        function it:SetValue(b) self.CurrentValue = b and true or false end
        function it:Get() return { Name = self.Name, Value = self.CurrentValue } end
    end
    if lockFirst and items[1] then items[1].CurrentValue = true end
    return items
end

local Tab = {}
Tab.__index = Tab

function Tab:Section(Options)
    return newSection(self, Options or {}, self.page, { Left = self.Sides.Left.Sections, Right = self.Sides.Right.Sections })
end

function Tab:Activate()
    local win = self.Window
    if win.CurrentTab and win.CurrentTab ~= self then win.CurrentTab.Active = false end
    self.Active = true
    win.CurrentTab = self
    closePop()
end

function Tab:Deactivate()
    self.Active = false
    if self.Window.CurrentTab == self then self.Window.CurrentTab = nil end
end

function Tab:SubSection(Options)
    Options = Library:Validate({
        Name = "Preview Sub Section",
        Options = {},
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local tab = self
    local subs = { Name = tostring(Options.Name), Items = {}, Current = 1, Callback = Options.Callback }
    subs.strip = { col = 0, cspan = 24, row = 0, rspan = -1, fixed = tonumber(Options.Height) or 60 }
    self.Sub = subs
    self.SubSectionEnabled = true
    local out = {}
    for i, icon in ipairs(Options.Options) do
        local item = { Index = i, Active = i == 1, Left = {}, Right = {}, id = nextId() }
        item.page = { list = {}, pre = { subs.strip }, dirty = true }
        if isImageSrc(icon) then
            item.Icon = icon
            item.Label = tostring(i)
        else
            item.Label = tostring(icon)
            subs.Text = true
        end
        function item:Section(SOptions)
            return newSection(tab, SOptions or {}, self.page, { Left = self.Left, Right = self.Right })
        end
        function item:Activate()
            subs.Current = self.Index
            for _, o in ipairs(subs.Items) do o.Active = o == self end
            closePop()
            safecall(subs.Callback, self.Index)
        end
        function item:Deactivate() self.Active = false end
        subs.Items[i] = item
        out[i] = item
    end
    return (table.unpack or unpack)(out)
end

function Tab:ImageDropdown(Options)
    Options = Library:Validate({
        Name = "Weapon type",
        Options = {},
        LockFirst = true,
        ShowTitle = true,
        Height = 50,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local d = setmetatable({
        id = nextId(),
        Name = tostring(Options.Name),
        Flag = Options.Flag,
        Callback = Options.Callback,
        LockFirst = Options.LockFirst and true or false,
        ShowTitle = Options.ShowTitle and true or false,
        Enabled = true,
        sets = {},
        sc = { pos = 0 },
        Items = W.selItems(Options, Options.LockFirst),
        CurrentItem = nil,
    }, ImageDropdown)
    d.iconW, d.iconH = udimOffsets(Options.IconSize, 35, 30)
    if not (type(Options.Default) == "string" and d:Select(Options.Default)) and d.Items[1] then
        d:Select(d.Items[1].Name)
    end
    d.strip = {
        col = clamp(floor(tonumber(Options.Column) or 0), 0, 23), cspan = clamp(floor(tonumber(Options.ColumnSpan) or 12), 1, 24),
        row = 0, rspan = -1, fixed = tonumber(Options.Height) or 50,
    }
    self.page.pre = { d.strip }
    self.page.dirty = true
    self.ImageDD = d
    self.Strip = nil
    self.DropdownSectionEnabled = true
    Library.Flags[d.Flag] = d
    UI.sels = UI.sels or {}
    UI.sels[#UI.sels + 1] = d
    return d
end

function Tab:ImageStrip(Options)
    Options = Library:Validate({
        Name = "Weapon type",
        Options = {},
        ShowTitle = true,
        Height = 60,
        CellWidth = 76,
        Flag = Library:NewFlag(),
        Callback = function() end,
    }, Options)
    local st = setmetatable({
        id = nextId(),
        isStrip = true,
        Name = tostring(Options.Name),
        Flag = Options.Flag,
        Callback = Options.Callback,
        ShowTitle = Options.ShowTitle and true or false,
        Enabled = true,
        sets = {},
        cell = tonumber(Options.CellWidth) or 76,
        Items = W.selItems(Options, false),
        Value = nil,
        CurrentItem = nil,
    }, ImageStrip)
    st.iconW, st.iconH = udimOffsets(Options.IconSize, 48, 20)
    if not (type(Options.Default) == "string" and st:Select(Options.Default, true)) and st.Items[1] then
        st:Select(st.Items[1].Name, true)
    end
    st.strip = {
        col = clamp(floor(tonumber(Options.Column) or 0), 0, 23), cspan = clamp(floor(tonumber(Options.ColumnSpan) or 24), 1, 24),
        row = 0, rspan = -1, fixed = tonumber(Options.Height) or 60,
    }
    self.page.pre = { st.strip }
    self.page.dirty = true
    self.Strip = st
    self.ImageDD = nil
    Library.Flags[st.Flag] = st
    UI.sels = UI.sels or {}
    UI.sels[#UI.sels + 1] = st
    return st
end

local function drawTab(win, tab)
    local x, y = win.x, win.y
    local page = tab.page
    local sub_ = tab.Sub
    if sub_ then
        local item = sub_.Items[sub_.Current]
        if not item then return end
        page = item.page
    end
    Grid.layout(win, page)
    if sub_ then
        local st = sub_.strip
        local stx, sty, stw, sth = x + st.bx, y + st.by, st.bw + 1, st.bh + 1
        D.rect(stx, sty, stw, sth, C.b12)
        D.rect(stx + 1, sty + 1, stw - 2, sth - 2, C.b40)
        D.rect(stx + 2, sty + 2, stw - 4, sth - 4, C.b23)
        local ih0 = sth - 4
        local icw = clamp(floor((stw - 24) / max(1, #sub_.Items)), 20, sub_.Text and Z(110) or Z(75))
        for i, item in ipairs(sub_.Items) do
            local ix = stx + 12 + icw * (i - 1)
            if ix + icw <= stx + stw - 2 then
                local hov = over(ix, sty + 2, icw, ih0)
                local target = (sub_.Current == i) and 188 or (hov and 124 or 93)
                item.ag = approach(item.ag, target)
                local ih = floor(ih0 * icw / 75)
                local ok = item.Icon and D.image("sub" .. item.id, item.Icon, ix, sty + 2 + floor((ih0 - ih) / 2), icw, ih, gray(item.ag), item.ag / 188)
                if not ok then
                    local s = clampText(item.Label, icw - 4)
                    local g = item.Icon and item.ag or min(255, item.ag + 30)
                    D.text(ix + floor((icw - tw(s)) / 2), sty + floor((sth - CH) / 2), s, (sub_.Current == i and not item.Icon) and T.acc or gray(g))
                end
                if hov and click() then item:Activate() end
            end
        end
        if sub_.Name ~= "" then
            local nw = tw(sub_.Name) + 1
            D.rect(stx + 10, sty, nw + 7, 2, C.b23)
            D.label(stx + 14, sty - floor(CH / 2), sub_.Name, C.white, 200 / 255, true, true)
        end
    elseif tab.ImageDD then
        local st = tab.ImageDD.strip
        W.wsDraw(tab.ImageDD, x + st.bx, y + st.by, st.bw, st.bh)
    elseif tab.Strip then
        local st = tab.Strip.strip
        W.stripDraw(tab.Strip, x + st.bx, y + st.by, st.bw, st.bh)
    end
    local list = page.list
    for i = #list, 1, -1 do
        local s = list[i]
        if s.Visible then drawSection(s, win, page) end
    end
end

local Window = {}

function Window.visibleTabs(win)
    local out = {}
    for _, tab in ipairs(win.Tabs) do
        if not tab.Hidden then out[#out + 1] = tab end
    end
    return out
end

function Window.cycle(win, dir)
    local tabs = win.Tabs
    local n = #tabs
    if n == 0 then return end
    local idx = win.CurrentTab and win.CurrentTab.Index or 1
    for _ = 1, n do
        idx = (idx - 1 + dir) % n + 1
        if not tabs[idx].Hidden then
            if tabs[idx] ~= win.CurrentTab then
                win.TabChosen = true
                tabs[idx]:Activate()
            end
            return
        end
    end
end

function Window.focusNext(win)
    local tab = win.CurrentTab
    if not tab then return end
    local page = tab.page
    if tab.Sub then
        local item = tab.Sub.Items[tab.Sub.Current]
        if not item then return end
        page = item.page
    end
    local boxes = {}
    for _, s in ipairs(page.list) do
        if s.Visible then
            for _, e in ipairs(s.items) do
                if (e.isTextBox or e.isList) and e.shown and e.Enabled then boxes[#boxes + 1] = e end
            end
        end
    end
    if #boxes == 0 then return end
    local cur = UI.focus
    if not cur and UI.kf and UI.kf.isList then cur = UI.kf end
    local pick = boxes[1]
    for i, e in ipairs(boxes) do
        if e == cur then
            pick = boxes[i + 1] or boxes[1]
            break
        end
    end
    if pick == cur then return end
    UI.take(pick)
    if pick.isList then
        if pick.ShowSearch then
            pick.searchActive = true
            K.typed(true)
        end
        return
    end
    UI.focus = pick
    pick.Focused = true
    pick.seen = D.frame
    if pick.ClearOnFocus then pick.Text = "" end
    K.typed(true)
end

local function drawWindow(win)
    local x, y, W, H = win.x, win.y, win.w, win.h
    D.rect(x, y, W, H, C.b12)
    D.rect(x + 1, y + 1, W - 2, H - 2, C.b60)
    D.rect(x + 2, y + 2, W - 4, H - 4, C.b40)
    D.rect(x + 5, y + 5, W - 10, H - 10, C.b60)
    D.rect(x + 6, y + 6, W - 12, H - 12, C.b12)
    Img.drawBg(win, x + 6, y + 10, W - 12, H - 16)

    local tabW, tabH = Z(75), Z(64)
    local cur = win.CurrentTab
    if cur and cur.Hidden then
        cur.Active = false
        cur = nil
        win.CurrentTab = nil
    end
    local ty = 20
    for _, tab in ipairs(win.Tabs) do
        if tab.Hidden then
            tab.ty = nil
        else
            tab.ty = ty
            ty = ty + tabH
            if not cur and not win.TabChosen then
                tab:Activate()
                cur = tab
            end
        end
    end
    if not cur then
        for _, tab in ipairs(win.Tabs) do
            if not tab.Hidden then
                tab:Activate()
                cur = tab
                break
            end
        end
    end

    local sx0, sy0 = x + 6, y + 10
    local topH = cur and (cur.ty - 10) or 0
    if cur and topH + tabH + 20 < H then
        D.rect(sx0, sy0, tabW, topH, C.b12)
        D.rect(sx0 + tabW - 2, sy0, 1, topH - 1, C.black)
        D.rect(sx0 + tabW - 1, sy0, 1, topH, C.b40)
        D.rect(sx0, sy0 + topH - 2, tabW - 1, 1, C.black)
        D.rect(sx0, sy0 + topH - 1, tabW, 1, C.b40)
        local by = sy0 + topH + tabH
        local bh = y + H - 6 - by
        D.rect(sx0, by, tabW, bh, C.b12)
        D.rect(sx0 + tabW - 2, by + 1, 1, bh - 1, C.black)
        D.rect(sx0 + tabW - 1, by, 1, bh, C.b40)
        D.rect(sx0, by, tabW, 1, C.b40)
        D.rect(sx0, by + 1, tabW - 1, 1, C.black)
    else
        local bh = H - 16
        D.rect(sx0, sy0, tabW, bh, C.b12)
        D.rect(sx0 + tabW - 2, sy0 + 1, 1, bh - 1, C.black)
        D.rect(sx0 + tabW - 1, sy0, 1, bh, C.b40)
    end

    if not D.image("rainbow" .. win.id, "gen:rainbow", x + 7, y + 7, W - 14, 2) then
        D.rect(x + 7, y + 7, W - 14, 2, rgb(204, 70, 205))
    end
    D.rect(x + 7, y + 8, W - 14, 2, C.black, 119 / 255)

    for i, tab in ipairs(win.Tabs) do
        local tty = tab.ty
        if tty and tty + tabH <= H - 6 then
            local ay = y + tty
            local active = cur == tab
            local hov = over(x + 6, ay, tabW, tabH)
            local a = active and 1 or (hov and 200 / 255 or 100 / 255)
            local ok = false
            local icon = tab.Icon
            if icon then
                if tab.builtin then
                    ok = D.image("tab" .. tab.id, icon, x + 6 + floor((tabW - 48) / 2), ay + floor((tabH - 48) / 2), 48, 48, C.white, a)
                else
                    local iw, ih = tab.iconW or (tabW - 2), tab.iconH or tabH
                    ok = D.image("tab" .. tab.id, icon, x + 6 + floor((tabW - iw) / 2), ay + floor((tabH - ih) / 2), iw, ih, C.white, a)
                end
            end
            if not ok and tty + tabH < H then
                local s = UI.W.cut(tab.Name or tostring(i), tabW - 8, true)
                D.label(x + 6 + floor(tabW / 2) - floor((tw(s) + 1) / 2), ay + floor(tabH / 2) - floor(CH / 2), s, C.white, a, true)
            end
            if hov and click() and not active then
                win.TabChosen = true
                tab:Activate()
            end
        end
    end

    if win.CurrentTab then
        drawTab(win, win.CurrentTab)
    end

    local minW, minH = Z(win.minW), Z(win.minH)
    if UI.drag == win then
        if I.m1 then
            if UI.dragPart == "move" then
                local lox, loy = -floor(W / 3), -floor(H / 3)
                win.x = clamp(I.mx - win.dx, lox, max(lox, UI.vw - floor(W / 3)))
                win.y = clamp(I.my - win.dy, loy, max(loy, UI.vh - floor(H / 3)))
            elseif not Library.UI.LockLayout then
                local nw, nh = W + (I.mx - win.dx), H + (I.my - win.dy)
                if nw >= minW and nw ~= W then
                    win.w = min(nw, max(minW, win.maxW))
                    win.dx = I.mx
                end
                if nh >= minH and nh ~= H then
                    win.h = min(nh, max(minH, win.maxH))
                    win.dy = I.my
                end
                Library.UI.Resizing = true
            end
        else
            UI.drag = nil
            Library.UI.Resizing = false
        end
    elseif I.m1p and not I.used and not UI.drag and over(x, y, W, H) then
        I.used = true
        closePop()
        if UI.focus then UI.W.blur(UI.focus, false) end
        UI.kf = nil
        local g = Z(15)
        UI.drag = win
        if not Library.UI.LockLayout and I.mx - x > W - g and I.my - y > H - g then
            UI.dragPart = "size"
            win.dx, win.dy = I.mx, I.my
        else
            UI.dragPart = "move"
            win.dx, win.dy = I.mx - x, I.my - y
        end
    end
end

function Library:Window(Options)
    Options = Library:Validate({
        Name = "gamesense",
        MaxResize = { 10000, 10000 },
    }, Options)
    local sw, sh = udimOffsets(Options.Size, 660, 560)
    local mnw, mnh = udimOffsets(Options.MinResize, sw, sh)
    local mxw, mxh = udimOffsets(Options.MaxResize, 10000, 10000)
    if Options.CloseBind ~= nil then Library.UI.CloseBind = Options.CloseBind end
    local win = setmetatable({
        id = nextId(),
        index = #Library.Windows + 1,
        Name = Options.Name,
        Visible = true,
        CurrentTab = nil,
        Tabs = {},
        baseW = sw, baseH = sh,
        w = Z(sw), h = Z(sh),
        minW = mnw, minH = mnh, maxW = mxw, maxH = mxh,
        alpha = 0, fade = 2, fadeAt = nil,
    }, Library)
    local vw, vh = 1920, 1080
    pcall(function()
        local vs = workspace.CurrentCamera.ViewportSize
        vw, vh = vs.X, vs.Y
    end)
    win.x = floor(vw / 2 - win.w / 2)
    win.y = max(0, floor(vh / 2 - win.h / 2))
    win.SetTab = Window.SetTab
    win.CreateTab = Window.CreateTab
    win.Tab = Window.CreateTab
    win.SetVisible = Window.SetVisible
    win.NextTab = function(self) Window.cycle(self, 1) end
    win.PreviousTab = function(self) Window.cycle(self, -1) end
    Library.Windows[#Library.Windows + 1] = win
    Library.UI.MainUI = win
    Library:Start()
    return win
end

function Window:SetVisible(State, Instant)
    State = State and true or false
    if State ~= self.Visible then
        self.Visible = State
        self.fade = State and 2 or 1
        self.fadeAt = now()
    end
    if Instant then
        self.fade = 0
        self.alpha = 1
    end
    Library.UI.Faded = not self.Visible
    if not self.Visible then
        closePop()
        UI.capture = nil
        UI.drag = nil
        UI.held, UI.held2 = nil, nil
        Library.UI.Resizing = false
        if UI.focus then W.blur(UI.focus, false) end
        if UI.kf then UI.kf.searchActive = false end
        UI.kf = nil
    end
end

function Window:SetTab(Number)
    self.TabChosen = true
    self.PendingTab = nil
    local tab = self.Tabs[Number]
    if tab then tab:Activate() else self.PendingTab = Number end
end

function Window:CreateTab(Options)
    Options = Options or {}
    Library.UI.TabIndex = Library.UI.TabIndex + 1
    local tab = setmetatable({
        id = nextId(),
        Window = self,
        Icon = Options.Icon,
        Name = Options.Name,
        Index = #self.Tabs + 1,
        Active = false,
        Hidden = (Options.Hidden or Options.Visible == false) and true or false,
        SubSectionEnabled = false,
        DropdownSectionEnabled = false,
        Sides = { Left = { Sections = {}, Sizes = 0 }, Right = { Sections = {}, Sizes = 0 } },
        page = { list = {}, pre = {}, dirty = true },
        secN = 0,
    }, Tab)
    if type(tab.Icon) == "string" then
        local name = string.lower(tab.Icon)
        if Img.icons[name] then
            tab.Icon = "icon:" .. name
            tab.builtin = true
        elseif not isImageSrc(tab.Icon) then
            tab.Icon = nil
        end
    else
        tab.Icon = nil
    end
    if Options.IconSize ~= nil then
        tab.iconW, tab.iconH = udimOffsets(Options.IconSize, 48, 48)
    end
    self.Tabs[#self.Tabs + 1] = tab
    if self.PendingTab == tab.Index then
        self.PendingTab = nil
        tab:Activate()
    end
    return tab
end

function Tab:SetVisible(State)
    self.Hidden = not State
    if self.Hidden and self.Window.CurrentTab == self then
        self.Active = false
        self.Window.CurrentTab = nil
        self.Window.TabChosen = false
        closePop()
    end
end

function Tab:IsVisible()
    return not self.Hidden
end

local Notification = {}
Notification.__index = Notification

function Notification:UpdateText(Text)
    self.lines = parseRich(Text, C.t208)
    self.w = self.lines.w + 44
    self.h = #self.lines * CH + 5
end

function Notification:RemoveFrame()
    self.removing = true
end

function Notification:Update() end
function Notification:UpdatePositions() end

function Library:Notify(Options)
    Options = Library:Validate({ Message = "Notification", Delay = 3, Position = "Top Left" }, Options)
    local stackName = (Options.Position == "Top Left") and "TopLeft" or "Middle"
    local stack = Library.UI.Notifications[stackName]
    local n = setmetatable({
        Class = "Notification",
        stack = stackName,
        Delay = tonumber(Options.Delay) or 3,
        born = now(),
        a = 0,
        removing = false,
    }, Notification)
    n:UpdateText(Options.Message)
    table.insert(stack, 1, n)
    if not Library.Unloaded then Library:Start() end
    return n
end

local function drawNotifications()
    local tl = Library.UI.Notifications.TopLeft
    local total = 80
    for i = #tl, 1, -1 do
        local n = tl[i]
        if not n.removing and now() - n.born > n.Delay then n.removing = true end
        n.a = approach(n.a, n.removing and 0 or 1, 0.3)
        n.x = approach(n.x or -70, 5, 0.3)
        n.y = approach(n.y or total, total, 0.3)
        if n.a > 0.01 then
            softBar(n.x, n.y, n.w, n.h, n.a, "nb_tl" .. i)
            drawRich(n.lines, n.x + 22, n.y + 3, n.a, true)
        end
        total = total + n.h + 6
        if n.removing and n.a <= 0.01 then table.remove(tl, i) end
    end
    local mid = Library.UI.Notifications.Middle
    for i = #mid, 1, -1 do
        local n = mid[i]
        if not n.removing and now() - n.born > n.Delay then n.removing = true end
        n.a = approach(n.a, n.removing and 0 or 1, 0.3)
        local tx = floor(UI.vw / 2 - n.w / 2)
        local ty = UI.vh - 150 - i * 24
        n.x = tx
        n.y = approach(n.y or (UI.vh - 150), ty, 0.3)
        if n.a > 0.01 then
            softBar(n.x, n.y, n.w, n.h, n.a, "nb_mid" .. i)
            drawRich(n.lines, n.x + 22, n.y + 3, n.a, true)
        end
        if n.removing and n.a <= 0.01 then table.remove(mid, i) end
    end
end

local WM = { at = 0, lines = nil, w = 0 }
local function drawWatermark()
    if not (Library.UI.Initialized and Library.UI.Watermark) then return end
    local t = now()
    if not WM.lines or t - WM.at > (Library.UI.WatermarkRefreshRate or 1) or WM.acc ~= T.acc or WM.custom ~= Library.UI.WatermarkText then
        WM.at = t
        WM.acc = T.acc
        WM.custom = Library.UI.WatermarkText
        if WM.custom then
            WM.lines = parseRich(WM.custom, C.t208)
        else
            local name = tostring(Library.UI.Name or "gamesense")
            local a, b = name, ""
            local split = tonumber(Library.UI.NameSplit)
            if split and split >= 0 and split < #name then
                split = floor(split)
                a, b = sub(name, 1, split), sub(name, split + 1)
            elseif #name > 5 then
                a, b = sub(name, 1, #name - 5), sub(name, #name - 4)
            end
            WM.lines = {
                {
                    { t = a, c = C.t208 }, { t = b, c = T.acc }, { t = "  ", c = C.t208 },
                    { t = tostring(UI.fps), c = T.acc },
                    { t = (Library.UI.WatermarkClock == false) and " FPS" or " FPS  ", c = C.t208 },
                    { t = (Library.UI.WatermarkClock == false) and "" or os.date("%X"), c = C.t208 },
                },
            }
            local n = 0
            for _, seg in ipairs(WM.lines[1]) do n = n + #seg.t end
            WM.lines.w = n * CW
        end
        WM.w = WM.lines.w + 44
    end
    local x, y = UI.vw - WM.w - 5, 5
    softBar(x, y, WM.w, 20, 1, "nb_wm")
    drawRich(WM.lines, x + 22, y + 4, 1, true)
end

function Library:ToggleWatermark(State)
    Library.UI.Watermark = State and true or false
end

function Library:UpdateWatermark(Text)
    Library.UI.WatermarkText = (Text ~= nil) and tostring(Text) or nil
end

function Library:CreateWatermark()
    Library.UI.Watermark = true
end

local function pollHotkeys()
    if UI.capture then
        local kb = UI.capture
        local held = UI.capHeld
        for i = 1, #K.list do
            local vk = K.list[i]
            local d = UI.active and K.raw(vk)
            if not d then
                held[vk] = nil
            elseif not held[vk] then
                UI.capture = nil
                if vk == 0x1B then
                    kb:Set(nil)
                    kb.Key, kb.RegKeybind, kb.Keybind = nil, nil, "[-]"
                else
                    kb:Set(K.byVk[vk])
                    kb.down = true
                end
                UI.closeVk = nil
                if vk == 0x01 then I.used = true end
                if vk == 0x02 then I.used2 = true end
                break
            end
        end
        return
    end
    local typing = UI.focus ~= nil or (UI.kf ~= nil and UI.kf.searchActive == true)
    local list = Library.Keybinds
    for i = 1, #list do
        local kb = list[i]
        if kb.Key and not kb.Hiding then
            local d = K.down(K.toVk[kb.Key])
            if typing then
                kb.down = d
            elseif d ~= kb.down then
                kb.down = d
                if kb.Mode == "Always on" then
                    if d then kb:Toggle(true) end
                elseif kb.Mode == "On hotkey" then
                    kb:Toggle(d)
                elseif kb.Mode == "Off hotkey" then
                    kb:Toggle(not d)
                elseif d then
                    kb:Toggle()
                end
            end
        end
    end
end

local mouseObj
local function step()
    local t = now()
    UI.dt = clamp(t - UI.last, 0.001, 0.1)
    UI.last = t
    if t - (UI.vpAt or 0) > 0.5 then
        UI.vpAt = t
        pcall(function()
            local vs = workspace.CurrentCamera.ViewportSize
            UI.vw, UI.vh = vs.X, vs.Y
        end)
    end
    local th = Library.Theme.Default
    if th.Accent ~= T.sAcc then
        T.sAcc = th.Accent
        T.acc = pk(th.Accent)
        local r, g, b = unrgb(T.acc)
        T.acc2 = rgb(max(r - 40, 0), max(g - 40, 0), max(b - 40, 0))
        T.accS = rgb(max(r - 60, 0), max(g - 60, 0), max(b - 60, 0))
    end
    if th.TextColor ~= T.sText then T.sText = th.TextColor T.text = pk(th.TextColor) end
    if th.Risky ~= T.sRisky then T.sRisky = th.Risky T.risky = pk(th.Risky) end

    UI.active = isrbxactive() == true
    if not mouseObj then
        local lp = Players.LocalPlayer
        mouseObj = lp and lp:GetMouse()
    end
    if mouseObj then
        I.mx, I.my = mouseObj.X or 0, mouseObj.Y or 0
    end
    local d1 = UI.active and ismouse1pressed() == true
    local d2 = UI.active and ismouse2pressed() == true
    I.m1p, I.m1r, I.m1 = d1 and not I.m1, (not d1) and I.m1, d1
    I.m2p, I.m2r, I.m2 = d2 and not I.m2, (not d2) and I.m2, d2
    if UI.sels then
        for _, sel in ipairs(UI.sels) do
            if not sel.based then
                sel.based = true
                W.gBase(sel)
            end
        end
    end
    I.used, I.used2 = false, false

    D.begin()

    local cvk = K.vk(Library.UI.CloseBind)
    do
        local d = cvk and K.down(cvk) or false
        if cvk ~= UI.closeVk or UI.capture or UI.focus or (UI.kf and UI.kf.searchActive) then
            UI.closeVk = cvk
        elseif d and not UI.closeDown then
            for _, win in ipairs(Library.Windows) do
                if win.fade ~= 1 then win:SetVisible(not win.Visible) end
            end
        end
        UI.closeDown = d
    end

    pollHotkeys()

    do
        local td = K.down(0x09)
        if td and not UI.tabDown and not UI.capture then
            local ctrl = K.down(0x11) or K.down(0xA2) or K.down(0xA3)
            local shift = K.down(0x10) or K.down(0xA0) or K.down(0xA1)
            for _, win in ipairs(Library.Windows) do
                if win.Visible and win.fade == 0 then
                    if ctrl then
                        Window.cycle(win, shift and -1 or 1)
                    else
                        Window.focusNext(win)
                    end
                end
            end
        end
        UI.tabDown = td
    end

    for _, win in ipairs(Library.Windows) do
        if win.fade ~= 0 then
            if not win.fadeAt then win.fadeAt = t end
            local pr = (t - win.fadeAt) / 0.15
            if pr > 1 then
                win.fade = 0
                win.alpha = 1
            elseif win.fade == 2 then
                win.alpha = pr
            else
                win.alpha = 1 - pr
            end
        end
        if win.Visible or win.fade == 1 then
            D.alpha = win.alpha
            UI.noInput = win.fade ~= 0
            drawWindow(win)
            UI.noInput = false
            D.alpha = 1
        end
    end

    local p = UI.pop
    if p then
        if p.owner.seen ~= D.frame then
            UI.pop, UI.popRect = nil, nil
        else
            UI.inPop = true
            local px, py, pw, ph = POP[p.kind](p)
            UI.inPop = false
            if UI.pop == p then
                UI.popRect = { px, py, pw, ph }
            elseif not UI.pop then
                UI.popRect = nil
            end
        end
    else
        UI.popRect = nil
    end

    if UI.focus and UI.focus.seen ~= D.frame then
        W.blur(UI.focus, false)
    end
    if UI.capture and UI.capture.seen ~= D.frame then UI.capture = nil end
    if UI.kf and UI.kf.isList and UI.kf.seen ~= D.frame then
        UI.kf.searchActive = false
        UI.kf = nil
    end
    if not I.m1 then UI.held = nil end
    if not I.m2 then UI.held2 = nil end
    if UI.drag and not I.m1 and not I.m1r then
        UI.drag = nil
        Library.UI.Resizing = false
    end

    drawNotifications()
    drawWatermark()
    D.finish()
end

function Library:Start()
    if Library.Running then return end
    Library.Running = true
    Library.Unloaded = false
    UI.gen = (UI.gen or 0) + 1
    local gen = UI.gen
    D.dead = false
    _G.Library = Library
    Library:Connection(RunService.RenderStepped, function()
        UI.fpsN = UI.fpsN + 1
        local t = now()
        if t - UI.fpsAt >= 1 then
            UI.fps = floor(UI.fpsN / (t - UI.fpsAt) + 0.5)
            UI.fpsN = 0
            UI.fpsAt = t
        end
    end, "fps")
    task.spawn(function()
        while Library.Running and UI.gen == gen do
            UI.inStep = true
            local ok, err = pcall(step)
            UI.inStep = false
            if not ok then
                report(err, "render")
                UI.drag, UI.pop, UI.popRect, UI.inPop, UI.clip0, UI.clip1 = nil, nil, nil, false, nil, nil
                UI.held, UI.held2, UI.capture = nil, nil, nil
                UI.noInput = false
                D.alpha = 1
            end
            task.wait(0.007)
        end
        if UI.gen == gen or not Library.Running then D.destroy() end
    end)
end

function Library:Init()
    Library.UI.Initialized = true
    Library:Start()
end

do
    pcall(function()
        if not isfolder(Library.Folder) then makefolder(Library.Folder) end
        if not isfolder(Library.ConfigFolder) then makefolder(Library.ConfigFolder) end
        if not isfolder(Library.Folder .. "/Icons") then makefolder(Library.Folder .. "/Icons") end
    end)
    local probe = Library.ConfigFolder .. "/__probe"
    local ok = pcall(writefile, probe .. ".cfg", "1")
    if ok then
        pcall(delfile, probe .. ".cfg")
    else
        Library.ConfigExt = ".txt"
    end
end

Library.Internal = { Img = Img, D = D, UI = UI, Png = Png, Grid = Grid, RowH = UI.RowH, Scale = Z, Window = Window, W = W, POP = POP, SB = SB, K = K, I = I }
Library.FontNames = { "UI", "System", "SystemBold", "Minecraft", "Monospace", "Pixel", "Fortnite" }

function Library:SetFont(name)
    local id = Drawing.Fonts and Drawing.Fonts[tostring(name)]
    D.font = id or FONT
end

function Library:SetBoldFont(name)
    local id = Drawing.Fonts and Drawing.Fonts[tostring(name)]
    D.boldFont = id
end

_G.Library = Library
return Library
