{ pkgs }:

pkgs.writeShellScriptBin "setup-firn" ''
  if [ -z "$FIRN_URL" ] || [ -z "$FIRN_SECRET" ]; then
    echo "FIRN_URL or FIRN_SECRET not set"
    exit 1
  fi
  
  HOST=$(echo "$FIRN_URL" | awk -F/ '{print $3}')
  echo "machine $HOST password $FIRN_SECRET" | sudo tee -a /etc/nix/netrc > /dev/null
  
  nix build .#firn -L
  ./result/bin/firn login --server-url "$FIRN_URL" --token "$FIRN_SECRET"
''
