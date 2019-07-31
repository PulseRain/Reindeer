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

module single_port_ram #(parameter ADDR_WIDTH = 12, DATA_WIDTH = 16) (
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
		for (i = 0; i < (DATA_WIDTH / 8); i = i + 1) begin : gen_for_proc
			
			 SP8KC #(.DATA_WIDTH (9)) ram_8bit (
				.AD12 (ADDR_WIDTH>=12?addr[12]:1'b0),
				.AD11 (ADDR_WIDTH>=11?addr[11]:1'b0),
				.AD10 (addr[10]), .AD9 (addr[9]), .AD8 (addr[8]),  .AD7 (addr[7]), .AD6 (addr[6]), .AD5 (addr[5]), .AD4 (addr[4]), .AD3 (addr[3]), .AD2 (addr[2]), .AD1 (addr[1]), .AD0 (addr[0]),
				.DI8 (1'b0),
				.DI7 (din[i * 8 + 7]), .DI6 (din[i * 8 + 6]), .DI5 (din[i * 8 + 5]), .DI4 (din[i * 8 + 4]), .DI3 (din[i * 8 + 3]), .DI2 (din[i * 8 + 2]), .DI1 (din[i * 8 + 1]), .DI0 (din[i * 8 + 0]),
				.WE (write_en[i]),
				.CLK (clk),
				.DO7 (dout[i * 8 + 7]), .DO6 (dout[i * 8 + 6]), .DO5 (dout[i * 8 + 5]), .DO4 (dout[i * 8 + 4]), .DO3 (dout[i * 8 + 3]), .DO2 (dout[i * 8 + 2]), .DO1 (dout[i * 8 + 1]), .DO0 (dout[i * 8 + 0]),
				.CE (1'b1),
				.OCE (1'b1),
				.CS2 (1'b0), .CS1(1'b0), .CS0 (1'b0), 
				.RST (1'b1));
		end
    endgenerate
    
                
endmodule 



`default_nettype wire