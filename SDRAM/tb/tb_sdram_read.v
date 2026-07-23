`timescale 1ns / 1ns

module tb_sdram_read ();

    reg         sys_clk;
    reg         sys_rst_n;
    reg         init_end;
    reg         rd_en;
    reg  [23:0] rd_addr;
    reg  [15:0] rd_data;
    reg  [ 9:0] rd_burst_len;
    wire        rd_ack;
    wire        rd_end;
    wire [ 3:0] read_cmd;
    wire [ 1:0] read_ba;
    wire [12:0] read_addr;
    wire [15:0] rd_sdram_data;

    always #10 sys_clk = !sys_clk;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) rd_data <= 16'd0;
        else if (rd_ack) rd_data <= rd_data + 16'd1;
    end

    sdram_read #() u_sdram_read (
        .sys_clk      (sys_clk),
        .sys_rst_n    (sys_rst_n),
        .init_end     (init_end),
        .rd_addr      (rd_addr),
        .rd_burst_len (rd_burst_len),
        .rd_data      (rd_data),
        .rd_en        (rd_en),
        .rd_ack       (rd_ack),
        .rd_end       (rd_end),
        .rd_sdram_data(rd_sdram_data),
        .read_addr    (read_addr),
        .read_ba      (read_ba),
        .read_cmd     (read_cmd)
    );

    initial begin
        sys_clk      = 0;
        sys_rst_n    = 0;
        init_end     = 0;
        rd_data      = 0;
        rd_en        = 0;
        rd_addr      = 24'h000_000;
        rd_burst_len = 10'd10;
        #100 sys_rst_n = 1;
        #50 init_end = 1;
        #50 rd_en = 1;

    end




endmodule
