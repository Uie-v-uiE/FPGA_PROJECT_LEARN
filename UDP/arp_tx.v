`timescale 1ns / 1ns
module arp_tx #(
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
    input            sys_clk,
    input            sys_rst_n,
    input            arp_data_en,
    input      [7:0] arp_tx_data,
    input      [7:0] arp_crc_32,
    output           gmii_tx_clk,
    output           gmii_tx_clk_en,
    output           gmii_tx_rst_n,
    output           gmii_tx_en,
    output           gmii_tx_er,
    output reg [7:0] gmii_tx_data
);

    reg [6:0] cnt;
    reg [4:0] cnt_data;
    reg [3:0] cnt_crc;

    assign gmii_tx_clk    = sys_clk;
    assign gmii_tx_clk_en = 1;
    assign gmii_tx_rst_n  = sys_rst_n;
    assign gmii_tx_en     = arp_data_en;
    assign gmii_tx_er     = 1'b0;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt      <= 7'd0;
            cnt_data <= 5'd18;
            cnt_crc  <= 3'd4;
        end else if (arp_data_en) begin
            if (cnt == 45 && cnt_data > 1) begin
                cnt_data <= cnt_data - 1'b1;
            end else if (cnt == 46 && cnt_crc > 1) begin
                cnt_crc <= cnt_crc - 1'b1;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end else begin
            cnt      <= 7'd0;
            cnt_data <= 5'd18;
        end
    end

    always @(*) begin
        case (cnt)
            7'd1:    gmii_tx_data = PREAMBLE[55:48];
            7'd2:    gmii_tx_data = PREAMBLE[47:40];
            7'd3:    gmii_tx_data = PREAMBLE[39:32];
            7'd4:    gmii_tx_data = PREAMBLE[31:24];
            7'd5:    gmii_tx_data = PREAMBLE[23:16];
            7'd6:    gmii_tx_data = PREAMBLE[15:8];
            7'd7:    gmii_tx_data = PREAMBLE[7:0];
            7'd8:    gmii_tx_data = SFD;
            7'd9:    gmii_tx_data = DES_RADIO_ADDRESS[47:40];
            7'd10:   gmii_tx_data = DES_RADIO_ADDRESS[39:32];
            7'd11:   gmii_tx_data = DES_RADIO_ADDRESS[31:24];
            7'd12:   gmii_tx_data = DES_RADIO_ADDRESS[23:16];
            7'd13:   gmii_tx_data = DES_RADIO_ADDRESS[15:8];
            7'd14:   gmii_tx_data = DES_RADIO_ADDRESS[7:0];
            7'd15:   gmii_tx_data = SRC_MAC_ADDRESS[47:40];
            7'd16:   gmii_tx_data = SRC_MAC_ADDRESS[39:32];
            7'd17:   gmii_tx_data = SRC_MAC_ADDRESS[31:24];
            7'd18:   gmii_tx_data = SRC_MAC_ADDRESS[23:16];
            7'd19:   gmii_tx_data = SRC_MAC_ADDRESS[15:8];
            7'd20:   gmii_tx_data = SRC_MAC_ADDRESS[7:0];
            7'd21:   gmii_tx_data = ETH_TYPE_ARP[15:8];
            7'd22:   gmii_tx_data = ETH_TYPE_ARP[7:0];
            7'd23:   gmii_tx_data = HARDWARE_TYPE[15:8];
            7'd24:   gmii_tx_data = HARDWARE_TYPE[7:0];
            7'd25:   gmii_tx_data = IP_TYPE[15:8];
            7'd26:   gmii_tx_data = IP_TYPE[7:0];
            7'd27:   gmii_tx_data = MAC_ADDRESS_LEN;
            7'd28:   gmii_tx_data = IP_ADDRESS_LEN;
            7'd29:   gmii_tx_data = ARP_OPCODE_REQUEST[15:0];
            7'd30:   gmii_tx_data = ARP_OPCODE_REQUEST[7:0];
            7'd31:   gmii_tx_data = SRC_MAC_ADDRESS[47:40];
            7'd32:   gmii_tx_data = SRC_MAC_ADDRESS[39:32];
            7'd33:   gmii_tx_data = SRC_MAC_ADDRESS[31:24];
            7'd34:   gmii_tx_data = SRC_MAC_ADDRESS[23:16];
            7'd35:   gmii_tx_data = SRC_MAC_ADDRESS[15:8];
            7'd36:   gmii_tx_data = SRC_MAC_ADDRESS[7:0];
            7'd37:   gmii_tx_data = SRC_IP_ADDRESS[31:24];
            7'd38:   gmii_tx_data = SRC_IP_ADDRESS[23:16];
            7'd39:   gmii_tx_data = SRC_IP_ADDRESS[15:8];
            7'd40:   gmii_tx_data = SRC_IP_ADDRESS[7:0];
            7'd41:   gmii_tx_data = DES_MAC_ADDRESS[47:40];
            7'd42:   gmii_tx_data = DES_MAC_ADDRESS[39:32];
            7'd43:   gmii_tx_data = DES_MAC_ADDRESS[31:24];
            7'd44:   gmii_tx_data = DES_MAC_ADDRESS[23:16];
            7'd45:   gmii_tx_data = DES_MAC_ADDRESS[15:8];
            7'd46:   gmii_tx_data = DES_MAC_ADDRESS[7:0];
            7'd47:   gmii_tx_data = arp_tx_data;
            7'd48:   gmii_tx_data = arp_crc_32;
            default: gmii_tx_data = 8'd0;
        endcase
    end


endmodule
