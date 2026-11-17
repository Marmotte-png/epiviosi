#!/usr/bin/env bash
# Démarre l'ISO EPIVÍOSI dans QEMU/KVM.
#
# Usage : scripts/run-vm.sh [uefi|bios] [options]
#   --usb           démarre l'ISO comme une clé USB de 8 Go (copie dans .vm/usb.img)
#   --persist       ajoute un disque .vm/persist.qcow2 (à formater EPIVIOSI-DATA)
#   --wiki          ajoute un disque exFAT EPIV-WIKI (.vm/wiki.img) contenant
#                   les .zim du dossier .vm/zim/ (copiés via udisksctl)
#   --maps          ajoute un disque exFAT EPIV-MAPS (.vm/maps.img) contenant
#                   le dossier .vm/maps/ (ex. .vm/maps/organicmaps/260527/*.mwm)
#   --offline       pas de carte réseau (vérifier le fonctionnement hors-ligne)
#   --headless      pas de fenêtre ; moniteur QEMU sur .vm/monitor.sock et
#                   QMP sur .vm/qmp.sock (tests automatisés : clavier, souris)
#   --iso FICHIER   ISO à utiliser (défaut : result/iso/*.iso)
set -euo pipefail
cd "$(dirname "$0")/.."

mode=uefi usb=0 persist=0 wiki=0 maps=0 offline=0 headless=0 iso=""
while [ $# -gt 0 ]; do
  case "$1" in
    uefi|bios) mode="$1" ;;
    --usb) usb=1 ;;
    --persist) persist=1 ;;
    --wiki) wiki=1 ;;
    --maps) maps=1 ;;
    --offline) offline=1 ;;
    --headless) headless=1 ;;
    --iso) iso="$2"; shift ;;
    *) echo "option inconnue : $1" >&2; exit 1 ;;
  esac
  shift
done

if [ -z "$iso" ]; then
  iso="$(ls result/iso/*.iso 2>/dev/null | head -n1 || true)"
fi
[ -f "$iso" ] || { echo "ISO introuvable ; lancez d'abord scripts/build-iso.sh" >&2; exit 1; }

mkdir -p .vm
args=(-enable-kvm -cpu host -m 4096 -smp 2
      -vga virtio
      -device qemu-xhci -device usb-tablet)

if [ "$offline" = 1 ]; then
  args+=(-nic none)
else
  args+=(-nic user,model=virtio-net-pci)
fi

if [ "$mode" = uefi ]; then
  ovmf_code=/usr/share/OVMF/OVMF_CODE_4M.fd
  cp -f /usr/share/OVMF/OVMF_VARS_4M.fd .vm/OVMF_VARS.fd
  args+=(-drive "if=pflash,format=raw,readonly=on,file=$ovmf_code"
         -drive "if=pflash,format=raw,file=.vm/OVMF_VARS.fd")
fi

if [ "$usb" = 1 ]; then
  if [ ! -f .vm/usb.img ] || [ "$iso" -nt .vm/usb.img ]; then
    rm -f .vm/usb.img
    install -m 0644 "$iso" .vm/usb.img
    truncate -s 8G .vm/usb.img
  fi
  args+=(-drive "if=none,id=usbstick,format=raw,file=.vm/usb.img"
         -device "usb-storage,drive=usbstick,removable=on,bootindex=0")
else
  args+=(-drive "media=cdrom,readonly=on,file=$iso" -boot d)
fi

if [ "$persist" = 1 ]; then
  [ -f .vm/persist.qcow2 ] || qemu-img create -f qcow2 .vm/persist.qcow2 2G >/dev/null
  args+=(-drive "if=virtio,format=qcow2,file=.vm/persist.qcow2")
fi

# Disques de données (wiki, cartes) : un système de fichiers exFAT sur tout le
# disque, reconstruit quand le contenu du dossier source change. La copie passe
# par udisksctl (montage en loop sans sudo).
make_exfat_img() {  # ÉTIQUETTE IMAGE DOSSIER_SOURCE
  local label="$1" img="$2" src="$3" bytes size dev mp
  bytes="$(du -sb "$src" | cut -f1)"
  size=$(( (bytes / 1024 / 1024 / 1024) + 2 ))G
  rm -f "$img"
  truncate -s "$size" "$img"
  mkfs.exfat -L "$label" "$img" >/dev/null
  [ -n "$(ls -A "$src")" ] || return 0
  dev="$(udisksctl loop-setup --no-user-interaction -f "$img" | grep -o '/dev/loop[0-9]*')"
  sleep 1
  mp="$(findmnt -no TARGET "$dev" || true)"
  [ -n "$mp" ] || { udisksctl mount --no-user-interaction -b "$dev" >/dev/null; mp="$(findmnt -no TARGET "$dev")"; }
  echo "Copie de $src dans $img…"
  cp -r "$src"/. "$mp/"
  udisksctl unmount --no-user-interaction -b "$dev" >/dev/null
  # udisks libère souvent le périphérique loop dès le démontage.
  udisksctl loop-delete --no-user-interaction -b "$dev" >/dev/null 2>&1 || true
}

data_disk() {  # ÉTIQUETTE IMAGE DOSSIER_SOURCE
  mkdir -p "$3"
  if [ ! -f "$2" ] || [ -n "$(find "$3" -newer "$2" -print -quit)" ]; then
    make_exfat_img "$@"
  fi
  args+=(-drive "if=virtio,format=raw,file=$2")
}

[ "$wiki" = 1 ] && data_disk EPIV-WIKI .vm/wiki.img .vm/zim
[ "$maps" = 1 ] && data_disk EPIV-MAPS .vm/maps.img .vm/maps

if [ "$headless" = 1 ]; then
  args+=(-display none -monitor "unix:.vm/monitor.sock,server,nowait"
         -qmp "unix:.vm/qmp.sock,server,nowait"
         -serial file:.vm/serial.log)
else
  args+=(-display gtk)
fi

exec qemu-system-x86_64 "${args[@]}"
