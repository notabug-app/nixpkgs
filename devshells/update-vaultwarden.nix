{ pkgs }:

pkgs.writeShellApplication {
  name = "update-vaultwarden";
  runtimeInputs = with pkgs; [
    gh
    jq
    gnused
    nix
  ];
  text = ''
    set -e

    echo "Fetching latest Vaultwarden tag..."
    VW_TAG=$(gh api repos/dani-garcia/vaultwarden/releases/latest --jq .tag_name)
    VW_VERSION=''${VW_TAG#v}

    echo "Fetching latest web-vault tag..."
    WEB_TAG=$(gh api repos/dani-garcia/bw_web_builds/releases/latest --jq .tag_name)

    echo "Updating flake.nix URLs..."
    sed -i -E "s|github:dani-garcia/vaultwarden/[^\"]*|github:dani-garcia/vaultwarden/''${VW_TAG}|" flake.nix
    sed -i -E "s|download/v[0-9.]+/bw_web_v[0-9.]+\.tar\.gz|download/''${WEB_TAG}/bw_web_''${WEB_TAG}.tar.gz|" flake.nix

    echo "Updating pkgs/arm.nix versions..."
    sed -i -E '/vaultwarden =/,/version = /s/version = "[^"]*"/version = "'"$VW_VERSION"'"/' pkgs/arm.nix
    sed -i -E '/vaultwarden-vault =/,/version = /s/version = "[^"]*"/version = "'"$WEB_TAG"'"/' pkgs/arm.nix


    echo "Done!"
  '';
}
