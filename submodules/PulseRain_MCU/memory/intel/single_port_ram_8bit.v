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

`default_nettype none

module single_port_ram_8bit #(parameter ADDR_WIDTH = 14) (
            input  wire [ADDR_WIDTH - 1 : 0]         addr,
            input  wire [7 : 0]                      din,
            input  wire                              write_en, 
            input  wire                              clk,
            output wire [7 : 0]         dout
);
    
            reg [ADDR_WIDTH - 1 : 0] addr_reg;
            reg [7:0]   mem [0 : (2**ADDR_WIDTH) - 1] /* synthesis syn_ramstyle="lsram" */ ;

            assign dout = mem[addr_reg];

            always@(posedge clk) begin
                addr_reg <= addr;   
                
                if(write_en) begin
                    mem[addr] <= din;
                end
            end
    
endmodule 



`default_nettype wire
