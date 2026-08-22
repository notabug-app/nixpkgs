{ pkgs }:

pkgs.writeShellApplication {
  name = "update-flake";
  runtimeInputs = with pkgs; [
    git
    nix
  ];
  text = ''
            set -euo pipefail

            echo "Updating flake inputs..."
            nix flake update

            rm -f .update-messages

            echo "Checking for kernel updates..."
            update-kernel --no-commit

            echo "Checking for vaultwarden updates..."
            update-vaultwarden --no-commit

            echo "Checking for helium updates..."
            update-helium --no-commit

            # Always add versions.json and flake.lock
            git add flake.lock flake.nix pkgs/ versions.json 2>/dev/null || true

            if git diff --cached --quiet; then
                echo "No changes to commit"
                exit 0
            fi

        COMMIT_MSG="chore: update flake and packages"
        
        if [ -f .update-messages ]; then
            COMMIT_MSG="$COMMIT_MSG

    Updates:
    $(cat .update-messages)"
            rm .update-messages
        fi

        if [ "''${GITHUB_ACTIONS:-}" = "true" ]; then
            echo "Running in GitHub Actions, skipping git commit so the PR action can create it."
            echo "$COMMIT_MSG" > .pr-message
            exit 0
        fi

        git commit -m "$COMMIT_MSG"
        echo "Changes committed!"
  '';
}
