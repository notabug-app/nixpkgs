{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "rustdoc-text";
  version = "0.3.3";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-xsGpGb+tp8mNXvMvI/2XbC1G9rJ+wE83AZpK6j/2BU8=";
  };

  cargoHash = "sha256-ydPRMI0t3xeC55IrAADfIMxuTMOGfwtHgdd4VwbrJ00=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  doCheck = false;

  meta = with lib; {
    description = "View Rust documentation as plain Markdown in your terminal";
    homepage = "https://github.com/lmmx/rustdoc-text";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "rustdoc-text";
  };
}
