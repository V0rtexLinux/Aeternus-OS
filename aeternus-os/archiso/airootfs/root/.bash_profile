#!/bin/bash
# V0rtexOS — bash login profile
# Se zsh está disponível, troca para ele imediatamente (carrega .zprofile que inicia X).
# Fallback: sobe X direto do bash se zsh não existir.

if [[ -x /usr/bin/zsh ]]; then
    exec /usr/bin/zsh -l
fi

# Fallback bash: inicia X apenas se não há sessão gráfica e não está tentando já
if [[ -z "${DISPLAY}${WAYLAND_DISPLAY}" ]] && [[ "$(tty)" == /dev/tty1 ]]; then
    if [[ ! -f /tmp/.v0rtex-x-starting ]]; then
        touch /tmp/.v0rtex-x-starting
        echo "[v0rtex] Iniciando Xorg (bash fallback)..."
        /usr/local/bin/v0rtex-startx
        rm -f /tmp/.v0rtex-x-starting 2>/dev/null
    fi
fi
