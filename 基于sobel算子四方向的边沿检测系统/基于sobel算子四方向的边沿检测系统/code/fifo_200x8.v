module fifo_200x8(
    input         clk,
    input  [7:0]  din,
    input         wr_en,
    input         rd_en,
    output reg [7:0]  dout,  // 改为reg类型
    output        full,
    output        empty
);

// FIFO参数
parameter DEPTH = 200;
parameter WIDTH = 8;
parameter ADDR_WIDTH = 8;  // 2^8=256 > 200

// 内部信号
reg [WIDTH-1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_ptr = 0;
reg [ADDR_WIDTH-1:0] rd_ptr = 0;
reg [ADDR_WIDTH:0] count = 0;  // 额外一位用于检测满/空

// 写操作
always @(posedge clk) begin
    if (wr_en && !full) begin
        mem[wr_ptr] <= din;
        wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
    end
end

// 读操作 - 修复版
always @(posedge clk) begin
    if (rd_en && !empty) begin
        dout <= mem[rd_ptr];
        rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
    end
    else if (!rd_en) begin
        // 保持当前输出值
        dout <= dout;
    end
end

// 计数器更新
always @(posedge clk) begin
    case ({wr_en && !full, rd_en && !empty})
        2'b01: count <= count - 1;  // 只读
        2'b10: count <= count + 1;  // 只写
        2'b11: count <= count;      // 同时读写，计数不变
        default: count <= count;    // 无操作
    endcase
end

// 满标志
assign full = (count == DEPTH);

// 空标志  
assign empty = (count == 0);

endmodule