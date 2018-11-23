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

module RV2T_memory (
    
    //=======================================================================
    // clock / reset
    //=======================================================================

        input   wire                                                    clk,
        input   wire                                                    reset_n,
        input   wire                                                    sync_reset,

    //=======================================================================
    // ocd
    //=======================================================================
        
        input   wire                                                    ocd_read_enable,
        input   wire                                                    ocd_write_enable,
        
        input   wire  [`MEM_ADDR_BITS - 1 : 0]                          ocd_rw_addr,
        input   wire  [`XLEN - 1 : 0]                                   ocd_write_word,
        
    //=======================================================================
    // instruction fetch
    //=======================================================================
        input   wire                                                    code_read_enable,
        input   wire  [`MEM_ADDR_BITS - 1 : 0]                          code_read_addr,
                
    //=======================================================================
    // data read / write
    //=======================================================================
        input   wire                                                    data_read_enable,
        input   wire  [`XLEN_BYTES - 1 : 0]                             data_write_enable,
        
        input   wire  [`MEM_ADDR_BITS - 1 : 0]                          data_rw_addr,
        input   wire  [`XLEN - 1 : 0]                                   data_write_word,
        
        
    //=======================================================================
    // output
    //=======================================================================
        output  reg                                                     enable_out,
        output  wire  [`XLEN - 1 : 0]                                   word_out,
        
        output  wire  [`MEM_ADDR_BITS - 1 : 0]                          mem_addr,
        output  wire [`XLEN_BYTES - 1 : 0]                              mem_write_en,
        output  wire [`XLEN - 1 : 0]                                    mem_write_data,
        
        input   wire [`XLEN - 1 : 0]                                    mem_read_data
            
        
);

        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Signal
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

            reg  [`MEM_ADDR_BITS - 1 : 0]     addr;
            wire [`XLEN - 1 : 0]              din;
            wire [`XLEN_BYTES - 1 : 0]        write_en;
            wire [15 : 0]                     dout_high;
            wire [15 : 0]                     dout_low;
                        
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // memory
        //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            
            assign write_en = {(`XLEN_BYTES){ocd_write_enable}} | data_write_enable;
            
            always @(*) begin : addr_proc
                if (ocd_read_enable | ocd_write_enable) begin
                    addr = ocd_rw_addr;
                end else if (code_read_enable) begin
                    addr = code_read_addr;
                end else begin
                    addr = data_rw_addr;
                end
            end

            assign din = ocd_write_enable ? ocd_write_word : data_write_word;

            /*single_port_ram_sim_high #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) single_port_ram_sim_high_i (
                .addr (addr),
                .din (din [31 : 16]),
                .write_en (write_en[3 : 2]),
                .clk (clk),
                .dout (dout_high));
              
            single_port_ram_sim_low #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) single_port_ram_sim_low_i (
                .addr (addr),
                .din (din [15 : 0]),
                .write_en (write_en[1 : 0]),
                .clk (clk),
                .dout (dout_low));
            */
            /*
            single_port_ram_lattice #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) ram_high_i (
                .addr (addr),
                .din (din [31 : 16]),
                .write_en (write_en[3 : 2]),
                .clk (clk),
                .dout (dout_high));
              
            single_port_ram_lattice #(.ADDR_WIDTH (`MEM_ADDR_BITS), .DATA_WIDTH (16) ) ram_low_i (
                .addr (addr),
                .din (din [15 : 0]),
                .write_en (write_en[1 : 0]),
                .clk (clk),
                .dout (dout_low));
            */
            
           // assign word_out = {dout_high, dout_low};
           
            assign word_out = mem_read_data;
            
            always @(posedge clk, negedge reset_n) begin : output_proc
                if (!reset_n) begin
                    enable_out <= 0;
                end else begin
                    enable_out <= ocd_read_enable | code_read_enable | data_read_enable;
                end
            end

            assign mem_addr = addr;
            assign mem_write_en = write_en;
            assign mem_write_data = din;
        
endmodule



`default_nettype wire
