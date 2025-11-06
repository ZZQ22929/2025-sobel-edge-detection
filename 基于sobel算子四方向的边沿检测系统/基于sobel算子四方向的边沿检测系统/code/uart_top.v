//RX引脚 → uart_rx → 并行数据 → uart_tx → TX引脚

module uart_top(
    input        wire        sclk,
    input        wire        rst_n, 
    input        wire        rx,
    output       wire        tx,
    output       wire        po_flag,
    output       wire[7:0]   po_data
);

// 内部信号定义
wire            rx_flag;        // 接收使能信号
wire            rx_bit_flag;    // 接收位采样标志
wire [3:0]      rx_bit_cnt;     // 接收位计数器
wire            tx_flag;        // 发送使能信号  
wire            tx_bit_flag;    // 发送位采样标志
wire [3:0]      tx_bit_cnt;     // 发送位计数器
wire [7:0]      rx_po_data;     // 接收数据

// UART接收模块实例化
uart_rx u_uart_rx(
    .sclk        (sclk),
    .rst_n       (rst_n),
    .rx          (rx),
    .rx_bit_cnt  (rx_bit_cnt),
    .rx_bit_flag (rx_bit_flag),
    .po_data     (rx_po_data),
    .rx_flag     (rx_flag),
    .po_flag     (po_flag)
);

// 波特率生成模块实例化
uart_bps_rx u_uart_bps_rx(
    .sclk        (sclk),
    .rst_n       (rst_n),
    .rx_flag     (rx_flag),
    .tx_flag     (tx_flag),
    .rx_bit_flag (rx_bit_flag),
    .rx_bit_cnt  (rx_bit_cnt),
    .tx_bit_flag (tx_bit_flag),
    .tx_bit_cnt  (tx_bit_cnt)
);

// UART发送模块实例化
uart_tx u_uart_tx(
    .sclk        (sclk),
    .rst_n       (rst_n),
    .po_flag     (po_flag),        // 使用接收完成标志作为发送触发
    .po_data     (rx_po_data),     // 将接收到的数据直接发送回去
    .tx_bit_flag (tx_bit_flag),
    .tx_bit_cnt  (tx_bit_cnt),
    .tx_flag     (tx_flag),
    .tx_data     (tx)
);

// 输出接收到的数据
assign po_data = rx_po_data;

endmodule