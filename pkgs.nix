{
  final,
  prev,
  inputs,
}:
let
  sys = prev.stdenv.hostPlatform.system;
in
{
  cf-ddns = inputs.cf-ddns.packages.${sys}.default;
  dnsr = inputs.dnsr.packages.${sys}.default;
  sysmon = inputs.rpi-vcio.packages.${sys}.default;
  rpi-vcio = inputs.rpi-vcio.packages.${sys}.default;

  vaultwarden = prev.vaultwarden.overrideAttrs (old: {
    version = "1.37.0";
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
