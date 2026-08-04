{ pkgs }:

pkgs.writeShellApplication {
  name = "commit-update";
  runtimeInputs = with pkgs; [ git ];
  text = ''
    set -euo pipefail
    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git add flake.lock flake.nix pkgs.nix
    git commit -m "chore: update flake and vaultwarden" || echo "No changes to commit"
    git push
  '';
}
