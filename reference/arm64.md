# ARM64 / AArch64 — AAPCS64 (Linux / macOS)

macOS (Apple Silicon) mostly follows AAPCS64 but reserves x18 strictly and has stricter stack-alignment enforcement at every public function boundary (not just call sites) — if targeting macOS, be extra careful with alignment on every `ret`, not just `bl`.

## Registers
| Reg | Role | Save convention |
|---|---|---|
| x0-x7 | args 1-8 (int/ptr); return value in x0 (+x1 for 128-bit) | caller-saved |
| x8 | indirect-result register; **Linux syscall number** | caller-saved |
| x9-x15 | scratch | caller-saved |
| x16-x17 | intra-procedure-call scratch (IP0/IP1) | caller-saved |
| x18 | platform register — **avoid using**, reserved on some OSes (esp. macOS) | — |
| x19-x28 | general purpose | **callee-saved** |
| x29 (fp) | frame pointer | **callee-saved** |
| x30 (lr) | link register — holds return address after `bl` | caller must save if calling further |
| sp | stack pointer | (special) |

`w0`-`w30` are the 32-bit views of the same registers. Float/vector args: v0-v7, return in v0.

## Calling convention rules
- Args 1-8 integer/pointer: x0-x7. Args 9+ on the stack. Float/double: v0-v7.
- Return value: x0 (x1 too for values >64 bits, up to 128).
- **SP must be 16-byte aligned at every public function boundary** — at entry and at every `bl`/`ret`. Unlike x86, there's no "off by 8 after call" quirk to remember — just keep sp%16==0 throughout.
- `bl` does **not** push anything to the stack automatically — it just writes the return address into `x30`/`lr`. If your function calls anything else (a "non-leaf" function), you must explicitly save `lr` (and typically `fp`) to the stack yourself, or the nested call will overwrite it.
- Callee-saved: x19-x28, and x29/x30 if you use them and call further.
- Caller-saved (assume clobbered by any `bl`): x0-x17.

## Standard prologue / epilogue (non-leaf function)
```asm
stp x29, x30, [sp, #-16]!   // save fp+lr, pre-decrement sp by 16 (stays aligned)
mov x29, sp
// ... body, may contain further bl instructions ...
ldp x29, x30, [sp], #16
ret
```
A **leaf function** (calls nothing else) doesn't need to save lr/fp at all if it doesn't touch callee-saved regs — but if unsure, save them; the cost is negligible next to the debugging cost of a bug from skipping it.

## Syscalls (Linux)
Syscall number in `x8`; args in `x0-x5`. Trigger with `svc #0`. Return value in `x0` (negative = `-errno`).

## Assemble, link, inspect
```bash
# native arm64 host:
as file.s -o file.o && ld file.o -o file
# cross-assembling from x86-64 host (install once):
sudo apt-get install -y binutils-aarch64-linux-gnu qemu-user
aarch64-linux-gnu-as file.s -o file.o
aarch64-linux-gnu-ld file.o -o file
aarch64-linux-gnu-objdump -d file
qemu-aarch64 ./file; echo "exit: $?"
```
