#!/bin/sh
# V0rtexOS — xinitrc
# Sequência: autoresize → cursor → splash → wallpaper → compositor → panel → taskbar → i3

export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=i3
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# XAUTHORITY já definido pelo startx; garantir como fallback
export XAUTHORITY="${XAUTHORITY:-${HOME}/.Xauthority}"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

# Log de sessão
XLOG=/tmp/v0rtex-session.log
exec >> "$XLOG" 2>&1
echo "[xinitrc] $(date) — DISPLAY=$DISPLAY, USER=$(id -un)"

# ── Configurações de teclado e cursor ─────────────────────────────────────────
xsetroot -cursor_name left_ptr 2>/dev/null || true
xsetroot -solid "#000000" 2>/dev/null || true
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset r rate 300 50 2>/dev/null || true

# ── Auto Resize & DPI (QEMU, VirtualBox, bare metal, ARM) ────────────────────
if command -v v0rtex-autoresize.sh >/dev/null 2>&1; then
    echo "[xinitrc] detectando resolução..."
    v0rtex-autoresize.sh 2>/dev/null || true
fi

# ── Splash screen (bloqueante — termina antes de continuar) ──────────────────
if command -v aeternus-splash >/dev/null 2>&1; then
    echo "[xinitrc] splash screen"
    aeternus-splash 2>/dev/null || true
fi

# ── Wallpaper ─────────────────────────────────────────────────────────────────
if command -v feh >/dev/null 2>&1; then
    if [ -f /usr/local/share/v0rtex/wallpaper.png ]; then
        feh --bg-scale /usr/local/share/v0rtex/wallpaper.png &
    elif [ -f "$HOME/.config/i3/wallpaper.png" ]; then
        feh --bg-scale "$HOME/.config/i3/wallpaper.png" &
    else
        xsetroot -solid "#050505" 2>/dev/null || true
    fi
else
    xsetroot -solid "#050505" 2>/dev/null || true
fi

# ── Compositor (picom, sem travar se falhar) ──────────────────────────────────
if command -v picom >/dev/null 2>&1; then
    echo "[xinitrc] picom"
    if [ -f "$HOME/.config/picom/picom.conf" ]; then
        picom --config "$HOME/.config/picom/picom.conf" --backend glx -b 2>/dev/null \
            || picom --config "$HOME/.config/picom/picom.conf" -b 2>/dev/null \
            || picom -b 2>/dev/null \
            || true
    else
        picom -b 2>/dev/null || true
    fi
fi

# ── Desktop panel (top bar) ───────────────────────────────────────────────────
if command -v aeternus-panel >/dev/null 2>&1; then
    echo "[xinitrc] aeternus-panel"
    aeternus-panel &
fi

# ── Desktop taskbar (bottom bar) ──────────────────────────────────────────────
if command -v aeternus-taskbar >/dev/null 2>&1; then
    echo "[xinitrc] aeternus-taskbar"
    aeternus-taskbar &
fi

# ── Notificações ──────────────────────────────────────────────────────────────
if command -v dunst >/dev/null 2>&1; then
    dunst &
fi

# ── Network tray ──────────────────────────────────────────────────────────────
if command -v nm-applet >/dev/null 2>&1; then
    nm-applet --no-agent &
fi

# ── Window manager (processo principal — xinitrc termina quando i3 terminar) ──
echo "[xinitrc] iniciando i3"
exec i3 2>/tmp/v0rtex-i3.log
