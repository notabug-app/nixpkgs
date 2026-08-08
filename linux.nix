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
        modDirVersion = "7.1.6";
        tag = "517926071b31dc2e8e8603fd6de7115f95f50910";
        srcHash = "sha256-hcPCko+PuTxXIUH4JKfGm1Fad26jpDznnedGE5q2VD4=";
      }
    );
in
prev.lib.listToAttrs (
  map (model: {
    name = "linuxPackages_rpi${model}_7_1";
    value = mkLinuxPackages model;
  }) models
)
