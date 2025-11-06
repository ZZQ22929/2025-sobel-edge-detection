module double_fifo(
    input        wire        sclk,
    input        wire        rst_n,
    input        wire        rx,
    output       wire        tx
);

wire        rx_flag;
wire [7:0]  rx_data;
wire        tx_flag;
wire [7:0]  tx_data;
wire        area2;
wire        wr_area;
wire [7:0]  rgb;

// fifo_ctrl - 包含所有端口
fifo_ctrl U1(
    .sclk    (sclk    ),
    .rst_n   (rst_n   ),
    .rx_flag (rx_flag ),
    .rx_data (rx_data ),
    .area2   (area2   ),
    .wr_area (wr_area ),
    .rgb     (rgb     ),
    .tx_flag (tx_flag ),
    .tx_data (tx_data )
);

// uart_ctrl
uart_ctrl U2(
    .sclk    (sclk    ),
    .rst_n   (rst_n   ), 
    .rx      (rx      ),
    .tx_flag (tx_flag ),
    .tx_data (tx_data ),
    .po_flag (rx_flag ),
    .rx_data (rx_data ),
    .tx      (tx      )
);

endmodule