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


`include "RV2T_common.vh"

//=============================================================================
// Remarks:
//   Serial port for TX
//=============================================================================


`default_nettype none

module UART_TX #(parameter STABLE_TIME = `UART_STABLE_COUNT, BAUD_PERIOD_BITS= $clog2(`UART_TX_BAUD_PERIOD)) (
    
    //=======================================================================
    // clock / reset
    //=======================================================================
        
        input   wire                                clk,
        input   wire                                reset_n,
        input   wire                                sync_reset,

    //=======================================================================
    // host interface
    //=======================================================================
    
        input   wire                                            start_TX,
        input   wire [BAUD_PERIOD_BITS - 1 : 0]                 baud_rate_period_m1,
        input   wire [7 : 0]                                    SBUF_in,

    //=======================================================================
    // device interface
    //=======================================================================
        output  wire                                            tx_active,
        
        output  wire                                            TXD
    
);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        reg [$clog2(STABLE_TIME + 1) - 1 : 0]                    stable_counter;
        reg [BAUD_PERIOD_BITS - 1 : 0]                           baud_rate_counter;
        reg                                                      baud_rate_pulse;
        reg [BAUD_PERIOD_BITS - 1 : 0]                           counter;
        reg                                                      ctl_reset_stable_counter;
        reg                                                      ctl_save_counter;
        reg [$clog2 (8 + 4) - 1 : 0]                             data_counter;
        reg                                                      ctl_reset_data_counter;
        reg                                                      ctl_inc_data_counter;
        reg [8 + 2 : 0]                                          tx_data;                            
        reg                                                      ctl_load_tx_data;
        reg                                                      ctl_shift_tx_data;
        reg                                                      ctl_set_TI;
        reg                                                      ctl_counter_reset;
        reg                                                      tx_start_flag;
        reg                                                      ctl_set_tx_start_flag;
        reg                                                      ctl_clear_tx_start_flag;
        reg                                                      ctl_tx_idle;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // baud_rate_pulse
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        
        always @(posedge clk, negedge reset_n) begin : baud_rate_counter_proc
            if (!reset_n) begin
                baud_rate_counter <= 0;                
            end else if (sync_reset) begin
                baud_rate_counter <= 0;
            end else if (baud_rate_counter == baud_rate_period_m1) begin
                baud_rate_counter <= 0;
            end else begin
                baud_rate_counter <= baud_rate_counter + 1;
            end
        end 
                
        
        always @(posedge clk, negedge reset_n) begin : baud_rate_pulse_proc
            if (!reset_n) begin
                baud_rate_pulse <= 0;
            end else if (baud_rate_counter == 1) begin
                baud_rate_pulse <= 1'b1;
            end else begin
                baud_rate_pulse <= 0;
            end
        end 
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // tx_data
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : tx_data_proc
            if (!reset_n) begin
                tx_data <= 0;
            end else if (ctl_load_tx_data) begin
                tx_data <= {1'b1, SBUF_in, 2'b01};
            end else if (ctl_shift_tx_data) begin
                tx_data <= {1'b1, tx_data [10 : 1]};
            end
        end 

        assign TXD = tx_data [0];
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : counter_proc
            if (!reset_n) begin
                counter <= 0;
            end else if (sync_reset | ctl_counter_reset) begin
                counter <= 0;
            end else if (baud_rate_pulse) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end 
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // data_counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : data_counter_proc
            if (!reset_n) begin
                data_counter <= 0;
            end else if (ctl_reset_data_counter) begin
                data_counter <= 0;
            end else if (ctl_inc_data_counter) begin
                data_counter <= data_counter + 1;
            end
        end 
        
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // stable_counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : stable_counter_proc
            if (!reset_n) begin
                stable_counter <= 0;
            end else if (ctl_reset_stable_counter) begin
                stable_counter <= 0;
            end else begin
                stable_counter <= stable_counter + 1;
            end         
        end 
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // tx_start_flag
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        always @(posedge clk, negedge reset_n) begin : tx_start_flag_proc
            if (!reset_n) begin
                tx_start_flag <= 0;
            end else if (ctl_clear_tx_start_flag) begin
                tx_start_flag <= 0;
            end else if (ctl_set_tx_start_flag) begin
                tx_start_flag <= 1'b1;
            end
        end 
        
        assign tx_active = ~ctl_tx_idle;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
        localparam S_IDLE = 0, S_TX_START = 1, S_TX_DATA = 2, S_TX_WAIT = 3, S_TX_WAIT2 =4;
                
        reg [4 : 0] current_state = 0, next_state;
                
        // Declare states
        always @(posedge clk, negedge reset_n) begin : state_machine_reg
            if (!reset_n) begin
                current_state <= 0;
            end else if (sync_reset) begin 
                current_state <= 0;
            end else begin
                current_state <= next_state;
            end
        end 
            
        // FSM main body
        always @(*) begin : state_machine_comb

            next_state = 0;
            
            ctl_reset_stable_counter = 0;
            ctl_save_counter = 0;
            ctl_reset_data_counter = 0;
            
            ctl_inc_data_counter = 0;
            
            ctl_load_tx_data = 0;
            
            ctl_shift_tx_data = 0;
                        
            ctl_set_TI = 0;
            ctl_counter_reset = 0;
            
            ctl_set_tx_start_flag = 0;
            ctl_clear_tx_start_flag = 0;
            ctl_tx_idle = 0;
            
            case (1'b1) // synthesis parallel_case 
                
                current_state[S_IDLE]: begin
                    ctl_load_tx_data = 1'b1;
                    ctl_reset_data_counter = 1'b1;
                    ctl_counter_reset = 1'b1;
                    
                    ctl_clear_tx_start_flag = 1'b1;
                    
                    ctl_tx_idle = 1'b1;
                    
                    if (start_TX) begin
                        next_state [S_TX_START] = 1'b1;
                    end else begin
                        next_state [S_IDLE] = 1'b1;
                    end
                end
                
                current_state [S_TX_START] : begin
                    ctl_reset_data_counter = 1'b1;
                    
                    if (baud_rate_pulse) begin
                        if (tx_start_flag) begin
                            ctl_shift_tx_data = 1'b1;
                            next_state [S_TX_DATA] = 1'b1;
                        end else begin
                            ctl_set_tx_start_flag = 1'b1;
                            next_state [S_TX_START] = 1'b1;
                        end
                    end else begin
                        next_state [S_TX_START] = 1'b1;
                    end
                end
                
                current_state [S_TX_DATA] : begin
                    if (data_counter == (8 + 3)) begin
                        ctl_set_TI = 1'b1;
                        next_state [S_IDLE] = 1;
                    end else if (baud_rate_pulse) begin
                        ctl_shift_tx_data = 1'b1;
                        ctl_inc_data_counter = 1'b1;
                        next_state [S_TX_DATA] = 1;
                    end else begin
                        next_state [S_TX_DATA] = 1;
                    end
                end
                
                current_state [S_TX_WAIT] : begin
                    
                    ctl_load_tx_data = 1'b1;
                    if (baud_rate_pulse) begin
                        next_state [S_TX_WAIT2] = 1;
                    end else begin
                        next_state [S_TX_WAIT] = 1;
                    end
                end
                
                current_state [S_TX_WAIT2] : begin
                    
                    if (baud_rate_pulse) begin
                        ctl_set_TI = 1'b1;
                        next_state [S_IDLE] = 1;
                    end else begin
                        ctl_load_tx_data = 1'b1;                        
                        next_state [S_TX_WAIT2] = 1;
                    end
                end
                
                default: begin
                    next_state[S_IDLE] = 1'b1;
                end
                
            endcase
              
        end 

endmodule

`default_nettype wire
