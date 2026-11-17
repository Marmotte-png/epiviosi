# Logiciels de base. Volontairement léger : les outils spécialisés
# (wiki, cartes, sécurité…) viendront avec leurs modules respectifs.
{ pkgs, ... }:
{
  programs.nm-applet.enable = true;

  environment.systemPackages = with pkgs; [
    # Bureautique et documents
    libreoffice-fresh
    hunspell
    hunspellDicts.fr-moderne
    hunspellDicts.en_US
    evince
    mousepad
    ristretto
    file-roller

    # Sécurité de base
    keepassxc

    # Système
    gparted
    pavucontrol
    htop
    git
    vim
    nano
    curl
    wget
    rsync
    p7zip
    unzip

    # EPIVÍOSI
    epiviosi-persist
  ];
}
