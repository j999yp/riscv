# Simple risc-v core by j999yp
- 仅实现了RV32I指令集
- 五级流水线（Fetch, Decode, Excute, Memory Access, Write Back）
- 简单的分支预测（Fetch阶段实现）

|branch taken|should branch|nop|
|:-:|:-:|:-:|
|√|√|2|
|√|×|5|
|×|√|5|
|×|×|0|

- 指令和数据存放在同一内存里（冯诺依曼结构），包含指令读取接口、数据读取接口、数据存储接口，三者都为sync
- Fetch使用三个时钟周期（fu---pc--->mem, mem---inst--->inst_buffer, inst_buffer---inst--->du）
- Memory Access使用两个时钟周期（ex---addr--->mem, mem---data--->ma）
- 实现了ex->ex, ma->ex, wb->ex的bypassing，不会导致流水线中断
- 使用iverilog仿真，留出内存接口方便verilator仿真
- 通过riscof合规性测试

# 参考文档
- [Designing RISC-V CPU from scratch – Part 1: Getting hold of the ISA](https://chipmunklogic.com/digital-logic-design/designing-pequeno-risc-v-cpu-from-scratch-part-1-getting-hold-of-the-isa/)
- [RISC-V ISA Manual, version 20240411](https://github.com/riscv/riscv-isa-manual/releases/tag/20240411)
