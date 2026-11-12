-- Réglages : thème, couleur principale, langue, affichage, albums/artistes, bibliothèque, aide.
-- Appliqués en direct et enregistrés.
local T = require("theme")
local W = require("widgets")
local App = require("app")
local I = require("i18n")
local lg = love.graphics

local S = { sel = 1, t = 0, dt = 0, k = {} }

local X, CW = 28, 584
local ROW_Y0, ROW_H, ROW_GAP = 66, 50, 4
local NROWS = 7
local function rowY(i) return ROW_Y0 + (i - 1) * (ROW_H + ROW_GAP) end

local function accentIndex()
  for i, c in ipairs(T.accentChoices) do if c.id == T.accentName then return i end end
  return 0 -- couleur personnalisée (#RRGGBB dans sori.cfg)
end

local function langIndex()
  for i, c in ipairs(I.choices) do if c.id == I.choice then return i end end
  return 1
end

local function apply()
  lg.setBackgroundColor(T.c.bg)
  App.saveSettings()
end

local function setTheme(id)
  if id ~= T.themeName then T.setTheme(id); apply() end
end

local function stepAccent(d)
  local n = #T.accentChoices
  local i = accentIndex()
  if i == 0 then i = (d > 0) and 1 or n else i = (i - 1 + d) % n + 1 end
  T.setAccent(T.accentChoices[i].id)
  apply()
end

local function stepLang(d)
  local n = #I.choices
  I.set(I.choices[(langIndex() - 1 + d) % n + 1].id)
  App.lib.relabel()
  apply()
end

local function setMode(m)
  local A = App.screens.albums
  if A.mode ~= m then A.setMode(m) end
end

local function setView(v)
  local A = App.screens.albums
  if A.view ~= v then A.setView(v) end
end

function S.enter(args)
  if not args.back then S.sel = 1 end
end

function S.update(dt) S.t, S.dt = S.t + dt, dt end

function S.action(a)
  local change = (a == "left" or a == "right" or a == "a")
  local d = (a == "left") and -1 or 1
  local s = S.sel
  if a == "up" then S.sel = math.max(1, s - 1)
  elseif a == "down" then S.sel = math.min(NROWS, s + 1)
  elseif a == "b" or a == "select" then App.back()
  elseif change and s == 1 then
    if a == "left" then setTheme("sombre")
    elseif a == "right" then setTheme("clair")
    else setTheme(T.themeName == "sombre" and "clair" or "sombre") end
  elseif change and s == 2 then stepAccent(d)
  elseif change and s == 3 then stepLang(d)
  elseif change and s == 4 then
    local A = App.screens.albums
    if a == "left" then setView("grid")
    elseif a == "right" then setView("list")
    else setView(A.view == "grid" and "list" or "grid") end
  elseif change and s == 5 then
    local A = App.screens.albums
    if a == "left" then setMode("albums")
    elseif a == "right" then setMode("artists")
    else setMode(A.mode == "artists" and "albums" or "artists") end
  elseif a == "a" and s == 6 then
    if App.lib.state ~= "scanning" then App.rescan() end
  elseif (a == "a" or a == "right") and s == 7 then
    App.go("help")
  else return false end
  return true
end

-- carte d'un réglage : titre + sous-titre à gauche, contour couleur si sélectionnée
local function card(i, title, sub, accent, ctrlW)
  local y = rowY(i)
  local k = T.damp(S.k[i] or 0, (S.sel == i) and 1 or 0, 16, S.dt)
  S.k[i] = k
  if k > 0.02 then T.shadow(X, y, CW, ROW_H, 22, 8 + 8 * k, 0.12 * k + 0.04, 4) end
  T.set(T.c.surface, 0.7 + 0.3 * k)
  T.rr("fill", X, y, CW, ROW_H, 22)
  if k > 0.02 then
    lg.setLineWidth(3); T.set(accent, k)
    T.rr("line", X + 1.5, y + 1.5, CW - 3, ROW_H - 3, 21)
  end
  local lw = CW - 20 - ctrlW - 36
  local hasSub = sub and sub ~= ""
  local ty = hasSub and (y + 3) or (y + (ROW_H - T.f.h2:getHeight()) / 2) -- titre seul : centré
  T.text(T.f.h2, T.fit(T.f.h2, title, lw), X + 20, ty, T.c.ink)
  if sub and sub ~= "" then T.marquee(T.f.small, sub, X + 20, y + 28, lw, T.c.ink3, 1, (S.sel == i) and ("set_sub" .. i) or nil) end
  return y
end

-- interrupteur à deux choix, aligné à droite
local function segmented(y, labels, on, accent)
  local sw, sh = 220, 34
  local sx, sy = X + CW - 20 - sw, y + (ROW_H - sh) / 2
  T.track(); T.rr("fill", sx, sy, sw, sh, sh / 2)
  T.set(accent); T.rr("fill", sx + 3 + (on - 1) * sw / 2, sy + 3, sw / 2 - 6, sh - 6, (sh - 6) / 2)
  for i, l in ipairs(labels) do
    T.text(T.f.body, T.fit(T.f.body, l, sw / 2 - 12), sx + (i - 1) * sw / 2, sy + 6, i == on and T.c.white or T.c.ink2, 1, "center", sw / 2)
  end
  return sw
end

-- pastille "Pochette" : cercle en 4 quartiers de couleurs
local function albumSwatch(cx, cy, rad)
  local cols = { T.palette[1], T.palette[2], T.palette[3], T.palette[5] }
  for q = 1, 4 do
    T.set(cols[q])
    local a0 = -math.pi / 2 + (q - 1) * math.pi / 2
    lg.arc("fill", "pie", cx, cy, rad, a0, a0 + math.pi / 2, 12)
  end
end

function S.draw()
  local accent = T.accentFor(nil)
  T.background(accent, S.t)
  W.header({ I.t("settings") }, "Sori Player  ·  v" .. App.VERSION)

  -- 1. Thème
  local y = card(1, I.t("theme"), nil, accent, 220)
  segmented(y, { I.t("dark"), I.t("light") }, T.themeName == "clair" and 2 or 1, accent)

  -- 2. Couleur principale
  local cur = accentIndex()
  local name
  if cur == 0 then name = I.t("custom") .. " " .. T.accentName
  else
    name = I.t("c_" .. T.accentChoices[cur].id)
    if T.accentChoices[cur].id == "album" then name = name .. " " .. I.t("album_note") end
  end
  local rad, step = 13, 36
  local swW = (#T.accentChoices - 1) * step + rad * 2
  y = card(2, I.t("accent"), name, accent, swW)
  local x0 = X + CW - 20 - swW + rad
  local cy = y + ROW_H / 2
  for i, c in ipairs(T.accentChoices) do
    local cx = x0 + (i - 1) * step
    local col = T.accentColor(c.id)
    if i == cur then
      T.set(col or T.c.ink2); lg.setLineWidth(2.5); lg.circle("line", cx, cy, rad + 4, 28)
    end
    if col then T.set(col); lg.circle("fill", cx, cy, rad, 28) else albumSwatch(cx, cy, rad) end
    if i == cur then T.icon("check", cx, cy, 18, T.c.white) end
  end

  -- 3. Langue : ‹ valeur ›
  local lw = 240
  y = card(3, I.t("language"), I.choice == "auto" and I.label(I.lang) or nil, accent, lw)
  local lx, ly = X + CW - 20 - lw, y + ROW_H / 2
  T.icon("back", lx + 10, ly, 20, accent)
  T.text(T.f.body, T.fit(T.f.body, I.label(I.choice), lw - 52), lx + 26, ly - 12, T.c.ink, 1, "center", lw - 52)
  T.icon("chevron", lx + lw - 10, ly, 20, accent)

  -- 4. Affichage des albums
  y = card(4, I.t("view"), nil, accent, 220)
  segmented(y, { I.t("h_grid"), I.t("h_list") }, App.screens.albums.view == "list" and 2 or 1, accent)

  -- 5. Afficher par : albums / artistes
  y = card(5, I.t("by_label"), nil, accent, 220)
  segmented(y, { I.t("by_albums"), I.t("by_artists") }, App.screens.albums.mode == "artists" and 2 or 1, accent)

  -- 6. Bibliothèque : dossier + nombre de morceaux, A = rechercher
  local lib = App.lib
  local info = table.concat(App.roots, "  ·  ") .. "  ·  " .. I.n("tracks", #lib.tracks)
  if lib.state == "scanning" then info = I.t("still_scanning", lib.count) end
  local btn = I.t("rescan")
  local bw = T.f.small:getWidth(btn) + 52
  y = card(6, I.t("library"), info, accent, bw)
  local bx, by, bh = X + CW - 20 - bw, y + (ROW_H - 34) / 2, 34
  T.set(accent, lib.state == "scanning" and 0.5 or 1); T.rr("fill", bx, by, bw, bh, bh / 2)
  T.keycap(bx + 7, by + 7, "A")
  T.text(T.f.small, btn, bx + 34, by + 7, T.c.white)

  -- 7. Aide et raccourcis : A = ouvrir
  y = card(7, I.t("help"), I.t("help_sub"), accent, 40)
  T.set(accent); lg.circle("fill", X + CW - 20 - 18, y + ROW_H / 2, 17, 28)
  T.icon("chevron", X + CW - 20 - 17, y + ROW_H / 2, 20, T.c.white)

  W.hints({ { "ud", I.t("h_choose") }, { "lr", I.t("h_change") }, { "B", I.t("h_back") } })
end

return S
