module sdram_init #(
    parameter T_POWER   = 15'd20_000,
    parameter TRP_CLK   = 2,
    parameter TRF_CLK   = 7,
    parameter TRF_CLK_8 = 8,
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
    reg        cnt_trp_2clk;
    reg [ 2:0] cnt_trc_7clk;
    reg [ 3:0] cnt_trc_rfclk;
    reg [ 1:0] cnt_tmrd_clk;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_200us <= 15'd0;
        end else if (cnt_200us < T_POWER) begin
            cnt_200us <= cnt_200us + 15'd1;
        end else begin
            cnt_200us <= cnt_200us;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wait_end <= 1'd0;
        end else if (cnt_200us == T_POWER - 2) begin
            wait_end <= 1'd1;
        end else begin
            wait_end <= 1'd0;
        end
    end

    always @(*) begin
        case (init_current_state)
            INIT_IDLE: begin
                if (wait_end) begin
                    init_next_state <= INIT_PRE;
                end else begin
                    init_next_state <= INIT_IDLE;
                end
            end
            INIT_PRE: begin
                init_next_state <= INIT_TRP;
            end
            INIT_TRP: begin
                if (cnt_trp_2clk == TRP_CLK - 1) begin
                    init_next_state <= INIT_AR;
                end else begin
                    init_next_state <= INIT_TRP;
                end
            end
            INIT_AR: begin
                init_next_state <= INIT_TRF;
            end
            INIT_TRF: begin
                if (cnt_trc_rfclk == TRF_CLK_8 - 1) begin
                    init_next_state <= INIT_MRS;
                end else begin
                    init_next_state <= INIT_TRF;
                end
            end
            INIT_MRS: begin
                init_next_state <= INIT_TMRD;
            end
            INIT_TMRD: begin
                if (cnt_tmrd_clk == TMRD_CLK - 1) begin
                    init_next_state <= INIT_END;
                end else begin
                    init_next_state <= INIT_TMRD;
                end
            end
            INIT_END: begin
                init_next_state <= INIT_END;
            end
            default: init_next_state <= INIT_IDLE;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_trp_2clk <= 1'd0;
        end else if (init_current_state == INIT_TRP && cnt_trp_2clk < TRP_CLK - 1) begin
            cnt_trp_2clk <= cnt_trp_2clk + 1'd1;
        end else begin
            cnt_trp_2clk <= 1'b0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_trc_7clk <= 3'd0;
        end else if (init_current_state == INIT_TRF && cnt_trc_7clk < TRF_CLK - 1) begin
            cnt_trc_7clk <= cnt_trc_7clk + 3'd1;
        end else begin
            cnt_trc_7clk <= 3'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_trc_rfclk <= 4'd0;
        end else if (init_current_state == INIT_TRF && cnt_trc_rfclk < TRF_CLK_8 - 1) begin
            cnt_trc_rfclk <= cnt_trc_rfclk + 4'd1;
        end else begin
            cnt_trc_rfclk <= 4'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_tmrd_clk <= 2'd0;
        end else if (init_current_state == INIT_TMRD && cnt_tmrd_clk < TMRD_CLK - 1) begin
            cnt_tmrd_clk <= cnt_tmrd_clk + 2'd1;
        end else begin
            cnt_tmrd_clk <= 2'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            init_current_state <= INIT_IDLE;
        end else begin
            init_current_state <= init_next_state;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n)
        if (sys_rst_n == 1'b0) begin
            init_cmd  <= NOP;
            init_ba   <= 2'b11;
            init_addr <= 13'h1fff;
        end else
            case (init_current_state)
                INIT_IDLE, INIT_TRP, INIT_TRF, INIT_TMRD:  //执行空操作指令
                    begin
                    init_cmd  <= NOP;
                    init_ba   <= 2'b11;
                    init_addr <= 13'h1fff;
                end
                INIT_PRE:  //预充电指令
                    begin
                    init_cmd  <= P_CHARGE;
                    init_ba   <= 2'b11;
                    init_addr <= 13'h1fff;
                end
                INIT_AR:  //自动刷新指令
                    begin
                    init_cmd  <= AUTO_REF;
                    init_ba   <= 2'b11;
                    init_addr <= 13'h1fff;
                end
                INIT_MRS:  //模式寄存器设置指令
                    begin
                    init_cmd <= M_REG_SET;
                    init_ba <= 2'b00;
                    init_addr <=
                        {  //地址辅助配置模式寄存器,参数不同,配置的模式不同
                        3'b000,  //A12-A10:预留
                        1'b0,  //A9=0:读写方式,0:突发读&突发写,1:突发读&单写
                        2'b00,  //{A8,A7}=00:标准模式,默认
                        3'b011,  //{A6,A5,A4}=011:CAS潜伏期,010:2,011:3,其他:保留
                        1'b0,  //A3=0:突发传输方式,0:顺序,1:隔行
                        3'b111  //{A2,A1,A0}=111:突发长度,000:单字节,001:2字节
                                //010:4字节,011:8字节,111:整页,其他:保留
                    };
                end
                INIT_END:  //SDRAM初始化完成
                    begin
                    init_cmd  <= NOP;
                    init_ba   <= 2'b11;
                    init_addr <= 13'h1fff;
                end
                default: begin
                    init_cmd  <= NOP;
                    init_ba   <= 2'b11;
                    init_addr <= 13'h1fff;
                end
            endcase


endmodule
