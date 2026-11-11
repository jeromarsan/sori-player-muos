-- Pochettes : décodage en thread, miniatures arrondies, couleur dominante.
local T = require("theme")
local lg = love.graphics
local C = {}

local BIG, SMALL = 320, 96
local MAX_LOADED = 80

local THREAD = [[
require("love.filesystem"); require("love.image"); require("love.thread")
local req = love.thread.getChannel((select(1, ...)))
local res = love.thread.getChannel((select(2, ...)))
while true do
  local r = req:demand()
  if r == "quit" then break end
  local ok, data = pcall(function()
    local f = io.open(r.path, "rb")
    if not f then error("open") end
    if r.off then f:seek("set", r.off) end
    local bytes = r.len and f:read(r.len) or f:read("*a")
    f:close()
    local d = love.image.newImageData(love.filesystem.newFileData(bytes, "cover"))
    if d:getWidth() * d:getHeight() > 36000000 then error("trop grand") end
    return d
  end)
  res:push({ id = r.id, data = ok and data or nil })
end
]]

local MASK = [[
uniform float size;
uniform float rad;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec4 c = Texel(tex, uv) * color;
  vec2 p = abs(sc - vec2(size * 0.5)) - (vec2(size * 0.5) - vec2(rad));
  float d = length(max(p, 0.0)) - rad;
  c.a *= clamp(0.5 - d, 0.0, 1.0);
  return c;
}
]]

local shader, thread, reqCh, resCh
local nextId, pending, wanted, outstanding = 1, {}, {}, 0
local frame = 0
local placeholders = {}
local loaded = 0

function C.init()
  shader = lg.newShader(MASK)
  local ok = pcall(function()
    reqCh, resCh = love.thread.getChannel("cov_req"), love.thread.getChannel("cov_res")
    thread = love.thread.newThread(THREAD)
    thread:start("cov_req", "cov_res")
  end)
  if not ok then thread = nil end
end

function C.shutdown()
  if reqCh then reqCh:push("quit") end
end

local function hashIdx(s)
  local h = 5381
  for i = 1, #s do h = (h * 33 + s:byte(i)) % 1000003 end
  return h % #T.palette + 1
end

-- Tuile sans pochette : logo SORI = dégradé du logo en fond (rose → violet → bleu → cyan)
-- et barres d'onde en blanc. (ci n'est plus utilisé : même tuile pour tous les dossiers)
local function makePlaceholder(ci, S)
  local cv = lg.newCanvas(S, S)
  lg.push("all")
  lg.origin()
  lg.setScissor() -- sinon la zone de découpage de la liste rogne la tuile
  lg.setCanvas({ cv, stencil = true })
  lg.clear(0, 0, 0, 0)
  lg.stencil(function() T.rr("fill", 0, 0, S, S, S * 0.14) end, "replace", 1)
  lg.setStencilTest("greater", 0)
  -- dégradé en diagonale, par fines bandes
  local step = math.max(1, math.floor(S / 160))
  for d = 0, 2 * S, step do
    T.set(T.logoColor(d / (2 * S)))
    lg.polygon("fill", d, 0, d + step + 1, 0, 0, d + step + 1, 0, d)
  end
  lg.setColor(1, 1, 1, 0.10)
  lg.circle("fill", S * 0.85, S * 0.12, S * 0.34, 40)
  lg.circle("fill", S * 0.08, S * 0.92, S * 0.28, 40)
  lg.setStencilTest()
  -- barres blanches du logo, centrées
  local n = #T.LOGO_H
  local bw = S * 0.62 / (2 * n - 1)
  local x0 = (S - (2 * n - 1) * bw) / 2
  local maxh = S * 0.52
  lg.setColor(1, 1, 1, 0.96)
  for i, h in ipairs(T.LOGO_H) do
    local bh = math.max(bw, maxh * h)
    T.rr("fill", x0 + (i - 1) * 2 * bw, S / 2 - bh / 2, bw, bh, bw / 2)
  end
  lg.pop()
  return cv
end

function C.placeholder(ci, small)
  local key = ci .. (small and "s" or "b")
  if not placeholders[key] then placeholders[key] = makePlaceholder(ci, small and SMALL or BIG) end
  return placeholders[key]
end

