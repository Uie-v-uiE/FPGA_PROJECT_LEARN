`timescale 1ns / 1ps

module tb_sdram_arbit;

    //---------------------------------------------------------
    // 时钟周期，单位 ns
    //---------------------------------------------------------
    localparam CLK_PERIOD = 10;

    //---------------------------------------------------------
    // 和 DUT 一致的状态编码
    // 这些只用于 TB 等待状态、打印状态、看波形
    //---------------------------------------------------------
    localparam [3:0] NOP = 4'b0111;

    localparam [4:0] SDRAM_IDLE = 5'b0000_1;
    localparam [4:0] SDRAM_ARBIT = 5'b0001_0;
    localparam [4:0] SDRAM_A_REF = 5'b0010_0;
    localparam [4:0] SDRAM_WRITE = 5'b0100_0;
    localparam [4:0] SDRAM_READ = 5'b1000_0;

    //---------------------------------------------------------
    // DUT 输入信号
    //---------------------------------------------------------
    reg         sys_clk;
    reg         sys_rst_n;

    reg  [ 3:0] init_cmd;
    reg  [ 1:0] init_ba;
    reg  [12:0] init_addr;
    reg         init_end;

    reg         aref_req;
    reg  [ 3:0] aref_cmd;
    reg  [ 1:0] aref_ba;
    reg  [12:0] aref_addr;
    reg         aref_end;

    reg         wr_req;
    reg  [ 3:0] wr_cmd;
    reg  [ 1:0] wr_ba;
    reg  [12:0] wr_addr;
    reg         wr_sdram_en;
    reg  [15:0] wr_data;
    reg         wr_end;

    reg         rd_req;
    reg  [ 3:0] rd_cmd;
    reg  [ 1:0] rd_ba;
    reg  [12:0] rd_addr;
    reg         rd_end;

    //---------------------------------------------------------
    // DUT 输出信号
    //---------------------------------------------------------
    wire        aref_en;
    wire        wr_en;
    wire        rd_en;

    wire        sdram_cke;
    wire        sdram_cs_n;
    wire        sdram_cas_n;
    wire        sdram_ras_n;
    wire        sdram_we_n;

    wire [ 1:0] sdram_ba;
    wire [12:0] sdram_addr;

    //---------------------------------------------------------
    // SDRAM 双向数据总线
    //---------------------------------------------------------
    wire [15:0] sdram_dq;

    //---------------------------------------------------------
    // TB 侧驱动 sdram_dq 的控制信号
    //
    // tb_dq_en = 1 时，TB 驱动 sdram_dq，用于模拟读数据
    // tb_dq_en = 0 时，TB 释放 sdram_dq，避免和 DUT 写数据冲突
    //---------------------------------------------------------
    reg  [15:0] tb_dq_data;
    reg         tb_dq_en;

    assign sdram_dq = (tb_dq_en == 1'b1) ? tb_dq_data : 16'bz;

    //---------------------------------------------------------
    // 命令引脚合并显示
    // 位顺序：{CS_N, RAS_N, CAS_N, WE_N}
    //---------------------------------------------------------
    wire [3:0] sdram_cmd_pins;

    assign sdram_cmd_pins = {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n};

    //---------------------------------------------------------
    // 时钟生成
    //---------------------------------------------------------
    initial begin
        sys_clk = 1'b0;
    end

    always #(CLK_PERIOD / 2) begin
        sys_clk = ~sys_clk;
    end

    //---------------------------------------------------------
    // 被测模块实例化
    //---------------------------------------------------------
    sdram_arbit #(
        .NOP        (NOP),
        .SDRAM_IDLE (SDRAM_IDLE),
        .SDRAM_ARBIT(SDRAM_ARBIT),
        .SDRAM_A_REF(SDRAM_A_REF),
        .SDRAM_WRITE(SDRAM_WRITE),
        .SDRAM_READ (SDRAM_READ)
    ) u_dut (
        .sys_clk  (sys_clk),
        .sys_rst_n(sys_rst_n),

        .init_cmd (init_cmd),
        .init_ba  (init_ba),
        .init_addr(init_addr),
        .init_end (init_end),

        .aref_req (aref_req),
        .aref_cmd (aref_cmd),
        .aref_ba  (aref_ba),
        .aref_addr(aref_addr),
        .aref_end (aref_end),

        .wr_req     (wr_req),
        .wr_cmd     (wr_cmd),
        .wr_ba      (wr_ba),
        .wr_addr    (wr_addr),
        .wr_sdram_en(wr_sdram_en),
        .wr_data    (wr_data),
        .wr_end     (wr_end),

        .rd_req (rd_req),
        .rd_cmd (rd_cmd),
        .rd_ba  (rd_ba),
        .rd_addr(rd_addr),
        .rd_end (rd_end),

        .aref_en(aref_en),
        .wr_en  (wr_en),
        .rd_en  (rd_en),

        .sdram_cke  (sdram_cke),
        .sdram_cs_n (sdram_cs_n),
        .sdram_cas_n(sdram_cas_n),
        .sdram_ras_n(sdram_ras_n),
        .sdram_we_n (sdram_we_n),

        .sdram_ba  (sdram_ba),
        .sdram_addr(sdram_addr),

        .sdram_dq(sdram_dq)
    );

    //---------------------------------------------------------
    // 调试信号
    //
    // DUT 没有把状态机输出成端口，
    // 所以这里用层次路径把内部状态引出来。
    //
    // Vivado 仿真时也可以在波形里手动添加：
    //      u_dut/sdram_current_state
    //      u_dut/sdram_next_state
    //---------------------------------------------------------
    wire [4:0] dbg_current_state;
    wire [4:0] dbg_next_state;

    assign dbg_current_state = u_dut.sdram_current_state;
    assign dbg_next_state    = u_dut.sdram_next_state;

    //---------------------------------------------------------
    // 主测试流程
    //---------------------------------------------------------
    initial begin
        //-----------------------------------------------------
        // 生成波形文件
        // 如果用 Vivado，也可以不依赖这个，直接在 GUI 里看波形
        //-----------------------------------------------------
        $dumpfile("tb_sdram_arbit.vcd");
        $dumpvars(0, tb_sdram_arbit);

        //-----------------------------------------------------
        // 初始化所有 TB 输入
        //-----------------------------------------------------
        sys_rst_n   = 1'b0;

        init_cmd    = NOP;
        init_ba     = 2'b00;
        init_addr   = 13'h0000;
        init_end    = 1'b0;

        aref_req    = 1'b0;
        aref_cmd    = NOP;
        aref_ba     = 2'b00;
        aref_addr   = 13'h0000;
        aref_end    = 1'b0;

        wr_req      = 1'b0;
        wr_cmd      = NOP;
        wr_ba       = 2'b00;
        wr_addr     = 13'h0000;
        wr_sdram_en = 1'b0;
        wr_data     = 16'h0000;
        wr_end      = 1'b0;

        rd_req      = 1'b0;
        rd_cmd      = NOP;
        rd_ba       = 2'b00;
        rd_addr     = 13'h0000;
        rd_end      = 1'b0;

        tb_dq_en    = 1'b0;
        tb_dq_data  = 16'h0000;

        //-----------------------------------------------------
        // 保持复位一段时间
        //-----------------------------------------------------
        repeat (5) @(posedge sys_clk);

        //-----------------------------------------------------
        // 释放复位
        //-----------------------------------------------------
        sys_rst_n = 1'b1;

        //-----------------------------------------------------
        // 模拟初始化结束
        //
        // DUT 在 SDRAM_IDLE 状态等待 init_end。
        // init_end 拉高一个时钟周期后，状态应进入 SDRAM_ARBIT。
        //-----------------------------------------------------
        @(posedge sys_clk);
        init_cmd  <= NOP;
        init_ba   <= 2'b00;
        init_addr <= 13'h0000;
        init_end  <= 1'b1;

        @(posedge sys_clk);
        init_end <= 1'b0;

        //-----------------------------------------------------
        // 等待进入仲裁状态
        //-----------------------------------------------------
        wait (dbg_current_state == SDRAM_ARBIT);

        //-----------------------------------------------------
        // 测试自动刷新请求
        //-----------------------------------------------------
        aref_transaction;

        //-----------------------------------------------------
        // 测试写请求
        //-----------------------------------------------------
        write_transaction;

        //-----------------------------------------------------
        // 测试读请求
        //-----------------------------------------------------
        read_transaction;

        //-----------------------------------------------------
        // 仿真结束前多跑几拍
        //-----------------------------------------------------
        repeat (20) @(posedge sys_clk);

        $finish;
    end

    //---------------------------------------------------------
    // 超时保护
    //
    // 如果某个 wait 条件永远等不到，
    // 防止仿真卡死。
    //---------------------------------------------------------
    initial begin
        #(CLK_PERIOD * 5000);
        $display("ERROR: simulation timeout, check wait condition.");
        $finish;
    end

    //---------------------------------------------------------
    // 每个时钟上升沿打印关键信号
    //
    // 用 $strobe 可以在当前时间步末尾打印，
    // 这样更容易看到非阻塞赋值更新后的值。
    //---------------------------------------------------------
    always @(posedge sys_clk) begin
        if (sys_rst_n == 1'b1) begin
            $strobe(
                "time=%0t | cur=%b next=%b | aref_en=%b wr_en=%b rd_en=%b | cmd=%b ba=%b addr=%h dq=%h",
                $time, dbg_current_state, dbg_next_state, aref_en, wr_en, rd_en, sdram_cmd_pins,
                sdram_ba, sdram_addr, sdram_dq);
        end
    end

    //---------------------------------------------------------
    // 自动刷新事务
    //
    // 流程：
    // 1. 在 SDRAM_ARBIT 状态下拉高 aref_req
    // 2. 等 DUT 进入 SDRAM_A_REF
    // 3. 清除 aref_req，防止回到 ARBIT 后再次进入 A_REF
    // 4. 模拟刷新模块工作几拍
    // 5. 拉高 aref_end，让 DUT 返回 SDRAM_ARBIT
    //---------------------------------------------------------
    task aref_transaction;
        begin
            // 等下一个时钟沿再发请求，方便波形对齐
            @(posedge sys_clk);

            // 刷新请求
            aref_req  <= 1'b1;

            // 示例命令编码，仅用于仿真
            // 真实 SDRAM 的 REFRESH 命令编码要查 SDRAM 手册
            // 通常是 {CS_N, RAS_N, CAS_N, WE_N}
            aref_cmd  <= 4'b0001;
            aref_ba   <= 2'b00;
            aref_addr <= 13'h0123;

            // 等 DUT 进入刷新状态
            wait (dbg_current_state == SDRAM_A_REF);

            // 进入 A_REF 后下一拍清除请求
            // 否则回到 ARBIT 后会马上再次进入 A_REF
            @(posedge sys_clk);
            aref_req <= 1'b0;

            // 模拟刷新过程持续几拍
            repeat (3) @(posedge sys_clk);

            // 刷新结束
            aref_end <= 1'b1;

            @(posedge sys_clk);
            aref_end <= 1'b0;
        end
    endtask

    //---------------------------------------------------------
    // 写事务
    //
    // 流程：
    // 1. 在 SDRAM_ARBIT 状态下拉高 wr_req
    // 2. 等 DUT 进入 SDRAM_WRITE
    // 3. 清除 wr_req，防止 wr_end 后再次进入 WRITE
    // 4. 拉高 wr_sdram_en，让 DUT 把 wr_data 驱动到 sdram_dq
    // 5. 模拟写过程持续几拍
    // 6. 拉高 wr_end，让 DUT 返回 SDRAM_ARBIT
    //---------------------------------------------------------
    task write_transaction;
        begin
            @(posedge sys_clk);

            // 写请求
            wr_req      <= 1'b1;

            // 示例命令编码，仅用于仿真
            // 真实 SDRAM 的 WRITE 命令编码要查手册
            wr_cmd      <= 4'b0000;
            wr_ba       <= 2'b01;
            wr_addr     <= 13'h0456;

            // 先不驱动 DQ
            wr_sdram_en <= 1'b0;
            wr_data     <= 16'h0000;

            // 等 DUT 进入写状态
            wait (dbg_current_state == SDRAM_WRITE);

            // 进入 WRITE 后下一拍清除请求
            @(posedge sys_clk);
            wr_req      <= 1'b0;

            // 开始驱动 DQ，模拟写数据
            wr_sdram_en <= 1'b1;
            wr_data     <= 16'hABCD;

            // 模拟写数据持续几拍
            repeat (3) @(posedge sys_clk);

            // 关闭 DQ 驱动
            wr_sdram_en <= 1'b0;

            // 写结束
            wr_end      <= 1'b1;

            @(posedge sys_clk);
            wr_end <= 1'b0;
        end
    endtask

    //---------------------------------------------------------
    // 读事务
    //
    // 流程：
    // 1. 在 SDRAM_ARBIT 状态下拉高 rd_req
    // 2. 等 DUT 发出 rd_en
    // 3. 清除 rd_req，防止再次进入 READ
    // 4. TB 驱动 sdram_dq，模拟 SDRAM 返回读数据
    // 5. 拉高 rd_end
    //
    // 注意：
    // 按你当前 RTL，SDRAM_READ 状态判断的是 rd_en，
    // 所以 rd_en 一高，READ 状态很快会回 ARBIT。
    // 这个现象在波形里要重点看。
    //---------------------------------------------------------
    task read_transaction;
        begin
            @(posedge sys_clk);

            // 读请求
            rd_req     <= 1'b1;

            // 示例命令编码，仅用于仿真
            // 真实 SDRAM 的 READ 命令编码要查手册
            rd_cmd     <= 4'b0101;
            rd_ba      <= 2'b10;
            rd_addr    <= 13'h0789;

            // TB 先不驱动 DQ
            tb_dq_en   <= 1'b0;
            tb_dq_data <= 16'h0000;

            // 等 DUT 发出读使能
            wait (rd_en == 1'b1);

            // 下一拍清除读请求
            @(posedge sys_clk);
            rd_req     <= 1'b0;

            // TB 驱动 DQ，模拟 SDRAM 返回数据
            tb_dq_en   <= 1'b1;
            tb_dq_data <= 16'h1234;

            // 模拟读数据持续几拍
            repeat (3) @(posedge sys_clk);

            // 读结束
            rd_end <= 1'b1;

            @(posedge sys_clk);
            rd_end   <= 1'b0;

            // 释放 DQ
            tb_dq_en <= 1'b0;
        end
    endtask

endmodule
