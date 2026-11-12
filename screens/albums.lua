-- Écran d'accueil : tous les albums, en grille ou en liste.
-- Ordre : dossier "Favoris" (morceaux favoris, toujours en premier même vide), albums favoris, puis les autres albums.
-- (lecture aléatoire de tout : X ici, ou L1 + R1 partout)
local T = require("theme")
local C = require("covers")
local W = require("widgets")
local App = require("app")
local I = require("i18n")
local Favs = require("favs")
local lg = love.graphics

local S = { view = "grid", mode = "albums", artist = nil, sel = 1, scroll = 0, t = 0, dt = 0, kmap = {}, items = {}, ver = -1, fver = -1, bg = { 0.29, 0.62, 1.0 } }

local COLS, COVER, GAPX = 3, 144, 48
local X0 = (T.W - (COLS * COVER + (COLS - 1) * GAPX)) / 2
local ROWH = COVER + 58
local LROW_H, LROW_P = 72, 80
local VT = 84

local function rebuild()
  local lib = App.lib
  local keep = S.items[S.sel]
  if S.ver ~= lib.version then
    C.setAlbums(lib.albums)
    lib.all.ci, lib.all.tint = 5, T.palette[5]
  end
  if lib.favVersion ~= Favs.version then lib.refreshFavs() end
  S.items = {}
  if S.mode == "artists" then
    -- après une nouvelle recherche, on retrouve l'artiste ouvert par sa clé
    if S.artist and S.ver ~= lib.version then
      local found
      for _, ar in ipairs(lib.artists or {}) do if ar.key == S.artist.key then found = ar; break end end
      S.artist = found
    end
    if S.artist then
      -- un artiste : dossier "Sans album" en premier (s'il y en a), puis tous ses albums
      if S.artist.noalbum then S.items[#S.items + 1] = S.artist.noalbum end
      for _, a in ipairs(S.artist.albums) do S.items[#S.items + 1] = a end
    else
      S.items[#S.items + 1] = lib.fav -- dossier Favoris : toujours en premier, même vide
      for _, ar in ipairs(lib.artists or {}) do S.items[#S.items + 1] = ar end
    end
  else
    S.items[#S.items + 1] = lib.fav -- dossier Favoris : toujours en premier, même vide
    for _, a in ipairs(lib.albums) do if Favs.isAlbum(a) then S.items[#S.items + 1] = a end end
    for _, a in ipairs(lib.albums) do if not Favs.isAlbum(a) then S.items[#S.items + 1] = a end end
  end
  S.ver, S.fver, S.bmode, S.bartist = lib.version, Favs.version, S.mode, S.artist
  -- on garde la sélection sur le même élément
  if keep then
    for i, it in ipairs(S.items) do if it == keep then S.sel = i; break end end
  end
  S.sel = T.clamp(S.sel, 1, math.max(1, #S.items))
end

local function stale()
  return S.ver ~= App.lib.version or S.fver ~= Favs.version or S.bmode ~= S.mode or S.bartist ~= S.artist
end

-- teinte d'un élément (un artiste prend celle de la pochette de son album)
local function tintOf(item)
  if item.artistItem and item.rep then return item.rep.tint or T.palette[4] end
  return item.tint or T.palette[4]
end

-- Albums / Artistes (depuis les Réglages)
function S.setMode(m)
  if S.mode == m then return end
  S.mode, S.artist, S.sel = m, nil, 1
  S.scroll, S.scrollTarget = 0, 0
  App.saveSettings()
end

-- ouvrir / refermer un artiste
local function openArtist(ar)
  S.artist, S.sel = ar, 1
  S.scroll, S.scrollTarget = 0, 0
  rebuild()
end
local function closeArtist()
  local ar = S.artist
  S.artist = nil
  S.scroll, S.scrollTarget = 0, 0
  rebuild()
  for i, it in ipairs(S.items) do if it == ar then S.sel = i; break end end
end

function S.enter(args)
  if stale() then rebuild() end
end

-- changement grille / liste (depuis les Réglages)
function S.setView(v)
  S.view = v
  S.scroll, S.scrollTarget = 0, 0
  App.saveSettings()
end

local function bounds(i)
  if S.view == "grid" then
    local row = math.floor((i - 1) / COLS)
    return 8 + row * ROWH, 8 + row * ROWH + COVER + 56
  end
  return 6 + (i - 1) * LROW_P, 6 + (i - 1) * LROW_P + LROW_H
end

function S.update(dt)
  S.t, S.dt = S.t + dt, dt
  if stale() then rebuild() end
  local n = #S.items
  if n > 0 then
    local top, bot = bounds(S.sel)
    local viewH = App.viewBottom() - VT
    local tgt = S.scrollTarget or 0
    if top - 8 < tgt then tgt = top - 8 end
    if bot + 6 > tgt + viewH then tgt = bot + 6 - viewH end
    S.scrollTarget = math.max(0, tgt)
    S.scroll = T.damp(S.scroll, S.scrollTarget, 14, dt)
    -- teinte du fond selon l'album sélectionné
    local tint = tintOf(S.items[S.sel])
    for i = 1, 3 do S.bg[i] = T.damp(S.bg[i], tint[i], 5, dt) end
    -- demande des pochettes visibles (les plus proches du curseur d'abord)
    local first, last
    if S.view == "grid" then
      first = math.max(1, (math.floor(S.scroll / ROWH) - 1) * COLS + 1)
      last = math.min(n, (math.floor((S.scroll + viewH) / ROWH) + 2) * COLS)
    else
      first = math.max(1, math.floor(S.scroll / LROW_P))
      last = math.min(n, math.ceil((S.scroll + viewH) / LROW_P) + 2)
    end
    for i = first, last do C.want(S.items[i], math.abs(i - S.sel)) end
  end
end

local function shuffleAll() App.shuffleAll() end

function S.action(a)
  local n = #S.items
  if a == "x" then shuffleAll(); return true
  elseif a == "start" then
    if App.player.current then App.go("now") end
    return true
  elseif a == "select" then
    App.go("settings")
    return true
  end
  if n == 0 then return false end
  local it = S.items[S.sel]
  if a == "a" then
    if it.all then shuffleAll()
    elseif it.artistItem then openArtist(it)
    else App.go("tracks", { album = it }) end
    return true
  elseif a == "b" then
    if S.artist then closeArtist(); return true end
    return false
  elseif a == "y" then
    if not it.all and not it.fav and not it.artistItem and not it.noalbum then App.say("fav", Favs.toggleAlbum(it)) end
    return true
  end
  local grid = S.view == "grid"
  if a == "left" and grid then S.sel = math.max(1, S.sel - 1)
  elseif a == "right" and grid then S.sel = math.min(n, S.sel + 1)
  elseif a == "up" then S.sel = math.max(1, S.sel - (grid and COLS or 1))
  elseif a == "down" then
    local step = grid and COLS or 1
    if S.sel + step <= n then S.sel = S.sel + step
    elseif grid and math.floor((S.sel - 1) / COLS) < math.floor((n - 1) / COLS) then S.sel = n end
  else return false end
  return true
end

local function playingBadge(item, x, y, size)
  local P = App.player
  if not P.current or item.all or item.fav or item.artistItem or item.noalbum then return end
  if P.current.album ~= item then return end
  local tint = item.tint or T.palette[4]
  local w, h = 36, 24
  T.set(T.c.surface, 0.95)
  T.rr("fill", x + size - w - 8, y + 8, w, h, 12)
  T.eq(x + size - w - 8 + 9, y + 8 + 5, 18, 14, S.t, tint, 1, P.state == "playing")
end

-- petit cœur sur la pochette d'un album favori
local function favBadge(item, x, y, r)
  if not Favs.isAlbum(item) then return end
  T.set(T.c.surface, 0.95); lg.circle("fill", x + r + 6, y + r + 6, r, 24)
  T.icon("heart", x + r + 6, y + r + 6.5, r * 1.15, T.palette[6])
end

local function subOf(item, long)
  if item.all then return long and I.t("all_sub") or I.n("tracks", #item.tracks) end
  if item.fav or item.noalbum then return I.n("tracks", #item.tracks) end
  if item.artistItem then
    if #item.albums > 0 then return I.n("albums", #item.albums) end
    return I.n("tracks", #item.tracks)
  end
  return item.artist
end

local function gridCard(item, x, y, k)
  local size = COVER
  local sc = 1 + 0.08 * k
  local tint = tintOf(item)
  lg.push()
  lg.translate(x + size / 2, y + size / 2 - 5 * k)
  lg.scale(sc)
  lg.translate(-size / 2, -size / 2)
  T.shadow(0, 0, size, size, 20, 8 + 14 * k, 0.15 + 0.1 * k, 5 + 6 * k, k > 0.05 and T.mix({ 0.16, 0.18, 0.32 }, T.darken(tint, 0.3), k) or nil)
  C.drawItem(item, 0, 0, size, S.t)
  playingBadge(item, 0, 0, size)
  favBadge(item, 0, 0, 13)
  lg.pop()
  local lw = COVER + 34
  local col = T.mix(T.c.ink, T.contrast(tint, 0.3), k * 0.8)
  local on = k > 0.5
  T.marquee(T.f.body, item.title, x - 17, y + size + 10, lw, col, 1, on and "alb_t" or nil, "center")
  T.marquee(T.f.small, subOf(item), x - 17, y + size + 33, lw, T.c.ink2, 1, on and "alb_s" or nil, "center")
end

local function listRow(item, y, k)
  local x, w, h = 28, 584, LROW_H
  local tint = tintOf(item)
  local sc = 1 + 0.015 * k
  lg.push()
  lg.translate(x + w / 2, y + h / 2)
  lg.scale(sc)
  lg.translate(-w / 2, -h / 2)
  if k > 0.02 then T.shadow(0, 0, w, h, 24, 8 + 8 * k, 0.12 * k + 0.04, 4) end
  T.set(T.c.surface, 0.6 + 0.4 * k)
  T.rr("fill", 0, 0, w, h, 24)
  if k > 0.02 then
    lg.setLineWidth(3)
    T.set(tint, k)
    T.rr("line", 1.5, 1.5, w - 3, h - 3, 23)
  end
  C.drawItem(item, 10, 8, 56, S.t)
  playingBadge(item, 10, 8, 56)
  local tw = w - 82 - 120
  local on = k > 0.5
  T.marquee(T.f.h2, item.title, 82, 9, tw, T.c.ink, 1, on and "alb_t" or nil)
  T.marquee(T.f.small, subOf(item, true), 82, 38, tw, T.c.ink2, 1, on and "alb_s" or nil)
  if not item.all and not item.fav then
    T.text(T.f.small, I.n("tracks", #item.tracks), w - 150, 25, T.c.ink3, 1, "right", 112)
  end
  if Favs.isAlbum(item) then T.icon("heart", w - 168, h / 2, 18, T.palette[6]) end
  T.icon("chevron", w - 24, h / 2, 22, T.c.ink3)
  lg.pop()
end

local function drawHeader()
  local lib = App.lib
  local crumbs, stats = { I.t("music") }, nil
  if S.mode == "artists" and S.artist then
    crumbs[2] = S.artist.title
    stats = I.n("albums", #S.artist.albums) .. "  ·  " .. I.n("tracks", #S.artist.tracks)
  elseif S.mode == "artists" then
    stats = I.n("artists", #(lib.artists or {})) .. "  ·  " .. I.n("tracks", #lib.tracks)
  else
    stats = I.n("albums", #lib.albums) .. "  ·  " .. I.n("tracks", #lib.tracks)
  end
  -- batterie à gauche du bouton Réglages
  local bw = W.battery(T.W - 28 - 40 - 14, 32)
  W.header(crumbs, stats, T.W - 28 - 40 - 12 - (bw > 0 and bw + 14 or 0))
  -- bouton Réglages (Select)
  local gx, gy = T.W - 28 - 20, 32
  T.shadow(gx - 20, gy - 20, 40, 40, 20, 8, 0.1, 3)
  T.set(T.c.surface, 0.95); lg.circle("fill", gx, gy, 20, 32)
  T.icon("gear", gx, gy, 22, T.c.ink2)
end

-- Logo SORI PLAYER centré (barres en dégradé qui ondulent doucement), comme l'écran de démarrage
local logoBig, logoSub
local function drawLogo(cx, cy)
  if not logoBig then
    logoBig = lg.newFont("assets/Nunito-Black.ttf", 56)
    logoSub = lg.newFont("assets/Nunito-ExtraBold.ttf", 13)
    logoBig:setFilter("linear", "linear"); logoSub:setFilter("linear", "linear")
  end
  local BW, GAP, MAXH = 6, 6, 96
  local n = #T.LOGO_H
  local barsW = n * BW + (n - 1) * GAP
  local word = "SORI"
  local tw = logoBig:getWidth(word)
  local gap = 20
  local x0 = cx - (barsW + gap + tw) / 2
  for i, hgt in ipairs(T.LOGO_H) do
    local wave = 0.88 + 0.12 * math.sin(S.t * 3.2 + i * 0.8)
    local h = math.max(BW, MAXH * hgt * wave)
    T.set(T.logoColor((i - 1) / (n - 1)))
    T.rr("fill", x0 + (i - 1) * (BW + GAP), cy - h / 2, BW, h, BW / 2)
  end
  local tx = x0 + barsW + gap
  T.text(logoBig, word, tx, cy + 6 - logoBig:getBaseline(), T.c.ink)
  T.set(T.c.ink2)
  T.spaced(logoSub, "PLAYER", tx + 2, cy + 13, tw - 4)
end

local function drawCenteredMessage(title, lines, mood, logo)
  if logo then drawLogo(T.W / 2, 190) else T.mascot(T.W / 2, 190, 62, S.t, T.palette[4], mood) end
  T.text(T.f.h1, title, 0, 270, T.c.ink, 1, "center", T.W)
  for i, l in ipairs(lines) do T.text(T.f.body, l, 40, 306 + (i - 1) * 26, T.c.ink2, 1, "center", T.W - 80) end
end

function S.draw()
  local lib = App.lib
  T.background(S.bg, S.t)
  -- (le dossier Favoris est toujours présent : on teste les vrais albums)
  if lib.state == "scanning" and #lib.albums == 0 then
    local dots = string.rep(".", math.floor(S.t * 3) % 4)
    drawCenteredMessage(I.t("scanning") .. dots, { I.t("found", lib.count) }, "open")
    return
  elseif #lib.albums == 0 then
    drawCenteredMessage(I.t("empty_title"), { I.t("empty_hint"), table.concat(App.roots, "  ·  ") }, nil, true)
    T.text(T.f.small, I.t("empty_hint2"), 40, 372, T.c.ink3, 1, "center", T.W - 80)
    return
  end

  App.scissor(0, VT, T.W, App.viewBottom() - VT)
  local n = #S.items
  local viewH = App.viewBottom() - VT
  for i = 1, n do
    local item = S.items[i]
    local top, bot = bounds(i)
    local y = VT + top - S.scroll
    if y + (bot - top) > VT - 24 and y < VT + viewH + 24 then
      local k = S.kmap[item] or 0
      k = T.damp(k, (i == S.sel) and 1 or 0, 16, S.dt)
      S.kmap[item] = k
      if S.view == "grid" then
        local col = (i - 1) % COLS
        gridCard(item, X0 + col * (COVER + GAPX), y, k)
      else
        listRow(item, y, k)
      end
    end
  end
  lg.setScissor()
  drawHeader()
  if lib.state == "scanning" then
    T.text(T.f.small, I.t("still_scanning", lib.count), 0, 62, T.c.ink3, 1, "right", T.W - 80)
  end
  if App.miniVisible() then W.mini(S.t) end
  if S.artist then
    W.hints({ { "dpad", I.t("h_choose") }, { "A", I.t("h_open") }, { "X", I.t("h_random") }, { "Y", I.t("h_fav") }, { "B", I.t("h_back") } })
  else
    W.hints({ { "dpad", I.t("h_choose") }, { "A", I.t("h_open") }, { "X", I.t("h_random") }, { "Y", I.t("h_fav") }, { "SELECT", I.t("settings") } })
  end
end

return S
