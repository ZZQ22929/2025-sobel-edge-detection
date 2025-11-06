/*VGA时序生成 → 动画位置控制 → 图像显示区域 → 彩色条背景
    ↓              ↓              ↓            ↓
同步信号       移动逻辑       Sobel结果显示   静态背景*/

module vga_uart(
    input   wire        sclk,
    input   wire        rst_n,
    input   wire        rx,
    output  wire        tx,
    output  wire        h_sync,
    output  wire        v_sync,
    output  wire[2:0]  r,
    output  wire[2:0]  g,
    output  wire[1:0]  b  
);
    wire        vga_clk;
    wire[7:0]   rx_data;    
    wire        po_flag;
    wire        area;
    wire[7:0]   dout;
    
    // 新增FIFO控制信号
    wire        area2;
    wire        wr_area;
    wire[7:0]   fifo_rgb;    // FIFO输出的边缘检测结果

    // vga_clk部分例化
    vga_clk_module U1(
        .sclk(sclk),
        .rst_n(rst_n),
        .vga_clk(vga_clk)     
    );

    // vga_module部分例化
    vga_module U2(
        .sclk(sclk),
        .rst_n(rst_n),
        .vga_clk(vga_clk),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .dout(dout),
        .r(r),
        .g(g),
        .area(area),
        .b(b)  
    );

    // uart_top部分例化
    uart_top U3(
        .sclk(sclk),
        .rst_n(rst_n), 
        .rx(rx),
        .tx(tx),
        .po_flag(po_flag),
        .po_data(rx_data)
    );

    // fifo_ctrl部分例化 - 新增
    fifo_ctrl U4(
        .sclk(sclk),
        .rst_n(rst_n),
        .rx_flag(po_flag),    // 使用UART接收完成标志
        .rx_data(rx_data),    // UART接收的数据
        .area2(area2),
        .wr_area(wr_area),
        .rgb(fifo_rgb)        // FIFO输出的边缘检测结果
    );

    // ram_ctrl部分例化
    ram_ctrl U5(
        .sclk(sclk),
        .rst_n(rst_n),
        .vga_clk(vga_clk),
        .pi_flag(po_flag),
        .rgb(fifo_rgb),       // 连接FIFO的输出，不是直接连接rx_data
        .area2(area2),
        .area(area),
        .dout(dout)
    );

endmodule