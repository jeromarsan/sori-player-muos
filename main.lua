-- Sori Player — lecteur de musique (LÖVE 11.5 / muOS, Anbernic RG40XXV)
local T = require("theme")
local App = require("app")
local Lib = require("library")
local P = require("player")
local C = require("covers")
local W = require("widgets")
local lg = love.graphics
if os.getenv("SORI_TEST") then devtest = require("devtest") end

local held, down = {}, {}
local REPEAT = { up = true, down = true, left = true, right = true, l2 = true, r2 = true }
local rawLog = nil

local GAMEPAD = {
  a = "a", b = "b", x = "x", y = "y", leftshoulder = "l1", rightshoulder = "r1",
  start = "start", back = "select", guide = "menu",
  dpup = "up", dpdown = "down", dpleft = "left", dpright = "right",
}
local KEYS = {
  up = "up", down = "down", left = "left", right = "right", ["return"] = "a", backspace = "b",
  x = "x", y = "y", q = "l1", e = "r1", ["["] = "l2", ["]"] = "r2", tab = "start", rshift = "select", m = "menu",
}
-- Boutons sans mapping manette (dernier recours, modifiable dans sori.cfg : btn_a=… etc.)
-- MENU n'a pas de numéro connu : btn_menu=<numéro> dans sori.cfg si besoin (voir debug_input=1)
local RAWBTN = { a = 1, b = 0, x = 2, y = 3, l1 = 4, r1 = 5, select = 6, start = 7, l2 = 8, r2 = 9, menu = -1 }

function App.volume(delta)
  P:setVolume(P.volume + delta)
  App.say("volume", P.volume / (P.maxVolume > 0 and P.maxVolume or 1))
  App.saveSettings()
end

function App.rescan()
  Lib.start(App.roots, true)
end

