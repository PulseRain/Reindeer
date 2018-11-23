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
//     reply module for OCD
//=============================================================================

`include "debug_coprocessor.vh"

module debug_reply (
    input wire                                              clk,                             // clock input
    input wire                                              reset_n,                         // reset, active low
    
    input wire                                              reply_enable_in,
    input wire   [`DBG_NUM_OF_OPERATIONS - 1 : 0]           reply_debug_cmd,
    input wire   [`DEBUG_ACK_PAYLOAD_BITS - 1 : 0]          reply_payload,
    
    input wire                                              uart_tx_done,
    output reg                                              ctl_start_uart_tx,
    output wire  [`DEBUG_DATA_WIDTH - 1 : 0]                uart_data_out,
    output reg                                              reply_done
);
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg  [(`DEBUG_FRAME_LENGTH - `DEBUG_CRC_LEN) * `DEBUG_DATA_WIDTH - 1 : 0]           data_out_sr;
        reg  [$clog2(`DEBUG_FRAME_LENGTH + 1) - 1 : 0]                                      data_counter;
        reg                                                                                 ctl_reset_data_counter;
        reg                                                                                 ctl_inc_data_counter;
        reg                                                                                 ctl_crc_sync_reset;
        wire  [`DEBUG_DATA_WIDTH * 2 - 1 : 0]                                               crc_out;
        reg                                                                                 ctl_data_out_sr_shift;
        reg                                                                                 ctl_crc_enable_in;
        reg                                                                                 ctl_load_crc;
        reg                                                                                 ctl_reply_done;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // data_out_sr
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : data_out_sr_proc
            if (!reset_n) begin
                data_out_sr <= 0;
            end else begin
                if (reply_enable_in) begin
                    data_out_sr <= {`DEBUG_REPLY_SYNC, reply_payload};
                end else if (ctl_load_crc) begin
                    data_out_sr [(`DEBUG_FRAME_LENGTH - `DEBUG_CRC_LEN) * (`DEBUG_DATA_WIDTH) - 1: (`DEBUG_FRAME_LENGTH - `DEBUG_CRC_LEN) * (`DEBUG_DATA_WIDTH) - 1 - 15] <= crc_out; 
                end else if (ctl_data_out_sr_shift) begin
                    data_out_sr <= {data_out_sr [(`DEBUG_FRAME_LENGTH - `DEBUG_CRC_LEN) * (`DEBUG_DATA_WIDTH) - 1 - `DEBUG_DATA_WIDTH : 0], 8'd170};
                end
            end
        end 
        
        assign uart_data_out = data_out_sr [(`DEBUG_FRAME_LENGTH - `DEBUG_CRC_LEN) * `DEBUG_DATA_WIDTH - 1 : (`DEBUG_FRAME_LENGTH - `DEBUG_CRC_LEN) * `DEBUG_DATA_WIDTH - 1 - `DEBUG_DATA_WIDTH + 1]; 
            
        always @(posedge clk, negedge reset_n) begin : data_counter_proc
            if (!reset_n) begin
                data_counter <= 0;
            end else if (ctl_reset_data_counter) begin
                data_counter <= 0;
            end else if (ctl_inc_data_counter) begin
                data_counter <= data_counter + 1;
            end
        end
            
        always @(posedge clk, negedge reset_n) begin : reply_done_proc
            if (!reset_n) begin
                reply_done <= 0;
            end else begin
                reply_done <= ctl_reply_done;
            end
        end 
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // CRC
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        crc16_CCITT crc16_CCITT_i (
				.clk (clk),
				.reset_n (reset_n),
            .sync_reset (ctl_crc_sync_reset),
            .crc_en (ctl_crc_enable_in),
            .data_in (uart_data_out),
            .crc_out (crc_out)
        );
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
        localparam S_IDLE = 0, S_TX_WITHOUT_CRC = 1, S_TX_WITHOUT_CRC_WAIT_DONE = 2, S_TX_CRC = 3, S_TX_CRC_DONE = 4;
        reg [4:0] current_state = 0, next_state;
            
        // Declare states
        always @(posedge clk, negedge reset_n) begin : state_machine_reg
            if (!reset_n) begin
                current_state <= 0;
            end else begin
                current_state <= next_state;
            end
        end 
        
        // FSM main body
        always @(*) begin : state_machine_comb

            next_state = 0;
            
            ctl_reset_data_counter = 0;
            ctl_inc_data_counter = 0;
            
            ctl_start_uart_tx = 0;
            
            ctl_data_out_sr_shift = 0;
            ctl_crc_enable_in = 0;
            
            ctl_crc_sync_reset = 0;
            
            ctl_load_crc = 0;
            ctl_reply_done = 0;
            
            case (1'b1) // synthesis parallel_case 
                
                current_state [S_IDLE]: begin
                    
                    if (reply_enable_in) begin
                        ctl_reset_data_counter = 1'b1;
                        next_state [S_TX_WITHOUT_CRC] = 1;
                    end else begin
                        ctl_crc_sync_reset = 1'b1;
                        next_state [S_IDLE] = 1;                        
                    end
                    
                end
                
                current_state [S_TX_WITHOUT_CRC] : begin
                    if (data_counter == (`DEBUG_FRAME_LENGTH - `DEBUG_CRC_LEN)) begin
                        ctl_reset_data_counter = 1'b1;
                        ctl_load_crc = 1'b1;
                        next_state [S_TX_CRC] = 1;
                    end else begin
                        ctl_start_uart_tx = 1'b1;
                        ctl_crc_enable_in = 1'b1;
                        next_state [S_TX_WITHOUT_CRC_WAIT_DONE] = 1;
                    end
                end
                
                
                current_state [S_TX_WITHOUT_CRC_WAIT_DONE] : begin
                    if (uart_tx_done) begin
                        ctl_inc_data_counter = 1'b1; 
                        ctl_data_out_sr_shift = 1'b1;
                        next_state [S_TX_WITHOUT_CRC] = 1;
                    end else begin
                        next_state [S_TX_WITHOUT_CRC_WAIT_DONE] = 1;
                    end
                end
                
                
                current_state [S_TX_CRC] : begin
                    if (data_counter == 2) begin
                        ctl_reply_done = 1'b1;
                        next_state [S_IDLE] = 1;
                    end else begin
                        ctl_start_uart_tx = 1'b1;
                        next_state [S_TX_CRC_DONE] = 1;
                    end
                end
                
                current_state [S_TX_CRC_DONE] : begin
                    if (uart_tx_done) begin
                        ctl_inc_data_counter = 1'b1; 
                        ctl_data_out_sr_shift = 1'b1;
                        next_state [S_TX_CRC] = 1;
                    end else begin
                        next_state [S_TX_CRC_DONE] = 1;
                    end
                end
                
                default: begin
                    next_state[S_IDLE] = 1'b1;
                end
                
            endcase
            
        end
    
endmodule 
