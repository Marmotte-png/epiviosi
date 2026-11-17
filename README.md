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
- **EPIVÍOSI WIKI** : Wikipédia et autres archives ZIM hors-ligne (Kiwix), sur une partition `EPIV-WIKI`
- **EPIVÍOSI MAPS** : cartes OpenStreetMap, recherche et itinéraires hors-ligne (Organic Maps), sur une partition `EPIV-MAPS`
- **EPIVÍOSI SECURITY** : clés USB et fichiers chiffrés, nettoyage des métadonnées, guide et documentation hors-ligne
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
scripts/run-vm.sh uefi --wiki       # avec un disque EPIV-WIKI contenant les .zim de .vm/zim/
scripts/run-vm.sh uefi --maps       # avec un disque EPIV-MAPS contenant .vm/maps/
scripts/run-vm.sh uefi --offline    # sans réseau, pour vérifier le hors-ligne
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
sudo epiviosi-persist-setup            # clé USB de démarrage, tout l'espace libre
sudo epiviosi-persist-setup --size 8G  # ou une taille fixe
sudo epiviosi-persist-setup /dev/sdY   # ou un autre disque
```

Seul le contenu de `~/Persistant` est conservé.

## Wiki hors-ligne (EPIVÍOSI WIKI)

Les archives ZIM (Wikipédia FR complète ≈ 56 Go avec images, ≈ 13 Go sans ; EN ≈ 128 Go) ne tiennent pas
dans l'ISO : elles vont sur une partition **exFAT** étiquetée `EPIV-WIKI`
(11 caractères au plus en exFAT). Elle est montée sur `/wiki`, et tous ses
`.zim` sont servis par Kiwix sur <http://127.0.0.1:8080> (lanceur
« EPIVÍOSI WIKI » dans le menu).

```sh
sudo epiviosi-wiki-setup --size 60G    # sur la clé de démarrage
sudo epiviosi-persist-setup            # puis la persistance dans l'espace restant
```

On peut aussi formater la partition depuis Windows, macOS ou Linux (exFAT,
nom `EPIV-WIKI`) et y copier des fichiers téléchargés sur
[download.kiwix.org](https://download.kiwix.org/zim/wikipedia/).
Le module est fourni par [epiviosi-wiki](https://github.com/Marmotte-png/epiviosi-wiki).

## Cartes hors-ligne (EPIVÍOSI MAPS)

Les cartes Organic Maps (France ≈ 4,9 Go, outre-mer compris) vont sur une
partition **exFAT** étiquetée `EPIV-MAPS`, montée sur `/maps`. Le lanceur
« EPIVÍOSI MAPS » y redirige les données d'Organic Maps : cartes, favoris et
traces restent sur la clé.

```sh
sudo epiviosi-maps-setup --size 8G     # partition EPIV-MAPS
epiviosi-maps-fetch                    # cartes de la France (connexion requise)
epiviosi-maps-fetch --list             # autres pays disponibles
```

Le module est fourni par [epiviosi-maps](https://github.com/Marmotte-png/epiviosi-maps).

## Sécurité (EPIVÍOSI SECURITY)

Chiffrement de clés USB et de disques (GNOME Disques, LUKS), de fichiers
(Picocrypt, GnuPG + GPA, age), nettoyage des métadonnées (Metadata Cleaner),
BleachBit, GtkHash. Le lanceur « EPIVÍOSI SECURITY » ouvre un guide pas à pas,
et `epiviosi-security-docs` ajoute au wiki ≈ 0,8 Go de documentation
(Information Security, Cryptography, The OpSec Bible).
Le module est fourni par [epiviosi-security](https://github.com/Marmotte-png/epiviosi-security).

## Préparer une clé de 128 Go

```sh
sudo dd if=epiviosi-live-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync   # ≈ 3 Go
# puis, après avoir démarré sur la clé, avec une connexion :
sudo epiviosi-wiki-setup --size 75G    # Wikipédia FR + intros EN (≈ 70 Go)
sudo epiviosi-maps-setup --size 8G     # cartes de la France (≈ 5 Go)
sudo epiviosi-persist-setup            # persistance dans l'espace restant (≈ 35 Go)
epiviosi-wiki-fetch && epiviosi-maps-fetch && epiviosi-security-docs
```

## Structure

| Chemin | Rôle |
| --- | --- |
| `flake.nix` | Entrée du projet (nixpkgs `nixos-26.05`) |
| `hosts/live-iso.nix` | Paramètres de l'image ISO |
| `modules/` | Modules NixOS : identité, langue, bureau, paquets, persistance, durcissement |
| `epiviosi-wiki` (entrée du flake) | Module EPIVÍOSI WIKI (Kiwix), activé dans `hosts/live-iso.nix` |
| `epiviosi-maps` (entrée du flake) | Module EPIVÍOSI MAPS (Organic Maps), activé dans `hosts/live-iso.nix` |
| `epiviosi-security` (entrée du flake) | Module EPIVÍOSI SECURITY, activé dans `hosts/live-iso.nix` |
| `modules/epiviosi-modules.nix` | Options `epiviosi.{wiki,medic,maps,security}.enable` pour les autres modules |
| `pkgs/epiviosi-persist/` | Outil `epiviosi-persist-setup` |
| `assets/` | Logo et fond d'écran |
| `scripts/` | Construction et tests en VM |

## Licence

[Hippocratic License 2.1](LICENSE).
