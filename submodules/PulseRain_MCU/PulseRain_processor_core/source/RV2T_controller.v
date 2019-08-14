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


//=============================================================================
// Remarks:
//    PulseRain RV2T is a MCU core of Von Neumann architecture. 
//=============================================================================

`include "RV2T_common.vh"

`default_nettype none

module RV2T_controller (

    //=====================================================================
    // clock and reset
    //=====================================================================
            
        input wire                                          clk,                          
        input wire                                          reset_n,                      
        input wire                                          sync_reset,
    
    
    //=====================================================================
    // interface for PC init
    //=====================================================================
        input wire                                          start,
        input wire [`PC_BITWIDTH - 1 : 0]                   start_addr,
        
    //=====================================================================
    // interface for instruction fetch
    //=====================================================================
        output reg                                          fetch_init,
        output reg [`PC_BITWIDTH - 1 : 0]                   fetch_start_addr,
        output wire                                         fetch_next,
        
        
    //=====================================================================
    // JARL / BRANCH
    //=====================================================================
        input wire                                          branch_active,
        input wire [`PC_BITWIDTH - 1 : 0]                   branch_addr,
        
    //=====================================================================
    // LOAD / STORE
    //=====================================================================
        input wire                                          decode_ctl_LOAD,
        input wire                                          decode_ctl_STORE,
        input wire                                          decode_ctl_MISC_MEM,
        input wire                                          decode_ctl_MUL_DIV_FUNCT3,
        
        input wire                                          decode_ctl_WFI,
        
        input wire                                          mul_div_active,
        input wire                                          mul_div_done,
        
        input wire                                          load_active,
        input wire [`XLEN - 1 : 0]                          data_to_store,
        input wire [`XLEN - 1 : 0]                          mem_access_addr,
        input wire                                          unaligned_write,
        
        input wire                                          store_done,
        input wire                                          load_done,
        
    //=====================================================================
    // MRET
    //=====================================================================
        
        input wire                                          mret_active,
        
    //=====================================================================
    // interface for execution unit
    //=====================================================================
        output wire                                         exe_enable,
        output wire                                         data_access_enable,

    //=====================================================================
    // exception
    //=====================================================================
        input wire  [`PC_BITWIDTH - 1 : 0]                  PC_in,
        
        input wire  [`XLEN - 1 : 0]                         mtvec_in,
        input wire  [`XLEN - 1 : 0]                         mepc_in,
        
        input wire                                          exception_storage_page_fault,
        input wire                                          exception_ecall,
        input wire                                          exception_ebreak,
        input wire                                          exception_alignment,
        input wire                                          timer_triggered, 
        input wire                                          exception_illegal_instruction,
         
        output reg                                          is_interrupt,
        output reg [`EXCEPTION_CODE_BITS - 1 : 0]           exception_code,
        output reg                                          activate_exception,
        output reg [`PC_BITWIDTH - 1 : 0]                   exception_PC,
        output reg [`PC_BITWIDTH - 1 : 0]                   exception_addr,
        
        output wire                                         paused
);

        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Signal
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            reg                                             ctl_pc_init;
            reg                                             ctl_fetch_enable;
            reg                                             ctl_exe_enable;
            reg                                             ctl_data_access_enable;
            reg                                             ctl_fetch_init_branch;
            reg                                             ctl_fetch_init_exception;
            reg                                             ctl_fetch_init_mret_active;
            reg                                             ctl_disable_data_access;
            
            reg                                             ctl_disable_data_access_reg;
            reg                                             ctl_clear_exception;
            reg                                             ctl_activate_exception;
            reg                                             ctl_instruction_addr_misalign_exception;
            reg                                             ctl_load_active;
            reg                                             ctl_store_active;
            reg                                             ctl_fetch_exe_active;
            reg                                             ctl_paused;
            reg                                             ctl_set_interrupt_active;
            reg                                             ctl_set_interrupt_active_reg;
            
            reg                                             load_active_reg;
            reg                                             store_active_reg;
            
            reg                                             first_exe;

            reg [`XLEN - 1 : 0]                             mem_access_addr_d1;
            
            wire                                            exception_active;
            wire                                            exception_active_reg;    
            reg                                             exception_storage_page_fault_reg;
            reg                                             exception_ecall_reg;
            reg                                             exception_ebreak_reg;
            reg                                             exception_instruction_addr_misalign_reg;
            reg                                             exception_alignment_reg;
            reg                                             exception_illegal_instruction_reg;
            reg                                             interrupt_active;
            
            reg                                             decode_ctl_WFI_d1;
            reg                                             ecall_active;
            
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // data path
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                assign exception_active     = 
                    exception_storage_page_fault | exception_ecall | exception_ebreak | 
                    ctl_instruction_addr_misalign_exception | exception_alignment | exception_illegal_instruction;
                assign exception_active_reg = 
                            exception_storage_page_fault_reg | exception_ecall_reg | exception_ebreak_reg |
                            exception_instruction_addr_misalign_reg | exception_alignment_reg | exception_illegal_instruction_reg;
                
                always @(posedge clk, negedge reset_n) begin : fetch_proc
                    if (!reset_n) begin
                        fetch_init       <= 0;
                        fetch_start_addr <= 0;
                        
                        ctl_disable_data_access_reg <= 0;
                        
                        exception_storage_page_fault_reg <= 0;
                        exception_ecall_reg  <= 0;
                        exception_ebreak_reg <= 0;
                        exception_instruction_addr_misalign_reg <= 0;
                        
                        exception_code <= 0;
                        
                        activate_exception <= 0;
                        
                        exception_PC   <= 0;
                        exception_addr <= 0;
                        
                        load_active_reg  <= 0;
                        store_active_reg <= 0;
                        
                        exception_alignment_reg <= 0;
                        interrupt_active <= 0;
                        
                        mem_access_addr_d1  <= 0;
            
                        ctl_set_interrupt_active_reg <= 0;
                        
                        decode_ctl_WFI_d1 <= 0;
                        is_interrupt <= 0;
                        ecall_active <= 0;
                        
                    end else begin
                        
                        decode_ctl_WFI_d1 <= decode_ctl_WFI;
                        
                        activate_exception <= ctl_activate_exception;
                        
                        mem_access_addr_d1  <= mem_access_addr;
            
                        
                        if (data_access_enable) begin
                            if (decode_ctl_WFI_d1) begin
                                exception_PC <= PC_in + 4;
                            end else begin
                                exception_PC <= PC_in;
                            end
                            
                            if (exception_alignment) begin // store exception
                                exception_addr <= mem_access_addr;
                            end else begin
                                case (1'b1) // synthesis parallel_case 
                                    branch_active : begin
                                        exception_addr <= {branch_addr[`PC_BITWIDTH - 1 : 1], 1'b0};
                                    end
                                    
                                    default : begin
                                        exception_addr <= PC_in;
                                    end
                                    
                                endcase
                            end
                        end else if (exception_alignment) begin // load exception
                            exception_addr <= mem_access_addr_d1;
                        end 
                        
                                
                        if (ctl_set_interrupt_active) begin
                            interrupt_active <= 1'b1;
                        end else if (!timer_triggered) begin
                            interrupt_active <= 0;
                        end
                        
                        ctl_set_interrupt_active_reg <= ctl_set_interrupt_active;
                        
                        if (ctl_clear_exception) begin
                            exception_storage_page_fault_reg <= 0;
                        end else if (exception_storage_page_fault) begin
                            exception_storage_page_fault_reg <= 1'b1;
                        end 
                        
                        if (ctl_clear_exception) begin
                            exception_ecall_reg <= 0;
                        end else if (exception_ecall) begin
                            exception_ecall_reg <= 1'b1;
                        end
                        
                        if (ctl_clear_exception) begin
                            exception_ebreak_reg <= 0;
                        end else if (exception_ebreak) begin
                            exception_ebreak_reg <= 1'b1;
                        end
                        
                        if (ctl_clear_exception) begin
                            exception_instruction_addr_misalign_reg <= 0;
                        end else if (ctl_instruction_addr_misalign_exception) begin
                            exception_instruction_addr_misalign_reg <= 1'b1;
                        end
                        
                        if (ctl_clear_exception) begin
                            exception_alignment_reg <= 0;
                        end else if (exception_alignment) begin
                            exception_alignment_reg <= 1'b1;
                        end
                        
                        if (ctl_clear_exception) begin
                            exception_illegal_instruction_reg <= 0;
                        end else if (exception_illegal_instruction) begin
                            exception_illegal_instruction_reg <= 1'b1;
                        end

                        if (ctl_fetch_exe_active) begin
                            load_active_reg <= 0;
                        end else if (ctl_load_active) begin
                            load_active_reg <= 1'b1;
                        end
                        
                        if (ctl_fetch_exe_active) begin
                            store_active_reg <= 0;
                        end else if (ctl_store_active) begin
                            store_active_reg <= 1'b1;
                        end
                        
                        if (exception_ecall) begin
                            ecall_active <= 1'b1;
                        end else if (mret_active) begin
                            ecall_active <= 1'b0;
                        end
                        
                        if (ctl_set_interrupt_active_reg) begin
                            exception_code <= `INTERRUPT_MACHINE_TIMER;
                            is_interrupt <= 1'b1;
                        end else begin
                            is_interrupt <= 0;
                            
                            case (1'b1) // synthesis parallel_case 
                                exception_storage_page_fault_reg : begin
                                    exception_code <= `EXCEPTION_STORE_PAGE_FAULT;
                                end

                                exception_ecall_reg : begin
                                    exception_code <= `EXCEPTION_ENV_CALL_FROM_M_MODE;
                                end
                                
                                exception_ebreak_reg : begin
                                    exception_code <= `EXCEPTION_BREAKPOINT;
                                end
                                
                                exception_instruction_addr_misalign_reg : begin
                                    exception_code <= `EXCEPTION_INSTRUCTION_ADDR_MISALIGN;
                                end
                                
                                exception_illegal_instruction_reg : begin
                                    exception_code <= `EXCEPTION_ILLEGAL_INSTRUCTION;
                                end

                                exception_alignment_reg : begin
                                    if (load_active_reg) begin
                                        exception_code <= `EXCEPTION_LOAD_ADDR_MISALIGN;
                                    end else begin
                                        exception_code <= `EXCEPTION_STORE_ADDR_MISALIGN;
                                    end
                                end
                                
                                default : begin
                                
                                end
                                
                            endcase
                        end
                        
                        fetch_init <= ctl_pc_init | ctl_fetch_init_branch | ctl_fetch_init_exception | ctl_fetch_init_mret_active;
                        
                        ctl_disable_data_access_reg <= ctl_disable_data_access;
                        
                        case (1'b1) // synthesis parallel_case 
                            ctl_pc_init : begin
                                fetch_start_addr <= {start_addr [`PC_BITWIDTH - 1 : 1], 1'b0};
                            end

                            ctl_fetch_init_branch : begin
                                fetch_start_addr <= {branch_addr [`PC_BITWIDTH - 1 : 1], 1'b0};
                            end
                            
                            ctl_fetch_init_mret_active : begin
                                fetch_start_addr <= mepc_in;
                            end
                            
                            ctl_fetch_init_exception : begin
                                if (mtvec_in [1 : 0] == 2'b00) begin
                                    fetch_start_addr <= mtvec_in;
                                end else begin
                                    fetch_start_addr <= {mtvec_in [`XLEN - 1 : 2], 2'b00} + {{(30 - `EXCEPTION_CODE_BITS){1'b0}}, exception_code, 2'b00};
                                end
                            end
                            
                            default : begin
                            
                            end

                        endcase
                        
                    end
                    
                end
                
                assign fetch_next = ctl_fetch_enable;
                
                assign exe_enable = ctl_exe_enable;
                
                assign data_access_enable = ctl_data_access_enable;
                
                always @(posedge clk, negedge reset_n) begin : first_exe_proc
                    if (!reset_n) begin
                        first_exe <= 0;
                    end else if (fetch_init) begin
                        first_exe <= 0;
                    end else if (exe_enable) begin
                        first_exe <= 1'b1;
                    end
                end
                
                assign paused = ctl_paused;
           
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // FSM
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            localparam S_INIT = 0, S_INIT_WAIT1 = 1, S_FETCH = 2, 
                       S_DECODE = 3, S_FETCH_EXE = 4, S_DECODE_DATA = 5,
                       S_STORE = 6, S_STORE_WAIT = 7, S_LOAD = 8, S_LOAD_WAIT = 9,
                       S_EXCEPTION = 10, S_EXCEPTION_REINIT = 11, S_MUL_DIV = 12,
                       S_WFI = 13, S_WFI_WAIT = 14;
            reg [14 : 0] current_state, next_state;
                  
            // Declare states
            always @(posedge clk, negedge reset_n) begin : state_machine_reg
                if (!reset_n) begin
                    current_state <= 0;
                end else if (sync_reset) begin 
                    current_state <= 0;
                end else begin
                    current_state <= next_state;
                end
            end
                
            // FSM main body
            always @(*) begin : state_machine_comb
    
                next_state = 0;
                
                ctl_pc_init = 0;
                ctl_fetch_enable = 0;
                ctl_exe_enable = 0;
                ctl_data_access_enable = 0;
                ctl_disable_data_access = 0;
                
                ctl_fetch_init_branch = 0;
                ctl_fetch_init_mret_active = 0;
                
                ctl_clear_exception = 0;
                ctl_activate_exception = 0;
                
                ctl_fetch_init_exception = 0;
                
                ctl_instruction_addr_misalign_exception = 0;
                
                ctl_load_active = 0;
                ctl_store_active = 0;
                ctl_fetch_exe_active = 0;
                
                ctl_paused = 0;
                
                ctl_set_interrupt_active = 0;
                
                case (1'b1) // synthesis parallel_case 
                    
                    current_state[S_INIT]: begin
                        ctl_paused = 1'b1;
                        
                        if (start) begin
                            ctl_pc_init = 1'b1;
                            next_state [S_INIT_WAIT1] = 1'b1;
                        end else begin
                            next_state [S_INIT] = 1'b1;
                        end
                        
                    end
                    
                    current_state[S_INIT_WAIT1]: begin
                        next_state [S_FETCH] = 1'b1;
                    end
                    
                    current_state [S_FETCH] : begin
                        next_state [S_DECODE] = 1'b1;
                    end
                    
                    current_state [S_DECODE] : begin
                        ctl_fetch_enable = 1;
                        next_state [S_FETCH_EXE] = 1'b1;
                    end
                    
                    current_state [S_FETCH_EXE] : begin
                        ctl_fetch_exe_active = 1'b1;
                        
                        ctl_data_access_enable = first_exe & (~ctl_disable_data_access_reg);
                        ctl_fetch_init_branch = branch_active & (~(branch_addr[1]));
                        ctl_fetch_init_mret_active = mret_active;
                        
                        if (timer_triggered & (~interrupt_active) & (~ecall_active)) begin
                            ctl_set_interrupt_active = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (branch_active & branch_addr[1]) begin
                            ctl_instruction_addr_misalign_exception = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if ((exception_active | exception_active_reg) & data_access_enable) begin
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (branch_active | mret_active) begin
                            next_state [S_INIT_WAIT1] = 1'b1;
                        end else begin
                            next_state [S_DECODE_DATA] = 1'b1;
                        end
                        
                    end
                    
                    current_state [S_DECODE_DATA] : begin
                        ctl_exe_enable = 1'b1; 
                        
                        if (decode_ctl_WFI) begin
                            next_state [S_WFI] = 1'b1;
                        end 
                        
                        //else if (decode_ctl_STORE) begin
                        //    next_state [S_STORE] = 1'b1;
                        //end 
                        
                        else if (decode_ctl_LOAD) begin
                            next_state [S_LOAD] = 1'b1; 
                        end else if (decode_ctl_MUL_DIV_FUNCT3) begin
                            next_state [S_MUL_DIV] = 1'b1;
                        end 
                        
                        else begin
                            ctl_fetch_enable = 1'b1; 
                            next_state [S_FETCH_EXE] = 1'b1;
                        end
                    end
                    
                    current_state [S_WFI] : begin
                        ctl_data_access_enable = 1'b1;
                        next_state [S_WFI_WAIT] = 1'b1;
                    end
                    
                    current_state [S_WFI_WAIT] : begin
                        if (timer_triggered & (~interrupt_active)) begin
                            ctl_set_interrupt_active = 1'b1;
                            next_state [S_EXCEPTION] = 1'b1;
                        end else begin
                            next_state [S_WFI_WAIT] = 1'b1;
                        end
                    end
                    
                    current_state [S_STORE] : begin
                        ctl_data_access_enable = 1'b1;
                        ctl_store_active = 1'b1;
                        next_state [S_STORE_WAIT] = 1'b1;
                    end
                    
                    current_state [S_STORE_WAIT] : begin
                        if (exception_alignment) begin
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (store_done) begin
                            ctl_fetch_enable = 1'b1; 
                            ctl_disable_data_access = 1'b1;
                            next_state [S_FETCH_EXE] = 1'b1;
                        end else begin
                            next_state [S_STORE_WAIT] = 1'b1;
                        end
                    end
                                        
                    current_state [S_LOAD] : begin
                        ctl_data_access_enable = 1'b1;
                        ctl_load_active = 1'b1;
                        next_state [S_LOAD_WAIT] = 1'b1;
                    end
                    
                    current_state [S_LOAD_WAIT] : begin
                        if (exception_alignment) begin
                            next_state [S_EXCEPTION] = 1'b1;
                        end else if (load_done) begin
                            ctl_fetch_enable = 1'b1; 
                            ctl_disable_data_access = 1'b1;
                            next_state [S_FETCH_EXE] = 1'b1;
                        end else begin
                            next_state [S_LOAD_WAIT] = 1'b1;
                        end
                    end
                    
                    current_state [S_EXCEPTION] : begin
                        ctl_activate_exception = 1'b1;
                        next_state [S_EXCEPTION_REINIT] = 1'b1;
                    end
                    
                    current_state [S_EXCEPTION_REINIT] : begin
                        ctl_fetch_init_exception  = 1'b1;
                        ctl_clear_exception       = 1'b1;
                        next_state [S_INIT_WAIT1] = 1'b1;
                    end
                    
                    current_state [S_MUL_DIV] : begin
                        if (!mul_div_done) begin
                            next_state [S_MUL_DIV] = 1'b1;
                        end else begin
                            ctl_fetch_enable = 1'b1; 
                            ctl_disable_data_access = 1'b1;
                            next_state [S_FETCH_EXE] = 1'b1;
                        end
                    end
                    
                    default: begin
                        next_state[S_INIT] = 1'b1;
                    end
                    
                endcase
                  
            end  

endmodule

`default_nettype wire
