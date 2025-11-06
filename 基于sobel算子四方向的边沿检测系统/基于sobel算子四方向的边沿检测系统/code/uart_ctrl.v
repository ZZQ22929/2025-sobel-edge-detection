module uart_ctrl(
    input        wire        sclk,
    input        wire        rst_n,
    input        wire        rx,
    input        wire        tx_flag,    // 来自 fifo_ctrl 的发送标志
    input        wire [7:0]  tx_data,    // 来自 fifo_ctrl 的发送数据
    output       wire        po_flag,
    output       wire [7:0]  rx_data,
    output       wire        tx          // TX输出
);

wire                rx_bit_flag;
wire [3:0]          rx_bit_cnt;
wire                tx_bit_flag;
wire [3:0]          tx_bit_cnt;
wire                rx_flag;
wire                uart_tx_tx;  // 来自 uart_tx 的 tx 信号

// bps - 需要修改以支持TX
uart_bps_rx U1(
    .sclk          (sclk),
    .rst_n         (rst_n),
    .rx_flag       (rx_flag),
    .tx_flag       (tx_flag),      // 使用来自 fifo_ctrl 的 tx_flag
    .rx_bit_flag   (rx_bit_flag),
    .rx_bit_cnt    (rx_bit_cnt),
    .tx_bit_flag   (tx_bit_flag),
    .tx_bit_cnt    (tx_bit_cnt)
);

// rx
uart_rx U2(
    .sclk          (sclk),
    .rst_n         (rst_n),
    .rx            (rx),
    .rx_bit_cnt    (rx_bit_cnt),
    .rx_bit_flag   (rx_bit_flag),
    .po_data       (rx_data),
    .rx_flag       (rx_flag),
    .po_flag       (po_flag)
);

// tx - 修改实例化，使用来自 fifo_ctrl 的信号
uart_tx U3(
    .sclk          (sclk),
    .rst_n         (rst_n),
    .po_flag       (tx_flag),      // 使用来自 fifo_ctrl 的 tx_flag 作为发送触发
    .po_data       (tx_data),      // 使用来自 fifo_ctrl 的 tx_data
    .tx_bit_flag   (tx_bit_flag),
    .tx_bit_cnt    (tx_bit_cnt),
    .tx_flag       (),             // 这个输出我们不需要
    .tx_data       (tx)            // 连接到顶层输出
);

endmodule