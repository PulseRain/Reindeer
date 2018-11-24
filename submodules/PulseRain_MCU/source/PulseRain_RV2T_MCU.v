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

module PulseRain_RV2T_MCU (

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
    // UART
    //=====================================================================
        output  wire                                            TXD,
        
    //=====================================================================
    // Interface for init/start
    //=====================================================================
        input   wire                                            start,
        input   wire  [`PC_BITWIDTH - 1 : 0]                    start_address,
        
        output  wire                                            processor_paused,

        output  wire  [`XLEN - 1 : 0]                           peek_pc,
        output  wire  [`XLEN - 1 : 0]                           peek_ir,
        
        output  wire  [`XLEN_BYTES - 1 : 0]                     peek_mem_write_en,
        output  wire  [`XLEN - 1 : 0]                           peek_mem_write_data,
        output  wire [`MEM_ADDR_BITS - 1 : 0]                   peek_mem_addr
        
);
     
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signal
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
        wire [`MEM_ADDR_BITS - 1 : 0]                           mem_addr;
        reg  [`MEM_ADDR_BITS - 1 : 0]                           mem_addr_d1;
        
        wire [`XLEN_BYTES - 1 : 0]                              mem_write_en;
        wire [`XLEN - 1 : 0]                                    mem_write_data;
        wire [`XLEN - 1 : 0]                                    mem_read_data;
            
        wire [15 : 0]                                           dout_high;
        wire [15 : 0]                                           dout_low;
        
        wire                                                    start_TX;
        wire [7 : 0]                                            tx_data;
        wire                                                    tx_active;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // processor core
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         
         PulseRain_RV2T_core PulseRain_RV2T_core_i (
                .clk        (clk),
                .reset_n    (reset_n),
                .sync_reset (sync_reset),
                
                .ocd_read_enable  (ocd_read_enable),
                .ocd_write_enable (ocd_write_enable),
                
                .ocd_rw_addr (ocd_rw_addr),
                .ocd_write_word (ocd_write_word),
                
                .ocd_mem_enable_out (ocd_mem_enable_out),
                .ocd_mem_word_out (ocd_mem_word_out),        
                
                .ocd_reg_read_addr (ocd_reg_read_addr),
                .ocd_reg_we (ocd_reg_we),
                .ocd_reg_write_addr (ocd_reg_write_addr),
                .ocd_reg_write_data (ocd_reg_write_data),

                .start_TX  (start_TX),
                .tx_data   (tx_data),
                .tx_active (tx_active),

                .start (start),
                .start_address (start_address),
                
                .peek_pc (peek_pc),
                .peek_ir (peek_ir),
                
                .mem_addr (mem_addr),
                .mem_write_en (mem_write_en),
                .mem_write_data (mem_write_data),
                .mem_read_data (mem_read_data),
                .processor_paused (processor_paused));

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // memory 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            single_port_ram #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) ram_high_i (
                .addr (mem_addr),
                .din (mem_write_data [31 : 16]),
                .write_en (mem_write_en[3 : 2]),
                .clk (clk),
                .dout (dout_high));
              
            single_port_ram #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) ram_low_i (
                .addr (mem_addr),
                .din (mem_write_data [15 : 0]),
                .write_en (mem_write_en[1 : 0]),
                .clk (clk),
                .dout (dout_low));
      
   /*
      
          single_port_ram_sim_high #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) ram_high_i (
                .addr (mem_addr),
                .din (mem_write_data [31 : 16]),
                .write_en (mem_write_en[3 : 2]),
                .clk (clk),
                .dout (dout_high));
              
            single_port_ram_sim_low #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) ram_low_i (
                .addr (mem_addr),
                .din (mem_write_data [15 : 0]),
                .write_en (mem_write_en[1 : 0]),
                .clk (clk),
                .dout (dout_low));
     */           
      
           // assign mem_read_data = {(`UART_TX_ADDR == {mem_addr_d1 [`MEM_ADDR_BITS - 1 : 0], 2'b00}) ? tx_active : dout_high[15], dout_high [14 : 0], dout_low};
            
           assign mem_read_data = {dout_high, dout_low};
        
            always @(posedge clk, negedge reset_n) begin 
                if (!reset_n) begin
                    mem_addr_d1 <= 0;
                end else begin
                    mem_addr_d1 <= mem_addr;
                end
            end
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // peripherals 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        /* verilator lint_off WIDTH */
        
        UART_TX #(.STABLE_TIME(`UART_STABLE_COUNT), .BAUD_PERIOD_BITS(`UART_TX_BAUD_PERIOD_BITS)) UART_TX_i (
            .clk (clk),
            .reset_n (reset_n),
            .sync_reset (sync_reset),
            
            .start_TX (start_TX),
            .baud_rate_period_m1 (`UART_TX_BAUD_PERIOD - 1),
            //.baud_rate_period_m1 ((`UART_TX_BAUD_PERIOD - 1)),
            .SBUF_in (tx_data),
            .tx_active (tx_active),
            .TXD (TXD));
        
        
        assign  peek_mem_write_en   = mem_write_en;
        assign  peek_mem_write_data = mem_write_data;
        assign  peek_mem_addr       = mem_addr;    
            
endmodule

`default_nettype wire
