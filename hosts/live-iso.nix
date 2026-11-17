# Configuration de l'image live EPIVÍOSI.
{ lib, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"
    ../modules
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  image.baseName = lib.mkForce "epiviosi-live-x86_64";

  isoImage = {
    volumeID = "EPIVIOSI";
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 19";
  };

  # ZFS n'est pas utile ici : on le retire (ISO plus légère, pas d'avertissement).
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # Modules de la suite EPIVÍOSI.
  epiviosi.wiki.enable = true;

  system.stateVersion = "26.05";
}
