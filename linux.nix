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
        tag = "79f8b2304b796b42fa786e7f474650c9e35bd538";
        srcHash = "sha256-v5/IyuFmsvzSOPF2x2PfR0suaX9YpzsTIKTsaLrmPGY=";
      }
    );
in
prev.lib.listToAttrs (
  map (model: {
    name = "linuxPackages_rpi${model}_7_1";
    value = mkLinuxPackages model;
  }) models
)
