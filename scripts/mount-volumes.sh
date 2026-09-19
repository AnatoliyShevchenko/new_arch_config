#!/bin/bash

# Монтирует внешний диск с медиатекой и прописывает его в /etc/fstab.
#
# UUID зашит намеренно: он лежит в суперблоке самой файловой системы, а её
# переустановка системы не трогает — диск переживает mkfs корня без изменений.
# Меняется он только при переформатировании раздела, `tune2fs -U` или замене
# диска, поэтому на такой случай оставлено переопределение переменной.
#
# Запускать ДО install-dev-tools.sh: k3s держит на этом диске hostPath
# jellyfin, и без готовой точки монтирования он поднимется в пустой каталог.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/../configs"

HDD_UUID="${HDD_UUID:-64b29be9-ff41-4b9d-aa15-d1a28a1e8a79}"
HDD_MOUNT="${HDD_MOUNT:-/HDD-WD}"
HDD_FSTYPE="${HDD_FSTYPE:-ext4}"

# nofail — без диска машина всё равно обязана догрузиться до логина.
# x-systemd.device-timeout — иначе отсутствующее устройство systemd ждёт 90 секунд.
HDD_OPTS="${HDD_OPTS:-rw,relatime,nofail,x-systemd.device-timeout=10s}"

echo "==> Mounting volumes..."

# Проверяем по симлинку udev, а не через blkid: симлинк читается без root,
# так что скрипт падает с внятной ошибкой ещё до запроса пароля.
if [ ! -e "/dev/disk/by-uuid/$HDD_UUID" ]; then
    echo "Диск с UUID $HDD_UUID не найден." >&2
    echo "Посмотреть, что есть:  lsblk -o NAME,SIZE,FSTYPE,UUID,LABEL" >&2
    echo "Указать другой:        HDD_UUID=... $0" >&2
    exit 1
fi

sudo mkdir -p "$HDD_MOUNT"

# Идемпотентность: строку добавляем, только если этого UUID в fstab ещё нет.
# Остальной fstab не трогаем — корень и подтома btrfs генерит genfstab при
# установке, и после переустановки их UUID другие.
if grep -q "$HDD_UUID" /etc/fstab; then
    echo "    $HDD_MOUNT уже в /etc/fstab, строку не трогаю"
else
    echo "    добавляю $HDD_MOUNT в /etc/fstab"
    printf 'UUID=%s\t%s\t%s\t%s\t0 2\n' \
        "$HDD_UUID" "$HDD_MOUNT" "$HDD_FSTYPE" "$HDD_OPTS" \
        | sudo tee -a /etc/fstab >/dev/null
fi

# fstab systemd читает один раз при загрузке; без reload свежая строка не
# станет .mount-юнитом.
sudo systemctl daemon-reload

if mountpoint -q "$HDD_MOUNT"; then
    echo "    $HDD_MOUNT уже смонтирован"
else
    sudo mount "$HDD_MOUNT"
    echo "    $HDD_MOUNT смонтирован"
fi

# Drop-in кладём здесь, до установки k3s: он даёт RequiresMountsFor=/HDD-WD,
# без которого systemd при выключении пытается отмонтировать диск раньше, чем
# остановится k3s, и получает "target is busy".
echo "    ставлю drop-in k3s на /HDD-WD"
sudo mkdir -p /etc/systemd/system/k3s.service.d
sudo cp "$CONFIGS_DIR/systemd/system/k3s.service.d/hdd-wd.conf" \
        /etc/systemd/system/k3s.service.d/
sudo systemctl daemon-reload

echo "==> Volumes mounted successfully!"
