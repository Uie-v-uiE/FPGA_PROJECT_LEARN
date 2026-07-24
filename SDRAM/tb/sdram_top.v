module sdram_top #(
    parameter PARAM = VALUE
) (
    input  wire        sys_clk,          //系统时钟
    input  wire        clk_out,          //相位偏移时钟
    input  wire        sys_rst_n,        //复位信号,低有效
    //写FIFO信号
    input  wire        wr_fifo_wr_clk,   //写FIFO写时钟
    input  wire        wr_fifo_wr_req,   //写FIFO写请求
    input  wire [15:0] wr_fifo_wr_data,  //写FIFO写数据
    input  wire [23:0] sdram_wr_b_addr,  //写SDRAM首地址
    input  wire [23:0] sdram_wr_e_addr,  //写SDRAM末地址
    input  wire [ 9:0] wr_burst_len,     //写SDRAM数据突发长度
    input  wire        wr_rst,           //写复位信号
    //读FIFO信号
    input  wire        rd_fifo_rd_clk,   //读FIFO读时钟
    input  wire        rd_fifo_rd_req,   //读FIFO读请求
    input  wire [23:0] sdram_rd_b_addr,  //读SDRAM首地址
    input  wire [23:0] sdram_rd_e_addr,  //读SDRAM末地址
    input  wire [ 9:0] rd_burst_len,     //读SDRAM数据突发长度
    input  wire        rd_rst,           //读复位信号
    output wire [15:0] rd_fifo_rd_data,  //读FIFO读数据
    output wire [ 9:0] rd_fifo_num,      //读fifo中的数据量

    input  wire        read_valid,   //SDRAM读使能
    output wire        init_end,     //SDRAM初始化完成标志
    //SDRAM接口信号
    output wire        sdram_clk,    //SDRAM芯片时钟
    output wire        sdram_cke,    //SDRAM时钟有效信号
    output wire        sdram_cs_n,   //SDRAM片选信号
    output wire        sdram_ras_n,  //SDRAM行地址选通脉冲
    output wire        sdram_cas_n,  //SDRAM列地址选通脉冲
    output wire        sdram_we_n,   //SDRAM写允许位
    output wire [ 1:0] sdram_ba,     //SDRAM的L-Bank地址线
    output wire [12:0] sdram_addr,   //SDRAM地址总线
    output wire [ 1:0] sdram_dqm,    //SDRAM数据掩码
    inout  wire [15:0] sdram_dq      //SDRAM数据总线
);



endmodule
