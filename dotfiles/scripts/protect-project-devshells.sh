#!/usr/bin/env bash
set -euo pipefail

projects_dir="${PROJECTS_DIR:-$HOME/Projects}"
profile_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/project-devshells"
system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"

if [[ ! -d "$projects_dir" ]]; then
  echo "Projects directory not found: $projects_dir" >&2
  exit 1
fi

mkdir -p "$profile_dir"

while IFS= read -r -d '' flake; do
  project="$(dirname "$flake")"
  relative="${project#"$projects_dir"/}"
  slug="${relative//\//--}"
  slug="${slug// /-}"
  profile="$profile_dir/$slug"

  if ! grep -q 'devShells' "$flake"; then
    echo "skip (no default devShell): $relative"
    continue
  fi

  echo "Protecting devShell: $relative"
  nix develop --profile "$profile" "$project#devShells.$system.default" --command true
  nix profile wipe-history --profile "$profile"
done < <(find "$projects_dir" -path '*/.git' -prune -o -type f -name flake.nix -print0 | sort -z)
