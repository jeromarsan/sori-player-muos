-- Aide : ce qu'on peut faire dans l'appli + tous les raccourcis, par écran.
-- Ouvert depuis Réglages > Aide et raccourcis. Haut/Bas = défiler, B = retour.
local T = require("theme")
local W = require("widgets")
local App = require("app")
local I = require("i18n")
local lg = love.graphics

local S = { scroll = 0, target = 0, t = 0, dt = 0, lang = nil, cards = nil, total = 0 }

local X, CW = 28, 584
local VT, VB = 74, 444          -- zone qui défile
local PAD, GAP = 16, 12         -- marge intérieure des cartes, espace entre cartes
local KEYW = 150                -- colonne des boutons
local LINE = 24                 -- hauteur d'une ligne de texte

-- Contenu. Boutons : "L1 / R1" = l'un ou l'autre, "L1 + R1" = ensemble,
-- "dpad" / "lr" / "ud" = croix directionnelle, "*" = n'importe quel bouton.
local CONTENT = {
  { "hs_features", { { "txt", "hf_1" }, { "txt", "hf_2" }, { "txt", "hf_3" }, { "txt", "hf_4" },
                     { "txt", "hf_5" }, { "txt", "hf_6" }, { "txt", "hf_7" } } },
  { "hs_everywhere", { { "key", "L1 / R1", "k_prevnext" }, { "key", "L1 + R1", "k_shuffle_all" },
                       { "key", "L2 / R2", "k_volume" }, { "key", "Menu", "k_screen_off" },
                       { "key", "Menu + Start", "k_quit" } } },
  { "hs_albums", { { "key", "dpad", "k_move" }, { "key", "A", "k_open" }, { "key", "X", "k_shuffle_all" },
                   { "key", "Y", "k_fav_album" }, { "key", "Start", "k_now" }, { "key", "Select", "k_settings" } } },
  { "hs_album", { { "key", "ud", "k_move" }, { "key", "A", "k_play" }, { "key", "X", "k_shuffle_album" },
                  { "key", "Y", "k_fav_track" }, { "key", "Start", "k_now" }, { "key", "B", "k_back" } } },
  { "hs_now", { { "key", "A", "k_pause" }, { "key", "X", "k_shuffle_toggle" }, { "key", "Y", "k_fav_now" },
                { "key", "Select", "k_repeat" }, { "key", "lr", "k_seek" }, { "key", "ud", "k_volume" },
                { "key", "B", "k_back" } } },
  { "hs_screen", { { "key", "*", "k_wake" }, { "txt", "hf_screen" }, { "txt", "hf_power" } } },
}

local function wrapCount(font, text, w)
  local _, lines = font:getWrap(text, w)
  return math.max(1, #lines)
end

-- Mise en page (recalculée si la langue change)
local function layout()
  local cards, y = {}, 0
  local fb = T.f.body
  for _, sec in ipairs(CONTENT) do
    local card = { title = I.t(sec[1]), y = y, rows = {} }
    local cy = PAD + 30
    for _, it in ipairs(sec[2]) do
      local row = { kind = it[1], y = cy }
      if it[1] == "txt" then
        row.text = I.t(it[2])
        row.h = wrapCount(fb, row.text, CW - 2 * PAD - 18) * LINE + 6
      else
        row.keys = it[2]
        row.text = I.t(it[3])
        row.h = math.max(34, wrapCount(fb, row.text, CW - 2 * PAD - KEYW) * LINE + 8)
      end
      cy = cy + row.h
      card.rows[#card.rows + 1] = row
    end
    card.h = cy + PAD - 6
    cards[#cards + 1] = card
    y = y + card.h + GAP
  end
  S.cards, S.total, S.lang = cards, y - GAP, I.lang
end

local function maxScroll() return math.max(0, S.total - (VB - VT) + 8) end

function S.enter(args)
  if not args.back then S.scroll, S.target = 0, 0 end
  S.lang = nil
end

function S.update(dt)
  S.t, S.dt = S.t + dt, dt
  if S.lang ~= I.lang then layout() end
  S.scroll = T.damp(S.scroll, S.target, 14, dt)
end

function S.action(a)
  if a == "up" then S.target = math.max(0, S.target - 60)
  elseif a == "down" then S.target = math.min(maxScroll(), S.target + 60)
  elseif a == "left" then S.target = math.max(0, S.target - (VB - VT - 40))
  elseif a == "right" then S.target = math.min(maxScroll(), S.target + (VB - VT - 40))
  elseif a == "b" or a == "select" or a == "a" then App.back()
  else return false end
  return true
end

-- Dessine une combinaison de boutons ("L1 + R1", "L2 / R2", "dpad"...). Renvoie la largeur.
local function drawKeys(spec, x, y)
  local x0 = x
  for tok in spec:gmatch("%S+") do
    if tok == "/" or tok == "+" then
      T.text(T.f.small, tok, x + 2, y + 1, T.c.ink3)
      x = x + T.f.small:getWidth(tok) + 6
    elseif tok == "*" then
      x = x + T.keycap(x, y, I.t("key_any")) + 4
    else
      x = x + W.cap(x, y, tok) + 4
    end
  end
  return x - x0
end

function S.draw()
  local accent = T.accentFor(nil)
  T.background(accent, S.t)
  W.header({ I.t("settings"), I.t("help") }, "Sori Player  ·  v" .. App.VERSION)
  if not S.cards or S.lang ~= I.lang then layout() end

  App.scissor(0, VT, T.W, VB - VT)
  local fb = T.f.body
  for _, c in ipairs(S.cards) do
    local cy = VT + c.y - S.scroll
    if cy + c.h > VT - 10 and cy < VB + 10 then
      T.set(T.c.surface, 0.9)
      T.rr("fill", X, cy, CW, c.h, 22)
      -- titre de la partie
      T.set(accent); T.rr("fill", X + PAD, cy + PAD + 3, 5, 20, 2.5)
      T.text(T.f.h2, c.title, X + PAD + 14, cy + PAD - 2, T.c.ink)
      for _, r in ipairs(c.rows) do
        local ry = cy + r.y
        if r.kind == "txt" then
          T.set(accent); lg.circle("fill", X + PAD + 5, ry + LINE / 2 + 1, 3.5, 12)
          T.set(T.c.ink2)
          lg.setFont(fb)
          lg.printf(r.text, X + PAD + 18, ry, CW - 2 * PAD - 18, "left")
        else
          drawKeys(r.keys, X + PAD, ry + 5)
          T.set(T.c.ink)
          lg.setFont(fb)
          lg.printf(r.text, X + PAD + KEYW, ry + 2, CW - 2 * PAD - KEYW, "left")
        end
      end
    end
  end
  lg.setScissor()

  -- barre de défilement
  local ms = maxScroll()
  if ms > 0 then
    local trackH = VB - VT - 8
    local barH = math.max(30, trackH * (VB - VT) / (S.total + 8))
    local by = VT + 4 + (trackH - barH) * (S.scroll / ms)
    T.set(T.c.ink3, 0.35); T.rr("fill", T.W - 12, VT + 4, 4, trackH, 2)
    T.set(accent); T.rr("fill", T.W - 12, by, 4, barH, 2)
  end

  W.hints({ { "ud", I.t("h_scroll") }, { "B", I.t("h_back") } })
end

return S
