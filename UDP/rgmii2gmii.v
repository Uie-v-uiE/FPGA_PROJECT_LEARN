`timescale 1ns / 1ns (* blackbox *)
module IDDR #(
    parameter DDR_CLK_EDGE = "SAME_EDGE_PIPELINED",
    parameter INIT_Q1      = 1'b0,
    parameter INIT_Q2      = 1'b0,
    parameter SRTYPE       = "ASYNC"
) (
    input  C,
    input  CE,
    input  D,
    input  R,
    input  S,
    output Q1,
    output Q2
);
endmodule

module rgmii2gmii #(
    parameter [55:0] PREAMBLE           = 56'h55_55_55_55_55_55_55,
    parameter [ 7:0] SFD                = 8'hd5,
    parameter [47:0] DES_MAC_ADDRESS_PC = 48'h88_d8_2e_49_a0_b6,
    parameter [47:0] DES_MAC_ADDRESS    = 48'h00_00_00_00_00_00,
    parameter [47:0] DES_RADIO_ADDRESS  = 48'hff_ff_ff_ff_ff_ff,
    parameter [47:0] SRC_MAC_ADDRESS    = 48'h00_0a_35_10_20_16,
    parameter [15:0] ETH_TYPE_ARP       = 16'h08_06,
    parameter [15:0] HARDWARE_TYPE      = 16'h00_01,
    parameter [15:0] IP_TYPE            = 16'h08_00,
    parameter [ 7:0] MAC_ADDRESS_LEN    = 8'h6,
    parameter [ 7:0] IP_ADDRESS_LEN     = 8'h4,
    parameter [15:0] ARP_OPCODE_REQUEST = 16'h00_01,
    parameter [15:0] ARP_OPCODE_REPLY   = 16'h00_02,
    parameter [31:0] SRC_IP_ADDRESS     = 32'hc0_a8_01_66
) (
    input        rgmii_rx_clk,
    input        rgmii_rx_rst_n,
    input        rgmii_rx_clk_en,
    input        rgmii_rx_ctrl,
    input  [3:0] rgmii_rx_data,
    output       gmii_rx_clk,
    output       gmii_rx_data_valid,
    output       gmii_rx_er,
    output [7:0] gmii_rx_data
);

    wire gmii_rx_data_valid_xor_gmii_rx_er;

    assign gmii_rx_er  = gmii_rx_data_valid_xor_gmii_rx_er ^ gmii_rx_data_valid;

    assign gmii_rx_clk = rgmii_rx_clk;

    IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),  // "OPPOSITE_EDGE", "SAME_EDGE" 
        //    or "SAME_EDGE_PIPELINED" 
        .INIT_Q1     (1'b0),                   // Initial value of Q1: 1'b0 or 1'b1
        .INIT_Q2     (1'b0),                   // Initial value of Q2: 1'b0 or 1'b1
        .SRTYPE      ("ASYNC")                 // Set/Reset type: "SYNC" or "ASYNC" 
    ) IDDR_inst (
        .Q1(gmii_rx_data_valid),                 // 1-bit output for positive edge of clock
        .Q2(gmii_rx_data_valid_xor_gmii_rx_er),  // 1-bit output for negative edge of clock
        .C (rgmii_rx_clk),                       // 1-bit clock input
        .CE(rgmii_rx_clk_en),                    // 1-bit clock enable input
        .D (rgmii_rx_ctrl),                      // 1-bit DDR data input
        .R (~rgmii_rx_rst_n),                    // 1-bit reset
        .S (1'b0)                                // 1-bit set
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : inst_iddr
            IDDR #(
                .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),  // "OPPOSITE_EDGE", "SAME_EDGE" 
                //    or "SAME_EDGE_PIPELINED" 
                .INIT_Q1     (1'b0),                   // Initial value of Q1: 1'b0 or 1'b1
                .INIT_Q2     (1'b0),                   // Initial value of Q2: 1'b0 or 1'b1
                .SRTYPE      ("ASYNC")                 // Set/Reset type: "SYNC" or "ASYNC" 
            ) IDDR_inst0 (
                .Q1(gmii_rx_data[i]),    // 1-bit output for positive edge of clock
                .Q2(gmii_rx_data[i+4]),  // 1-bit output for negative edge of clock
                .C (rgmii_rx_clk),       // 1-bit clock input
                .CE(rgmii_rx_clk_en),    // 1-bit clock enable input
                .D (rgmii_rx_data[i]),   // 1-bit DDR data input
                .R (~rgmii_rx_rst_n),    // 1-bit reset
                .S (1'b0)                // 1-bit set
            );
        end
    endgenerate

endmodule
