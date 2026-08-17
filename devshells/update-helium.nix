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

    echo "Checking for Helium updates..."

    LATEST_TAG=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases/latest | jq -r '.tag_name')
    VERSION="''${LATEST_TAG#v}"

    if [ -z "$VERSION" ] || [ "$VERSION" == "null" ]; then
        echo "Failed to get latest version."
        exit 1
    fi

    # Clone the helium repository
    TMPDIR=$(mktemp -d)
    git clone git@github.com:s-Sizz/helium.git "$TMPDIR/helium"
    pushd "$TMPDIR/helium"

    CURRENT_VERSION=$(jq -r .version versions.json)
    if [ "$VERSION" == "$CURRENT_VERSION" ]; then
        echo "Helium is already up to date ($VERSION)."
        popd
        rm -rf "$TMPDIR"
        exit 0
    fi

    echo "Updating Helium to version $VERSION"

    echo "Prefetching x86_64 hash..."
    HASH_X86=$(nix-prefetch-url "https://github.com/imputnet/helium-linux/releases/download/''${VERSION}/helium-''${VERSION}-x86_64_linux.tar.xz")

    echo "Prefetching aarch64 hash..."
    HASH_ARM=$(nix-prefetch-url "https://github.com/imputnet/helium-linux/releases/download/''${VERSION}/helium-''${VERSION}-arm64_linux.tar.xz")

    jq \
      --arg v "$VERSION" \
      --arg hx "sha256:$HASH_X86" \
      --arg ha "sha256:$HASH_ARM" \
      '.version = $v | .["x86_64-linux"].hash = $hx | .["aarch64-linux"].hash = $ha' \
      versions.json > versions.json.tmp && mv versions.json.tmp versions.json

    git config user.name "github-actions[bot]"
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    
    git add versions.json
    git commit -m "bump helium to $VERSION"
    git push origin main
    # Not tagging since we just need the commit, but we can tag if wanted:
    # git tag -a "v$VERSION" -m "v$VERSION"
    # git push origin "v$VERSION"

    popd
    rm -rf "$TMPDIR"
    echo "Successfully updated and pushed helium to v$VERSION"
  '';
}
