{ pkgs }:

pkgs.writeShellScriptBin "setup-firn" ''
  if [ -z "$FIRN_SERVER_URL" ] || [ -z "$FIRN_TOKEN" ]; then
    echo "FIRN_SERVER_URL or FIRN_TOKEN not set"
    exit 1
  fi

  HOST=$(echo "$FIRN_SERVER_URL" | awk -F/ '{print $3}')
  echo "machine $HOST password $FIRN_TOKEN" | sudo tee -a /etc/nix/netrc > /dev/null

  nix build .#firn -L
  ./result/bin/firn login
''
