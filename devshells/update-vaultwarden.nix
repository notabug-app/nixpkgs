{ pkgs }:

pkgs.writeShellApplication {
  name = "update-vaultwarden";
  runtimeInputs = with pkgs; [
    gh
    jq
    nix
    git
    gawk
    gnugrep
  ];
  text = ''
    set -e

    NO_COMMIT=0
    if [ "''${1:-}" = "--no-commit" ]; then
        NO_COMMIT=1
    fi

    VW_TAG=$(gh api repos/dani-garcia/vaultwarden/releases/latest --jq .tag_name)
    VW_VERSION=''${VW_TAG#v}

    WEB_TAG=$(gh api repos/dani-garcia/bw_web_builds/releases/latest --jq .tag_name)

    CURRENT_VW=$(jq -r .vaultwarden.version versions.json)
    CURRENT_WEB=$(jq -r .webvault.version versions.json)

    if [ "$VW_VERSION" = "$CURRENT_VW" ] && [ "$WEB_TAG" = "$CURRENT_WEB" ]; then
        exit 0
    fi

    VW_PREFETCH=$(nix store prefetch-file --json --name source --unpack "https://github.com/dani-garcia/vaultwarden/archive/refs/tags/''${VW_TAG}.tar.gz")
    VW_HASH=$(echo "$VW_PREFETCH" | jq -r '.hash')

    if [ -z "$VW_HASH" ] || [ "$VW_HASH" = "null" ]; then
        echo "Error calculating vaultwarden hash" >&2
        exit 1
    fi

    WEB_PREFETCH=$(nix store prefetch-file --json --name source --unpack "https://github.com/dani-garcia/bw_web_builds/releases/download/''${WEB_TAG}/bw_web_''${WEB_TAG}.tar.gz")
    WEB_HASH=$(echo "$WEB_PREFETCH" | jq -r '.hash')

    if [ -z "$WEB_HASH" ] || [ "$WEB_HASH" = "null" ]; then
        echo "Error calculating webvault hash" >&2
        exit 1
    fi

    CARGO_HASH=$(nix build --no-link --impure --expr "
      let
        pkgs = import (builtins.getFlake (toString ./.)).inputs.nixpkgs {};
      in
      pkgs.rustPlatform.fetchCargoVendor {
        src = pkgs.fetchFromGitHub {
          owner = \"dani-garcia\";
          repo = \"vaultwarden\";
          tag = \"$VW_TAG\";
          hash = \"$VW_HASH\";
        };
        hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
      }
    " 2>&1 | grep "got:" | head -n1 | awk '{print $2}' || true)

    if [ -z "$CARGO_HASH" ]; then
        echo "Error calculating cargoHash" >&2
        exit 1
    fi

    jq \
      --arg vw_ver "$VW_VERSION" \
      --arg vw_hash "$VW_HASH" \
      --arg vw_cargo "$CARGO_HASH" \
      --arg web_ver "$WEB_TAG" \
      --arg web_hash "$WEB_HASH" \
      '.vaultwarden.version = $vw_ver | .vaultwarden.hash = $vw_hash | .vaultwarden.cargoHash = $vw_cargo | .webvault.version = $web_ver | .webvault.hash = $web_hash' \
      versions.json > versions.json.tmp && mv versions.json.tmp versions.json

    if [ "$VW_VERSION" != "$CURRENT_VW" ]; then
        echo "vaultwarden: $VW_VERSION" >> .update-messages
    fi
    if [ "$WEB_TAG" != "$CURRENT_WEB" ]; then
        echo "webvault: $WEB_TAG" >> .update-messages
    fi

    if [ "$NO_COMMIT" -eq 1 ]; then
        exit 0
    fi

    git add versions.json
    if ! git diff --cached --quiet; then
        if [ "$VW_VERSION" != "$CURRENT_VW" ]; then
            git commit -m "chore(vaultwarden): update to $VW_VERSION"
        else
            git commit -m "chore(webvault): update to $WEB_TAG"
        fi
        echo "Changes committed!"
    else
        echo "No changes to commit."
    fi
  '';
}
