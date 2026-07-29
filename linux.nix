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
        modDirVersion = "7.1.5";
        tag = "183b5f6ee2119b0ef214f6c2a00876b84b866d93";
        srcHash = "sha256-OYp/cLv7ogxBxvEjpZOaCq+WP9bYyI7t7auD3NE9vVE=";
      }
    );
in
prev.lib.listToAttrs (
  map (model: {
    name = "linuxPackages_rpi${model}_7_1";
    value = mkLinuxPackages model;
  }) models
)
