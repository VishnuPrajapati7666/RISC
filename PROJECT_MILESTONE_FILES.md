# RISC-V Project Milestone File Map

This document records which files belong to each project milestone and the purpose of each file.

## Milestone 1 — Base Common Units

| File | Purpose |
|---|---|
| `rtl/common/rv32i_pkg.sv` | RV32I constants, opcodes, ALU operations, memory formats, immediate selectors, and control structures. |
| `rtl/common/alu.sv` | Arithmetic and logical execution unit. |
| `rtl/common/imm_gen.sv` | Generates I-, S-, B-, U-, and J-type immediates. |
| `rtl/common/regfile.sv` | 32-register file with x0 protection and write/read behavior. |
| `test.sv` | Common-unit sanity test. |

## Milestone 2 — Single-Cycle Core and Sanity Testbench

| File | Purpose |
|---|---|
| `rtl/core/decoder.sv` | Decodes RV32I instructions and generates control signals. |
| `rtl/core/branch_unit.sv` | Resolves branches and jumps. |
| `rtl/core/single_cycle_core.sv` | Single-cycle processor integration. |
| `rtl/memory/reference_memory.sv` | Instruction and data reference memory model. |
| `tb/single_cycle_tb.sv` | Single-cycle core self-checking testbench. |

## Milestone 3 — Five-Stage Pipeline

| File | Purpose |
|---|---|
| `rtl/core/five_stage_core.sv` | Five-stage IF, ID, EX, MEM, and WB pipeline core. |
| `tb/five_stage_tb.sv` | Pipeline testbench with arithmetic, memory, branch, and jump tests. |

## Milestone 4 — Hazards and Forwarding

| File | Purpose |
|---|---|
| `rtl/core/forwarding_unit.sv` | Selects EX/MEM and MEM/WB forwarding paths. |
| `rtl/core/hazard_unit.sv` | Detects load-use hazards and requests pipeline stalls. |
| `rtl/core/five_stage_core.sv` | Updated with forwarding, load-use stalls, branch operand forwarding, and store-data forwarding. |
| `tb/hazard_tb.sv` | Hazard regression testbench. |

## Milestone 5 — Branch Prediction Unit

| File | Purpose |
|---|---|
| `rtl/core/bpu.sv` | 16-entry two-bit dynamic branch predictor. |
| `rtl/core/five_stage_core.sv` | Updated with prediction metadata, target prediction, and misprediction recovery. |
| `tb/bpu_tb.sv` | Branch predictor unit testbench. |

## Milestone 6 — Memory Hierarchy and Caches

| File | Purpose |
|---|---|
| `rtl/memory/icache.sv` | Configurable direct-mapped or two-way instruction cache with refill support. |
| `rtl/memory/dcache.sv` | Configurable write-back, write-allocate data cache with dirty eviction and byte enables. |
| `rtl/memory/cache_arbiter.sv` | Shared memory arbiter with data-cache request priority and response routing. |
| `tb/cache_tb.sv` | Instruction-cache and data-cache regression testbench. |
| `tb/arbiter_tb.sv` | Cache-arbiter priority and response-routing testbench. |

The cache regression covers:

- Instruction-cache miss and hit behavior
- Two-way set selection
- Data-cache refill
- Data-cache write hit
- Data-cache read-after-write

The arbiter regression covers:

- Data request priority
- Data response routing
- Instruction request acceptance
- Instruction response routing

## Milestone 7 — Full SoC Integration and Verification

| File | Purpose |
|---|---|
| `rtl/core/risc_soc_top.sv` | Top-level SoC wrapper connecting the five-stage core and reference memory. |
| `rtl/core/soc_checker.sv` | SVA checker for aligned full-word stores. |
| `tb/soc_tb.sv` | Self-checking full SoC system testbench. |
| `scripts/milestone7_sim.tcl` | Vivado project and behavioral simulation setup for `soc_tb`. |
| `scripts/milestone7_synth.tcl` | Vivado synthesis, utilization-report, and timing-report setup for `risc_soc_top`. |
| `rtl/core/five_stage_core.sv` | Used by the SoC wrapper as the processor core. |
| `rtl/memory/reference_memory.sv` | Used by the SoC wrapper as the backing instruction/data memory. |

The full SoC regression verifies:

- Instruction execution
- Register write-back
- Store operation
- Load operation
- Data-memory contents
- Store-alignment assertion

Expected simulation output:

```text
MILESTONE 7: FULL SOC VERIFIED SUCCESSFULLY!
```

## Complete File List

### Common RTL

- `rtl/common/rv32i_pkg.sv`
- `rtl/common/alu.sv`
- `rtl/common/imm_gen.sv`
- `rtl/common/regfile.sv`

### Core RTL

- `rtl/core/decoder.sv`
- `rtl/core/branch_unit.sv`
- `rtl/core/single_cycle_core.sv`
- `rtl/core/five_stage_core.sv`
- `rtl/core/forwarding_unit.sv`
- `rtl/core/hazard_unit.sv`
- `rtl/core/bpu.sv`
- `rtl/core/risc_soc_top.sv`
- `rtl/core/soc_checker.sv`

### Memory RTL

- `rtl/memory/reference_memory.sv`
- `rtl/memory/icache.sv`
- `rtl/memory/dcache.sv`
- `rtl/memory/cache_arbiter.sv`

### Testbenches

- `test.sv`
- `tb/single_cycle_tb.sv`
- `tb/five_stage_tb.sv`
- `tb/hazard_tb.sv`
- `tb/bpu_tb.sv`
- `tb/cache_tb.sv`
- `tb/arbiter_tb.sv`
- `tb/soc_tb.sv`

### Vivado Scripts

- `scripts/milestone7_sim.tcl`
- `scripts/milestone7_synth.tcl`

## Verification Summary

| Milestone | Verification top | Result |
|---|---|---|
| 1 | `test` | Common-unit sanity verification |
| 2 | `single_cycle_tb` | Single-cycle core verified |
| 3 | `five_stage_tb` | Five-stage pipeline verified |
| 4 | `hazard_tb` | Hazards and forwarding verified |
| 5 | `bpu_tb` | Branch predictor verified |
| 6 | `cache_tb` | Instruction and data caches verified |
| 6 | `arbiter_tb` | Cache arbiter regression available |
| 7 | `soc_tb` | Full SoC verified successfully |
