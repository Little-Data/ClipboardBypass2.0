#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import time
import threading
import configparser
import pyperclip
from pynput import keyboard
from pynput.keyboard import Controller as KeyboardController
import pystray
from PIL import Image, ImageDraw

# ---------- 配置路径 ----------
CONFIG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.ini')

# ---------- 自动创建默认 ini ----------
if not os.path.isfile(CONFIG_FILE):
    print(f'[{time.strftime("%H:%M:%S")}] config.ini 不存在，正在创建默认配置...')
    default_cfg = configparser.ConfigParser()
    default_cfg['settings'] = {
        'delay_seconds': '3',
        'typing_interval': '0.05',
        'newline_extra_delay':'0.2'
    }
    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        default_cfg.write(f)
    print(f'[{time.strftime("%H:%M:%S")}] 默认 config.ini 已生成')

# ---------- 正式读取 ----------
cfg = configparser.ConfigParser()
cfg.read(CONFIG_FILE, encoding='utf-8')
DELAY        = float(cfg.get('settings', 'delay_seconds', fallback=3))
TYPE_INTERVAL= float(cfg.get('settings', 'typing_interval', fallback=0.05))
NEWLINE_DELAY = float(cfg.get('settings', 'newline_extra_delay', fallback=0.2))

# ---------- 全局 ----------
stop_flag = False
kbd       = KeyboardController()

def log(msg):
    """统一打印，带时间戳"""
    print(f'[{time.strftime("%H:%M:%S")}] {msg}', flush=True)

# ---------- 核心逻辑 ----------
def type_text(text: str):
    global stop_flag
    from pynput.keyboard import Key

    SHIFT_MAP = {
        '~': '`', '!': '1', '@': '2', '#': '3', '$': '4', '%': '5',
        '^': '6', '&': '7', '*': '8', '(': '9', ')': '0', '_': '-',
        '+': '=', '{': '[', '}': ']', '|': '\\', ':': ';', '"': "'",
        '<': ',', '>': '.', '?': '/'
    }

    def send_key(c: str):
        if c == '\n':
            kbd.tap(Key.home)
            time.sleep(0.05)
        elif c.isupper() or c in SHIFT_MAP:
            base = SHIFT_MAP.get(c, c.lower())
            with kbd.pressed(Key.shift):
                kbd.tap(base)
        else:
            kbd.tap(c)

    log(f'开始模拟键盘输入，共 {len(text)} 个字符...')
    for ch in text:
        if stop_flag:
            log('>>> 用户通过托盘“退出”中断粘贴')
            return
        send_key(ch)
        time.sleep(TYPE_INTERVAL)

        # 换行后额外延迟（保留上次修复）
        if ch == '\n':
            time.sleep(NEWLINE_DELAY)

    log('粘贴完成！')

def on_hotkey():
    global stop_flag
    stop_flag = False
    text = pyperclip.paste()
    if not text:
        log('剪贴板为空，忽略')
        return
    log(f'热键触发，延迟 {DELAY}s 后开始粘贴...')
    threading.Timer(DELAY, type_text, args=(text,)).start()

# ---------- 热键监听 ----------
def start_hotkey_listener():
    def for_canonical(f):
        return lambda k: f(listener.canonical(k))

    hotkey = keyboard.HotKey(
        keyboard.HotKey.parse('<shift>+<ctrl>+v'),
        on_hotkey)

    def on_press(key):
        hotkey.press(key)

    def on_release(key):
        hotkey.release(key)

    with keyboard.Listener(
            on_press=for_canonical(on_press),
            on_release=for_canonical(on_release)) as listener:
        log('热键监听已启动：Shift+Ctrl+V')
        listener.join()

# ---------- 托盘图标 ----------
def icon_image():
    # 生成一个简单的 16×16 图标
    img = Image.new('RGB', (16, 16), color='white')
    draw = ImageDraw.Draw(img)
    draw.rectangle([4, 4, 12, 12], fill='black')
    return img

def on_exit(icon, item):
    global stop_flag
    stop_flag = True
    log('托盘：用户退出程序')
    icon.stop()
    # 强制结束整个进程
    os._exit(0)

def setup_tray():
    tray = pystray.Icon(
        'PasteToVM',
        icon=icon_image(),
        menu=pystray.Menu(pystray.MenuItem('退出', on_exit))
    )
    tray.run()

# ---------- 入口 ----------
if __name__ == '__main__':
    log('程序启动，配置文件：{}'.format(CONFIG_FILE))
    log('程序版本：1.6，https://github.com/Little-Data/ClipboardBypass2.0，最后更新日期：2025.11.17，HAF半个水果')
    log('delay_seconds={}s, typing_interval={}s, newline_extra_delay={}s'.format(DELAY, TYPE_INTERVAL, NEWLINE_DELAY))

    # 后台线程监听热键
    threading.Thread(target=start_hotkey_listener, daemon=True).start()

    # 主线程负责托盘，同时保持控制台窗口
    setup_tray()
