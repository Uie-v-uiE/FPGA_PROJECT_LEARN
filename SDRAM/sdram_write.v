module sdram_write #(
    parameter WR_TRCD_CLK     = 2,
    parameter WR_TRP_CLK      = 2,
    parameter NOP             = 4'b0111,
    parameter P_CHARGE        = 4'b0010,
    parameter WR_ACTIVE_ORDER = 4'b0011,
    parameter WR_WRITE_ORDER  = 4'b0100,
    parameter B_STOP          = 4'b0110,
    parameter WR_IDLE         = 8'b0000_0001,
    parameter WR_ACTIVE       = 8'b0000_0010,
    parameter WR_TRCD         = 8'b0000_0100,
    parameter WR_WRITE        = 8'b0000_1000,
    parameter WR_DATA         = 8'b0001_0000,
    parameter WR_PRE          = 8'b0010_0000,
    parameter WR_TRP          = 8'b0100_0000,
    parameter WR_END          = 8'b1000_0000

) (
    input         sys_clk,
    input         sys_rst_n,
    input         init_end,
    input         wr_en,
    input  [23:0] wr_addr,
    input  [15:0] wr_data,
    input  [ 9:0] wr_burst_len,
    output        wr_ack,
    output        wr_end,
    output [ 3:0] write_cmd,
    output [ 1:0] write_ba,
    output [12:0] write_addr,
    output        wr_sdram_en,
    output [15:0] wr_sdram_data
);

    reg [7:0] wr_current_state;
    reg [7:0] wr_next_state;
    reg [3:0] wr_cnt_state;

    always @(*) begin
        case (wr_current_state)
            WR_IDLE: begin
                if (init_end && wr_en) begin
                    wr_next_state = WR_ACTIVE;
                end else begin
                    wr_next_state = WR_IDLE;
                end
            end
            WR_ACTIVE: begin
                wr_next_state = WR_TRCD;
            end
            WR_TRCD: begin
                if (wr_cnt_state == WR_TRCD_CLK) begin
                    wr_next_state = WR_WRITE;
                end else begin
                    wr_next_state = WR_TRCD;
                end
            end
            WR_WRITE: begin
                wr_next_state = WR_DATA;
            end
            WR_DATA: begin
                if (wr_cnt_state == wr_burst_len) begin
                    wr_next_state = WR_PRE;
                end
            end
            WR_PRE: begin
                wr_next_state = WR_TRP;
            end
            WR_TRP: begin
                if (wr_cnt_state == WR_TRP_CLK) begin
                    wr_next_state = WR_END;
                end else begin
                    wr_next_state = WR_END;
                end
            end
            WR_END: begin
                wr_next_state = WR_IDLE;
            end
            default: wr_next_state = WR_IDLE;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_current_state <= WR_IDLE;
        end else begin
            wr_current_state <= wr_next_state;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_cnt_state <= 4'd0;
        end else if (wr_current_state == WR_ACTIVE || wr_current_state == WR_TRCD) begin
            if (wr_cnt_state < WR_TRCD_CLK) begin
                wr_cnt_state <= wr_cnt_state + 4'd1;
            end else begin
                wr_cnt_state <= 4'd0;
            end
        end else if (wr_current_state == WR_WRITE || wr_current_state == WR_DATA) begin
            if (wr_cnt_state < wr_burst_len) begin
                wr_cnt_state <= wr_cnt_state + 4'd1;
            end else begin
                wr_cnt_state <= 4'd0;
            end
        end else if (wr_current_state == WR_PRE || wr_current_state == WR_TRP) begin
            if (wr_cnt_state < WR_TRCD_CLK) begin
                wr_cnt_state <= wr_cnt_state + 4'd1;
            end else begin
                wr_cnt_state <= 4'd0;
            end
        end else begin
            wr_cnt_state <= 4'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_ack <= 1'd0;
        end else if (wr_current_state == WR_TRCD && wr_next_state == WR_WRITE) begin
            wr_ack <= 1'd1;
        end else if (wr_current_state == WR_DATA && wr_cnt_state == wr_burst_len - 10'd1) begin
            wr_ack <= 1'd0;
        end else begin
            wr_ack <= wr_ack;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_end <= 1'd0;
        end else if (wr_current_state == WR_TRP && wr_next_state == WR_END) begin
            wr_end <= 1'd1;
        end else begin
            wr_end <= 1'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            write_cmd  <= NOP;
            write_ba   <= 2'b11;
            write_addr <= 13'h1fff;
        end else if (wr_current_state == WR_ACTIVE && wr_next_state == WR_TRCD) begin
            write_cmd  <= WR_ACTIVE_ORDER;
            write_ba   <= 2'b00;
            write_addr <= 13'h0000;
        end else if (wr_current_state == WR_WRITE && wr_next_state == WR_DATA) begin
            write_cmd  <= WR_WRITE_ORDER;
            write_ba   <= 2'b00;
            write_addr <= 13'h0000;
        end else if (wr_current_state == WR_DATA && wr_next_state == WR_PRE) begin
            write_cmd <= B_STOP;
        end else if (wr_current_state == WR_PRE && wr_next_state == WR_TRP) begin
            write_cmd  <= P_CHARGE;
            write_ba   <= 2'b00;
            write_addr <= 13'h0400;
        end else begin
            write_cmd  <= NOP;
            write_ba   <= 2'b11;
            write_addr <= 13'h1fff;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_sdram_en   <= 1'd0;
            wr_sdram_data <= 16'd0;
        end else if ((wr_current_state == WR_WRITE && wr_next_state == WR_DATA) ||
                     (wr_current_state == WR_DATA && wr_next_state != WR_PRE)) begin
            wr_sdram_en   <= 1'd1;
            wr_sdram_data <= wr_sdram_data + 16'd1;
        end else if (wr_current_state == WR_DATA && wr_next_state == WR_PRE) begin
            wr_sdram_en   <= 1'd1;
            wr_sdram_data <= 16'd0;
        end
    end


endmodule
