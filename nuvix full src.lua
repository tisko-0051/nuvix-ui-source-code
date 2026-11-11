script_name('Nuvix UI Template')
script_author('UI template - design only')

--[[
    NUVIX UI TEMPLATE
    ------------------
    This is a VISUAL TEMPLATE ONLY. It reproduces the look of the
    reference screenshots (header, side menu, players list, player
    info panel, bottom-right monitor box).

    It intentionally contains NO gameplay-affecting logic (no speedhack,
    no RPC blocking, no spectate/teleport/desync code, etc). Anywhere
    you'd hook up real functionality, there's a clearly marked
    "-- TODO" comment with placeholder/sample data instead.

    Open the menu in-game with: /nuvix
]]

require 'lib.moonloader'
local imgui    = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local V, V2 = imgui.ImVec4, imgui.ImVec2

-- ===================== WINDOW CONSTANTS =====================
local WIN_W, HEADER_H = 500, 172
local winH = 540

-- ===================== STATE =====================
local show        = imgui.new.bool(false)
local showMonitor = imgui.new.bool(true)
local page        = 'home'      -- 'home' | 'players' | ...
local ptab        = 1           -- sub-tab inside 'players' page (1 Players, 2 Logs, 3 Free Cam)
local selected    = 1
local fMain, fLogo, fBold

-- ===================== FONTS =====================
-- Loads bold system fonts so the header/title and body text look like the
-- reference design instead of the default thin ImGui font.
-- TODO: if these paths don't exist on your system, point them at any
-- bold .ttf you have (e.g. a font shipped inside your moonloader/fonts folder).
imgui.OnInitialize(function()
    local io = imgui.GetIO()
    pcall(function()
        fMain = io.Fonts:AddFontFromFileTTF('C:/Windows/Fonts/segoeui.ttf', 16, nil, io.Fonts:GetGlyphRangesCyrillic())
    end)
    pcall(function()
        fBold = io.Fonts:AddFontFromFileTTF('C:/Windows/Fonts/segoeuib.ttf', 16, nil, io.Fonts:GetGlyphRangesCyrillic())
    end)
    pcall(function()
        -- Segoe UI Black: much heavier weight, matches the reference wordmark
        fLogo = io.Fonts:AddFontFromFileTTF('C:/Windows/Fonts/seguibl.ttf', 60, nil, io.Fonts:GetGlyphRangesCyrillic())
    end)
end)

-- ===================== SAMPLE / PLACEHOLDER DATA =====================
-- TODO: replace this with your own real data source (e.g. streamed players)
local samplePlayers = {
    {name = 'Aleksandar_Jovanovic', id = 244, dist = '143.0m', health = 84, armour = 0, weapon = 'Unarmed', vehicle = '-', state = 'On Foot', ping = 56},
    {name = 'Walker_Skill',         id = 61,  dist = '146m',  health = 100, armour = 0, weapon = 'Unarmed', vehicle = '-', state = 'On Foot', ping = 40},
    {name = 'Robert_Young',         id = 94,  dist = '147m',  health = 100, armour = 0, weapon = 'Unarmed', vehicle = '-', state = 'On Foot', ping = 60},
    {name = 'Jovan_Max',            id = 317, dist = '147m',  health = 100, armour = 0, weapon = 'Unarmed', vehicle = '-', state = 'On Foot', ping = 55},
    {name = 'Igi_Bleyaz',           id = 184, dist = '156m',  health = 100, armour = 0, weapon = 'Unarmed', vehicle = '-', state = 'On Foot', ping = 48},
    {name = 'Bahattee',             id = 174, dist = '157m',  health = 100, armour = 0, weapon = 'Unarmed', vehicle = '-', state = 'On Foot', ping = 70},
    {name = 'Ajla_Smajic',          id = 229, dist = '157m',  health = 100, armour = 0, weapon = 'Unarmed', vehicle = '-', state = 'On Foot', ping = 65},
}

