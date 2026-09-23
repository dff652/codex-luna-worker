#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf '%s\n' 'Usage: ./install.sh [--update] [--codex-home PATH] [--skills-dir PATH]'
}

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
test -n "$script_dir" || fail "cannot resolve installer directory"

user_home="${HOME:?HOME must be set}"
codex_home=""
skills_root=""
update=false

while test "$#" -gt 0; do
  case "$1" in
    --update)
      update=true
      shift
      ;;
    --codex-home)
      test "$#" -ge 2 || fail "--codex-home requires a path"
      codex_home="$2"
      shift 2
      ;;
    --skills-dir)
      test "$#" -ge 2 || fail "--skills-dir requires a path"
      skills_root="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

codex_home="${codex_home:-${CODEX_HOME:-$user_home/.codex}}"
if test -z "$skills_root"; then
  if test -n "${CODEX_SKILLS_DIR:-}"; then
    skills_root="$CODEX_SKILLS_DIR"
  elif test -f "$codex_home/skills/luna/SKILL.md"; then
    test ! -f "$user_home/.agents/skills/luna/SKILL.md" || fail "luna skill exists in both skill roots; pass --skills-dir"
    skills_root="$codex_home/skills"
  else
    skills_root="$user_home/.agents/skills"
  fi
fi

case "$codex_home" in
  /*) ;;
  *) fail "CODEX_HOME must be an absolute path: $codex_home" ;;
esac

case "$skills_root" in
  /*) ;;
  *) fail "CODEX_SKILLS_DIR must be an absolute path: $skills_root" ;;
esac

source_agent="$script_dir/agents/luna-worker.toml"
source_agent6="$script_dir/agents/luna6-worker.toml"
source_agent56="$script_dir/agents/luna56-worker.toml"
source_skill="$script_dir/skills/luna/SKILL.md"
source_metadata="$script_dir/skills/luna/agents/openai.yaml"

sources=("$source_agent" "$source_agent6" "$source_agent56" "$source_skill" "$source_metadata")
targets=("$codex_home/agents/luna-worker.toml" "$codex_home/agents/luna6-worker.toml" "$codex_home/agents/luna56-worker.toml" "$skills_root/luna/SKILL.md" "$skills_root/luna/agents/openai.yaml")
modes=(600 600 600 644 644)

for source_file in "${sources[@]}"; do
  test -f "$source_file" || fail "required source file is missing: $source_file"
  test ! -L "$source_file" || fail "source file must not be a symbolic link: $source_file"
done

for i in "${!sources[@]}"; do
  target_path="${targets[$i]}"
  if test -e "$target_path" || test -L "$target_path"; then
    test ! -L "$target_path" || fail "refusing to replace symbolic link: $target_path"
    test -f "$target_path" || fail "destination exists but is not a regular file: $target_path"
    if ! cmp -s "${sources[$i]}" "$target_path" && test "$update" = false; then
      fail "destination already exists with different content: $target_path (use --update to back it up and replace it)"
    fi
  fi
done

ensure_directory() {
  local destination_dir="$1"
  local directory_mode="$2"

  test ! -L "$destination_dir" || fail "destination directory must not be a symbolic link: $destination_dir"
  if test -e "$destination_dir"; then
    test -d "$destination_dir" || fail "destination exists but is not a directory: $destination_dir"
    return
  fi
  install -d -m "$directory_mode" "$destination_dir"
}

install_file() {
  local source_path="$1"
  local target_path="$2"
  local file_mode="$3"

  if test -e "$target_path" || test -L "$target_path"; then
    test ! -L "$target_path" || fail "refusing to replace symbolic link: $target_path"
    test -f "$target_path" || fail "destination exists but is not a regular file: $target_path"
    if cmp -s "$source_path" "$target_path"; then
      printf 'Unchanged: %s\n' "$target_path"
      return
    fi
  fi

  install -m "$file_mode" "$source_path" "$target_path"
  printf 'Installed: %s\n' "$target_path"
}

agent_dir="$codex_home/agents"
skill_dir="$skills_root/luna"
skill_metadata_dir="$skill_dir/agents"

ensure_directory "$agent_dir" 700
ensure_directory "$skills_root" 755
ensure_directory "$skill_dir" 755
ensure_directory "$skill_metadata_dir" 755

backup_dir=""
if test "$update" = true; then
  for i in "${!sources[@]}"; do
    target_path="${targets[$i]}"
    if test -f "$target_path" && ! cmp -s "${sources[$i]}" "$target_path"; then
      if test -z "$backup_dir"; then
        ensure_directory "$codex_home/backups" 700
        backup_dir="$(mktemp -d "$codex_home/backups/luna-worker.XXXXXXXX")"
      fi
      case "$i" in
        0|1|2) backup_path="$backup_dir/agents/$(basename "$target_path")" ;;
        3) backup_path="$backup_dir/skills/luna/SKILL.md" ;;
        4) backup_path="$backup_dir/skills/luna/agents/openai.yaml" ;;
      esac
      install -d -m 700 "$(dirname "$backup_path")"
      cp -p -- "$target_path" "$backup_path"
      printf 'Backed up: %s\n' "$backup_path"
    fi
  done
fi

for i in "${!sources[@]}"; do
  install_file "${sources[$i]}" "${targets[$i]}" "${modes[$i]}"
done

printf '\nInstallation complete. Restart Codex or open a new chat, then invoke:\n'
printf '  $luna <bounded coding task>\n'
printf '  Or ask for luna6-worker or luna56-worker by name.\n'
