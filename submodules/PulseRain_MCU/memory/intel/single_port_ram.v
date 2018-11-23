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


`include "config.vh"

`default_nettype none

module single_port_ram #(parameter ADDR_WIDTH = 14, DATA_WIDTH = 16) (
            input  wire [ADDR_WIDTH - 1 : 0]         addr,
            input  wire [DATA_WIDTH - 1 : 0]         din,
            input  wire [DATA_WIDTH / 8 - 1 : 0]     write_en, 
            input  wire                              clk,
            output wire [DATA_WIDTH - 1 : 0]         dout
);

    wire [DATA_WIDTH - 1 : 0]         dout_1st;
    wire [DATA_WIDTH - 1 : 0]         dout_2nd;
    
    reg  [ADDR_WIDTH - 1 : 0]         addr_reg;
    
    
    always @(posedge clk) begin
        addr_reg <= addr;
    end
    
    genvar i; 
    
    generate
        if (`MEM_SIZE_IN_BYTES == (48 * 1024)) begin: gen_if_proc
            for (i = 0; i < (DATA_WIDTH / 8); i = i + 1) begin : gen_for_proc_1st
                
                 single_port_ram_8bit #(.ADDR_WIDTH (ADDR_WIDTH - 1)) ram_8bit_1st (
                    .addr (addr[ADDR_WIDTH - 2 : 0]),
                    .din (din [(i + 1) * 8 - 1 : i * 8]),
                    .write_en (write_en[i] & (~addr[ADDR_WIDTH - 1])),
                    .clk (clk),
                    .dout (dout_1st [(i + 1) * 8 - 1 : i * 8]));
            end
            
            for (i = 0; i < (DATA_WIDTH / 8); i = i + 1) begin : gen_for_proc_2nd
                
                 single_port_ram_8bit #(.ADDR_WIDTH (ADDR_WIDTH - 2)) ram_8bit_2nd (
                    .addr (addr[ADDR_WIDTH - 3 : 0]),
                    .din (din [(i + 1) * 8 - 1 : i * 8]),
                    .write_en (write_en[i] & (addr[ADDR_WIDTH - 1])),
                    .clk (clk),
                    .dout (dout_2nd [(i + 1) * 8 - 1 : i * 8]));
            end
            
            assign dout = addr_reg [ADDR_WIDTH - 1] ? dout_2nd : dout_1st;
        
        end else begin
        
            for (i = 0; i < (DATA_WIDTH / 8); i = i + 1) begin : gen_for_proc
                
                 single_port_ram_8bit #(.ADDR_WIDTH (ADDR_WIDTH)) ram_8bit (
                    .addr (addr),
                    .din (din [(i + 1) * 8 - 1 : i * 8]),
                    .write_en (write_en[i]),
                    .clk (clk),
                    .dout (dout [(i + 1) * 8 - 1 : i * 8]));
            end
        end
        
    endgenerate
    
                
endmodule 



`default_nettype wire