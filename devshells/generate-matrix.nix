{ pkgs }:

pkgs.writeShellApplication {
  name = "generate-matrix";
  runtimeInputs = with pkgs; [ nix ];
  text = ''
    set -euo pipefail
    if [ -z "''${GITHUB_OUTPUT:-}" ]; then
      echo "GITHUB_OUTPUT is not set!"
      exit 1
    fi
    PKGS=$(nix eval --json .#packages.aarch64-linux --apply 'builtins.attrNames')
    echo "matrix=$PKGS" >> "$GITHUB_OUTPUT"
  '';
}
