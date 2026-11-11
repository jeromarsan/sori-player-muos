-- Éléments d'interface partagés : mini-lecteur, aide des boutons, toast de volume.
local T = require("theme")
local C = require("covers")
local App = require("app")
local lg = love.graphics
local W = {}

local function dpadIcon(x, y, mode)
  T.set(T.c.cap)
  T.rr("fill", x, y, 24, 20, 10)
  T.set(T.c.ink2)
  local cx, cy = x + 12, y + 10
  if mode ~= "ud" then T.rr("fill", cx - 8, cy - 1.5, 16, 3, 1.5) end
  if mode ~= "lr" then T.rr("fill", cx - 1.5, cy - 7, 3, 14, 1.5) end
  return 24
end

local function cap(x, y, key)
  if key == "dpad" then return dpadIcon(x, y) end
  if key == "lr" then return dpadIcon(x, y, "lr") end
  if key == "ud" then return dpadIcon(x, y, "ud") end
  return T.keycap(x, y, key)
end
W.cap = cap

-- Ligne d'aide en bas : { {"A","Ouvrir"}, ... }
function W.hints(list)
  local f, gap, total, widths
  -- on resserre (puis on réduit la police) si les textes traduits sont trop longs
  for _, try in ipairs({ { T.f.small, 16 }, { T.f.small, 9 }, { T.f.tiny, 8 } }) do
    f, gap, total, widths = try[1], try[2], 0, {}
    for i, h in ipairs(list) do
      local kw = (h[1] == "dpad" or h[1] == "lr" or h[1] == "ud") and 24 or math.max(20, T.f.tiny:getWidth(h[1]) + 12)
      widths[i] = kw + 6 + f:getWidth(h[2])
      total = total + widths[i]
    end
    total = total + gap * (#list - 1)
    if total <= T.W - 24 then break end
  end
  local x, y = (T.W - total) / 2, 456
  for i, h in ipairs(list) do
    local kw = cap(x, y, h[1])
    T.text(f, h[2], x + kw + 6, y - 1, T.c.ink2)
    x = x + widths[i] + gap
  end
end

-- Petit logo SORI PLAYER (les barres bougent pendant la lecture). Renvoie le bord droit.
function W.logo(x, cy)
  local BW, GAP, MAXH = 4, 3, 30
  local n = #T.LOGO_H
  local playing = App.player and App.player.state == "playing"
  for i, h in ipairs(T.LOGO_H) do
    local wave = playing and (0.80 + 0.20 * math.sin(App.t * 5 + i * 0.9)) or 1
    local bh = math.max(BW, MAXH * h * wave)
    T.set(T.logoColor((i - 1) / (n - 1)))
    T.rr("fill", x + (i - 1) * (BW + GAP), cy + 3 - bh / 2, BW, bh, BW / 2)
  end
  local tx = x + n * BW + (n - 1) * GAP + 9
  local fb = T.f.logo
  local ww = fb:getWidth("SORI")
  T.text(fb, "SORI", tx, cy + 5 - fb:getBaseline(), T.c.ink)
  T.set(T.c.ink2)
  T.spaced(T.f.logoSub, "PLAYER", tx + 1, cy + 8, ww - 2)
  return tx + ww
end

-- En-tête commun : logo + fil d'Ariane (liste de noms) + ligne d'info facultative.
-- right = limite droite (pour laisser la place à des boutons)
function W.header(crumbs, sub, right)
  right = right or (T.W - 28)
  local lx = W.logo(28, 32)
  local ln = T.c.line
  lg.setColor(ln[1], ln[2], ln[3], math.min(1, ln[4] * 2.5))
  lg.rectangle("fill", lx + 14, 16, 1.5, 34)
  local cx = lx + 29
  local avail = right - cx
  local f = T.f.body
  local SEP = "  ›  "
  local sepW, ellW = f:getWidth(SEP), f:getWidth("…")
  -- on retire les premiers niveaux tant que ça ne rentre pas
  local items, lead = {}, false
  for i, v in ipairs(crumbs) do items[i] = v end
  local function width()
    local w = lead and (ellW + sepW) or 0
    for i, v in ipairs(items) do w = w + f:getWidth(v) + (i < #items and sepW or 0) end
    return w
  end
  while #items > 1 and width() > avail do table.remove(items, 1); lead = true end
  local y = sub and 13 or 22
  local px = cx
  if lead then
    T.text(f, "…" .. SEP, px, y, T.c.ink3); px = px + ellW + sepW
  end
  for i, v in ipairs(items) do
    if i < #items then
      T.text(f, v, px, y, T.c.ink2); px = px + f:getWidth(v)
      T.text(f, SEP, px, y, T.c.ink3); px = px + sepW
    else
      T.marquee(f, v, px, y, right - px, T.c.ink, 1, "crumb")
    end
  end
  if sub then T.text(T.f.small, T.fit(T.f.small, sub, avail), cx, 39, T.c.ink3) end
end

-- Mini-lecteur flottant
function W.mini(t)
  local P = App.player
  local cur = P.current
  if not cur then return end
  local x, y, w, h = 28, 396, 584, 56
  local album = cur.album
  local tint = album and album.tint or T.palette[4]
  T.shadow(x, y, w, h, 28, 12, 0.16, 5)
  T.set(T.c.surface, 0.97)
  T.rr("fill", x, y, w, h, 28)
  if album then C.draw(album, x + 8, y + 8, 40) end
  local tw = w - 60 - 124
  T.marquee(T.f.h2, cur.t, x + 60, y + 5, tw, T.c.ink, 1, "mini_t")
  T.marquee(T.f.small, (cur.ar ~= "" and cur.ar) or (album and album.title) or "", x + 60, y + 30, tw, T.c.ink2, 1, "mini_a")
  -- égaliseur
  T.eq(x + w - 150, y + 19, 18, 18, t, tint, 1, P.state == "playing")
  -- suivant
  T.icon("next", x + w - 82, y + h / 2, 22, T.c.ink, 0.85)
  -- play/pause avec anneau de progression
  local bx, by = x + w - 34, y + h / 2
  lg.setColor(tint[1], tint[2], tint[3], 0.22)
  lg.setLineWidth(3)
  lg.circle("line", bx, by, 22, 32)
  local p = P:progress()
  if p > 0.005 then
    T.set(tint)
    lg.arc("line", "open", bx, by, 22, -math.pi / 2, -math.pi / 2 + p * math.pi * 2, 40)
  end
  T.set(tint); lg.circle("fill", bx, by, 17, 28)
  T.icon(P.state == "playing" and "pause" or "play", bx + (P.state == "playing" and 0 or 1), by, 22, T.c.white)
end

-- Petit bandeau de volume
function W.toast()
  local ts = App.toast
  if not ts then return end
  local a = T.clamp(ts.life / 0.25, 0, 1)
  -- favori ajouté / retiré : cœur + texte
  if ts.kind == "fav" then
    local I = require("i18n")
    local txt = I.t(ts.value and "fav_added" or "fav_removed")
    local f = T.f.body
    local w, h = f:getWidth(txt) + 66, 44
    local x, y = (T.W - w) / 2, 14 - (1 - a) * 20
    T.shadow(x, y, w, h, 22, 10, 0.18 * a, 4)
    T.set(T.c.surface, 0.97 * a)
    T.rr("fill", x, y, w, h, 22)
    T.icon("heart", x + 28, y + h / 2, 24, ts.value and T.palette[6] or T.c.ink3, a)
    T.text(f, txt, x + 48, y + 9, T.c.ink, a)
    return
  end
  local w, h = 190, 44
  local x, y = (T.W - w) / 2, 14 - (1 - a) * 20
  T.shadow(x, y, w, h, 22, 10, 0.18 * a, 4)
  T.set(T.c.surface, 0.97 * a)
  T.rr("fill", x, y, w, h, 22)
  local v = ts.value
  T.icon("speaker", x + 26, y + h / 2, 22, T.c.ink, a, v <= 0.001 and 0 or (v < 0.5 and 1 or 2))
  T.track(a)
  T.rr("fill", x + 50, y + h / 2 - 5, 120, 10, 5)
  local cur = App.player.current
  local tint = T.accentFor(cur and cur.album)
  lg.setColor(tint[1], tint[2], tint[3], a)
  T.rr("fill", x + 50, y + h / 2 - 5, math.max(10, 120 * v), 10, 5)
end

return W
