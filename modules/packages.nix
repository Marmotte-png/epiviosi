# Logiciels de base. Volontairement léger : les outils spécialisés
# (wiki, cartes, sécurité…) viendront avec leurs modules respectifs.
{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    languagePacks = [
      "fr"
      "en-US"
    ];
    # Session live hors-ligne : pas d'onglets de bienvenue, de note de
    # confidentialité ni de télémétrie à chaque démarrage.
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DontCheckDefaultBrowser = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      UserMessaging = {
        SkipOnboarding = true;
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        MoreFromMozilla = false;
        Locked = true;
      };
    };
    preferences = {
      # Onglet « Privacy Notice » / « Note sur la confidentialité ».
      "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
      "datareporting.policy.firstRunURL" = "";
    };
  };

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
