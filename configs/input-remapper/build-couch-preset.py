import evdev
from evdev.ecodes import (EV_KEY, EV_ABS, EV_REL, REL_X, REL_Y, REL_WHEEL,
    BTN_SOUTH, BTN_EAST, BTN_NORTH, BTN_WEST, BTN_TL, BTN_TR, BTN_SELECT, BTN_START, BTN_MODE,
    BTN_LEFT, BTN_RIGHT, ABS_X, ABS_Y, ABS_Z, ABS_RZ, ABS_GAS, ABS_BRAKE,
    ABS_HAT0X, ABS_HAT0Y)
from inputremapper.configs.preset import Preset
from inputremapper.configs.mapping import Mapping
from inputremapper.configs.input_config import InputConfig, InputCombination
from inputremapper.configs.paths import PathUtils
from inputremapper.utils import get_device_hash

DEV = "/dev/input/event27"
GROUP = "Xbox Wireless Controller"
PRESET = "couch"

h = get_device_hash(evdev.InputDevice(DEV))
print("origin_hash:", h)

def ic(type_, code, threshold=None):
    return InputConfig(type=type_, code=code, origin_hash=h, analog_threshold=threshold)

def comb(*configs):
    return InputCombination(configs)

path = PathUtils.get_preset_path(GROUP, PRESET)
PathUtils.touch(path)
p = Preset(path, mapping_factory=Mapping)

def key(combination, symbol, name):
    p.add(Mapping(input_combination=combination.to_config(),
                  target_uinput="keyboard", output_symbol=symbol, name=name))

def click(combination, symbol, name):
    p.add(Mapping(input_combination=combination.to_config(),
                  target_uinput="mouse", output_symbol=symbol, name=name))

# --- left stick -> mouse cursor ---
p.add(Mapping(input_combination=comb(ic(EV_ABS, ABS_X)).to_config(),
              target_uinput="mouse", output_type=EV_REL, output_code=REL_X,
              deadzone=0.15, gain=0.4, expo=0.6, name="cursor X"))
p.add(Mapping(input_combination=comb(ic(EV_ABS, ABS_Y)).to_config(),
              target_uinput="mouse", output_type=EV_REL, output_code=REL_Y,
              deadzone=0.15, gain=0.4, expo=0.6, name="cursor Y"))

# --- right stick vertical -> scroll wheel ---
p.add(Mapping(input_combination=comb(ic(EV_ABS, ABS_RZ)).to_config(),
              target_uinput="mouse", output_type=EV_REL, output_code=REL_WHEEL,
              deadzone=0.2, gain=-1.0, name="scroll"))

# --- triggers -> mouse clicks ---
click(comb(ic(EV_ABS, ABS_GAS, 30)), "BTN_LEFT", "RT = left click")
click(comb(ic(EV_ABS, ABS_BRAKE, 30)), "BTN_RIGHT", "LT = right click")

# --- d-pad -> arrows ---
key(comb(ic(EV_ABS, ABS_HAT0X, -1)), "KEY_LEFT",  "dpad left")
key(comb(ic(EV_ABS, ABS_HAT0X,  1)), "KEY_RIGHT", "dpad right")
key(comb(ic(EV_ABS, ABS_HAT0Y, -1)), "KEY_UP",    "dpad up")
key(comb(ic(EV_ABS, ABS_HAT0Y,  1)), "KEY_DOWN",  "dpad down")

# --- face buttons ---
key(comb(ic(EV_KEY, BTN_SOUTH)), "KEY_ENTER", "A = Enter")
key(comb(ic(EV_KEY, BTN_EAST)),  "KEY_ESC",   "B = Esc")
# X и Y поодиночке не назначены — они работают только в аккордах с Menu.

# --- bumpers -> workspace prev/next (SUPER+[ / SUPER+]) ---
key(comb(ic(EV_KEY, BTN_TL)), "modify(KEY_LEFTMETA, key(KEY_LEFTBRACE))",  "LB = workspace prev")
key(comb(ic(EV_KEY, BTN_TR)), "modify(KEY_LEFTMETA, key(KEY_RIGHTBRACE))", "RB = workspace next")

# --- xbox button -> launcher (SUPER+Space) ---
key(comb(ic(EV_KEY, BTN_MODE)), "modify(KEY_LEFTMETA, key(KEY_SPACE))", "Xbox = launcher")

# --- View + Menu -> power menu (SUPER+M) ---
key(comb(ic(EV_KEY, BTN_SELECT), ic(EV_KEY, BTN_START)),
    "modify(KEY_LEFTMETA, key(KEY_M))", "View+Menu = power menu")

# --- View + X -> таймер сна (SUPER+SHIFT+M) ---
key(comb(ic(EV_KEY, BTN_SELECT), ic(EV_KEY, BTN_NORTH)),
    "modify(KEY_LEFTMETA, modify(KEY_LEFTSHIFT, key(KEY_M)))", "View+X = sleep timer")

# --- Menu + X -> закрыть окно (SUPER+C) ---
key(comb(ic(EV_KEY, BTN_START), ic(EV_KEY, BTN_NORTH)),
    "modify(KEY_LEFTMETA, key(KEY_C))", "Menu+X = close window")

# --- View + D-pad вверх/вниз -> громкость ТЕЛЕВИЗОРА (SUPER+SHIFT+up/down) ---
# hold_keys, а не key: клавиша держится, пока зажат аккорд, и Hyprland
# повторяет бинд сам. Одиночный D-pad остаётся стрелками.
key(comb(ic(EV_KEY, BTN_SELECT), ic(EV_ABS, ABS_HAT0Y, -1)),
    "modify(KEY_LEFTMETA, modify(KEY_LEFTSHIFT, hold_keys(KEY_UP)))",
    "View+dpad up = TV volume up")
key(comb(ic(EV_KEY, BTN_SELECT), ic(EV_ABS, ABS_HAT0Y, 1)),
    "modify(KEY_LEFTMETA, modify(KEY_LEFTSHIFT, hold_keys(KEY_DOWN)))",
    "View+dpad down = TV volume down")

# --- Menu + D-pad вверх/вниз -> подсветка ТЕЛЕВИЗОРА (SUPER+CTRL+up/down) ---
# Тот же приём, что и с громкостью: View отвечает за звук, Menu — за картинку.
key(comb(ic(EV_KEY, BTN_START), ic(EV_ABS, ABS_HAT0Y, -1)),
    "modify(KEY_LEFTMETA, modify(KEY_LEFTCTRL, hold_keys(KEY_UP)))",
    "Menu+dpad up = TV backlight up")
key(comb(ic(EV_KEY, BTN_START), ic(EV_ABS, ABS_HAT0Y, 1)),
    "modify(KEY_LEFTMETA, modify(KEY_LEFTCTRL, hold_keys(KEY_DOWN)))",
    "Menu+dpad down = TV backlight down")

# --- Menu + Y -> полный экран (F11, понимают плееры и браузер) ---
key(comb(ic(EV_KEY, BTN_START), ic(EV_KEY, BTN_WEST)),
    "KEY_F11", "Menu+Y = fullscreen")

bad = [m for m in p if not m.is_valid()]
print("invalid mappings:", len(bad))
for m in bad:
    print("  !!", m.name, m.get_error())
p.save()
print("saved:", path)
