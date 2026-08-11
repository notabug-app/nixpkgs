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
        modDirVersion = "7.1.8";
        tag = "db6416f1b6285aca5374ce23ed3b2fb07bf7529e";
        srcHash = "sha256-jtenX9rfhW/TYp6JYNttEUROvtz/suxb2xLYdQxCIRo=";
      }
    );
in
prev.lib.listToAttrs (
  map (model: {
    name = "linuxPackages_rpi${model}_7_1";
    value = mkLinuxPackages model;
  }) models
)
