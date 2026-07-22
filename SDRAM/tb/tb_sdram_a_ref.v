`timescale 1ns / 1ns
module tb_sdram_a_ref ();

    reg         sys_clk;
    reg         sys_rst_n;
    reg         init_end;
    reg         aref_en;
    wire        aref_req;
    wire [ 3:0] aref_cmd;
    wire [ 1:0] aref_ba;
    wire [12:0] init_addr;
    wire        aref_end;

    initial begin
        sys_clk   = 0;
        sys_rst_n = 0;
        init_end  = 1;
        aref_en   = 0;
        #100 sys_rst_n = 1;
        #100 aref_en = 1;
    end

    always #10 sys_clk = !sys_clk;

    sdram_a_ref #() u_sdram_a_ref (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),
        .init_end (init_end),
        .aref_en  (aref_en),
        .aref_req (aref_req),
        .aref_cmd (aref_cmd),
        .aref_ba  (aref_ba),
        .aref_addr(aref_addr),
        .aref_end (aref_end)
    );
endmodule
