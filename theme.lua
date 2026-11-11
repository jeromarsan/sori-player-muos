-- Thème "Sori Player" : couleurs, polices, formes arrondies, icônes dessinées, mascotte.
local utf8 = require("utf8")
local lg = love.graphics
local T = {}

T.W, T.H = 640, 480

-- Thèmes (Réglages > Thème). T.c est modifié sur place pour que tous les écrans suivent.
local THEMES = {
  sombre = {
    bg = { 0.071, 0.071, 0.086 },      -- fond
    surface = { 0.145, 0.145, 0.170 }, -- cartes, lignes, mini-lecteur
    cap = { 0.230, 0.230, 0.270 },     -- pastilles de boutons
    ink = { 0.95, 0.95, 0.97 },        -- texte principal
    ink2 = { 0.66, 0.66, 0.72 },       -- texte secondaire
    ink3 = { 0.44, 0.44, 0.50 },       -- texte discret
    track = { 1, 1, 1, 0.10 },         -- fond des barres (volume, progression)
    line = { 1, 1, 1, 0.06 },          -- contours fins
    shadow = { 0, 0, 0 },
  },
  clair = {
    bg = { 0.949, 0.949, 0.969 },
    surface = { 1, 1, 1 },
    cap = { 1, 1, 1 },
    ink = { 0.11, 0.11, 0.14 },
    ink2 = { 0.44, 0.44, 0.50 },
    ink3 = { 0.70, 0.70, 0.75 },
    track = { 0, 0, 0, 0.09 },
    line = { 0, 0, 0, 0.10 },
    shadow = { 0.16, 0.18, 0.32 },
  },
}
T.c = { white = { 1, 1, 1 } }
T.themeName, T.dark = "sombre", true
function T.setTheme(name)
  if not THEMES[name] then name = "sombre" end
  for k, v in pairs(THEMES[name]) do T.c[k] = v end
  T.themeName, T.dark = name, (name == "sombre")
end
T.setTheme("sombre")
T.palette = {
  { 1.00, 0.42, 0.42 }, -- corail
  { 1.00, 0.76, 0.18 }, -- soleil
  { 0.20, 0.80, 0.60 }, -- menthe
  { 0.29, 0.62, 1.00 }, -- ciel
  { 0.62, 0.42, 1.00 }, -- violet
  { 1.00, 0.46, 0.70 }, -- rose
}

