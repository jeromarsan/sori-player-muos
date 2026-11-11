-- Moteur de lecture : file d'attente, aléatoire, répétition, volume.
local P = {
  queue = {}, order = {}, pos = 0,
  shuffle = false, repeatMode = 0, -- 0 = non, 1 = tout, 2 = un seul morceau
  volume = 0.7, maxVolume = 1.0,
  state = "stopped", -- stopped | loading | playing | paused
  current = nil, src = nil, fd = nil, duration = -1,
  bump = 0, -- animation de rebond (changement de piste)
}

local function shuffled(n, first)
  local o = {}
  for i = 1, n do o[i] = i end
  for i = n, 2, -1 do
    local j = love.math.random(i)
    o[i], o[j] = o[j], o[i]
  end
  if first then
    for i = 1, n do
      if o[i] == first then o[1], o[i] = o[i], o[1]; break end
    end
  end
  return o
end

function P:build(startIdx)
  local n = #self.queue
  if self.shuffle then
    self.order = shuffled(n, startIdx)
    self.pos = 1
  else
    self.order = {}
    for i = 1, n do self.order[i] = i end
    self.pos = startIdx or 1
  end
end

function P:setQueue(tracks, startIdx, forceShuffle)
  if #tracks == 0 then return end
  if forceShuffle ~= nil then self.shuffle = forceShuffle end
  self.queue = tracks
  self:build(startIdx or 1)
  self.fails = 0
  self:load(true)
end

function P:unload()
  if self.src then
    self.src:stop()
    self.src:release()
  end
  self.src, self.fd = nil, nil
  self.duration = -1
end

function P:load(autoplay)
  self:unload()
  self.current = self.queue[self.order[self.pos]]
  self.state = "loading"
  self.autoplay = autoplay
  self.loadDelay = 0.04 -- laisse une image s'afficher avant la lecture disque
  self.bump = 1
  if self.onTrack then self.onTrack(self.current) end
end

function P:doLoad()
  local t = self.current
  local ok = false
  local f = io.open(t.p, "rb")
  if f then
    local data = f:read("*a")
    f:close()
    local ok2, fd = pcall(love.filesystem.newFileData, data, t.p:match("[^/]+$") or "track")
    if ok2 then
      local ok3, src = pcall(love.audio.newSource, fd, "stream")
      if ok3 then
        self.fd, self.src, ok = fd, src, true
      end
    end
  end
  if ok then
    self.duration = self.src:getDuration("seconds") or -1
    if self.autoplay then
      self.src:play()
      self.state = "playing"
    else
      self.state = "paused"
    end
    self.fails = 0
  else
    t.bad = true
    self.fails = (self.fails or 0) + 1
    if self.fails < #self.queue then self:advance(true) else self.state = "stopped" end
  end
end

function P:advance(auto)
  local n = #self.order
  if self.pos < n then
    self.pos = self.pos + 1
    self:load(true)
  elseif self.repeatMode == 1 or not auto then
    if self.shuffle then
      local cur = self.order[self.pos]
      self:build(love.math.random(#self.queue))
      if #self.queue > 1 and self.order[1] == cur then self.order[1], self.order[2] = self.order[2], self.order[1] end
    else
      self.pos = 1
    end
    self:load(true)
  else
    self.pos = 1
    self:load(false) -- fin de la liste : on s'arrête sur le 1er morceau
  end
end

function P:next() if #self.queue > 0 then self:advance(false) end end

function P:prev()
  if #self.queue == 0 then return end
  if self:position() > 3 or self.pos <= 1 then
    if self.src then self.src:seek(0, "seconds") end
    if self.state == "paused" then return end
    if self.state == "stopped" then self:load(true) end
  else
    self.pos = self.pos - 1
    self:load(true)
  end
end

function P:toggle()
  if self.state == "playing" then
    self.src:pause()
    self.state = "paused"
  elseif self.state == "paused" and self.src then
    self.src:play()
    self.state = "playing"
  elseif self.state == "stopped" and #self.queue > 0 then
    self:load(true)
  end
end

function P:position()
  if self.src and (self.state == "playing" or self.state == "paused") then
    return self.src:tell("seconds") or 0
  end
  return 0
end

function P:progress()
  if self.duration and self.duration > 0 then return math.min(1, self:position() / self.duration) end
  return 0
end

function P:seek(delta)
  if not self.src then return end
  local p = self:position() + delta
  if self.duration and self.duration > 0 then p = math.min(p, self.duration - 0.3) end
  self.src:seek(math.max(p, 0), "seconds")
end

function P:setVolume(v)
  self.volume = math.max(0, math.min(self.maxVolume, v))
  love.audio.setVolume(self.volume)
end

function P:toggleShuffle()
  self.shuffle = not self.shuffle
  if #self.queue > 0 then self:build(self.order[self.pos]) end
end

function P:cycleRepeat() self.repeatMode = (self.repeatMode + 1) % 3 end

function P:update(dt)
  self.bump = math.max(0, self.bump - dt * 3)
  if self.state == "loading" then
    self.loadDelay = self.loadDelay - dt
    if self.loadDelay <= 0 then self:doLoad() end
  elseif self.state == "playing" and self.src and not self.src:isPlaying() then
    if self.repeatMode == 2 then self:load(true) else self:advance(true) end
  end
end

return P
