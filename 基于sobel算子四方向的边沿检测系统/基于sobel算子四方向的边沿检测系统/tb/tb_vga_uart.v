`timescale 1ns/1ps

module tb_vga_uart();

reg  sclk;
reg  rst_n;
reg  rx;
wire tx;
wire h_sync;
wire v_sync;
wire [2:0] r;
wire [2:0] g;
wire [1:0] b;

// 用于检测信号边沿的寄存器
reg h_sync_prev;
reg v_sync_prev;

vga_uart u_vga_uart(
    .sclk(sclk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .r(r),
    .g(g),
    .b(b)
);

// 系统时钟 50MHz
initial begin
    sclk = 0;
    forever #10 sclk = ~sclk;
end

// 初始化
initial begin
    rst_n = 0;
    rx = 1;
    h_sync_prev = 0;
    v_sync_prev = 0;
    #1000;
    rst_n = 1;
    #1000;
    
    $display("=== VGA UART System Test Start ===");
    $display("Time: %0t ns", $time);
end

// 主测试序列
initial begin
    // 等待复位完成
    #2000;
    
    // 测试：发送200x200图像测试系统
    $display("\n--- Test: 200x200 Image Transmission ---");
    test_large_image();
    
    #1000000;  // 延长仿真时间观察VGA输出
    
    $display("\n=== VGA UART System Test Completed ===");
    $display("Time: %0t ns", $time);
    $finish;
end

// 发送大图像测试
task test_large_image;
    integer i, j;
    begin
        $display("Sending 200x200 test image via UART...");
        
        // 发送200x200测试图像
        for (j = 0; j < 200; j = j + 1) begin
            for (i = 0; i < 200; i = i + 1) begin
                // 创建明显的边缘测试图案
                if (i < 100)  // 左半部分黑色，右半部分白色，创建垂直边缘
                    send_byte(8'h00);  // 黑色
                else
                    send_byte(8'hFF);  // 白色
                
                #500;  // 字节间间隔
            end
            if (j % 20 == 0) begin
                $display("  Line %0d sent", j);
            end
        end
        
        $display("Large image transmission completed");
    end
endtask

// 发送单个字节
task send_byte;
    input [7:0] data;
    integer k;
    begin
        // 起始位
        rx = 1'b0;
        #8680;
        
        // 8个数据位 (LSB first)
        for (k = 0; k < 8; k = k + 1) begin
            rx = data[k];
            #8680;
        end
        
        // 停止位
        rx = 1'b1;
        #8680;
    end
endtask

// 监控信号边沿
always @(posedge sclk) begin
    h_sync_prev <= h_sync;
    v_sync_prev <= v_sync;
    
    // 显示VGA同步信号变化
    if (h_sync && !h_sync_prev) begin
        $display("H_SYNC: rising edge");
    end
    if (v_sync && !v_sync_prev) begin
        $display("V_SYNC: rising edge - FRAME START");
    end
end

// 监控RGB输出 - 只在有变化时显示
reg [7:0] last_rgb;
always @(posedge sclk) begin
    last_rgb <= {r, g, b};
    if ({r, g, b} !== last_rgb && (r != 0 || g != 0 || b != 0)) begin
        $display("RGB_CHANGE: r=%b, g=%b, b=%b", r, g, b);
    end
end

// 监控系统状态
always @(posedge sclk) begin
    // 显示UART接收
    if (u_vga_uart.U3.po_flag) begin
        $display("UART_RX: data=0x%h", u_vga_uart.U3.po_data);
    end
end

// 波形保存
initial begin
    $dumpfile("vga_uart.vcd");
    $dumpvars(0, tb_vga_uart);
end

endmodule