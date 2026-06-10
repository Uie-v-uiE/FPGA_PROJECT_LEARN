`timescale 1ns / 1ns
module UDP_tx #(
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
    input             clk,
    input             rst_n,
    input             data_en,
    input      [15:0] eth_type,
    input      [47:0] dst_mac_addr,
    input      [47:0] src_mac_addr,
    input      [31:0] FCS,
    input      [ 3:0] ver,
    input      [ 3:0] hdr_len,
    input      [ 7:0] tos,
    input      [15:0] total_len,
    input      [15:0] id,
    input      [15:0] offset,
    input      [ 7:0] ttl,
    input      [ 7:0] protocol,
    input      [31:0] src_ip,
    input      [31:0] dst_ip,
    input      [15:0] checksum_result,
    input      [15:0] src_port,
    input      [15:0] dst_port,
    input      [15:0] udp_len,
    input      [15:0] udp_result,
    input      [ 7:0] fifo_data,
    output            gmii_tx_clk,
    output            gmii_tx_clk_en,
    output            gmii_tx_rst_n,
    output            gmii_tx_en,
    output            gmii_tx_er,
    output reg [ 7:0] gmii_tx_data
);

    reg        data_en_reg;
    reg [15:0] eth_type_reg;
    reg [47:0] dst_mac_addr_reg;
    reg [47:0] src_mac_addr_reg;
    reg [31:0] FCS_reg;
    reg [ 3:0] ver_reg;
    reg [ 3:0] hdr_len_reg;
    reg [ 7:0] tos_reg;
    reg [15:0] total_len_reg;
    reg [15:0] id_reg;
    reg [15:0] offset_reg;
    reg [ 7:0] ttl_reg;
    reg [ 7:0] protocol_reg;
    reg [31:0] src_ip_reg;
    reg [31:0] dst_ip_reg;
    reg [15:0] checksum_result_reg;
    reg [15:0] src_port_reg;
    reg [15:0] dst_port_reg;
    reg [15:0] udp_len_reg;
    reg [15:0] udp_result_reg;
    reg [ 7:0] fifo_data_reg;

    reg [ 6:0] cnt;
    reg [13:0] cnt_data;

    assign gmii_tx_clk    = clk;
    assign gmii_tx_clk_en = 1;
    assign gmii_tx_rst_n  = rst_n;
    assign gmii_tx_en     = data_en;
    assign gmii_tx_er     = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_en_reg         <= 1'd0;
            eth_type_reg        <= 16'd0;
            dst_mac_addr_reg    <= 48'd0;
            src_mac_addr_reg    <= 48'd0;
            FCS_reg             <= 32'd0;
            ver_reg             <= 4'd0;
            hdr_len_reg         <= 4'd0;
            tos_reg             <= 8'd0;
            total_len_reg       <= 16'd0;
            id_reg              <= 16'd0;
            offset_reg          <= 16'd0;
            ttl_reg             <= 8'd0;
            protocol_reg        <= 8'd0;
            src_ip_reg          <= 32'd0;
            dst_ip_reg          <= 32'd0;
            checksum_result_reg <= 16'd0;
            src_port_reg        <= 16'd0;
            dst_port_reg        <= 16'd0;
            udp_len_reg         <= 16'd0;
            udp_result_reg      <= 16'd0;
            fifo_data_reg       <= 8'd0;
        end else begin
            data_en_reg         <= data_en;
            eth_type_reg        <= eth_type;
            dst_mac_addr_reg    <= dst_mac_addr;
            src_mac_addr_reg    <= src_mac_addr;
            FCS_reg             <= FCS;
            ver_reg             <= ver;
            hdr_len_reg         <= hdr_len;
            tos_reg             <= tos;
            total_len_reg       <= total_len;
            id_reg              <= id;
            offset_reg          <= offset;
            ttl_reg             <= ttl;
            protocol_reg        <= protocol;
            src_ip_reg          <= src_ip;
            dst_ip_reg          <= dst_ip;
            checksum_result_reg <= checksum_result;
            src_port_reg        <= src_port;
            dst_port_reg        <= dst_port;
            udp_len_reg         <= udp_len;
            udp_result_reg      <= udp_result;
            fifo_data_reg       <= fifo_data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt      <= 7'd0;
            cnt_data <= 14'd0;
        end else if (data_en) begin
            if (cnt == 7'd51 && cnt_data < udp_len_reg - 16'd1) begin
                cnt_data <= cnt_data + 14'd1;
            end else begin
                cnt <= cnt + 7'd1;
            end
        end else begin
            cnt      <= 7'd0;
            cnt_data <= 14'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        case (cnt)
            7'd1:  gmii_tx_data = PREAMBLE[55:48];
            7'd2:  gmii_tx_data = PREAMBLE[47:40];
            7'd3:  gmii_tx_data = PREAMBLE[39:32];
            7'd4:  gmii_tx_data = PREAMBLE[31:24];
            7'd5:  gmii_tx_data = PREAMBLE[23:16];
            7'd6:  gmii_tx_data = PREAMBLE[15:8];
            7'd7:  gmii_tx_data = PREAMBLE[7:0];
            7'd8:  gmii_tx_data = SFD;
            7'd9:  gmii_tx_data = dst_mac_addr_reg[47:40];
            7'd10: gmii_tx_data = dst_mac_addr_reg[39:32];
            7'd11: gmii_tx_data = dst_mac_addr_reg[31:24];
            7'd12: gmii_tx_data = dst_mac_addr_reg[23:16];
            7'd13: gmii_tx_data = dst_mac_addr_reg[15:8];
            7'd14: gmii_tx_data = DES_RADIO_ADDRESS[7:0];
            7'd15: gmii_tx_data = src_mac_addr_reg[47:40];
            7'd16: gmii_tx_data = src_mac_addr_reg[39:32];
            7'd17: gmii_tx_data = src_mac_addr_reg[31:24];
            7'd18: gmii_tx_data = src_mac_addr_reg[23:16];
            7'd19: gmii_tx_data = src_mac_addr_reg[15:8];
            7'd20: gmii_tx_data = src_mac_addr_reg[7:0];
            7'd21: gmii_tx_data = eth_type_reg[15:8];
            7'd22: gmii_tx_data = eth_type_reg[7:0];
            7'd23: gmii_tx_data = {ver_reg, hdr_len_reg};
            7'd24: gmii_tx_data = tos_reg;
            7'd25: gmii_tx_data = total_len_reg[15:8];
            7'd26: gmii_tx_data = total_len_reg[7:0];
            7'd27: gmii_tx_data = id_reg[15:8];
            7'd28: gmii_tx_data = id_reg[7:0];
            7'd29: gmii_tx_data = offset_reg[15:8];
            7'd30: gmii_tx_data = offset_reg[7:0];
            7'd31: gmii_tx_data = ttl_reg;
            7'd32: gmii_tx_data = protocol_reg;
            7'd33: gmii_tx_data = checksum_result_reg[15:8];
            7'd34: gmii_tx_data = checksum_result_reg[7:0];
            7'd35: gmii_tx_data = src_ip_reg[31:24];
            7'd36: gmii_tx_data = src_ip_reg[23:16];
            7'd37: gmii_tx_data = src_ip_reg[15:8];
            7'd38: gmii_tx_data = src_ip_reg[7:0];
            7'd39: gmii_tx_data = dst_ip_reg[31:24];
            7'd40: gmii_tx_data = dst_ip_reg[23:16];
            7'd41: gmii_tx_data = dst_ip_reg[15:8];
            7'd42: gmii_tx_data = dst_ip_reg[7:0];
            7'd43: gmii_tx_data = src_port_reg[15:8];
            7'd44: gmii_tx_data = src_port_reg[7:0];
            7'd45: gmii_tx_data = dst_port_reg[15:8];
            7'd46: gmii_tx_data = dst_port_reg[7:0];
            7'd47: gmii_tx_data = udp_len_reg[15:8];
            7'd48: gmii_tx_data = udp_len_reg[7:0];
            7'd49: gmii_tx_data = udp_result_reg[15:8];
            7'd50: gmii_tx_data = udp_result_reg[7:0];
            7'd51: gmii_tx_data = fifo_data_reg;
            7'd52: gmii_tx_data = FCS_reg[31:24];
            7'd52: gmii_tx_data = FCS_reg[23:16];
            7'd52: gmii_tx_data = FCS_reg[15:8];
            7'd52: gmii_tx_data = FCS_reg[7:0];

            default: gmii_tx_data = 8'd0;
        endcase
    end


endmodule

