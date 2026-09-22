local env = require("modules.env")
local bin = env.bin

hl.on("hyprland.start", function()
  hl.exec_cmd("noctalia")
  -- Apply the gamepad preset (Hyprland does not run /etc/xdg/autostart)
  hl.exec_cmd("input-remapper-control --command autoload")
  -- Wake the LG TV over the network (Wake-on-LAN)
  hl.exec_cmd(bin("tv on"))
end)
