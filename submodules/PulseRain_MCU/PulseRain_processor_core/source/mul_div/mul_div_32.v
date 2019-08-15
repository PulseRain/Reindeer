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

module mul_div_32(
      
//=======  clock and reset ======
        input  wire                              clk,
        input  wire                              reset_n,
//========== INPUT ==========

        input  wire                              enable_in,
        
        input  wire signed [31 : 0]              x,
        input  wire signed [31 : 0]              y,
        
        input  wire                              mul0_div1,
        input  wire                              x_signed0_unsigned1,
        input  wire                              y_signed0_unsigned1,
        
//========== OUTPUT ==========
        output wire                              enable_out,
        output wire [63 : 0]                     z,
        
        output wire                              ov
);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        wire signed [31 : 0]        x_abs;
        wire signed [31 : 0]        y_abs;
        
        reg unsigned [31 : 0]                x_mul;
        reg unsigned [31 : 0]                y_mul;
        
        
        wire                        x_max_neg_flag;
        
        reg                         enable_in_d1;
        reg                         enable_in_d2;
        reg                         enable_in_d3;
        
        reg                         mul0_div1_reg;
        reg                         z_pos0_neg1;
        reg                         x_pos0_neg1;
        
        wire                        div_enable_out;
        
        reg  [63 : 0]                z_i;
        wire [31 : 0]                q_i;
        wire [31 : 0]                r_i;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // mul
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        assign x_max_neg_flag = x[31] & (~(|x[30 : 0]));
       
        absolute_value #(.DATA_WIDTH (32)) abs_x_i (
            
            .data_in (x),
            .data_out (x_abs));

        absolute_value #(.DATA_WIDTH (32)) abs_y_i (
            
            .data_in (y),
            .data_out (y_abs));

        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                x_mul <= 0;
                y_mul <= 0;
            
                z_i <= 0;
                mul0_div1_reg <= 0;
                
                enable_in_d1 <= 0;
                enable_in_d2 <= 0;
                enable_in_d3 <= 0;
                
            end else begin
                enable_in_d1 <= enable_in;
                enable_in_d2 <= enable_in_d1;
                enable_in_d3 <= enable_in_d2;
                
                if (enable_in) begin
                    if (!x_signed0_unsigned1) begin
                        x_mul <= x_abs;
                    end else begin
                        x_mul <= x;
                    end
                    
                    if (!y_signed0_unsigned1) begin
                        y_mul <= y_abs;
                    end else begin
                        y_mul <= y;
                    end

                    
                    mul0_div1_reg <= mul0_div1;
                    z_pos0_neg1 <= (~x_signed0_unsigned1 & x[31]) ^ (~y_signed0_unsigned1 & y[31]);
                    x_pos0_neg1 <= ~x_signed0_unsigned1 & x[31];
                end
                
                z_i <= x_mul * y_mul;
            end    
        end
    
        assign enable_out = mul0_div1_reg ? div_enable_out : enable_in_d3;

        assign z = mul0_div1_reg ? 
                    {z_pos0_neg1 ? -q_i : q_i, x_pos0_neg1 ? -r_i : r_i} :
                    (z_pos0_neg1 ? -z_i : z_i);
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // div
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
          long_slow_div_denom_reg #(.DATA_WIDTH (32)) long_slow_div_denom_reg_i (
              .clk (clk),
              .reset_n (reset_n),
              
              .enable_in (enable_in_d1 & mul0_div1_reg),
              .numerator   (x_mul),
              .denominator (y_mul),
        
              .enable_out (div_enable_out),
              .quotient   (q_i),
              .remainder  (r_i),
              .div_by_zero (),
              .error (ov)
            );  

endmodule

`default_nettype wire
