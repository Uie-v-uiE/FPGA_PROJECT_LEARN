`timescale 1ns / 1ns

module tb_arp_tx;

    // 端口声明
    reg        sys_clk;
    reg        sys_rst_n;
    reg        arp_data_en;
    reg  [7:0] arp_tx_data;
    reg  [7:0] arp_crc_32;

    wire       gmii_tx_clk;
    wire       gmii_tx_clk_en;
    wire       gmii_tx_rst_n;
    wire       gmii_tx_en;
    wire       gmii_tx_er;
    wire [7:0] gmii_tx_data;

    // 调试：看内部计数器
    wire [6:0] cnt = u_arp_tx.cnt;
    wire [4:0] cnt_data = u_arp_tx.cnt_data;
    wire [3:0] cnt_crc = u_arp_tx.cnt_crc;

    // 例化待测模块
    arp_tx u_arp_tx (
        .sys_clk       (sys_clk),
        .sys_rst_n     (sys_rst_n),
        .arp_data_en   (arp_data_en),
        .arp_tx_data   (arp_tx_data),
        .arp_crc_32    (arp_crc_32),
        .gmii_tx_clk   (gmii_tx_clk),
        .gmii_tx_clk_en(gmii_tx_clk_en),
        .gmii_tx_rst_n (gmii_tx_rst_n),
        .gmii_tx_en    (gmii_tx_en),
        .gmii_tx_er    (gmii_tx_er),
        .gmii_tx_data  (gmii_tx_data)
    );

    // 1. 生成系统时钟 100MHz (10ns周期)
    initial begin
        sys_clk = 1'b0;
        forever #5 sys_clk = ~sys_clk;
    end

    // 2. 激励信号
    initial begin
        // 初始值
        sys_rst_n   = 1'b0;
        arp_data_en = 1'b0;
        arp_tx_data = 8'h00;
        arp_crc_32  = 8'hFF;

        // 复位
        #20;
        sys_rst_n = 1'b1;
        #20;

        // 启动发送
        arp_data_en = 1'b1;

        // 让仿真跑足够久，看到完整填充 + CRC
        #2000;

        arp_data_en = 1'b0;
        #100;

        $stop;
    end

endmodule
