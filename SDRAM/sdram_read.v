module sdram_read #(
    parameter RD_TRCD_CLK     = 2,
    parameter CL              = 3,
    parameter RD_TRP_CLK      = 2,
    parameter NOP             = 4'b0111,
    parameter P_CHARGE        = 4'b0010,
    parameter RD_ACTIVE_ORDER = 4'b0011,
    parameter RD_READ_ORDER   = 4'b0101,
    parameter B_STOP          = 4'b0110,
    parameter RD_IDLE         = 9'b0_0000_0001,
    parameter RD_ACTIVE       = 9'b0_0000_0010,
    parameter RD_TRCD         = 9'b0_0000_0100,
    parameter RD_READ         = 9'b0_0000_1000,
    parameter RD_CL           = 9'b0_0001_0000,
    parameter RD_DATA         = 9'b0_0010_0000,
    parameter RD_PRE          = 9'b0_0100_0000,
    parameter RD_TRP          = 9'b0_1000_0000,
    parameter RD_END          = 9'b1_0000_0000

) (
    input             sys_clk,
    input             sys_rst_n,
    input             init_end,
    input             rd_en,
    input      [23:0] rd_addr,
    input      [15:0] rd_data,
    input      [ 9:0] rd_burst_len,
    output reg        rd_ack,
    output reg        rd_end,
    output reg [ 3:0] read_cmd,
    output reg [ 1:0] read_ba,
    output reg [12:0] read_addr,
    output     [15:0] rd_sdram_data
);

    reg [8:0] rd_current_state;
    reg [8:0] rd_next_state;
    reg [3:0] rd_cnt_state;

    always @(*) begin
        case (rd_current_state)
            RD_IDLE: begin
                if (init_end && rd_en) begin
                    rd_next_state = RD_ACTIVE;
                end else begin
                    rd_next_state = RD_IDLE;
                end
            end
            RD_ACTIVE: begin
                rd_next_state = RD_TRCD;
            end
            RD_TRCD: begin
                if (rd_cnt_state == RD_TRCD_CLK) begin
                    rd_next_state = RD_READ;
                end else begin
                    rd_next_state = RD_TRCD;
                end
            end
            RD_READ: begin
                rd_next_state = RD_CL;
            end
            RD_CL: begin
                if (rd_cnt_state == CL) begin
                    rd_next_state = RD_DATA;
                end else begin
                    rd_next_state = RD_CL;
                end
            end
            RD_DATA: begin
                if (rd_cnt_state == CL + rd_burst_len) begin
                    rd_next_state = RD_PRE;
                end else begin
                    rd_next_state = RD_DATA;
                end
            end
            RD_PRE: begin
                rd_next_state = RD_TRP;
            end
            RD_TRP: begin
                if (rd_cnt_state == RD_TRP_CLK) begin
                    rd_next_state = RD_END;
                end else begin
                    rd_next_state = RD_TRP;
                end
            end
            RD_END: begin
                rd_next_state = RD_IDLE;
            end
            default: rd_next_state = RD_IDLE;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rd_current_state <= RD_IDLE;
        end else begin
            rd_current_state <= rd_next_state;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rd_cnt_state <= 4'd0;
        end else if (rd_current_state == RD_ACTIVE || rd_current_state == RD_TRCD) begin
            if (rd_cnt_state < RD_TRCD_CLK) begin
                rd_cnt_state <= rd_cnt_state + 4'd1;
            end else begin
                rd_cnt_state <= 4'd0;
            end
        end else if (rd_current_state == RD_READ || rd_current_state == RD_CL) begin
            if (rd_cnt_state < CL) begin
                rd_cnt_state <= rd_cnt_state + 4'd1;
            end else begin
                rd_cnt_state <= 4'd0;
            end
        end else if (rd_current_state == RD_DATA) begin
            if (rd_cnt_state < CL + rd_burst_len - 10'd1) begin
                rd_cnt_state <= rd_cnt_state + 4'd1;
            end else begin
                rd_cnt_state <= 4'd0;
            end
        end else if (rd_current_state == RD_PRE || rd_current_state == RD_TRP) begin
            if (rd_cnt_state < RD_TRP_CLK) begin
                rd_cnt_state <= rd_cnt_state + 4'd1;
            end else begin
                rd_cnt_state <= 4'd0;
            end
        end else begin
            rd_cnt_state <= 4'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rd_ack <= 1'd1;
        end else if (rd_current_state == RD_DATA) begin
            rd_ack <= 1'd1;
        end else if (rd_current_state == RD_DATA && rd_cnt_state == CL + rd_burst_len - 10'd3) begin
            rd_ack <= 1'b0;
        end else begin
            rd_ack <= rd_ack;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            read_cmd  <= NOP;
            read_ba   <= 2'b11;
            read_addr <= 13'h1fff;
        end else if (rd_current_state == RD_ACTIVE && rd_next_state == RD_TRCD) begin
            read_cmd  <= RD_ACTIVE_ORDER;
            read_ba   <= 2'b00;
            read_addr <= 13'h0000;
        end else if (rd_current_state == RD_READ && rd_next_state == RD_CL) begin
            read_cmd  <= RD_READ_ORDER;
            read_ba   <= 2'b00;
            read_addr <= 13'h0000;
        end else if (rd_current_state == RD_DATA && rd_cnt_state == CL + rd_burst_len - 10'd7) begin
            read_cmd <= B_STOP;
        end else if (rd_current_state == RD_PRE && rd_next_state == RD_TRP) begin
            read_cmd  <= P_CHARGE;
            read_ba   <= 2'b00;
            read_addr <= 13'h0400;
        end else begin
            read_cmd  <= NOP;
            read_ba   <= 2'b11;
            read_addr <= 13'h1fff;
        end
    end

    assign rd_sdram_data = rd_ack ? rd_data : 16'd0;

endmodule
