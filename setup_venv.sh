#!/bin/bash
#
# One-shot setup for a fresh clone of DRAMBender.
#
#   bash setup_venv.sh                  # create .venv, install deps, build + install drambender
#   bash setup_venv.sh --force          # wipe .venv/ first
#   PYTHON_BIN=python3.11 bash setup_venv.sh   # use a different interpreter
#
# After this finishes, `import drambender` works from the .venv. Package
# metadata and CMake build configuration live in pyproject.toml. For iterative
# Debug builds during development, run
# `bash build.sh debug` afterward — it overwrites python/drambender/_core.*.so
# in place.

set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3.12}"
VENV_DIR="${VENV_DIR:-.venv}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

FORCE=0
for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=1 ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "error: unknown argument '$arg'" >&2; exit 1 ;;
    esac
done

if (( FORCE )); then
    echo "==> Removing existing $VENV_DIR"
    rm -rf "$VENV_DIR"
elif [[ -d "$VENV_DIR" ]]; then
    echo "==> $VENV_DIR already exists; reusing it (pass --force to recreate)"
fi

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "error: $PYTHON_BIN not found on PATH." >&2
    echo "       Set PYTHON_BIN=/path/to/python3.x if you need a different interpreter." >&2
    exit 1
fi

if [[ ! -d "$VENV_DIR" ]]; then
    echo "==> Creating venv at $VENV_DIR with $($PYTHON_BIN --version)"
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

VENV_PYTHON="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"

echo "==> Upgrading pip inside $VENV_DIR"
"$VENV_PYTHON" -m pip install --quiet --upgrade pip

echo "==> Installing requirements.txt"
"$VENV_PIP" install --quiet -r requirements.txt

echo "==> Building C++ extension and installing editable drambender wheel"
"$VENV_PIP" install -e "."

echo
echo "Done. Verify with:"
echo "    $VENV_PYTHON -c 'import drambender; print(drambender.__file__)'"
