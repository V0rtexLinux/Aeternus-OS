#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  V0rtexOS — COMPILAR ISO (rodar em Arch Linux ou Docker)
#  Uso: bash COMPILE-ISO.sh [x86_64|arm64|rpi|mobile]
#  Requer: Arch Linux nativo OU Docker instalado
# ══════════════════════════════════════════════════════════════
set -uo pipefail

RED='\033[1;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_OUTPUT="$SCRIPT_DIR/release"
mkdir -p "$ISO_OUTPUT"

# Target: primeiro argumento ou padrão x86_64
TARGET="${1:-x86_64}"
case "$TARGET" in
    x86_64|arm64|aarch64|rpi|mobile) ;;
    *) echo -e "${RED}ERRO: target inválido. Use: x86_64 | arm64 | rpi | mobile${RST}"; exit 1 ;;
esac
[[ "$TARGET" == "arm64" ]] && TARGET="aarch64"

log()  { echo -e "\n${CYN}${BLD}▶ $*${RST}"; }
ok()   { echo -e "${GRN}✓ $*${RST}"; }
warn() { echo -e "${YLW}⚠ $*${RST}"; }
err()  { echo -e "${RED}✗ $*${RST}" >&2; exit 1; }

echo -e "${BLD}"
echo "  ██╗   ██╗ ██████╗ ██████╗ ████████╗███████╗██╗  ██╗"
echo "  ██║   ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝╚██╗██╔╝"
echo "  ██║   ██║██║   ██║██████╔╝   ██║   █████╗   ╚███╔╝ "
echo "  ╚██╗ ██╔╝██║   ██║██╔══██╗   ██║   ██╔══╝   ██╔██╗ "
echo "   ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗██╔╝ ██╗"
echo "    ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
echo -e "  ${CYN}ISO Builder${RST}${BLD} — V0rtexOS Grey Hat Security — target: ${TARGET}${RST}"
echo ""

# ── Detectar método de build ──────────────────────────────────
METHOD=""
if command -v pacman &>/dev/null && [ -f /etc/arch-release ]; then
    METHOD="arch-native"
    ok "Arch Linux detectado — build nativo"
elif command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    METHOD="docker"
    ok "Docker detectado — build via container"
elif command -v podman &>/dev/null; then
    METHOD="podman"
    ok "Podman detectado — build via container"
else
    err "Nenhum método de build disponível.
  Opções:
  1. Rodar em Arch Linux (nativo ou VM)
  2. Instalar Docker: https://docs.docker.com/get-docker/
  3. Usar GitHub Actions: push para GitHub e o CI compila automaticamente
     (workflows em .github/workflows/)"
fi

echo ""

# ════════════════════════════════════════════════════
# MÉTODO 1 — Arch Linux Nativo
# ════════════════════════════════════════════════════
build_arch_native() {
    log "Compilando em Arch Linux nativo (target=$TARGET)..."
    [[ $EUID -ne 0 ]] && err "Build nativo requer root: sudo bash COMPILE-ISO.sh $TARGET"

    log "Instalando dependências..."
    pacman -Syu --noconfirm --needed \
        archiso git curl base-devel \
        gcc make cairo libxrender libx11 pkg-config \
        squashfs-tools libisoburn dosfstools mtools \
        grub efibootmgr

    # BlackArch apenas para x86_64
    if [[ "$TARGET" == "x86_64" ]]; then
        if ! grep -q "\[blackarch\]" /etc/pacman.conf; then
            log "Configurando BlackArch..."
            curl -fsSL https://blackarch.org/strap.sh -o /tmp/strap.sh
            chmod +x /tmp/strap.sh && bash /tmp/strap.sh && rm /tmp/strap.sh
        fi
    fi

    log "Executando build.sh --target=$TARGET..."
    bash "$SCRIPT_DIR/build.sh" "--target=$TARGET"

    _show_result
}

