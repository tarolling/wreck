---
name: assembly-programming
description: Write, debug, and verify hand-written assembly code (x86-64, ARM64, or RISC-V) and reason precisely about function-call ABIs, registers, and calling conventions. Use this whenever the user asks to write assembly by hand, work with a calling convention at the machine level, hand-optimize a routine in asm, write inline asm inside C, write a bootloader/kernel entry point, or debug why hand-written assembly is crashing or misbehaving. Load this before writing any .s/.asm file or inline asm block, even if the user doesn't say "assembly" explicitly (e.g. "write this directly in machine code", "no compiler, raw asm", "what registers does this clobber").
---

# Assembly Programming

**Core principle: don't try to be a mental compiler.** Register liveness, stack alignment, and ABI edge cases are exactly the kind of many-step state-tracking problem where LLMs quietly drift and produce plausible-looking but wrong code. The fix isn't "think harder" — it's to always route through a real toolchain and treat its output as ground truth, the same way a human assembly programmer would never trust code they haven't assembled and run.

## The loop (always follow this, don't skip steps)

1. **Pin down target arch + OS/ABI.** Ask if ambiguous: x86-64 (SysV Linux/macOS, or Windows x64) / ARM64 (AAPCS64) / RISC-V (RV64). Then load the matching file in `reference/` before writing any code — don't rely on memory for register roles or ABI rules.
2. **Write the smallest testable unit first.** One function, not a whole program. Bigger units multiply the chance of an untracked mistake.
3. **Assemble it for real.** Use `scripts/assemble_and_run.sh <arch> <file.s>`, or the manual commands in that arch's reference file. If a cross-arch toolchain/qemu isn't installed, install it (commands are in the reference file) — don't skip verification because the tool isn't present yet.
4. **Disassemble what actually got encoded** (`objdump -d`) and compare against intent. Assemblers sometimes accept syntax that doesn't do what you assumed.
5. **Run it** and check actual behavior (exit code, register/memory state via gdb/lldb, or qemu-user for cross-arch) — not what you assume the code does.
6. **For non-trivial logic, cross-check against a real compiler.** Write the equivalent C, compile with `gcc -S -O0 -o - file.c`, and diff for stack layout / register usage sanity — not to copy verbatim, but to catch ABI mistakes you'd otherwise miss.
7. **Iterate until it actually passes.** Never tell the user asm code is correct without having run it in this session.

## Reference files (load only the one you need)
- `reference/x86-64.md` — registers, SysV ABI, syscalls, AT&T syntax
- `reference/arm64.md` — registers, AAPCS64, syscalls
- `reference/riscv64.md` — registers, RISC-V calling convention, syscalls

## Common failure modes — actively guard against these
- Stack misalignment at `call`/`bl`/`jal` sites (the single biggest source of segfaults in hand-written asm)
- Clobbering a caller-saved register across a call without saving it first
- Forgetting to restore callee-saved registers before returning
- Sign- vs zero-extension mismatches when narrowing/widening values
- Off-by-one in stack frame size vs. what's actually pushed/popped
- Mixing operand-order mental models (AT&T x86 is `src, dst`; Intel x86, ARM64, and RISC-V are `dst, src` — state which convention you're using at the top of the file and stay consistent)

## Scripts
- `scripts/assemble_and_run.sh <x86-64|arm64|riscv64> <file.s>` — assembles, links, disassembles, and runs (natively or under qemu-user for cross-arch)
- `scripts/verify.sh <binary> [gdb-script]` — objdump + optional scripted gdb session for register/memory inspection

## Style notes
Don't write hundreds of lines of asm in one shot — build up in small, individually-verified pieces, the same way you'd build up any other program incrementally. Comment each function with its calling convention (which regs hold which args, what's clobbered, what's preserved) since that context isn't visible from the code the way it is in a high-level language.
