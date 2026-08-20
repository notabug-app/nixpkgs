{
  final,
  prev,
  inputs,
}:
let
  models = [
    "4"
    "5"
  ];
  mkLinuxPackages =
    rpiModel:
    prev.linuxPackagesFor (
      prev.callPackage "${inputs.nixos-raspberrypi}/pkgs/linux-rpi/package.nix" {
        inherit rpiModel;
        modDirVersion = "7.2.0";
        tag = "48599d5d6403fd9680b2f5582a7b7b17a0c9d018";
        srcHash = "sha256-rBR1UMSicc7QyRcaBK9i5jqt1/EgorpWaBWeTJYfcY8=";
        structuredExtraConfig =
          with prev.lib;
          with prev.lib.kernel;
          {
            # x86/other GPUs
            DRM_I915 = mkForce no;
            DRM_XE = mkForce no;
            DRM_AMDGPU = mkForce no;
            DRM_RADEON = mkForce no;
            DRM_NOUVEAU = mkForce no;
            
            # Non-Pi ARM GPUs
            DRM_PANFROST = mkForce no;
            DRM_LIMA = mkForce no;
            DRM_MSM = mkForce no;
            DRM_ROCKCHIP = mkForce no;
            DRM_SUN4I = mkForce no;
            DRM_ETNAVIV = mkForce no;
            DRM_TEGRA = mkForce no;
            DRM_MESON = mkForce no;
            DRM_EXYNOS = mkForce no;
            DRM_MEDIATEK = mkForce no;

            # 3D acceleration (keep vc4 for display, drop v3d)
            DRM_V3D = mkForce no;

            # Audio/Media
            SOUND = mkForce no;
            SND = mkForce no;
            MEDIA_SUPPORT = mkForce no;

            # Unneeded Input
            INPUT_JOYSTICK = mkForce no;
            INPUT_TOUCHSCREEN = mkForce no;

            # Unneeded Network/WiFi vendors (Pi uses Broadcom)
            NET_VENDOR_INTEL = mkForce no;
            NET_VENDOR_REALTEK = mkForce no;
            NET_VENDOR_AMD = mkForce no;
            NET_VENDOR_MELLANOX = mkForce no;
            NET_VENDOR_MARVELL = mkForce no;
            NET_VENDOR_ALTEON = mkForce no;
            NET_VENDOR_AMAZON = mkForce no;
            NET_VENDOR_CHELSIO = mkForce no;
            NET_VENDOR_CISCO = mkForce no;
            NET_VENDOR_DEC = mkForce no;
            NET_VENDOR_GOOGLE = mkForce no;
            NET_VENDOR_HP = mkForce no;
            NET_VENDOR_NI = mkForce no;
            NET_VENDOR_NVIDIA = mkForce no;
            NET_VENDOR_QLOGIC = mkForce no;
            NET_VENDOR_SUN = mkForce no;
            NET_VENDOR_NATSEMI = mkForce no;
            NET_VENDOR_NETRONOME = mkForce no;
            NET_VENDOR_8390 = mkForce no;
            NET_VENDOR_OKI = mkForce no;
            NET_VENDOR_PENSANDO = mkForce no;
            ETHOC = mkForce no;
            WLAN_VENDOR_INTEL = mkForce no;
            WLAN_VENDOR_MEDIATEK = mkForce no;
            WLAN_VENDOR_RALINK = mkForce no;
            WLAN_VENDOR_REALTEK = mkForce no;
            WLAN_VENDOR_ATH = mkForce no;
            WLAN_VENDOR_ATMEL = mkForce no;
            WLAN_VENDOR_CISCO = mkForce no;
            WLAN_VENDOR_MARVELL = mkForce no;

            # Ancient / Exotic Filesystems
            JFS_FS = mkForce no;
            REISERFS_FS = mkForce no;
            OCFS2_FS = mkForce no;
            GFS2_FS = mkForce no;
            MINIX_FS = mkForce no;
            ROMFS_FS = mkForce no;

            # Obsolete / Enterprise / Niche
            MACINTOSH_DRIVERS = mkForce no;
            ISA = mkForce no;
            EISA = mkForce no;
            MCA = mkForce no;
            ATM = mkForce no;
            FDDI = mkForce no;
            HIPPI = mkForce no;
            INPUT_TABLET = mkForce no;
            INPUT_MISC = mkForce no;
            HAMRADIO = mkForce no;
            CAN = mkForce no;
            PCCARD = mkForce no;
            INFINIBAND = mkForce no;
            SCSI_LOWLEVEL = mkForce no;
            CHROME_PLATFORMS = mkForce no;
            ACCESSIBILITY = mkForce no;
            CDROM = mkForce no;

            # Debug
            DEBUG_INFO = mkForce no;
            DEBUG_KERNEL = mkForce no;

            # Server Optimizations
            # Maximize throughput over latency
            PREEMPT = mkForce no;
            PREEMPT_VOLUNTARY = mkForce no;
            PREEMPT_NONE = mkForce yes;

            # Lower timer frequency (less interrupt overhead)
            HZ_1000 = mkForce no;
            HZ_250 = mkForce yes;

            # Disable sleep/hibernate (it's a server)
            SUSPEND = mkForce no;
            HIBERNATION = mkForce no;

            # Better network congestion control
            TCP_CONG_BBR = mkForce yes;
            DEFAULT_BBR = mkForce yes;
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
