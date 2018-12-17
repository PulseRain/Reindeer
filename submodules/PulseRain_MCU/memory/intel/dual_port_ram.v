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

module dual_port_ram #(parameter ADDR_WIDTH = 5, DATA_WIDTH = 32) (
          input wire [ADDR_WIDTH - 1 : 0]       waddr, 
          input wire [ADDR_WIDTH - 1 : 0]       raddr,
          
          input wire [DATA_WIDTH - 1 : 0]       din,
          input wire                            write_en, 
          input wire                            clk, 
          output reg [DATA_WIDTH - 1 : 0]       dout
);

    //    reg [ADDR_WIDTH - 1 : 0] raddr_reg;
        reg [DATA_WIDTH - 1 : 0] mem [(2**ADDR_WIDTH) - 1 : 0] /* synthesis syn_ramstyle="M9K" */;

    //    assign dout = mem[raddr_reg] ;
        
    //    always @(posedge rclk) begin
    //        raddr_reg <= raddr;
    //    end
        
        always @(posedge clk) begin
            if (write_en) begin
                mem[waddr] <= din;
            end
            
            dout <= mem[raddr] ;
        end

endmodule

`default_nettype wire