`timescale 1ns / 1ns
module UDP_send #(

) (
    input        clk,
    input        rst_n,
    input        data_en,
    input [15:0] eth_type,
    input [47:0] dst_mac_addr,
    input [47:0] src_mac_addr,
    input [31:0] FCS,
    input [ 3:0] ver,
    input [ 3:0] hdr_len,
    input [ 7:0] tos,
    input [15:0] total_len,
    input [15:0] id,
    input [15:0] offset,
    input [ 7:0] ttl,
    input [ 7:0] protocol,
    input [31:0] src_ip,
    input [31:0] dst_ip,
    input [15:0] src_port,
    input [15:0] dst_port,
    input [15:0] udp_len
);

    wire [15:0] checksum_result;
    wire        gmii_tx_er;
    wire [15:0] udp_result;
    wire [ 7:0] gmii_tx_data;
    wire [ 7:0] fifo_data;


    gmii2rgmii u_gmii2rgmii (
        .gmii_tx_clk   (sys_clk),
        .gmii_tx_clk_en(1),
        .gmii_tx_rst_n (rst_n),
        .gmii_tx_en    (1),
        .gmii_tx_er    (gmii_tx_er),
        .gmii_tx_data  (),
        .rgmii_tx_clk  (),
        .rgmii_tx_ctrl (),
        .rgmii_tx_data ()
    );

    check_sum_ip u_check_sum_ip (
        .ver            (ver),
        .hdr_len        (hdr_len),
        .tos            (tos),
        .total_len      (total_len),
        .id             (id),
        .offset         (offset),
        .ttl            (ttl),
        .protocol       (protocol),
        .src_ip         (src_ip),
        .dst_ip         (dst_ip),
        .checksum_result(checksum_result)
    );

    crc32_d8 u_crc32_d8 (
        .clk     (sys_clk),
        .rst_n   (rst_n),
        .data    (gmii_tx_data),
        .crc_en  (),
        .crc_clr (),
        .crc_data()
    );

    UDP_tx u_UDP_tx (
        .clk            (sys_clk),
        .rst_n          (rst_n),
        .data_en        (data_en),
        .eth_type       (eth_type),
        .dst_mac_addr   (dst_mac_addr),
        .src_mac_addr   (src_mac_addr),
        .FCS            (FCS),
        .ver            (ver),
        .hdr_len        (hdr_len),
        .tos            (tos),
        .total_len      (total_len),
        .id             (id),
        .offset         (offset),
        .ttl            (ttl),
        .protocol       (protocol),
        .src_ip         (src_ip),
        .dst_ip         (dst_ip),
        .checksum_result(checksum_result),
        .src_port       (src_port),
        .dst_port       (dst_port),
        .udp_len        (udp_len),
        .udp_result     (udp_result),
        .fifo_data      (fifo_data),
        .gmii_tx_clk    (gmii_tx_clk),
        .gmii_tx_clk_en (gmii_tx_clk_en),
        .gmii_tx_rst_n  (gmii_tx_rst_n),
        .gmii_tx_en     (gmii_tx_en),
        .gmii_tx_er     (gmii_tx_er),
        .gmii_tx_data   (gmii_tx_data)
    );


endmodule
