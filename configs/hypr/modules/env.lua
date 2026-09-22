-- Общее для всех модулей конфига.
-- local-переменные hyprland.lua внутри require()'нутых файлов не видны,
-- поэтому всё, что нужно больше чем одному файлу, живёт здесь.

local M = {}

-- Программы
M.terminal    = "kitty"
M.fileManager = "nautilus"
M.menu        = "hyprlauncher"

-- Hyprland inherits a PATH without ~/.local/bin, so our own scripts there are
-- invisible to exec_cmd by bare name. Always route them through bin().
function M.bin(cmd) return os.getenv("HOME") .. "/.local/bin/" .. cmd end

return M
