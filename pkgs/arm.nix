{
  final,
  prev,
  inputs,
}:
let
  sys = prev.stdenv.hostPlatform.system;
in
prev.lib.optionalAttrs (sys == "aarch64-linux") {
  kernel-rpi4 = final.linuxPackages_rpi4_7_1.kernel;
  cpupower-rpi4 = final.linuxPackages_rpi4_7_1.cpupower;
  kernel-rpi5 = final.linuxPackages_rpi5_7_1.kernel;
  cpupower-rpi5 = final.linuxPackages_rpi5_7_1.cpupower;
  libraspberrypi = inputs.nixos-raspberrypi.packages.${sys}.libraspberrypi;
  raspberrypi-utils = inputs.nixos-raspberrypi.packages.${sys}.raspberrypi-utils;

  cf = inputs.cf.packages.${sys}.default;
  void = inputs.void.packages.${sys}.default;

  vaultwarden = (prev.vaultwarden.override { dbBackend = "postgresql"; }).overrideAttrs (old: {
    version = "1.37.1";
    src = inputs.vaultwarden-src;
    cargoDeps = prev.rustPlatform.importCargoLock {
      lockFile = "${inputs.vaultwarden-src}/Cargo.lock";
    };
    cargoHash = "";
    passthru = (old.passthru or { }) // {
      webvault = final.vaultwarden-vault;
    };
  });

  vaultwarden-vault = prev.stdenv.mkDerivation {
    pname = "vaultwarden-vault";
    version = "v2026.6.4";
    src = inputs.webvault-src;
    installPhase = ''
      mkdir -p $out/share/vaultwarden/vault
      cp -r . $out/share/vaultwarden/vault
    '';
  };
}
