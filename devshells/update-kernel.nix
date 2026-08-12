{ pkgs }:

pkgs.writeShellApplication {
  name = "update-kernel";
  runtimeInputs = with pkgs; [
    git
    curl
    jq
    gnused
    nix
  ];
  text = ''
    set -euo pipefail

    if [ "$#" -ne 1 ]; then
        echo "Usage: update-kernel <base-version>"
        echo "Example: update-kernel 7.1.y"
        exit 1
    fi

    BASE_VERSION=$1
    BRANCH="rpi-''${BASE_VERSION}"
    REPO="https://github.com/raspberrypi/linux"

    echo "Fetching latest commit for branch $BRANCH..."
    COMMIT=$(git ls-remote "$REPO.git" "refs/heads/$BRANCH" | awk '{print $1}')
    if [ -z "$COMMIT" ]; then
        echo "Error: Branch $BRANCH not found"
        exit 1
    fi
    echo "Latest commit: $COMMIT"

    CURRENT_COMMIT=$(grep 'tag =' linux.nix | cut -d'"' -f2 || true)
    if [ "$COMMIT" = "$CURRENT_COMMIT" ]; then
        echo "Already at latest commit ($COMMIT). Exiting."
        exit 0
    fi

    echo "Fetching Makefile to determine modDirVersion..."
    MAKEFILE_URL="https://raw.githubusercontent.com/raspberrypi/linux/''${COMMIT}/Makefile"
    MAKEFILE_CONTENT=$(curl -sSL "$MAKEFILE_URL")

    VERSION=$(echo "$MAKEFILE_CONTENT" | grep -E '^VERSION = ' | awk '{print $3}')
    PATCHLEVEL=$(echo "$MAKEFILE_CONTENT" | grep -E '^PATCHLEVEL = ' | awk '{print $3}')
    SUBLEVEL=$(echo "$MAKEFILE_CONTENT" | grep -E '^SUBLEVEL = ' | awk '{print $3}')
    EXTRAVERSION=$(echo "$MAKEFILE_CONTENT" | grep -E '^EXTRAVERSION =' | awk '{print $3}' || true)

    if [ -z "$VERSION" ] || [ -z "$PATCHLEVEL" ] || [ -z "$SUBLEVEL" ]; then
        echo "Error parsing Makefile for version"
        exit 1
    fi

    MOD_DIR_VERSION="''${VERSION}.''${PATCHLEVEL}.''${SUBLEVEL}''${EXTRAVERSION}"
    echo "Kernel version: $MOD_DIR_VERSION"

    echo "Calculating nix hash... (this may take a while)"
    PREFETCH_JSON=$(nix store prefetch-file --json --name source --unpack "''${REPO}/archive/''${COMMIT}.tar.gz")
    SRI_HASH=$(echo "$PREFETCH_JSON" | jq -r '.hash')

    if [ -z "$SRI_HASH" ] || [ "$SRI_HASH" = "null" ]; then
        echo "Error getting hash."
        exit 1
    fi

    echo "Hash: $SRI_HASH"

    echo "Updating linux.nix and flake.nix..."

    MAJOR=$(echo "$BASE_VERSION" | cut -d. -f1)
    MINOR=$(echo "$BASE_VERSION" | cut -d. -f2)
    NEW_SUFFIX="''${MAJOR}_''${MINOR}"

    sed -i -E "s/modDirVersion = \".+\";/modDirVersion = \"$MOD_DIR_VERSION\";/" linux.nix
    sed -i -E "s/tag = \".+\";/tag = \"$COMMIT\";/" linux.nix
    sed -i -E "s|srcHash = \".+\";|srcHash = \"$SRI_HASH\";|" linux.nix
    # shellcheck disable=SC2016
    sed -i -E 's/name = "linuxPackages_rpi\$\{model\}_[0-9]+_[0-9]+";/name = "linuxPackages_rpi\''${model}_'"''${NEW_SUFFIX}"'";/' linux.nix

    sed -i -E "s/linuxPackages_rpi([45])_[0-9]+_[0-9]+/linuxPackages_rpi\1_''${NEW_SUFFIX}/g" flake.nix

    echo "Committing changes..."
    git add linux.nix flake.nix
    if ! git diff --cached --quiet; then
        echo ""
        echo "Changes:"
        git diff --cached --stat
        echo ""
        git diff --cached --color=always
        echo ""
        
        read -r -p "Commit these changes? [y/N] " ans
        if [[ ! "$ans" =~ ^[Yy]$ ]]; then
            echo "Aborting commit."
            exit 1
        fi
        
        SHORT_COMMIT="''${COMMIT:0:7}"
        git commit -m "chore(kernel): update to $MOD_DIR_VERSION ($SHORT_COMMIT)"
        echo "Changes committed!"
    else
        echo "No changes to commit."
    fi

    echo "Done!"
  '';
}
