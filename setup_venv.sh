#!/bin/bash
#
# One-shot setup for a fresh clone of DRAMBender.
#
#   bash setup_venv.sh                  # create .venv, install deps, build + install drambender
#   bash setup_venv.sh --force          # wipe .venv/ first
#   PYTHON_BIN=python3.11 bash setup_venv.sh   # use a different interpreter
#   export CXX=/path/to/g++-11-or-newer # use this first if default g++ is too old
#
# After this finishes, `import drambender` works from the .venv. Package
# metadata and CMake build configuration live in pyproject.toml. For iterative
# Debug builds during development, run
# `bash build.sh debug` afterward — it rebuilds the extension imported by
# this venv.

set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3.12}"
VENV_DIR="${VENV_DIR:-.venv}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

MIN_GXX_MAJOR=11
CXX_COMPILER="${CXX:-g++}"
CXX_VERSION=""
CXX_MAJOR=""

check_python_dev_headers() {
    local python_bin="$1"
    local report

    if report="$("$python_bin" - <<'PY'
import os
import sys
import sysconfig

version = f"{sys.version_info.major}.{sys.version_info.minor}"
include_dirs = []
for key in ("INCLUDEPY", "CONFINCLUDEPY"):
    value = sysconfig.get_config_var(key)
    if value and value not in include_dirs:
        include_dirs.append(value)

missing = []
for header in ("Python.h", "patchlevel.h"):
    if not any(os.path.exists(os.path.join(include_dir, header)) for include_dir in include_dirs):
        missing.append(header)

if missing:
    print(f"error: Python {version} development headers are missing: {', '.join(missing)}")
    print("       Checked include directories:")
    for include_dir in include_dirs or ["<none reported by sysconfig>"]:
        print(f"         - {include_dir}")
    print(f"       On Ubuntu/Debian, install them with:")
    print(f"           sudo apt install python{version}-dev")
    raise SystemExit(1)
PY
    )"; then
        return 0
    fi

    echo "$report" >&2
    return 1
}

check_cxx_compiler() {
    if ! command -v "$CXX_COMPILER" >/dev/null 2>&1; then
        echo "error: C++ compiler '$CXX_COMPILER' not found." >&2
        echo "       Install g++ ${MIN_GXX_MAJOR} or newer, or run 'export CXX=/path/to/g++-11-or-newer'." >&2
        exit 1
    fi

    CXX_VERSION="$("$CXX_COMPILER" -dumpfullversion -dumpversion 2>/dev/null || true)"
    if [[ -z "$CXX_VERSION" ]]; then
        CXX_VERSION="$("$CXX_COMPILER" -dumpversion 2>/dev/null || true)"
    fi
    CXX_VERSION="${CXX_VERSION%%$'\n'*}"
    CXX_MAJOR="${CXX_VERSION%%.*}"

    if [[ ! "$CXX_MAJOR" =~ ^[0-9]+$ ]]; then
        echo "error: unable to determine g++ version for '$CXX_COMPILER'." >&2
        echo "       Install g++ ${MIN_GXX_MAJOR} or newer, or run 'export CXX=/path/to/g++-11-or-newer'." >&2
        exit 1
    fi

    if (( CXX_MAJOR < MIN_GXX_MAJOR )); then
        echo "error: '$CXX_COMPILER' is g++ $CXX_VERSION; DRAMBender requires g++ ${MIN_GXX_MAJOR} or newer." >&2
        echo "       Install a newer g++, or run 'export CXX=/path/to/g++-11-or-newer'." >&2
        exit 1
    fi
}

FORCE=0
for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=1 ;;
        -h|--help) sed -n '2,14p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "error: unknown argument '$arg'" >&2; exit 1 ;;
    esac
done

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "error: $PYTHON_BIN not found on PATH." >&2
    echo "       Set PYTHON_BIN=/path/to/python3.x if you need a different interpreter." >&2
    exit 1
fi

echo "==> Checking Python development headers"
check_python_dev_headers "$PYTHON_BIN"
check_cxx_compiler

if (( FORCE )); then
    echo "==> Removing existing $VENV_DIR"
    rm -rf "$VENV_DIR"
elif [[ -d "$VENV_DIR" ]]; then
    echo "==> $VENV_DIR already exists; reusing it (pass --force to recreate)"
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

echo "==> Using C++ compiler: $CXX_COMPILER (g++ $CXX_VERSION)"
echo "==> Building C++ extension and installing editable drambender wheel"
CXX="$CXX_COMPILER" "$VENV_PIP" install -e "."

echo
echo "Done. Verify with:"
echo "    $VENV_PYTHON -c 'import drambender; print(drambender.__file__)'"
