#!/bin/bash

# Управление компьютером и телевизором с дивана:
#   - геймпад Xbox рулит десктопом через input-remapper (пресет couch);
#   - телевизор LG гасится, будится и настраивается по сети скриптом tv;
#   - машина выключается сама, если через 10 минут после загрузки никто
#     не залогинился.
#
# Запускать после copy-configs.sh: бинды живут в hyprland.lua, а скрипты,
# которые они зовут, раскладывает уже этот скрипт.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/../configs"

echo "==> Setting up couch control..."

# --- свои скрипты ------------------------------------------------------
# tv           — телевизор LG по сети: питание, громкость, подсветка
# sleeptimer   — таймер выключения с закрытием окон по-хорошему
# tune-cursor  — скорость курсора геймпада
# gamepad-probe— диагностика: что геймпад шлёт на входе
#
# Hyprland наследует PATH без ~/.local/bin, поэтому в hyprland.lua они
# зовутся по полному пути через bin() — но бит на выполнение всё равно нужен.
mkdir -p ~/.local/bin
install -m 755 "$CONFIGS_DIR"/bin/* ~/.local/bin/

# --- геймпад -----------------------------------------------------------
# Пресет couch: стики — курсор и скролл, триггеры — клики, аккорды
# View/Menu + D-pad — громкость и подсветка телевизора.
#
# Имя каталога внутри presets/ должно точно совпадать с именем устройства,
# как его видит input-remapper, иначе autoload молча ничего не подхватит.
# Источник истины — build-couch-preset.py: couch.json собирается им через
# API inputremapper, а не правится руками.
mkdir -p ~/.config/input-remapper-2
cp -r "$CONFIGS_DIR/input-remapper/." ~/.config/input-remapper-2/

# --- юниты -------------------------------------------------------------
sudo cp "$CONFIGS_DIR/systemd/system/tv-off-on-poweroff.service" /etc/systemd/system/

sudo install -m 755 "$CONFIGS_DIR/usr-local-bin/login-deadline" /usr/local/bin/login-deadline
sudo cp "$CONFIGS_DIR/systemd/system/login-deadline.service" /etc/systemd/system/
sudo cp "$CONFIGS_DIR/systemd/system/login-deadline.timer"   /etc/systemd/system/

sudo systemctl daemon-reload

# --- службы ------------------------------------------------------------
# Без bluetooth геймпад просто не подключится.
sudo systemctl enable --now bluetooth

# Демон перехвата. Сам autoload зовётся из hyprland.lua, потому что
# Hyprland не выполняет /etc/xdg/autostart.
sudo systemctl enable --now input-remapper

# tv-off-on-poweroff обязан быть именно АКТИВНЫМ: вся его работа лежит в
# ExecStop, у неактивного юнита его никто не позовёт, и телевизор останется
# гореть после выключения машины.
sudo systemctl enable --now tv-off-on-poweroff

# Гасит машину через 10 минут после загрузки, если логина не было.
# Отменить разово: sudo touch /etc/login-deadline.disabled
sudo systemctl enable --now login-deadline.timer

echo "==> Couch control ready."
echo
echo "Осталось руками:"
echo "  1. Спарить геймпад по Bluetooth (bluetoothctl), потом:"
echo "       input-remapper-control --command autoload"
echo "  2. Спарить телевизор:  tv pair"
echo "     На самом телевизоре заранее: Настройки -> Сеть ->"
echo "     LG Connect Apps = вкл, Mobile TV On = вкл (иначе порты 3000/3001 закрыты)."
echo "     Ключ ляжет в ~/.config/lgtv/client-key — в репозитории его нет и быть не должно."
