#!/usr/bin/env bash
# Install the agent-browser CLI and its Chrome for Testing.
#
# Installs the latest release. run_onchange_ runs this only when the script
# changes. To upgrade later:
#   npm install -g --prefix ~/.local agent-browser@latest
# The prefix is ~/.local, so the install needs no sudo and does not depend on the
# active nvm Node version. dot_zshenv puts ~/.local/bin on PATH.
#
# Linux: Chrome needs system libraries. `--with-deps` installs them with apt, so it
# is used only when sudo works without a password. Otherwise run once by hand:
#   agent-browser install --with-deps
set -euo pipefail

prefix="$HOME/.local"
bin="$prefix/bin/agent-browser"

# GNU timeout is not on a fresh Mac. perl is on macOS and Debian.
limit() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$@"
  else
    perl -e 'alarm shift; exec @ARGV or die "exec: $!"' "$@"
  fi
}

if ! command -v npm >/dev/null 2>&1; then
  echo "agent-browser: npm not found, skipping" >&2
  exit 0
fi

limit 600 npm install --global --prefix "$prefix" --no-fund --no-audit agent-browser@latest

deps=()
if [[ "$(uname -s)" == Linux ]]; then
  if sudo -n true 2>/dev/null; then
    deps=(--with-deps)
  else
    echo "agent-browser: no passwordless sudo, skipping system libraries." >&2
    echo "agent-browser: run 'agent-browser install --with-deps' once by hand." >&2
  fi
fi
limit 900 "$bin" install ${deps[@]+"${deps[@]}"}
