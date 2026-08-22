{ pkgs }:

pkgs.writeShellApplication {
  name = "update-kernel";
  runtimeInputs = with pkgs; [
    git
    curl
    jq
  ];
  text = ''
    set -euo pipefail

    NO_COMMIT=0
    if [ "''${1:-}" = "--no-commit" ]; then
        NO_COMMIT=1
        shift
    fi

    SAVED_BRANCH=$(jq -r '.kernel.branch // empty' versions.json)

    if [ "$#" -eq 1 ]; then
        BASE_VERSION=$1
        jq --arg b "$BASE_VERSION" '.kernel.branch = $b' versions.json > versions.json.tmp && mv versions.json.tmp versions.json
    elif [ -n "$SAVED_BRANCH" ]; then
        BASE_VERSION=$SAVED_BRANCH
    else
        echo "Usage: update-kernel [--no-commit] [base-version]"
        echo "Example: update-kernel 7.1.y"
        exit 1
    fi

    BRANCH="rpi-''${BASE_VERSION}"
    REPO="https://github.com/raspberrypi/linux"

    COMMIT=$(git ls-remote "$REPO.git" "refs/heads/$BRANCH" | awk '{print $1}')
    if [ -z "$COMMIT" ]; then
        echo "Error: Branch $BRANCH not found" >&2
        exit 1
    fi

    CURRENT_COMMIT=$(jq -r .kernel.tag versions.json)
    if [ "$COMMIT" = "$CURRENT_COMMIT" ]; then
        exit 0
    fi

    MAKEFILE_URL="https://raw.githubusercontent.com/raspberrypi/linux/''${COMMIT}/Makefile"
    MAKEFILE_CONTENT=$(curl -sSL "$MAKEFILE_URL")

    VERSION=$(echo "$MAKEFILE_CONTENT" | grep -E '^VERSION = ' | awk '{print $3}')
    PATCHLEVEL=$(echo "$MAKEFILE_CONTENT" | grep -E '^PATCHLEVEL = ' | awk '{print $3}')
    SUBLEVEL=$(echo "$MAKEFILE_CONTENT" | grep -E '^SUBLEVEL = ' | awk '{print $3}')
    EXTRAVERSION=$(echo "$MAKEFILE_CONTENT" | grep -E '^EXTRAVERSION =' | awk '{print $3}' || true)

    if [ -z "$VERSION" ] || [ -z "$PATCHLEVEL" ] || [ -z "$SUBLEVEL" ]; then
        echo "Error parsing Makefile for version" >&2
        exit 1
    fi

    MOD_DIR_VERSION="''${VERSION}.''${PATCHLEVEL}.''${SUBLEVEL}''${EXTRAVERSION}"

    # Calculate nix hash
    PREFETCH_JSON=$(nix store prefetch-file --json --name source --unpack "''${REPO}/archive/''${COMMIT}.tar.gz")
    SRI_HASH=$(echo "$PREFETCH_JSON" | jq -r '.hash')

    if [ -z "$SRI_HASH" ] || [ "$SRI_HASH" = "null" ]; then
        echo "Error getting hash." >&2
        exit 1
    fi

    jq \
      --arg tag "$COMMIT" \
      --arg mdv "$MOD_DIR_VERSION" \
      --arg sh "$SRI_HASH" \
      '.kernel.tag = $tag | .kernel.modDirVersion = $mdv | .kernel.srcHash = $sh' \
      versions.json > versions.json.tmp && mv versions.json.tmp versions.json

    SHORT_COMMIT="''${COMMIT:0:7}"
    echo "kernel: $MOD_DIR_VERSION ($SHORT_COMMIT)" > .update-messages

    if [ "$NO_COMMIT" -eq 1 ]; then
        exit 0
    fi

    git add versions.json
    if ! git diff --cached --quiet; then
        git commit -m "chore(kernel): update to $MOD_DIR_VERSION ($SHORT_COMMIT)"
        echo "Changes committed!"
    else
        echo "No changes to commit."
    fi
  '';
}
