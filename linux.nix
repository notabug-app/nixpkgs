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
        modDirVersion = kernelVersion.modDirVersion;
        tag = kernelVersion.tag;
        srcHash = kernelVersion.srcHash;
        structuredExtraConfig =
          with prev.lib;
          with prev.lib.kernel;
          let
            disabledModules = import ./disabled-modules.nix;
            disabledConfig = genAttrs disabledModules (name: mkForce no);
          in
          disabledConfig
          // {
            # Server Optimizations (Explicitly enabled)
            PREEMPT_NONE = mkForce yes;
            HZ_250 = mkForce yes;
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
