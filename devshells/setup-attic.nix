{ pkgs }:

pkgs.writeShellApplication {
  name = "setup-attic";
  runtimeInputs = with pkgs; [ attic-client ];
  text = ''
    set -euo pipefail

    if [ "$#" -ne 1 ]; then
        echo "Usage: setup-attic <cache-name>"
        exit 1
    fi
    CACHE=$1

    if [ -n "''${ATTIC_URL:-}" ] && [ -n "''${ATTIC_SECRET:-}" ]; then
      echo "Authenticating with Attic..."
      attic login default "$ATTIC_URL" "$ATTIC_SECRET" --set-default
      echo "Configuring Nix to use Attic cache..."
      attic use "$CACHE"
    else
      echo "No ATTIC_URL or ATTIC_SECRET provided, skipping setup."
    fi
  '';
}
