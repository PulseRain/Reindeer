//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Sat Dec 22 16:32:38 2018
// Version: v11.9 SP1 11.9.1.0
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// creative
module creative(
    // Inputs
    RXD,
    osc_in,
    // Outputs
    LED_GREEN,
    LED_RED,
    TXD
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  RXD;
input  osc_in;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output LED_GREEN;
output LED_RED;
output TXD;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   FCCC_0_GL0;
wire   FCCC_0_LOCK;
wire   LED_GREEN_net_0;
wire   LED_RED_net_0;
wire   osc_in;
wire   RXD;
wire   TXD_net_0;
wire   LED_GREEN_net_1;
wire   LED_RED_net_1;
wire   TXD_net_1;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire   GND_net;
wire   [7:2]PADDR_const_net_0;
wire   [7:0]PWDATA_const_net_0;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign GND_net            = 1'b0;
assign PADDR_const_net_0  = 6'h00;
assign PWDATA_const_net_0 = 8'h00;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign LED_GREEN_net_1 = LED_GREEN_net_0;
assign LED_GREEN       = LED_GREEN_net_1;
assign LED_RED_net_1   = LED_RED_net_0;
assign LED_RED         = LED_RED_net_1;
assign TXD_net_1       = TXD_net_0;
assign TXD             = TXD_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------creative_FCCC_0_FCCC   -   Actel:SgCore:FCCC:2.0.201
creative_FCCC_0_FCCC FCCC_0(
        // Inputs
        .CLK0_PAD ( osc_in ),
        // Outputs
        .GL0      ( FCCC_0_GL0 ),
        .LOCK     ( FCCC_0_LOCK ) 
        );

//--------Reindeer
Reindeer Reindeer_0(
        // Inputs
        .clk              ( FCCC_0_GL0 ),
        .reset_n          ( FCCC_0_LOCK ),
        .RXD              ( RXD ),
        // Outputs
        .TXD              ( TXD_net_0 ),
        .processor_active ( LED_GREEN_net_0 ),
        .processor_paused ( LED_RED_net_0 ) 
        );


endmodule