-- TODO: replace with your own monitor/log data source
local monitor = {
    {'Mirko_Racic',  'CONNECTED'},
    {'Dino_Mujic',   'DISCONNECTED'},
    {'Edin_Saric',   'CONNECTED'},
    {'Ban_Bik',      'DISCONNECTED'},
    {'Fikro_Isu',    'TIMEOUT'},
    {'Korleone',     'DISCONNECTED'},
    {'Korleone',     'CONNECTED'},
    {'Zoran_Pasic',  'DISCONNECTED'},
    {'Sean_Combs',   'DISCONNECTED'},
}

local menuItems = {
    {'Player',        'players',  'person'},
    {'Server',        'server',   'globe'},
    {'Visual',        'visual',   'eye'},
    {'Vehicle',       'vehicle',  'car'},
    {'Miscellaneous', 'misc',     'grid'},
    {'Settings',      'settings', 'gear'},
}

-- ===================== COLORS (purple / dark theme) =====================
local col = {
    bg       = V(0.028, 0.028, 0.055, 0.98),
    header   = V(0.012, 0.012, 0.024, 1.0),
    list     = V(0.043, 0.043, 0.075, 1.0),
    panel    = V(0.075, 0.075, 0.120, 1.0),
    row      = V(0.067, 0.063, 0.114, 1.0),
    rowSel   = V(0.149, 0.118, 0.345, 1.0),
    accent   = V(0.42, 0.33, 0.92, 1.0),
    accentH  = V(0.58, 0.50, 1.00, 1.0),
    text     = V(0.90, 0.90, 0.94, 1.0),
    textDim  = V(0.55, 0.55, 0.64, 1.0),
    heading  = V(0.58, 0.50, 1.00, 1.0),
    green    = V(0.36, 0.85, 0.46, 1.0),
    red      = V(0.95, 0.33, 0.38, 1.0),
    yellow   = V(0.95, 0.75, 0.30, 1.0),
    border   = V(0.17, 0.15, 0.30, 1.0),
}

function U32(c, a) return imgui.ColorConvertFloat4ToU32(V(c.x, c.y, c.z, a or c.w)) end

local function statusCol(s)
    if s == 'CONNECTED' then return col.green end
    if s == 'TIMEOUT' then return col.yellow end
    return col.red
end

-- ===================== HELPERS =====================
local function shadowText(dl, x, y, c, text)
    dl:AddText(V2(x + 1, y + 1), U32(V(0,0,0,1), 0.85), text)
    dl:AddText(V2(x, y), U32(c), text)
end

local function boldText(dl, x, y, c, text)
    dl:AddText(V2(x + 0.5, y), U32(c), text)
    dl:AddText(V2(x, y), U32(c), text)
end

