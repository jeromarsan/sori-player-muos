-- Lecture des tags (MP3 ID3v2/v1, FLAC, OGG Vorbis) en Lua pur.
-- Ce fichier est exécuté DANS le thread de scan (voir scan_thread.lua).
local M = {}

local function b(s, i) return s:byte(i) or 0 end
local function be32(s, i) return ((b(s, i) * 256 + b(s, i + 1)) * 256 + b(s, i + 2)) * 256 + b(s, i + 3) end
local function le32(s, i) return ((b(s, i + 3) * 256 + b(s, i + 2)) * 256 + b(s, i + 1)) * 256 + b(s, i) end
local function syncsafe(s, i) return ((b(s, i) * 128 + b(s, i + 1)) * 128 + b(s, i + 2)) * 128 + b(s, i + 3) end

local function cp2u8(cp)
  if cp < 0x80 then return string.char(cp)
  elseif cp < 0x800 then return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
  elseif cp < 0x10000 then
    return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
  end
  return string.char(0xF0 + math.floor(cp / 262144), 0x80 + math.floor(cp / 4096) % 64,
    0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
end

local function latin1(s)
  return (s:gsub("[\128-\255]", function(c)
    local x = c:byte()
    if x < 192 then return "\194" .. c end
    return "\195" .. string.char(x - 64)
  end))
end

local function isutf8(s)
  local i, n = 1, #s
  while i <= n do
    local c = s:byte(i)
    local len = c < 0x80 and 1 or (c >= 0xC2 and c < 0xE0) and 2 or (c >= 0xE0 and c < 0xF0) and 3
      or (c >= 0xF0 and c < 0xF5) and 4 or 0
    if len == 0 or i + len - 1 > n then return false end
    for k = 1, len - 1 do
      local cc = s:byte(i + k)
      if cc < 0x80 or cc > 0xBF then return false end
    end
    i = i + len
  end
  return true
end

local function utf16(s, bigendian)
  local out, i, n = {}, 1, #s
  if s:sub(1, 2) == "\255\254" then bigendian = false; i = 3
  elseif s:sub(1, 2) == "\254\255" then bigendian = true; i = 3 end
  while i + 1 <= n do
    local a, c = s:byte(i, i + 1)
    local u = bigendian and a * 256 + c or c * 256 + a
    i = i + 2
    if u >= 0xD800 and u < 0xDC00 and i + 1 <= n then
      local a2, c2 = s:byte(i, i + 1)
      local l = bigendian and a2 * 256 + c2 or c2 * 256 + a2
      if l >= 0xDC00 and l < 0xE000 then u = 0x10000 + (u - 0xD800) * 1024 + (l - 0xDC00); i = i + 2 end
    end
    if u == 0 then break end
    out[#out + 1] = cp2u8(u)
  end
  return table.concat(out)
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function decode(enc, s)
  local r
  if enc == 1 then r = utf16(s, false)
  elseif enc == 2 then r = utf16(s, true)
  else
    r = s:match("^[^%z]*")
    if enc == 0 and not isutf8(r) then r = latin1(r) end
  end
  return trim(r)
end

local MAP22 = { TT2 = "TIT2", TAL = "TALB", TP1 = "TPE1", TP2 = "TPE2", TRK = "TRCK", TPA = "TPOS", PIC = "APIC" }
local TEXT = { TIT2 = "title", TALB = "album", TPE1 = "artist", TPE2 = "albumartist", TRCK = "track", TPOS = "disc" }

local function readID3v2(f, r)
  f:seek("set", 0)
  local h = f:read(10)
  if not h or #h < 10 or h:sub(1, 3) ~= "ID3" then return end
  local ver, flags = h:byte(4), h:byte(6)
  local limit = 10 + syncsafe(h, 7)
  local pos = 10
  if ver >= 3 and math.floor(flags / 64) % 2 == 1 then
    local eh = f:read(4)
    if not eh or #eh < 4 then return end
    pos = pos + ((ver == 4) and syncsafe(eh, 1) or (be32(eh, 1) + 4))
  end
  local idlen = (ver == 2) and 3 or 4
  local hlen = (ver == 2) and 6 or 10
  while pos + hlen <= limit do
    f:seek("set", pos)
    local fh = f:read(hlen)
    if not fh or #fh < hlen then break end
    local id = fh:sub(1, idlen)
    if b(id, 1) == 0 then break end
    local fsz
    if ver == 2 then fsz = (b(fh, 4) * 256 + b(fh, 5)) * 256 + b(fh, 6)
    elseif ver == 4 then fsz = syncsafe(fh, 5)
    else fsz = be32(fh, 5) end
    if fsz <= 0 or pos + hlen + fsz > limit then break end
    local key = MAP22[id] or id
    local field = TEXT[key]
    if field and fsz <= 4096 and not r[field] then
      local d = f:read(fsz)
      if d and #d > 1 then
        local v = decode(d:byte(1), d:sub(2))
        if field == "track" or field == "disc" then v = tonumber(v:match("^%d+")) end
        if v and v ~= "" then r[field] = v end
      end
    elseif key == "APIC" and r.coverType ~= 3 then
      local head = f:read(math.min(fsz, 300))
      if head and #head > 8 then
        local enc = head:byte(1)
        local p
        if ver == 2 then p = 5 else
          local z = head:find("\0", 2, true)
          p = z and (z + 1) or nil
        end
        if p then
          local ptype = head:byte(p); p = p + 1
          if enc == 1 or enc == 2 then
            while p + 1 <= #head and not (head:byte(p) == 0 and head:byte(p + 1) == 0) do p = p + 2 end
            p = p + 2
          else
            local z = head:find("\0", p, true)
            p = z and (z + 1) or nil
          end
          if p and p <= #head + 1 and fsz - (p - 1) > 100 then
            r.cover = { off = pos + hlen + (p - 1), len = fsz - (p - 1) }
            r.coverType = ptype
          end
        end
      end
    end
    pos = pos + hlen + fsz
  end
end

local function readID3v1(f, r)
  local size = f:seek("end")
  if not size or size < 128 then return end
  f:seek("set", size - 128)
  local d = f:read(128)
  if not d or d:sub(1, 3) ~= "TAG" then return end
  local function fld(a, z) return trim(decode(0, d:sub(a, z))) end
  r.title = r.title or fld(4, 33)
  r.artist = r.artist or fld(34, 63)
  r.album = r.album or fld(64, 93)
  if not r.track and d:byte(126) == 0 and d:byte(127) ~= 0 then r.track = d:byte(127) end
end

local function vorbis(s, pos, r)
  local vl = le32(s, pos); pos = pos + 4 + vl
  local cnt = le32(s, pos); pos = pos + 4
  for _ = 1, math.min(cnt, 200) do
    if pos + 4 > #s then break end
    local l = le32(s, pos); pos = pos + 4
    local kv = s:sub(pos, pos + l - 1); pos = pos + l
    local k, v = kv:match("^([^=]+)=(.*)$")
    if k then
      k = k:upper()
      if k == "TITLE" then r.title = v
      elseif k == "ARTIST" then r.artist = v
      elseif k == "ALBUM" then r.album = v
      elseif k == "ALBUMARTIST" then r.albumartist = v
      elseif k == "TRACKNUMBER" then r.track = tonumber(v:match("^%d+"))
      elseif k == "DISCNUMBER" then r.disc = tonumber(v:match("^%d+")) end
    end
  end
end

local function readFlac(f, r)
  f:seek("set", 0)
  if f:read(4) ~= "fLaC" then return end
  local pos = 4
  for _ = 1, 64 do
    f:seek("set", pos)
    local h = f:read(4)
    if not h or #h < 4 then break end
    local last = h:byte(1) >= 128
    local typ = h:byte(1) % 128
    local len = (b(h, 2) * 256 + b(h, 3)) * 256 + b(h, 4)
    if typ == 4 and len < 262144 then
      local d = f:read(len)
      if d then vorbis(d, 1, r) end
    elseif typ == 6 then
      local d = f:read(math.min(len, 4096))
      if d and #d > 32 then
        local ptype = be32(d, 1)
        local ml = be32(d, 5)
        local dl = be32(d, 9 + ml)
        local datalen = be32(d, 29 + ml + dl)
        if (ptype == 3 or not r.cover) and datalen > 100 then
          r.cover = { off = pos + 4 + (33 + ml + dl - 1), len = datalen }
        end
      end
    end
    if last then break end
    pos = pos + 4 + len
  end
end

local function readOgg(f, r)
  f:seek("set", 0)
  local d = f:read(65536)
  if not d then return end
  local i = d:find("\3vorbis", 1, true)
  if i then vorbis(d, i + 7, r) end
end

function M.read(path, ext)
  local f = io.open(path, "rb")
  if not f then return {} end
  local r = {}
  pcall(function()
    if ext == "mp3" then
      readID3v2(f, r)
      if not r.title or not r.album then readID3v1(f, r) end
    elseif ext == "flac" then readFlac(f, r)
    elseif ext == "ogg" or ext == "oga" then readOgg(f, r) end
  end)
  f:close()
  r.coverType = nil
  return r
end

return M
