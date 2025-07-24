`timescale 1ns / 1ps

module CONV (
    input clk,
    input reset,
    output reg busy,
    input ready,

    output reg [11:0] iaddr,
    input signed [19:0] idata,

    output reg cwr,
    output reg [11:0] caddr_wr,
    output reg [19:0] cdata_wr,

    output reg crd,
    output reg [11:0] caddr_rd,
    input [19:0] cdata_rd,

    output reg [2:0] csel
);

    typedef enum logic [2:0] {
        IDLE,
        INPUT,
        WRITE_L0,
        READ_L0,
        WRITE_L1
    } state_t;
    state_t current_state, next_state;

    logic [11:0] addr;
    logic [5:0] x, y;
    logic [11:0] real_addr;
    logic [3:0] counter;
    logic signed [19:0] idata_temp;
    logic signed [19:0] k_c, k_1, k_2, k_3, k_4, k_5, k_6, k_7, k_8;
    logic signed [39:0] cdata_wr_reg;
    logic signed [39:0] product_result;

    logic [11:0] real_addr_relu;
    logic [5:0] x_relu, y_relu;
    logic [9:0] relu_write_addr;

    assign addr = {x, y};
    assign k_c  = 20'hF8F71;
    assign k_1  = 20'h0A89E;
    assign k_2  = 20'h092D5;
    assign k_3  = 20'h06D43;
    assign k_4  = 20'h01004;
    assign k_5  = 20'hF6E54;
    assign k_6  = 20'hFA6D7;
    assign k_7  = 20'hFC834;
    assign k_8  = 20'hFAC19;


    always_ff @(posedge clk or posedge reset) begin
        if (reset) current_state <= IDLE;
        else current_state <= next_state;
    end

    always_comb begin
        case (current_state)
            IDLE: begin
                if (!ready) begin
                    next_state = INPUT;
                end else begin
                    next_state = IDLE;
                end
            end
            INPUT: begin
                if (counter == 4'b1010) begin
                    next_state = WRITE_L0;
                end else begin
                    next_state = INPUT;
                end
            end
            WRITE_L0: begin
                if (addr == 4095) begin
                    next_state = READ_L0;
                end else begin
                    next_state = INPUT;
                end
            end
            READ_L0: begin  //還沒修改
                if (counter == 3) begin
                    next_state = WRITE_L1;
                end else begin
                    next_state = READ_L0;
                end
            end
            WRITE_L1: begin
                if (relu_write_addr == 1023) begin
                    next_state = IDLE;
                end else begin
                    next_state = READ_L0;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    //real_addr: 0~4095 每一個週期加一次
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            real_addr <= 0;
        end else if (ready == 0 && current_state == WRITE_L0) real_addr <= real_addr + 1;
        else real_addr <= real_addr;
    end
    assign x = real_addr[11:6];
    assign y = real_addr[5:0];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            busy <= 0;
        end else if (ready) begin
            busy <= 1;
        end else if (relu_write_addr == 1023 && current_state == WRITE_L1) busy <= 0;
        else begin
            busy <= busy;  // 保持原來的 busy 狀態（不改變）
        end
    end

    //counter: 0~8
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else if (ready == 0 && current_state == INPUT) counter <= counter + 1;
        else if (current_state == WRITE_L0) counter <= 0;
        else if (current_state == READ_L0) counter <= counter + 1;
        else counter <= 0;
    end
    always_comb begin
        case (counter)
            0: iaddr = {x, y};
            1: iaddr = {x - 1'd1, y - 1'd1};
            2: iaddr = {x - 1'd1, y};
            3: iaddr = {x - 1'd1, y + 1'd1};
            4: iaddr = {x, y - 1'd1};
            5: iaddr = {x, y + 1'd1};
            6: iaddr = {x + 1'd1, y - 1'd1};
            7: iaddr = {x + 1'd1, y};
            8: iaddr = {x + 1'd1, y + 1'd1};
            default: iaddr = 0;
        endcase
    end
    always_ff @(posedge clk)  begin        
        case (counter)
            0: idata_temp <= idata;
            1: begin
                if (x == 0 || y == 0) idata_temp <= 0;
                else idata_temp <= idata;
            end
            2: begin
                if (x == 0) idata_temp <= 0;
                else idata_temp <= idata;
            end
            3: begin
                if (x == 0 || y == 63) idata_temp <= 0;
                else idata_temp <= idata;
            end
            4: begin
                if (y == 0) idata_temp <= 0;
                else idata_temp <= idata;
            end
            5: begin
                if (y == 63) idata_temp <= 0;
                else idata_temp <= idata;
            end
            6: begin
                if (y == 0 || x == 63) idata_temp <= 0;
                else idata_temp <= idata;
            end
            7: begin
                if (x == 63) idata_temp <= 0;
                else idata_temp <= idata;
            end
            8: begin
                if (y == 63 || x == 63) idata_temp <= 0;
                else idata_temp <= idata;
            end
            default: idata_temp <= 0;
        endcase        
    end
    //=========================================

    //reveise
    logic [3:0] counter_temp;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_temp <= 0;
        end
        else counter_temp <= counter;
    end
    //=========================================

    logic signed [19:0] kernal;
    always_comb begin
        if (current_state == INPUT) begin
            case (counter_temp)
                0: kernal = k_c;
                1: kernal = k_1;
                2: kernal = k_2;
                3: kernal = k_3;
                4: kernal = k_4;
                5: kernal = k_5;
                6: kernal = k_6;
                7: kernal = k_7;
                8: kernal = k_8;
                default: kernal = 0;
            endcase
        end
        else kernal = 0;
    end
    // always_ff @(posedge clk or posedge reset) begin
    //     if(reset) begin
    //         product_result <= 0;
    //     end
    //     else if (current_state == INPUT) begin
    //         product_result <= idata_temp * kernal;
    //     end else product_result <= 0;
    // end
    always_comb begin
        if (current_state == INPUT) begin
            product_result = idata_temp * kernal;
        end else product_result = 0;
    end

    // // Instance of DW02_mult_2_stage
    // DW02_mult_2_stage #(20, 20)
    //     U1 ( .A(idata_temp),
    //     .B(kernal),
    //     .TC(1'b1),
    //     .CLK(clk),
    //     .PRODUCT(product_result) );
    //==========================
    // always_ff @(*) begin
    //     if (current_state == INPUT) begin
    //         case (counter)
    //             0: product_result = idata_temp * k_c;
    //             1: product_result = idata_temp * k_1;
    //             2: product_result = idata_temp * k_2;
    //             3: product_result = idata_temp * k_3;
    //             4: product_result = idata_temp * k_4;
    //             5: product_result = idata_temp * k_5;
    //             6: product_result = idata_temp * k_6;
    //             7: product_result = idata_temp * k_7;
    //             8: product_result = idata_temp * k_8;
    //             default: product_result = 0;
    //         endcase
    //     end else product_result = 0;
    // end
    //=========================================
    logic signed [39:0] bias_and_truncation;
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            bias_and_truncation <= 0;
        end else if (current_state == INPUT && counter == 9) begin
            bias_and_truncation <= 40'h0013100000 + 16'b1000_0000_0000_0000; //bias + truncation
        end
        else bias_and_truncation <= 0;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) cdata_wr_reg <= 0;
        else if (current_state == INPUT && counter == 10) begin
            cdata_wr_reg <= cdata_wr_reg + bias_and_truncation;
        end 
        else if (counter == 11) cdata_wr_reg <= 0;
        else if (current_state == INPUT) cdata_wr_reg <= cdata_wr_reg + product_result;
        else if (current_state == READ_L0 && counter == 0) cdata_wr_reg <= cdata_rd;  //
        else if (current_state == READ_L0 && cdata_rd > cdata_wr_reg) cdata_wr_reg <= cdata_rd;
            // if (cdata_rd > cdata_wr_reg) cdata_wr_reg <= cdata_rd;
            // else cdata_wr_reg <= cdata_wr_reg;
        else cdata_wr_reg <= cdata_wr_reg;
    end

    always_comb begin
        if (current_state == WRITE_L0) begin
            if (cdata_wr_reg[39] == 1) cdata_wr = 0;
            else cdata_wr = cdata_wr_reg[35:16];
        end else if (current_state == WRITE_L1) begin
            cdata_wr = cdata_wr_reg;
        end else cdata_wr = 0;
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) csel <= 0;
        else if (counter == 10) csel <= 3'b001;
        else if (current_state == READ_L0 && counter < 3 || (
            caddr_wr == 4095 && counter == 11
            ) || (current_state == WRITE_L1 && counter == 4))  //根據波型硬湊出來的條件
            csel <= 3'b001;
        else if (current_state == READ_L0 && counter == 3) csel <= 3'b011;
        else csel <= 0;
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cwr <= 0;
        end else if (counter == 10) begin
            cwr <= 1;
        end else if (current_state == READ_L0 && counter == 3) cwr <= 1;
        else begin
            cwr <= 0;
        end
    end
    //========================read RELU===================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            real_addr_relu <= 0;
        end else if (ready == 0 && current_state == WRITE_L1 && real_addr_relu[5:1] == 5'b11111)
            real_addr_relu <= real_addr_relu + 66;
        else if (ready == 0 && current_state == WRITE_L1) real_addr_relu <= real_addr_relu + 2;
        else real_addr_relu <= real_addr_relu;
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            relu_write_addr <= 0;
        end else if (current_state == WRITE_L1) begin
            relu_write_addr <= relu_write_addr + 1;
        end
    end
    assign x_relu = real_addr_relu[11:6];
    assign y_relu = real_addr_relu[5:0];

    always_comb begin
        case (counter)
            0: caddr_rd = {x_relu, y_relu};
            1: caddr_rd = {x_relu, y_relu + 1'd1};
            2: caddr_rd = {x_relu + 1'b1, y_relu};
            3: caddr_rd = {x_relu + 1'd1, y_relu + 1'd1};
            default: caddr_rd = 0;
        endcase
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            crd <= 0;
        end else if (current_state == READ_L0 && counter < 3 ||(current_state==WRITE_L0 && counter==11) 
        || (current_state==WRITE_L1 && counter==4)) begin  //根據波型硬湊出來的條件
            crd <= 1;
        end else begin
            crd <= 0;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            caddr_wr <= 0;
        end else if (counter == 10) begin
            caddr_wr <= addr;
        end else if (current_state == READ_L0 && counter == 3) begin
            caddr_wr <= relu_write_addr;
        end
    end


endmodule




