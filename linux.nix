{
  final,
  prev,
  inputs,
}:
let
  models = [
    "02"
    "3"
    "4"
    "5"
  ];
  mkLinuxPackages =
    rpiModel:
    prev.linuxPackagesFor (
      prev.callPackage "${inputs.nvmd-rpi}/pkgs/linux-rpi/package.nix" {
        inherit rpiModel;
        modDirVersion = "7.2.0-rc5";
        tag = "40608a2182511a06de4cae92c6290199ffd3fbfd";
        srcHash = "sha256-Dtab1vlX/2xoVmY47klVfBH/DILSHngmqNnouJ1tvss=";
      }
    );
in
prev.lib.listToAttrs (
  map (model: {
    name = "linuxPackages_rpi${model}_7_2";
    value = mkLinuxPackages model;
  }) models
)
