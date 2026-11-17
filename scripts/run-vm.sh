#!/usr/bin/env bash
# Démarre l'ISO EPIVÍOSI dans QEMU/KVM.
#
# Usage : scripts/run-vm.sh [uefi|bios] [options]
#   --usb           démarre l'ISO comme une clé USB de 8 Go (copie dans .vm/usb.img)
#   --persist       ajoute un disque .vm/persist.qcow2 (à formater EPIVIOSI-DATA)
#   --headless      pas de fenêtre ; moniteur QEMU sur .vm/monitor.sock
#   --iso FICHIER   ISO à utiliser (défaut : result/iso/*.iso)
set -euo pipefail
cd "$(dirname "$0")/.."

mode=uefi usb=0 persist=0 headless=0 iso=""
while [ $# -gt 0 ]; do
  case "$1" in
    uefi|bios) mode="$1" ;;
    --usb) usb=1 ;;
    --persist) persist=1 ;;
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
      -nic user,model=virtio-net-pci
      -device qemu-xhci)

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

if [ "$headless" = 1 ]; then
  args+=(-display none -monitor "unix:.vm/monitor.sock,server,nowait"
         -serial file:.vm/serial.log)
else
  args+=(-display gtk)
fi

exec qemu-system-x86_64 "${args[@]}"
