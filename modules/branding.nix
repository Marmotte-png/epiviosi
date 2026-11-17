# Identité du système : nom, os-release, messages d'accueil, utilisateur live.
{ config, lib, pkgs, ... }:
let
  user = config.epiviosi.user;
in
{
  # En ASCII : le menu BIOS (syslinux) et la console n'affichent pas l'UTF-8.
  # L'accent reste dans les éléments graphiques (logo, fond d'écran).
  system.nixos.distroName = "EPIVIOSI";
  system.nixos.distroId = "epiviosi";

  networking.hostName = "epiviosi";

  isoImage.appendToMenuLabel = " Live";

  # Menu de démarrage aux couleurs d'EPIVÍOSI (UEFI : GRUB, BIOS : syslinux).
  isoImage.grubTheme = "${pkgs.epiviosi-artwork}/grub-theme";
  isoImage.splashImage = "${pkgs.epiviosi-artwork}/bios-splash.png";
  isoImage.syslinuxTheme = ''
    MENU TITLE EPIVIOSI
    MENU RESOLUTION 800 600
    MENU CLEAR
    MENU ROWS 6
    MENU CMDLINEROW -4
    MENU TIMEOUTROW -3
    MENU TABMSGROW  -2
    MENU HELPMSGROW -1
    MENU HELPMSGENDROW -1
    MENU MARGIN 4

    #                                FG:AARRGGBB  BG:AARRGGBB   shadow
    MENU COLOR BORDER       30;44      #00000000    #00000000   none
    MENU COLOR SCREEN       37;40      #FFF1EDE4    #00000000   none
    MENU COLOR TABMSG       31;40      #807FA6C4    #00000000   none
    MENU COLOR TIMEOUT      1;37;40    #FFE8B04B    #00000000   none
    MENU COLOR TIMEOUT_MSG  37;40      #FFF1EDE4    #00000000   none
    MENU COLOR CMDMARK      1;36;40    #FFE8B04B    #00000000   none
    MENU COLOR CMDLINE      37;40      #FFF1EDE4    #00000000   none
    MENU COLOR TITLE        1;36;44    #00000000    #00000000   none
    MENU COLOR UNSEL        37;44      #FFF1EDE4    #00000000   none
    MENU COLOR SEL          7;37;40    #FF0B1826    #FFE8B04B   std
  '';

  services.getty.greetingLine = ''<<< EPIVÍOSI OS (\m) — \l >>>'';
  services.getty.helpLine = lib.mkForce ''

    Bienvenue dans EPIVÍOSI OS / Welcome to EPIVÍOSI OS.
    Session live : l'utilisateur « ${user} » n'a pas de mot de passe.
    Persistance : lancez « sudo epiviosi-persist-setup » pour créer la partition EPIVIOSI-DATA.
  '';

  users.users.${user} = {
    isNormalUser = true;
    description = "EPIVÍOSI";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
    initialHashedPassword = "";
  };

  # Le profil d'installation NixOS connecte « nixos » par défaut : on le remplace.
  services.getty.autologinUser = lib.mkForce user;
}
