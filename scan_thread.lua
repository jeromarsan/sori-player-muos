-- Thread de scan : parcourt les dossiers musique, lit les tags, envoie les pistes au thread principal.
-- (id3.lua est collé juste avant ce fichier : la variable locale ID3 est disponible.)
local cfgName, outName = ...
require("love.filesystem")
require("love.thread")
local cfgCh = love.thread.getChannel(cfgName)
local out = love.thread.getChannel(outName)
local cfg = cfgCh:demand()

local AUDIO = { mp3 = true, ogg = true, oga = true, flac = true, wav = true }
local IMAGE = { jpg = true, jpeg = true, png = true }
local COVER_NAMES = { cover = 1, folder = 2, front = 3, album = 4, albumart = 5, artwork = 6, art = 7 }

local function sh(s) return "'" .. (s:gsub("'", "'\\''")) .. "'" end
local function nonempty(s) if s and s ~= "" then return s end end

-- Cache des tags (relance rapide)
local cache = {}
if not cfg.force then
  pcall(function()
    local data = love.filesystem.read("library.cache")
    if data then
      local fn = loadstring(data)
      if fn then
        local ok, t = pcall(fn)
        if ok and type(t) == "table" and t.v == 3 then cache = t.tracks or {} end
      end
    end
  end)
end

local seen, newcache, images = {}, {}, {}
local batch, total = {}, 0

local function flush()
  if #batch > 0 then out:push({ k = "tracks", list = batch }); batch = {} end
end

local function build(path, ext)
  local folder, file = path:match("^(.*)/([^/]*)$")
  folder = folder or ""
  file = file or path
  local base = file:gsub("%.[^.]*$", "")
  local fn, ft = base:match("^(%d+)[%s%.%-_]+(.+)$")
  local tag = ID3.read(path, ext)
  local parent = folder:match("([^/]*)$") or ""
  return {
    p = path, f = folder,
    t = nonempty(tag.title) or (ft or base):gsub("_", " "),
    ar = nonempty(tag.artist) or "",
    aa = nonempty(tag.albumartist) or "",
    al = nonempty(tag.album) or parent,
    na = not nonempty(tag.album), -- pas de tag album (nom du dossier utilisé)
    n = tag.track or tonumber(fn) or 0,
    d = tag.disc or 1,
    co = tag.cover,
  }
end

local exts = "\\( -iname '*.mp3' -o -iname '*.ogg' -o -iname '*.oga' -o -iname '*.flac' -o -iname '*.wav'"
  .. " -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\)"

for _, root in ipairs(cfg.roots) do
  local p = io.popen("find " .. sh(root) .. " -type f " .. exts .. " 2>/dev/null")
  if p then
    for line in p:lines() do
      local ext = (line:match("%.(%w+)$") or ""):lower()
      local lp = line:lower()
      if not seen[lp] then
        seen[lp] = true
        if AUDIO[ext] then
          local rec = cache[line]
          if not rec then rec = build(line, ext) end
          newcache[line] = rec
          batch[#batch + 1] = rec
          total = total + 1
          if #batch >= 20 then flush() end
        elseif IMAGE[ext] then
          local folder, file = line:match("^(.*)/([^/]*)$")
          if folder then
            local list = images[folder]
            if not list then list = {}; images[folder] = list end
            list[#list + 1] = file
          end
        end
      end
    end
    p:close()
  end
end
flush()

-- Choix des pochettes de dossier
local covers = {}
for folder, list in pairs(images) do
  local best, bestRank
  for _, file in ipairs(list) do
    local base = (file:gsub("%.[^.]*$", "")):lower()
    local rank = COVER_NAMES[base]
    if rank and (not bestRank or rank < bestRank) then best, bestRank = file, rank end
  end
  if not best and #list == 1 then best = list[1] end
  if best then covers[folder] = folder .. "/" .. best end
end

-- Sauvegarde du cache
pcall(function()
  local lines = { "return {v=3,tracks={" }
  for path, r in pairs(newcache) do
    lines[#lines + 1] = string.format("[%q]={p=%q,f=%q,t=%q,ar=%q,aa=%q,al=%q,na=%s,n=%d,d=%d,co=%s},",
      path, r.p, r.f, r.t, r.ar, r.aa, r.al, tostring(r.na == true), r.n or 0, r.d or 1,
      r.co and string.format("{off=%d,len=%d}", r.co.off, r.co.len) or "nil")
  end
  lines[#lines + 1] = "}}"
  love.filesystem.write("library.cache", table.concat(lines, "\n"))
end)

out:push({ k = "done", covers = covers, total = total })
