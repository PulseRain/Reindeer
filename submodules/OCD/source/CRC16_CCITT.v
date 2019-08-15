//-----------------------------------------------------------------------------
// Copyright (C) 2009 OutputLogic.com
// This source file may be used and distributed without restriction
// provided that this copyright statement is not removed from the file
// and that any derivative work contains the original copyright notice
// and the associated disclaimer.
//
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
//-----------------------------------------------------------------------------
// CRC module for data[7:0] ,   crc[15:0]=1+x^5+x^12+x^16;
//-----------------------------------------------------------------------------

`default_nettype none

module crc16_CCITT #(parameter INIT_VALUE = 16'hFFFF) (
        input wire                  clk,
        input wire                  reset_n,
        
        input wire                  sync_reset,
        
        input wire                  crc_en,
        input wire [7:0]   data_in,
        
        output wire [15:0] crc_out
);

    reg [15:0] lfsr_q,lfsr_c;

    assign crc_out = lfsr_q;

    always @(*) begin
        lfsr_c[0] = lfsr_q[8] ^ lfsr_q[12] ^ data_in[0] ^ data_in[4];
        lfsr_c[1] = lfsr_q[9] ^ lfsr_q[13] ^ data_in[1] ^ data_in[5];
        lfsr_c[2] = lfsr_q[10] ^ lfsr_q[14] ^ data_in[2] ^ data_in[6];
        lfsr_c[3] = lfsr_q[11] ^ lfsr_q[15] ^ data_in[3] ^ data_in[7];
        lfsr_c[4] = lfsr_q[12] ^ data_in[4];
        lfsr_c[5] = lfsr_q[8] ^ lfsr_q[12] ^ lfsr_q[13] ^ data_in[0] ^ data_in[4] ^ data_in[5];
        lfsr_c[6] = lfsr_q[9] ^ lfsr_q[13] ^ lfsr_q[14] ^ data_in[1] ^ data_in[5] ^ data_in[6];
        lfsr_c[7] = lfsr_q[10] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[2] ^ data_in[6] ^ data_in[7];
        lfsr_c[8] = lfsr_q[0] ^ lfsr_q[11] ^ lfsr_q[15] ^ data_in[3] ^ data_in[7];
        lfsr_c[9] = lfsr_q[1] ^ lfsr_q[12] ^ data_in[4];
        lfsr_c[10] = lfsr_q[2] ^ lfsr_q[13] ^ data_in[5];
        lfsr_c[11] = lfsr_q[3] ^ lfsr_q[14] ^ data_in[6];
        lfsr_c[12] = lfsr_q[4] ^ lfsr_q[8] ^ lfsr_q[12] ^ lfsr_q[15] ^ data_in[0] ^ data_in[4] ^ data_in[7];
        lfsr_c[13] = lfsr_q[5] ^ lfsr_q[9] ^ lfsr_q[13] ^ data_in[1] ^ data_in[5];
        lfsr_c[14] = lfsr_q[6] ^ lfsr_q[10] ^ lfsr_q[14] ^ data_in[2] ^ data_in[6];
        lfsr_c[15] = lfsr_q[7] ^ lfsr_q[11] ^ lfsr_q[15] ^ data_in[3] ^ data_in[7];

    end // always

    always @(posedge clk, negedge reset_n) begin
        if(!reset_n) begin
            lfsr_q <= INIT_VALUE;
        end else if (sync_reset) begin
            lfsr_q <= INIT_VALUE;
        end else begin
            lfsr_q <= crc_en ? lfsr_c : lfsr_q;
        end
    end // always
    
endmodule // crc16_CCITT

`default_nettype wire
