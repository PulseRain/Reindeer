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

//=============================================================================
// Remarks:
//   Serial port 
//=============================================================================

`include "RV2T_common.vh"

`default_nettype none

module Serial_RS232 #(parameter STABLE_TIME = `UART_STABLE_COUNT, MAX_BAUD_PERIOD = `UART_TX_BAUD_PERIOD) (
    
    //=======================================================================
    // clock / reset
    //=======================================================================
        
    input   wire                                clk,
    input   wire                                reset_n,
    
    //=======================================================================
    // host interface
    //=======================================================================
    
    input   wire                                start_TX,
    input   wire                                start_RX,
    
    input   wire                                class_8051_unit_pulse,
    input   wire                                timer_trigger,
    input   wire  [7 : 0]                       SBUF_in,
    input   wire  [2 : 0]                       SM,
    input   wire                                REN,
    output  reg  [7 : 0]                        SBUF_out,
    
    output  reg                               TI, // TX interrupt
    output  reg                               RI, // RX interrupt
    
    //=======================================================================
    // device interface
    //=======================================================================
    
    input   wire                                RXD,
    output  wire                                TXD
    
    
);

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg                                                               sync_reset;
        reg  [2 : 0]                                              SM_d1;
        reg  [2 : 0]                                              rxd_sr;
        reg  [$clog2(STABLE_TIME + 1) - 1 : 0]                    stable_counter;
        reg                                                               baud_rate_pulse;
        reg  [$clog2(MAX_BAUD_PERIOD) - 1 : 0]                    counter, counter_save;
        reg                                                               ctl_reset_stable_counter;
        reg                                                               ctl_save_counter;
        reg  [$clog2 (8 + 4) - 1 : 0]  data_counter;
        reg                                                               ctl_reset_data_counter;
        reg                                                               ctl_inc_data_counter;
        reg  [10 : 0]                                                     tx_data;                            
        reg                                                               ctl_load_tx_data;
        reg                                                               ctl_shift_tx_data;
        reg                                                               ctl_set_TI;
        reg                                                               ctl_set_RI;
        reg                                                               ctl_shift_rx_data;
        reg                                                               ctl_counter_reset;
        reg                                                               tx_start_flag;
        reg                                                               ctl_set_tx_start_flag;
        reg                                                               ctl_clear_tx_start_flag;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // sync reset
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : sync_reset_proc
            if (!reset_n) begin
                SM_d1 <= 0;
                sync_reset <= 0;
            end else begin
                SM_d1 <= SM;
                if (SM_d1 != SM) begin
                    sync_reset <= 1'b1;
                end else begin
                    sync_reset <= 0;
                end
            end
        end 
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // TI / RI
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : TI_proc
            if (!reset_n) begin
                TI <= 0;
            end else if (ctl_set_TI) begin
                TI <= 1'b1;
            end else if (start_TX) begin
                TI <= 0;
            end
        end 
        
        always @(posedge clk, negedge reset_n) begin : RI_proc
            if (!reset_n) begin
                RI <= 0;
            end else if (ctl_set_RI) begin
                RI <= 1'b1;
            end else if (start_RX) begin
                RI <= 0;    
            end
        end 
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // baud_rate_pulse
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : baud_rate_pulse_proc
            if (!reset_n) begin
                baud_rate_pulse <= 0;
            end else if (sync_reset) begin
                baud_rate_pulse <= 0;
            end else begin
                baud_rate_pulse <= timer_trigger;
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
    // rx_data
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : SBUF_out_proc
            if (!reset_n) begin
                SBUF_out <= 0;
            end else if (ctl_shift_rx_data) begin
                SBUF_out <= {rxd_sr[2], SBUF_out [7 : 1]};
            end
        end
        
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // rxd_sr
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        always @(posedge clk, negedge reset_n) begin : rxd_sr_proc
            if (!reset_n) begin
                rxd_sr <= 0;
            end else  begin
                rxd_sr <= {rxd_sr [2 - 1 : 0] , RXD};
            end
        end 
            
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
        
        always @(posedge clk, negedge reset_n) begin : counter_save_proc
            if (!reset_n) begin
                counter_save <= 0;
            end else if (sync_reset | ctl_counter_reset) begin
                counter_save <= 0;
            end else if (ctl_save_counter) begin
                counter_save <= counter;
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
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
        localparam S_IDLE = 0, S_RX_START = 1, S_TX_START = 2, S_RX_START_BIT = 3, S_RX_DATA = 4, 
              S_TX_DATA = 5, S_RX_STOP_BIT = 6, S_TX_WAIT = 7, S_TX_WAIT2 = 8;
                
        reg [8:0] current_state = 0, next_state;
                
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
            ctl_shift_rx_data = 0;
                        
            ctl_set_TI = 0;
            ctl_set_RI = 0;
            ctl_counter_reset = 0;
            
            ctl_set_tx_start_flag = 0;
            ctl_clear_tx_start_flag = 0;
            
            case (1'b1) // synthesis parallel_case 
                
                current_state[S_IDLE]: begin
                    ctl_load_tx_data = 1'b1;
                    ctl_reset_data_counter = 1'b1;
                    ctl_counter_reset = 1'b1;
                    
                    ctl_clear_tx_start_flag = 1'b1;
                    
                    if (REN) begin
                        if (start_RX) begin
                            next_state [S_RX_START] = 1'b1;
                        end else begin
                            next_state [S_IDLE] = 1'b1;
                        end
                    end else if (start_TX) begin
                        next_state [S_TX_START] = 1'b1;
                    end else begin
                        next_state [S_IDLE] = 1'b1;
                    end
                end
                
                current_state [S_TX_START] : begin
                    ctl_reset_data_counter = 1'b1;
                    
                    if (REN) begin
                        next_state [S_RX_START] = 1'b1;
                    end else if (baud_rate_pulse) begin
                        if (tx_start_flag) begin
                            ctl_shift_tx_data = 1'b1;
                            next_state [S_TX_DATA] = 1'b1;
                        end else begin
                            ctl_set_tx_start_flag = 1'b1;
                            ctl_load_tx_data = 1'b1;
                            next_state [S_TX_START] = 1'b1;
                        end
                    end else begin
                        ctl_load_tx_data = 1'b1;
                        next_state [S_TX_START] = 1'b1;
                    end
                end
                
                current_state [S_TX_DATA] : begin
                    if (data_counter == (8 + 3)) begin
                        ctl_set_TI = 1'b1;
                        next_state [S_IDLE] = 1;
                        //ctl_load_tx_data = 1'b1;
                        //next_state [S_TX_WAIT] = 1;
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
                
                
                current_state [S_RX_START] : begin
                    ctl_reset_stable_counter = 1'b1;
                    ctl_clear_tx_start_flag = 1'b1;
                    
                    if (!REN) begin
                        next_state [S_TX_START] = 1'b1;
                    end else if (rxd_sr[2] & (~rxd_sr[1])) begin
                        next_state [S_RX_START_BIT] = 1'b1;
                    end else begin
                        next_state [S_RX_START] = 1'b1;
                    end
                    
                end
                
                current_state [S_RX_START_BIT] : begin
                
                    if (!rxd_sr[2]) begin
                        if (stable_counter == STABLE_TIME) begin
                            ctl_save_counter = 1'b1;
                            ctl_reset_data_counter = 0;
                            next_state [S_RX_DATA] = 1;
                        end else begin
                            next_state [S_RX_START_BIT] = 1;
                        end
                    end else begin
                        next_state [S_RX_START] = 1'b1;
                    end
                    
                end
                                
                current_state [S_RX_DATA] : begin
                    
                    if (counter == counter_save) begin
                        ctl_inc_data_counter = 1'b1;
                        ctl_shift_rx_data = 1'b1;
                    end 
                    
                    if (data_counter == 8) begin
                        next_state [S_RX_STOP_BIT] = 1'b1;
                    end else begin
                        next_state [S_RX_DATA] = 1;
                    end
                    
                end
                
                current_state [S_RX_STOP_BIT] : begin
                    if (counter == counter_save) begin
                        ctl_set_RI = 1'b1;
                        next_state [S_IDLE] = 1;
                    end else begin
                        next_state [S_RX_STOP_BIT] = 1;
                    end
                end
                
                default: begin
                    next_state[S_IDLE] = 1'b1;
                end
                
            endcase
              
        end 

endmodule 

`default_nettype wire
