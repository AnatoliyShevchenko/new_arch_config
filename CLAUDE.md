# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Что это за репозиторий

Личный репозиторий развёртывания: превращает свежую установку Arch Linux в рабочий
десктоп автора — Hyprland (Wayland-композитор) + Noctalia (оболочка: бар, лаунчер,
панели) + greetd, плюс однонодовый кластер k3s. Сборки, тестов и линтера здесь нет —
«программа» это набор bash-скриптов и те дотфайлы, которые они раскладывают по
местам. Проверять изменения нужно чтением скриптов и, где безопасно, сухим прогоном
отдельной команды. Не запускай `install.sh` и скрипты из `scripts/` без явной просьбы:
они ставят пакеты, включают systemd-юниты и перезаписывают файлы в `$HOME` и `/etc`.

## Структура и порядок выполнения

`install.sh` — единственная точка входа. Он включает локаль `ru_RU.UTF-8`, после чего
запускает скрипты из `scripts/` в фиксированном порядке, который отражает реальные
зависимости:

1. `install-packages.sh` — `pacman -S - < packages/pacman.txt`, ставит `paru` из AUR,
   если его нет, затем `paru -S - < packages/aur.txt`. Списки пакетов подаются на
   stdin, поэтому в них должно быть по одному пакету на строку и никаких комментариев.
2. `mount-volumes.sh` — прописывает `/HDD-WD` в `fstab`, монтирует его и кладёт
   drop-in для k3s. Идёт до установки k3s осознанно, см. раздел про том.
3. `enable-services.sh` — greetd, tailscaled, sshd, docker; добавляет `$USER` в группу
   `docker`. Здесь же ставится и включается `amd-boost-disable.service` — единственный
   юнит не из пакета, который сюда попал: копирование и `enable` держим рядом, чтобы
   не следить за порядком между скриптами. Когда таких юнитов станет заметно больше,
   их стоит вынести в отдельный шаг.
4. `install-dev-tools.sh` — пайпит в bash установщики Claude Code и k3s.
5. `set-environment.sh` — oh-my-zsh + powerlevel10k + плагины zsh. Каждый шаг закрыт
   проверкой существования каталога, так что это единственный полностью
   идемпотентный скрипт.
6. `copy-configs.sh` — копирует `configs/` в `$HOME` и `/etc`, затем ставит расширения
   VSCode из `configs/vscode/extensions.txt`.
7. `couch-control.sh` — геймпад, телевизор и дедлайн на логин. Последним, потому что
   бинды приезжают с `hyprland.lua` на предыдущем шаге.

Добавление нового куска десктопа обычно затрагивает три места сразу: пакет в
`packages/`, дерево конфигов в `configs/` и строку копирования в `copy-configs.sh`.

## Соответствие configs/ → место назначения

`configs/` не повторяет структуру `$HOME`; соответствие задано только в самих
скриптах, и раскладывает конфиги не один `copy-configs.sh`: юнит едет вместе с
тем шагом, который его включает.

| источник | назначение | кто копирует |
| --- | --- | --- |
| `configs/hypr/` | `~/.config/hypr/` | `copy-configs.sh` |
| `configs/kitty/` | `~/.config/kitty/` | `copy-configs.sh` |
| `configs/zsh/` (`.zshrc`, `.p10k.zsh`) | `~/` | `copy-configs.sh` |
| `configs/noctalia/` | `~/.local/state/noctalia/` | `copy-configs.sh` |
| `configs/vscode/settings.json` | `~/.config/Code/User/settings.json` | `copy-configs.sh` |
| `configs/greetd/config.toml` | `/etc/greetd/config.toml` (sudo) | `copy-configs.sh` |
| `configs/bin/` | `~/.local/bin/` (режим 755) | `couch-control.sh` |
| `configs/input-remapper/` | `~/.config/input-remapper-2/` | `couch-control.sh` |
| `configs/usr-local-bin/login-deadline` | `/usr/local/bin/` (sudo, 755) | `couch-control.sh` |
| `configs/systemd/system/amd-boost-disable.service` | `/etc/systemd/system/` (sudo) | `enable-services.sh` |
| `configs/systemd/system/tv-off-on-poweroff.service`, `login-deadline.service`, `login-deadline.timer` | `/etc/systemd/system/` (sudo) | `couch-control.sh` |
| `configs/systemd/system/k3s.service.d/hdd-wd.conf` | `/etc/systemd/system/k3s.service.d/` (sudo) | `mount-volumes.sh` |

