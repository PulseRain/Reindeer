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

module RV2T_data_access (
    //=====================================================================
    // clock and reset
    //=====================================================================
        input wire                                              clk,                          
        input wire                                              reset_n,                      
        input wire                                              sync_reset,

    //=====================================================================
    // interface from controller
    //=====================================================================
        input wire                                              data_access_enable,
   
    //=====================================================================
    // interface for the execution unit
    //=====================================================================
        input wire                                              ctl_CSR,
        input wire                                              ctl_CSR_write,
        
        input wire [`XLEN - 1 : 0]                              csr_new_value,
        input wire [`XLEN - 1 : 0]                              csr_old_value,
        
        input wire [`CSR_BITS - 1 : 0]                          csr_addr,
        
        input wire                                              ctl_save_to_rd,
        
        input wire [`REG_ADDR_BITS - 1 : 0]                     rd_addr_in,
        input wire [`XLEN - 1 : 0]                              rd_data_in,
        
        input wire                                              load_active,
        input wire                                              store_active,
        input wire [2 : 0]                                      width_load_store,
        input wire [`XLEN - 1 : 0]                              data_to_store,
        input wire [`XLEN - 1 : 0]                              mem_access_addr,
        input wire                                              mem_access_unaligned,
        
        input wire                                              mul_div_done,
        
    //=====================================================================
    // interface to write to the register file
    //=====================================================================
        output wire                                             ctl_reg_we,
        output wire [`XLEN - 1 : 0]                             ctl_reg_data_to_write,
        output wire [`REG_ADDR_BITS - 1 : 0]                    ctl_reg_addr,
    
    //=====================================================================
    // interface for CSR
    //=====================================================================
        output wire                                             ctl_csr_we,
        output wire [`CSR_ADDR_BITS - 1 : 0]                    ctl_csr_write_addr,
        output wire [`XLEN - 1 : 0]                             ctl_csr_write_data,
        
    //=====================================================================
    // interface for memory
    //=====================================================================
        input  wire                                             mem_enable_in,
        input  wire [`XLEN - 1 : 0]                             mem_data_in,
        
        input  wire                                             mm_reg_enable_in,
        input  wire [`XLEN - 1 : 0]                             mm_reg_data_in,
        
        
        output wire                                             mem_re,
        output reg [`XLEN_BYTES - 1 : 0]                        mem_we,
        output reg [`XLEN - 1 : 0]                              mem_data_to_write,
        output reg [`XLEN - 1 : 0]                              mem_addr_rw_out,
        output reg                                              store_done,
        output wire                                             load_done,
        output wire                                             exception_alignment,
        
        output reg                                              mm_reg_re,
        output reg                                              mm_reg_we,
        
        output reg [`XLEN - 1 : 0]                              mm_reg_data_to_write,
        output reg [`MM_REG_ADDR_BITS - 1 : 0]                  mm_reg_addr_rw_out
         
);


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg                                                     ctl_mem_we;
        reg                                                     ctl_mem_re;
        reg                                                     ctl_mem_we_d1;
        
        reg                                                     ctl_load_exception;
        reg                                                     ctl_store_exception;
        reg                                                     ctl_load_exception_d1;
        
        reg                                                     ctl_store_done;
        reg                                                     ctl_load_done;
        reg                                                     ctl_load_shift;
        reg                                                     ctl_load_mask;
        reg                                                     ctl_load_reg_write;
        
        reg [2 : 0]                                             width_reg;
        reg [3 : 0]                                             width_mask;
        
        reg [`XLEN - 1 : 0]                                     mem_data_in_reg;
        reg [`XLEN - 1 : 0]                                     load_masked_data;
        
        reg [1 : 0]                                             mem_addr_rw_out_tail_reg;
        
        wire [`XLEN - 1 : 0]                                    mem_data_in_mux;
        reg [`XLEN - 1 : 0]                                     mem_access_addr_d1;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // data path
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        //---------------------------------------------------------------------
        //  register write back
        //---------------------------------------------------------------------
            assign ctl_reg_we            = (data_access_enable & ctl_save_to_rd) | ctl_load_reg_write | mul_div_done;
            assign ctl_reg_data_to_write = ctl_CSR ? csr_old_value : (ctl_load_reg_write ? load_masked_data : rd_data_in);
            assign ctl_reg_addr          = rd_addr_in;

        //---------------------------------------------------------------------
        //  CSR write back
        //---------------------------------------------------------------------
            assign ctl_csr_we            = data_access_enable & ctl_CSR_write;
            assign ctl_csr_write_addr    = csr_addr;
            assign ctl_csr_write_data    = csr_new_value;
        
        //---------------------------------------------------------------------
        //  memory read / write
        //---------------------------------------------------------------------
            
   /*         always @(*) begin
                case (mem_access_addr[1 : 0]) // synthesis parallel_case 
                    2'b01 : begin
                        mem_data_to_write = {data_to_store[23 : 0], 8'd0};
                    end

                    2'b10 : begin
                        mem_data_to_write = {data_to_store[15 : 0], 16'd0};
                    end
                            
                    2'b11 : begin
                        mem_data_to_write = {data_to_store[7 : 0], 24'd0};
                    end
                            
                    default : begin
                        mem_data_to_write = data_to_store;
                    end
                endcase
            end
     */       
            always @(*) begin
                if (width_load_store [1 : 0] == 2'b00) begin
                    width_mask = 4'b0001 << (mem_access_addr[1 : 0]);
                end else if (width_load_store [1 : 0] == 2'b01) begin
                    width_mask = 4'b0011 << (mem_access_addr[1 : 0]);
                end else begin
                    width_mask = 4'b1111;
                end
            end
             
           // assign mem_we ={ctl_mem_we, ctl_mem_we, ctl_mem_we, ctl_mem_we} & width_mask;
            assign mem_re = ctl_mem_re & mem_access_addr [`MEM_SPACE_BIT];
            
            always @(*) begin
                if (ctl_mem_we_d1) begin
                    mem_addr_rw_out = mem_access_addr_d1;
                end else begin
                    mem_addr_rw_out = mem_access_addr;
                end
            end
            
            assign mem_data_in_mux = mem_enable_in ? mem_data_in : mm_reg_data_in;
            
            always @(*) begin
                case (mem_addr_rw_out_tail_reg) // synthesis parallel_case 
                    2'b01 : begin
                        mem_data_in_reg = {8'd0, mem_data_in_mux[`XLEN - 1 : 8]};
                    end
                    
                    2'b10 : begin
                        mem_data_in_reg = {16'd0, mem_data_in_mux[`XLEN - 1 : 16]};
                    end
                    
                    2'b11 : begin
                        mem_data_in_reg = {24'd0, mem_data_in_mux[`XLEN - 1 : 24]};
                    end
                    
                    default : begin
                        mem_data_in_reg = mem_data_in_mux;
                    end
                    
                endcase
            end
            
            always @(*) begin
                case (width_reg)
                    3'b000 : begin  // LB
                        load_masked_data = {{24{mem_data_in_reg[7]}}, mem_data_in_reg[7 : 0]};
                    end
                    
                    3'b001 : begin // LH
                        load_masked_data = {{16{mem_data_in_reg[15]}}, mem_data_in_reg[15 : 0]};
                    end
                    
                    3'b100 : begin  // LBU
                        load_masked_data = {24'd0, mem_data_in_reg[7 : 0]};
                    end
                    
                    3'b101 : begin // LHU
                        load_masked_data = {16'd0, mem_data_in_reg[15 : 0]};
                    end
                    
                    default : begin
                        load_masked_data = mem_data_in_reg;
                    end
                    
                endcase
            end
            
            assign load_done = ctl_load_done;
            
            always @(posedge clk, negedge reset_n) begin
                if (!reset_n) begin
                 //   mem_re <= 0;
                    mem_we <= 0;
                    mm_reg_re <= 0;
                    mm_reg_we <= 0;
                    mem_data_to_write <= 0;
                 //   mem_addr_rw_out <= 0;
                    
                    width_reg  <= 0;
                //    width_mask <= 0;
                    
                 //   mem_data_in_reg <= 0;
                    
                    ctl_mem_we_d1 <= 0;
                    
                    store_done <= 0;
                  //  load_done  <= 0;
                    
                //    load_masked_data <= 0;
                    
                    mm_reg_data_to_write <= 0;
                    mm_reg_addr_rw_out <= 0;
                    
                    mem_addr_rw_out_tail_reg <= 0;
                    
                    mem_access_addr_d1 <= 0;
                    
                    ctl_load_exception_d1 <= 0;
                    
                end else begin
                    
                    mem_access_addr_d1 <= mem_access_addr;
                    ctl_load_exception_d1 <= ctl_load_exception;
                    
                    mm_reg_we <= ctl_mem_we & mem_access_addr [`REG_SPACE_BIT];
                    mm_reg_re <= ctl_mem_re & mem_access_addr [`REG_SPACE_BIT];
                    
                    mm_reg_data_to_write <= data_to_store;
                    mm_reg_addr_rw_out <= ctl_mem_we ? mem_access_addr [`MM_REG_ADDR_BITS + 1 : 2] : mem_access_addr [`MM_REG_ADDR_BITS + 1 : 2];
                    
                    //ctl_mem_we_d1 <= ctl_mem_we & mem_access_addr [`MEM_SPACE_BIT];
                    ctl_mem_we_d1 <= ctl_mem_we;
                    
                    store_done <= ctl_store_done;
                    //load_done  <= ctl_load_done;
                    
                    
                    
              //      mem_we <={ctl_mem_we_d1, ctl_mem_we_d1, ctl_mem_we_d1, ctl_mem_we_d1} & width_mask;
                
                    mem_we <= {4{ctl_mem_we & mem_access_addr [`MEM_SPACE_BIT]}} & width_mask;
                    
        /*            if (mem_enable_in) begin
                        mem_data_in_reg <= mem_data_in;
                    end else if (mm_reg_enable_in) begin
                        mem_data_in_reg <= mm_reg_data_in;
                    end else if (ctl_load_shift) begin
                        case (mem_addr_rw_out [1 : 0]) // synthesis parallel_case 
                            2'b01 : begin
                                mem_data_in_reg <= mem_data_in_reg >> 8;
                            end
                            
                            2'b10 : begin
                                mem_data_in_reg <= mem_data_in_reg >> 16;
                            end
                            
                            2'b11 : begin
                                mem_data_in_reg <= mem_data_in_reg >> 24;
                            end
                            
                            default : begin
                            
                            end
                            
                        endcase
                        
                    end
          */         
/*                   
                    if (ctl_mem_we) begin
                         case (mem_access_addr[1 : 0]) // synthesis parallel_case 
                            2'b01 : begin
                                mem_data_to_write <= {data_to_store[23 : 0], 8'd0};
                            end

                            2'b10 : begin
                                mem_data_to_write <= {data_to_store[15 : 0], 16'd0};
                            end
                            
                            2'b11 : begin
                                mem_data_to_write <= {data_to_store[7 : 0], 24'd0};
                            end
                            
                            default : begin
                                mem_data_to_write <= data_to_store;
                            end
                            
                        endcase
                        
                        mem_addr_rw_out <= mem_access_addr;
                    end else if (ctl_mem_re) begin
                        mem_addr_rw_out <= mem_access_addr;
                    end 
*/
                case (mem_access_addr[1 : 0]) // synthesis parallel_case 
                    2'b01 : begin
                        mem_data_to_write <= {data_to_store[23 : 0], 8'd0};
                    end

                    2'b10 : begin
                        mem_data_to_write <= {data_to_store[15 : 0], 16'd0};
                    end
                    
                    2'b11 : begin
                        mem_data_to_write <= {data_to_store[7 : 0], 24'd0};
                    end
                    
                    default : begin
                        mem_data_to_write <= data_to_store;
                    end
                    
                endcase
                        


                    
                   // mem_re <= ctl_mem_re & mem_access_addr [`MEM_SPACE_BIT];
                    
                    if (data_access_enable) begin
                        width_reg <= width_load_store;
                        mem_addr_rw_out_tail_reg <= mem_addr_rw_out [1 : 0];
/*  
                        if (width_load_store [1 : 0] == 2'b00) begin
                            width_mask <= 4'b0001 << (mem_access_addr[1 : 0]);
                        end else if (width_load_store [1 : 0] == 2'b01) begin
                            width_mask <= 4'b0011 << (mem_access_addr[1 : 0]);
                        end else begin
                            width_mask <= 4'b1111;
                        end
*/                        
                    end
                    
   /*                 if (ctl_load_mask) begin
                        case (width_reg)
                            3'b000 : begin  // LB
                                load_masked_data <= {{24{mem_data_in_reg[7]}}, mem_data_in_reg[7 : 0]};
                            end
                            
                            3'b001 : begin // LH
                                load_masked_data <= {{16{mem_data_in_reg[15]}}, mem_data_in_reg[15 : 0]};
                            end
                            
                            3'b100 : begin  // LBU
                                load_masked_data <= {24'd0, mem_data_in_reg[7 : 0]};
                            end
                            
                            3'b101 : begin // LHU
                                load_masked_data <= {16'd0, mem_data_in_reg[15 : 0]};
                            end
                            
                            default : begin
                                load_masked_data <= mem_data_in_reg;
                            end
                            
                        endcase
                    end
     */               
                    
                end 
            end
            
        //---------------------------------------------------------------------
        //  exception
        //---------------------------------------------------------------------
           /* always @(posedge clk, negedge reset_n) begin : exception_proc
                if (!reset_n) begin
                    exception_alignment <= 0;
                end else begin
                    exception_alignment <= ctl_load_store_exception;
                end
            end
            */
            assign exception_alignment = ctl_store_exception | ctl_load_exception_d1;
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            localparam S_IDLE = 0, S_EXCEPTION = 1, S_LOAD = 2; 
            
            reg [2 : 0] current_state, next_state;
                    
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
                
                ctl_mem_we               = 0;
                ctl_mem_re               = 0;
                ctl_load_exception       = 0;
                ctl_store_exception      = 0;
                ctl_store_done           = 0;
                ctl_load_done            = 0;
                ctl_load_shift           = 0;
                ctl_load_mask            = 0;
                ctl_load_reg_write       = 0;
                
                case (1'b1) // synthesis parallel_case 
                    
                    current_state[S_IDLE]: begin
                        if (data_access_enable) begin
                            if (store_active) begin
                                if (mem_access_unaligned) begin
                                    ctl_store_exception = 1'b1;
                                    next_state [S_EXCEPTION] = 1'b1;
                                end else begin
                                    ctl_mem_we = 1'b1;
                                    //next_state [S_STORE] = 1'b1;
                                    next_state [S_IDLE] = 1'b1;
                                end
                            end else if (load_active) begin
                                if (mem_access_unaligned) begin
                                    ctl_load_exception = 1'b1;
                                    next_state [S_EXCEPTION] = 1'b1;
                                end else begin
                                    ctl_mem_re = 1'b1;
                                    next_state [S_LOAD] = 1'b1;
                                end
                            end else begin
                                next_state [S_IDLE] = 1'b1;
                            end
                        end else begin
                            next_state [S_IDLE] = 1'b1;
                        end
                    end
                    
                    current_state [S_EXCEPTION] : begin
                        next_state [S_IDLE] = 1'b1;
                    end
                    
                    current_state [S_LOAD] : begin
                        if (mem_enable_in | mm_reg_enable_in) begin
                            //==next_state [S_LOAD_SHIFT_IN] = 1'b1;
                            
                            ctl_load_reg_write = 1'b1;
                            ctl_load_done = 1'b1;
                            next_state [S_IDLE] = 1'b1;
                        end else begin
                            next_state [S_LOAD] = 1'b1;
                        end
                    end
                    
                    default: begin
                        next_state[S_IDLE] = 1'b1;
                    end
                    
                endcase
                  
            end  
        
endmodule

`default_nettype wire
