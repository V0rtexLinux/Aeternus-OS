#!/bin/bash
# ==============================================================================
# Script: setup_android.sh
# Função: Instalar todas as dependências no Termux automaticamente
# Como usar: Copie este arquivo para o celular e rode "bash setup_android.sh"
# ==============================================================================

echo "================================================="
echo "  V0rtexOS - Instalador Automático para Termux"
echo "================================================="
echo ""

echo "[1/4] Atualizando pacotes do sistema..."
pkg update -y

echo "[2/4] Instalando emulador QEMU, Git, Wget e Termux-API..."
pkg install qemu-system-x86_64-headless git wget termux-api termux-tools -y

echo "[3/4] Baixando o repositório do V0rtexOS..."
if [ ! -d "$HOME/V0rtexOS" ]; then
    git clone https://github.com/V0rtexLinux/V0rtexOS.git $HOME/V0rtexOS
else
    echo "Repositório já existe. Puxando atualizações..."
    cd $HOME/V0rtexOS && git pull
    cd $HOME
fi

echo "[4/4] Baixando o app AVNC (VNC Viewer)..."
APK_FILE="$HOME/AVNC.apk"
# Link direto para baixar a última versão do AVNC (Open Source) do GitHub
wget -q --show-progress -O "$APK_FILE" https://github.com/gujjwal00/avnc/releases/download/v3.2.2/AVNC-3.2.2.apk

echo ""
echo "================================================="
echo " SETUP CONCLUÍDO COM SUCESSO!"
echo "================================================="
echo ""
echo "O arquivo AVNC.apk foi baixado. Vou tentar abri-lo para instalação agora."
echo "Por favor, autorize o Termux a instalar aplicativos se o Android pedir."
echo ""

# Tenta abrir o instalador do Android automaticamente
termux-open "$APK_FILE"

echo "Lembre-se: Você precisa colocar a imagem v0rtex-os-2026.05.13-x86_64.iso dentro da pasta ~/V0rtexOS/aeternus-os/"