`configs/k8s/` копируется в `~/k8s` (`copy-configs.sh`), но, в отличие от остальных
конфигов, не потому, что программа читает фиксированный путь: `kubectl` читает тот
путь, который ему дали. Копия нужна, потому что клон репозитория после установки
удаляется, а применять и править манифесты приходится и дальше. Сами манифесты ни
один скрипт не применяет — это делается руками через `kubectl apply -f`.

## Конфиг Hyprland

`configs/hypr/hyprland.lua` написан на Lua-API Hyprland (`hl.config`, `hl.bind`,
`hl.window_rule`, …), а не в старом синтаксисе `hyprland.conf`. Что там легко сломать:

- Hyprland наследует PATH без `~/.local/bin`, поэтому всё оттуда должно идти через
  локальный хелпер `bin()`, а не по голому имени команды.
- Биндинги дёргают скрипты из `~/.local/bin`. `tv` (телевизор LG по сети — питание,
  громкость, подсветка) и `sleeptimer` лежат в `configs/bin/` и раскладываются
  `couch-control.sh`. А вот `screen-owner` **в этом репозитории нет** — он живёт в
  отдельной репе; без него соответствующие бинды молча ничего не делают.
- Команды к телевизору обёрнуты в `flock -n` с отдельным лок-файлом на функцию, чтобы
  автоповтор клавиши не копил сетевые запросы. При добавлении новых TV-биндов обёртку
  нужно сохранять.
- Часть биндов существует только как клавиатурная цель геймпадного аккорда
  `input-remapper` (например, `SUPER+SHIFT+up/down`, `SUPER+CTRL+up/down`). Смена этих
  сочетаний ломает пресет геймпада, который настраивается вне этого репозитория.

## Noctalia

`configs/noctalia/` — это каталог **состояния** Noctalia, а не конфиг, написанный
руками: `settings.toml` (раскладка бара, виджеты, геометрия локскрина) и `state.toml`
пишет сама программа, поэтому менять их лучше через UI Noctalia и копировать заново.

Рабочего каталога плагинов (`~/.local/state/noctalia/plugins/`) здесь намеренно нет:
это кэш, а не конфиг. Внутри него `sources/<имя>/repo` — git-клоны репозиториев
плагинов, и в `configs/` они попали бы embedded-репозиториями, то есть пустыми
каталогами у того, кто клонирует этот репозиторий. Вместо этого источники и список
включённых плагинов везёт сам `settings.toml`:

    [plugins]
    enabled = [ "noctalia/wallhaven", ..., "brick/screen-owner" ]

        [[plugins.source]]
        kind = "git"
        location = "https://github.com/AnatoliyShevchenko/noctalia-screen-owner"
        name = "screen-owner"

Если после восстановления Noctalia не подтянет источник сама, он добавляется
командой — но уже **после первого входа** в Hyprland, потому что `noctalia msg`
разговаривает с запущенной оболочкой и внутри `install.sh` не сработает:

    noctalia msg plugins source add screen-owner git \
        https://github.com/AnatoliyShevchenko/noctalia-screen-owner
    noctalia msg plugins enable brick/screen-owner

Проверить, что получилось: `noctalia msg plugins source list` и
`noctalia msg plugins list`.

## k8s (k3s)

Одна нода, ingress на Traefik, wildcard-домен. Сам домен и почта ACME в манифестах
заменены плейсхолдерами `__BASE_DOMAIN__` и `__ACME_EMAIL__`: репозиторий публичный.
Подстановка делается один раз после `copy-configs.sh`, обычным `sed` по `~/k8s` —
см. README. В рантайме шаблонов не остаётся, поэтому `kubectl apply -f` работает
без обёрток. Имена ресурсов (`wildcard`, `wildcard-tls`) домен не кодируют
намеренно — иначе плейсхолдеров понадобилось бы два, с точками и с дефисами. cert-manager выпускает
wildcard-сертификат через Let's Encrypt DNS-01 в Cloudflare, поэтому применение
`configs/k8s/cert-manager/` требует секрета `cloudflare-api-token` (ключ `api-token`),
которого в репозитории нет. `traefik/tlsstore-default.yaml` делает этот
wildcard-секрет сертификатом Traefik по умолчанию — TLS получают все ingress'ы без
настройки в каждом. Проверять нужно на `letsencrypt-staging` и только потом
переключать issuer на `letsencrypt-prod`: у prod-эндпоинта ACME есть лимиты запросов.

