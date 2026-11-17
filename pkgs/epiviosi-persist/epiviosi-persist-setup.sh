# epiviosi-persist-setup — crée la partition de persistance EPIVIOSI-DATA.
#
# Usage : sudo epiviosi-persist-setup [DISQUE]
#   DISQUE : disque entier (ex. /dev/sdb). Par défaut, la clé USB qui a
#            démarré EPIVÍOSI. La partition est ajoutée dans l'espace libre
#            restant ; les partitions existantes ne sont pas modifiées.

LABEL="EPIVIOSI-DATA"

die() { echo "Erreur : $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "lancez cette commande avec sudo."

if [ -e "/dev/disk/by-label/$LABEL" ]; then
  echo "Une partition $LABEL existe déjà : $(readlink -f "/dev/disk/by-label/$LABEL")"
  exit 0
fi

disk="${1:-}"
if [ -z "$disk" ]; then
  src="$(findmnt -no SOURCE /iso 2>/dev/null || true)"
  [ -n "$src" ] || die "impossible de trouver le support de démarrage ; indiquez le disque (ex. /dev/sdb)."
  parent="$(lsblk -no PKNAME "$src" | head -n1)"
  if [ -n "$parent" ]; then disk="/dev/$parent"; else disk="$src"; fi
fi

[ -b "$disk" ] || die "$disk n'est pas un périphérique bloc."
[ "$(lsblk -dno TYPE "$disk")" = "disk" ] || die "$disk n'est pas un disque entier."
case "$(lsblk -dno TYPE,RO "$disk")" in
  *1) die "$disk est en lecture seule (CD/DVD ?). La persistance nécessite une clé USB." ;;
esac

pttype="$(blkid -p -o value -s PTTYPE "$disk" 2>/dev/null || true)"
[ -n "$pttype" ] || die "$disk n'a pas de table de partitions."

echo "Disque cible : $disk ($pttype)"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS "$disk"
echo
echo "Une partition ext4 « $LABEL » va être créée dans l'espace libre de ce disque."
printf "Tapez OUI pour continuer : "
read -r answer
[ "$answer" = "OUI" ] || [ "$answer" = "YES" ] || die "annulé."

before="$(lsblk -lnpo NAME,TYPE "$disk" | awk '$2=="part"{print $1}' | sort)"

case "$pttype" in
  gpt)
    # Image hybride : l'en-tête GPT de secours est à la fin de l'image et non
    # à la fin du disque. On le déplace pour libérer l'espace restant.
    sgdisk -e "$disk" >/dev/null
    sgdisk -n "0:0:0" -t "0:8300" -c "0:$LABEL" "$disk" >/dev/null || die "création de la partition impossible (espace libre insuffisant ?)."
    ;;
  dos)
    echo ',,83' | sfdisk --append --no-reread --wipe never "$disk" >/dev/null || die "création de la partition impossible (espace libre insuffisant ?)."
    ;;
  *)
    die "type de table de partitions non pris en charge : $pttype"
    ;;
esac

# Le disque est en cours d'utilisation (il porte /iso) : le noyau refuse de
# relire la table. On ajoute seulement les nouvelles partitions, sans toucher
# à celles qui existent.
partx -a "$disk" 2>/dev/null || true
udevadm settle

after="$(lsblk -lnpo NAME,TYPE "$disk" | awk '$2=="part"{print $1}' | sort)"
part="$(comm -13 <(echo "$before") <(echo "$after") | head -n1)"
[ -n "$part" ] || die "nouvelle partition introuvable ; redémarrez puis relancez la commande."

mkfs.ext4 -q -L "$LABEL" "$part"
udevadm settle

echo "Partition $part créée. Elle est montée sur /persist (lien ~/Persistant)."
