`timescale 1ns / 1ns (* blackbox *)
module ODDR #(
    parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
    parameter INIT         = 1'b0,
    parameter SRTYPE       = "SYNC"
) (
    input  C,
    input  CE,
    input  D1,
    input  D2,
    input  R,
    input  S,
    output Q
);
endmodule

module gmii2rgmii #(
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

    input        gmii_tx_clk,
    input        gmii_tx_clk_en,
    input        gmii_tx_rst_n,
    input        gmii_tx_en,
    input        gmii_tx_er,
    input  [7:0] gmii_tx_data,
    output       rgmii_tx_clk,
    output       rgmii_tx_ctrl,
    output [3:0] rgmii_tx_data
);

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),  // "OPPOSITE_EDGE" or "SAME_EDGE" 
        .INIT        (1'b0),         // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE      ("ASYNC")       // Set/Reset type: "SYNC" or "ASYNC" 
    ) ODDR_inst1 (
        .Q (rgmii_tx_ctrl),            // 1-bit DDR output
        .C (gmii_tx_clk),              // 1-bit clock input
        .CE(gmii_tx_clk_en),           // 1-bit clock enable input
        .D1(gmii_tx_en),               // 1-bit data input (positive edge)
        .D2(gmii_tx_en ^ gmii_tx_er),  // 1-bit data input (negative edge)
        .R (~gmii_tx_rst_n),           // 1-bit reset
        .S (1'b0)                      // 1-bit set
    );

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),  // "OPPOSITE_EDGE" or "SAME_EDGE" 
        .INIT        (1'b0),         // Initial value of Q: 1'b0 or 1'b1
        .SRTYPE      ("ASYNC")       // Set/Reset type: "SYNC" or "ASYNC" 
    ) ODDR_inst2 (
        .Q (rgmii_tx_clk),    // 1-bit DDR output
        .C (gmii_tx_clk),     // 1-bit clock input
        .CE(gmii_tx_clk_en),  // 1-bit clock enable input
        .D1(1'b1),            // 1-bit data input (positive edge)
        .D2(1'b0),            // 1-bit data input (negative edge)
        .R (~gmii_tx_rst_n),  // 1-bit reset
        .S (1'b0)             // 1-bit set
    );

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : inst_oddr
            ODDR #(
                .DDR_CLK_EDGE("SAME_EDGE"),  // "OPPOSITE_EDGE" or "SAME_EDGE" 
                .INIT        (1'b0),         // Initial value of Q: 1'b0 or 1'b1
                .SRTYPE      ("ASYNC")       // Set/Reset type: "SYNC" or "ASYNC" 
            ) ODDR_inst0 (
                .Q (rgmii_tx_data[i]),   // 1-bit DDR output
                .C (gmii_tx_clk),        // 1-bit clock input
                .CE(gmii_tx_clk_en),     // 1-bit clock enable input
                .D1(gmii_tx_data[i]),    // 1-bit data input (positive edge)
                .D2(gmii_tx_data[i+4]),  // 1-bit data input (negative edge)
                .R (~gmii_tx_rst_n),     // 1-bit reset
                .S (1'b0)                // 1-bit set
            );

        end
    endgenerate


endmodule

