`timescale 1ns / 1ps

module tb_sdram_ctrl;

    //=============================================================================
    // 参数（必须和 sdram_init / sdram_read / sdram_write 里一致）
    //=============================================================================
    localparam CLK_PERIOD = 10;  // 100 MHz
    localparam CL = 3;  // CAS Latency
    localparam BURST_LEN = 10'd4;  // 突发长度

    //=============================================================================
    // 信号
    //=============================================================================
    reg         sys_clk;
    reg         sys_rst_n;

    reg         sdram_wr_req;
    reg  [23:0] sdram_wr_addr;
    reg  [ 9:0] wr_burst_len;
    reg  [15:0] sdram_data_in;

    reg         sdram_rd_req;
    reg  [23:0] sdram_rd_addr;
    reg  [ 9:0] rd_burst_len;

    wire        sdram_wr_ack;
    wire [15:0] sdram_data_out;
    wire        init_end;
    wire        sdram_rd_ack;

    wire        sdram_cke;
    wire        sdram_cs_n;
    wire        sdram_ras_n;
    wire        sdram_cas_n;
    wire        sdram_we_n;
    wire [ 1:0] sdram_ba;
    wire [12:0] sdram_addr;
    wire [15:0] sdram_dq;  // ← 只声明 wire，不在 TB 顶层 assign

    //=============================================================================
    // 时钟 & 复位
    //=============================================================================
    initial sys_clk = 0;
    always #(CLK_PERIOD / 2) sys_clk = ~sys_clk;

    initial begin
        sys_rst_n = 1'b0;
        repeat (5) @(posedge sys_clk);
        sys_rst_n = 1'b1;
        $display("[%0t] Reset released.", $time);
    end

    //=============================================================================
    // DUT
    //=============================================================================
    sdram_ctrl u_dut (
        .sys_clk       (sys_clk),
        .sys_rst_n     (sys_rst_n),
        .sdram_wr_req  (sdram_wr_req),
        .sdram_wr_addr (sdram_wr_addr),
        .wr_burst_len  (wr_burst_len),
        .sdram_data_in (sdram_data_in),
        .sdram_rd_req  (sdram_rd_req),
        .sdram_rd_addr (sdram_rd_addr),
        .rd_burst_len  (rd_burst_len),
        .sdram_wr_ack  (sdram_wr_ack),
        .sdram_data_out(sdram_data_out),
        .init_end      (init_end),
        .sdram_rd_ack  (sdram_rd_ack),
        .sdram_cke     (sdram_cke),
        .sdram_cs_n    (sdram_cs_n),
        .sdram_ras_n   (sdram_ras_n),
        .sdram_cas_n   (sdram_cas_n),
        .sdram_we_n    (sdram_we_n),
        .sdram_ba      (sdram_ba),
        .sdram_addr    (sdram_addr),
        .sdram_dq      (sdram_dq)
    );

    //=============================================================================
    // SDRAM 行为模型（用 force/release 驱动 DQ，不产生双 assign）
    //=============================================================================
    // 命令解码
    wire [3:0] cmd = {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n};
    localparam C_NOP = 4'b0111;
    localparam C_ACT = 4'b0011;
    localparam C_RD = 4'b0101;
    localparam C_WR = 4'b0100;
    localparam C_PRE = 4'b0010;
    localparam C_REF = 4'b0001;
    localparam C_MRS = 4'b0000;
    localparam C_BST = 4'b0110;

    // 简化存储体
    reg     [15:0] mem[0:1023];
    integer        k;
    initial begin
        for (k = 0; k < 1024; k = k + 1)
        mem[k] = 16'hA000 + k[15:0];  // 预填数据，读出来验证
    end

    // 读 pipeline
    reg [3:0] rd_cl_cnt;
    reg       rd_active;
    reg [9:0] rd_beat;

    // 写 pipeline
    reg [3:0] wr_cl_cnt;
    reg       wr_active;
    reg [9:0] wr_beat;

    initial begin
        rd_active = 0;
        wr_active = 0;
    end

    // 主模型
    always @(posedge sys_clk) begin
        // ---- 命令识别 ----
        if (sdram_cs_n == 1'b0) begin
            case (cmd)
                C_ACT: begin
                    // 激活（不需要模型做什么，只是标记）
                end
                C_RD: begin
                    // 读命令：CL 拍后开始 force DQ
                    rd_active <= 1'b1;
                    rd_cl_cnt <= CL;
                    rd_beat   <= 10'd0;
                end
                C_WR: begin
                    // 写命令：CL 拍后开始采样 DQ
                    wr_active <= 1'b1;
                    wr_cl_cnt <= CL;
                    wr_beat   <= 10'd0;
                end
                C_BST: begin
                    // Burst Stop
                    if (rd_active) begin
                        rd_active <= 1'b0;
                        release sdram_dq;  // ← 释放 DQ
                    end
                    wr_active <= 1'b0;
                end
                C_PRE: begin
                    rd_active <= 1'b0;
                    wr_active <= 1'b0;
                    release sdram_dq;
                end
                default: ;
            endcase
        end

        // ---- 读数据输出（force 驱动 DQ）----
        if (rd_active) begin
            if (rd_cl_cnt > 0) begin
                rd_cl_cnt <= rd_cl_cnt - 1;
            end else begin
                force sdram_dq = mem[rd_beat[9:0]];  // ← force 覆盖控制器的 Z
                rd_beat <= rd_beat + 1;
                if (rd_beat == BURST_LEN - 1) begin
                    rd_active <= 1'b0;
                    // 下一拍 release（让控制器重新控制 DQ）
                    #1 release sdram_dq;
                end
            end
        end

        // ---- 写数据接收（从 DQ 采样）----
        if (wr_active) begin
            if (wr_cl_cnt > 0) begin
                wr_cl_cnt <= wr_cl_cnt - 1;
            end else begin
                mem[wr_beat[9:0]] <= sdram_dq;  // 采样控制器驱动的数据
                $display("[%0t] SDRAM WRITE: mem[%0d] <= 0x%04h", $time, wr_beat, sdram_dq);
                wr_beat <= wr_beat + 1;
                if (wr_beat == BURST_LEN - 1) wr_active <= 1'b0;
            end
        end
    end

    //=============================================================================
    // 用户激励
    //=============================================================================
    initial begin
        sdram_wr_req  = 0;
        sdram_wr_addr = 24'd0;
        wr_burst_len  = BURST_LEN;
        sdram_data_in = 16'hDEAD;
        sdram_rd_req  = 0;
        sdram_rd_addr = 24'd0;
        rd_burst_len  = BURST_LEN;

        // 等初始化完成
        $display("[%0t] Waiting for init_end...", $time);
        @(posedge init_end);
        $display("[%0t] === INIT DONE ===", $time);
        repeat (10) @(posedge sys_clk);

        // ---- 写测试 ----
        $display("[%0t] >>> WRITE TEST START", $time);
        @(posedge sys_clk);
        sdram_wr_req  <= 1'b1;
        sdram_wr_addr <= 24'h00_0000;
        sdram_data_in <= 16'hDEAD;
        @(posedge sys_clk);
        sdram_wr_req <= 1'b0;

        // 等写完成（给足时间）
        repeat (60) @(posedge sys_clk);

        // ---- 读测试 ----
        $display("[%0t] >>> READ TEST START", $time);
        @(posedge sys_clk);
        sdram_rd_req  <= 1'b1;
        sdram_rd_addr <= 24'h00_0000;
        @(posedge sys_clk);
        sdram_rd_req <= 1'b0;

        repeat (60) @(posedge sys_clk);

        $display("[%0t] === ALL DONE ===", $time);
        repeat (10) @(posedge sys_clk);

    end

    //=============================================================================
    // 波形 dump
    //=============================================================================
    initial begin
        $dumpfile("sdram_tb.vcd");
        $dumpvars(0, tb_sdram_ctrl);
    end

    // 关键信号变化打印（不依赖层次路径，只看顶层端口）
    always @(posedge sys_clk) begin
        if (init_end)
            $display(
                "[%0t] cmd=%b ba=%b addr=%h dq=%h | wr_ack=%b rd_ack=%b data_out=%h",
                $time,
                cmd,
                sdram_ba,
                sdram_addr,
                sdram_dq,
                sdram_wr_ack,
                sdram_rd_ack,
                sdram_data_out
            );
    end

endmodule
