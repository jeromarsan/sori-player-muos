-- Lecture en cours : grande pochette qui danse, boutons ronds, volume.
local T = require("theme")
local C = require("covers")
local W = require("widgets")
local App = require("app")
local I = require("i18n")
local Favs = require("favs")
local lg = love.graphics

local S = { t = 0, dt = 0, bg = { 0.29, 0.62, 1.0 }, live = 0, press = {}, notes = {}, noteT = 0, shown = 0 }

local CX, CY, CS = 28, 84, 300 -- pochette
local RX, RW = 352, 260 -- colonne de droite

function S.enter()
  local cur = App.player.current
  if cur and cur.album then for i = 1, 3 do S.bg[i] = cur.album.tint[i] end end
end

local function bump(name) S.press[name] = 1 end

function S.action(a)
  local P = App.player
  if a == "a" then P:toggle(); bump("play")
  elseif a == "x" then P:toggleShuffle(); bump("shuffle")
  elseif a == "y" then
    if P.current then App.say("fav", Favs.toggleTrack(P.current)); bump("fav") end
  elseif a == "select" then P:cycleRepeat(); bump("repeat")
  elseif a == "left" then P:seek(-10)
  elseif a == "right" then P:seek(10)
  elseif a == "up" then App.volume(0.05)
  elseif a == "down" then App.volume(-0.05)
  elseif a == "b" or a == "start" then App.back()
  else return false end
  return true
end

