module sdram_a_ref #(
    parameter NOP          = 4'b0111,
    parameter P_CHARGE     = 4'b0010,
    parameter AUTO_REF     = 4'b0001,
    parameter M_REG_SET    = 4'b0000,
    parameter CNT_REF_MAX  = 749,
    parameter AREF_TRP_CLK = 2,
    parameter AREF_TRF_CLK = 7,
    parameter AREF_TRF_CNT = 2,

    parameter AREF_IDLE = 6'b00_0001,
    parameter AREF_PCHA = 6'b00_0010,
    parameter AREF_TRP  = 6'b00_0100,
    parameter AREF_REF  = 6'b00_1000,
    parameter AREF_TRF  = 6'b01_0000,
    parameter AREF_END  = 6'b10_0000

) (
    input             sys_clk,
    input             sys_rst_n,
    input             init_end,
    input             aref_en,
    output reg        aref_req,
    output reg [ 3:0] aref_cmd,
    output reg [ 1:0] aref_ba,
    output reg [12:0] aref_addr,
    output reg        aref_end
);

    reg [5:0] aref_current_state;
    reg [5:0] aref_next_state;
    reg       aref_ack;
    reg [2:0] aref_cnt_state;
    reg [1:0] aref_cnt_ref;
    reg [8:0] aref_cnt_period;

    always @(*) begin
        case (aref_current_state)
            AREF_IDLE: begin
                if (aref_en) begin
                    aref_next_state = AREF_PCHA;
                end else begin
                    aref_next_state = AREF_IDLE;
                end
            end
            AREF_PCHA: begin
                aref_next_state = AREF_TRP;
            end
            AREF_TRP: begin
                if (aref_cnt_state == AREF_TRP_CLK) begin
                    aref_next_state = AREF_REF;
                end else begin
                    aref_next_state = AREF_TRP;
                end
            end
            AREF_REF: begin
                aref_next_state = AREF_TRF;
            end
            AREF_TRF: begin
                if (aref_cnt_state == AREF_TRF_CLK && aref_cnt_ref == AREF_TRF_CNT) begin
                    aref_next_state = AREF_END;
                end else if (aref_cnt_state == AREF_TRF_CLK) begin
                    aref_next_state = AREF_REF;
                end else begin
                    aref_next_state = AREF_TRF;
                end
            end
            AREF_END: begin
                aref_next_state = AREF_IDLE;
            end
            default: aref_next_state = AREF_IDLE;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_current_state <= AREF_IDLE;
        end else begin
            aref_current_state <= aref_next_state;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_ack <= 1'd0;
        end else if (aref_current_state == AREF_IDLE && aref_next_state == AREF_PCHA) begin
            aref_ack <= 1'd1;
        end else begin
            aref_ack <= 1'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_cnt_state <= 3'd0;
        end else if (aref_current_state == AREF_PCHA || aref_current_state == AREF_TRP) begin
            if (aref_cnt_state < AREF_TRP_CLK) begin
                aref_cnt_state <= aref_cnt_state + 3'd1;
            end else begin
                aref_cnt_state <= 3'd0;
            end
        end else if (aref_current_state == AREF_REF || aref_current_state == AREF_TRF) begin
            if (aref_cnt_state < AREF_TRF_CLK) begin
                aref_cnt_state <= aref_cnt_state + 3'd1;
            end else begin
                aref_cnt_state <= 3'd0;
            end
        end else begin
            aref_cnt_state <= 3'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_cnt_ref <= 2'd0;
        end else if (aref_current_state == AREF_REF && aref_next_state == AREF_TRF) begin
            aref_cnt_ref <= aref_cnt_ref + 2'd1;
        end else if (aref_current_state == AREF_IDLE) begin
            aref_cnt_ref <= 2'd0;
        end else begin
            aref_cnt_ref <= aref_cnt_ref;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_cnt_period <= 9'd0;
        end else if (init_end && aref_cnt_period < CNT_REF_MAX) begin
            aref_cnt_period <= aref_cnt_period + 9'd1;
        end else begin
            aref_cnt_period <= 9'd0;
        end
    end


    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_req <= 1'd0;
        end else if (aref_cnt_period == CNT_REF_MAX - 1) begin
            aref_req <= 1'd1;
        end else if (aref_ack) begin
            aref_req <= 1'd0;
        end else begin
            aref_req <= aref_req;
        end
    end


    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_ba   <= 2'b11;
            aref_addr <= 13'h1fff;
        end else begin
            aref_ba   <= 2'b11;
            aref_addr <= 13'h1fff;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_cmd <= NOP;
        end else if (aref_current_state == AREF_PCHA && aref_next_state == AREF_TRP) begin
            aref_cmd <= P_CHARGE;
        end else if (aref_current_state == AREF_REF && aref_next_state == AREF_TRF) begin
            aref_cmd <= AUTO_REF;
        end else begin
            aref_cmd <= NOP;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_end <= 1'd0;
        end else if (aref_current_state == AREF_TRF && aref_next_state == AREF_END) begin
            aref_end <= 1'd1;
        end else begin
            aref_end <= 1'd0;
        end
    end

endmodule
