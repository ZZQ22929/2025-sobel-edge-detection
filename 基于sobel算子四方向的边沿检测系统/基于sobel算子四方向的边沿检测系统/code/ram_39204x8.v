/*处理时钟域(sclk) → 双端口RAM → 显示时钟域(vga_clk)
     ↓                    ↓              ↓
 Sobel处理结果 → 帧缓存 → VGA显示数据*/

module ram_39204x8(
    input         clka,
    input         wea,
    input  [15:0] addra,
    input  [7:0]  dina,
    input         clkb,
    input  [15:0] addrb,
    output reg [7:0] doutb
);

// RAM参数
parameter DEPTH = 39204;
parameter WIDTH = 8;
parameter ADDR_WIDTH = 16;

// RAM存储器
reg [WIDTH-1:0] mem [0:DEPTH-1];

// 写操作 (端口A)
always @(posedge clka) begin
    if (wea) begin
        if (addra < DEPTH) begin
            mem[addra] <= dina;
        end
    end
end

// 读操作 (端口B)
always @(posedge clkb) begin
    if (addrb < DEPTH) begin
        doutb <= mem[addrb];
    end else begin
        doutb <= 8'h00;  // 地址越界时输出0
    end
end

endmodule