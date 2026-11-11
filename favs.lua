-- Favoris : morceaux (par chemin) et albums (par clé dossier|album), enregistrés dans favorites.lua
local F = { tracks = {}, albums = {}, seq = 0, version = 0 }

function F.load()
  local ok, data = pcall(love.filesystem.read, "favorites.lua")
  if not ok or not data then return end
  local fn = loadstring(data)
  if not fn then return end
  local ok2, t = pcall(fn)
  if ok2 and type(t) == "table" then
    F.tracks = type(t.tracks) == "table" and t.tracks or {}
    F.albums = type(t.albums) == "table" and t.albums or {}
    F.seq = tonumber(t.seq) or 0
  end
end

function F.save()
  local out = { "return {seq=" .. F.seq .. ",tracks={" }
  for k, n in pairs(F.tracks) do out[#out + 1] = string.format("[%q]=%d,", k, n) end
  out[#out + 1] = "},albums={"
  for k, n in pairs(F.albums) do out[#out + 1] = string.format("[%q]=%d,", k, n) end
  out[#out + 1] = "}}"
  pcall(love.filesystem.write, "favorites.lua", table.concat(out, "\n"))
end

local function toggle(set, key)
  if set[key] then set[key] = nil
  else F.seq = F.seq + 1; set[key] = F.seq end
  F.version = F.version + 1
  F.save()
  return set[key] ~= nil
end

function F.isTrack(t) return t ~= nil and t.p ~= nil and F.tracks[t.p] ~= nil end
function F.isAlbum(a) return a ~= nil and a.key ~= nil and F.albums[a.key] ~= nil end
function F.toggleTrack(t) return toggle(F.tracks, t.p) end
function F.toggleAlbum(a) return toggle(F.albums, a.key) end

return F
