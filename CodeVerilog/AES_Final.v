module AES_Final (
    // Avalon-MM Slave Interface
    input  wire        clk,
    input  wire        reset_n,       
    input  wire [3:0]  address,
    input  wire        write,
    input  wire [31:0] writedata,
    input  wire        read,
    output reg  [31:0] readdata,
    output wire        waitrequest
);
    // Các tín hiệu kết nối nội bộ sang AES_TOP
    reg          start;
    reg          mode;
    reg  [1:0]   key_len;
    reg  [2:0]   block_mode;
    reg          init_iv;
    reg  [255:0] key;
    reg  [127:0] iv;
    reg  [127:0] data_in;
    wire [127:0] data_out;
    wire         valid_out;
    wire         ready;
    // Các thanh ghi và bộ đếm quản lý Bus
    reg [1:0]   write_cnt;       
    reg [1:0]   read_cnt;        
    reg [127:0] data_out_buf;    
    reg         data_out_ready;  
    reg         first_block;     

    AES_TOP aes_top_inst (
        .clk(clk),
        .rst(reset_n),           
        .start(start),
        .mode(mode),
        .key_len(key_len),
        .block_mode(block_mode),
        .init_iv(init_iv),
        .key(key),
        .iv(iv),
        .data_in(data_in),
        .data_out(data_out),
        .valid_out(valid_out),
        .ready(ready)
    );

    wire busy = ~ready;

    assign waitrequest = (write && (address == 4'd13) && (write_cnt == 2'd0) && (busy || data_out_ready)) ||
                             (read && (address == 4'd14) && !data_out_ready);

    // Logic Ghi dữ liệu từ Bus (Write Cycle)
    always @(posedge clk or negedge reset_n) begin 
        if (!reset_n) begin                        
            mode       <= 1'b1;
            key_len    <= 2'b00;
            block_mode <= 3'b000;
            key        <= 256'd0;
            iv         <= 128'd0;
            data_in    <= 128'd0;
            write_cnt      <= 2'd0;
            start      <= 1'b0;
            first_block    <= 1'b1;
            init_iv    <= 1'b0;
        end else begin
            start <= 1'b0; 
            if (valid_out) begin
                init_iv <= 1'b0;
                first_block <= 1'b0;
            end
            if (write && !waitrequest) begin
                case (address)
                    4'd0: begin 
                        mode       <= writedata[0];   
                        key_len    <= writedata[2:1]; 
                        block_mode <= writedata[5:3]; 
                        if (writedata[6]) begin           
                            write_cnt   <= 2'd0;
                            first_block <= 1'b1;
                        end
                    end
                    // Nạp Key
                    4'd1: key[31:0]     <= writedata;
                    4'd2: key[63:32]    <= writedata;
                    4'd3: key[95:64]    <= writedata;
                    4'd4: key[127:96]   <= writedata;
                    4'd5: key[159:128]  <= writedata;
                    4'd6: key[191:160]  <= writedata;
                    4'd7: key[223:192]  <= writedata;
                    4'd8: key[255:224]  <= writedata;
                    
                    // Nạp IV
                    4'd9:  iv[31:0]     <= writedata;
                    4'd10: iv[63:32]    <= writedata;
                    4'd11: iv[95:64]    <= writedata;
                    4'd12: begin
                        iv[127:96]   <= writedata;
                        first_block      <= 1'b1; 
                    end
                    
                    // Cổng tiếp nhận dữ liệu 
                    4'd13: begin
                        case (write_cnt)
                            2'd0: data_in[31:0]   <= writedata;
                            2'd1: data_in[63:32]  <= writedata;
                            2'd2: data_in[95:64]  <= writedata;
                            2'd3: begin
                                data_in[127:96] <= writedata;
                                start           <= 1'b1; 
                                if (first_block) begin
                                    init_iv     <= 1'b1; 
                                end
                            end
                        endcase
                        write_cnt <= write_cnt + 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

    // Logic Đọc dữ liệu và Đệm đầu ra (Read Cycle)
    always @(posedge clk or negedge reset_n) begin 
        if (!reset_n) begin                        
            data_out_buf   <= 128'd0;
            data_out_ready <= 1'b0;
            read_cnt       <= 2'd0;
        end else begin
            if (valid_out) begin
                data_out_buf   <= data_out;
                data_out_ready <= 1'b1;
            end

            if (read && !waitrequest) begin
                if (address == 4'd14) begin 
                    if (read_cnt == 2'd3) begin
                        data_out_ready <= 1'b0; 
                    end
                    read_cnt <= read_cnt + 1'b1;
                end
            end
        end
    end

    // Khối Mux chuyển dữ liệu trả về Bus
    always @(*) begin
        readdata = 32'd0;
        if (read) begin
            case (address)
                4'd0:  readdata = {14'd0, data_out_ready, ready, 10'd0, block_mode, key_len, mode};
                4'd1:  readdata = key[31:0];
                4'd2:  readdata = key[63:32];
                4'd3:  readdata = key[95:64];
                4'd4:  readdata = key[127:96];
                4'd5:  readdata = key[159:128];
                4'd6:  readdata = key[191:160];
                4'd7:  readdata = key[223:192];
                4'd8:  readdata = key[255:224];
                4'd9:  readdata = iv[31:0];
                4'd10: readdata = iv[63:32];
                4'd11: readdata = iv[95:64];
                4'd12: readdata = iv[127:96];
                4'd14: begin 
                    case (read_cnt)
                        2'd0: readdata = data_out_buf[31:0];
                        2'd1: readdata = data_out_buf[63:32];
                        2'd2: readdata = data_out_buf[95:64];
                        2'd3: readdata = data_out_buf[127:96];
                    endcase
                end
                default: readdata = 32'hDEADBEEF;
            endcase
        end
    end

endmodule
