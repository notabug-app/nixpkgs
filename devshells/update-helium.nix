{ pkgs }:

pkgs.writeShellApplication {
  name = "update-helium";
  runtimeInputs = with pkgs; [
    curl
    jq
    git
    nix
  ];
  text = ''
    set -euo pipefail

    NO_COMMIT=0
    if [ "''${1:-}" = "--no-commit" ]; then
        NO_COMMIT=1
    fi

    LATEST_TAG=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest | jq -r '.tag_name')
    VERSION="''${LATEST_TAG#v}"

    if [ -z "$VERSION" ] || [ "$VERSION" == "null" ]; then
        echo "Failed to get latest version." >&2
        exit 1
    fi

    CURRENT_VERSION=$(jq -r .helium.version versions.json)
    if [ "$VERSION" == "$CURRENT_VERSION" ]; then
        exit 0
    fi

    HASH_X86=$(nix-prefetch-url "https://github.com/imputnet/helium-linux/releases/download/''${VERSION}/helium-''${VERSION}-x86_64_linux.tar.xz")
    HASH_ARM=$(nix-prefetch-url "https://github.com/imputnet/helium-linux/releases/download/''${VERSION}/helium-''${VERSION}-arm64_linux.tar.xz")

    jq \
      --arg v "$VERSION" \
      --arg hx "sha256:$HASH_X86" \
      --arg ha "sha256:$HASH_ARM" \
      '.helium.version = $v | .helium["x86_64-linux"].hash = $hx | .helium["aarch64-linux"].hash = $ha' \
      versions.json > versions.json.tmp && mv versions.json.tmp versions.json

    echo "helium: $VERSION" >> .update-messages

    if [ "$NO_COMMIT" -eq 1 ]; then
        exit 0
    fi

    git add versions.json
    if ! git diff --cached --quiet; then
        git commit -m "chore(helium): bump to $VERSION"
        echo "Changes committed!"
    else
        echo "No changes to commit."
    fi
  '';
}
