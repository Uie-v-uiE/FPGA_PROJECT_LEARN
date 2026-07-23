module sdram_arbit #(
    parameter NOP         = 4'b0111,
    parameter SDRAM_IDLE  = 5'b0000_1,
    parameter SDRAM_ARBIT = 5'b0001_0,
    parameter SDRAM_A_REF = 5'b0010_0,
    parameter SDRAM_WRITE = 5'b0100_0,
    parameter SDRAM_READ  = 5'b1000_0

) (
    input             sys_clk,
    input             sys_rst_n,
    input      [ 3:0] init_cmd,
    input      [ 1:0] init_ba,
    input      [12:0] init_addr,
    input             init_end,
    input             aref_req,
    input      [ 3:0] aref_cmd,
    input      [ 1:0] aref_ba,
    input      [12:0] aref_addr,
    input             aref_end,
    input             wr_req,
    input      [ 3:0] wr_cmd,
    input      [ 1:0] wr_ba,
    input      [12:0] wr_addr,
    input             wr_sdram_en,
    input      [15:0] wr_data,
    input             wr_end,
    input             rd_req,
    input      [ 3:0] rd_cmd,
    input      [ 1:0] rd_ba,
    input      [12:0] rd_addr,
    input             rd_end,
    output reg        aref_en,
    output reg        wr_en,
    output reg        rd_en,
    output reg        sdram_cke,
    output            sdram_cs_n,
    output            sdram_cas_n,
    output            sdram_ras_n,
    output            sdram_we_n,
    output reg [ 1:0] sdram_ba,
    output reg [12:0] sdram_addr,
    inout      [15:0] sdram_dq
);

    reg [4:0] sdram_current_state;
    reg [4:0] sdram_next_state;
    reg [4:0] sdram_cmd;

    always @(*) begin
        case (sdram_current_state)
            SDRAM_IDLE: begin
                if (init_end) begin
                    sdram_next_state = SDRAM_ARBIT;
                end else begin
                    sdram_next_state = SDRAM_IDLE;
                end
            end
            SDRAM_ARBIT: begin
                if (aref_req) begin
                    sdram_next_state = SDRAM_A_REF;
                end else if (wr_req) begin
                    sdram_next_state = SDRAM_WRITE;
                end else if (rd_req) begin
                    sdram_next_state = SDRAM_READ;
                end else begin
                    sdram_next_state = SDRAM_ARBIT;
                end
            end
            SDRAM_A_REF: begin
                if (aref_end) begin
                    sdram_next_state = SDRAM_ARBIT;
                end else begin
                    sdram_next_state = SDRAM_A_REF;
                end
            end
            SDRAM_WRITE: begin
                if (wr_end) begin
                    sdram_next_state = SDRAM_ARBIT;
                end else begin
                    sdram_next_state = SDRAM_WRITE;
                end
            end
            SDRAM_READ: begin
                if (rd_en) begin
                    sdram_next_state = SDRAM_ARBIT;
                end else begin
                    sdram_next_state = SDRAM_READ;
                end
            end
            default: sdram_next_state = SDRAM_IDLE;
        endcase
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sdram_current_state <= SDRAM_IDLE;
        end else begin
            sdram_current_state <= sdram_next_state;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            aref_en <= 1'd0;
        end else if (sdram_current_state == SDRAM_ARBIT && aref_req) begin
            aref_en <= 1'd1;
        end else if (aref_end) begin
            aref_en <= 1'd0;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_en <= 1'd0;
        end else if (sdram_current_state == SDRAM_ARBIT && !aref_req && wr_req) begin
            wr_en <= 1'd1;
        end else if (wr_end) begin
            wr_en <= 1'd0;
        end else begin
            wr_en <= wr_en;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rd_en <= 1'd0;
        end else if (sdram_current_state == SDRAM_ARBIT && !aref_req && !wr_req && rd_req) begin
            rd_en <= 1'd1;
        end else if (rd_end) begin
            rd_en <= 1'd0;
        end else begin
            rd_en <= rd_en;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sdram_cmd  <= NOP;
            sdram_ba   <= 2'b11;
            sdram_addr <= 13'h1fff;
        end else if (sdram_current_state == SDRAM_IDLE && sdram_next_state != SDRAM_ARBIT) begin
            sdram_cmd  <= init_cmd;
            sdram_ba   <= init_ba;
            sdram_addr <= init_addr;
        end else if (sdram_next_state == SDRAM_ARBIT) begin
            sdram_cmd  <= NOP;
            sdram_ba   <= 2'b11;
            sdram_addr <= 13'h1fff;
        end else if (sdram_current_state == SDRAM_ARBIT && sdram_next_state == SDRAM_A_REF) begin
            sdram_cmd  <= aref_cmd;
            sdram_ba   <= aref_ba;
            sdram_addr <= aref_addr;
        end else if (sdram_current_state == SDRAM_ARBIT && sdram_next_state == SDRAM_WRITE) begin
            sdram_cmd  <= wr_cmd;
            sdram_ba   <= wr_ba;
            sdram_addr <= wr_addr;
        end else if (sdram_current_state == SDRAM_ARBIT && sdram_next_state == SDRAM_READ) begin
            sdram_cmd  <= rd_cmd;
            sdram_ba   <= rd_ba;
            sdram_addr <= rd_addr;
        end else begin
            sdram_cmd  <= sdram_cmd;
            sdram_ba   <= sdram_ba;
            sdram_addr <= sdram_addr;
        end
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sdram_cke <= 1'b1;
        end else begin
            sdram_cke <= 1'b1;
        end
    end

    assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = sdram_cmd;

    assign sdram_dq = (wr_sdram_en == 1'b1) ? wr_data : 16'bz;

endmodule
