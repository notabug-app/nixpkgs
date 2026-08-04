{ pkgs }:

pkgs.writeShellApplication {
  name = "record-store-paths";
  runtimeInputs = with pkgs; [ nix ];
  text = ''
    set -euo pipefail
    nix path-info --all > /tmp/store-paths-before
  '';
}
