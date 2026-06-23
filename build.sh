#!/bin/bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [--cxx-only] [debug|release]

Configure and build DRAMBender. If no argument is given and stdin is a
terminal, you will be prompted to choose a configuration.

Default builds include the Python extension and require .venv/bin/python.
Run bash setup_venv.sh first for Python development.

  debug                 -> build/dev-gcc12         (Python, Debug)
  release               -> build/release-gcc12     (Python, Release)
  --cxx-only debug      -> build/cxx-dev-gcc12     (C++ only, Debug)
  --cxx-only release    -> build/cxx-release-gcc12 (C++ only, Release)

Examples:
  bash setup_venv.sh
  bash build.sh debug
  bash build.sh --cxx-only release
EOF
}

CXX_ONLY=0
CONFIG=""

for arg in "$@"; do
    case "${arg,,}" in
        -h|--help)
            usage
            exit 0
            ;;
        --cxx-only)
            CXX_ONLY=1
            ;;
        debug|release)
            if [[ -n "$CONFIG" ]]; then
                echo "error: build configuration specified more than once" >&2
                echo >&2
                usage >&2
                exit 1
            fi
            CONFIG="$arg"
            ;;
        *)
            echo "error: unknown argument '$arg'" >&2
            echo >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$CONFIG" ]]; then
    if [[ -t 0 && -t 1 ]]; then
        echo
        echo "Select build configuration:"
        echo
        PS3=$'\nChoice> '
        select choice in "Debug" "Release"; do
            case "$choice" in
                Debug|Release) CONFIG="$choice"; break ;;
                *) echo "  Invalid choice. Enter 1 or 2." ;;
            esac
        done
        echo
    else
        CONFIG="Debug"
    fi
fi

case "${CONFIG,,}" in
    debug)
        CMAKE_BUILD_TYPE=Debug
        if (( CXX_ONLY )); then
            BUILD_DIR=build/cxx-dev-gcc12
        else
            BUILD_DIR=build/dev-gcc12
        fi
        ;;
    release)
        CMAKE_BUILD_TYPE=Release
        if (( CXX_ONLY )); then
            BUILD_DIR=build/cxx-release-gcc12
        else
            BUILD_DIR=build/release-gcc12
        fi
        ;;
    *)
        echo "error: unknown configuration '$CONFIG'" >&2
        echo >&2
        usage >&2
        exit 1
        ;;
esac

CXX_COMPILER="${CXX:-/usr/bin/g++-12}"

if ! command -v "$CXX_COMPILER" >/dev/null 2>&1; then
    echo "error: C++ compiler '$CXX_COMPILER' not found." >&2
    echo "       Set CXX=/path/to/g++ if you need a different compiler." >&2
    exit 1
fi

cmake_args=(
  -S .
  -B "$BUILD_DIR"
  -G "Unix Makefiles"
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
  -DCMAKE_CXX_COMPILER="$CXX_COMPILER"
)

if (( CXX_ONLY )); then
    cmake_args+=(
      -DDRAMBENDER_BUILD_PYTHON=OFF
    )
else
    VENV_DIR="${VENV_DIR:-.venv}"
    if [[ "$VENV_DIR" = /* ]]; then
        VENV_PYTHON="$VENV_DIR/bin/python"
    else
        VENV_PYTHON="$(pwd)/$VENV_DIR/bin/python"
    fi

    if [[ ! -x "$VENV_PYTHON" ]]; then
        echo "error: Python-enabled build requires $VENV_PYTHON." >&2
        echo "       Run 'bash setup_venv.sh' first, or set VENV_DIR=/path/to/venv." >&2
        exit 1
    fi

    cmake_args+=(
      -DPython_EXECUTABLE="$VENV_PYTHON"
      -DDRAMBENDER_BUILD_PYTHON=ON
      -DDRAMBENDER_PYTHON_PACKAGE_DIR="$(pwd)/python/drambender"
    )
fi

echo "==> Configuring $CMAKE_BUILD_TYPE build in $BUILD_DIR"
cmake "${cmake_args[@]}"

echo "==> Building ($CMAKE_BUILD_TYPE)"
cmake --build "$BUILD_DIR"
