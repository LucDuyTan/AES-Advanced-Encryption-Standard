module AES_CU(
    input wire clk,
    input wire rst,
    input wire start,
    input wire key_done,
    input wire [1:0] key_len,
    output wire key_start,
    output wire load_data,
    output wire run_rounds,
    output wire is_final,
    output wire update_iv,
    output wire valid_out,
    output wire ready,
    output wire [3:0] round_num
);

    localparam IDLE     = 3'd0;
    localparam WAIT_KEY = 3'd1;
    localparam LOAD     = 3'd2;
    localparam ROUNDS   = 3'd3;
    localparam DONE     = 3'd4;

    reg [2:0] state, next_state;
    reg [3:0] r_num, next_r_num;

    wire [3:0] Nr = (key_len == 2'b00) ? 4'd10 : (key_len == 2'b01) ? 4'd12 : 4'd14;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            r_num <= 4'd0;
        end else begin
            state <= next_state;
            r_num <= next_r_num;
        end
    end

    always @(*) begin
        next_state = state;
        next_r_num = r_num;
        case (state)
            IDLE: begin
                if (start) next_state = WAIT_KEY;
            end
            WAIT_KEY: begin
                if (key_done) next_state = LOAD;
            end
            LOAD: begin
                next_state = ROUNDS;
                next_r_num = 4'd1;
            end
            ROUNDS: begin
                if (r_num == Nr) next_state = DONE;
                else next_r_num = r_num + 1'b1;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    assign key_start = (state == IDLE) && start;
    assign load_data = (state == LOAD);
    assign run_rounds = (state == ROUNDS);
    assign is_final = (state == ROUNDS) && (r_num == Nr);
    assign update_iv = (state == DONE);
    assign valid_out = (state == DONE);
    assign ready = (state == IDLE);
    assign round_num = (state == LOAD) ? 4'd0 : r_num;

endmodule
