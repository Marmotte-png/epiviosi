# Firefox pour une session live hors-ligne.
#
# Le Firefox de nixpkgs est en anglais ; le pack de langue français est
# embarqué dans l'ISO (et non téléchargé au premier lancement, comme le fait
# l'option programs.firefox.languagePacks). Firefox suit la langue choisie au
# démarrage : français par défaut, anglais avec l'entrée « English ».
{ config, lib, pkgs, ... }:
let
  firefox = config.programs.firefox.package;
  version = firefox.version;

  # Un pack de langue ne fonctionne qu'avec la version exacte de Firefox.
  # Après une mise à jour de nixpkgs qui change cette version :
  #   nix store prefetch-file https://releases.mozilla.org/pub/firefox/releases/<VERSION>/linux-x86_64/xpi/fr.xpi
  # puis ajouter la version et le hash ci-dessous.
  langpackHashes = {
    "160.0".fr = "sha256-TKoqUbnDgmtlxbTn/GkVGE4axcfEZ/lXFellFaF0QeY=";
  };

  langpack =
    lang:
    pkgs.fetchurl {
      name = "firefox-${version}-langpack-${lang}.xpi";
      url = "https://releases.mozilla.org/pub/firefox/releases/${version}/linux-x86_64/xpi/${lang}.xpi";
      hash = langpackHashes.${version}.${lang};
    };
in
{
  assertions = [
    {
      assertion = langpackHashes ? ${version};
      message = ''
        modules/firefox.nix : pas de pack de langue pour Firefox ${version}.
        Lancez : nix store prefetch-file https://releases.mozilla.org/pub/firefox/releases/${version}/linux-x86_64/xpi/fr.xpi
        et ajoutez le hash dans langpackHashes.
      '';
    }
  ];

  programs.firefox = {
    enable = true;

    policies = {
      ExtensionSettings."langpack-fr@firefox.mozilla.org" = {
        installation_mode = "force_installed";
        install_url = "file://${langpack "fr"}";
      };

      # Pas d'onglets de bienvenue, de note de confidentialité ni de
      # télémétrie à chaque démarrage.
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
      # Langue de l'interface = langue du système (choisie au démarrage).
      "intl.locale.requested" = "";
      # Onglet « Privacy Notice » / « Note sur la confidentialité ».
      "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
      "datareporting.policy.firstRunURL" = "";
    };
  };
}
