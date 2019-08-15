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

module single_port_ram #(parameter ADDR_WIDTH = 14, DATA_WIDTH = 16) (
            input  wire [ADDR_WIDTH - 1 : 0]         addr,
            input  wire [DATA_WIDTH - 1 : 0]         din,
            input  wire [DATA_WIDTH / 8 - 1 : 0]     write_en, 
            input  wire                              clk,
            output wire [DATA_WIDTH - 1 : 0]         dout
);
    
    single_port_ram_lattice #(.ADDR_WIDTH (ADDR_WIDTH), .DATA_WIDTH (DATA_WIDTH)) single_port_ram_lattice_i (
        .addr (addr),
        .din (din),
        .write_en (write_en),
        .clk (clk),
        .dout (dout));

                
endmodule 



`default_nettype wire
