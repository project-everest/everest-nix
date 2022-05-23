{modulesPath, ...}: {
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "sd_mod" "sr_mod" ];

  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  boot.loader.grub = { device = "/dev/sda"; };
}