-- draws a small glyph centered at (cx, cy) inside a circle of radius r
local function drawIcon(dl, kind, cx, cy, r, c)
    local u32 = U32(c)
    if kind == 'person' then
        dl:AddCircleFilled(V2(cx, cy - r*0.32), r*0.32, u32)
        dl:AddRectFilled(V2(cx - r*0.42, cy + r*0.05), V2(cx + r*0.42, cy + r*0.62), u32, r*0.3)
    elseif kind == 'globe' then
        dl:AddCircle(V2(cx, cy), r*0.62, u32, 20, 1.6)
        dl:AddLine(V2(cx, cy - r*0.62), V2(cx, cy + r*0.62), u32, 1.4)
        dl:AddLine(V2(cx - r*0.62, cy), V2(cx + r*0.62, cy), u32, 1.4)
        dl:AddLine(V2(cx - r*0.44, cy - r*0.44), V2(cx + r*0.44, cy + r*0.44), u32, 1.0)
        dl:AddLine(V2(cx - r*0.44, cy + r*0.44), V2(cx + r*0.44, cy - r*0.44), u32, 1.0)
    elseif kind == 'eye' then
        dl:AddCircle(V2(cx, cy), r*0.55, u32, 20, 1.6)
        dl:AddCircleFilled(V2(cx, cy), r*0.2, u32)
    elseif kind == 'car' then
        dl:AddRectFilled(V2(cx - r*0.6, cy - r*0.05), V2(cx + r*0.6, cy + r*0.32), u32, r*0.18)
        dl:AddRectFilled(V2(cx - r*0.32, cy - r*0.34), V2(cx + r*0.32, cy), u32, r*0.14)
        dl:AddCircleFilled(V2(cx - r*0.35, cy + r*0.38), r*0.14, u32)
        dl:AddCircleFilled(V2(cx + r*0.35, cy + r*0.38), r*0.14, u32)
    elseif kind == 'grid' then
        local s, g = r*0.34, r*0.16
        dl:AddRectFilled(V2(cx - s - g/2, cy - s - g/2), V2(cx - g/2, cy - g/2), u32, 2)
        dl:AddRectFilled(V2(cx + g/2, cy - s - g/2), V2(cx + s + g/2, cy - g/2), u32, 2)
        dl:AddRectFilled(V2(cx - s - g/2, cy + g/2), V2(cx - g/2, cy + s + g/2), u32, 2)
        dl:AddRectFilled(V2(cx + g/2, cy + g/2), V2(cx + s + g/2, cy + s + g/2), u32, 2)
    elseif kind == 'gear' then
        dl:AddCircle(V2(cx, cy), r*0.5, u32, 8, 1.8)
        dl:AddCircleFilled(V2(cx, cy), r*0.18, u32)
        for a = 0, 7 do
            local ang = a * (math.pi / 4)
            local x1, y1 = cx + math.cos(ang) * r * 0.5, cy + math.sin(ang) * r * 0.5
            local x2, y2 = cx + math.cos(ang) * r * 0.78, cy + math.sin(ang) * r * 0.78
            dl:AddLine(V2(x1, y1), V2(x2, y2), u32, 2)
        end
    end
end

local function sectionLabel(text)
    imgui.PushStyleColor(imgui.Col.Text, col.textDim)
    imgui.Text(u8(text))
    imgui.PopStyleColor()
end

-- ===================== HEADER (logo) =====================
local glowOff = {
    {-3,0},{3,0},{0,-3},{0,3},{-3,-3},{3,3},{-3,3},{3,-3},
    {-6,0},{6,0},{0,-6},{0,6},
}

local function drawHeader()
    local dl = imgui.GetWindowDrawList()
    local wp = imgui.GetWindowPos()
    local w  = imgui.GetWindowWidth()

    -- darker top-to-bottom gradient instead of a flat fill
    local c1 = U32(V(0.055, 0.035, 0.11, 1))   -- slightly lighter purple-black at top
    local c2 = U32(V(0.02, 0.02, 0.04, 1))     -- near-black at bottom
    dl:AddRectFilledMultiColor(wp, V2(wp.x + w, wp.y + HEADER_H), c1, c1, c2, c2)

    -- decorative corner "constellation" dots (simple placeholder version)
    local function corner(cx, cy, flip)
        local s = flip and -1 or 1
        dl:AddCircleFilled(V2(cx, cy), 2, U32(col.accent, 0.8))
        dl:AddLine(V2(cx, cy), V2(cx + 18*s, cy + 10), U32(col.accent, 0.35), 1)
        dl:AddLine(V2(cx + 18*s, cy + 10), V2(cx + 30*s, cy - 6), U32(col.accent, 0.35), 1)
        dl:AddCircleFilled(V2(cx + 18*s, cy + 10), 1.5, U32(col.accent, 0.6))
        dl:AddCircleFilled(V2(cx + 30*s, cy - 6), 1.5, U32(col.accent, 0.6))
    end
    corner(wp.x + 20, wp.y + 20, false)
    corner(wp.x + w - 20, wp.y + 20, true)

    -- NUVIX title, heavier font + soft glow behind it
    if fLogo then imgui.PushFont(fLogo) end
    local title = 'NUVIX'
    local tsz = imgui.CalcTextSize(title)
    local tx, ty = wp.x + w/2 - tsz.x/2, wp.y + 50
    for i, o in ipairs(glowOff) do
        local a = (i <= 8) and 0.16 or 0.07
        dl:AddText(V2(tx + o[1], ty + o[2]), U32(col.accentH, a), title)
    end
    dl:AddText(V2(tx, ty), U32(col.accentH), title)
    if fLogo then imgui.PopFont() end

    -- divider with small diamond
    local ly = wp.y + HEADER_H - 14
    dl:AddLine(V2(wp.x + 24, ly), V2(wp.x + w/2 - 10, ly), U32(col.accent, 0.5), 1)
    dl:AddLine(V2(wp.x + w/2 + 10, ly), V2(wp.x + w - 24, ly), U32(col.accent, 0.5), 1)
    dl:AddQuadFilled(
        V2(wp.x + w/2, ly - 5), V2(wp.x + w/2 + 5, ly),
        V2(wp.x + w/2, ly + 5), V2(wp.x + w/2 - 5, ly), U32(col.accent, 0.9))

    -- close "X"
    imgui.SetCursorPos(V2(w - 28, 10))
    if imgui.Button(u8('X'), V2(18, 18)) then show[0] = false end
