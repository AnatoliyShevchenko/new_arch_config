# new_arch_config

Разворачивает чистый Arch Linux в рабочий десктоп: Hyprland + Noctalia + greetd,
однонодовый k3s с Jellyfin, и управление компьютером с телевизором с геймпада.

Внутри — bash-скрипты и дотфайлы, которые они раскладывают по местам. Сборки,
тестов и линтера нет.

---

## Установка

```sh
pacman -S git
git clone https://github.com/AnatoliyShevchenko/new_arch_config.git
cd new_arch_config
./install.sh
```

`install.sh` спросит пароль sudo и дальше идёт сам:

| # | Скрипт | Что делает |
| --- | --- | --- |
| 1 | `install-packages.sh` | пакеты из `packages/pacman.txt`, потом `paru` и `packages/aur.txt` |
| 2 | `mount-volumes.sh` | `/HDD-WD` в fstab и монтирование, drop-in для k3s |
| 3 | `enable-services.sh` | greetd, tailscaled, sshd, docker + группа `docker`, гашение буста AMD |
| 4 | `install-dev-tools.sh` | Claude Code и k3s |
| 5 | `set-environment.sh` | oh-my-zsh, powerlevel10k, плагины zsh |
| 6 | `copy-configs.sh` | `configs/` в `$HOME` и `/etc`, расширения VSCode |
| 7 | `couch-control.sh` | геймпад, телевизор, дедлайн на логин |

Порядок не случайный: том встаёт до k3s (на нём hostPath Jellyfin),
`couch-control` идёт после `copy-configs` (бинды приезжают с `hyprland.lua`),
а greetd включается, когда `noctalia-greeter` уже установлен.

После этого — перезагрузка.

---

## После первой перезагрузки

Это `install.sh` сделать не может: нужен вошедший пользователь, живое железо
или секреты, которых в репозитории нет.

### 1. Перелогиниться

Группа `docker` подхватится только в новой сессии.

### 2. Геймпад

Рабочий стол к этому моменту уже поднят, так что проще через интерфейс: значок
Bluetooth в баре или панель управления по `SUPER+S`. Включить Bluetooth, на
геймпаде зажать кнопку сопряжения (сверху, рядом с разъёмом), пока логотип Xbox
не замигает часто, и спарить «Xbox Wireless Controller» из списка.

Если панель почему-то недоступна — то же самое из терминала:

```sh
bluetoothctl
> scan on
> pair 9C:AA:1B:7B:13:57
> trust 9C:AA:1B:7B:13:57
> connect 9C:AA:1B:7B:13:57
> scan off
```

Геймпад подключился уже после старта Hyprland, а `autoload` отрабатывает при
старте — поэтому пресет надо подтянуть руками:

```sh
input-remapper-control --command autoload
```

Проверить, что геймпад вообще шлёт события: `gamepad-probe 5`.

### 3. Телевизор

Сначала **на самом телевизоре**: Настройки → Сеть → **LG Connect Apps** = вкл,
**Mobile TV On** = вкл. Без них порты 3000/3001 закрыты и ничего не выйдет.

Сам `tv` к этому моменту уже лежит в `~/.local/bin` и виден в PATH. Две команды
работают сразу, без спаривания:

```sh
tv on        # чистый Wake-on-LAN, магический пакет, ключ не нужен
tv status    # ping, порты 3000/3001 и есть ли ключ
```

Телевизор должен быть включён, иначе спариваться не с чем — поэтому порядок
именно такой:

```sh
tv on
tv pair      # подтвердить запрос на экране телевизора
             # ключ ляжет в ~/.config/lgtv/client-key
tv status
```

Всё остальное — `off`, `vol`, `bl`, `mute` — идёт через webOS-сессию и до
`tv pair` будет молча отваливаться. В том числе `tv-off-on-poweroff.service`:
юнит активен с самой установки, но гасить телевизор начнёт только после
спаривания.

После этого заработают: гашение вместе с компьютером, пробуждение при старте
Hyprland, громкость и подсветка с геймпада и с клавиатуры.

### 4. Плагины Noctalia