-- Couleur principale (Réglages, ou sori.cfg : couleur=bleu | corail | jaune | menthe | violet | rose | album | #RRGGBB)
local ACCENTS = { corail = 1, jaune = 2, soleil = 2, menthe = 3, vert = 3, bleu = 4, ciel = 4, violet = 5, rose = 6 }
-- ordre proposé dans l'écran Réglages
T.accentChoices = {
  { id = "bleu", label = "Bleu" }, { id = "corail", label = "Corail" }, { id = "jaune", label = "Jaune" },
  { id = "menthe", label = "Menthe" }, { id = "violet", label = "Violet" }, { id = "rose", label = "Rose" },
  { id = "album", label = "Pochette" },
}
T.accent, T.accentName = T.palette[4], "bleu"
function T.setAccent(name)
  name = (name or ""):lower()
  if name == "" then name = "bleu" end
  T.accentName = name
  if name == "album" then T.accent = nil; return end
  local hex = name:match("^#?(%x%x%x%x%x%x)$")
  if hex then
    T.accent = { tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255 }
  else
    if not ACCENTS[name] then T.accentName = "bleu" end
    T.accent = T.palette[ACCENTS[name] or 4]
  end
end
function T.accentColor(id) return ACCENTS[id] and T.palette[ACCENTS[id]] or nil end
-- couleur à utiliser pour un album (l'accent fixe, ou la couleur de la pochette si couleur=album)
function T.accentFor(album) return T.accent or (album and album.tint) or T.palette[4] end

---------------------------------------------------------------- couleurs
function T.set(c, a) lg.setColor(c[1], c[2], c[3], a or 1) end
function T.mix(a, b, t) return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t } end
function T.lighten(c, t) return T.mix(c, T.c.white, t) end
function T.darken(c, t) return T.mix(c, { 0.08, 0.08, 0.12 }, t) end
-- version d'une couleur lisible sur le fond (éclaircie en sombre, assombrie en clair)
function T.contrast(c, t) if T.dark then return T.lighten(c, t) end return T.darken(c, t) end
-- fond des barres (volume, progression)
function T.track(a) local c = T.c.track; lg.setColor(c[1], c[2], c[3], c[4] * (a or 1)) end
function T.damp(a, b, rate, dt) return a + (b - a) * (1 - math.exp(-rate * dt)) end
function T.clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
function T.ease(t) t = T.clamp(t, 0, 1); return 1 - (1 - t) ^ 3 end

function T.rgb2hsv(r, g, b)
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  local d = mx - mn
  local h = 0
  if d > 0 then
    if mx == r then h = ((g - b) / d) % 6
    elseif mx == g then h = (b - r) / d + 2
    else h = (r - g) / d + 4 end
    h = h / 6
  end
  return h, (mx == 0) and 0 or d / mx, mx
end

function T.hsv2rgb(h, s, v)
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
  i = i % 6
  if i == 0 then return { v, t, p } elseif i == 1 then return { q, v, p } elseif i == 2 then return { p, v, t }
  elseif i == 3 then return { p, q, v } elseif i == 4 then return { t, p, v } end
  return { v, p, q }
end

---------------------------------------------------------------- polices
function T.load()
  local function F(file, size)
    local f = lg.newFont("assets/" .. file, size)
    f:setFilter("linear", "linear")
    return f
  end
  T.f = {
    huge = F("Nunito-Black.ttf", 40),
    title = F("Nunito-Black.ttf", 34),
    h1 = F("Nunito-ExtraBold.ttf", 26),
    h2 = F("Nunito-ExtraBold.ttf", 20),
    body = F("Nunito-SemiBold.ttf", 18),
    small = F("Nunito-SemiBold.ttf", 15),
    tiny = F("Nunito-ExtraBold.ttf", 12),
    logo = F("Nunito-Black.ttf", 26),
    logoSub = F("Nunito-ExtraBold.ttf", 9),
  }
end

---------------------------------------------------------------- logo
-- hauteurs relatives des barres et dégradé rose → violet → bleu → cyan
T.LOGO_H = { 0.30, 0.48, 0.70, 0.40, 0.92, 0.62, 1.00, 0.55, 0.80, 0.45, 0.66, 0.36, 0.24 }
local LOGO_STOPS = { { 0.94, 0.20, 0.56 }, { 0.70, 0.30, 0.82 }, { 0.45, 0.42, 0.96 }, { 0.30, 0.82, 0.92 } }
function T.logoColor(u)
  local n = #LOGO_STOPS - 1
  local x = math.max(0, math.min(1, u)) * n
  local i = math.min(n - 1, math.floor(x))
  return T.mix(LOGO_STOPS[i + 1], LOGO_STOPS[i + 2], x - i)
end

-- texte en lettres espacées, étalé sur la largeur w (ASCII)
function T.spaced(font, s, x, y, w)
  local sum = 0
  for c in s:gmatch(".") do sum = sum + font:getWidth(c) end
  local sp = math.max(2, (w - sum) / math.max(1, #s - 1))
  lg.setFont(font)
  for c in s:gmatch(".") do
    lg.print(c, x, y)
    x = x + font:getWidth(c) + sp
  end
end

---------------------------------------------------------------- texte défilant
-- Si le texte dépasse w : défile (avec une pause au début) quand une clé est donnée,
-- sinon il est coupé avec "…". Sans dépassement : affichage normal (align possible).
local marquees = {}
local MQ_SPEED, MQ_PAUSE, MQ_GAP = 34, 1.4, 48
function T.marquee(font, s, x, y, w, color, a, key, align)
  s = s or ""
  local tw = font:getWidth(s)
  if tw <= w or not key then
    if tw > w then s = T.fit(font, s, w) end
    T.text(font, s, x, y, color, a, align, align and w)
    return
  end
  local now = love.timer.getTime()
  local m = marquees[key]
  if not m or m.s ~= s or now - m.seen > 0.25 then m = { s = s, t0 = now }; marquees[key] = m end
  m.seen = now
  local L = MQ_PAUSE + (tw + MQ_GAP) / MQ_SPEED
  local u = (now - m.t0) % L
  local off = (u < MQ_PAUSE) and 0 or (u - MQ_PAUSE) * MQ_SPEED
  local sx, sy, sw, sh = lg.getScissor()
  local x1, y1 = lg.transformPoint(x, y - 4)
  local x2, y2 = lg.transformPoint(x + w, y + font:getHeight() + 4)
  lg.intersectScissor(x1, y1, math.max(0, x2 - x1), math.max(0, y2 - y1))
  T.text(font, s, x - off, y, color, a)
  T.text(font, s, x - off + tw + MQ_GAP, y, color, a)
  if sx then lg.setScissor(sx, sy, sw, sh) else lg.setScissor() end
end

local function sub(s, n) -- n premiers caractères UTF-8
  local o = utf8.offset(s, n + 1)
  return o and s:sub(1, o - 1) or s
end

local fitCache = {}
function T.fit(font, s, maxw)
  if font:getWidth(s) <= maxw then return s end
  local key = tostring(font) .. "|" .. maxw .. "|" .. s
  if fitCache[key] then return fitCache[key] end
  local lo, hi = 0, utf8.len(s) or #s
  while lo < hi do
    local mid = math.ceil((lo + hi) / 2)
    if font:getWidth(sub(s, mid) .. "…") <= maxw then lo = mid else hi = mid - 1 end
  end
  local r = sub(s, lo):gsub("%s+$", "") .. "…"
  fitCache[key] = r
  return r
end

function T.wrap(font, s, w, maxLines)
  local _, lines = font:getWrap(s, w)
  if #lines <= maxLines then return lines end
  local out = {}
  for i = 1, maxLines - 1 do out[i] = lines[i] end
  out[maxLines] = T.fit(font, table.concat(lines, " ", maxLines), w)
  return out
end

function T.text(font, s, x, y, color, a, align, w)
  lg.setFont(font)
  T.set(color, a)
  if align then lg.printf(s, x, y, w, align) else lg.print(s, x, y) end
end

---------------------------------------------------------------- formes
function T.rr(mode, x, y, w, h, r)
  r = math.min(r, w / 2, h / 2)
  lg.rectangle(mode, x, y, w, h, r, r, 20)
end

function T.shadow(x, y, w, h, r, size, alpha, dy, col)
  size, alpha, dy = size or 12, alpha or 0.15, dy or 5
  col = col or T.c.shadow
  local n = 5
  for i = n, 1, -1 do
    local k = i / n
    local g = size * k
    lg.setColor(col[1], col[2], col[3], alpha * 0.32 * (1.15 - k))
    T.rr("fill", x - g, y - g + dy, w + 2 * g, h + 2 * g, r + g)
  end
end

local gmesh
function T.gradV(x, y, w, h, c1, c2, a1, a2)
  gmesh = gmesh or lg.newMesh(4, "fan", "stream")
  a1, a2 = a1 or 1, a2 or a1 or 1
  gmesh:setVertices({
    { x, y, 0, 0, c1[1], c1[2], c1[3], a1 }, { x + w, y, 0, 0, c1[1], c1[2], c1[3], a1 },
    { x + w, y + h, 0, 0, c2[1], c2[2], c2[3], a2 }, { x, y + h, 0, 0, c2[1], c2[2], c2[3], a2 },
  })
  lg.setColor(1, 1, 1, 1)
  lg.draw(gmesh)
end

-- Fond uni, à peine teinté par la pochette
function T.background(tint, t)
  local top = T.mix(T.c.bg, tint, T.dark and 0.14 or 0.10)
  T.gradV(0, 0, T.W, T.H, top, T.c.bg)
end

---------------------------------------------------------------- icônes
local function rpoly(pts, r)
  lg.polygon("fill", pts)
  lg.setLineWidth(r * 2)
  lg.setLineJoin("bevel")
  lg.polygon("line", pts)
  for i = 1, #pts, 2 do lg.circle("fill", pts[i], pts[i + 1], r, 12) end
end
local function rrect(x, y, w, h, r) lg.rectangle("fill", x, y, w, h, r, r, 10) end

local curves
local I = {}
function I.play() rpoly({ -0.24, -0.34, 0.36, 0, -0.24, 0.34 }, 0.07) end
function I.pause() rrect(-0.30, -0.36, 0.22, 0.72, 0.09); rrect(0.08, -0.36, 0.22, 0.72, 0.09) end
function I.next() rpoly({ -0.36, -0.30, 0.10, 0, -0.36, 0.30 }, 0.06); rrect(0.18, -0.36, 0.17, 0.72, 0.07) end
function I.prev() lg.scale(-1, 1); I.next() end
function I.shuffle()
  curves = curves or {
    love.math.newBezierCurve(-0.46, -0.24, -0.04, -0.24, 0.04, 0.24, 0.24, 0.24):render(4),
    love.math.newBezierCurve(-0.46, 0.24, -0.04, 0.24, 0.04, -0.24, 0.24, -0.24):render(4),
  }
  lg.setLineWidth(0.09); lg.setLineJoin("bevel")
  lg.line(curves[1]); lg.line(curves[2])
  lg.polygon("fill", 0.20, 0.10, 0.46, 0.24, 0.20, 0.38)
  lg.polygon("fill", 0.20, -0.38, 0.46, -0.24, 0.20, -0.10)
end
function I.repeat_()
  lg.setLineWidth(0.09); lg.setLineJoin("bevel")
  lg.line(-0.40, 0.06, -0.40, -0.12, -0.34, -0.24, -0.22, -0.28, 0.16, -0.28)
  lg.polygon("fill", 0.14, -0.42, 0.40, -0.28, 0.14, -0.14)
  lg.line(0.40, -0.06, 0.40, 0.12, 0.34, 0.24, 0.22, 0.28, -0.16, 0.28)
  lg.polygon("fill", -0.14, 0.14, -0.40, 0.28, -0.14, 0.42)
end
function I.one()
  lg.setLineWidth(0.08)
  lg.line(0.0, -0.13, 0.0, 0.13); lg.line(-0.07, -0.07, 0.0, -0.13)
end
function I.speaker(level)
  lg.polygon("fill", -0.46, -0.14, -0.28, -0.14, -0.02, -0.38, -0.02, 0.38, -0.28, 0.14, -0.46, 0.14)
  lg.setLineWidth(0.075)
  if level >= 1 then lg.arc("line", "open", 0.0, 0, 0.2, -0.85, 0.85, 12) end
  if level >= 2 then lg.arc("line", "open", 0.0, 0, 0.4, -0.85, 0.85, 14) end
  if level <= 0 then lg.line(0.14, -0.14, 0.40, 0.14); lg.line(0.14, 0.14, 0.40, -0.14) end
end
function I.grid()
  for _, p in ipairs({ { -0.44, -0.44 }, { 0.06, -0.44 }, { -0.44, 0.06 }, { 0.06, 0.06 } }) do
    rrect(p[1], p[2], 0.38, 0.38, 0.1)
  end
end
function I.list()
  for _, y in ipairs({ -0.34, 0, 0.34 }) do
    lg.circle("fill", -0.38, y, 0.075, 10)
    rrect(-0.2, y - 0.06, 0.66, 0.12, 0.06)
  end
end
function I.note()
  lg.ellipse("fill", -0.22, 0.28, 0.17, 0.13)
  lg.ellipse("fill", 0.26, 0.18, 0.17, 0.13)
  lg.setLineWidth(0.075)
  lg.line(-0.07, 0.27, -0.07, -0.32); lg.line(0.41, 0.17, 0.41, -0.42)
  lg.polygon("fill", -0.10, -0.36, 0.44, -0.48, 0.44, -0.28, -0.10, -0.16)
end
function I.chevron()
  lg.setLineWidth(0.12); lg.setLineJoin("bevel")
  lg.line(-0.12, -0.30, 0.16, 0, -0.12, 0.30)
end
function I.back() lg.scale(-1, 1); I.chevron() end
function I.gear()
  for k = 0, 7 do
    lg.push(); lg.rotate(k * math.pi / 4)
    rrect(-0.08, -0.46, 0.16, 0.2, 0.04)
    lg.pop()
  end
  lg.setLineWidth(0.17)
  lg.circle("line", 0, 0, 0.24, 24)
end
function I.heart()
  lg.circle("fill", -0.2, -0.1, 0.235, 20)
  lg.circle("fill", 0.2, -0.1, 0.235, 20)
  lg.polygon("fill", -0.425, -0.02, 0.425, -0.02, 0, 0.42)
end
function I.star()
  local pts = {}
  for k = 0, 9 do
    local ang = -math.pi / 2 + k * math.pi / 5
    local r = (k % 2 == 0) and 0.48 or 0.2
    pts[#pts + 1] = math.cos(ang) * r
    pts[#pts + 1] = math.sin(ang) * r + 0.03
  end
  -- polygone concave : on le découpe en triangles depuis le centre
  for k = 0, 9 do
    local i, j = k * 2 + 1, ((k + 1) % 10) * 2 + 1
    lg.polygon("fill", 0, 0.03, pts[i], pts[i + 1], pts[j], pts[j + 1])
  end
end
function I.check()
  lg.setLineWidth(0.14); lg.setLineJoin("bevel")
  lg.line(-0.26, 0.02, -0.07, 0.21, 0.28, -0.18)
end
function I.refresh()
  lg.setLineWidth(0.1)
  lg.arc("line", "open", 0, 0, 0.32, 0.6, 5.5, 20)
  lg.polygon("fill", 0.18, -0.46, 0.46, -0.22, 0.12, -0.12)
end

function T.icon(name, cx, cy, s, color, a, arg)
  lg.push()
  lg.translate(cx, cy)
  lg.scale(s, s)
  T.set(color, a)
  I[name](arg)
  lg.pop()
end

---------------------------------------------------------------- éléments mignons
-- Barres d'égaliseur animées
function T.eq(x, y, w, h, t, color, a, active)
  local bw = w / 5
  T.set(color, a)
  for i = 0, 2 do
    local k = active and (0.45 + 0.55 * (math.sin(t * (7 + i * 2.3) + i * 1.7) * 0.5 + 0.5)) or 0.35
    local bh = h * k
    T.rr("fill", x + i * bw * 2, y + h - bh, bw, bh, bw / 2)
  end
end

-- Pastille de bouton (A, B, L1…)
function T.keycap(x, y, label, color)
  local f = T.f.tiny
  local w = math.max(20, f:getWidth(label) + 12)
  T.set(T.c.cap)
  T.rr("fill", x, y, w, 20, 10)
  local ln = T.c.line
  lg.setColor(ln[1], ln[2], ln[3], ln[4]); lg.setLineWidth(1); T.rr("line", x + 0.5, y + 0.5, w - 1, 19, 10)
  T.text(f, label, x, y + 2, color or T.c.ink2, 1, "center", w)
  return w
end

-- Mélo, la petite mascotte avec son casque
function T.mascot(cx, cy, r, t, col, mood)
  col = col or T.palette[4]
  local bob = math.sin(t * 3) * r * 0.05
  cy = cy + bob
  lg.setColor(0, 0, 0, 0.08)
  lg.ellipse("fill", cx, cy + r * 1.08, r * 0.8, r * 0.14, 24)
  -- casque (arceau derrière)
  lg.setLineWidth(r * 0.16)
  T.set(T.darken(col, 0.35))
  lg.arc("line", "open", cx, cy, r * 1.04, math.pi * 1.1, math.pi * 1.9, 24)
  -- corps
  T.set(col); lg.circle("fill", cx, cy, r, 48)
  T.set(T.lighten(col, 0.55), 0.45); lg.circle("fill", cx - r * 0.3, cy - r * 0.38, r * 0.32, 24)
  -- oreillettes
  T.set(T.darken(col, 0.35))
  T.rr("fill", cx - r * 1.16, cy - r * 0.3, r * 0.26, r * 0.62, r * 0.12)
  T.rr("fill", cx + r * 0.90, cy - r * 0.3, r * 0.26, r * 0.62, r * 0.12)
  -- yeux
  local blink = (t % 3.6) > 3.45
  local ey = blink and r * 0.025 or r * 0.13
  lg.setColor(0.12, 0.1, 0.18)
  lg.ellipse("fill", cx - r * 0.32, cy - r * 0.04, r * 0.09, ey, 16)
  lg.ellipse("fill", cx + r * 0.32, cy - r * 0.04, r * 0.09, ey, 16)
  if not blink then
    lg.setColor(1, 1, 1, 0.9)
    lg.circle("fill", cx - r * 0.29, cy - r * 0.09, r * 0.03, 8)
    lg.circle("fill", cx + r * 0.35, cy - r * 0.09, r * 0.03, 8)
  end
  -- joues
  lg.setColor(1, 0.55, 0.65, 0.55)
  lg.circle("fill", cx - r * 0.54, cy + r * 0.2, r * 0.12, 16)
  lg.circle("fill", cx + r * 0.54, cy + r * 0.2, r * 0.12, 16)
  -- bouche
  if mood == "open" then
    lg.setColor(0.12, 0.1, 0.18)
    lg.arc("fill", "closed", cx, cy + r * 0.12, r * 0.2, 0.1, math.pi - 0.1, 16)
    lg.setColor(1, 0.5, 0.6)
    lg.arc("fill", "closed", cx, cy + r * 0.26, r * 0.1, math.pi + 0.3, 2 * math.pi - 0.3, 10)
  else
    lg.setColor(0.12, 0.1, 0.18)
    lg.setLineWidth(r * 0.07)
    lg.arc("line", "open", cx, cy + r * 0.1, r * 0.2, 0.3, math.pi - 0.3, 16)
  end
end

return T
