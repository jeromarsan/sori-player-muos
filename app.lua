-- État global partagé entre les écrans.
local T = require("theme")
local lg = love.graphics

local App = {
  VERSION = "1.0.0",
  screens = {}, current = nil, name = nil, stack = {},
  t = 0, trans = 1, transDir = 1,
  scale = 1, ox = 0, oy = 0,
  toast = nil, cfg = {}, roots = {},
}

---------------------------------------------------------------- navigation
function App.go(name, args)
  if App.name and App.name ~= name then App.stack[#App.stack + 1] = App.name end
  App.name, App.current = name, App.screens[name]
  App.trans, App.transDir = 0, 1
  if App.current.enter then App.current.enter(args or {}) end
end

function App.back()
  local prev = table.remove(App.stack)
  if not prev then return false end
  App.name, App.current = prev, App.screens[prev]
  App.trans, App.transDir = 0, -1
  if App.current.enter then App.current.enter({ back = true }) end
  return true
end

-- Bas de la zone de contenu (laisse la place au mini-lecteur)
function App.miniVisible()
  local P = App.player
  if not P.current or App.name == "now" then return false end
  if App.name == "tracks" and App.screens.tracks.album == P.current.album then return false end
  return true
end
function App.viewBottom() return App.miniVisible() and 390 or 456 end

function App.scissor(x, y, w, h)
  lg.setScissor(App.ox + x * App.scale, App.oy + y * App.scale, w * App.scale, h * App.scale)
end

-- Fil d'Ariane d'un album : "Musique" puis les dossiers sous le dossier musique
function App.crumbs(album)
  local c = { require("i18n").t("music") }
  if not album then return c end
  if album.all then c[2] = album.title; return c end
  local f = album.folder or ""
  local rel
  for _, r in ipairs(App.roots) do
    r = r:gsub("/+$", "")
    if f == r then rel = ""; break end
    if f:sub(1, #r + 1) == r .. "/" then rel = f:sub(#r + 2); break end
  end
  if rel == nil then rel = f:match("([^/]+)$") or "" end
  for seg in rel:gmatch("[^/]+") do c[#c + 1] = seg end
  if #c == 1 then c[2] = album.title end
  return c
end

function App.say(kind, value) App.toast = { kind = kind, value = value, life = 1.3 } end

---------------------------------------------------------------- réglages
function App.loadSettings()
  local ok, data = pcall(love.filesystem.read, "settings.lua")
  if ok and data then
    local fn = loadstring(data)
    if fn then
      local ok2, s = pcall(fn)
      if ok2 and type(s) == "table" then return s end
    end
  end
  return {}
end

function App.saveSettings()
  local P = App.player
  local s = string.format("return {volume=%.2f,shuffle=%s,repeatMode=%d,view=%q,theme=%q,accent=%q,lang=%q}",
    P.volume, tostring(P.shuffle), P.repeatMode, App.screens.albums.view or "grid", T.themeName, T.accentName,
    require("i18n").choice)
  pcall(love.filesystem.write, "settings.lua", s)
end

function App.loadConfig()
  local dirs = {}
  local env = os.getenv("SORI_DIR")
  if env and env ~= "" then dirs[#dirs + 1] = env end
  local base = love.filesystem.getSourceBaseDirectory()
  if base then dirs[#dirs + 1] = base end
  local src = love.filesystem.getSource()
  if src then dirs[#dirs + 1] = src end
  local cfg = { roots = {} }
  for _, d in ipairs(dirs) do
    local f = io.open(d .. "/sori.cfg", "r")
    if f then
      for line in f:lines() do
        line = line:gsub("\r", "")
        if not line:match("^%s*#") then
          local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
          if k then
            if k == "music_dir" then cfg.roots[#cfg.roots + 1] = v else cfg[k] = v end
          end
        end
      end
      f:close()
      cfg.dir = d
      break
    end
  end
  cfg.dir = cfg.dir or env or base
  if #cfg.roots == 0 then
    -- dossier MUSIC à la racine de la carte SD1 (/mnt/mmc) puis de la SD2 (/mnt/sdcard),
    -- quelle que soit la casse du nom (MUSIC, Music, music...)
    for _, card in ipairs({ "/mnt/mmc", "/mnt/sdcard" }) do
      local found
      local p = io.popen("ls -1 '" .. card .. "' 2>/dev/null")
      if p then
        for name in p:lines() do
          if name:lower() == "music" then
            found = card .. "/" .. name
            cfg.roots[#cfg.roots + 1] = found
          end
        end
        p:close()
      end
      if not found then cfg.roots[#cfg.roots + 1] = card .. "/MUSIC" end
    end
  end
  return cfg
end

return App
