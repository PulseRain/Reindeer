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
//     Top level wrapper for Onchip Debugger 
//=============================================================================

`include "debug_coprocessor.vh"

module debug_coprocessor_wrapper #(parameter BAUD_PERIOD=208) (
        input   wire                                clk,
        input   wire                                reset_n,
    
        
        input   wire                                RXD,
        output  wire                                TXD,
        
        input  wire                                                                 pram_read_enable_in,
        input  wire [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]             pram_read_data_in,
    
        output wire                                                                 pram_read_enable_out,
        output wire [`DEBUG_PRAM_ADDR_WIDTH - 1 : 0]                                pram_read_addr_out,
    
        
        output wire                                                                 pram_write_enable_out,
        output wire [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                                pram_write_addr_out,
        output wire [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN  - 1 : 0]            pram_write_data_out,
        
        output wire                                                                 cpu_reset,
        output wire                                                                 cpu_start,
        output wire [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]             cpu_start_addr,
         
        output wire                                                                 debug_uart_tx_sel_ocd1_cpu0
    
);

    wire  [7 : 0]                                       SBUF_out;
    wire                                                TI, RI;
    
    wire                                                reply_enable;
    wire  [`DBG_NUM_OF_OPERATIONS - 1 : 0]              reply_debug_cmd;
    wire  [`DEBUG_ACK_PAYLOAD_BITS - 1 : 0]             reply_payload;
    
    wire                                                TX_done_pulse;
    
    wire                                                ctl_start_uart_tx;
    wire  [7 : 0]                                       SBUF_in;
    wire                                                reply_done;
    
    
   

    debug_UART #(.BAUD_PERIOD (BAUD_PERIOD)) debug_UART_i (
                .clk (clk),
                .reset_n (reset_n),
                .sync_reset (1'b0),
                .UART_enable (1'b1),
                .TX_enable_in (ctl_start_uart_tx),
                .RXD (RXD),
                .SBUF_in (SBUF_in),
                .REN (1'b1),
                .TXD (TXD),
                .SBUF_out (SBUF_out),
                .TX_done_pulse (TX_done_pulse), 
                .TI (TI),
                .RI (RI));
    
    debug_reply debug_reply_i (
            .clk (clk),
            .reset_n (reset_n),
            .reply_enable_in (reply_enable),
            .reply_debug_cmd (reply_debug_cmd),
            .reply_payload (reply_payload),
            
            .uart_tx_done (TX_done_pulse),
            
            .ctl_start_uart_tx (ctl_start_uart_tx),
            .uart_data_out (SBUF_in),
            .reply_done (reply_done));
    
    
    debug_coprocessor debug_coprocessor_i (
            .clk (clk),
            .reset_n (reset_n),
            .enable_in (RI),
            .debug_data_in (SBUF_out),
                        
            .reply_enable_out (reply_enable),
            .reply_debug_cmd (reply_debug_cmd),
            .reply_payload (reply_payload),
            
            .reply_done (reply_done),
            
            .pram_read_enable_in (pram_read_enable_in),
            .pram_read_data_in (pram_read_data_in),
            
            .pram_read_enable_out (pram_read_enable_out),
            .pram_read_addr_out (pram_read_addr_out),
            
            .pram_write_enable_out (pram_write_enable_out),
            .pram_write_addr_out (pram_write_addr_out),
            .pram_write_data_out (pram_write_data_out),
            
            .cpu_reset (cpu_reset),
            
            .cpu_start (cpu_start),
            .cpu_start_addr (cpu_start_addr),
    
            .debug_uart_tx_sel_ocd1_cpu0 (debug_uart_tx_sel_ocd1_cpu0)
    
            );
        
    
endmodule 

