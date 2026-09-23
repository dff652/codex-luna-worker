#!/usr/bin/env bash
set -euo pipefail

archive_url="https://github.com/dff652/codex-luna-worker/archive/refs/heads/main.tar.gz"
download_dir="$(mktemp -d)"
trap 'rm -r -- "$download_dir"' EXIT

curl -fsSL "$archive_url" -o "$download_dir/source.tar.gz"
mkdir "$download_dir/source"
tar -xzf "$download_dir/source.tar.gz" -C "$download_dir/source" --strip-components=1
bash "$download_dir/source/install.sh" --update "$@"
