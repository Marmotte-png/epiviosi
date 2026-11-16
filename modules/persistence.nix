# Persistance optionnelle : si une partition ext4 étiquetée EPIVIOSI-DATA est
# présente (au démarrage ou branchée plus tard), elle est montée sur /persist et
# ~/Persistant y pointe. Sans elle, le système reste entièrement amnésique.
#
# On passe par une unité systemd déclenchée par l'apparition du périphérique
# plutôt que par fileSystems : le démarrage n'attend jamais un disque absent.
{ config, pkgs, ... }:
let
  user = config.epiviosi.user;
  label = "EPIVIOSI-DATA";
  deviceUnit = "dev-disk-by\\x2dlabel-EPIVIOSI\\x2dDATA.device";
  udevIsoRule = ''
    SUBSYSTEM=="block", KERNEL!="sr[0-9]*", ENV{DEVTYPE}=="disk", ENV{ID_PART_TABLE_TYPE}=="?*", ENV{ID_FS_TYPE}=="iso9660", SYMLINK-="disk/by-label/${config.isoImage.volumeID}"
  '';
in
{
  # Sur une clé USB, l'ISO est visible à la fois sur le disque entier (sdX) et
  # sur sa première partition (sdX1), avec la même étiquette. Si /iso est monté
  # depuis le disque entier, le noyau interdit ensuite de formater ou monter
  # toute autre partition de la clé. Une simple priorité ne suffit pas : dans
  # l'initrd, sdX apparaît avant sdX1 et /iso serait déjà monté. On retire donc
  # le lien by-label du disque entier dès qu'il porte une table de partitions
  # (un lecteur CD/DVD, dont le noyau ne lit pas les partitions, est exclu).
  boot.initrd.services.udev.rules = udevIsoRule;
  services.udev.extraRules = udevIsoRule;

  systemd.mounts = [
    {
      what = "/dev/disk/by-label/${label}";
      where = "/persist";
      type = "ext4";
      options = "noatime";
      wantedBy = [ deviceUnit ];
    }
  ];

  # Une partition déjà présente dans l'initrd n'« apparaît » jamais aux yeux du
  # systemd principal : le déclencheur ci-dessus ne sert alors qu'aux clés
  # branchées après le démarrage. Ce service couvre le cas du démarrage.
  systemd.services.epiviosi-persist-boot = {
    description = "Montage de la partition EPIVÍOSI présente au démarrage";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-trigger.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ -e /dev/disk/by-label/${label} ]; then
        systemctl start --no-block persist.mount
      fi
    '';
  };

  systemd.services.epiviosi-persist-init = {
    description = "Préparation du dossier persistant EPIVÍOSI";
    after = [ "persist.mount" ];
    requires = [ "persist.mount" ];
    wantedBy = [ "persist.mount" ];
    serviceConfig.Type = "oneshot";
    script = ''
      install -d -o ${user} -g users -m 0700 /persist/${user}
      home=${config.users.users.${user}.home}
      if [ ! -e "$home/Persistant" ]; then
        ln -s /persist/${user} "$home/Persistant"
        chown -h ${user}:users "$home/Persistant"
      fi
    '';
    path = [ pkgs.coreutils ];
  };
}
