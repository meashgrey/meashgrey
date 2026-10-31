#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--dry-run]\n' "${0##*/}"
}

dry_run=false
case "${1-}" in
  '') ;;
  --dry-run) dry_run=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if (( $# > 1 )); then usage >&2; exit 2; fi

repo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}
missing=0
changed=0

sync_file() {
  local source=$1 target=$2
  if [[ ! -f "$source" ]]; then
    printf 'Missing, skipped: %s\n' "$source" >&2
    missing=1
    return
  fi
  if [[ -f "$target" ]] && cmp -s -- "$source" "$target"; then
    printf 'Unchanged: %s\n' "${target#"$repo_dir"/}"
    return
  fi
  printf '%s: %s\n' "$([[ $dry_run == true ]] && printf 'Would update' || printf 'Updating')" "${target#"$repo_dir"/}"
  changed=1
  if [[ $dry_run == false ]]; then
    mkdir -p -- "$(dirname -- "$target")"
    cp -- "$source" "$target"
  fi
}

sync_file "$config_dir/niri/config.kdl" "$repo_dir/home/niri/config.kdl"
for fragment in alttab binds colors cursor layout outputs; do
  sync_file "$config_dir/niri/dms/$fragment.kdl" "$repo_dir/home/niri/dms/$fragment.kdl"
done
sync_file "$config_dir/DankMaterialShell/settings.json" "$repo_dir/home/dms/settings.json"
sync_file "$config_dir/fcitx5/profile" "$repo_dir/home/fcitx5/profile"

if (( missing )); then
  printf 'Some files were missing; existing repository files were preserved.\n' >&2
  exit 1
fi
if (( changed )); then
  printf 'Review changes, including monitor settings, before sharing or using on another machine.\n'
fi

if [[ $dry_run == true ]]; then
  printf 'Would copy the repository to /etc/nixos (excluding .git and result).\n'
  exit 0
fi

printf 'Deploying configuration to /etc/nixos; sudo may request your password.\n'
sudo -v
sudo mkdir -p /etc/nixos
tar -C "$repo_dir" --exclude='./.git' --exclude='./result' -cf - . |
  sudo tar -C /etc/nixos --no-same-owner -xf -
printf 'Configuration copied to /etc/nixos. No rebuild was run.\n'
