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
			input  wire                               clk,
            input  wire [ADDR_WIDTH - 1 : 0]         addr,
            input  wire [DATA_WIDTH - 1 : 0]         din,
            input  wire [DATA_WIDTH / 8 - 1 : 0]     write_en, 
            output reg  [DATA_WIDTH - 1 : 0]         dout
);

    reg [7 : 0] mem_hi [(1<<ADDR_WIDTH)-1:0];
	reg [7 : 0] mem_low [(1<<ADDR_WIDTH)-1:0];
	always @(posedge clk) begin
		if (write_en[0]) begin
			mem_low[addr] <= din[7 : 0];
		end
		if (write_en[1]) begin
			mem_hi[addr] <= din[15 : 8];
		end
	end
 
    always @(posedge clk) begin
        dout <= {mem_hi[addr], mem_low[addr]};
    end
                
endmodule 



`default_nettype wire