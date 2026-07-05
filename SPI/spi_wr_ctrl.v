module spi_wr_ctrl #(
    parameter [ 7:0] WR_EN_ORDER = 8'b0000_0110,
    parameter [ 7:0] PP_ORDER    = 8'b0000_0010,
    parameter [ 7:0] S_ADDR      = 8'b0000_0000,
    parameter [ 7:0] P_ADDR      = 8'b0000_0100,
    parameter [ 7:0] B_ADDR      = 8'b0010_0101,
    parameter [23:0] ADDR        = 24'h00_04_25,
    parameter [ 3:0] IDLE        = 4'b0001,
    parameter [ 3:0] WREN        = 4'b0010,
    parameter [ 3:0] DELAY       = 4'b0100,
    parameter [ 3:0] PP          = 4'b1000
) (
    input        clk,
    input        rst_n,
    input        pi_flag,
    input  [7:0] pi_data,
    output       sck,
    output       mosi,
    output       cs_n
);

    reg [ 4:0] cnt_clk;
    reg [ 3:0] cnt_byte;
    reg [ 1:0] cnt_sck;
    reg [ 2:0] cnt_bit;
    reg [23:0] addr;
    reg [23:0] addr_reg;
    reg [ 3:0] current_state;
    reg [ 3:0] next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_clk <= 5'd0;
        end else if (current_state != IDLE) begin
            cnt_clk <= cnt_clk + 5'd1;
        end else begin
            cnt_clk <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_byte <= 4'd0;
        end else if (cnt_byte < 10 && cnt_clk == 5'd31) begin
            cnt_byte <= cnt_byte + 4'd1;
        end else begin
            cnt_byte <= 4'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= ADDR;
        end else if (pi_flag) begin
            addr_reg <= addr_reg + 24'd1;
        end else begin
            addr_reg <= addr_reg;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= 24'd0;
        end else if (pi_flag) begin
            addr <= addr_reg;
        end else begin
            addr <= addr;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        if (!rst_n) begin
            next_state <= IDLE;
        end else if (pi_flag) begin
            next_state <= WREN;
        end else if (cnt_byte == 4'd2 && cnt_clk == 5'd31) begin
            next_state <= DELAY;
        end else if (cnt_byte == 4'd3 && cnt_clk == 5'd31) begin
            next_state <= PP;
        end else if (cnt_byte == 4'd10 && cnt_clk == 5'd31) begin
            next_state <= IDLE;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_sck <= 2'd0;
        end else if (cnt_byte == 4'd1 || (cnt_byte < 10 && cnt_byte >= 5)) begin
            cnt_sck <= cnt_sck + 2'd1;
        end else begin
            cnt_sck <= 2'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sck <= 1'd0;
        end else if (cnt_sck == 2'd0) begin
            sck <= 1'd0;
        end else if (cnt_sck == 2'd2) begin
            sck <= 1'd1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs_n <= 1'd1;
        end else if (current_state == IDLE && next_state == WREN) begin
            cs_n <= 1'd0;
        end else if (current_state == WREN && next_state == DELAY) begin
            cs_n <= 1'd1;
        end else if (current_state == DELAY && next_state == PP) begin
            cs_n <= 1'd0;
        end else if (current_state == PP && next_state == IDLE) begin
            cs_n <= 1'd1;
        end else begin
            cs_n <= cs_n;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_bit <= 5'd0;
        end else if (current_state == WREN || current_state == PP) begin
            cnt_bit <= cnt_bit + 3'd1;
        end else begin
            cnt_bit <= 3'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mosi <= 1'd0;
        end else if (current_state == WREN) begin
            mosi <= WR_EN_ORDER[7-cnt_bit];
        end else if (current_state == PP && cnt_byte == 4'd5) begin
            mosi <= PP_ORDER[7-cnt_bit];
        end else if (current_state == PP && cnt_byte == 4'd6) begin
            mosi <= ADDR[23-cnt_bit];
        end else if (current_state == PP && cnt_byte == 4'd7) begin
            mosi <= ADDR[15-cnt_bit];
        end else if (current_state == PP && cnt_byte == 4'd8) begin
            mosi <= ADDR[7-cnt_bit];
        end else if (current_state == PP && cnt_byte == 4'd9) begin
            mosi <= pi_data;
        end
    end

endmodule
