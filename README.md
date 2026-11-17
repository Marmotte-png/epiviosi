# EPIVÍOSI OS

Système live hors-ligne basé sur NixOS (x86_64), socle de la suite EPIVÍOSI :
[wiki](https://github.com/Marmotte-png/epiviosi-wiki),
[medic](https://github.com/Marmotte-png/epiviosi-medic),
[maps](https://github.com/Marmotte-png/epiviosi-maps),
[security](https://github.com/Marmotte-png/epiviosi-security).

## Caractéristiques

- Live ISO amorçable en BIOS et UEFI, sur DVD ou clé USB
- Bureau XFCE, connexion automatique (utilisateur `epiviosi`, sans mot de passe)
- Choix de la langue au démarrage : **Français (AZERTY)** par défaut, ou **English (QWERTY)**
- Amnésique par défaut ; persistance optionnelle via une partition `EPIVIOSI-DATA`
- Pare-feu actif, pas de serveur SSH, réglages noyau durcis

## Prérequis (machine de construction)

- Linux x86_64 avec [Nix](https://nixos.org/download) (mode multi-utilisateur) et les flakes activés :
  ```sh
  sh <(curl -L https://nixos.org/nix/install) --daemon
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
  sudo systemctl restart nix-daemon
  ```
- Pour les tests : QEMU avec KVM, et OVMF pour l'UEFI.

## Construire

```sh
scripts/build-iso.sh          # => result/iso/epiviosi-live-x86_64.iso
nix flake check               # évalue la configuration et construit les paquets
```

## Tester dans une machine virtuelle

```sh
scripts/run-vm.sh uefi              # démarrage UEFI depuis le CD
scripts/run-vm.sh bios              # démarrage BIOS
scripts/run-vm.sh uefi --usb        # comme une clé USB de 8 Go
scripts/run-vm.sh uefi --persist    # avec un disque supplémentaire pour la persistance
```

## Écrire sur une clé USB

```sh
sudo dd if=result/iso/epiviosi-live-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Remplacez `/dev/sdX` par la clé (vérifiez avec `lsblk` : tout son contenu est effacé).

## Persistance

Le système est entièrement amnésique, sauf si une partition ext4 étiquetée
`EPIVIOSI-DATA` est présente : elle est alors montée sur `/persist`, et
`~/Persistant` y mène. Pour la créer dans l'espace libre de la clé de démarrage :

```sh
sudo epiviosi-persist-setup            # clé USB de démarrage
sudo epiviosi-persist-setup /dev/sdY   # ou un autre disque
```

Seul le contenu de `~/Persistant` est conservé.

## Structure

| Chemin | Rôle |
| --- | --- |
| `flake.nix` | Entrée du projet (nixpkgs `nixos-26.05`) |
| `hosts/live-iso.nix` | Paramètres de l'image ISO |
| `modules/` | Modules NixOS : identité, langue, bureau, paquets, persistance, durcissement |
| `modules/epiviosi-modules.nix` | Options `epiviosi.{wiki,medic,maps,security}.enable` pour les autres modules |
| `pkgs/epiviosi-persist/` | Outil `epiviosi-persist-setup` |
| `assets/` | Logo et fond d'écran |
| `scripts/` | Construction et tests en VM |

## Licence

[Hippocratic License 2.1](LICENSE).
