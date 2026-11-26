# Options communes à la suite EPIVÍOSI.
# Les dépôts epiviosi-{wiki,medic,maps,security,news} fourniront chacun un
# `nixosModules.default` qui implémentera l'option correspondante.
{ lib, ... }:
{
  options.epiviosi = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "epiviosi";
      description = "Utilisateur principal de la session live.";
    };
    wiki.enable = lib.mkEnableOption "EPIVÍOSI WIKI (archives Wikipédia FR/EN via Kiwix)";
    medic.enable = lib.mkEnableOption "EPIVÍOSI MEDIC (dossiers médicaux et premiers secours)";
    maps.enable = lib.mkEnableOption "EPIVÍOSI MAPS (cartes OpenStreetMap hors-ligne)";
    security.enable = lib.mkEnableOption "EPIVÍOSI SECURITY (cybersécurité et cryptographie)";
    news.enable = lib.mkEnableOption "EPIVÍOSI NEWS (rédaction chiffrée pour journalistes)";
  };
}
