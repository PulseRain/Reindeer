

`default_nettype none

module SP256K (

    input wire [13:0] AD,
    input wire [15:0] DI,
    input wire [3:0] MASKWE,
    input wire WE,
    input wire CS,
    input wire CK,
    input wire STDBY,
    input wire SLEEP,
    input wire PWROFF_N,
    output wire [15:0] DO
);


    wire [13 : 0]         addr;
    wire [15 : 0]         din;
    wire [1 : 0]          write_en;
    wire                  clk;
    reg [15 : 0]          dout;
    
    assign clk = CK;
    assign DO = dout;
    assign addr = AD;
    assign din = DI;
    assign write_en = {WE & MASKWE [2], WE & MASKWE [0]};
    
    

    reg [15 : 0] mem [(1<<14)-1:0];
    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin : gen_proc
            always @(posedge clk) begin
                if (write_en[i]) begin
                    mem[(addr)][8 * (i + 1) - 1 : 8 * i] <= din[8 * (i + 1) - 1 : 8 * i];
                end
            end
        end
    endgenerate
 
    always @(posedge clk) begin
        dout <= mem[addr];
    end

endmodule

`default_nettype wire
