{
  final,
  prev,
  inputs,
  versions,
}:
let
  models = [
    "4"
    "5"
  ];
  kernelVersion = versions.kernel;
  mkLinuxPackages =
    rpiModel:
    prev.linuxPackagesFor (
      prev.callPackage "${inputs.nixos-raspberrypi}/pkgs/linux-rpi/package.nix" {
        inherit rpiModel;
        autoModules = false;
        modDirVersion = kernelVersion.modDirVersion;
        tag = kernelVersion.tag;
        srcHash = kernelVersion.srcHash;
        structuredExtraConfig =
          with prev.lib;
          with prev.lib.kernel;
          {
            # Subsystem Stripping (Cameras, Sound, Pi HATs, Sensors, 3D)
            MEDIA_SUPPORT = mkForce no;
            SOUND = mkForce no;
            SND = mkForce no;
            IIO = mkForce no;
            FB_TFT = mkForce no;
            INPUT_TOUCHSCREEN = mkForce no;
            INPUT_JOYSTICK = mkForce no;
            DRM_V3D = mkForce no;

            # Server Optimizations
            PREEMPT_NONE = mkForce yes;
            HZ_250 = mkForce yes;
            TCP_CONG_BBR = mkForce yes;
            DEFAULT_BBR = mkForce yes;
            SUSPEND = mkForce no;
            HIBERNATION = mkForce no;

            # NixOS Initrd & Essential Core Drivers
            BLK_DEV_INITRD = mkForce yes;
            DEVTMPFS = mkForce yes;
            DEVTMPFS_MOUNT = mkForce yes;
            RD_GZIP = mkForce yes;
            RD_XZ = mkForce yes;
            RD_ZSTD = mkForce yes;
            EXT4_FS = mkForce yes;
            BTRFS_FS = mkForce module;
            OVERLAY_FS = mkForce module;
            BLK_DEV_NVME = mkForce yes;
            BLK_DEV_SD = mkForce yes;
            USB_STORAGE = mkForce yes;
            USB_XHCI_HCD = mkForce yes;
            USB_HID = mkForce yes;
            HID_GENERIC = mkForce yes;
            PCIE_BRCMSTB = mkForce yes;
            RESET_RASPBERRYPI = mkForce yes;
          };
      }
    );
in
let
  pkgAttrSet = prev.lib.listToAttrs (
    map (model: {
      name = "linuxPackages_rpi${model}_7_2";
      value = mkLinuxPackages model;
    }) models
  );
in
pkgAttrSet
// {
  kernel-rpi4 = pkgAttrSet.linuxPackages_rpi4_7_2.kernel;
  cpupower-rpi4 = pkgAttrSet.linuxPackages_rpi4_7_2.cpupower;
  kernel-rpi5 = pkgAttrSet.linuxPackages_rpi5_7_2.kernel;
  cpupower-rpi5 = pkgAttrSet.linuxPackages_rpi5_7_2.cpupower;
}
