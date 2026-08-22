{ pkgs }:

pkgs.writeShellApplication {
  name = "update-vaultwarden";
  runtimeInputs = with pkgs; [
    gh
    jq
    nix
    git
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

    if [ "$VW_VERSION" == "$CURRENT_VW" ] && [ "$WEB_TAG" == "$CURRENT_WEB" ]; then
        exit 0
    fi

    VW_HASH=$(nix-prefetch-url --unpack "https://github.com/dani-garcia/vaultwarden/archive/refs/tags/''${VW_TAG}.tar.gz")
    WEB_HASH=$(nix-prefetch-url --unpack "https://github.com/dani-garcia/bw_web_builds/releases/download/''${WEB_TAG}/bw_web_''${WEB_TAG}.tar.gz")

    jq \
      --arg vw_ver "$VW_VERSION" \
      --arg vw_hash "$VW_HASH" \
      --arg web_ver "$WEB_TAG" \
      --arg web_hash "$WEB_HASH" \
      '.vaultwarden.version = $vw_ver | .vaultwarden.hash = $vw_hash | .webvault.version = $web_ver | .webvault.hash = $web_hash' \
      versions.json > versions.json.tmp && mv versions.json.tmp versions.json

    echo "vaultwarden: $VW_VERSION" >> .update-messages

    if [ "$NO_COMMIT" -eq 1 ]; then
        exit 0
    fi

    git add versions.json
    if ! git diff --cached --quiet; then
        git commit -m "chore(vaultwarden): update to $VW_VERSION"
        echo "Changes committed!"
    else
        echo "No changes to commit."
    fi
  '';
}
