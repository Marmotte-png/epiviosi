# Préparation d'une clé USB comme le ferait l'utilisateur : l'ISO EPIVÍOSI
# copiée sur un disque (table MBR hybride : système + EFI, la partition
# système commençant au secteur 0), puis le wiki et la persistance. Vérifie
# les partitions 3 et 4 (une table MBR n'en accepte que 4), que les
# partitions de démarrage sont intactes, qu'une relance ne modifie rien, et
# que le mauvais ordre (persistance d'abord) échoue proprement.
{
  pkgs,
  iso,
  tools,
}:
pkgs.testers.runNixOSTest {
  name = "epiviosi-cle-usb";

  nodes.machine = {
    virtualisation.emptyDiskImages = [
      4096
      4096
    ];
    virtualisation.memorySize = 1536;
    environment.systemPackages = tools;
  };

  testScript = ''
    iso = "${iso}"
    machine.wait_for_unit("multi-user.target")

    with subtest("copie de l'ISO sur deux « clés »"):
        print(machine.succeed(f"stat -L -c '%s' {iso}; blockdev --getsize64 /dev/vdb /dev/vdc"))
        machine.succeed(f"dd if={iso} of=/dev/vdb bs=4M conv=fsync status=none")
        # Second disque (test du mauvais ordre) : seule la table de partitions
        # compte, le début de l'image suffit.
        machine.succeed(f"dd if={iso} of=/dev/vdc bs=4M count=1 conv=fsync status=none")
        for d in ["vdb", "vdc"]:
            machine.succeed(f"partx -u /dev/{d} || true")
        machine.succeed("udevadm settle")
        avant = machine.succeed("sfdisk -d /dev/vdb | grep -E '^/dev/vdb[12] '")
        machine.succeed("blkid -p -s PTTYPE -o value /dev/vdb | grep -qx dos")

    def etat(titre):
        print("=== " + titre)
        print(machine.execute("sfdisk -d /dev/vdb; od -A d -t x1 -j 440 -N 72 /dev/vdb; cat /proc/partitions | grep vdb")[1])

    with subtest("wiki puis persistance"):
        etat("avant")
        machine.succeed("echo OUI | epiviosi-wiki-setup --size 400M /dev/vdb")
        etat("après wiki")
        rc, out = machine.execute("echo OUI | epiviosi-persist-setup /dev/vdb 2>&1")
        etat("après persistance")
        assert rc == 0, out
        machine.succeed("udevadm settle")

    with subtest("partitions, étiquettes et systèmes de fichiers"):
        attendu = {"EPIV-WIKI": ("/dev/vdb3", "exfat"),
                   "EPIVIOSI-DATA": ("/dev/vdb4", "ext4")}
        for label, (dev, fs) in attendu.items():
            vrai = machine.succeed(f"blkid -L {label}").strip()
            assert vrai == dev, f"{label}: {vrai} au lieu de {dev}"
            machine.succeed(f"blkid -p -s TYPE -o value {dev} | grep -qx {fs}")
        print(machine.succeed("sfdisk -l /dev/vdb"))

    with subtest("relancer un outil ne modifie rien"):
        table = machine.succeed("sfdisk -d /dev/vdb")
        out = machine.succeed("echo OUI | epiviosi-wiki-setup --size 100M /dev/vdb 2>&1")
        assert "existe déjà" in out, out
        out = machine.succeed("echo OUI | epiviosi-persist-setup /dev/vdb 2>&1")
        assert "existe déjà" in out, out
        assert machine.succeed("sfdisk -d /dev/vdb") == table

    with subtest("partitions de démarrage intactes"):
        apres = machine.succeed("sfdisk -d /dev/vdb | grep -E '^/dev/vdb[12] '")
        assert avant == apres, (avant, apres)
        machine.succeed("blkid -p -s TYPE -o value /dev/vdb1 | grep -qx iso9660")
        machine.succeed("mkdir -p /mnt/iso && mount -o ro /dev/vdb1 /mnt/iso && test -f /mnt/iso/nix-store.squashfs && umount /mnt/iso")

    with subtest("partitions utilisables"):
        machine.succeed("mkdir -p /mnt/w /mnt/p && mount /dev/vdb3 /mnt/w && echo ok > /mnt/w/t && umount /mnt/w")
        machine.succeed("mount /dev/vdb4 /mnt/p && echo ok > /mnt/p/t && umount /mnt/p")

    with subtest("mauvais ordre : persistance d'abord, puis le wiki échoue proprement"):
        # Les outils cherchent leur étiquette sur toute la machine : on retire
        # celles de la première clé.
        machine.succeed("wipefs -q -a /dev/vdb3 /dev/vdb4 && udevadm settle")
        machine.succeed("echo OUI | epiviosi-persist-setup /dev/vdc")
        out = machine.fail("echo OUI | epiviosi-wiki-setup --size 400M /dev/vdc 2>&1")
        assert "Erreur" in out, out
        print(out)
        machine.succeed("sfdisk -d /dev/vdc | grep -E '^/dev/vdc1 '")
  '';
}
