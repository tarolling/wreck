#!/usr/bin/env bash
# Inspect a built binary: disassembly, file info, and optionally a scripted
# gdb session (e.g. to check register state at a breakpoint).
# Usage: verify.sh <binary> [gdb-commands-file]
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <binary> [gdb-commands-file]" >&2
  exit 1
fi

BIN="$1"
GDB_SCRIPT="${2:-}"

echo "--- file ---"
file "$BIN"

echo "--- objdump -d ---"
objdump -d "$BIN"

if [ -n "$GDB_SCRIPT" ]; then
  if command -v gdb >/dev/null; then
    echo "--- gdb (scripted) ---"
    gdb -batch -x "$GDB_SCRIPT" "$BIN"
  else
    echo "gdb not installed. Install with: sudo apt-get install -y gdb" >&2
  fi
fi
