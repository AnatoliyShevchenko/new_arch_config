---------------------
---- KEYBINDINGS ----
---------------------

local env         = require("modules.env")
local bin         = env.bin
local terminal    = env.terminal
local fileManager = env.fileManager
local menu        = env.menu

local mainMod = "SUPER"
local ipc = "noctalia msg "

-- Core binds
hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. "+S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))
hl.bind("PRINT", hl.dsp.exec_cmd(ipc .. "screenshot-region"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
-- Power menu (Noctalia session panel: lock/suspend/logout/reboot/shutdown)
-- Also the target for the gamepad View+Menu chord via input-remapper
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(ipc .. "panel-toggle session"))
-- Sleep timer: cycles 30 -> 60 -> 90 -> off. Gamepad chord View+X.
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(bin("sleeptimer")))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Workspace prev/next on keys (drives gamepad LB/RB via input-remapper)
hl.bind(mainMod .. " + bracketleft",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Громкость ТЕЛЕВИЗОРА по сети (аккорд View + D-pad на геймпаде).
-- Не XF86Audio*: те уже заняты дважды и крутят поток по HDMI, а не сам телевизор.
-- flock -n схлопывает автоповтор: пока запрос к телевизору в полёте (~90 мс),
-- следующие нажатия молча пропускаются, иначе громкость улетает лавиной.
local tvlock = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/tv-vol.lock"
local function tvvol(dir) return "flock -n " .. tvlock .. " " .. bin("tv") .. " vol" .. dir .. " 1" end
-- SUPER+SHIFT+up/down — это то, во что input-remapper превращает аккорд View+D-pad
-- на геймпаде. Шаг 1, потому что там срабатывает автоповтор при удержании.
hl.bind(mainMod .. " + SHIFT + up",   hl.dsp.exec_cmd(tvvol("+")), { locked = true, repeating = true })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.exec_cmd(tvvol("-")), { locked = true, repeating = true })

-- Клавиатурная группа телевизора: SUPER+ALT (свободен целиком). Шаг крупнее —
-- пальцем жмут разово, а не удерживают.
local function tvcmd(args) return "flock -n " .. tvlock .. " " .. bin("tv") .. " " .. args end
hl.bind(mainMod .. " + ALT + up",   hl.dsp.exec_cmd(tvcmd("vol+ 2")), { locked = true, repeating = true })
hl.bind(mainMod .. " + ALT + down", hl.dsp.exec_cmd(tvcmd("vol- 2")), { locked = true, repeating = true })
hl.bind(mainMod .. " + ALT + M",    hl.dsp.exec_cmd(tvcmd("mute")),   { locked = true })
hl.bind(mainMod .. " + ALT + I",    hl.dsp.exec_cmd(tvcmd("on")),     { locked = true })
hl.bind(mainMod .. " + ALT + O",    hl.dsp.exec_cmd(tvcmd("off")),    { locked = true })

-- Подсветка ТЕЛЕВИЗОРА (аккорд Menu + D-pad на геймпаде). Панель слушается
-- webOS-настройку picture/backlight; ssap её писать не даёт, обход — внутри `tv`.
-- Замок отдельный от громкости, чтобы они не глушили друг друга.
local tvbllock = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/tv-bl.lock"
local function tvbl(args) return "flock -n " .. tvbllock .. " " .. bin("tv") .. " " .. args end
-- Шаг 10 и БЕЗ repeating, в отличие от громкости: подсветку крутят редко и грубо,
-- а с автоповтором шаг 10 улетал бы в 0 или 100 меньше чем за секунду.
-- Одно нажатие = 10 пунктов, весь диапазон = десять нажатий.
-- SUPER+CTRL+up/down — то, во что input-remapper превращает аккорд Menu+D-pad.
hl.bind(mainMod .. " + CTRL + up",   hl.dsp.exec_cmd(tvbl("bl+ 10")), { locked = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.exec_cmd(tvbl("bl- 10")), { locked = true })
-- В клавиатурной группе телевизора ↑/↓ уже заняты громкостью, поэтому
-- подсветка — на ←/→, как ползунок: влево темнее, вправо светлее.
hl.bind(mainMod .. " + ALT + right", hl.dsp.exec_cmd(tvbl("bl+ 10")), { locked = true })
hl.bind(mainMod .. " + ALT + left",  hl.dsp.exec_cmd(tvbl("bl- 10")), { locked = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