Обычно подтягиваются сами из `settings.toml`. Проверить:

```sh
noctalia msg plugins source list
noctalia msg plugins list
```

Если своего источника нет — добавить (работает только при запущенной оболочке):

```sh
noctalia msg plugins source add screen-owner git \
    https://github.com/AnatoliyShevchenko/noctalia-screen-owner
noctalia msg plugins enable brick/screen-owner
```

### 5. Кластер

`install-dev-tools.sh` ставит только сам k3s. Дальше руками.

cert-manager:

```sh
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager --create-namespace \
    --version v1.21.2 --set crds.enabled=true
```

Секрет Cloudflare — в репозитории его нет и быть не должно:

```sh
kubectl -n cert-manager create secret generic cloudflare-api-token \
    --from-literal=api-token='<токен>'
```

Манифесты `copy-configs.sh` уже разложил в `~/k8s` — оттуда и применяем, чтобы
не зависеть от того, лежит ли ещё клон репозитория на диске.

Домен и почта в них заменены плейсхолдерами, чтобы не лежать в публичном
репозитории. Подставить надо один раз, дальше `~/k8s` работает как обычный
рабочий каталог:

```sh
ACME_EMAIL='почта@example.com'
BASE_DOMAIN='example.com'

sed -i "s/__ACME_EMAIL__/$ACME_EMAIL/g; s/__BASE_DOMAIN__/$BASE_DOMAIN/g" ~/k8s/*/*.yaml
grep -rn '__' ~/k8s/    # должно быть пусто
```

Забыть этот шаг не страшно: cert-manager сразу упадёт на невалидном имени
`*.__BASE_DOMAIN__`, тихо применённого мусора не будет.

Теперь применяем. Сначала staging: у prod-эндпоинта ACME жёсткие лимиты, и
упереться в них на отладке легко.

```sh
kubectl apply -f ~/k8s/cert-manager/clusterissuer-staging.yaml
kubectl apply -f ~/k8s/cert-manager/certificate-wildcard-staging.yaml
# убедиться, что сертификат выписался, и только потом:
kubectl apply -f ~/k8s/cert-manager/clusterissuer-prod.yaml
kubectl apply -f ~/k8s/cert-manager/certificate-wildcard.yaml
kubectl apply -f ~/k8s/traefik/tlsstore-default.yaml
kubectl apply -f ~/k8s/jellyfin/jellyfin.yaml
```

Traefik приезжает вместе с k3s, отдельно ставить не нужно.

---

## Чего здесь нет намеренно

| Что | Как восстановить |
| --- | --- |
| `~/.config/lgtv/client-key` | `tv pair` |
| Токен Cloudflare | создать секрет руками, см. выше |
| `~/.ssh`, `~/.kube/config` | ключи — отдельно, kubeconfig создаёт k3s |
| Рабочий каталог плагинов Noctalia | оболочка клонирует источники сама |
| `screen-owner` | отдельный репозиторий, `~/.local/bin/screen-owner` — симлинк в него |

---

## Грабли

- **`tv-off-on-poweroff.service` должен быть активен**, а не просто enabled: вся
  его работа лежит в `ExecStop`, у неактивного юнита его никто не позовёт, и
  телевизор останется гореть. `couch-control.sh` включает его через `enable --now`.
- **Имя каталога в `configs/input-remapper/presets/`** должно точно совпадать с
  именем устройства, как его видит input-remapper. Не совпало — `autoload` молча
  ничего не сделает.
- **Пресет геймпада не правят руками.** Источник истины —
  `build-couch-preset.py`, `couch.json` собирается им.
- **`greetd` включать только после `noctalia-greeter`.** Иначе на первом
  перезапуске чёрный экран на VT1 (спасаться Ctrl+Alt+F2). Порядок в
  `install.sh` это уже учитывает.
- **`paru` клонируется в текущий каталог** и `makepkg -si` там интерактивен —
  если запускать `install.sh` из репозитория, клон насорит рядом.
- **`/HDD-WD` монтируется до k3s.** Иначе Jellyfin поднимется в пустой каталог,
  а при выключении systemd упрётся в «target is busy».
