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
        modDirVersion = "7.1.4";
        tag = "rpi-7.1.y";
        srcHash = "sha256-g/FTvTi4AT2aQgpebUbrt5X+c2ntwQhjc/5k3Fe1kGk=";
      }
    );
in
prev.lib.listToAttrs (
  map (model: {
    name = "linuxPackages_rpi${model}_7_1";
    value = mkLinuxPackages model;
  }) models
)
