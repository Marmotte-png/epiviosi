# Traduction de pages FR <-> EN dans Firefox, entièrement hors-ligne.
#
# Firefox Translations traduit sur la machine (moteur Bergamot), mais obtient
# la liste des modèles (Remote Settings, collections *-v2) et les modèles eux-
# mêmes depuis les serveurs de Mozilla. Hors-ligne, la traduction est donc
# indisponible. Ici :
#
# 1. les enregistrements FR<->EN et du moteur sont figés dans records.json ;
#    un script autoconfig (privilégié, exécuté au démarrage de Firefox) les
#    importe dans la base Remote Settings du profil s'ils y manquent ;
# 2. les fichiers (≈ 51 Mo, vérifiés par leur empreinte SHA-256) sont inclus
#    dans l'ISO et servis par un petit serveur local sur 127.0.0.1 ;
# 3. services.settings.base_attachments_url pointe vers ce serveur : Firefox
#    réutilise cette valeur sans interroger le serveur Remote Settings.
#
# Firefox vérifie lui-même l'empreinte de chaque fichier téléchargé.
# Mettre à jour records.json : voir README (section Traduction).
{ lib, pkgs, ... }:
let
  data = builtins.fromJSON (builtins.readFile ./records.json);
  records = lib.concatLists (lib.attrValues data.collections);
  port = 8091;

  # Arborescence identique à celle du CDN de Mozilla (attachment.location).
  attachments = pkgs.linkFarm "firefox-translations-attachments" (
    map (r: {
      name = r.attachment.location;
      path = pkgs.fetchurl {
        url = "https://firefox-settings-attachments.cdn.mozilla.net/${r.attachment.location}";
        sha256 = r.attachment.hash;
      };
    }) records
  );

  # Serveur Remote Settings par défaut de Firefox (AppConstants) : la valeur
  # enregistrée n'est réutilisée que si elle commence par cette adresse.
  serverUrl = "https://firefox.settings.services.mozilla.com/v2";
in
{
  systemd.services.epiviosi-firefox-translations = {
    description = "Modèles de traduction Firefox hors-ligne (EPIVÍOSI)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.darkhttpd} ${attachments} --addr 127.0.0.1 --port ${toString port} --no-listing --no-server-id";
      DynamicUser = true;
      Restart = "on-failure";
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
    };
  };

  programs.firefox.autoConfig = ''
    // EPIVÍOSI : traduction FR <-> EN hors-ligne (modules/firefox-translations).
    try {
      defaultPref("services.settings.base_attachments_url",
                  "${serverUrl}|http://127.0.0.1:${toString port}/");
      const epiviosiTranslations = ${builtins.toJSON {
        inherit (data) timestamp collections;
      }};
      Services.obs.addObserver(function epiviosiImport(subject, topic) {
        Services.obs.removeObserver(epiviosiImport, topic);
        (async () => {
          const { RemoteSettings } = ChromeUtils.importESModule(
            "resource://services-settings/remote-settings.sys.mjs");
          for (const [name, recs] of Object.entries(epiviosiTranslations.collections)) {
            const client = RemoteSettings(name);
            const last = await client.db.getLastModified();
            if (last && last >= epiviosiTranslations.timestamp) {
              continue;
            }
            await client.db.importChanges({}, epiviosiTranslations.timestamp, recs, { clear: true });
          }
          Services.obs.notifyObservers(null, "epiviosi-translations-imported");
        })().catch(e => Cu.reportError("EPIVÍOSI translations: " + e));
      }, "final-ui-startup");
    } catch (e) {
      Components.utils.reportError("EPIVÍOSI translations: " + e);
    }
  '';
}
