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

  sparkyfitness-server = inputs.sparkyfitness.packages.${sys}.sparkyfitness-server;
  sparkyfitness-frontend = inputs.sparkyfitness.packages.${sys}.sparkyfitness-frontend;

  vaultwarden =
    let
      vw = versions.vaultwarden;
    in
    (prev.vaultwarden.override { dbBackend = "postgresql"; }).overrideAttrs (old: {
      version = vw.version;
      src = final.fetchFromGitHub {
        owner = "dani-garcia";
        repo = "vaultwarden";
        tag = vw.version;
        hash = vw.hash;
      };
      cargoDeps = null;
      cargoHash = vw.cargoHash;
      passthru = (old.passthru or { }) // {
        webvault = final.vaultwarden-vault;
      };
    });

  vaultwarden-vault =
    let
      wv = versions.webvault;
    in
    final.stdenv.mkDerivation {
      pname = "vaultwarden-vault";
      version = wv.version;
      src = final.fetchzip {
        url = "https://github.com/dani-garcia/bw_web_builds/releases/download/${wv.version}/bw_web_${wv.version}.tar.gz";
        sha256 = wv.hash;
      };
      installPhase = ''
        mkdir -p $out/share/vaultwarden/vault
        cp -r . $out/share/vaultwarden/vault
      '';
    };
}
