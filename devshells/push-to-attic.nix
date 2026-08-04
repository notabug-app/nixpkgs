{ pkgs }:

pkgs.writeShellApplication {
  name = "push-to-attic";
  runtimeInputs = with pkgs; [
    nix
    jq
    gnugrep
    coreutils
    attic-client
  ];
  text = ''
    set -euo pipefail

    if [ "$#" -ne 1 ]; then
        echo "Usage: push-to-attic <cache-name>"
        exit 1
    fi

    CACHE=$1

    if [ -n "''${ATTIC_URL:-}" ] && [ -n "''${ATTIC_SECRET:-}" ]; then
      echo "Authenticating with Attic..."
      attic login default "$ATTIC_URL" "$ATTIC_SECRET" --set-default
    fi

    nix path-info --all > /tmp/store-paths-after
    comm -13 <(sort /tmp/store-paths-before) <(sort /tmp/store-paths-after) > /tmp/store-paths-new
    
    # Only push paths built locally (no signatures from binary caches)
    if [ -s /tmp/store-paths-new ]; then
      # shellcheck disable=SC2046
      nix path-info --json $(cat /tmp/store-paths-new) | \
        jq -r 'to_entries[] | select(.value.signatures == null or (.value.signatures | length == 0)) | .key' | \
        grep -v '\.drv$' > /tmp/store-paths-to-push || true
    else
      touch /tmp/store-paths-to-push
    fi
    
    if [ -s /tmp/store-paths-to-push ]; then
      echo "Pushing $(wc -l < /tmp/store-paths-to-push) paths..."
      for i in {1..5}; do
        if attic push --stdin "$CACHE" < /tmp/store-paths-to-push; then
          echo "Push successful!"
          exit 0
        fi
        echo "Push failed, retrying in 5 seconds... ($i/5)"
        sleep 5
      done
      echo "Failed to push after 5 attempts."
      exit 1
    else
      echo "No new paths to push."
    fi
  '';
}
