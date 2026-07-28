{
  final,
  prev,
  inputs,
}:
let
  sys = prev.stdenv.hostPlatform.system;
in
{
  cf = inputs.cf.packages.${sys}.default;
  void = inputs.void.packages.${sys}.default;

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
