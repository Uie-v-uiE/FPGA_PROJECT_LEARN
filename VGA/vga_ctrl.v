module vga_ctrl #(
    // 640*480@60 clk = 25.175 Mhz
    //h
    parameter sync_h         = 96,
    parameter h_back_porch   = 40,
    parameter h_left         = 8,
    parameter h_active_pixel = 640,
    parameter h_right        = 8,
    parameter h_front_porch  = 8,
    parameter h_period       = 800,
    //v
    parameter sync_v         = 2,
    parameter v_back_porch   = 25,
    parameter v_up           = 8,
    parameter v_active_pixel = 480,
    parameter v_down         = 8,
    parameter v_front_porch  = 2,
    parameter v_period       = 525
) (
    input             clk,
    input             rst_n,
    input      [15:0] pixel_data,
    output reg [ 9:0] pixel_x,
    output reg [ 9:0] pixel_y,
    output reg        h_sync,
    output reg        v_sync,
    output reg [15:0] rgb
);

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;
    reg       pixel_data_valid;

    assign pixel_x = h_cnt;
    assign pixel_y = v_cnt;
    assign rgb     = pixel_data_valid ? pixel_data : 16'd0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 10'd0;
        end else if (h_cnt == h_period) begin
            h_cnt = 10'd0;
        end else begin
            h_cnt <= h_cnt + 10'd1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_cnt = 10'd0;
        end else if (v_cnt == v_period) begin
            v_cnt <= 10'd0;
        end else if (h_cnt == h_period) begin
            v_cnt <= v_cnt + 10'd1;
        end else begin
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_sync <= 1'b0;
        end else if (h_cnt > 0 && h_cnt < sync_h) begin
            h_sync <= 1'b1;
        end else begin
            h_sync <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_sync <= 1'b0;
        end else if (v_cnt > 0 && v_cnt < sync_v) begin
            v_sync <= 1'b1;
        end else begin
            v_sync <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data_valid <= 1'd0;
        end else if ((h_cnt > sync_h + h_back_porch + h_left) &&
                     (h_cnt < sync_h + h_back_porch + h_left + h_active_pixel) &&
                     (v_cnt > sync_v + v_back_porch + v_up) &&
                     (v_cnt < sync_v + v_back_porch + v_up + v_active_pixel)) begin
            pixel_data_valid <= 1'b1;
        end else begin
            pixel_data_valid <= 1'b0;
        end
    end


endmodule