-- Réduction par moitiés successives puis découpe arrondie
local function bake(img)
  local iw, ih = img:getDimensions()
  local m = math.min(iw, ih)
  m = m - m % 2
  local src = img
  local q = lg.newQuad(math.floor((iw - m) / 2), math.floor((ih - m) / 2), m, m, iw, ih)
  local cur = m
  local first = true
  lg.push("all")
  lg.origin()
  lg.setScissor()
  lg.setBlendMode("alpha")
  lg.setColor(1, 1, 1, 1)
  while cur >= BIG * 2 do
    local nxt = math.floor(cur / 2)
    local cv = lg.newCanvas(nxt, nxt)
    lg.setCanvas(cv)
    lg.clear(0, 0, 0, 1)
    if first then lg.draw(src, q, 0, 0, 0, nxt / cur, nxt / cur) else lg.draw(src, 0, 0, 0, nxt / cur, nxt / cur) end
    lg.setCanvas()
    if not first then src:release() end
    src, cur, first = cv, nxt, false
  end
  local function final(S)
    local cv = lg.newCanvas(S, S)
    lg.setCanvas(cv)
    lg.clear(0, 0, 0, 0)
    lg.setBlendMode("replace")
    lg.setShader(shader)
    shader:send("size", S)
    shader:send("rad", S * 0.14)
    if first then lg.draw(src, q, 0, 0, 0, S / cur, S / cur) else lg.draw(src, 0, 0, 0, S / cur, S / cur) end
    lg.setShader()
    lg.setBlendMode("alpha")
    lg.setCanvas()
    return cv
  end
  local big = final(BIG)
  -- petite version à partir de la grande (meilleure qualité)
  local small = lg.newCanvas(SMALL, SMALL)
  lg.setCanvas(small)
  lg.clear(0, 0, 0, 0)
  lg.setBlendMode("replace")
  lg.draw(big, 0, 0, 0, SMALL / BIG, SMALL / BIG)
  lg.setBlendMode("alpha")
  lg.setCanvas()
  if not first then src:release() end
  lg.pop()
  return big, small
end

