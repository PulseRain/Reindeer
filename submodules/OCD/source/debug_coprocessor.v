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
//     Onchip Debugger 
//=============================================================================

`include "debug_coprocessor.vh"

`default_nettype none

module debug_coprocessor (
    input wire                                                                  clk,                             // clock input
    input wire                                                                  reset_n,                         // reset, active low
    
    input wire                                                                  enable_in,
    input wire [`DEBUG_DATA_WIDTH - 1 : 0]                                      debug_data_in,
    
    
    output reg                                                                  reply_enable_out,
    output reg [`DBG_NUM_OF_OPERATIONS - 1 : 0]                                 reply_debug_cmd,
    output reg [`DEBUG_ACK_PAYLOAD_BITS - 1 : 0]                                reply_payload,
    
    input  wire                                                                 reply_done,
    
    input  wire                                                                 pram_read_enable_in,
    input  wire [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]             pram_read_data_in,
    
    output reg                                                                  pram_read_enable_out,
    output reg [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                                 pram_read_addr_out,
        
    output reg                                                                  pram_write_enable_out,
    output reg [`DEBUG_PRAM_ADDR_WIDTH - 3 : 0]                                 pram_write_addr_out,
    output reg [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]              pram_write_data_out,
    
    output reg                                                                  cpu_reset,
    output reg                                                                  cpu_start,
    output reg [`DEBUG_DATA_WIDTH * `DEBUG_FRAME_DATA_LEN - 1 : 0]              cpu_start_addr,
    output reg                                                                  debug_uart_tx_sel_ocd1_cpu0
    
                
);
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Signals
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        reg  [1 : 0]                                                    enable_in_sr;
        reg  [`DEBUG_FRAME_LENGTH * `DEBUG_DATA_WIDTH - 1 : 0]          data_in_sr;
        wire [`DEBUG_DATA_WIDTH -  1 : 0]                               new_data_in;
        reg  [$clog2(`DEBUG_EXT_FRAME_LENGTH + 1) - 1 : 0]              input_counter;
        reg                                                             ctl_reset_input_counter;
        
        reg                                                             ctl_crc_sync_reset;
        
        wire  [15 : 0]                                                  crc_out;
                    
        reg                                                             ctl_pram_write_enable;
        reg                                                             ctl_pram_read_enable;
        
        wire [`DEBUG_PRAM_ADDR_WIDTH - 1 : 0]                           pram_addr;
        wire [`DEBUG_FRAME_DATA_LEN * `DEBUG_DATA_WIDTH -  1 : 0]       pram_data;
        
        wire [`DEBUG_DATA_WIDTH -  2 : 0]                               frame_type;
        wire                                                            toggle_bit;
                        
        wire                                                            uart_sel_ocd1_cpu0;
                    
        reg                                                             ctl_reply_wr_ack;
        reg                                                             ctl_reply_pram_read_back;
        reg                                                             ctl_reply_data_mem_read_back;
        reg                                                             ctl_cpu_reset;
        reg [`DEBUG_CPU_RESET_LENGTH - 1 : 0]                           cpu_reset_sr;
        reg                                                             ctl_run_pulse;
        reg                                                             ctl_cpu_status_ack;
        reg                                                             ctl_uart_sel;
        
        reg [`DEBUG_PRAM_ADDR_WIDTH - 1 : 0]                            pram_addr_ext;
        reg                                                             ctl_load_pram_addr_ext;
        reg                                                             ctl_inc_pram_addr_ext;
        
        reg                                                             wr_ext_enable;
        reg                                                             ctl_wr_ext_disable;
        reg                                                             ctl_wr_ext_enable;
        
        reg                                                             ctl_config_start;
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // shift registers
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : enable_in_sr_proc
            if (!reset_n) begin
                enable_in_sr <= 0;
                data_in_sr <= 0;
            end else if (enable_in) begin
                enable_in_sr <= {enable_in_sr [0 : 0] , 1'b1};
                data_in_sr <= {data_in_sr[`DEBUG_FRAME_LENGTH * `DEBUG_DATA_WIDTH - 1 - `DEBUG_DATA_WIDTH : 0], debug_data_in};
            end else begin
                enable_in_sr <= {enable_in_sr [0 : 0] , 1'b0};
            end
        end
        
        assign new_data_in = data_in_sr [`DEBUG_DATA_WIDTH - 1 : 0];
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // CRC
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        crc16_CCITT crc16_CCITT_i (
				.clk (clk),
				.reset_n (reset_n),
            .sync_reset (ctl_crc_sync_reset),
            .crc_en (enable_in_sr[0]),
            .data_in (new_data_in),
            .crc_out (crc_out)
        );
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // start address
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : start_addr_proc
            if (!reset_n) begin
                cpu_start <= 0;
                cpu_start_addr <= 0;
            end else if (ctl_config_start) begin
                cpu_start <= 1'b1;
                cpu_start_addr <= pram_data;
            end else begin
                cpu_start <= 0;
            end
        end 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // input_counter
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        always @(posedge clk, negedge reset_n) begin : input_counter_proc
            if (!reset_n) begin
                input_counter <= 0;
            end else if (ctl_reset_input_counter) begin
                input_counter <= 0;
            end else if (enable_in_sr[0]) begin
                input_counter <= input_counter + 1;
            end
        end
        
            
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // CPU reset
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        always @(posedge clk, negedge reset_n) begin : cpu_reset_proc
            if (!reset_n) begin
                cpu_reset <= 0;
                cpu_reset_sr <= 0;
            end else begin
                cpu_reset_sr <= {cpu_reset_sr [`DEBUG_CPU_RESET_LENGTH - 2 : 0], ctl_cpu_reset};
                cpu_reset <= |cpu_reset_sr;
            end
            
        end
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // debug_pram_write
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        assign pram_addr = data_in_sr [(`DEBUG_FRAME_DATA_LEN + `DEBUG_CRC_LEN + `DEBUG_FRAME_ADDR_LEN) * `DEBUG_DATA_WIDTH - 1 : 
                                       (`DEBUG_FRAME_DATA_LEN + `DEBUG_CRC_LEN) * `DEBUG_DATA_WIDTH];
        
        
        assign pram_data = data_in_sr [(`DEBUG_FRAME_DATA_LEN + `DEBUG_CRC_LEN) * `DEBUG_DATA_WIDTH - 1 : 
                                       `DEBUG_CRC_LEN * `DEBUG_DATA_WIDTH];
        
        assign uart_sel_ocd1_cpu0         = pram_data [1];
        
        assign frame_type = data_in_sr [(`DEBUG_FRAME_DATA_LEN + `DEBUG_CRC_LEN + `DEBUG_FRAME_ADDR_LEN + `DEBUG_FRAME_TYPE_LEN) * `DEBUG_DATA_WIDTH - 1 : 
                                        (`DEBUG_FRAME_DATA_LEN + `DEBUG_CRC_LEN + `DEBUG_FRAME_ADDR_LEN ) * `DEBUG_DATA_WIDTH + 1];
        
        assign toggle_bit = data_in_sr [(`DEBUG_FRAME_DATA_LEN + `DEBUG_CRC_LEN + `DEBUG_FRAME_ADDR_LEN ) * `DEBUG_DATA_WIDTH];
        
        always @(posedge clk, negedge reset_n) begin : pram_write_proc
            if (!reset_n) begin
                pram_write_enable_out <= 0;
                pram_write_addr_out   <= 0;
                pram_write_data_out   <= 0;
            end else begin
                pram_write_enable_out <= ctl_pram_write_enable;
                
                if (wr_ext_enable) begin
                    pram_write_addr_out   <= pram_addr_ext [`DEBUG_PRAM_ADDR_WIDTH - 1 : 2];
                end else begin  
                    pram_write_addr_out   <= pram_addr [`DEBUG_PRAM_ADDR_WIDTH - 1 : 2];
                end
                
                pram_write_data_out   <= pram_data;
            end
        end 
            
        always @(posedge clk, negedge reset_n) begin : pram_read_proc
            if (!reset_n) begin
                pram_read_enable_out <= 0;
                pram_read_addr_out   <= 0;
            end else begin
                pram_read_enable_out <= ctl_pram_read_enable;
                pram_read_addr_out   <= pram_addr [`DEBUG_PRAM_ADDR_WIDTH - 1 : 2];
            end
            
        end 
        
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // uart selection
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                debug_uart_tx_sel_ocd1_cpu0 <= 0;
            end else if (ctl_uart_sel) begin
                debug_uart_tx_sel_ocd1_cpu0 <= uart_sel_ocd1_cpu0;
            end
        end
        
        
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Reply Acknowledge 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        always @(posedge clk, negedge reset_n) begin : reply_ack_proc
            if (!reset_n) begin
                reply_enable_out <= 0;
                reply_debug_cmd <= 0;
                reply_payload <= 0;
            end else begin
                reply_enable_out <= ctl_reply_wr_ack | ctl_reply_pram_read_back | ctl_cpu_status_ack | ctl_reply_data_mem_read_back;
                
                case (1'b1) // synthesis parallel_case 
                    ctl_reply_wr_ack : begin
                        reply_debug_cmd <= (1 << (`OP_DBG_ACK)); 
                        reply_payload <= {frame_type, toggle_bit, pram_addr, 32'hAAABACAD};
                    end
                    
                    ctl_reply_pram_read_back : begin
                        reply_debug_cmd <= (1 << (`OP_READ_BACK_4_BYTES));   
                        reply_payload <= {frame_type, toggle_bit, pram_addr, pram_read_data_in};
                    end
                    
                    ctl_cpu_status_ack : begin
                        reply_debug_cmd <= (1 << `OP_CPU_STATUS_ACK);
                        reply_payload <= {frame_type, toggle_bit, 8'h0, 7'd59, 1'b0, 16'hBEEF, 16'hDEAD};
                    end
                    
                    ctl_reply_data_mem_read_back : begin
                        reply_debug_cmd <= (1 << (`OP_DATA_MEM_READ));
                        reply_payload <= {frame_type, toggle_bit, 16'h999D, 24'hAABBCC, 8'hDC};
                    end
                    
                    default : begin
                        reply_payload <= 0;
                    end
                endcase
            end
        end 
    
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // debug RAM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                pram_addr_ext <= 0;
            end else if (ctl_load_pram_addr_ext) begin
                pram_addr_ext <= pram_addr + 4;
            end else if (ctl_inc_pram_addr_ext) begin
                pram_addr_ext <= pram_addr_ext + 4;
            end
        end
        
        always @(posedge clk, negedge reset_n) begin
            if (!reset_n) begin
                wr_ext_enable <= 0;
            end else if (ctl_wr_ext_disable) begin
                wr_ext_enable <= 0;
            end else if (ctl_wr_ext_enable) begin
                wr_ext_enable <= 1'b1;
            end
        end
                 
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // FSM
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                
        localparam S_IDLE = 0, S_SYNC_1 = 1, S_SYNC_0 = 2, S_INPUT_WAIT = 3, S_FRAME_TYPE = 4, S_CRC = 5, 
                   S_WR_ACK = 6, S_PRAM_READ_WAIT = 7, S_CPU_STATUS_ACK = 8,  
                   S_WAIT_DONE = 9, S_WR_EXT = 10, S_EXT_CRC = 11;
                   
        reg [11 : 0] current_state = 0, next_state;
            
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
            
            ctl_reset_input_counter = 0;
            
            ctl_crc_sync_reset = 0;
            
            ctl_pram_write_enable = 0;
            ctl_pram_read_enable = 0;
            
            ctl_reply_wr_ack = 0;
            
            ctl_reply_pram_read_back = 0;
            
            ctl_cpu_reset = 0;
            
            ctl_cpu_status_ack = 0;
            
            ctl_reply_data_mem_read_back = 0;
            
            ctl_uart_sel= 0;
            
            ctl_load_pram_addr_ext = 0;
            ctl_inc_pram_addr_ext = 0;
            
            ctl_wr_ext_disable = 0;
            ctl_wr_ext_enable = 0;
        
            ctl_config_start = 0;
            
            case (1'b1) // synthesis parallel_case 
                
                current_state[S_IDLE]: begin
                    ctl_wr_ext_disable = 1'b1;
                    
                    if (enable_in_sr[0] && (new_data_in == `DEBUG_SYNC_2)) begin
                        next_state [S_SYNC_1] = 1;
                    end else begin
                        ctl_crc_sync_reset = 1'b1;
                        next_state [S_IDLE] = 1;                        
                    end
                end
                
                current_state [S_SYNC_1] : begin
                    if (enable_in_sr[0]) begin
                        if (new_data_in == `DEBUG_SYNC_1) begin
                            next_state [S_SYNC_0] = 1;
                        end else begin
                            next_state [S_IDLE] = 1;
                        end
                    end else begin
                        next_state [S_SYNC_1] = 1;
                    end
                end
                
                current_state [S_SYNC_0] : begin
                    ctl_reset_input_counter = 1;
                    
                    if (enable_in_sr[0]) begin
                        if (new_data_in == `DEBUG_SYNC_0) begin
                            next_state [S_INPUT_WAIT] = 1;
                        end else begin
                            next_state [S_IDLE] = 1;
                        end
                    end else begin
                        next_state [S_SYNC_0] = 1;
                    end
                end
                
                current_state [S_INPUT_WAIT] : begin
                    if (input_counter == (`DEBUG_FRAME_LENGTH - `DEBUG_SYNC_LENGTH - 1)) begin
                        next_state [S_FRAME_TYPE] = 1;          
                    end else begin
                        next_state [S_INPUT_WAIT] = 1;
                    end
                end
                
                current_state [S_FRAME_TYPE] : begin
                    ctl_reset_input_counter = 1'b1;
                    
                    if (enable_in_sr[0]) begin
                        next_state [S_CRC] = 1;
                    end else begin
                        next_state [S_FRAME_TYPE] = 1;
                    end
                    
                end
                
                current_state [S_CRC] : begin
                    ctl_load_pram_addr_ext = 1'b1;
                    
                    if (!crc_out) begin
                        case (frame_type) // synthesis parallel_case
                                                            
                            `DEBUG_TYPE_PRAM_WRITE_128_BYTES_WITH_ACK  : begin
                                ctl_pram_write_enable = 1'b1;
                                ctl_crc_sync_reset = 1'b1;
                                
                                next_state [S_WR_EXT] = 1;
                            end
                            
                            `DEBUG_TYPE_PRAM_WRITE_4_BYTES_WITHOUT_ACK : begin
                                ctl_pram_write_enable = 1'b1;
                                next_state [S_IDLE] = 1;
                            end
                            
                            `DEBUG_TYPE_PRAM_WRITE_4_BYTES_WITH_ACK : begin
                                
                                ctl_pram_write_enable = 1'b1;
                                next_state [S_WR_ACK] = 1;
                            end
                            
                            `DEBUG_TYPE_PRAM_READ_4_BYTES : begin
                                ctl_pram_read_enable = 1'b1;
                                next_state [S_PRAM_READ_WAIT] = 1;
                            end
                            
                            `DEBUG_TYPE_CPU_RESET_WITH_ACK : begin
                                ctl_cpu_reset = 1'b1;
                                next_state [S_WR_ACK] = 1;
                            end
                            
                            `DEBUG_TYPE_RUN_PULSE_WITH_ACK : begin
                                next_state [S_WR_ACK] = 1;
                            end
                            
                            `DEBUG_TYPE_READ_CPU_STATUS : begin
                                next_state [S_CPU_STATUS_ACK] = 1;
                            end
                            
                            `DEBUG_TYPE_COUNTER_CONFIG : begin
                                ctl_config_start = 1'b1;
                                next_state [S_WR_ACK] = 1;
                            end
                            
                            `DEBUG_TYPE_UART_SEL : begin
                                ctl_uart_sel = 1'b1;
                                next_state [S_IDLE] = 1;
                            end
                            
                            default : begin
                                next_state [S_IDLE] = 1;
                            end
                                
                        endcase
                        
                        
                    end else begin
                        next_state [S_IDLE] = 1;
                    end
                end
                                
                current_state [S_WR_ACK] : begin
                    ctl_crc_sync_reset = 1'b1;
                    
                    ctl_reply_wr_ack = 1'b1;
                    next_state [S_WAIT_DONE] = 1;
                    
                end
                
                current_state [S_CPU_STATUS_ACK] : begin
                    ctl_crc_sync_reset = 1'b1;
                    
                    ctl_cpu_status_ack = 1'b1;
                    next_state [S_WAIT_DONE] = 1;
                end
                
                
                current_state [S_PRAM_READ_WAIT] : begin
                    ctl_crc_sync_reset = 1'b1;
                    
                    if (!pram_read_enable_in) begin
                        next_state [S_PRAM_READ_WAIT] = 1;
                    end else begin
                        ctl_reply_pram_read_back = 1'b1;
                        next_state [S_WAIT_DONE] = 1;
                    end
                end

                current_state [S_WAIT_DONE] :begin
                    if (reply_done) begin
                        next_state [S_IDLE] = 1;
                    end else begin
                        next_state [S_WAIT_DONE] = 1;
                    end
                end
                
                current_state [S_WR_EXT] : begin
                    
                    ctl_wr_ext_enable = 1'b1;
                    
                    if (input_counter == (`DEBUG_EXT_FRAME_LENGTH - `DEBUG_FRAME_LENGTH)) begin
                        next_state [S_EXT_CRC] = 1;         
                    end else begin
                        next_state [S_WR_EXT] = 1;
                    end
                    
                    if (enable_in_sr[0] && (|input_counter[$clog2(`DEBUG_EXT_FRAME_LENGTH + 1) - 1 : 2]) && (input_counter [1:0] == 2'b01)) begin
                        ctl_pram_write_enable = 1'b1;   
                        ctl_inc_pram_addr_ext = 1'b1;
                    end
                            
                    
                end
                
                current_state [S_EXT_CRC] : begin
                    if (!crc_out) begin
                        next_state [S_WR_ACK] = 1;
                    end else begin
                        next_state [S_IDLE] = 1;    
                    end
                end
                
                default: begin
                    next_state[S_IDLE] = 1'b1;
                end
                
            endcase
            
        end 
    
endmodule


`default_nettype wire
