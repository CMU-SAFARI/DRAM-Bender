#!/bin/bash

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") [debug|release]

Configure and build DRAMInspector. If no argument is given and stdin is a
terminal, you will be prompted to choose a configuration.

  Debug   -> build/dev-gcc12     (CMAKE_BUILD_TYPE=Debug)
  Release -> build/release-gcc12 (CMAKE_BUILD_TYPE=Release, -O3 -DNDEBUG)
EOF
}

CONFIG="${1:-}"

case "$CONFIG" in
    -h|--help) usage; exit 0 ;;
esac

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
        BUILD_DIR=build/dev-gcc12
        ;;
    release)
        CMAKE_BUILD_TYPE=Release
        BUILD_DIR=build/release-gcc12
        ;;
    *)
        echo "error: unknown configuration '$CONFIG'" >&2
        echo >&2
        usage >&2
        exit 1
        ;;
esac

echo "==> Configuring $CMAKE_BUILD_TYPE build in $BUILD_DIR"

cmake -S . -B "$BUILD_DIR" \
  -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
  -DCMAKE_C_COMPILER=/usr/bin/gcc-12 \
  -DCMAKE_CXX_COMPILER=/usr/bin/g++-12 \
  -DPython_EXECUTABLE="$(pwd)/.venv/bin/python" \
  -DDRAMINSPECTOR_BUILD_PYTHON=ON \
  -DDRAMINSPECTOR_PYTHON_PACKAGE_DIR="$(pwd)/python/draminspector"

echo "==> Building ($CMAKE_BUILD_TYPE)"
cmake --build "$BUILD_DIR"
