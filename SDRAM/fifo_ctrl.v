module fifo_ctrl #(
    parameter PARAM = VALUE
) (
    input             sys_clk,          //系统时钟
    input             sys_rst_n,        //复位信号
    input             wr_fifo_wr_clk,   //写FIFO写时钟
    input             wr_fifo_wr_req,   //写FIFO写请求
    input      [15:0] wr_fifo_wr_data,  //写FIFO写数据
    input      [23:0] sdram_wr_b_addr,  //写SDRAM首地址
    input      [23:0] sdram_wr_e_addr,  //写SDRAM末地址
    input      [ 9:0] wr_burst_len,     //写SDRAM数据突发长度
    input             wr_rst,           //写复位信号
    input             rd_fifo_rd_clk,   //读FIFO读时钟
    input             rd_fifo_rd_req,   //读FIFO读请求
    input      [23:0] sdram_rd_b_addr,  //读SDRAM首地址
    input      [23:0] sdram_rd_e_addr,  //读SDRAM末地址
    input      [ 9:0] rd_burst_len,     //读SDRAM数据突发长度
    input             rd_rst,           //读复位信号
    output     [15:0] rd_fifo_rd_data,  //读FIFO读数据
    output     [ 9:0] rd_fifo_num,      //读fifo中的数据量
    input             read_valid,       //SDRAM读使能
    input             init_end,         //SDRAM初始化完成标志
    input             sdram_wr_ack,     //SDRAM写响应
    output reg        sdram_wr_req,     //SDRAM写请求
    output reg [23:0] sdram_wr_addr,    //SDRAM写地址
    output     [15:0] sdram_data_in,    //写入SDRAM的数据
    input             sdram_rd_ack,     //SDRAM读相应
    input      [15:0] sdram_data_out,   //读出SDRAM数据
    output reg        sdram_rd_req,     //SDRAM读请求
    output reg [23:0] sdram_rd_addr     //SDRAM读地址);
);


endmodule
