# RISC-V — RV64 standard integer calling convention (Linux)

RV32 uses the same register names and role assignments; only the width (`lw`/`sw` vs `ld`/`sd`, 4-byte vs 8-byte slots) changes. Assume RV64 unless told otherwise.

## Registers (ABI names — always use these, not xN, for readability)
| Reg | ABI name | Role | Save convention |
|---|---|---|---|
| x0 | zero | hardwired constant 0 | — |
| x1 | ra | return address (set by `jal`/`jalr`) | caller-saved |
| x2 | sp | stack pointer | (special) |
| x3 | gp | global pointer | — |
| x4 | tp | thread pointer | — |
| x5-x7 | t0-t2 | temporaries | caller-saved |
| x8 | s0/fp | saved reg / frame pointer | **callee-saved** |
| x9 | s1 | saved reg | **callee-saved** |
| x10-x11 | a0-a1 | args 1-2, also return value(s) | caller-saved |
| x12-x17 | a2-a7 | args 3-8 | caller-saved |
| x18-x27 | s2-s11 | saved regs | **callee-saved** |
| x28-x31 | t3-t6 | temporaries | caller-saved |

Float args (if F/D extension present): fa0-fa7, similarly named saved/temp float regs.

## Calling convention rules
- Args 1-8 integer: a0-a7. Return value: a0 (a0:a1 for wide/128-bit return).
- **SP must be 16-byte aligned** at every point where a call could occur.
- `jal`/`jalr` only writes `ra` — like ARM64, there's **no automatic stack push**. If your function calls anything else, you must explicitly save `ra` (and any saved regs you use) to the stack yourself.
- Callee-saved: s0-s11 (and ra, if you clobber it by calling further).
- Caller-saved: ra, t0-t6, a0-a7 — assume clobbered across any `call`/`jal` to another function.

## Standard prologue / epilogue
```asm
addi sp, sp, -16
sd   ra, 8(sp)
sd   s0, 0(sp)
# ... body ...
ld   ra, 8(sp)
ld   s0, 0(sp)
addi sp, sp, 16
ret
```

## Syscalls (Linux RV64)
Syscall number in `a7`; args in `a0-a5`. Trigger with `ecall`. Return value in `a0` (negative = `-errno`).

## Assemble, link, inspect
```bash
# native riscv64 host:
as file.s -o file.o && ld file.o -o file
# cross-assembling from x86-64 host (install once):
sudo apt-get install -y binutils-riscv64-linux-gnu qemu-user
riscv64-linux-gnu-as file.s -o file.o
riscv64-linux-gnu-ld file.o -o file
riscv64-linux-gnu-objdump -d file
qemu-riscv64 ./file; echo "exit: $?"
```
