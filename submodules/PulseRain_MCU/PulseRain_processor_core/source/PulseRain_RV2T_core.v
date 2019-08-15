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

`include "RV2T_common.vh"

`default_nettype none

module PulseRain_RV2T_core (

    //=====================================================================
    // clock and reset
    //=====================================================================
        input   wire                                            clk,                          
        input   wire                                            reset_n,                      
        input   wire                                            sync_reset,

    
    //=====================================================================
    // Interface Onchip Debugger
    //=====================================================================
      //==  input   wire                                            run1_pause0,

        input   wire                                            ocd_read_enable,
        input   wire                                            ocd_write_enable,
        
        input   wire  [`MEM_ADDR_BITS - 1 : 0]                  ocd_rw_addr,
        input   wire  [`XLEN - 1 : 0]                           ocd_write_word,
        
        output  wire                                            ocd_mem_enable_out,
        output  wire  [`XLEN - 1 : 0]                           ocd_mem_word_out,        
        
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  ocd_reg_read_addr,
        input   wire                                            ocd_reg_we,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  ocd_reg_write_addr,
        input   wire  [`XLEN - 1 : 0]                           ocd_reg_write_data,

    //=====================================================================
    // UARAT
    //=====================================================================
        output wire                                             start_TX,
        output wire [7 : 0]                                     tx_data,
        input  wire                                             tx_active,
        
    //=====================================================================
    // Interface for init/start
    //=====================================================================
        input   wire                                            start,
        input   wire  [`PC_BITWIDTH - 1 : 0]                    start_address,
        
        output  wire  [31 : 0]                                  peek_pc,
        output  wire  [31 : 0]                                  peek_ir,
        
        
        output  wire [`MEM_ADDR_BITS - 1 : 0]                   mem_addr,
        output  wire [`XLEN_BYTES - 1 : 0]                      mem_write_en,
        output  wire [`XLEN - 1 : 0]                            mem_write_data,
        
        input   wire [`XLEN - 1 : 0]                            mem_read_data,
        
        output  wire                                            processor_paused
            
);
     
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire                                            csr_read_en_out;
        wire  [`XLEN - 1 : 0]                           csr_read_data_out;
        
        wire                                            mem_enable_out;
        wire  [`XLEN - 1 : 0]                           mem_word_out;

        wire  [`REG_ADDR_BITS - 1 : 0]                  reg_file_read_rs1_addr;
        wire  [`REG_ADDR_BITS - 1 : 0]                  reg_file_read_rs2_addr;
        
        wire  [`XLEN - 1 : 0]                           reg_file_read_rs1_data_out;
        wire  [`XLEN - 1 : 0]                           reg_file_read_rs2_data_out;
        
        wire                                            reg_file_write_enable;
        wire  [`REG_ADDR_BITS - 1 : 0]                  reg_file_write_addr;
        wire  [`XLEN - 1 : 0]                           reg_file_write_data;
                
        wire                                            fetch_init;
        wire  [`PC_BITWIDTH - 1 : 0]                    fetch_init_addr;
        wire                                            fetch_next;
        
        wire                                            fetch_enable_out;
        wire  [`XLEN - 1 : 0]                           fetch_IR_out;
        wire  [`PC_BITWIDTH - 1 : 0]                    fetch_PC_out;
    
        wire                                            fetch_read_mem_enable;
        wire  [`PC_BITWIDTH - 1 : 0]                    fetch_read_mem_addr;
        
        wire                                            decode_enable;
        
        wire  [`REG_ADDR_BITS - 1 : 0]                  rs1;
        wire  [`REG_ADDR_BITS - 1 : 0]                  rs2;
        
        wire  [`XLEN - 1 : 2]                           decode_IR_out ;
        wire  [`PC_BITWIDTH - 1 : 0]                    decode_PC_out ;
        
        wire  [`CSR_BITS - 1 : 0]                       decode_csr;
        wire                                            decode_csr_enable;
        
        wire                                            decode_ctl_load_X_from_rs1;
        wire                                            decode_ctl_load_Y_from_rs2;
        wire                                            decode_ctl_load_Y_from_imm_12;
        wire                                            decode_ctl_load_Y_from_store_offset_12;
        wire                                            decode_ctl_save_to_rd;
        wire                                            decode_ctl_ALU_FUNCT3;
        wire                                            decode_ctl_MUL_DIV_FUNCT3;
        wire                                            decode_ctl_LUI;
        wire                                            decode_ctl_AUIPC;
        wire                                            decode_ctl_JAL;
        wire                                            decode_ctl_JALR;
        wire                                            decode_ctl_BRANCH;
        wire                                            decode_ctl_LOAD;
        wire                                            decode_ctl_STORE;
        wire                                            decode_ctl_SYSTEM;
        wire                                            decode_ctl_CSR;
        wire                                            decode_ctl_CSR_write;
        wire                                            decode_ctl_MISC_MEM;
        wire                                            decode_ctl_MRET;
        wire                                            decode_ctl_WFI;
        
        wire                                            exe_ctl_save_to_rd;
        wire                                            exe_ctl_LOAD;
        wire                                            exe_ctl_STORE;
        
        wire [`REG_ADDR_BITS - 1 : 0]                   exe_rd_addr_out;
        wire [`XLEN - 1 : 0]                            exe_data_out;
        
        wire                                            exe_enable ; 
        wire                                            data_access_enable;
        
        wire                                            data_access_reg_we;
        wire [`XLEN - 1 : 0]                            data_access_reg_data_to_write;
        wire [`REG_ADDR_BITS - 1 : 0]                   data_access_reg_addr;
        
        wire                                            exe_branch_active;
        wire [`PC_BITWIDTH - 1 : 0]                     exe_branch_addr;
        wire                                            exe_jalr_active;
        wire [`PC_BITWIDTH - 1 : 0]                     exe_jalr_addr;
        wire                                            exe_jal_active;
        wire [`PC_BITWIDTH - 1 : 0]                     exe_jal_addr;
        
        wire                                            exe_load_active;
        wire                                            exe_store_active;
        wire [`XLEN - 1 : 0]                            exe_data_to_store;
        wire [`XLEN - 1 : 0]                            exe_mem_access_addr;
        wire                                            exe_mem_access_unaligned;
        wire                                            exe_unaligned_read;
        wire [2 : 0]                                    exe_width_load_store;
        wire                                            exe_reg_ctl_CSR;
        wire                                            exe_reg_ctl_CSR_write;
        wire [`CSR_BITS - 1 : 0]                        exe_csr_addr;
        
        wire  [`XLEN - 1 : 2]                           exe_IR_out;
        wire  [`PC_BITWIDTH - 1 : 0]                    exe_PC_out;
        
        wire                                            data_access_mem_re;
        wire [`XLEN_BYTES - 1 : 0]                      data_access_mem_we;
        wire [`XLEN - 1 : 0]                            data_access_mem_data_to_write;
        wire [`XLEN - 1 : 0]                            data_access_mem_addr_rw;
        
        wire                                            data_access_ctl_csr_we;
        wire [`CSR_ADDR_BITS - 1 : 0]                   data_access_ctl_csr_write_addr;
        wire [`XLEN - 1 : 0]                            data_access_ctl_csr_write_data;
        
        
        wire                                            store_done;
        wire                                            load_done;

        wire [`XLEN - 1 : 0]                            csr_new_value;
        wire [`XLEN - 1 : 0]                            csr_old_value;
        
        wire                                            exception_ecall;
        wire                                            exception_ebreak;
        wire                                            exception_alignment;

        wire                                            decode_exception_illegal_instruction;
        wire                                            csr_exception_illegal_instruction;
        
        wire                                            activate_exception;
        wire  [`EXCEPTION_CODE_BITS - 1 : 0]            exception_code;
        wire  [`XLEN - 1 : 0]                           mtvec_value;
        wire  [`XLEN - 1 : 0]                           mepc_value;
        
        wire  [`PC_BITWIDTH - 1 : 0]                    exception_PC;
        wire  [`PC_BITWIDTH - 1 : 0]                    exception_addr;
        
        wire                                            mret_active;
        
        wire                                            mul_div_active;
        wire                                            mul_div_done;

        wire                                            paused;
        wire                                            run1_pause0;

                
        wire                                            mm_reg_re;
        wire                                            mm_reg_we;
        
        wire [`XLEN - 1 : 0]                            mm_reg_data_to_write;
        wire [`MM_REG_ADDR_BITS - 1 : 0]                mm_reg_addr_rw;

        wire                                            mm_reg_enable_out;
        wire [`XLEN - 1 : 0]                            mm_reg_word_out;
        
        wire                                            timer_triggered;
        wire                                            mtie_out;
        wire                                            mie_out;
        wire                                            mtip_out;
        wire                                            is_interrupt;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Data Path
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        //---------------------------------------------------------------------
        // memory mapped registers
        //---------------------------------------------------------------------
             RV2T_mm_reg RV2T_mm_reg_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .data_read_enable  (mm_reg_re),
                .data_write_enable (mm_reg_we),
                .data_rw_addr (mm_reg_addr_rw),
                .data_write_word (mm_reg_data_to_write),
                
                .enable_out (mm_reg_enable_out),
                .word_out (mm_reg_word_out),
                
                .start_TX (start_TX),
                .tx_data (tx_data),
                .tx_active (tx_active),

                .timer_triggered (timer_triggered));

        //---------------------------------------------------------------------
        // memory
        //---------------------------------------------------------------------
            RV2T_memory RV2T_memory_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .ocd_read_enable (ocd_read_enable),
                .ocd_write_enable (ocd_write_enable),
                .ocd_rw_addr (ocd_rw_addr),
                .ocd_write_word (ocd_write_word),
                
                .code_read_enable (fetch_read_mem_enable),
                .code_read_addr (fetch_read_mem_addr [`MEM_ADDR_BITS + 1 : 2]),
                
                .data_read_enable  (data_access_mem_re),
                .data_write_enable (data_access_mem_we),
                
                .data_rw_addr (data_access_mem_addr_rw [`MEM_ADDR_BITS + 1 : 2]),
                .data_write_word (data_access_mem_data_to_write),
                
                .enable_out (mem_enable_out),
                .word_out (mem_word_out),
                
                .mem_addr       (mem_addr),
                .mem_write_en   (mem_write_en),
                .mem_write_data (mem_write_data),
                .mem_read_data  (mem_read_data));
        
            assign ocd_mem_enable_out = mem_enable_out;
            assign ocd_mem_word_out   = mem_word_out;
        
        //---------------------------------------------------------------------
        // register file
        //---------------------------------------------------------------------
            assign processor_paused = paused;
            assign run1_pause0 = ~paused;
                        
            assign reg_file_read_rs1_addr = rs1;
            assign reg_file_read_rs2_addr = run1_pause0 ? rs2 : ocd_reg_read_addr;
            
            assign reg_file_write_enable = run1_pause0 ? data_access_reg_we : ocd_reg_we;
            assign reg_file_write_addr   = run1_pause0 ? data_access_reg_addr : ocd_reg_write_addr;
            assign reg_file_write_data   = run1_pause0 ? data_access_reg_data_to_write : ocd_reg_write_data;
             
            RV2T_reg_file RV2T_reg_file_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .read_enable (fetch_enable_out),
                .read_rs1_addr (reg_file_read_rs1_addr),
                .read_rs2_addr (reg_file_read_rs2_addr),
                
                .read_en_out(),
                .read_rs1_data_out (reg_file_read_rs1_data_out),
                .read_rs2_data_out (reg_file_read_rs2_data_out),
        
                .write_enable  (reg_file_write_enable),
                .write_addr    (reg_file_write_addr),
                .write_data_in (reg_file_write_data));
                
        //---------------------------------------------------------------------
        // Control and Status Registers
        //---------------------------------------------------------------------
            RV2T_CSR RV2T_CSR_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .exe_enable (exe_enable),

                .read_enable (decode_csr_enable & exe_enable),
                .read_addr   (decode_csr),
                
                .read_en_out   (csr_read_en_out),
                .read_data_out (csr_read_data_out),
                
                .write_enable  (data_access_ctl_csr_we),
                .write_addr    (data_access_ctl_csr_write_addr),
                .write_data_in (data_access_ctl_csr_write_data),
                
                .timer_triggered (timer_triggered),
                
                .activate_exception (activate_exception),
                .is_interrupt       (is_interrupt),
                .exception_code     (exception_code),
                .exception_PC       (exception_PC),
                .exception_addr     (exception_addr),
                
                .exception_illegal_instruction (csr_exception_illegal_instruction),
                .mtvec_out (mtvec_value),
                .mepc_out  (mepc_value),
                .mtie_out  (mtie_out),
                .mie_out   (mie_out),
                .mtip_out  (mtip_out));
            
        //---------------------------------------------------------------------
        // fetch instruction
        //---------------------------------------------------------------------
            RV2T_fetch_instruction RV2T_fetch_instruction_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .fetch_init (fetch_init),
                .start_addr (fetch_init_addr),
                
                .fetch_next (fetch_next),
                
                .fetch_enable_out (fetch_enable_out),
                .IR_out (fetch_IR_out),
                .PC_out (fetch_PC_out),
                
                .mem_read_done (mem_enable_out),
                .mem_data (mem_word_out),
                
                .read_mem_enable (fetch_read_mem_enable),
                .read_mem_addr (fetch_read_mem_addr));

        //---------------------------------------------------------------------
        // instruction decode
        //---------------------------------------------------------------------
            RV2T_instruction_decode RV2T_instruction_decode_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .decode_enable (decode_enable),
                                    
                .enable_in (fetch_enable_out),
                .IR_in (fetch_IR_out),
                .PC_in (fetch_PC_out),
                
                .rs1 (rs1),
                .rs2 (rs2),
                
                .csr             (decode_csr),
                .csr_read_enable (decode_csr_enable),
                
                .IR_out (decode_IR_out),
                .PC_out (decode_PC_out),
                
                .ctl_load_X_from_rs1             (decode_ctl_load_X_from_rs1),
                .ctl_load_Y_from_rs2             (decode_ctl_load_Y_from_rs2),
                .ctl_load_Y_from_imm_12          (decode_ctl_load_Y_from_imm_12),
                .ctl_load_Y_from_store_offset_12 (decode_ctl_load_Y_from_store_offset_12),
                .ctl_save_to_rd                  (decode_ctl_save_to_rd),
                .ctl_ALU_FUNCT3                  (decode_ctl_ALU_FUNCT3),
                .ctl_MUL_DIV_FUNCT3              (decode_ctl_MUL_DIV_FUNCT3),
                .ctl_LUI                         (decode_ctl_LUI),
                .ctl_AUIPC                       (decode_ctl_AUIPC),
                .ctl_JAL                         (decode_ctl_JAL),
                .ctl_JALR                        (decode_ctl_JALR),
                .ctl_BRANCH                      (decode_ctl_BRANCH),
                .ctl_LOAD                        (decode_ctl_LOAD),
                .ctl_STORE                       (decode_ctl_STORE),
                .ctl_SYSTEM                      (decode_ctl_SYSTEM),
                .ctl_CSR                         (decode_ctl_CSR),
                .ctl_CSR_write                   (decode_ctl_CSR_write),
                .ctl_MISC_MEM                    (decode_ctl_MISC_MEM),
                .ctl_MRET                        (decode_ctl_MRET),
                .ctl_WFI                         (decode_ctl_WFI),

                .exception_illegal_instruction   (decode_exception_illegal_instruction));
                
        //---------------------------------------------------------------------
        // execution unit
        //---------------------------------------------------------------------
            RV2T_execution_unit RV2T_execution_unit_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .exe_enable (exe_enable),
         
                .enable_in (1'b0),
                .IR_in       (decode_IR_out),
                .PC_in       (decode_PC_out),
                .csr_addr_in (decode_csr),
                
                .ctl_load_Y_from_imm_12 (decode_ctl_load_Y_from_imm_12),
                .ctl_save_to_rd         (decode_ctl_save_to_rd),

                .ctl_LUI                (decode_ctl_LUI),
                .ctl_AUIPC              (decode_ctl_AUIPC),
                .ctl_JAL                (decode_ctl_JAL),
                .ctl_JALR               (decode_ctl_JALR),
                .ctl_BRANCH             (decode_ctl_BRANCH),
                .ctl_LOAD               (decode_ctl_LOAD),
                .ctl_STORE              (decode_ctl_STORE),
                .ctl_SYSTEM             (decode_ctl_SYSTEM),
                .ctl_CSR                (decode_ctl_CSR),
                .ctl_CSR_write          (decode_ctl_CSR_write),
                .ctl_MISC_MEM           (decode_ctl_MISC_MEM),
                .ctl_MRET               (decode_ctl_MRET),
                .ctl_MUL_DIV_FUNCT3     (decode_ctl_MUL_DIV_FUNCT3),
                
                .rs1_in (reg_file_read_rs1_data_out),
                .rs2_in (reg_file_read_rs2_data_out),

                .csr_in (csr_read_data_out),
         
                .enable_out (),
                .rd_addr_out (exe_rd_addr_out),
                
                .IR_out (exe_IR_out),
                .PC_out (exe_PC_out),
        
                .branch_active  (exe_branch_active),
                .branch_addr    (exe_branch_addr),
              
                .csr_new_value  (csr_new_value),
                .csr_old_value  (csr_old_value),
                .reg_ctl_save_to_rd (exe_ctl_save_to_rd),
                .data_out (exe_data_out),
                
                .load_active       (exe_load_active),
                .store_active      (exe_store_active),
                .width_load_store  (exe_width_load_store),
                .data_to_store     (exe_data_to_store),
                .mem_access_addr    (exe_mem_access_addr),
                .mem_access_unaligned   (exe_mem_access_unaligned),
                .reg_ctl_CSR       (exe_reg_ctl_CSR),
                .reg_ctl_CSR_write (exe_reg_ctl_CSR_write),
                .csr_addr_out      (exe_csr_addr),
                .ecall_active      (exception_ecall),
                .ebreak_active     (exception_ebreak),
                .mret_active       (mret_active),
                .mul_div_active    (mul_div_active),
                .mul_div_done      (mul_div_done)
                );
                
     
        //---------------------------------------------------------------------
        // data access
        //---------------------------------------------------------------------
        
            RV2T_data_access RV2T_data_access_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .data_access_enable (data_access_enable),
                
                .ctl_CSR        (exe_reg_ctl_CSR),
                .ctl_CSR_write  (exe_reg_ctl_CSR_write),
                .csr_new_value  (csr_new_value),
                .csr_old_value  (csr_old_value),
                .csr_addr       (exe_csr_addr),
                .ctl_save_to_rd (exe_ctl_save_to_rd),
                
                .rd_addr_in (exe_rd_addr_out),
                .rd_data_in (exe_data_out),
                
                .load_active      (exe_load_active),
                .store_active     (exe_store_active),
                .width_load_store (exe_width_load_store),
                .data_to_store    (exe_data_to_store),
                .mem_access_addr  (exe_mem_access_addr),
                .mem_access_unaligned  (exe_mem_access_unaligned),

                .mul_div_done     (mul_div_done),
                .ctl_reg_we (data_access_reg_we),
                .ctl_reg_data_to_write (data_access_reg_data_to_write),
                .ctl_reg_addr (data_access_reg_addr),
                
                .ctl_csr_we         (data_access_ctl_csr_we),
                .ctl_csr_write_addr (data_access_ctl_csr_write_addr),
                .ctl_csr_write_data (data_access_ctl_csr_write_data),
                 
                .mem_enable_in (mem_enable_out),
                .mem_data_in   (mem_word_out),
                
                .mm_reg_enable_in (mm_reg_enable_out),
                .mm_reg_data_in   (mm_reg_word_out),
                 
                .mem_re             (data_access_mem_re),
                .mem_we             (data_access_mem_we),
                .mem_data_to_write  (data_access_mem_data_to_write),
                .mem_addr_rw_out    (data_access_mem_addr_rw),
                .store_done (store_done),
                .load_done  (load_done),
                .exception_alignment (exception_alignment),
                
                .mm_reg_re (mm_reg_re),
                .mm_reg_we (mm_reg_we),
                
                .mm_reg_data_to_write (mm_reg_data_to_write),
                .mm_reg_addr_rw_out   (mm_reg_addr_rw));

        //---------------------------------------------------------------------
        // pipeline controller
        //---------------------------------------------------------------------
            RV2T_controller RV2T_controller_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (sync_reset),
                
                .start (start),
                .start_addr (start_address),
                
                .fetch_init (fetch_init),
                .fetch_start_addr (fetch_init_addr),
                .fetch_next (fetch_next),
                
                .mul_div_active    (mul_div_active),
                .mul_div_done      (mul_div_done),
                
                .decode_ctl_LOAD     (decode_ctl_LOAD),
                .decode_ctl_STORE    (decode_ctl_STORE),
                .decode_ctl_MISC_MEM (decode_ctl_MISC_MEM),
                
                .decode_ctl_MUL_DIV_FUNCT3 (decode_ctl_MUL_DIV_FUNCT3),

                .decode_ctl_WFI  (decode_ctl_WFI),
        
                .branch_active   (exe_branch_active),
                .branch_addr     (exe_branch_addr),
                              
                .load_active     (exe_load_active),
                .data_to_store   (exe_data_to_store),
                .mem_access_addr  (exe_mem_access_addr),
                .unaligned_write (exe_mem_access_unaligned),

                .store_done (store_done),
                .load_done  (load_done),
                
                .mret_active (mret_active),
                
                .exe_enable (exe_enable),
                .data_access_enable (data_access_enable),
   
                .PC_in      (exe_PC_out),
                .mtvec_in   (mtvec_value),
                .mepc_in    (mepc_value),
                
                .exception_storage_page_fault (1'b0),
                .exception_ecall              (exception_ecall),
                .exception_ebreak             (exception_ebreak),
                .exception_alignment          (exception_alignment),
                .timer_triggered              (mtip_out & mtie_out & mie_out),
                .is_interrupt                 (is_interrupt),
                .exception_code               (exception_code),
                .activate_exception           (activate_exception),
                .exception_PC                 (exception_PC),
                .exception_addr               (exception_addr),
                .exception_illegal_instruction (decode_exception_illegal_instruction | csr_exception_illegal_instruction),
                .paused                       (paused)
                
                );

//----------------------------------------------------------------------------
// DEBUG
//----------------------------------------------------------------------------
    assign peek_pc = exe_PC_out;
    assign peek_ir = { exe_IR_out, 2'b11 };
        
endmodule

`default_nettype wire
