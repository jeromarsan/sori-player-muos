-- Bibliothèque : lance le scan en thread, regroupe les pistes en albums.
local I = require("i18n")
local T = require("theme")
local Favs = require("favs")
local Lib = {
  tracks = {}, albums = {}, state = "idle", count = 0, version = 0,
  all = { all = true, title = "Tout mélanger", artist = "", tracks = {} },
  -- pseudo-album des morceaux favoris (dans l'ordre d'ajout)
  fav = { fav = true, title = "Favoris", artist = "", tracks = {}, tint = { 1.0, 0.80, 0.22 }, ci = 6 },
}

function Lib.refreshFavs()
  local list = {}
  for _, t in ipairs(Lib.tracks) do
    if Favs.isTrack(t) then list[#list + 1] = t end
  end
  table.sort(list, function(a, b) return Favs.tracks[a.p] < Favs.tracks[b.p] end)
  Lib.fav.tracks = list
  Lib.favVersion = Favs.version
end

local FOLD = {
  ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
  ["î"] = "i", ["ï"] = "i", ["ô"] = "o", ["ö"] = "o", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
  ["ç"] = "c", ["É"] = "e", ["È"] = "e", ["À"] = "a", ["Ç"] = "c", ["Ô"] = "o", ["Î"] = "i",
}
local function fold(s)
  s = s:gsub("[\195][\128-\191]", function(c) return FOLD[c] or c end)
  return s:lower()
end

local scanCount = 0

function Lib.start(roots, force)
  scanCount = scanCount + 1
  local cfgName, outName = "scan_cfg" .. scanCount, "scan_out" .. scanCount
  local id3 = love.filesystem.read("id3.lua")
  local scan = love.filesystem.read("scan_thread.lua")
  local code = "local ID3 = (function()\n" .. id3 .. "\nend)()\n" .. scan
  Lib.thread = love.thread.newThread(code)
  Lib.outName = outName
  Lib.tracks, Lib.count, Lib.state = {}, 0, "scanning"
  love.thread.getChannel(cfgName):push({ roots = roots, force = force })
  Lib.thread:start(cfgName, outName)
end

-- Vue "Artistes" : un artiste = l'artiste de chaque morceau (sinon l'artiste de l'album).
-- Il contient ses albums, et un dossier "Sans album" pour ses morceaux sans tag album.
local UNKNOWN_KEY = "\255unknown" -- trié en dernier
function Lib.buildArtists(albums)
  local by, list = {}, {}
  for _, a in ipairs(albums) do
    for _, t in ipairs(a.tracks) do
      local name = (t.ar ~= "" and t.ar) or a.aa or ""
      local key = name ~= "" and fold(name) or UNKNOWN_KEY
      local ar = by[key]
      if not ar then
        ar = { artistItem = true, title = name, unknown = (name == ""), sortkey = key, key = "artist|" .. key,
               albums = {}, albumSet = {}, loose = {}, tracks = {} }
        if ar.unknown then ar.title = I.t("unknown_artist") end
        by[key] = ar
        list[#list + 1] = ar
      end
      ar.tracks[#ar.tracks + 1] = t
      if t.na then
        ar.loose[#ar.loose + 1] = t
      elseif not ar.albumSet[a] then
        ar.albumSet[a] = true
        ar.albums[#ar.albums + 1] = a -- déjà dans l'ordre alphabétique des albums
      end
    end
  end
  table.sort(list, function(x, y) return x.sortkey < y.sortkey end)
  for _, ar in ipairs(list) do
    ar.albumSet = nil
    -- image de l'artiste : son 1er album avec pochette, sinon l'album de son 1er morceau
    for _, a in ipairs(ar.albums) do if a.cover then ar.rep = a; break end end
    ar.rep = ar.rep or ar.albums[1] or (ar.tracks[1] and ar.tracks[1].album)
    if #ar.loose > 0 then
      table.sort(ar.loose, function(x, y) return fold(x.t) < fold(y.t) end)
      for i, t in ipairs(ar.loose) do t.li = i end
      ar.noalbum = { noalbum = true, title = I.t("no_album"), artist = ar.title, tracks = ar.loose,
                     key = "noalbum|" .. ar.sortkey, cvState = "none", ci = 4, tint = T.logoColor(0.55) }
    end
  end
  return list
end

local function build(covers)
  local byKey, albums = {}, {}
  for _, r in ipairs(Lib.tracks) do
    local key = r.f .. "|" .. r.al:lower()
    local a = byKey[key]
    if not a then
      a = { key = key, title = r.al, tracks = {}, folder = r.f, artists = {} }
      byKey[key] = a
      albums[#albums + 1] = a
    end
    a.tracks[#a.tracks + 1] = r
    if r.aa ~= "" then a.aa = r.aa end
    if r.ar ~= "" then a.artists[r.ar] = true end
    r.album = a
  end
  for _, a in ipairs(albums) do
    table.sort(a.tracks, function(x, y)
      if x.d ~= y.d then return x.d < y.d end
      if x.n ~= y.n then return x.n < y.n end
      return x.p < y.p
    end)
    for i, t in ipairs(a.tracks) do t.i = i end
    local n, only = 0, nil
    for name in pairs(a.artists) do n = n + 1; only = name end
    a.various = (not a.aa) and n > 1
    a.artist = a.aa or (n == 1 and only) or (a.various and I.t("various")) or ""
    a.artists = nil
    for _, t in ipairs(a.tracks) do
      if t.co then a.cover = { path = t.p, off = t.co.off, len = t.co.len }; break end
    end
    if not a.cover and covers[a.folder] then a.cover = { path = covers[a.folder] } end
    a.sortkey = fold(a.title)
  end
  table.sort(albums, function(x, y)
    if x.sortkey ~= y.sortkey then return x.sortkey < y.sortkey end
    return x.key < y.key
  end)
  for i, a in ipairs(albums) do a.idx = i end
  Lib.albums = albums
  Lib.artists = Lib.buildArtists(albums)
  Lib.all.tracks = Lib.tracks
  Lib.refreshFavs()
  Lib.version = Lib.version + 1
end

-- après un changement de langue
function Lib.relabel()
  Lib.all.title = I.t("all_title")
  Lib.fav.title = I.t("favorites")
  for _, a in ipairs(Lib.albums) do
    if a.various then a.artist = I.t("various") end
  end
  for _, ar in ipairs(Lib.artists or {}) do
    if ar.unknown then ar.title = I.t("unknown_artist") end
    if ar.noalbum then ar.noalbum.title = I.t("no_album"); ar.noalbum.artist = ar.title end
  end
end

function Lib.update()
  if Lib.state ~= "scanning" then return end
  local ch = love.thread.getChannel(Lib.outName)
  local t0 = love.timer.getTime()
  while love.timer.getTime() - t0 < 0.004 do
    local m = ch:pop()
    if not m then break end
    if m.k == "tracks" then
      for _, r in ipairs(m.list) do Lib.tracks[#Lib.tracks + 1] = r end
      Lib.count = #Lib.tracks
    elseif m.k == "done" then
      build(m.covers)
      Lib.state = "ready"
      return
    end
  end
  local err = Lib.thread:getError()
  if err then Lib.state = "error"; Lib.err = err end
end

return Lib
