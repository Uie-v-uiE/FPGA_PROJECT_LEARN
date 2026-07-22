`timescale 1ns / 1ns

module tb_sdram_init ();

    reg  sys_clk;
    reg  sys_rst_n;
    wire init_cmd;
    wire init_ba;
    wire init_addr;
    wire init_end;

    initial begin
        sys_clk   = 0;
        sys_rst_n = 0;
        #200 sys_rst_n = 1;
    end

    always #10 sys_clk = !sys_clk;

    sdram_init #(
        .T_POWER(15'd20)
    ) u_sdram_init (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),
        .init_addr(init_addr),
        .init_ba  (init_ba),
        .init_cmd (init_cmd),
        .init_end (init_end)
    );
endmodule
