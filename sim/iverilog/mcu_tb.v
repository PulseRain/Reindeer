`timescale 1ns / 100ps

`include "RV2T_common.vh"


module mcu_test();

    //=====================================================================
    // clock and reset
    //=====================================================================
        reg                                            clk;                          
        reg                                            reset_n;                      
        reg                                            sync_reset;

    //=====================================================================
    // Interface Onchip Debugger
    //=====================================================================
      //==  input   wire                                            run1_pause0;

        reg                                            ocd_read_enable;
        reg                                            ocd_write_enable;

        reg  [`MEM_ADDR_BITS - 1 : 0]                  ocd_rw_addr;
        reg  [`XLEN - 1 : 0]                           ocd_write_word;

        wire                                            ocd_mem_enable_out;
        wire  [`XLEN - 1 : 0]                           ocd_mem_word_out;        

        reg  [`REG_ADDR_BITS - 1 : 0]                  ocd_reg_read_addr;
        reg                                             ocd_reg_we;
        reg  [`REG_ADDR_BITS - 1 : 0]                  ocd_reg_write_addr;
        reg  [`XLEN - 1 : 0]                           ocd_reg_write_data;

    //=====================================================================
    // UART
    //=====================================================================
        wire                                            TXD;
        
    //=====================================================================
    // Interface for init/start
    //=====================================================================
        reg                                             start;
        reg  [`PC_BITWIDTH - 1 : 0]                    start_address;

        wire                                            processor_paused;

        wire  [`XLEN - 1 : 0]                           peek_pc;
        wire  [`XLEN - 1 : 0]                           peek_ir;

        wire  [`XLEN_BYTES - 1 : 0]                     peek_mem_write_en;
        wire  [`XLEN - 1 : 0]                           peek_mem_write_data;
        wire [`MEM_ADDR_BITS - 1 : 0]                   peek_mem_addr;


    PulseRain_RV2T_MCU PulseRain_RV2T_MCU_i(
        .clk (clk),
        .reset_n (reset_n),
        .sync_reset (sync_reset),

        .ocd_read_enable (ocd_read_enable),
        .ocd_write_enable (ocd_write_enable),

        .ocd_rw_addr (ocd_rw_addr),
        .ocd_write_word (ocd_write_word),

        .ocd_mem_enable_out (ocd_mem_enable_out),
        .ocd_mem_word_out (ocd_mem_word_out),

        .ocd_reg_read_addr (ocd_reg_read_addr),
        .ocd_reg_we (ocd_reg_we),
        .ocd_reg_write_addr (ocd_reg_write_addr),
        .ocd_reg_write_data (ocd_reg_write_data),

        .TXD (TXD),

        .start (start),
        .start_address (start_address),

        .processor_paused (processor_paused),

        .peek_pc (peek_pc),
        .peek_ir (peek_ir),

        .peek_mem_write_en (peek_mem_write_en),
        .peek_mem_write_data (peek_mem_write_data),
        .peek_mem_addr (peek_mem_addr)
    );

  initial begin
    clk = 1'b0;
    reset_n = 1'b0;
    repeat(4) #10 clk = ~clk;
    reset_n = 1'b1;
    forever #10 clk = ~clk; // generate a clock
  end

integer File;
integer r;
integer i;
integer addr;
reg[31:0] elf_buf;
reg[127:0] reference_buf [0:25];

// elf file header
reg[15:0] e_type;
reg[15:0] e_machine;
reg[31:0] e_entry;
reg[31:0] e_phoff;
reg[15:0] e_phentsize;
reg[15:0] e_phnum;

reg[31:0] p_type;
reg[31:0] p_offset;
reg[31:0] p_vaddr;
reg[31:0] p_paddr;
reg[31:0] p_filesz;

localparam PT_LOAD = 32'h1;

function [15:0] swap_16(input [15:0] in);
    swap_16 =  {in[7:0], in[15:8]};
endfunction

