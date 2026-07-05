module spi_ctrl #(
    parameter [7:0] WR_EN_ORDER = 8'b0000_0110,
    parameter [7:0] BE_ORDER    = 8'b1100_0111,
    parameter       IDLE        = 4'b0001,
    parameter       WREN        = 4'b0010,
    parameter       DELAY       = 4'b0100,
    parameter       BE          = 4'b1000
) (
    input      sys_clk,
    input      sys_rst_n,
    input      key,
    output reg sck,
    output reg cs_n,
    output reg mosi
);

    reg [4:0] cnt_clk;
    reg [3:0] cnt_byte;
    reg [1:0] cnt_sck;
    reg [2:0] cnt_bit;
    reg [3:0] current_state;
    reg [3:0] next_state;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_clk <= 5'd0;
        end else if (current_state != IDLE) begin
            cnt_clk <= cnt_clk + 5'd1;
        end else begin
            cnt_clk <= 5'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_sck <= 2'd0;
        end else if (current_state == WREN || current_state == BE) begin
            cnt_sck <= cnt_sck + 2'd1;
        end else begin
            cnt_sck <= 2'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sck <= 1'd0;
        end else if (cs_n == 1'd0 && cnt_sck == 2'd0 &&
                     (current_state == WREN || current_state == BE)) begin
            sck <= 1'd0;
        end else if (cs_n == 1'd0 && cnt_sck == 2'd2 &&
                     (current_state == WREN || current_state == BE)) begin
            sck <= 1'd1;
        end else begin
            sck <= sck;
        end
    end


    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_byte <= 4'd0;
        end else if (cnt_clk == 5'd31) begin
            cnt_byte <= cnt_byte + 4'd1;
        end else if (current_state == IDLE) begin
            cnt_byte <= 4'd0;
        end else begin
            cnt_byte <= cnt_byte;
        end
    end


    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cs_n <= 1'd1;
        end else if (current_state == IDLE && next_state == WREN) begin
            cs_n <= 1'd0;
        end else if (current_state == WREN && next_state == DELAY) begin
            cs_n <= 1'd1;
        end else if (current_state == DELAY && next_state == BE) begin
            cs_n <= 1'd0;
        end else if (current_state == BE && next_state == IDLE) begin
            cs_n <= 1'd1;
        end else begin
            cs_n <= cs_n;
        end
    end

    always @(*) begin
        if (!sys_rst_n) begin
            next_state = IDLE;
        end else begin
            if (key) begin
                next_state = WREN;
            end else if (cnt_byte == 2 && cnt_clk == 5'd31 && current_state == WREN) begin
                next_state = DELAY;
            end else if (cnt_byte == 4 && cnt_clk == 5'd31 && current_state == DELAY) begin
                next_state = BE;
            end else if (cnt_byte == 6 && cnt_clk == 5'd31 && current_state == BE) begin
                next_state = IDLE;
            end else begin
                next_state = next_state;
            end
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_bit <= 3'd0;
        end else if (current_state == WREN || current_state == BE) begin
            if (cnt_sck == 2'd1) begin
                cnt_bit <= cnt_bit + 3'd1;
            end else begin
                cnt_bit <= cnt_bit;
            end
        end else begin
            cnt_bit <= 3'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            mosi <= 1'd0;
        end else begin
            if (cnt_byte == 4'd0) begin
                mosi <= 1'd0;
            end else if (cnt_byte == 4'd1) begin
                mosi <= WR_EN_ORDER[7-cnt_bit];
            end else if (cnt_byte == 4'd2) begin
                mosi <= 1'd0;
            end else if (cnt_byte == 4'd3) begin
                mosi <= 1'd0;
            end else if (cnt_byte == 4'd4) begin
                mosi <= 1'd0;
            end else if (cnt_byte == 4'd6) begin
                mosi <= BE_ORDER[7-cnt_bit];
            end else if (cnt_byte == 4'd7) begin
                mosi <= 1'd0;
            end else begin
                mosi <= 1'd0;
            end
        end
    end
endmodule
