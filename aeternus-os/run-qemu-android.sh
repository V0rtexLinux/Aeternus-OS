#!/data/data/com.termux/files/usr/bin/bash
# V0rtexOS — Script de Inicialização para QEMU no Android (Termux)
# Este script cria um ambiente compatível com qualquer celular (ARM/ARM64)
# emulando a ISO x86_64 do V0rtexOS via QEMU TCG com otimizações para mobile.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Procura pela ISO do V0rtexOS na pasta atual
ISO_FILE=$(ls "$DIR"/v0rtex-os-*.iso 2>/dev/null | sort | tail -n 1)

echo "================================================="
echo "  V0rtexOS - Android Mobile Edition (Termux)     "
echo "================================================="

if [ -z "$ISO_FILE" ]; then
    echo "[ERRO] Nenhuma ISO do V0rtexOS (v0rtex-os-*.iso) encontrada na pasta:"
    echo "       $DIR"
    echo "       Por favor, coloque a ISO aqui e tente novamente."
    exit 1
fi

echo "[INFO] ISO detectada: $(basename "$ISO_FILE")"
echo "[INFO] Verificando se o qemu-system-x86_64 está instalado..."

if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "[AVISO] qemu-system-x86_64 não encontrado!"
    echo "[INFO] Instalando QEMU headless..."
    pkg update -y
    pkg install qemu-system-x86_64-headless -y
fi

echo "================================================="
echo "[VNC] O V0rtexOS sera iniciado em Background."
echo "[VNC] Para ver a tela, abra o aplicativo AVNC"
echo "[VNC] e conecte-se a: 127.0.0.1 porta 5900"
echo "================================================="
echo "[INFO] Dica de Otimizacao: A emulacao x86_64 em ARM "
echo "       pode ser lenta. Configuramos 1GB de RAM e 2 Cores"
echo "       para evitar travamentos no seu Android."
echo "================================================="
echo "[>>] Iniciando V0rtexOS... (Pressione Ctrl+C para forcar parada)"

# Rodamos o QEMU com configurações otimizadas para emulação TCG em celulares
qemu-system-x86_64 \
    -machine q35 \
    -cpu qemu64 \
    -m 1024 \
    -smp 2 \
    -cdrom "$ISO_FILE" \
    -boot d \
    -vga virtio \
    -display vnc=127.0.0.1:0 \
    -netdev user,id=net0 \
    -device virtio-net,netdev=net0 \
    -usb \
    -device usb-tablet \
    -audiodev none,id=noaudio
