`timescale 1ns / 1ns
module tb_sdram_write ();

    reg         sys_clk;
    reg         sys_rst_n;
    reg         init_end;
    reg         wr_en;
    reg  [23:0] wr_addr;
    reg  [15:0] wr_data;
    reg  [ 9:0] wr_burst_len;
    wire        wr_ack;
    wire        wr_end;
    wire [ 3:0] write_cmd;
    wire [ 1:0] write_ba;
    wire [12:0] write_addr;
    wire        wr_sdram_en;
    wire [15:0] wr_sdram_data;


    initial begin
        sys_clk      = 0;
        sys_rst_n    = 0;
        init_end     = 0;
        wr_data      = 0;
        wr_en        = 0;
        wr_addr      = 24'h000_000;
        wr_burst_len = 10'd10;
        #100 sys_rst_n = 1;
        #50 init_end = 1;
        #50 wr_en = 1;
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) wr_data <= 16'd0;
        else if (wr_ack) wr_data <= wr_data + 16'd1;
    end


    always #10 sys_clk = !sys_clk;

    sdram_write #() u_sdram_write (
        .sys_clk      (sys_clk),
        .sys_rst_n    (sys_rst_n),
        .init_end     (init_end),
        .wr_addr      (wr_addr),
        .wr_burst_len (wr_burst_len),
        .wr_data      (wr_data),
        .wr_en        (wr_en),
        .wr_ack       (wr_ack),
        .wr_end       (wr_end),
        .wr_sdram_data(wr_sdram_data),
        .wr_sdram_en  (wr_sdram_en),
        .write_addr   (write_addr),
        .write_ba     (write_ba),
        .write_cmd    (write_cmd)
    );

endmodule
