{
  writeShellApplication,
  util-linux,
  gptfdisk,
  e2fsprogs,
  gawk,
  gnugrep,
  gnused,
  coreutils,
  systemd,
}:
writeShellApplication {
  name = "epiviosi-persist-setup";
  runtimeInputs = [
    util-linux
    gptfdisk
    e2fsprogs
    gawk
    gnugrep
    gnused
    coreutils
    systemd
  ];
  text = builtins.readFile ./epiviosi-persist-setup.sh;
}
