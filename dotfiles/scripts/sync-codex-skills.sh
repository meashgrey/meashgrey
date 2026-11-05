#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--dry-run]\n' "${0##*/}"
}

dry_run=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

repo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
skills_dir=${CODEX_SKILLS_DIR:-"$HOME/.agents/skills"}
target_root="$repo_dir/home/skills"
changed=0

sync_skill() {
  local source=$1 target=$2 name stage backup
  name=${source##*/}
  if [[ -f "$target/SKILL.md" ]] && diff -qr -- "$source" "$target" >/dev/null; then
    printf 'Unchanged: %s\n' "${target#"$repo_dir"/}"
    return
  fi

  printf '%s: %s\n' "$([[ $dry_run == true ]] && printf 'Would update' || printf 'Updating')" "${target#"$repo_dir"/}"
  changed=1
  if [[ $dry_run == true ]]; then
    return 0
  fi

  mkdir -p -- "$target_root"
  stage=$(mktemp -d "$target_root/.${name}.sync.XXXXXX")
  cp -aL -- "$source/." "$stage/"

  if [[ -e "$target" || -L "$target" ]]; then
    backup="${target}.backup.$$"
    mv -- "$target" "$backup"
    if ! mv -- "$stage" "$target"; then
      mv -- "$backup" "$target"
      rm -rf -- "$stage"
      return 1
    fi
    rm -rf -- "$backup"
  else
    mv -- "$stage" "$target"
  fi
}

if [[ ! -d "$skills_dir" ]]; then
  printf 'No user skills directory: %s\n' "$skills_dir"
  exit 0
fi

shopt -s nullglob
for skill_file in "$skills_dir"/*/SKILL.md; do
  skill_source=${skill_file%/SKILL.md}
  skill_name=${skill_source##*/}
  sync_skill "$skill_source" "$target_root/$skill_name"
done
shopt -u nullglob

if (( ! changed )); then
  printf 'No skill changes to sync.\n'
elif [[ $dry_run == true ]]; then
  printf 'No files were changed.\n'
else
  printf 'Skills synced into home/skills. Review and commit the changes.\n'
fi
