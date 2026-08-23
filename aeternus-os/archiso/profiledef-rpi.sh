#!/usr/bin/env bash
# V0rtexOS — ArchISO Profile (Raspberry Pi 4/5 — ARM64)
# Live boot via microSD ou USB

iso_name="v0rtex-os-rpi"
iso_label="V0RTEX_RPI"
iso_publisher="V0rtex Security"
iso_application="V0rtexOS — Grey Hat Linux — Raspberry Pi Edition"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
    'uefi.grub'
)
arch="aarch64"
pacman_conf="pacman-aarch64.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=(
    '-comp' 'zstd'
    '-Xcompression-level' '3'
    '-b' '256K'
    '-no-duplicates'
)
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
    ["/etc/shadow"]="0:0:400"
    ["/etc/gshadow"]="0:0:400"
    ["/usr/local/bin/ghost-protocol.sh"]="0:0:755"
    ["/usr/local/bin/aet-scan"]="0:0:755"
    ["/usr/local/bin/aet-nuke"]="0:0:755"
    ["/usr/local/bin/amnesia"]="0:0:755"
    ["/usr/local/bin/install-tools.sh"]="0:0:755"
    ["/usr/local/bin/vortex-center"]="0:0:755"
    ["/usr/local/bin/aeternus-splash"]="0:0:755"
    ["/usr/local/bin/aeternus-panel"]="0:0:755"
    ["/usr/local/bin/aeternus-taskbar"]="0:0:755"
    ["/opt/vortex"]="0:0:755"
    ["/root"]="0:0:700"
    ["/root/.xinitrc"]="0:0:755"
    ["/root/.bash_profile"]="0:0:644"
    ["/root/.zprofile"]="0:0:644"
    ["/usr/local/bin/v0rtex-startx"]="0:0:755"
    ["/usr/local/bin/v0rtex-autoresize.sh"]="0:0:755"
)
