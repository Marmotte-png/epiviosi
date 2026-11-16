# Images EPIVÍOSI rendues depuis les SVG de ./assets.
{
  runCommand,
  librsvg,
  imagemagick,
  makeFontsConf,
  dejavu_fonts,
  nixos-grub2-theme,
}:
let
  assets = ../../assets;
in
runCommand "epiviosi-artwork"
  {
    nativeBuildInputs = [
      librsvg
      imagemagick
    ];
    FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ dejavu_fonts ]; };
  }
  ''
    mkdir -p $out
    rsvg-convert -w 1920 -h 1080 ${assets}/wallpaper.svg -o $out/wallpaper.png
    rsvg-convert -w 800 -h 600 ${assets}/boot-bios.svg -o $out/bios-splash.png
    cp ${assets}/logo.svg $out/logo.svg

    # Thème GRUB (UEFI) : celui de NixOS, avec nos couleurs et notre logo.
    cp -r ${nixos-grub2-theme} $out/grub-theme
    chmod -R u+w $out/grub-theme
    rsvg-convert -w 319 -h 100 ${assets}/boot-banner.svg -o $out/grub-theme/logo.png
    # GRUB n'accepte que des PNG en 8 ou 16 bits par canal (pas de palette).
    magick -size 16x16 xc:'#0b1826' -depth 8 PNG24:$out/grub-theme/background.png
    sed -i \
      -e 's/#5579C4/#E8B04B/g' \
      -e 's/#7EBAE4/#1D3B56/g' \
      $out/grub-theme/theme.txt
  ''