## Том /HDD-WD

`mount-volumes.sh` добавляет в `/etc/fstab` ровно одну строку и не трогает всё
остальное: корень и подтома btrfs генерит `genfstab` при установке, и после
переустановки их UUID другие. А вот UUID самого `/HDD-WD` зашит в скрипт — он лежит
в суперблоке ext4 на отдельном диске, который переустановка не трогает, и переживает
её без изменений. Переопределяется переменными `HDD_UUID` / `HDD_MOUNT` на случай
замены диска. Наличие диска проверяется по симлинку `/dev/disk/by-uuid/...`, а не
через `blkid`: симлинк читается без root, поэтому скрипт падает с внятной ошибкой
ещё до запроса пароля.

Порядок важен в обе стороны. Скрипт идёт **до** `install-dev-tools.sh`, потому что
jellyfin держит `/HDD-WD/jellyfin` как hostPath. И он же кладёт drop-in
`k3s.service.d/hdd-wd.conf` с `RequiresMountsFor=/HDD-WD` — без него systemd при
выключении пытается отмонтировать диск раньше, чем остановится k3s, и получает
«target is busy».

## Диван-управление

`couch-control.sh` собирает три вещи, которые работают вместе:

- **Геймпад.** Xbox-контроллер по Bluetooth через `input-remapper`, пресет `couch`.
  Имя каталога внутри `presets/` должно точно совпадать с именем устройства, как его
  видит input-remapper, иначе `autoload` молча не сработает. Сам `couch.json` —
  продукт сборки: источник истины `build-couch-preset.py`, правится он, а не JSON.
  `autoload` зовётся из `hyprland.lua`, потому что Hyprland не выполняет
  `/etc/xdg/autostart`.
- **Телевизор.** Скрипт `tv` ходит к LG по webOS-протоколу на голой стандартной
  библиотеке Python. Юнит `tv-off-on-poweroff.service` обязан быть **активным**: вся
  его работа в `ExecStop`, у неактивного юнита его никто не позовёт. Ключ спаривания
  (`~/.config/lgtv/client-key`) в репозитории отсутствует намеренно — репозиторий
  публичный. Первый запуск требует `tv pair` и включённых на телевизоре LG Connect
  Apps / Mobile TV On.
- **Дедлайн на логин.** `login-deadline.timer` через 10 минут после загрузки зовёт
  скрипт, который гасит машину, если нет ни одной сессии с uid >= 1000 (greeter
  сидит под 964 и за логин не считается). Разово отключается файлом
  `/etc/login-deadline.disabled`.

## greetd и сессия по умолчанию

`configs/greetd/config.toml` — единственное место, где задана стартовая сессия.
`command` запускает `noctalia-greeter-session` с `-- --session 'Hyprland (uwsm-managed)'`,
чтобы гритер по умолчанию поднимал Hyprland через uwsm, а не `/usr/bin/start-hyprland`.
Имя сессии должно точно совпадать со строкой из `noctalia-greeter sessions`
(она берётся из `Name=` в `/usr/share/wayland-sessions/*.desktop`). Значение `command`
выполняет `sh`, так что кавычки и переменные окружения там работают как в шелле.

Собственный конфиг гритера (`/var/lib/noctalia-greeter/greeter.toml`, `sync.toml`)
этот репозиторий намеренно не хранит: всё нужное задаётся флагом в greetd, а остальное
гритер пишет себе сам.

## Соглашения

- Скрипты — `#!/bin/bash` с `set -e`, свой каталог определяют через
  `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`. Новые скрипты должны
  так же запускаться и отдельно, и из `install.sh`.
- Пояснительные комментарии в `configs/` (бинды Hyprland, плагин screen-owner)
  написаны по-русски; язык комментариев должен совпадать с языком файла.
- В `copy-configs.sh` содержимое каталога копируется через `cp -r "<каталог>/." <цель>`,
  а не глобом `*`: глоб не берёт скрытые файлы (из-за чего `.zshrc` и `.p10k.zsh` не
  доезжали) и может зацепить соседний каталог с похожим именем. Каталог назначения
  должен быть в `mkdir -p` выше.
