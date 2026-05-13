#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODE=${SANDBOX_MODE:-runtime}
APP_ROOT=${APP_ROOT:-$ROOT_DIR}
DATA_ROOT=${DATA_ROOT:-/Users/Shared/mlx/data}
MODEL_ROOT=${MODEL_ROOT:-/Users/Shared/mlx/models}
CACHE_ROOT=${CACHE_ROOT:-/Users/Shared/mlx/.cache/hf}
TMP_ROOT=${TMP_ROOT:-/private/tmp/chr33s-ai}

usage() {
  cat <<'EOF'
Usage: scripts/sandbox.sh [runtime|bootstrap] -- command [args...]

Examples:
  scripts/sandbox.sh runtime -- /opt/homebrew/bin/node server.js
  scripts/sandbox.sh bootstrap -- /Users/Shared/mlx/.venv/bin/python -m mlx_lm.server

Environment overrides:
  APP_ROOT
  DATA_ROOT
  MODEL_ROOT
  CACHE_ROOT
  TMP_ROOT
  SANDBOX_EXEC_USER   Default: mlx
  SANDBOX_PROFILE     Override the profile path entirely
EOF
}

if [ $# -eq 0 ]; then
  usage >&2
  exit 64
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

if [ "$1" = "runtime" ] || [ "$1" = "bootstrap" ]; then
  MODE=$1
  shift
fi

if [ $# -eq 0 ] || [ "$1" != "--" ]; then
  usage >&2
  exit 64
fi
shift

if [ $# -eq 0 ]; then
  usage >&2
  exit 64
fi

EXECUTABLE=$1
if [ ! -x "$EXECUTABLE" ]; then
  echo "Executable not found or not executable: $EXECUTABLE" >&2
  exit 66
fi

PROFILE=${SANDBOX_PROFILE:-$ROOT_DIR/sandbox/$MODE.sb}
SANDBOX_EXEC_USER=${SANDBOX_EXEC_USER:-mlx}

if [ ! -f "$PROFILE" ]; then
  echo "Sandbox profile not found: $PROFILE" >&2
  exit 66
fi

mkdir -p "$DATA_ROOT" "$MODEL_ROOT" "$CACHE_ROOT" "$TMP_ROOT"

exec sudo -u "$SANDBOX_EXEC_USER" sandbox-exec \
  -f "$PROFILE" \
  -D APP_ROOT="$APP_ROOT" \
  -D DATA_ROOT="$DATA_ROOT" \
  -D MODEL_ROOT="$MODEL_ROOT" \
  -D CACHE_ROOT="$CACHE_ROOT" \
  -D TMP_ROOT="$TMP_ROOT" \
  -D EXECUTABLE="$EXECUTABLE" \
  -- "$@"