-- lecture aléatoire de toute la musique (tous les dossiers MUSIC)
function App.shuffleAll()
  if #Lib.tracks == 0 then App.rescan(); return end
  P:setQueue(Lib.tracks, love.math.random(#Lib.tracks), true)
  App.go("now")
end

-- Veille écran : l'appli éteint elle-même le rétroéclairage (la console reste allumée,
-- la musique continue). Menu seul = éteindre ; n'importe quel bouton = rallumer ;
-- automatique après ecran_veille secondes sans bouton pendant la lecture (sori.cfg, 0 = jamais).
-- L1/R1/L2/R2 fonctionnent écran éteint sans le rallumer.
local BRIGHT = "/opt/muos/script/device/bright.sh"
local Screen = { off = false, idle = 0, delay = 60, can = false }
local SILENT = { l1 = true, r1 = true, l2 = true, r2 = true }

function App.screenOff()
  if Screen.off or not Screen.can then return end
  Screen.off = true
  os.execute(BRIGHT .. " 0 >/dev/null 2>&1 &")
end

function App.screenOn()
  Screen.idle = 0
  if not Screen.off then return end
  Screen.off = false
  local b = tonumber(os.getenv("SORI_BRIGHT") or "")
  if b and b > 0 then
    os.execute(BRIGHT .. " " .. math.floor(b) .. " transient >/dev/null 2>&1 &")
  else
    os.execute(BRIGHT .. " R >/dev/null 2>&1 &")
  end
end

-- Empêcher muOS de couper le son / d'assombrir / de mettre en veille pendant la lecture.
-- muhotkey relit ces fichiers toutes les 250 ms : s'ils contiennent le PID d'un processus vivant,
-- l'inactivité est ignorée (même mécanisme que pour les jeux). On les retire à la pause / en quittant.
local INHIBIT_FILES = { "/run/muos/idle_game_inhibit", "/run/muos/idle_sleep_inhibit" }
local Inhibit = { on = false, pid = nil, tried = false }

local function myPid()
  local f = io.open("/proc/self/stat", "r")
  if not f then return nil end
  local line = f:read("*l") or ""
  f:close()
  return line:match("^(%d+)")
end

function App.setIdleInhibit(on)
  if on == Inhibit.on then return end
  if not Inhibit.tried then Inhibit.tried = true; Inhibit.pid = myPid() end
  if not Inhibit.pid then return end -- pas sur la console (PC)
  Inhibit.on = on
  print(string.format("[sori] veille muOS %s (pid %s)", on and "bloquee" or "liberee", Inhibit.pid))
  for _, path in ipairs(INHIBIT_FILES) do
    if on then
      local f, err = io.open(path, "w")
      if f then f:write(Inhibit.pid, "\n"); f:close() else print("[sori] impossible d'ecrire " .. path .. " : " .. tostring(err)) end
    else
      -- on ne supprime que si c'est bien notre PID
      local f = io.open(path, "r")
      local cur = f and f:read("*l")
      if f then f:close() end
      if cur == Inhibit.pid then os.remove(path) end
    end
  end
end

local menuSolo, swallowed = false, {}
local shotCombo, volBefore = false, nil -- capture d'écran muOS (L2 + R2 + X)

-- L1 / R1 seuls = morceau précédent / suivant, déclenché au relâchement ;
-- L1 + R1 ensemble = lecture aléatoire de toute la musique.
local shoulderPending, shoulderCombo = {}, false

local function press(a)
  if swallowed[a] then return end -- répétition d'un bouton qui a servi à rallumer l'écran
  down[a] = true
  Screen.idle = 0
  if a ~= "menu" then menuSolo = false end
  -- écran éteint : on rallume et on ignore ce bouton (sauf piste / volume)
  if Screen.off and not SILENT[a] then
    App.screenOn()
    swallowed[a] = true
    return
  end
  if a == "menu" then menuSolo = true end
  -- quitter : MENU + START ou SELECT + START (dans n'importe quel ordre)
  if (a == "start" and (down.select or down.menu)) or ((a == "select" or a == "menu") and down.start) then
    love.event.quit()
    return
  end
  if a == "l1" or a == "r1" then
    local other = (a == "l1") and "r1" or "l1"
    if down[other] then
      shoulderCombo = true
      shoulderPending = {}
      App.shuffleAll()
    elseif not shoulderCombo then
      shoulderPending[a] = true
    end
    return
  end
  -- L2 + R2 ensemble = capture d'écran muOS (L2 + R2 + X) : on annule le volume,
  -- on cache le bandeau et on ignore X, pour que la capture soit propre.
  if a == "l2" or a == "r2" then
    local other = (a == "l2") and "r2" or "l2"
    if down[other] then
      shotCombo = true
      held.l2, held.r2 = nil, nil
      if volBefore then P:setVolume(volBefore); App.saveSettings() end
      App.toast = nil
      return
    end
    if shotCombo then return end
    if not held[a] then volBefore = P.volume end -- 1er appui (pas une répétition)
    App.volume(a == "l2" and -0.05 or 0.05)
    return
  end
  if shotCombo and (down.l2 or down.r2) then return end -- X de la capture, etc.
  if App.current and App.current.action then App.current.action(a) end
end
App.press = press

local function release(a)
  down[a] = nil; held[a] = nil
  if swallowed[a] then swallowed[a] = nil; return end
  -- Menu appuyé seul (sans autre bouton) = éteindre l'écran
  if a == "menu" and menuSolo then menuSolo = false; App.screenOff() end
  if (a == "l2" or a == "r2") and not down.l2 and not down.r2 then shotCombo = false end
  if a == "l1" or a == "r1" then
    if shoulderPending[a] then
      shoulderPending[a] = nil
      if a == "l1" then P:prev() else P:next() end
    end
    if not down.l1 and not down.r1 then shoulderCombo = false end
  end
end

-- sori.cfg : inverser_ab=1 / inverser_xy=1 si A/B ou X/Y sont à l'envers sur une autre console
local function flipAB(l)
  if App.cfg.inverser_ab == "1" then
    if l == "a" then return "b" elseif l == "b" then return "a" end
  end
  if App.cfg.inverser_xy == "1" then
    if l == "x" then return "y" elseif l == "y" then return "x" end
  end
  return l
end

local function logical(name)
  -- pas d'inversion X/Y par défaut (correct sur la RG40XXV sous muOS)
  return flipAB(GAMEPAD[name])
end

function love.load()
  lg.setDefaultFilter("linear", "linear")
  lg.setBackgroundColor(T.c.bg)
  love.keyboard.setKeyRepeat(false)
  T.load()
  App.cfg = App.loadConfig()
  App.roots = App.cfg.roots
  App.player, App.lib = P, Lib
  love.math.setRandomSeed(os.time())

  local st = App.loadSettings()
  -- choix faits dans Réglages > sinon sori.cfg > sinon sombre + bleu
  T.setTheme(st.theme or App.cfg.theme or "sombre")
  T.setAccent(st.accent or App.cfg.couleur or "bleu")
  require("i18n").set(st.lang or App.cfg.langue or "auto")
  Lib.relabel()
  lg.setBackgroundColor(T.c.bg)
  P.maxVolume = tonumber(App.cfg.max_volume) or 1.0
  P:setVolume(st.volume or tonumber(App.cfg.start_volume) or 0.6)
  if st.shuffle then P.shuffle = true end
  P.repeatMode = st.repeatMode or 0

  App.screens = {
    splash = require("screens.splash"),
    settings = require("screens.settings"),
    albums = require("screens.albums"),
    tracks = require("screens.tracks"),
    now = require("screens.now"),
    help = require("screens.help"),
  }
  if st.view then App.screens.albums.view = st.view end
  if st.mode == "artists" then App.screens.albums.mode = "artists" end
  if App.cfg.debug_input == "1" then rawLog = {} end
  Screen.delay = tonumber(App.cfg.ecran_veille) or 60
  local bf = io.open(BRIGHT, "r") -- uniquement sur la console (pas sur PC)
  if bf then bf:close(); Screen.can = true end

  C.init()
  require("favs").load()
  Lib.start(App.roots, false)
  App.go(devtest and "albums" or "splash")
  if devtest then devtest.load() end
end

function love.update(dt)
  dt = math.min(dt, 0.1)
  App.t = App.t + dt
  Lib.update()
  P:update(dt)
  C.update(dt)
  App.trans = math.min(1, App.trans + dt * 5)
  if App.toast then
    App.toast.life = App.toast.life - dt
    if App.toast.life <= 0 then App.toast = nil end
  end
  for a, t in pairs(held) do
    held[a] = t + dt
    if held[a] > 0.38 then
      held[a] = 0.38 - 0.075
      press(a)
    end
  end
  if App.current and App.current.update then App.current.update(dt) end
  if devtest then devtest.update(dt) end
  -- muOS ne doit ni couper le son ni mettre en veille tant que la musique joue
  App.setIdleInhibit(P.state == "playing" or P.state == "loading")
  -- veille écran automatique pendant la lecture
  if not Screen.off and Screen.delay > 0 and P.state == "playing" then
    Screen.idle = Screen.idle + dt
    if Screen.idle >= Screen.delay then App.screenOff() end
  else
    if P.state ~= "playing" then Screen.idle = 0 end
  end
end

function love.draw()
  if Screen.off then lg.clear(0, 0, 0); return end -- rien à dessiner écran éteint (économie de batterie)
  local w, h = lg.getDimensions()
  local s = math.min(w / T.W, h / T.H)
  App.scale, App.ox, App.oy = s, (w - T.W * s) / 2, (h - T.H * s) / 2
  lg.clear(T.c.bg)
  lg.push()
  lg.translate(App.ox, App.oy)
  lg.scale(s)
  lg.setScissor(App.ox, App.oy, T.W * s, T.H * s)

  local e = T.ease(App.trans)
  lg.push()
  lg.translate((1 - e) * 36 * App.transDir, 0)
  if App.current then App.current.draw() end
  lg.pop()
  if e < 1 then
    lg.setColor(T.c.bg[1], T.c.bg[2], T.c.bg[3], (1 - e) * 0.85)
    lg.rectangle("fill", 0, 0, T.W, T.H)
  end
  W.toast()
  if rawLog then
    lg.setFont(T.f.small); T.set(T.c.ink, 0.9)
    lg.print(table.concat(rawLog, "  "), 8, 8)
  end
  lg.setScissor()
  lg.pop()
end

-- Entrées -------------------------------------------------------------
local function pressed(name)
  if not name then return end
  press(name)
  if REPEAT[name] then held[name] = 0 end
end

function love.gamepadpressed(js, button)
  if rawLog then rawLog = { "gp:" .. button } end
  pressed(logical(button))
end
function love.gamepadreleased(js, button)
  local n = logical(button); if n then release(n) end
end

local trig = {}
function love.gamepadaxis(js, axis, value)
  local name = (axis == "triggerleft") and "l2" or (axis == "triggerright") and "r2" or nil
  if not name then return end
  if value > 0.5 and not trig[name] then trig[name] = true; pressed(name)
  elseif value < 0.3 and trig[name] then trig[name] = nil; release(name) end
end

function love.joystickpressed(js, button)
  if rawLog then rawLog = { "joy:" .. button } end
  if js:isGamepad() then return end
  for name, idx in pairs(RAWBTN) do
    local over = tonumber(App.cfg["btn_" .. name])
    if (over or idx) == button then pressed(flipAB(name)); return end
  end
end
function love.joystickreleased(js, button)
  if js:isGamepad() then return end
  for name, idx in pairs(RAWBTN) do
    if (tonumber(App.cfg["btn_" .. name]) or idx) == button then release(flipAB(name)) end
  end
end
function love.joystickhat(js, hat, dir)
  if js:isGamepad() then return end
  for _, n in ipairs({ "up", "down", "left", "right" }) do release(n) end
  local map = { u = "up", d = "down", l = "left", r = "right", lu = "up", ld = "down", ru = "up", rd = "down" }
  if dir ~= "c" and map[dir] then pressed(map[dir]) end
end

function love.keypressed(key)
  if key == "escape" then love.event.quit(); return end
  pressed(KEYS[key])
end
function love.keyreleased(key)
  local n = KEYS[key]; if n then release(n) end
end

function love.quit()
  App.setIdleInhibit(false)
  App.screenOn()
  App.saveSettings()
  C.shutdown()
end