function S.update(dt)
  S.t, S.dt = S.t + dt, dt
  local P = App.player
  local cur = P.current
  if cur and cur.album then
    local a = cur.album
    C.want(a, 0)
    for i = 1, 3 do S.bg[i] = T.damp(S.bg[i], a.tint[i], 5, dt) end
  end
  for k, v in pairs(S.press) do S.press[k] = v > 0.01 and v - dt * 4 or nil end
  S.live = T.damp(S.live, P.state == "playing" and 1 or 0, 5, dt)
  -- petites notes de musique qui s'envolent
  if P.state == "playing" then
    S.noteT = S.noteT - dt
    if S.noteT <= 0 then
      S.noteT = 0.55
      local left = love.math.random() < 0.5
      S.notes[#S.notes + 1] = {
        x = left and (CX + 6 + love.math.random() * 30) or (CX + CS - 36 + love.math.random() * 30),
        y = CY + CS * (0.35 + love.math.random() * 0.4), age = 0, life = 2.4 + love.math.random(),
        col = T.palette[love.math.random(#T.palette)], sw = love.math.random() * 6, s = 18 + love.math.random() * 10,
      }
    end
  end
  for i = #S.notes, 1, -1 do
    local n = S.notes[i]
    n.age = n.age + dt
    n.y = n.y - 34 * dt
    if n.age > n.life then table.remove(S.notes, i) end
  end
end

local function fmt(sec)
  sec = math.max(0, math.floor(sec))
  return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function roundBtn(name, cx, cy, r, icon, active, tint, big, arg)
  local pr = S.press[name] or 0
  local sc = 1 + 0.22 * math.sin(pr * math.pi)
  lg.push()
  lg.translate(cx, cy)
  lg.scale(sc)
  if big or active then
    T.shadow(-r, -r, r * 2, r * 2, r, 10, 0.2, 4, T.darken(tint, 0.4))
    T.set(tint); lg.circle("fill", 0, 0, r, 40)
    lg.setColor(1, 1, 1, 0.18); lg.arc("fill", "closed", 0, 0, r - 1, math.pi, math.pi * 2, 24)
    T.icon(icon, (icon == "play") and 2 or 0, 0, r * 1.05, T.c.white, 1, arg)
  else
    T.shadow(-r, -r, r * 2, r * 2, r, 8, 0.1, 3)
    T.set(T.c.surface, 0.95); lg.circle("fill", 0, 0, r, 40)
    T.icon(icon, 0, 0, r * 1.0, T.c.ink2, 1, arg)
  end
  lg.pop()
end

function S.draw()
  local P = App.player
  local cur = P.current
  T.background(S.bg, S.t)
  if not cur then
    W.header({ I.t("music"), I.t("now_playing") })
    T.mascot(T.W / 2, 200, 60, S.t, T.palette[4], nil)
    T.text(T.f.h1, I.t("nothing_playing"), 0, 290, T.c.ink, 1, "center", T.W)
    W.hints({ { "B", I.t("h_back") } })
    return
  end
  local album = cur.album
  local tint = (album and album.tint) or T.palette[4]
  local playing = P.state == "playing"

  local crumbs = App.crumbs(album)
  crumbs[#crumbs + 1] = I.t("now_playing")
  W.header(crumbs)

  -- notes qui flottent (derrière la pochette)
  for _, n in ipairs(S.notes) do
    local a = math.sin(math.pi * math.min(1, n.age / n.life))
    local x = n.x + math.sin(n.age * 2 + n.sw) * 10
    T.icon("note", x, n.y, n.s, n.col, 0.85 * a)
  end

  -- pochette qui danse
  local ang = math.sin(S.t * 2.2) * 0.022 * S.live
  local sc = (0.95 + 0.05 * S.live) + 0.014 * S.live * math.sin(S.t * 4.4) + 0.05 * math.sin(math.min(1, P.bump) * math.pi)
  lg.push()
  lg.translate(CX + CS / 2, CY + CS / 2 + 2 - 4 * S.live)
  lg.rotate(ang)
  lg.scale(sc)
  lg.translate(-CS / 2, -CS / 2)
  T.shadow(0, 0, CS, CS, 42, 22, 0.2, 14, T.darken(tint, 0.35))
  if album then C.draw(album, 0, 0, CS) end
  lg.pop()

  -- colonne de droite : titre, artiste
  local n = #P.order
  T.text(T.f.small, I.t("track_of", P.pos, n), RX, 86, T.contrast(tint, 0.25))
  T.marquee(T.f.h1, cur.t, RX, 108, RW - 36, T.c.ink, 1, "now_t")
  -- cœur favori (Y)
  local fp = S.press["fav"] or 0
  local fs = 26 * (1 + 0.3 * math.sin(fp * math.pi))
  if Favs.isTrack(cur) then T.icon("heart", RX + RW - 14, 124, fs, T.palette[6])
  else T.icon("heart", RX + RW - 14, 124, fs, T.c.ink3, 0.45) end
  local y = 108 + 34
  local sub = cur.ar ~= "" and cur.ar or (album and album.artist) or ""
  T.marquee(T.f.body, sub, RX, y, RW, T.c.ink2, 1, "now_a")
  if album then T.marquee(T.f.small, album.title, RX, y + 24, RW, T.c.ink3, 1, "now_al") end

  -- boutons
  local cy = 262
  roundBtn("shuffle", RX + 19, cy, 19, "shuffle", P.shuffle, tint)
  roundBtn("prev", RX + 66, cy, 24, "prev", false, tint)
  roundBtn("play", RX + 130, cy, 35, playing and "pause" or "play", true, tint, true)
  roundBtn("next", RX + 194, cy, 24, "next", false, tint)
  local rep = P.repeatMode
  local pr = S.press["repeat"] or 0
  roundBtn("repeat", RX + 241, cy, 19, "repeat_", rep > 0, tint)
  if rep == 2 then T.icon("one", RX + 241, cy, 19, T.c.white) end
  -- rappel des touches
  local capY = cy + 42
  W.cap(RX + 19 - 12, capY, "X")
  T.keycap(RX + 66 - 12, capY, "L1")
  T.keycap(RX + 130 - 10, capY + 10, "A")
  T.keycap(RX + 194 - 12, capY, "R1")
  W.cap(RX + 241 - 14, capY, "SEL")
  if P.state == "loading" then
    T.text(T.f.tiny, I.t("loading"), RX, cy - 62, T.c.ink3, 1, "center", RW)
  end

  -- volume
  local vy = 358
  local v = P.volume
  T.icon("speaker", RX + 12, vy, 24, T.c.ink2, 1, v <= 0.001 and 0 or (v < 0.5 and 1 or 2))
  local sx, sw = RX + 38, RW - 38 - 38
  T.track(); T.rr("fill", sx, vy - 5, sw, 10, 5)
  T.set(tint); T.rr("fill", sx, vy - 5, math.max(10, sw * v / (P.maxVolume > 0 and P.maxVolume or 1)), 10, 5)
  T.text(T.f.small, math.floor(v * 100 + 0.5) .. "%", RX + RW - 36, vy - 11, T.c.ink2, 1, "right", 36)

  -- progression
  local px, pw, py = 28, 584, 408
  local prog = P:progress()
  T.track(); T.rr("fill", px, py - 6, pw, 12, 6)
  T.set(tint); T.rr("fill", px, py - 6, math.max(12, pw * prog), 12, 6)
  local kx = px + 6 + (pw - 12) * prog
  T.shadow(kx - 10, py - 10, 20, 20, 10, 6, 0.25, 2)
  lg.setColor(1, 1, 1, 1); lg.circle("fill", kx, py, 10, 24)
  T.set(tint); lg.circle("fill", kx, py, 4, 16)
  T.text(T.f.small, fmt(P:position()), px, py + 12, T.c.ink2)
  if P.duration and P.duration > 0 then T.text(T.f.small, fmt(P.duration), px, py + 12, T.c.ink2, 1, "right", pw) end

  W.hints({ { "lr", I.t("h_seek") }, { "ud", I.t("h_volume") }, { "Y", I.t("h_fav") }, { "B", I.t("h_back") } })
end

return S
