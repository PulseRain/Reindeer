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

module absolute_value #(parameter DATA_WIDTH=32)(
      
//========== INPUT ==========

        input  wire signed [DATA_WIDTH - 1 : 0]  data_in,
            
        
//========== OUTPUT ==========
        output wire  signed [DATA_WIDTH - 1 : 0] data_out
        
//========== IN/OUT ==========
);
    wire signed [DATA_WIDTH - 1 : 0]    data_sign_ext, data_tmp;
    wire signed [DATA_WIDTH - 1 : 0]    abs_value;
    
    assign data_sign_ext = {(DATA_WIDTH){data_in[DATA_WIDTH - 1]}};
    assign data_tmp      = data_in ^ data_sign_ext;
    assign abs_value     = data_tmp - data_sign_ext;
    
    assign data_out = abs_value;
    
endmodule

`default_nettype wire
