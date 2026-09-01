#!/usr/bin/env bash
# Assemble, link, disassemble, and run a .s file for a given target arch.
# Usage: assemble_and_run.sh <x86-64|arm64|riscv64> <file.s>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <x86-64|arm64|riscv64> <file.s>" >&2
  exit 1
fi

ARCH="$1"
SRC="$2"
BASE="${SRC%.*}"

# Absolute paths run as-is; relative paths need ./ so the shell doesn't
# search $PATH for them.
case "$BASE" in
  /*) BIN="$BASE" ;;
  *) BIN="./$BASE" ;;
esac

run_native() {
  echo "--- objdump -d ---"
  objdump -d "$BASE"
  echo "--- run ---"
  set +e
  "$BIN"
  echo "exit code: $?"
  set -e
}

case "$ARCH" in
  x86-64)
    as "$SRC" -o "$BASE.o"
    ld "$BASE.o" -o "$BASE"
    run_native
    ;;
  arm64)
    if ! command -v aarch64-linux-gnu-as >/dev/null; then
      echo "Installing aarch64 cross toolchain + qemu-user..." >&2
      sudo apt-get update -qq && sudo apt-get install -y -qq binutils-aarch64-linux-gnu qemu-user
    fi
    aarch64-linux-gnu-as "$SRC" -o "$BASE.o"
    aarch64-linux-gnu-ld "$BASE.o" -o "$BASE"
    echo "--- objdump -d ---"
    aarch64-linux-gnu-objdump -d "$BASE"
    echo "--- run (qemu-aarch64) ---"
    set +e
    qemu-aarch64 "$BIN"
    echo "exit code: $?"
    set -e
    ;;
  riscv64)
    if ! command -v riscv64-linux-gnu-as >/dev/null; then
      echo "Installing riscv64 cross toolchain + qemu-user..." >&2
      sudo apt-get update -qq && sudo apt-get install -y -qq binutils-riscv64-linux-gnu qemu-user
    fi
    riscv64-linux-gnu-as "$SRC" -o "$BASE.o"
    riscv64-linux-gnu-ld "$BASE.o" -o "$BASE"
    echo "--- objdump -d ---"
    riscv64-linux-gnu-objdump -d "$BASE"
    echo "--- run (qemu-riscv64) ---"
    set +e
    qemu-riscv64 "$BIN"
    echo "exit code: $?"
    set -e
    ;;
  *)
    echo "Unknown arch '$ARCH' (expected x86-64, arm64, or riscv64)" >&2
    exit 1
    ;;
esac
