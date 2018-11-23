/*
###############################################################################
# Copyright (c) 2018, PulseRain Technology LLC 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
###############################################################################
*/

`ifndef RV2T_COMMON_VH
`define RV2T_COMMON_VH

`define XLEN                (32)
`define XLEN_BYTES          (`XLEN / 8)


`define PC_BITWIDTH         (`XLEN)
`define NUM_OF_REG          (32)
`define REG_ADDR_BITS       ($clog2(`NUM_OF_REG))

// The number of bits defined in specification
`define CSR_BITS            (12)  

`define RV32I_NOP           (32'h00000013)

`define CMD_LOAD            (5'b00000)
`define CMD_LOAD_FP         (5'b00001)
`define CMD_MISC_MEM        (5'b00011)
`define CMD_OP_IMM          (5'b00100)
`define CMD_AUIPC           (5'b00101)
`define CMD_IMM_32          (5'b00110)
`define CMD_STORE           (5'b01000)
`define CMD_STORE_FP        (5'b01001)
`define CMD_AMO             (5'b01011)
`define CMD_OP              (5'b01100)
`define CMD_LUI             (5'b01101)
`define CMD_OP_32           (5'b01110)
`define CMD_MADD            (5'b10000)
`define CMD_MSUB            (5'b10001)
`define CMD_NMSUB           (5'b10010)
`define CMD_NMADD           (5'b10011)
`define CMD_OP_FP           (5'b10100)
`define CMD_BRANCH          (5'b11000)
`define CMD_JALR            (5'b11001)
`define CMD_JAL             (5'b11011)
`define CMD_SYSTEM          (5'b11100)


`define ALU_ADD_SUB         (3'b000)
`define ALU_SLL             (3'b001)
`define ALU_SLT             (3'b010)
`define ALU_SLTU            (3'b011)
`define ALU_XOR             (3'b100)
`define ALU_SRL_SRA         (3'b101)
`define ALU_OR              (3'b110)
`define ALU_AND             (3'b111)

`define RV32M_MUL           (3'b000)
`define RV32M_MULH          (3'b001)
`define RV32M_MULHSU        (3'b010)
`define RV32M_MULHU         (3'b011)
`define RV32M_DIV           (3'b100)
`define RV32M_DIVU          (3'b101)
`define RV32M_REM           (3'b110)
`define RV32M_REMU          (3'b111)


`define BRANCH_BEQ          (3'b000)
`define BRANCH_BNE          (3'b001)
`define BRANCH_BLT          (3'b100)
`define BRANCH_BGE          (3'b101)
`define BRANCH_BLTU         (3'b110)
`define BRANCH_BGEU         (3'b111)

`define SYSTEM_CSRRW        (3'b001)
`define SYSTEM_CSRRS        (3'b010)
`define SYSTEM_CSRRC        (3'b011)
`define SYSTEM_CSRRWI       (3'b101)
`define SYSTEM_CSRRSI       (3'b110)
`define SYSTEM_CSRRCI       (3'b111)

`define SYSTEM_ECALL_EBREAK (3'b000)

`define WIDTH_8_BITS        (2'b00)
`define WIDTH_16_BITS       (2'b01)
`define WIDTH_32_BITS       (2'b10)


//====================================================================================================================
//  CSR (Control and Status Registers)
//====================================================================================================================

`define PULSERAIN_JEDEC_VENDOR_ID   (32'h000005DE)
`define PULSERAIN_RV2T_ARCH_ID      (32'h00200007)
`define PULSERAIN_RV2T_IMPLEMENT_ID (32'h0A008964)
`define PULSERAIN_RV2T_ISA          (32'h40000100)
`define PULSERAIN_RV2T_HART_ID      (32'h00000000)

// The actual CSR address bits used in the implementation
`define CSR_ADDR_BITS               (`CSR_BITS)

//----------------------------------------------------------------------------
//  Machine Information Register
//----------------------------------------------------------------------------

`define CSR_MVENDORID   (12'hF11)    // Vendor ID
`define CSR_MARCHID     (12'hF12)    // Architecture ID
`define CSR_MIMPID      (12'hF13)    // Implementation ID
`define CSR_HARTID      (12'hF14)    // Hardware Thread ID

//----------------------------------------------------------------------------
//  Machine Trap Setup
//----------------------------------------------------------------------------

`define CSR_MSTATUS     (12'h300)    // Machine Status Register
`define CSR_MISA        (12'h301)    // ISA and extension
`define CSR_MEDELEG     (12'h302)    // Machine exception delegation register
`define CSR_MIDELEG     (12'h303)    // Machine interrupt delegation register
`define CSR_MIE         (12'h304)    // Machine interrupt-enable register
`define CSR_MTVEC       (12'h305)    // Machine trap-handler base address
`define CSR_MCYCLE      (12'hB00)    // Machine mcycle
`define CSR_MCYCLEH     (12'hB80)    // Machine mcycleh
`define CSR_MINSTRET    (12'hB02)    // Machine Instructions-retired counter
`define CSR_MINSTRETH   (12'hB82)    // Machine Upper 32 bits of minstret, RV32I only




//----------------------------------------------------------------------------
//  Machine Trap Handling
//----------------------------------------------------------------------------

`define CSR_MSCRATCH    (12'h340)    // Scratch register for machine trap handlers
`define CSR_MEPC        (12'h341)    // Machine exception program counter
`define CSR_MCAUSE      (12'h342)    // Machine trap cause
`define CSR_MTVAL       (12'h343)    // Machine bad address or instruction
`define CSR_MIP         (12'h344)    // Machine interrupt pending



//----------------------------------------------------------------------------
//  load / store width
//----------------------------------------------------------------------------
`define WIDTH_8         (3'b000)
`define WIDTH_16        (3'b001)
`define WIDTH_16U       (3'b101)
`define WIDTH_32        (3'b010)
`define WIDTH_64        (3'b011)
`define WIDTH_128       (3'b100)
`define WIDTH_256       (3'b101)
`define WIDTH_512       (3'b110)
`define WIDTH_1024      (3'b111)


//----------------------------------------------------------------------------
//  exception code
//----------------------------------------------------------------------------
`define EXCEPTION_CODE_BITS                 (4)

`define EXCEPTION_INSTRUCTION_ADDR_MISALIGN (4'h0)
`define EXCEPTION_INSTRUCTION_ACCESS_FAULT  (4'h1)
`define EXCEPTION_ILLEGAL_INSTRUCTION       (4'h2)
`define EXCEPTION_BREAKPOINT                (4'h3)
`define EXCEPTION_LOAD_ADDR_MISALIGN        (4'h4)
`define EXCEPTION_LOAD_ACCESS_FAULT         (4'h5)
`define EXCEPTION_STORE_ADDR_MISALIGN       (4'h6)
`define EXCEPTION_STORE_ACCESS_FAULT        (4'h7)
`define EXCEPTION_ENV_CALL_FROM_U_MODE      (4'h8)
`define EXCEPTION_ENV_CALL_FROM_S_MODE      (4'h9)
`define EXCEPTION_ENV_CALL_FROM_M_MODE      (4'hB)
`define EXCEPTION_INSTRUCTION_PAGE_FAULT    (4'hC)
`define EXCEPTION_LOAD_PAGE_FAULT           (4'hD)
`define EXCEPTION_STORE_PAGE_FAULT          (4'hF)

`define INTERRUPT_MACHINE_TIMER             (4'h7)

`include "config.vh"

`define MTIME_CYCLE_PERIOD                  (`MCU_MAIN_CLK_RATE / 1000000)

`define MTIME_CYCLE_PERIOD_BITS             ($clog2(`MTIME_CYCLE_PERIOD))                        

// mem space 0x80000000
`define MEM_SPACE_BIT                       (`XLEN - 1)

// reg space 0x20000000
`define REG_SPACE_BIT                       (`XLEN - 3)

`endif
