# Point d'entrée de tous les modules EPIVÍOSI OS.
{
  imports = [
    ./epiviosi-modules.nix
    ./branding.nix
    ./locale.nix
    ./desktop.nix
    ./packages.nix
    ./firefox.nix
    ./firefox-translations
    ./persistence.nix
    ./hardening.nix
  ];
}
