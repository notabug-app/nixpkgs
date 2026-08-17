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
    # shellcheck disable=SC2016
    PKGS=$(nix eval --json .#packages --apply 'packages: builtins.concatLists (map (system: let os = if system == "aarch64-linux" then "ubuntu-24.04-arm" else "ubuntu-24.04"; allPkgs = builtins.filter (p: p != "firn") (builtins.attrNames packages.''${system}); isKernel = p: builtins.match ".*kernel.*" p != null; kernels = builtins.filter isKernel allPkgs; others = builtins.filter (p: ! (isKernel p)) allPkgs; in map (package: { inherit system package os; }) (kernels ++ others)) [ "aarch64-linux" "x86_64-linux" ])')
    echo "matrix={\"include\":$PKGS}" >> "$GITHUB_OUTPUT"
  '';
}
