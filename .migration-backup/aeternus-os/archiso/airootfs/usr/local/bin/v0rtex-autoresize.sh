#!/bin/bash
# V0rtexOS — detecta resolução e ajusta DPI automaticamente
# Compatível com: QEMU, VirtualBox, VMware, bare metal, ARM, celulares

LOG=/tmp/v0rtex-autoresize.log
exec >> "$LOG" 2>&1
echo "[autoresize] $(date)"

# Aguardar DISPLAY estar disponível
for i in $(seq 1 20); do
    xdpyinfo >/dev/null 2>&1 && break
    sleep 0.1
done

# Obter resolução atual
SCREEN_INFO=$(xdpyinfo 2>/dev/null | grep "dimensions:" | head -1)
W=$(echo "$SCREEN_INFO" | awk '{print $2}' | cut -dx -f1)
H=$(echo "$SCREEN_INFO" | awk '{print $2}' | cut -dx -f2)

echo "[autoresize] resolução detectada: ${W}x${H}"

# Se QEMU / VirtualBox: tentar redimensionar para resolução do host
if command -v xrandr >/dev/null 2>&1; then
    # Para SPICE/QXL (QEMU): resolução automática via spice-vdagent
    if pgrep -x spice-vdagent >/dev/null 2>&1; then
        echo "[autoresize] SPICE detectado, resolução gerenciada pelo spice-vdagent"
    fi

    # Para VirtualBox: xrandr auto
    if lspci 2>/dev/null | grep -qi "virtualbox"; then
        echo "[autoresize] VirtualBox detectado, aplicando xrandr --auto"
        xrandr --auto 2>/dev/null || true
    fi

    # Para VMware: xrandr auto
    if lspci 2>/dev/null | grep -qi "vmware"; then
        echo "[autoresize] VMware detectado, aplicando xrandr --auto"
        xrandr --auto 2>/dev/null || true
    fi
fi

# Ajuste de DPI baseado no tamanho da tela
# Pequenas telas (mobile/RPi) precisam de DPI menor para ser legível
if [ -n "$W" ] && [ -n "$H" ]; then
    if [ "$W" -le 800 ] || [ "$H" -le 600 ]; then
        echo "[autoresize] tela pequena detectada (${W}x${H}) — DPI 72"
        # DPI baixo para telas pequenas
        xrdb -merge 2>/dev/null <<'XRDB'
Xft.dpi: 72
Xft.antialias: true
Xft.hinting: true
Xft.hintstyle: hintslight
Xft.rgba: rgb
XRDB
    elif [ "$W" -ge 2560 ]; then
        echo "[autoresize] tela HiDPI detectada (${W}x${H}) — DPI 192"
        xrdb -merge 2>/dev/null <<'XRDB'
Xft.dpi: 192
Xft.antialias: true
Xft.hinting: true
Xft.hintstyle: hintfull
Xft.rgba: rgb
XRDB
    else
        echo "[autoresize] tela normal (${W}x${H}) — DPI 96"
        xrdb -merge 2>/dev/null <<'XRDB'
Xft.dpi: 96
Xft.antialias: true
Xft.hinting: true
Xft.hintstyle: hintslight
Xft.rgba: rgb
XRDB
    fi
fi

echo "[autoresize] concluído"
