-- Écran de démarrage : logo "SORI PLAYER" (barres d'onde en dégradé) + numéro de version.
local T = require("theme")
local App = require("app")
local lg = love.graphics

local S = { t = 0, done = false }

local DUR = 2.6   -- durée totale (s), un bouton permet de passer
local FADE = 0.4  -- fondu de sortie

-- mêmes barres et dégradé que le petit logo de l'en-tête (theme.lua)
local HEIGHTS = T.LOGO_H
local grad = T.logoColor
local spaced = T.spaced
local BW, GAP, MAXH = 8, 8, 140

local fBig, fSub

local function finish()
  if S.done then return end
  S.done = true
  App.name, App.stack = nil, {} -- pas de retour possible vers le logo
  App.go("albums")
end

function S.enter()
  S.t, S.done = 0, false
  if not fBig then
    fBig = lg.newFont("assets/Nunito-Black.ttf", 80)
    fSub = lg.newFont("assets/Nunito-ExtraBold.ttf", 17)
    fBig:setFilter("linear", "linear"); fSub:setFilter("linear", "linear")
  end
end

function S.update(dt)
  S.t = S.t + dt
  if S.t >= DUR then finish() end
end

function S.action(a)
  if S.t > 0.3 then finish() end
  return true
end

function S.draw()
  local t = S.t
  -- fond bleu nuit qui se fond dans le fond de l'app
  T.gradV(0, 0, T.W, T.H, { 0.075, 0.085, 0.22 }, T.c.bg)

  local n = #HEIGHTS
  local barsW = n * BW + (n - 1) * GAP
  local word = "SORI"
  local tw = fBig:getWidth(word)
  local gap = 30
  local x0 = (T.W - (barsW + gap + tw)) / 2
  local cy = T.H / 2 - 12

  -- barres
  for i, hgt in ipairs(HEIGHTS) do
    local col = grad((i - 1) / (n - 1))
    local x = x0 + (i - 1) * (BW + GAP)
    local k = T.ease((t - 0.05 * i) / 0.55)
    local gh = MAXH * math.min(1, hgt + 0.25) * k
    T.set(col, 0.13); T.rr("fill", x, cy - gh / 2, BW, gh, BW / 2)
    local wave = 0.88 + 0.12 * math.sin(t * 3.2 + i * 0.8)
    local h = math.max(BW, MAXH * hgt * wave * k)
    T.set(col, k); T.rr("fill", x, cy - h / 2, BW, h, BW / 2)
  end

  -- SORI / PLAYER
  local a = T.ease((t - 0.45) / 0.5)
  local tx = x0 + barsW + gap - (1 - a) * 16
  local ty = cy + 8 - fBig:getBaseline()
  T.text(fBig, word, tx, ty, T.c.white, a)
  T.set({ 0.80, 0.82, 0.94 }, a)
  spaced(fSub, "PLAYER", tx + 3, cy + 18, tw - 6)

  -- version
  T.text(T.f.small, "v" .. App.VERSION, 0, T.H - 30, T.c.ink3, T.ease(t / 0.6), "right", T.W - 20)

  -- fondu de sortie
  local out = T.clamp((t - (DUR - FADE)) / FADE, 0, 1)
  if out > 0 then T.set(T.c.bg, out); lg.rectangle("fill", 0, 0, T.W, T.H) end
end

return S
