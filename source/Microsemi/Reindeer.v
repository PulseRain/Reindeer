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
`include "debug_coprocessor.vh"

`default_nettype none

module Reindeer (

    //=====================================================================
    // clock and reset
    //=====================================================================
        input   wire                                            clk,                          
        input   wire                                            reset_n,                      
  

    //=====================================================================
    // UART
    //=====================================================================
        output  reg                                             TXD, 
        input   wire                                            RXD,
    
    //=====================================================================
    // status
    //=====================================================================
        output wire                                             processor_active,
        output wire                                             processor_paused        
);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire                                                    debug_uart_tx_sel_ocd1_cpu0;
        wire                                                    cpu_reset;
        wire [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                   pram_read_addr;
        wire [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                   pram_write_addr;
        
        wire                                                    ocd_read_enable;
        wire                                                    ocd_write_enable;
        
        wire  [`MEM_ADDR_BITS - 1 : 0]                          ocd_rw_addr;
        wire  [`XLEN - 1 : 0]                                   ocd_write_word;
        
        wire                                                    ocd_mem_enable_out;
        wire  [`XLEN - 1 : 0]                                   ocd_mem_word_out;      
        
        wire                                                      cpu_start;
        wire [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]  cpu_start_addr;
       
        wire                                                      uart_tx_cpu;
        wire                                                      uart_tx_ocd;
       
    

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // MCU
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     
        PulseRain_RV2T_MCU PulseRain_RV2T_MCU_i (
            .clk (clk),
            .reset_n ((~cpu_reset) & reset_n),
            .sync_reset (1'b0),

            .ocd_read_enable (ocd_read_enable),
            .ocd_write_enable (ocd_write_enable),
            
            .ocd_rw_addr (ocd_rw_addr),
            .ocd_write_word (ocd_write_word),
            
            .ocd_mem_enable_out (ocd_mem_enable_out),
            .ocd_mem_word_out (ocd_mem_word_out),        
        
            .ocd_reg_read_addr (5'd2),
            .ocd_reg_we (1'b0),
            .ocd_reg_write_addr (5'd2),
            .ocd_reg_write_data (32'h80007F00),
        
            .TXD (uart_tx_cpu),
    
            .start (cpu_start),
            .start_address (cpu_start_addr),
        
            .processor_paused (processor_paused),
            
            .peek_pc (),
            .peek_ir () );
     
        assign processor_active = ~processor_paused;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // OCD
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
    
        debug_coprocessor_wrapper #(.BAUD_PERIOD (`UART_TX_BAUD_PERIOD)) ocd_i (
            .clk (clk),
            .reset_n (reset_n),
            
            .RXD (RXD),
            .TXD (uart_tx_ocd),
                
            .pram_read_enable_in (ocd_mem_enable_out),
            .pram_read_data_in (ocd_mem_word_out),
            
            .pram_read_enable_out (ocd_read_enable),
            .pram_read_addr_out (pram_read_addr),
            
            .pram_write_enable_out (ocd_write_enable),
            .pram_write_addr_out (pram_write_addr),
            .pram_write_data_out (ocd_write_word),
            
            .cpu_reset (cpu_reset),
            
            .cpu_start (cpu_start),
            .cpu_start_addr (cpu_start_addr),        
            
            .debug_uart_tx_sel_ocd1_cpu0 (debug_uart_tx_sel_ocd1_cpu0));
        
        assign ocd_rw_addr = ocd_read_enable ? pram_read_addr : pram_write_addr;
        
        always @(posedge clk, negedge reset_n) begin : uart_proc
            if (!reset_n) begin
                TXD <= 0;
            end else if (!debug_uart_tx_sel_ocd1_cpu0) begin
                TXD <= uart_tx_cpu;
            end else begin
                TXD <= uart_tx_ocd;
            end
        end 
     
     
endmodule

`default_nettype wire