`timescale 1ns / 1ns
module arp_rx #(
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
    input  clk,
    input  rst_n,
    input  data,
    output rgmii_data
);


    always @(posedge clk or negedge rst_n) begin
        if (rst_n) begin

        end
    end
endmodule