end

-- ===================== HOME PAGE (main menu list) =====================
local function drawHomePage()
    imgui.BeginChild('##homeList', V2(0, winH - HEADER_H - 30), false)
    local rowH = 64
    local dl = imgui.GetWindowDrawList()
    for i, item in ipairs(menuItems) do
        local label, target, icon = item[1], item[2], item[3]

        imgui.PushStyleColor(imgui.Col.Button, V(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, col.row)
        imgui.PushStyleColor(imgui.Col.ButtonActive, col.rowSel)
        if imgui.Button('##home' .. i, V2(-1, rowH)) then
            page = target
        end
        imgui.PopStyleColor(3)

        local rmin = imgui.GetItemRectMin()
        local rmax = imgui.GetItemRectMax()
        local midY = (rmin.y + rmax.y) / 2

        -- icon circle
        local iconCx, iconR = rmin.x + 34, 16
        dl:AddCircleFilled(V2(iconCx, midY), iconR, U32(col.accent, 0.22))
        drawIcon(dl, icon, iconCx, midY, iconR, col.accentH)

        -- label
        if fBold then imgui.PushFont(fBold) end
        shadowText(dl, rmin.x + 64, midY - 8, col.text, label)
        if fBold then imgui.PopFont() end

        -- chevron '>'
        local chv = '>'
        local cw = imgui.CalcTextSize(chv).x
        shadowText(dl, rmax.x - 20 - cw, midY - 8, col.textDim, chv)

        -- separator line (skip after last item)
        if i < #menuItems then
            dl:AddLine(V2(rmin.x + 16, rmax.y), V2(rmax.x - 16, rmax.y), U32(col.border, 0.8), 1)
        end
    end
    imgui.EndChild()
end

-- ===================== PLAYERS PAGE =====================
local function drawPlayersSubTabs()
    local tabs = {'Players', 'Logs', 'Free Cam'}
    local w = imgui.GetContentRegionAvail().x
    local tabW = w / #tabs
    local startPos = imgui.GetCursorPos()
    local startScreen = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()

    for i, t in ipairs(tabs) do
        local active = (ptab == i)
        imgui.SetCursorPos(V2(startPos.x + (i - 1) * tabW, startPos.y))
        imgui.PushStyleColor(imgui.Col.Button, V(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ButtonActive, V(0, 0, 0, 0))
        if imgui.Button('##tab' .. i, V2(tabW, 32)) then ptab = i end
        imgui.PopStyleColor(3)

        local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
        if active then
            -- filled rounded pill behind the active tab label
            dl:AddRectFilled(V2(rmin.x + 4, rmin.y + 3), V2(rmax.x - 4, rmax.y - 3), U32(col.accent), 6)
        end
        local tsz = imgui.CalcTextSize(t)
        local tx = rmin.x + (tabW - tsz.x) / 2
        local ty = rmin.y + ((rmax.y - rmin.y) - tsz.y) / 2
        dl:AddText(V2(tx, ty), U32(active and V(1, 1, 1, 1) or col.textDim), t)
    end

    -- single underline spanning the whole tab bar
    imgui.SetCursorPos(V2(startPos.x, startPos.y + 36))
    dl:AddLine(V2(startScreen.x, startScreen.y + 36), V2(startScreen.x + w, startScreen.y + 36), U32(col.border, 0.9), 1)
    imgui.Dummy(V2(w, 4))
end

-- one continuous bar, split into N columns by thin vertical divider lines
-- (matches the reference: not separate boxes with gaps, but one seamless strip)
local function statBar(items)
    local h = 50
    local w = imgui.GetContentRegionAvail().x
    imgui.BeginChild('##statbar', V2(w, h), true)
    local dl = imgui.GetWindowDrawList()
    local wp = imgui.GetWindowPos()
    local colW = w / #items
    for i, it in ipairs(items) do
        local cx = wp.x + (i - 1) * colW + 12
        imgui.SetCursorPos(V2((i - 1) * colW + 12, 6))
        imgui.PushStyleColor(imgui.Col.Text, col.textDim)
        imgui.Text(u8(it[1]))
        imgui.PopStyleColor()
        imgui.SetCursorPos(V2((i - 1) * colW + 12, 26))
        imgui.PushStyleColor(imgui.Col.Text, col.text)
        imgui.Text(u8(tostring(it[2])))
        imgui.PopStyleColor()
        if i < #items then
            dl:AddLine(V2(wp.x + i * colW, wp.y + 8), V2(wp.x + i * colW, wp.y + h - 8), U32(col.border, 0.9), 1)
        end
    end
    imgui.EndChild()
end

local function drawPlayersList()
    -- top stat bar (placeholder numbers)
    -- TODO: wire these to real stream/player data
    statBar({
        {'PLAYERS IN STREAM', #samplePlayers},
        {'NEAREST PLAYER', samplePlayers[1] and samplePlayers[1].name or '-'},
        {'AVG DISTANCE', '162m'},
    })

    imgui.Spacing()
    local avail = imgui.GetContentRegionAvail()

    -- left: player list
    imgui.BeginChild('##plist', V2(avail.x * 0.48, avail.y), true)
    local dl = imgui.GetWindowDrawList()
    for i, p in ipairs(samplePlayers) do
        local isSel = (selected == i)
        imgui.PushStyleColor(imgui.Col.Button, isSel and col.rowSel or V(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, isSel and col.rowSel or col.row)
        imgui.PushStyleColor(imgui.Col.ButtonActive, col.rowSel)
        if imgui.Button('##row' .. i, V2(-1, 46)) then selected = i end
        imgui.PopStyleColor(3)

        local rmin, rmax = imgui.GetItemRectMin(), imgui.GetItemRectMax()
        if isSel then
            -- thin accent bar on the left edge instead of a flat full-row fill
            dl:AddRectFilled(V2(rmin.x, rmin.y), V2(rmin.x + 3, rmax.y), U32(col.accentH))
        end
        shadowText(dl, rmin.x + 14, rmin.y + 6, col.text, p.name)
        shadowText(dl, rmin.x + 14, rmin.y + 24, col.red, p.dist)
        local idTxt = '#' .. p.id
        local idw = imgui.CalcTextSize(idTxt).x
        shadowText(dl, rmin.x + 230 - idw, rmin.y + 6, col.textDim, idTxt)
        if i < #samplePlayers then
            dl:AddLine(V2(rmin.x + 10, rmax.y), V2(rmax.x - 10, rmax.y), U32(col.border, 0.7), 1)
        end
    end
    imgui.EndChild()

    imgui.SameLine()

    -- right: selected player info panel
    imgui.BeginChild('##pinfo', V2(avail.x * 0.5, avail.y), true)
    local p = samplePlayers[selected]
    sectionLabel('PLAYER INFO')
    imgui.Spacing()
    if p then
        imgui.PushStyleColor(imgui.Col.Text, col.heading)
        imgui.Text(u8(p.name))
        imgui.PopStyleColor()
        imgui.Spacing()

        local function row(label, value, valCol)
            imgui.Text(u8(label))
            imgui.SameLine(140)
            imgui.PushStyleColor(imgui.Col.Text, valCol or col.text)
            imgui.Text(u8(tostring(value)))
            imgui.PopStyleColor()
        end

        row('ID', '#' .. p.id)
        row('Distance', p.dist, col.red)
        row('Health', p.health)
        row('Armour', p.armour)
        row('Weapon', p.weapon)
        row('Vehicle', p.vehicle)
        row('State', p.state, col.heading)
        row('Ping', p.ping .. 'ms')

        imgui.Spacing()
        sectionLabel('ACTIONS')
        imgui.Spacing()

        imgui.PushStyleColor(imgui.Col.Button, V(0.45, 0.12, 0.14, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, V(0.55, 0.16, 0.18, 1))
        imgui.PushStyleColor(imgui.Col.Border, col.red)
        imgui.PushStyleVarFloat(imgui.StyleVar.FrameBorderSize, 1)
        if imgui.Button(u8('  Spectate Player'), V2(-1, 34)) then
            -- TODO: hook up your own (legitimate) spectate logic here
        end
        imgui.PopStyleVar()
        imgui.PopStyleColor(3)
    end
    imgui.EndChild()
end

local function drawLogsTab()
    imgui.BeginChild('##logs', V2(0, 0), true)
    sectionLabel('LOGS')
    imgui.Spacing()
    imgui.TextWrapped(u8('-- TODO: render your own log entries here --'))
    imgui.EndChild()
end

local function drawFreeCamTab()
    imgui.BeginChild('##freecam', V2(0, 0), true)
    sectionLabel('FREE CAM')
    imgui.Spacing()
    imgui.TextWrapped(u8('-- TODO: free cam controls / settings go here --'))
    imgui.EndChild()
end

local function drawPlayersPage()
    if imgui.Button(u8('< Back'), V2(80, 24)) then page = 'home' end
    imgui.Spacing()
    drawPlayersSubTabs()
    if ptab == 1 then drawPlayersList()
    elseif ptab == 2 then drawLogsTab()
    elseif ptab == 3 then drawFreeCamTab()
    end
end

-- generic placeholder page for the other menu entries
local function drawGenericPage(title)
    if imgui.Button(u8('< Back'), V2(80, 24)) then page = 'home' end
    imgui.Spacing()
    sectionLabel(title:upper())
    imgui.Spacing()
    imgui.TextWrapped(u8('-- TODO: build this page\'s content --'))
end

-- ===================== STATUS BAR =====================
local function drawStatusBar()
    local dl = imgui.GetWindowDrawList()
    local wp = imgui.GetWindowPos()
    local w  = imgui.GetWindowWidth()
    local h  = imgui.GetWindowHeight()
    local y  = wp.y + h - 26

    dl:AddRectFilled(V2(wp.x, y), V2(wp.x + w, wp.y + h), U32(col.header))
    shadowText(dl, wp.x + 10, y + 5, col.heading, 'Nuvix Menu')
    shadowText(dl, wp.x + 90, y + 5, col.textDim, '- SAMP')

    -- TODO: wire FPS / ping / players-online up to real values
    local right = {
        {'FPS 60',   col.green},
        {'Ping 50ms', col.text},
        {'0/100',    col.text},
    }
    local rx = wp.x + w - 20
    for i = #right, 1, -1 do
        local txt, c = right[i][1], right[i][2]
        local tw = imgui.CalcTextSize(txt).x
        rx = rx - tw
        shadowText(dl, rx, y + 5, c, txt)
        rx = rx - 16
    end
end

-- ===================== MAIN WINDOW =====================
local mainFrame = imgui.OnFrame(function() return show[0] end, function(self)
    imgui.SetNextWindowSize(V2(WIN_W, winH), imgui.Cond.FirstUseEver)
    imgui.PushStyleColor(imgui.Col.WindowBg, col.bg)
    imgui.PushStyleColor(imgui.Col.Border, col.border)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6)
    imgui.PushStyleVarFloat(imgui.StyleVar.ChildRounding, 6)
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 4)

    imgui.Begin(u8('Nuvix'), show, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
    if fMain then imgui.PushFont(fMain) end

    drawHeader()
    imgui.SetCursorPosY(HEADER_H + 10)
    imgui.BeginChild('##body', V2(0, imgui.GetWindowHeight() - HEADER_H - 40), false)

    if page == 'home' then
        drawHomePage()
    elseif page == 'players' then
        drawPlayersPage()
    else
        drawGenericPage(page)
    end

    imgui.EndChild()
    drawStatusBar()

    if fMain then imgui.PopFont() end
    imgui.End()
    imgui.PopStyleVar(3)
    imgui.PopStyleColor(2)
end)

-- ===================== MONITOR WINDOW (bottom-right) =====================
local monFrame = imgui.OnFrame(function() return showMonitor[0] end, function(self)
    self.HideCursor = true
    local sx, sy = getScreenResolution()
    local rowH, hdrH, w = 28, 26, 300
    local h = hdrH + #monitor * rowH + 10
    imgui.SetNextWindowPos(V2(sx - w - 14, sy * 0.585), imgui.Cond.Always)
    imgui.SetNextWindowSize(V2(w, h), imgui.Cond.Always)
    imgui.PushStyleColor(imgui.Col.WindowBg, V(0, 0, 0, 0))
    imgui.PushStyleColor(imgui.Col.Border, V(0, 0, 0, 0))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
    imgui.Begin('##monitor', nil, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize
        + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoScrollbar
        + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoSavedSettings)
    if fMain then imgui.PushFont(fMain) end

    local dl, wp = imgui.GetWindowDrawList(), imgui.GetWindowPos()

    dl:AddRectFilled(wp, V2(wp.x + w, wp.y + hdrH), U32(V(0.02, 0.02, 0.04, 1), 0.96))
    local l1, l2 = U32(col.accent, 1), U32(col.accent, 0.15)
    dl:AddRectFilledMultiColor(V2(wp.x, wp.y + hdrH), V2(wp.x + w, wp.y + hdrH + 2), l1, l2, l2, l1)
    local nw = imgui.CalcTextSize('NUVIX ').x
    boldText(dl, wp.x + 12, wp.y + 4, col.accentH, 'NUVIX')
    dl:AddText(V2(wp.x + 12 + nw, wp.y + 4), U32(V(0.62, 0.62, 0.72, 1)), 'MONITOR')

    local statusX = wp.x + 150
    for i, m in ipairs(monitor) do
        local y = wp.y + hdrH + 9 + (i - 1) * rowH
        shadowText(dl, wp.x + 12, y, V(0.92, 0.92, 0.96, 1), m[1])
        boldText(dl, statusX, y, statusCol(m[2]), m[2])
    end

    if fMain then imgui.PopFont() end
    imgui.End()
    imgui.PopStyleVar()
    imgui.PopStyleColor(2)
end)
monFrame.HideCursor = true

-- ===================== MAIN =====================
function main()
    while not isSampAvailable() do wait(100) end
    sampRegisterChatCommand('nuvix', function() show[0] = not show[0] end)
    while true do
        wait(0)
        if wasKeyPressed(0x2D) then show[0] = not show[0] end -- Insert
    end
end
