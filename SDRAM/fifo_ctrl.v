module fifo_ctrl #(
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
    output reg [23:0] sdram_rd_addr     //SDRAM读地址
);

    wire       sdram_wr_ack_neg;
    wire       sdram_rd_ack_neg;
    reg        sdram_wr_ack_dly;
    reg        sdram_rd_ack_dly;
    reg  [9:0] wr_fifo_num;


    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sdram_wr_ack_dly <= 1'd0;
        end else begin
            sdram_wr_ack_dly <= sdram_wr_ack;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sdram_rd_ack_dly <= 1'd0;
        end else begin
            sdram_rd_ack_dly <= sdram_rd_ack;
        end
    end

    assign sdram_wr_ack_neg = sdram_wr_ack_dly && ~sdram_wr_ack;
    assign sdram_rd_ack_neg = sdram_rd_ack_dly && ~sdram_rd_ack;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_fifo_wr_req <= 1'd0;
            rd_fifo_rd_req <= 1'd0;
        end else if (wr_fifo_num >= wr_burst_len) begin
            wr_fifo_wr_req <= 1'd1;
            rd_fifo_rd_req <= 1'd0;
        end else if (rd_fifo_num < rd_burst_len && read_valid) begin
            wr_fifo_wr_req <= 1'd0;
            rd_fifo_rd_req <= 1'd1;
        end else begin
            wr_fifo_wr_req <= 1'd0;
            rd_fifo_rd_req <= 1'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sdram_wr_addr <= 24'd0;
        end else if (wr_rst) begin
            sdram_wr_addr <= sdram_wr_b_addr;
        end else if (sdram_wr_ack_neg) begin
            if (sdram_wr_addr < (sdram_wr_e_addr - wr_burst_len)) begin
                sdram_wr_addr <= sdram_wr_addr + wr_burst_len;
            end else begin
                sdram_wr_addr <= sdram_wr_b_addr;
            end
        end else begin
            sdram_wr_addr <= sdram_wr_addr;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sdram_rd_addr <= 24'd0;
        end else if (rd_rst) begin
            sdram_rd_addr <= sdram_rd_b_addr;
        end else if (sdram_rd_ack_neg) begin
            if (sdram_wr_addr < (sdram_rd_e_addr - rd_burst_len)) begin
                sdram_rd_addr <= sdram_rd_addr + rd_burst_len;
            end else begin
                sdram_rd_addr <= sdram_rd_b_addr;
            end
        end else begin
            sdram_rd_addr <= sdram_rd_addr;
        end
    end

    //fifo instnece

endmodule
