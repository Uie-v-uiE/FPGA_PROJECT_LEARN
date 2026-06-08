`timescale 1ns / 1ns
module arp #(
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
    input        sys_clk,
    input        sys_rst_n,
    input  [7:0] rx_data,
    output [7:0] tx_data
);

    arp_tx u_arp_tx (
        .clk           (sys_clk),
        .rst_n         (sys_rst_n),
        .arp_data_en   (data_en),
        .arp_crc_32    (crc_32),
        .arp_tx_data   (arp_tx_data),
        .gmii_tx_clk   (sys_clk),
        .gmii_tx_clk_en(gmii_tx_clk_en),
        .gmii_tx_data  (gmii_tx_data),
        .gmii_tx_en    (gmii_tx_en),
        .gmii_tx_er    (gmii_tx_er),
        .gmii_tx_rst_n (gmii_tx_rst_n)
    );

    crc32_d8 u_crc_d8 (
        .clk     (sys_clk),
        .rst_n   (sys_rst_n),
        .crc_clr (crc_clr),
        .crc_en  (crc_en),
        .crc_data(crc_data),
        .crc_en  (crc_en),
        .crc_next(crc_next),
        .data    (data)
    );

    gmii2rgmii u_gmii2rgmii (
          .gmii_tx_clk   (sys_clk),
          .gmii_tx_clk_en(gmii_tx_clk_en),
          .gmii_tx_data  (expr),
          .gmii_tx_en    (expr),
          .gmii_tx_er    (expr),
          .gmii_tx_rst_n (expr),
          .rgmii_tx_clk  (expr),
          .rgmii_tx_ctrl (expr)
        , .rgmii_tx_data (expr)
    );

    rgmii2gmii u_rgmii2gmii (
        .gmii_rx_clk       (expr),
        .gmii_rx_data      (expr),
        .gmii_rx_data_valid(expr),
        .gmii_rx_er        (expr),
        .rgmii_rx_clk      (expr),
        .rgmii_rx_clk_en   (expr),
        .rgmii_rx_ctrl     (expr),
        .rgmii_rx_data     (expr),
        .rgmii_rx_rst_n    (expr)
    );

    arp_rx u_arp_rx (
        .clk  (sys_clk),
        .rst_n(sys_rst_n),
        .data (data)
    );


endmodule
