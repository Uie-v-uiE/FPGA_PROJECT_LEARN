module sdram_init #(
    parameter T_POWER   = 15'd20_000,
    parameter TRP_CLK   = 2,
    parameter TRF_CLK   = 7,
    parameter TRF_CNT   = 8,
    parameter TMRD_CLK  = 3,
    parameter NOP       = 4'b0111,       //空操作指令
    parameter P_CHARGE  = 4'b0010,       //预充电指令
    parameter AUTO_REF  = 4'b0001,       //自动刷新指令
    parameter M_REG_SET = 4'b0000,       //配置模式寄存器指令
    parameter INIT_IDLE = 8'b0000_0001,  //初始状态
    parameter INIT_PRE  = 8'b0000_0010,  //预充电状态
    parameter INIT_TRP  = 8'b0000_0100,  //预充电等待状态
    parameter INIT_AR   = 8'b0000_1000,  //自动刷新状态
    parameter INIT_TRF  = 8'b0001_0000,  //自动刷新等待状态
    parameter INIT_MRS  = 8'b0010_0000,  //配置寄存器状态
    parameter INIT_TMRD = 8'b0100_0000,  //配置模式寄存器等待状态
    parameter INIT_END  = 8'b1000_0000   //初始化完成状态

) (
    input             sys_clk,
    input             sys_rst_n,
    output reg [ 3:0] init_cmd,   //初始化输出指令
    output reg [ 1:0] init_ba,    //初始化L-BAN地址
    output reg [12:0] init_addr,  //初始化总线地址 模式寄存器配置
    output reg        init_end    //初始化结束标志
);

    reg [14:0] cnt_200us;
    reg        wait_end;
    reg [ 7:0] init_current_state;
    reg [ 7:0] init_next_state;
    reg [ 3:0] cnt_state;
    reg [ 3:0] cnt_ref;

    always @(*) begin  //次态跳转
        case (init_current_state)
            INIT_IDLE: begin
                if (wait_end) begin
                    init_next_state = INIT_PRE;
                end else begin
                    init_next_state = INIT_IDLE;
                end
            end
            INIT_PRE: begin
                init_next_state = INIT_TRP;
            end
            INIT_TRP: begin
                if (cnt_state == TRP_CLK) begin
                    init_next_state = INIT_AR;
                end else begin
                    init_next_state = INIT_TRP;
                end
            end
            INIT_AR: begin
                init_next_state = INIT_TRF;
            end
            INIT_TRF: begin
                if (cnt_ref == TRF_CNT && cnt_state == TRF_CLK) begin
                    init_next_state = INIT_MRS;
                end else if (cnt_state == TRF_CLK) begin
                    init_next_state = INIT_AR;
                end else begin
                    init_next_state = INIT_TRF;
                end
            end
            INIT_MRS: begin
                init_next_state = INIT_TMRD;
            end
            INIT_TMRD: begin
                if (cnt_state == TMRD_CLK) begin
                    init_next_state = INIT_END;
                end else begin
                    init_next_state = INIT_TMRD;
                end
            end
            INIT_END: begin
                init_next_state = INIT_END;
            end
            default: init_next_state = INIT_IDLE;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  // 状态计数器
        if (!sys_rst_n) begin
            cnt_state <= 4'd0;
        end else if (init_current_state == INIT_PRE || init_current_state == INIT_TRP) begin
            if (cnt_state < TRP_CLK) begin
                cnt_state <= cnt_state + 4'd1;
            end else begin
                cnt_state <= 4'd0;
            end
        end else if (init_current_state == INIT_AR || init_current_state == INIT_TRF) begin
            if (cnt_state < TRF_CLK) begin
                cnt_state <= cnt_state + 4'd1;
            end else begin
                cnt_state <= 4'd0;
            end
        end else if (init_current_state == INIT_MRS || init_current_state == INIT_TMRD) begin
            if (cnt_state < TMRD_CLK) begin
                cnt_state <= cnt_state + 4'd1;
            end else begin
                cnt_state <= 4'd0;
            end
        end else begin
            cnt_state <= 4'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  //自刷新次数计数器
        if (!sys_rst_n) begin
            cnt_ref <= 4'd0;
        end else if (init_current_state == INIT_AR && init_next_state == INIT_TRF) begin
            cnt_ref <= cnt_ref + 4'd1;
        end else begin
            cnt_ref <= cnt_ref;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  //上电等待时间计数器
        if (!sys_rst_n) begin
            cnt_200us <= 15'd0;
        end else if (cnt_200us < T_POWER) begin
            cnt_200us <= cnt_200us + 15'd1;
        end else begin
            cnt_200us <= cnt_200us;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  //等待完成标志信号
        if (!sys_rst_n) begin
            wait_end <= 1'd0;
        end else if (cnt_200us == T_POWER - 2) begin
            wait_end <= 1'd1;
        end else begin
            wait_end <= 1'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  //状态机刷新
        if (!sys_rst_n) begin
            init_current_state <= INIT_IDLE;
        end else begin
            init_current_state <= init_next_state;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  // ba  addr
        if (!sys_rst_n) begin
            init_ba   <= 2'b11;
            init_addr <= 13'h1fff;
        end else if (init_next_state == INIT_TMRD) begin
            init_ba <= 2'b00;
            init_addr <= {
                3'b000,  // A12-A10: 预留
                1'b0,  // A9=0: 突发读&突发写
                2'b00,  // A8-A7: 标准模式
                3'b011,  // A6-A4: CAS 潜伏期 = 3
                1'b0,  // A3=0: 顺序突发
                3'b111  // A2-A0: 整页突发
            };
        end else begin
            init_ba   <= 2'b11;
            init_addr <= 13'h1fff;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  //cmd
        if (!sys_rst_n) begin
            init_cmd <= NOP;
        end else if (init_current_state == INIT_PRE && init_next_state == INIT_TRP) begin
            init_cmd <= P_CHARGE;
        end else if (init_current_state == INIT_AR && init_next_state == INIT_TRF) begin
            init_cmd <= AUTO_REF;
        end else if (init_current_state == INIT_MRS && init_next_state == INIT_TMRD) begin
            init_cmd <= M_REG_SET;
        end else begin
            init_cmd <= NOP;
        end

    end

    always @(posedge sys_clk or negedge sys_rst_n) begin  // end
        if (!sys_rst_n) begin
            init_end <= 1'd0;
        end else if (init_current_state == INIT_TMRD && init_next_state == INIT_END) begin
            init_end <= 1'd1;
        end else begin
            init_end <= 1'd0;
        end
    end

endmodule
