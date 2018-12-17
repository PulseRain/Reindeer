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
//    To save space, the register file of PulseRain RV2T is implemented with
//    block RAM (BRAM). 
//    To support two read and one write simultaneously, two BRAMs are used
//
//    Another option is to use only one BRAM, with extra clock cycle as penalty
//=============================================================================

`include "RV2T_common.vh"

`default_nettype none

module RV2T_reg_file (

    //=======================================================================
    // clock / reset
    //=======================================================================
        input   wire                                            clk,
        input   wire                                            reset_n,
        input   wire                                            sync_reset,

    //=======================================================================
    //  register read / write
    //=======================================================================
        input   wire                                            read_enable,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  read_rs1_addr,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  read_rs2_addr,
        
        output  reg                                             read_en_out,
        output  wire  [`XLEN - 1 : 0]                           read_rs1_data_out,
        output  wire  [`XLEN - 1 : 0]                           read_rs2_data_out,
        
        input   wire                                            write_enable,
        input   wire  [`REG_ADDR_BITS - 1 : 0]                  write_addr,
        input   wire  [`XLEN - 1 : 0]                           write_data_in

);

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Signals
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire   [`XLEN - 1 : 0]                                  read_rs1_data_out_i;
        wire   [`XLEN - 1 : 0]                                  read_rs2_data_out_i;
        reg                                                     write_enable_d1;
        reg    [`XLEN - 1 : 0]                                  write_data_in_d1;
        
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // datapath
   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        dual_port_ram #(.ADDR_WIDTH (`REG_ADDR_BITS), .DATA_WIDTH (`XLEN)) single_clk_ram_rs1 (
            .waddr (write_addr),
            .raddr (read_rs1_addr),
            .din (write_data_in),
            .write_en (write_enable),
            .clk (clk),
            .dout (read_rs1_data_out_i) );
            
        dual_port_ram #(.ADDR_WIDTH (`REG_ADDR_BITS), .DATA_WIDTH (`XLEN)) single_clk_ram_rs2 (
            .waddr (write_addr),
            .raddr (read_rs2_addr),
            .din (write_data_in),
            .write_en (write_enable),
            .clk (clk),
            .dout (read_rs2_data_out_i) );
           
        assign read_rs1_data_out = (|read_rs1_addr) ? (((write_enable_d1 == 1'b1) && (read_rs1_addr == write_addr)) ? write_data_in_d1 : read_rs1_data_out_i) : 0;
        assign read_rs2_data_out = (|read_rs2_addr) ? (((write_enable_d1 == 1'b1) && (read_rs2_addr == write_addr)) ? write_data_in_d1 : read_rs2_data_out_i) : 0;
        
        always @(posedge clk, negedge reset_n) begin : output_proc
            if (!reset_n) begin
                read_en_out     <= 0;
                write_enable_d1 <= 0;
                write_data_in_d1  <= 0;
            end else begin
                read_en_out      <= read_enable;
                write_enable_d1  <= write_enable;
                write_data_in_d1 <= write_data_in;
            end
        end
 
endmodule

`default_nettype wire
