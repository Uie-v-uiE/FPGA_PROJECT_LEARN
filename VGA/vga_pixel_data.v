module vga_pixel_data #(
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
    input         clk,
    input         rst_n,
    input  [ 9:0] pixel_x,
    input  [ 9:0] pixel_y,
    output [15:0] pixel_data
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data <= 16'd0;
        end
    end
endmodule
