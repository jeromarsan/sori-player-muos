function love.conf(t)
  t.identity = "sori-player"
  t.version = "11.5"
  t.console = false

  t.window.title = "Sori Player"
  t.window.width = 640
  t.window.height = 480
  t.window.resizable = false
  t.window.vsync = 1
  t.window.msaa = 2
  t.window.fullscreen = os.getenv("SORI_FULLSCREEN") == "1"
  t.window.fullscreentype = "desktop"

  t.modules.physics = false
  t.modules.video = false
  t.modules.touch = false
  t.modules.mouse = false
end