function [31:0] swap_32(input [31:0] in);
    swap_32 =  {in[7:0], in[15:8], in[23:16], in[31:24]};
endfunction

initial begin
        $dumpvars(0, PulseRain_RV2T_MCU_i);

        // Reset the CPU
        sync_reset = 0;
        ocd_reg_we = 0;
        ocd_reg_read_addr = 0;
        ocd_reg_write_addr = 0;
        ocd_reg_write_data = 0;
        ocd_read_enable = 0;
        ocd_write_enable = 0;
        ocd_rw_addr = 0;
        ocd_write_word = 0;
        start = 0;
        start_address = 32'h80000000;

        #1

        // open the file
        File = $fopen("../compliance/I-ADD-01.elf", "rb");
        if (!File) begin
            $display("Could not open \"result.dat\"");
            $finish;
        end

        // check elf header
        r = $fseek(File, 16, 0);
        r = $fread(e_type, File); e_type = swap_16(e_type);
        r = $fseek(File, 18, 0);
        r = $fread(e_machine, File); e_machine = swap_16(e_type);
        r = $fseek(File, 24, 0);
        r = $fread(e_entry, File); e_entry = swap_32(e_entry);

        r = $fseek(File, 28, 0);
        r = $fread(e_phoff, File); e_phoff = swap_32(e_phoff);
        r = $fseek(File, 42, 0);
        r = $fread(e_phentsize, File); e_phentsize = swap_16(e_phentsize);
        r = $fseek(File, 44, 0);
        r = $fread(e_phnum, File); e_phnum = swap_16(e_phnum);

        $display("type:0x%h, machine:0x%h, entry:0x%h", e_type, e_machine, e_entry);
        $display("phoff: %h, phent: %h, phnum: %h", e_phoff, e_phentsize, e_phnum);

        if (e_type != 2 || e_machine != 16'h0200) begin
            $display("Not a RISC-V Executable");
            $finish;
        end

        for (i = 0; i < e_phnum; i = i + 1) begin
            r = $fseek(File, e_phoff + i * e_phentsize, 0);
            r = $fread(p_type, File); p_type = swap_32(p_type);
            r = $fread(p_offset, File); p_offset = swap_32(p_offset);
            r = $fread(p_vaddr, File); p_vaddr = swap_32(p_vaddr);
            r = $fread(p_paddr, File); p_paddr = swap_32(p_paddr);
            r = $fread(p_filesz, File); p_filesz = swap_32(p_filesz);

            $display("program header: %d: %h %h %h %h", i, p_type, p_offset, p_vaddr, p_filesz);

            if (p_type & PT_LOAD) begin
                // Load the section
                ocd_write_enable = 1;
                r = $fseek(File, p_offset, 0);
                for (addr = p_vaddr; addr < p_vaddr + p_filesz; addr = addr + 4) begin
                    r = $fread(elf_buf, File);
                    elf_buf = swap_32(elf_buf);

                    ocd_rw_addr = addr >> 2;
                    ocd_write_word = elf_buf;
                    @(posedge clk);
                    // $display("%h = %h", ocd_rw_addr * 4, ocd_write_word);
                end
                ocd_write_enable = 0;
                @(posedge clk);
            end
        end
        $fclose(File);

        // start the CPU
        start = 1;
        i = 0;
        repeat(2000) begin
            if (peek_mem_write_en)
                $display("%d\t%08h\t%08h\t %08h\t%08h", i, peek_pc, peek_ir, peek_mem_addr, peek_mem_write_data);
            else
                $display("%d\t%08h\t%08h", i, peek_pc, peek_ir);
            @(posedge clk);
            i = i + 1;
        end

        // TODO: check the result
        /* $readmemh("../compliance/references/I-ADD-01.reference_output", reference_buf);
        for(i=0; i < 255 && ~(^reference_buf[i] === 1'bX); i = i + 1) begin
                $display("%d: %h", i, reference_buf[i]);
        end
        */
        
        // display error/success
        $finish;
end


endmodule
