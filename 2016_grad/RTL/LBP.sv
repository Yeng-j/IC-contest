`timescale 1ns/10ps

module LBP( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
    //================================================================
    //  INPUT & OUTPUT DECLARATION
    //================================================================
    input   	    clk;
    input   	    reset;
    input   	    gray_ready;
    input        [7:0]  gray_data;
    output  reg [13:0]  gray_addr;
    output  reg       	    gray_req;
    output  reg [13:0]  lbp_addr;
    output  reg 	    lbp_valid;
    output  reg [7:0]   lbp_data;
    output  reg	    finish;
    //================================================================
    //  ADD YOUR DESIGN BELOW
    //================================================================
    typedef enum logic [1:0] {
        IDLE,     
        INPUT,   
        CAL,   
        OUTPUT    
    } state_t;
    state_t current_state, next_state;

    logic [3:0] in_filled;
    logic [13:0] nxt_lbp_addr;
    logic [7:0] nxt_lbp_data;
    logic [7:0] g_c, g_p1, g_p2, g_p3, g_p4, g_p5, g_p6, g_p7, g_p8;
    
    //=================================================================
    always_ff @(posedge clk or posedge reset) begin
        if(reset)
            current_state<= INPUT;
        else
            current_state<= next_state;
    end
    always_comb begin
        case(current_state)
            INPUT: begin
                if(in_filled==4'b1000)
                    next_state = CAL;
                else
                    next_state = INPUT;
            end
            CAL: begin
                next_state = OUTPUT;
            end
            OUTPUT: begin
                next_state = INPUT;
            end
            IDLE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            gray_req <= 1'b0;
        end
        else begin
            if(gray_ready) begin
                gray_req <= 1'b1;
            end
            else begin
                gray_req <= 1'b0;
            end
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            in_filled <= 4'd0;
        end
        else if(gray_ready) begin
            if(in_filled == 4'd8) begin                
                in_filled <= 4'd6;
            end
            else if (in_filled==4'd6 & gray_addr[6:0]==7'b1111111) begin
                in_filled <= 4'd1;
            end
            else begin
                in_filled <= in_filled + 4'd1;
            end
        end
        else begin
            in_filled <= in_filled;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            gray_addr <= 14'd1;
        end
        else if(gray_ready) begin
            if(in_filled==0) begin
                if(gray_addr==14'd1) begin 
                    gray_addr <= gray_addr-1;
                end
                else gray_addr <= gray_addr + 128;                
            end
            else if(gray_addr[6:0]==7'b1111111 & in_filled==4'd6) begin
                gray_addr <= gray_addr - 14'd255;
            end
            else begin
                case(in_filled)
                    4'd1: gray_addr <= gray_addr+128;
                    4'd2: gray_addr <= gray_addr+128;
                    4'd3: gray_addr <= gray_addr-255;
                    4'd4: gray_addr <= gray_addr+128;
                    4'd5: gray_addr <= gray_addr+128;
                    4'd6: gray_addr <= gray_addr-255;
                    4'd7: gray_addr <= gray_addr+128;
                    4'd8: gray_addr <= gray_addr+128;
                endcase
            end            
        end
        else begin
            gray_addr <= gray_addr;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            lbp_addr <= 14'd129;
        end
        else begin
            lbp_addr <= nxt_lbp_addr;
        end
    end

    always@(*) begin
        if(lbp_valid) begin
            if(lbp_addr[6:1]==6'b111111) begin
                nxt_lbp_addr = lbp_addr + 3;
            end
            else begin
                nxt_lbp_addr = lbp_addr + 1;
            end
        end
        else begin
            nxt_lbp_addr = lbp_addr;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            lbp_valid <= 1'b0;
        end
        else if(current_state == OUTPUT) begin
            lbp_valid <= 1'b1;
        end
        else begin
            lbp_valid <= 1'b0;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            finish <= 1'b0;
        end
        else begin
            if(lbp_addr == 16254)
                finish <= 1'd1;
            else
                finish <= 1'd0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            lbp_data <= 8'd0;
        end
        else begin
            lbp_data <= nxt_lbp_data;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            g_c  <= 8'd0;
            g_p1 <= 8'd0;
            g_p2 <= 8'd0;
            g_p3 <= 8'd0;
            g_p4 <= 8'd0;
            g_p5 <= 8'd0;
            g_p6 <= 8'd0;
            g_p7 <= 8'd0;
            g_p8 <= 8'd0;
        end
        else begin //data-> 5 -> 8 -> 3 -> C -> 7 -> 2 -> 4 -> 6 -> 1 (此順序倒過來就是gray_addr的順序)
            g_p8 <= gray_data;
            g_p5 <= g_p8;
            g_p3 <= g_p5;
            g_p7  <= g_p3;
            g_c <= g_p7;
            g_p2 <= g_c;
            g_p6 <= g_p2;
            g_p4 <= g_p6;
            g_p1 <= g_p4;
        end
    end

    // LBP calculation
    always@(*) begin
    for (int i = 0; i < 8; i = i + 1) begin
        case (i)
            0: nxt_lbp_data[i] = (g_p1 < g_c) ? 1'b0 : 1'b1;
            1: nxt_lbp_data[i] = (g_p2 < g_c) ? 1'b0 : 1'b1;
            2: nxt_lbp_data[i] = (g_p3 < g_c) ? 1'b0 : 1'b1;
            3: nxt_lbp_data[i] = (g_p4 < g_c) ? 1'b0 : 1'b1;
            4: nxt_lbp_data[i] = (g_p5 < g_c) ? 1'b0 : 1'b1;
            5: nxt_lbp_data[i] = (g_p6 < g_c) ? 1'b0 : 1'b1;
            6: nxt_lbp_data[i] = (g_p7 < g_c) ? 1'b0 : 1'b1;
            7: nxt_lbp_data[i] = (g_p8 < g_c) ? 1'b0 : 1'b1;
        endcase
    end
end

endmodule