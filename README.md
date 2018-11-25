# PulseRain Reindeer - RISCV RV32I[M] Soft CPU
----------------------------------------------
  * # Overview
PulseRain Reindeer is a soft CPU of Von Neumann architecture. It supports RISC-V RV32I[M] instruction set, and features a 2 x 2 pipeline. It strives to make a balance between speed and area, and offers a flexible choice for soft CPU across all FPGA platforms.

## Highlights - 2 x 2 Pipeline
Reindeer's pipeline is composed of 4 stages: 
  + Instruction Fetch (IF)
  + Instruction Decode (ID)
  + Instruction Execution (IE)
  + Register Write Back and Memory Access (MEM)

However, unlike traditional pipelines, Reindeer's pipeline stages are mapped to a 2 x 2 layout, as illustrated below:

![2 x 2 pipeline](https://github.com/PulseRain/Reindeer/raw/master/docs/pipeline_2x2.png "2 x 2 Pipeline")

In the 2 x 2 layout, each stage is active every other clock cycle. For the even cycle, only IF and IE stages are active, while for the odd cycle, only ID and MEM stages are active. In this way, the Instruction Fetch and Memory Access always happen on different clock cycles, thus to avoid the structural hazard caused by the single port memory. 

Thanks to using single port memory to store both code and data, the Reindeer soft CPU is quite portable and flexible across all FPGA platforms. Some FPGA platforms, like the Lattice iCE40 UltraPlus family, carry a large amount of SPRAM with very little EBR RAM. And those platforms will find themselves a good match with the PulseRain Reindeer when it comes to soft CPU.

