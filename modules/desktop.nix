# Bureau XFCE avec connexion automatique et fond d'écran EPIVÍOSI.
{ config, lib, pkgs, ... }:
let
  user = config.epiviosi.user;

  wallpaper = "${pkgs.epiviosi-artwork}/wallpaper.png";

  # xfdesktop (4.20) n'enregistre aucune propriété de fond d'écran tant que
  # l'utilisateur n'en a pas choisi : on les crée pour chaque écran détecté,
  # une fois xfdesktop lancé (il applique alors le changement immédiatement).
  setWallpaper = pkgs.writeShellScript "epiviosi-set-wallpaper" ''
    PATH=${lib.makeBinPath [ pkgs.xfconf pkgs.xrandr pkgs.procps pkgs.coreutils pkgs.gnused pkgs.util-linux ]}
    for _ in $(seq 30); do
      pgrep -u "$(id -u)" -x xfdesktop >/dev/null && break
      sleep 1
    done
    sleep 1
    for monitor in $(xrandr --listmonitors | sed 1d | rev | cut -d' ' -f1 | rev); do
      xfconf-query -c xfce4-desktop -n -t string \
        -p "/backdrop/screen0/monitor$monitor/workspace0/last-image" -s ${wallpaper}
    done
  '';
in
{
  services.xserver.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.displayManager.lightdm.enable = true;

  services.displayManager.defaultSession = "xfce";
  services.displayManager.autoLogin = {
    enable = true;
    user = lib.mkForce user;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  environment.etc."xdg/autostart/epiviosi-wallpaper.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=EPIVÍOSI wallpaper
    Exec=${setWallpaper}
    OnlyShowIn=XFCE;
    NoDisplay=true
  '';

  environment.etc."epiviosi/wallpaper.png".source = wallpaper;
  environment.etc."epiviosi/logo.svg".source = "${pkgs.epiviosi-artwork}/logo.svg";
}
