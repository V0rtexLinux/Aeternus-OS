# V0rtexOS — zsh login profile
# Auto-inicia Xorg no tty1 (uma única vez, sem loop)

if [[ -z "${DISPLAY}${WAYLAND_DISPLAY}" ]] && [[ "$(tty)" == /dev/tty1 ]]; then
    # Evitar re-entrada: marcar que estamos iniciando X
    if [[ ! -f /tmp/.v0rtex-x-starting ]]; then
        touch /tmp/.v0rtex-x-starting
        /usr/local/bin/v0rtex-startx
        EXIT_CODE=$?
        rm -f /tmp/.v0rtex-x-starting 2>/dev/null
        if [[ $EXIT_CODE -ne 0 ]]; then
            echo ""
            echo "[v0rtex] ERRO: Xorg encerrou (código $EXIT_CODE)"
            echo "  Diagnóstico: cat /tmp/xorg.log && cat /tmp/v0rtex-session.log"
        fi
        # NÃO encerrar o shell — deixar o usuário interagir se X falhar
    fi
fi
