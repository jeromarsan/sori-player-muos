-- Les morceaux d'un album (toujours en liste).
local T = require("theme")
local C = require("covers")
local W = require("widgets")
local App = require("app")
local I = require("i18n")
local Favs = require("favs")
local lg = love.graphics

local S = { album = nil, sel = 0, scroll = 0, scrollTarget = 0, t = 0, dt = 0, kmap = {}, bg = { 0.29, 0.62, 1.0 } }

local VT = 140
local ROW_H, ROW_P = 52, 60
local PLAY_H = 58

function S.enter(args)
  if args.back then return end
  S.album = args.album
  S.sel, S.scroll, S.scrollTarget = 0, 0, 0
  S.kmap = {}
  local P = App.player
  -- si cet album est déjà en lecture, on se place sur le morceau en cours
  if P.current and P.current.album == S.album then S.sel = P.current.i or 0 end
  local tint = S.album.tint or T.palette[4]
  for i = 1, 3 do S.bg[i] = tint[i] end
end

-- position verticale (relative au haut de la liste) de l'élément i (0 = bouton Lire)
local function bounds(i)
  if i == 0 then return 0, PLAY_H end
  local top = PLAY_H + 10 + (i - 1) * ROW_P
  return top, top + ROW_H
end

function S.update(dt)
  S.t, S.dt = S.t + dt, dt
  local a = S.album
  if not a then return end
  -- liste Favoris modifiée ailleurs (ex. depuis l'écran de lecture)
  if a.fav and App.lib.favVersion ~= Favs.version then
    App.lib.refreshFavs()
    S.sel = math.min(S.sel, #a.tracks); S.kmap = {}
  end
  local top, bot = bounds(S.sel)
  local viewH = App.viewBottom() - VT
  local tgt = S.scrollTarget
  if top < tgt then tgt = top end
  if bot + 8 > tgt + viewH then tgt = bot + 8 - viewH end
  S.scrollTarget = math.max(0, tgt)
  S.scroll = T.damp(S.scroll, S.scrollTarget, 14, dt)
  local tint = a.tint or T.palette[4]
  for i = 1, 3 do S.bg[i] = T.damp(S.bg[i], tint[i], 5, dt) end
  C.want(a, 0)
end

function S.action(a)
  local P = App.player
  local alb = S.album
  local n = #alb.tracks
  if a == "up" then S.sel = math.max(0, S.sel - 1)
  elseif a == "down" then S.sel = math.min(n, S.sel + 1)
  elseif a == "b" then App.back()
  elseif a == "a" then
    if n == 0 then return true end
    if S.sel == 0 then P:setQueue(alb.tracks, 1) else P:setQueue(alb.tracks, S.sel) end
    App.go("now")
  elseif a == "x" then
    if n == 0 then return true end
    P:setQueue(alb.tracks, love.math.random(n), true)
    App.go("now")
  elseif a == "y" then
    -- Y : favori (l'album entier sur la ligne "Écouter", sinon le morceau)
    if S.sel == 0 then
      if not alb.fav and not alb.noalbum then App.say("fav", Favs.toggleAlbum(alb)) end
    else
      App.say("fav", Favs.toggleTrack(alb.tracks[S.sel]))
      App.lib.refreshFavs()
      if alb.fav then S.sel = math.min(S.sel, #alb.tracks); S.kmap = {} end
    end
  elseif a == "start" then
    if P.current then App.go("now") end
  else return false end
  return true
end

local function playRow(y, k)
  local x, w, h = 28, 584, PLAY_H
  local tint = T.accentFor(S.album)
  local sc = 1 + 0.025 * k
  lg.push()
  lg.translate(x + w / 2, y + h / 2)
  lg.scale(sc)
  lg.translate(-w / 2, -h / 2)
  T.shadow(0, 0, w, h, 29, 8 + 10 * k, 0.12 + 0.14 * k, 5, T.darken(tint, 0.4))
  T.set(T.mix(tint, T.darken(tint, 0.12), 0.5 * (1 - k)))
  T.rr("fill", 0, 0, w, h, 29)
  lg.setColor(1, 1, 1, 0.16)
  T.rr("fill", 0, 0, w, h / 2, 29)
  T.set(T.c.white)
  lg.circle("fill", 32, h / 2, 19, 28)
  T.icon("play", 33, h / 2, 26, T.darken(tint, 0.15))
  T.text(T.f.h1, T.fit(T.f.h1, I.t("play_album"), w - 66 - 200), 66, 11, T.c.white)
  local hint = I.t("shuffle_hint")
  T.text(T.f.small, hint, w - 190, 19, T.c.white, 0.9, "right", 136)
  T.icon("shuffle", w - 30, h / 2, 22, T.c.white, 0.9)
  lg.pop()
end

local function trackRow(t, i, y, k, isCur, playing)
  local x, w, h = 28, 584, ROW_H
  local col = T.accentFor(S.album)
  local sc = 1 + 0.02 * k
  lg.push()
  lg.translate(x + w / 2, y + h / 2)
  lg.scale(sc)
  lg.translate(-w / 2, -h / 2)
  if k > 0.02 then T.shadow(0, 0, w, h, 22, 8 + 6 * k, 0.1 + 0.06 * k, 4) end
  T.set(T.c.surface, 0.6 + 0.4 * k)
  T.rr("fill", 0, 0, w, h, 22)
  if k > 0.02 then
    lg.setLineWidth(3)
    T.set(col, k)
    T.rr("line", 1.5, 1.5, w - 3, h - 3, 21)
  end
  -- pastille numérotée
  if isCur then
    T.set(col); lg.circle("fill", 34, h / 2, 18, 24)
    T.eq(34 - 8.5, h / 2 - 8, 17, 16, S.t, T.c.white, 1, playing)
  else
    T.set(col, 0.18); lg.circle("fill", 34, h / 2, 18, 24)
    T.text(T.f.h2, tostring(i), 16, h / 2 - 14, T.contrast(col, 0.3), 1, "center", 36)
  end
  -- dans la liste Favoris, on précise l'artiste
  local label = t.t
  if S.album.fav and t.ar and t.ar ~= "" then label = t.t .. "  ·  " .. t.ar end
  T.marquee(T.f.body, label, 66, h / 2 - 13, w - 70 - 90, isCur and T.contrast(col, 0.3) or T.c.ink, 1, k > 0.5 and "trk" or nil)
  if Favs.isTrack(t) then T.icon("heart", w - 66, h / 2, 18, T.palette[6]) end
  if k > 0.3 then
    T.set(col, k)
    lg.circle("fill", w - 30, h / 2, 15, 24)
    T.icon("play", w - 29, h / 2, 17, T.c.white, k)
  end
  lg.pop()
end

function S.draw()
  local a = S.album
  T.background(S.bg, S.t)
  local P = App.player
  local tint = a.tint or T.palette[4]

  -- en-tête : logo + fil d'Ariane, puis pochette + titre
  W.header(App.crumbs(a))
  T.shadow(28, 62, 64, 64, 14, 8, 0.18, 4, T.darken(tint, 0.3))
  C.drawItem(a, 28, 62, 64, S.t)
  local isFav = Favs.isAlbum(a)
  T.marquee(T.f.h1, a.title, 108, 64, T.W - 28 - 108 - (isFav and 34 or 0), T.c.ink, 1, "trk_album")
  if isFav then T.icon("heart", T.W - 28 - 14, 82, 24, T.palette[6]) end
  local sub = a.artist
  if sub ~= "" then sub = sub .. "  ·  " end
  T.marquee(T.f.small, sub .. I.n("tracks", #a.tracks), 109, 100, T.W - 28 - 109, T.c.ink2, 1, "trk_sub")

  -- liste
  local viewH = App.viewBottom() - VT
  App.scissor(0, VT, T.W, viewH)
  local cur = P.current
  for i = 0, #a.tracks do
    local top, bot = bounds(i)
    local y = VT + top - S.scroll
    if y + (bot - top) > VT - 20 and y < VT + viewH + 20 then
      local key = i
      local k = S.kmap[key] or 0
      k = T.damp(k, (i == S.sel) and 1 or 0, 16, S.dt)
      S.kmap[key] = k
      if i == 0 then playRow(y, k)
      else
        local t = a.tracks[i]
        trackRow(t, i, y, k, cur == t, P.state == "playing")
      end
    end
  end
  lg.setScissor()
  -- dossier Favoris vide : petite explication
  if a.fav and #a.tracks == 0 then
    T.icon("star", T.W / 2, VT + PLAY_H + 70, 54, a.tint or T.palette[4], 0.9)
    T.text(T.f.h2, I.t("fav_empty"), 40, VT + PLAY_H + 112, T.c.ink, 1, "center", T.W - 80)
    T.text(T.f.small, I.t("fav_empty_hint"), 40, VT + PLAY_H + 142, T.c.ink2, 1, "center", T.W - 80)
  end
  if App.miniVisible() then W.mini(S.t) end
  W.hints({ { "dpad", I.t("h_choose") }, { "A", I.t("h_listen") }, { "X", I.t("h_shuffle") }, { "Y", I.t("h_fav") }, { "B", I.t("h_back") } })
end

return S
