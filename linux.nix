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
            DRM_I915 = mkForce no;
            DRM_AMDGPU = mkForce no;
            DRM_RADEON = mkForce no;
            DRM_NOUVEAU = mkForce no;
          };
        kernelPatches = [
          {
            name = "fix-intel-display";
            patch = ./fix-intel-display.patch;
          }
        ];
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
