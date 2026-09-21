{
  lib,
  rustPlatform,
  fetchCrate,
}:

rustPlatform.buildRustPackage rec {
  pname = "rusty-man";
  version = "0.5.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-gDiGvuBCLuxHrV3X0GdvmEgrknrzgezT8sfmHBQrJSA=";
  };

  cargoHash = "sha256-ZIRwp5AJugMDxg3DyFIH5VlD0m4Si2tJdspKE5QEB4M=";

  env.NIX_CFLAGS_COMPILE = "-std=gnu99 -Wno-error=incompatible-pointer-types";

  meta = with lib; {
    description = "Command-line viewer for rustdoc documentation";
    homepage = "https://git.sr.ht/~ireas/rusty-man";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "rusty-man";
  };
}
