{ pkgs }:

pkgs.writeShellApplication {
  name = "update-flake";
  runtimeInputs = with pkgs; [
    git
    nix
    jq
  ];
  text = ''
        set -euo pipefail

        if [ "''${GITHUB_ACTIONS:-}" != "true" ]; then
            if [ -n "$(git status --porcelain -uno)" ]; then
                echo "Error: Working directory has uncommitted changes. Please stash or commit them first." >&2
                exit 1
            fi

            ORIGINAL_BRANCH=$(git branch --show-current 2>/dev/null || true)

            echo "Fetching origin..."
            git fetch origin staging main

            if [ "$ORIGINAL_BRANCH" != "staging" ]; then
                echo "Switching to staging branch..."
                if git show-ref --verify --quiet refs/heads/staging; then
                    git checkout staging
                else
                    git checkout -b staging --track origin/staging
                fi
            fi

            if git rev-parse --verify origin/staging >/dev/null 2>&1; then
                git pull --ff-only origin staging || true
            fi

            if git rev-parse --verify origin/main >/dev/null 2>&1; then
                if ! git merge-base --is-ancestor origin/main staging; then
                    echo "Merging origin/main into staging..."
                    git merge --no-edit origin/main
                fi
            fi
        fi

        rm -f .update-messages
        echo "Updating top-level flake inputs..."
        nix flake update --accept-flake-config 2>&1 | grep -oP "(?<=(Updated|Added) input ').*(?=':)" | awk '{print "flake: "$1}' >> .update-messages || true

        echo "Updating transitive flake inputs (e.g. crane, flake-utils)..."
        TRANSITIVE_INPUTS=$(jq -r '
          .nodes as $nodes
          | $nodes.root.inputs
          | to_entries[]
          | .key as $parent_name
          | .value as $parent_node
          | ($nodes[$parent_node].inputs // {})
          | to_entries[]
          | select(.value | type == "string")
          | "\($parent_name)/\(.key)"
        ' flake.lock)

        if [ -n "$TRANSITIVE_INPUTS" ]; then
          echo "$TRANSITIVE_INPUTS" | xargs nix flake update --accept-flake-config 2>&1 | grep -oP "(?<=(Updated|Added) input ').*(?=':)" | awk '{print "flake: "$1}' >> .update-messages || true
        fi

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
            if [ "''${GITHUB_ACTIONS:-}" != "true" ] && [ -n "''${ORIGINAL_BRANCH:-}" ] && [ "$ORIGINAL_BRANCH" != "staging" ]; then
                echo "Switching back to $ORIGINAL_BRANCH..."
                git checkout "$ORIGINAL_BRANCH"
            fi
            exit 0
        fi

        COMMIT_MSG="chore: update flake and packages"

        if [ -s .update-messages ]; then
            COMMIT_MSG="$COMMIT_MSG

    Updates:
    $(cat .update-messages)"
            rm .update-messages
        else
            rm -f .update-messages
        fi

        if [ "''${GITHUB_ACTIONS:-}" = "true" ]; then
            echo "Running in GitHub Actions, skipping git commit so the PR action can create it."
            echo "$COMMIT_MSG" > .pr-message
            exit 0
        fi

        git commit -m "$COMMIT_MSG"
        echo "Changes committed to staging!"

        echo "Pushing changes to origin/staging..."
        git push origin staging
        echo "Pushed to origin/staging. GitHub Actions will build packages and merge into main on completion."
  '';
}