# ════════════════════════════════════════════════════
# MÉTODO 2 — Docker / Podman
# ════════════════════════════════════════════════════
build_docker() {
    local DOCKER_CMD="${1:-docker}"
    log "Compilando via $DOCKER_CMD (target=$TARGET)..."

    local FREE_GB
    FREE_GB=$(df "$ISO_OUTPUT" --output=avail -BG 2>/dev/null | tail -1 | tr -d 'G ' || echo "99")
    if [ "$FREE_GB" -lt 15 ]; then
        warn "Menos de 15GB livres ($FREE_GB GB). Build pode falhar."
    fi

    local DOCKER_IMAGE="archlinux:latest"
    local DOCKER_PLATFORM=""
    local KEYRING_CMD="pacman-key --populate archlinux"

    if [[ "$TARGET" != "x86_64" ]]; then
        DOCKER_IMAGE="archlinuxarm/base:latest"
        DOCKER_PLATFORM="--platform linux/arm64"
        KEYRING_CMD="pacman-key --populate archlinuxarm 2>/dev/null || pacman-key --populate archlinux"

        # Verificar se QEMU ARM64 está disponível
        if ! $DOCKER_CMD run --rm --platform linux/arm64 alpine:latest uname -m 2>/dev/null | grep -q aarch64; then
            warn "QEMU ARM64 pode não estar configurado. Instale: qemu-user-static"
            warn "Ubuntu: sudo apt install qemu-user-static"
        fi
    fi

    cat > /tmp/v0rtex-build-entry.sh <<DOCKER_ENTRY
#!/bin/bash
set -euo pipefail
echo "[v0rtex] Build container iniciado (target=$TARGET)"
df -h || true

# Mirror ARM64 se necessário
if [[ "$TARGET" != "x86_64" ]] && [[ -d /etc/pacman.d ]]; then
    echo 'Server = https://mirror.archlinuxarm.org/\$arch/\$repo' > /etc/pacman.d/mirrorlist || true
fi

# Instalar dependências
pacman -Sy --noconfirm --needed archlinux-keyring haveged 2>/dev/null || \
    pacman -Syu --noconfirm --needed 2>/dev/null || true
haveged -w 1024 & sleep 2
pacman-key --init
$KEYRING_CMD

pacman -S --noconfirm --needed \
    archiso git curl base-devel gcc make cmake \
    cairo libxrender libx11 pkg-config \
    squashfs-tools libisoburn dosfstools mtools \
    grub efibootmgr python openssl 2>&1 | tail -5

# BlackArch apenas para x86_64
if [[ "$TARGET" == "x86_64" ]]; then
    curl -fsSL https://blackarch.org/strap.sh -o /tmp/strap.sh || true
    chmod +x /tmp/strap.sh && bash /tmp/strap.sh 2>&1 | tail -5 && rm /tmp/strap.sh || true
    pacman -Sy --noconfirm || true
fi

echo "[v0rtex] Iniciando build.sh --target=$TARGET"
cd /project
chmod +x build.sh
CI=true bash build.sh "--target=$TARGET" 2>&1

echo "[v0rtex] Build concluído"
df -h || true
DOCKER_ENTRY
    chmod +x /tmp/v0rtex-build-entry.sh

    log "Iniciando container $DOCKER_IMAGE (precisa de --privileged)..."
    log "Isso pode levar 30-90 minutos dependendo da conexão."
    echo ""

    $DOCKER_CMD run \
        --privileged \
        --rm \
        $DOCKER_PLATFORM \
        --name "v0rtexos-build-$$" \
        -v "$SCRIPT_DIR:/project:ro" \
        -v "$ISO_OUTPUT:/project/release" \
        -v "/tmp/v0rtex-build-entry.sh:/entrypoint.sh:ro" \
        -e TERM=xterm \
        -e CI=true \
        -e TARGET="$TARGET" \
        "$DOCKER_IMAGE" \
        bash /entrypoint.sh

    _show_result
}

# ── Resultado ─────────────────────────────────────────────────
_show_result() {
    echo ""
    local ISO
    ISO=$(find "$ISO_OUTPUT" -name "*.iso" 2>/dev/null | head -1)
    if [ -n "$ISO" ]; then
        SIZE=$(du -sh "$ISO" | cut -f1)
        SHA=$(sha256sum "$ISO" 2>/dev/null | cut -d' ' -f1 | head -c 16)
        echo -e "${GRN}${BLD}"
        echo "  ╔═══════════════════════════════════════════════════╗"
        echo "  ║        V0RTEX OS — ISO PRONTA!                   ║"
        echo "  ╠═══════════════════════════════════════════════════╣"
        printf "  ║  Arquivo : %-36s║\n" "$(basename "$ISO")"
        printf "  ║  Tamanho : %-36s║\n" "$SIZE"
        printf "  ║  SHA256  : %-36s║\n" "${SHA}..."
        printf "  ║  Target  : %-36s║\n" "$TARGET"
        echo "  ╠═══════════════════════════════════════════════════╣"
        if [[ "$TARGET" == "rpi" ]]; then
            echo "  ║  Gravar microSD:                                  ║"
            echo "  ║  sudo dd if=*.iso of=/dev/mmcblkX bs=4M          ║"
        else
            echo "  ║  Gravar USB:                                      ║"
            echo "  ║  sudo dd if=*.iso of=/dev/sdX bs=4M status=progress║"
        fi
        if [[ "$TARGET" == "x86_64" ]]; then
            echo "  ╠═══════════════════════════════════════════════════╣"
            echo "  ║  Testar QEMU:                                     ║"
            echo "  ║  qemu-system-x86_64 -boot d -cdrom *.iso -m 4096 ║"
        fi
        echo "  ╚═══════════════════════════════════════════════════╝"
        echo -e "${RST}"
    else
        warn "ISO não encontrada em $ISO_OUTPUT"
    fi
}

# ── Executar método detectado ─────────────────────────────────
case "$METHOD" in
    arch-native) build_arch_native ;;
    docker)      build_docker "docker" ;;
    podman)      build_docker "podman" ;;
esac
