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
        modDirVersion = "7.2.0-rc6";
        tag = "54daaf9cdeb02074217707551beb705f6f8d4c4c";
        srcHash = "sha256-AFwVOAhAWy9aVpCblbQTFfDeza8AAf/17G333AF4cmE=";
      }
    );
in
prev.lib.listToAttrs (
  map (model: {
    name = "linuxPackages_rpi${model}_7_2";
    value = mkLinuxPackages model;
  }) models
)
