module rgmii2gmii (
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
        for (i = 0; i < 4; i = i + 1) begin : rgmii_rx_data
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