-- Couleur vive dominante (pour teinter l'interface)
local function dominant(small)
  local id = small:newImageData()
  local w, h = id:getDimensions()
  local bins, wsum = {}, {}
  for i = 1, 12 do bins[i] = { 0, 0, 0 }; wsum[i] = 0 end
  local tot = 0
  for y = 2, h - 2, 4 do
    for x = 2, w - 2, 4 do
      local r, g, b, a = id:getPixel(x, y)
      if a > 0.5 then
        local hh, s, v = T.rgb2hsv(r, g, b)
        local wt = s * s * v + 0.002
        local bi = math.floor(hh * 12) % 12 + 1
        bins[bi][1] = bins[bi][1] + r * wt; bins[bi][2] = bins[bi][2] + g * wt; bins[bi][3] = bins[bi][3] + b * wt
        wsum[bi] = wsum[bi] + wt
        tot = tot + wt
      end
    end
  end
  id:release()
  local best, bw = 1, -1
  for i = 1, 12 do if wsum[i] > bw then best, bw = i, wsum[i] end end
  if bw <= 0.02 then return nil end
  local r, g, b = bins[best][1] / bw, bins[best][2] / bw, bins[best][3] / bw
  local hh, s, v = T.rgb2hsv(r, g, b)
  if s < 0.18 then return nil end
  return T.hsv2rgb(hh, T.clamp(s, 0.45, 0.85), T.clamp(v, 0.82, 1.0))
end

local function evict()
  if loaded <= MAX_LOADED then return end
  local oldest, oa
  for _, a in pairs(C.albums or {}) do
    if a.cvState == "ready" and (a.used or 0) < frame - 90 and (not oa or a.used < oa.used) then oa = a end
  end
  if oa then
    oa.thumb:release(); oa.thumbS:release()
    oa.thumb, oa.thumbS, oa.cvState = nil, nil, nil
    loaded = loaded - 1
  end
end

local function finish(album, data)
  if not data then album.cvState = "none"; return end
  local ok, big, small = pcall(function()
    local img = lg.newImage(data)
    img:setFilter("linear", "linear")
    local b, s = bake(img)
    img:release()
    return b, s
  end)
  data:release()
  if not ok then if os.getenv("SORI_TEST") then print("COVER ERR", album.title, big) end album.cvState = "none"; return end
  album.thumb, album.thumbS, album.cvState, album.fade = big, small, "ready", 0
  album.tint = dominant(small) or album.tint
  loaded = loaded + 1
  evict()
end

function C.setAlbums(list)
  C.albums = list
  for _, a in ipairs(list) do
    a.ci = hashIdx(a.title)
    a.tint = T.palette[a.ci]
    if a.cover then a.cvState = nil
    else
      a.cvState = "none"
      a.tint = T.logoColor(0.55) -- teinte du dégradé SORI, comme la tuile sans pochette
    end
  end
end

-- Appelé par les écrans pour chaque album visible (prio petite = urgent)
function C.want(album, prio)
  if album.all or album.fav then return end
  album.used = frame
  if album.cvState == nil and (not wanted[album] or wanted[album] > prio) then wanted[album] = prio end
end

function C.update(dt)
  frame = frame + 1
  -- résultats
  if resCh then
    local m = resCh:pop()
    if m then
      outstanding = math.max(0, outstanding - 1)
      local album = pending[m.id]
      pending[m.id] = nil
      if album then finish(album, m.data) elseif m.data then m.data:release() end
    end
  end
  -- demandes (3 à la fois max)
  if outstanding < 3 then
    local best, bp
    for a, p in pairs(wanted) do if not bp or p < bp then best, bp = a, p end end
    if best then
      wanted[best] = nil
      if best.cvState == nil then
        if reqCh then
          local id = nextId; nextId = nextId + 1
          pending[id] = best
          best.cvState = "pending"
          outstanding = outstanding + 1
          reqCh:push({ id = id, path = best.cover.path, off = best.cover.off, len = best.cover.len })
        else
          best.cvState = "none"
        end
      end
    end
  end
  wanted = {}
end

-- Carte "Tout mélanger" : dégradé violet/rose + Mélo qui rigole
local allCv = {}
function C.drawAll(x, y, size, t)
  local small = size <= 110
  local key = small and "s" or "b"
  if not allCv[key] then
    local S = small and SMALL or BIG
    local cv = lg.newCanvas(S, S)
    lg.push("all")
    lg.origin()
    lg.setScissor()
    lg.setCanvas({ cv, stencil = true })
    lg.clear(0, 0, 0, 0)
    lg.stencil(function() T.rr("fill", 0, 0, S, S, S * 0.14) end, "replace", 1)
    lg.setStencilTest("greater", 0)
    T.gradV(0, 0, S, S, T.palette[5], T.palette[6])
    lg.setColor(1, 1, 1, 0.16)
    lg.circle("fill", S * 0.88, S * 0.1, S * 0.34, 40)
    lg.circle("fill", S * 0.06, S * 0.95, S * 0.3, 40)
    lg.setStencilTest()
    lg.pop()
    allCv[key] = cv
  end
  local cv = allCv[key]
  local s = size / cv:getWidth()
  lg.setColor(1, 1, 1, 1)
  lg.draw(cv, x, y, 0, s, s)
  T.mascot(x + size * 0.5, y + size * 0.54, size * 0.25, t or 0, { 1, 1, 1 }, "open")
  T.icon("shuffle", x + size * 0.84, y + size * 0.17, size * 0.17, T.c.white, 0.95)
end

-- Dossier "Favoris" : fond bleu nuit + grande étoile jaune
local favCv = {}
local STAR = { 1.0, 0.80, 0.22 }
function C.drawFav(x, y, size)
  local small = size <= 110
  local key = small and "s" or "b"
  if not favCv[key] then
    local S = small and SMALL or BIG
    local cv = lg.newCanvas(S, S)
    lg.push("all")
    lg.origin()
    lg.setScissor() -- sinon la zone de découpage de la liste rogne la carte
    lg.setCanvas({ cv, stencil = true })
    lg.clear(0, 0, 0, 0)
    lg.stencil(function() T.rr("fill", 0, 0, S, S, S * 0.14) end, "replace", 1)
    lg.setStencilTest("greater", 0)
    T.gradV(0, 0, S, S, { 0.17, 0.20, 0.36 }, { 0.08, 0.09, 0.19 })
    lg.setColor(1, 1, 1, 0.07)
    lg.circle("fill", S * 0.88, S * 0.1, S * 0.34, 40)
    lg.circle("fill", S * 0.06, S * 0.95, S * 0.3, 40)
    -- halo doux derrière l'étoile
    for k = 1, 6 do
      lg.setColor(STAR[1], STAR[2], STAR[3], 0.035)
      lg.circle("fill", S * 0.5, S * 0.52, S * (0.20 + k * 0.045), 40)
    end
    lg.setStencilTest()
    T.icon("star", S * 0.5, S * 0.5, S * 0.66, STAR, 1)
    lg.pop()
    favCv[key] = cv
  end
  local cv = favCv[key]
  local s = size / cv:getWidth()
  lg.setColor(1, 1, 1, 1)
  lg.draw(cv, x, y, 0, s, s)
end

-- pochette de n'importe quel élément (album, "Tout mélanger", "Favoris")
function C.drawItem(item, x, y, size, t)
  if item.all then C.drawAll(x, y, size, t)
  elseif item.fav then C.drawFav(x, y, size)
  else C.draw(item, x, y, size) end
end

-- Dessine la pochette (arrondie) d'un album
function C.draw(album, x, y, size, alpha)
  alpha = alpha or 1
  local small = size <= 110
  local ci = album.ci or 4
  local ph = C.placeholder(ci, small)
  local ph_s = size / ph:getWidth()
  lg.setColor(1, 1, 1, alpha)
  lg.draw(ph, x, y, 0, ph_s, ph_s)
  if album.cvState == "ready" then
    album.used = frame
    album.fade = math.min(1, (album.fade or 1) + 0.08)
    local tex = small and album.thumbS or album.thumb
    local s = size / tex:getWidth()
    lg.setColor(1, 1, 1, alpha * album.fade)
    lg.draw(tex, x, y, 0, s, s)
  end
  lg.setColor(1, 1, 1, 1)
end

return C
