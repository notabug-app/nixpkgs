{
  final,
  prev,
  inputs,
  versions,
}:
let
  sys = prev.stdenv.hostPlatform.system;
in
prev.lib.optionalAttrs (sys == "aarch64-linux") {
  libraspberrypi = inputs.nixos-raspberrypi.packages.${sys}.libraspberrypi;
  raspberrypi-utils = inputs.nixos-raspberrypi.packages.${sys}.raspberrypi-utils;

  cf = inputs.cf.packages.${sys}.default;
  void = inputs.void.packages.${sys}.default;

  vaultwarden =
    let
      vw = versions.vaultwarden;
      vw_src = builtins.fetchTarball {
        url = "https://github.com/dani-garcia/vaultwarden/archive/refs/tags/${vw.version}.tar.gz";
        sha256 = vw.hash;
      };
    in
    (prev.vaultwarden.override { dbBackend = "postgresql"; }).overrideAttrs (old: {
      version = vw.version;
      src = vw_src;
      cargoDeps = prev.rustPlatform.importCargoLock {
        lockFile = "${vw_src}/Cargo.lock";
      };
      cargoHash = "";
      passthru = (old.passthru or { }) // {
        webvault = final.vaultwarden-vault;
      };
    });

  vaultwarden-vault =
    let
      wv = versions.webvault;
    in
    prev.stdenv.mkDerivation {
      pname = "vaultwarden-vault";
      version = wv.version;
      src = builtins.fetchTarball {
        url = "https://github.com/dani-garcia/bw_web_builds/releases/download/${wv.version}/bw_web_${wv.version}.tar.gz";
        sha256 = wv.hash;
      };
      installPhase = ''
        mkdir -p $out/share/vaultwarden/vault
        cp -r . $out/share/vaultwarden/vault
      '';
    };
}
