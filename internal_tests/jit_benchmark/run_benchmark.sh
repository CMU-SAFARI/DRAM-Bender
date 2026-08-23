#!/usr/bin/env bash
# Run the single_sided_rowhammer benchmark across C++ -O3 and Python, then
# print a side-by-side runtime + correctness table.
#
# Usage:
#   bash internal_tests/jit_benchmark/run_benchmark.sh
#   bash internal_tests/jit_benchmark/run_benchmark.sh --start-row 200 --num-victims 64 --hammer-count 250000
#
# Any CLI args are forwarded verbatim to every variant. Benchmarks use MI1
# row mapping (see internal_tests/jit_benchmark/single_sided_rowhammer_bench.{py,cpp}).
#
# The *_bench.{py,cpp} sources are the instrumented counterparts of the clean
# reference examples in examples.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CPP_BIN="$REPO_ROOT/build/release/drambender_board_single_sided_rowhammer_bench"
PYTHON="$REPO_ROOT/.venv/bin/python"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[[ -x "$CPP_BIN" ]] || die "C++ benchmark binary not found at $CPP_BIN
       configure with: -DDRAMBENDER_BUILD_BOARD_BENCHMARKS=ON
       build with: cmake --build $REPO_ROOT/build/release --target drambender_board_single_sided_rowhammer_bench"
[[ -x "$PYTHON" ]]  || die "python not found at $PYTHON"

OUT_DIR="$(mktemp -d)"
trap 'rm -rf "$OUT_DIR"' EXIT
CPP_OUT="$OUT_DIR/cpp.txt"
PY_OUT="$OUT_DIR/py.txt"

hr()   { local n=${1:-72}; printf '%0.s=' $(seq 1 "$n"); echo; }
thin() { local n=${1:-72}; printf '%0.s-' $(seq 1 "$n"); echo; }

hr
echo "DRAMBender single_sided_rowhammer benchmark comparison"
hr
printf '  %-14s %s\n' 'C++ binary:' "$CPP_BIN"
printf '  %-14s %s\n' 'Python:'     "$PYTHON"
if (( $# > 0 )); then
  printf '  %-14s %s\n' 'CLI args:'   "$*"
else
  printf '  %-14s %s\n' 'CLI args:'   "(none — defaults: --start-row 81 --num-victims 30 --hammer-count 500000)"
fi
echo

run_stage() {
  local label="$1" out="$2"
  shift 2
  printf '[%-10s] running...\n' "$label"
  local t0 t1 rc
  t0=$(date +%s.%N)
  "$@" > "$out" 2>&1
  rc=$?
  t1=$(date +%s.%N)
  printf '[%-10s] exit=%d  wall=%.3fs\n' "$label" "$rc" \
    "$(awk -v a="$t0" -v b="$t1" 'BEGIN{print b-a}')"
  # Show Result + runtime breakdown block only (skip per-row bitflip lines).
  awk '/^Result:/ { show=1 } show' "$out"
  echo
}

run_stage 'C++ -O3' "$CPP_OUT" "$CPP_BIN" "$@"
run_stage 'Python'  "$PY_OUT"  "$PYTHON" "$SCRIPT_DIR/single_sided_rowhammer_bench.py" "$@"

# ---------------------------------------------------------------------------
# Parse per-phase ms/iter out of the "Runtime breakdown" section.
# ---------------------------------------------------------------------------
extract_phases() {
  awk '
    /Runtime breakdown/ { in_block=1; next }
    /^$/ { in_block=0 }
    in_block {
      for (i = 2; i <= NF; ++i) {
        if ($i == "ms/iter") { print $1, $(i-1); break }
      }
    }
  ' "$1"
}

get_field() {
  local dict="$1" phase="$2"
  echo "$dict" | awk -v p="$phase" '$1 == p { print $2; exit }'
}

get_result() {
  grep -E "^Result:" "$1" | tail -1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

cpp_phases=$(extract_phases "$CPP_OUT")
py_phases=$(extract_phases "$PY_OUT")

cpp_result=$(get_result "$CPP_OUT")
py_result=$(get_result "$PY_OUT")

print_row() {
  local name="$1" cpp_key="$2" py_key="$3"
  local cv pv
  cv=$(get_field "$cpp_phases" "$cpp_key")
  pv=$(get_field "$py_phases"  "$py_key")
  printf '  %-10s  %10s  %10s\n' "$name" "${cv:-—}" "${pv:-—}"
}

hr
echo "Summary — ms/iter (lower is better)"
hr
printf '  %-10s  %10s  %10s\n' 'phase' 'C++ -O3' 'Python'
thin
print_row 'build'    'build'   'build'
print_row 'execute'  'execute' 'execute'
print_row 'recv/rb'  'receive' 'readback'
print_row 'sync'     'sync'    'sync'
print_row 'count'    'count'   'count'
thin
print_row 'TOTAL'    'TOTAL'   'TOTAL'
hr

echo
hr
echo "Correctness"
hr
printf '  %-10s %s\n' 'C++ -O3:' "${cpp_result:-<no Result line>}"
printf '  %-10s %s\n' 'Python:'  "${py_result:-<no Result line>}"
hr
echo
echo "Full per-run logs:"
printf '  C++ -O3:  %s\n' "$CPP_OUT"
printf '  Python:   %s\n' "$PY_OUT"
echo "(logs are deleted on script exit; rerun with TMPDIR=/tmp to persist elsewhere)"
