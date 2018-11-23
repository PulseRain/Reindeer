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

module single_port_ram_lattice_16Kx16 (
            input  wire [13 : 0]         addr,
            input  wire [15 : 0]         din,
            input  wire [1 : 0]          write_en, 
            input  wire                  clk,
            output wire [15 : 0]         dout
);

	SP256K spram_i (
	  .AD       (addr),  // I
	  .DI       (din),  // I
	  .MASKWE   ({write_en[1], write_en[1], write_en[0], write_en[0]}),  // I
	  .WE       (|write_en),  // I
	  .CS       (1'b1),  // I
	  .CK       (clk),  // I
	  .STDBY    (1'b0),  // I
	  .SLEEP    (1'b0),  // I
	  .PWROFF_N (1'b1),  // I
	  .DO       (dout)   // O
	);
endmodule

`default_nettype wire
