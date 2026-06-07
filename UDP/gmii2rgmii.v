module gmii2rgmii (

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
        for (i = 0; i < 4; i = i + 1) begin : rgmii_tx_data
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

