# Langue et clavier. Français (AZERTY) par défaut ; la specialisation
# « english » ajoute une entrée de démarrage en anglais (QWERTY).
{ lib, ... }:
{
  i18n.defaultLocale = lib.mkDefault "fr_FR.UTF-8";
  i18n.supportedLocales = [
    "fr_FR.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
  console.keyMap = lib.mkDefault "fr";
  services.xserver.xkb.layout = lib.mkDefault "fr";
  time.timeZone = "Europe/Paris";

  # Libellés des entrées du menu de démarrage.
  isoImage.configurationName = lib.mkDefault "(Francais)";

  specialisation.english.configuration = {
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";
    services.xserver.xkb.layout = "us";
    isoImage.configurationName = "(English)";
  };
}
