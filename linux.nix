{
  final,
  prev,
  inputs,
}:
let
  kernel_7_1 = prev.callPackage "${inputs.nvmd-rpi}/pkgs/linux-rpi/package.nix" {
    rpiModel = "4";
    modDirVersion = "7.1.4";
    tag = "rpi-7.1.y";
    srcHash = "sha256-g/FTvTi4AT2aQgpebUbrt5X+c2ntwQhjc/5k3Fe1kGk=";
  };
in
{
  linuxPackages_rpi_7_1 = prev.linuxPackagesFor kernel_7_1;
}
