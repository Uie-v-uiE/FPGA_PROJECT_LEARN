module sdram_ctrl #(
) (
    input         sys_clk,
    input         sys_rst_n,
    input         sdram_wr_req,
    input  [23:0] sdram_wr_addr,
    input  [ 9:0] wr_burst_len,
    input  [15:0] sdram_data_in,
    input         sdram_rd_req,
    input  [23:0] sdram_rd_addr,
    input  [ 9:0] rd_burst_len,
    output        sdram_wr_ack,
    output [15:0] sdram_data_out,
    output        init_end,
    output        sdram_rd_ack,
    output        sdram_cke,
    output        sdram_cs_n,
    output        sdram_ras_n,
    output        sdram_cas_n,
    output        sdram_we_n,
    output [ 1:0] sdram_ba,
    output [12:0] sdram_addr,
    inout  [15:0] sdram_dq
);

    wire [ 3:0] init_cmd;
    wire [ 1:0] init_ba;
    wire [12:0] init_addr;
    wire        aref_req;
    wire [ 3:0] aref_cmd;
    wire [ 1:0] aref_ba;
    wire [12:0] aref_addr;
    wire        aref_end;
    wire        aref_en;
    wire        wr_en;
    wire        wr_end;
    wire [ 3:0] write_cmd;
    wire [ 1:0] write_ba;
    wire [12:0] write_addr;
    wire        wr_sdram_en;
    wire [15:0] wr_sdram_data;
    wire        rd_end;
    wire [ 3:0] read_cmd;
    wire [ 1:0] read_ba;
    wire [12:0] read_addr;
    wire        rd_en;

    sdram_init #() u_sdram_init (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),
        .init_cmd (init_cmd),
        .init_ba  (init_ba),
        .init_addr(init_addr),
        .init_end (init_end)
    );

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

    sdram_write #() u_sdram_write (
        .sys_clk      (sys_clk),
        .sys_rst_n    (sys_rst_n),
        .init_end     (init_end),
        .wr_en        (wr_en),
        .wr_addr      (sdram_wr_addr),
        .wr_data      (sdram_data_in),
        .wr_burst_len (wr_burst_len),
        .wr_ack       (sdram_wr_ack),
        .wr_end       (wr_end),
        .write_cmd    (write_cmd),
        .write_ba     (write_ba),
        .write_addr   (write_addr),
        .wr_sdram_en  (wr_sdram_en),
        .wr_sdram_data(wr_sdram_data)
    );

    sdram_read #() u_sdram_read (
        .sys_clk      (sys_clk),
        .sys_rst_n    (sys_rst_n),
        .init_end     (init_end),
        .rd_en        (rd_en),
        .rd_addr      (sdram_rd_addr),
        .rd_data      (sdram_dq),
        .rd_burst_len (rd_burst_len),
        .rd_ack       (sdram_rd_ack),
        .rd_end       (rd_end),
        .read_cmd     (read_cmd),
        .read_ba      (read_ba),
        .read_addr    (read_addr),
        .rd_sdram_data(sdram_data_out)
    );

    sdram_arbit #() sdram_arbit (
        .sys_clk    (sys_clk),
        .sys_rst_n  (sys_rst_n),
        .init_cmd   (init_cmd),
        .init_ba    (init_ba),
        .init_addr  (init_addr),
        .init_end   (init_end),
        .aref_req   (aref_req),
        .aref_cmd   (aref_cmd),
        .aref_ba    (aref_ba),
        .aref_addr  (aref_addr),
        .aref_end   (aref_end),
        .wr_req     (sdram_wr_req),
        .wr_cmd     (write_cmd),
        .wr_ba      (write_ba),
        .wr_addr    (write_addr),
        .wr_sdram_en(wr_sdram_en),
        .wr_data    (wr_sdram_data),
        .wr_end     (wr_end),
        .rd_req     (sdram_rd_req),
        .rd_cmd     (read_cmd),
        .rd_ba      (read_ba),
        .rd_addr    (read_addr),
        .rd_end     (rd_end),
        .aref_en    (aref_en),
        .wr_en      (wr_en),
        .rd_en      (rd_en),
        .sdram_cke  (sdram_cke),
        .sdram_cs_n (sdram_cs_n),
        .sdram_cas_n(sdram_cas_n),
        .sdram_ras_n(sdram_ras_n),
        .sdram_we_n (sdram_we_n),
        .sdram_ba   (sdram_ba),
        .sdram_addr (sdram_addr),
        .sdram_dq   (sdram_dq)
    );
endmodule
