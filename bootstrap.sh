#!/usr/bin/env bash
set -euo pipefail

release_tag="v0.1.0"
installer_args=()

while test "$#" -gt 0; do
  case "$1" in
    --version)
      test "$#" -ge 2 || { printf '%s\n' 'Error: --version requires a tag' >&2; exit 1; }
      release_tag="$2"
      shift 2
      ;;
    -h|--help)
      printf '%s\n' 'Usage: bash bootstrap.sh [--version vX.Y.Z] [--codex-home PATH] [--skills-dir PATH]'
      exit 0
      ;;
    *)
      installer_args+=("$1")
      shift
      ;;
  esac
done

[[ "$release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { printf 'Error: invalid release tag: %s\n' "$release_tag" >&2; exit 1; }
archive_url="https://github.com/dff652/codex-luna-worker/archive/refs/tags/${release_tag}.tar.gz"
download_dir="$(mktemp -d)"
trap 'rm -r -- "$download_dir"' EXIT

curl -fsSL "$archive_url" -o "$download_dir/source.tar.gz"
mkdir "$download_dir/source"
tar -xzf "$download_dir/source.tar.gz" -C "$download_dir/source" --strip-components=1
test -f "$download_dir/source/VERSION" || { printf '%s\n' 'Error: archive has no VERSION file' >&2; exit 1; }
read -r archive_version < "$download_dir/source/VERSION"
test "$archive_version" = "$release_tag" || { printf 'Error: archive version %s does not match %s\n' "$archive_version" "$release_tag" >&2; exit 1; }
bash "$download_dir/source/install.sh" --update "${installer_args[@]}"
