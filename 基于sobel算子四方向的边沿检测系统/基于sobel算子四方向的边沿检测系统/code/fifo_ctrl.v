/*UART数据 → FIFO2 → FIFO1 → 3x3窗口 → 均值滤波 → 多方向Sobel → 投票机制 → 边缘输出*/

module fifo_ctrl(
    input        wire        sclk,
    input        wire        rst_n,
    input        wire        rx_flag,
    input        wire [7:0]  rx_data,
    output       reg         area2,
    output       reg         wr_area,
    output       reg [7:0]   rgb,
    output       reg         tx_flag,
    output       reg [7:0]   tx_data
);

reg         wr_en1;
reg         wr_en2;
reg         rd_en1;
reg         rd_en2; 
wire [7:0]  data_in1;
wire [7:0]  data_in2;
wire [7:0]  dout2;
reg  [7:0]  cnt;
reg  [7:0]  h_cnt;
reg  [7:0]  v_cnt;
reg         add_flag;
wire [7:0]  dout1;
wire        full1; 
wire        empty1;
wire        full2;
wire        empty2;

reg  [23:0] a;
reg  [23:0] b;
reg  [23:0] c;
wire [7:0]  c3;
wire [7:0]  c2;
wire [7:0]  c1;
wire [7:0]  b3; 
wire [7:0]  b2;
wire [7:0]  b1;
wire [7:0]  a3;
wire [7:0]  a2;
wire [7:0]  a1;

// 均值滤波
reg [10:0] sum_pixels;
reg [7:0]  filtered_b2;

// 四个方向的Sobel计算
reg [10:0] dx;      // 0度 (水平)
reg [10:0] dy;      // 90度 (垂直)
reg [10:0] d45;     // 45度
reg [10:0] d135;    // 135度

reg [10:0] abs_dx;
reg [10:0] abs_dy;
reg [10:0] abs_d45;
reg [10:0] abs_d135;

// 四个方向的梯度值
reg [10:0] value_0;
reg [10:0] value_45;
reg [10:0] value_90;
reg [10:0] value_135;

// 最终梯度值（投票机制）
reg [10:0] value;
reg [10:0] max_val;
reg [10:0] min_val;
reg [2:0] edge_count;  // 计数有多少个方向检测到边缘

parameter H_CNT_END = 199;
parameter V_CNT_END = 199;

// tx_flag 和 tx_data
always @(posedge sclk or negedge rst_n)
    if (!rst_n) begin
        tx_flag <= 0;
        tx_data <= 0;
    end else begin
        tx_flag <= (value >= 40) ? 1'b1 : 1'b0;
        tx_data <= rgb;
    end

// area2
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        area2 <= 0;
    else if (v_cnt >= 2 && h_cnt == 1 && rx_flag == 1)
        area2 <= 1;
    else if (v_cnt >= 2 && h_cnt == 199 && rx_flag == 1)
        area2 <= 0;

// wr_area
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        wr_area <= 0;
    else if (v_cnt >= 2 && h_cnt == 3 && rx_flag == 1)
        wr_area <= 1;
    else if (v_cnt >= 2 && h_cnt == 1 && rx_flag == 1)
        wr_area <= 0;

// cnt
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        cnt <= 0;
    else if (cnt == H_CNT_END && rx_flag == 1)
        cnt <= 0;
    else if (rx_flag == 1)
        cnt <= cnt + 1;

// h_cnt
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        h_cnt <= 0;
    else if (h_cnt == H_CNT_END && rx_flag == 1)
        h_cnt <= 0;
    else if (v_cnt == 0 && cnt == 0 && rx_flag == 1)
        h_cnt <= 0;
    else if (rx_flag == 1)
        h_cnt <= h_cnt + 1;

// v_cnt
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        v_cnt <= 0;
    else if (v_cnt == V_CNT_END && h_cnt == H_CNT_END && rx_flag == 1)
        v_cnt <= 0;
    else if (h_cnt == H_CNT_END && rx_flag == 1)
        v_cnt <= v_cnt + 1;

// wr_en2
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        wr_en2 <= 0;
    else if (v_cnt == V_CNT_END && h_cnt == H_CNT_END && rx_flag == 1)
        wr_en2 <= 0;
    else if (v_cnt >= 1)
        wr_en2 <= rx_flag;

assign data_in2 = rx_data;

// rd_en2
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        rd_en2 <= 0;
    else if (v_cnt == V_CNT_END && h_cnt == H_CNT_END && rx_flag == 1)
        rd_en2 <= 0;
    else if (v_cnt >= 1)
        rd_en2 <= wr_en2;

// wr_en1
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        wr_en1 <= 0;
    else if (v_cnt >= 2)
        wr_en1 <= rd_en2;

// rd_en1
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        rd_en1 <= 0;
    else if (v_cnt == V_CNT_END && h_cnt == H_CNT_END && rx_flag == 1)
        rd_en1 <= 0;
    else if (v_cnt >= 2)
        rd_en1 <= wr_en1;

// add_flag
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        add_flag <= 0;
    else
        add_flag <= rd_en1;

assign data_in1 = dout2;

// a
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        a <= 0;
    else if (add_flag == 1)
        a <= {dout1, a[23:8]};

// b
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        b <= 0;
    else if (add_flag == 1)
        b <= {dout1, b[23:8]};

// c
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        c <= 0;
    else if (add_flag == 1)
        c <= {dout1, c[23:8]};

assign c3 = c[23:16];
assign c2 = c[15:8];
assign c1 = c[7:0];
assign b3 = b[23:16];
assign b2 = b[15:8];
assign b1 = b[7:0];
assign a3 = a[23:16];
assign a2 = a[15:8];
assign a1 = a[7:0];

// ========== 均值滤波 ==========
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        sum_pixels <= 0;
    else if (add_flag == 1)
        sum_pixels <= $signed(a3) + $signed(a2) + $signed(a1) +
                     $signed(b3) + $signed(b2) + $signed(b1) +
                     $signed(c3) + $signed(c2) + $signed(c1);

always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        filtered_b2 <= 0;
    else
        filtered_b2 <= sum_pixels[10:3];  // 右移3位，近似除以8

// ========== 四个方向Sobel计算 ==========
// 0度 (水平方向)
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        dx <= 0;
    else if (rx_flag == 1)
        dx <= ($signed(a3) + ($signed(filtered_b2) << 1) + $signed(c3)) - 
              ($signed(a1) + ($signed(filtered_b2) << 1) + $signed(c1));

// 90度 (垂直方向)
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        dy <= 0;
    else if (rx_flag == 1)
        dy <= ($signed(c1) + ($signed(filtered_b2) << 1) + $signed(c3)) -
              ($signed(a1) + ($signed(filtered_b2) << 1) + $signed(a3));

// 45度方向
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        d45 <= 0;
    else if (rx_flag == 1)
        d45 <= ($signed(a2) + ($signed(filtered_b2) << 1) + $signed(c1)) -
               ($signed(a3) + ($signed(filtered_b2) << 1) + $signed(c2));

// 135度方向
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        d135 <= 0;
    else if (rx_flag == 1)
        d135 <= ($signed(a1) + ($signed(filtered_b2) << 1) + $signed(c2)) -
                ($signed(a2) + ($signed(filtered_b2) << 1) + $signed(c3));

// ========== 绝对值计算 ==========
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        abs_dx <= 0;
    else if (dx[10] == 1)
        abs_dx <= ~dx + 1;
    else
        abs_dx <= dx;

always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        abs_dy <= 0;
    else if (dy[10] == 1)
        abs_dy <= ~dy + 1;
    else
        abs_dy <= dy;

always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        abs_d45 <= 0;
    else if (d45[10] == 1)
        abs_d45 <= ~d45 + 1;
    else
        abs_d45 <= d45;

always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        abs_d135 <= 0;
    else if (d135[10] == 1)
        abs_d135 <= ~d135 + 1;
    else
        abs_d135 <= d135;

// ========== 四个方向的梯度计算 ==========
// 0度梯度
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        value_0 <= 0;
    else begin
        max_val = (abs_dx > abs_dy) ? abs_dx : abs_dy;
        min_val = (abs_dx > abs_dy) ? abs_dy : abs_dx;
        value_0 <= (max_val * 15 + min_val * 5) >> 4;
    end

// 45度梯度
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        value_45 <= 0;
    else begin
        max_val = (abs_d45 > abs_d135) ? abs_d45 : abs_d135;
        min_val = (abs_d45 > abs_d135) ? abs_d135 : abs_d45;
        value_45 <= (max_val * 15 + min_val * 5) >> 4;
    end

// 90度梯度 (使用dy)
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        value_90 <= 0;
    else begin
        max_val = (abs_dy > abs_dx) ? abs_dy : abs_dx;
        min_val = (abs_dy > abs_dx) ? abs_dx : abs_dy;
        value_90 <= (max_val * 15 + min_val * 5) >> 4;
    end

// 135度梯度
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        value_135 <= 0;
    else begin
        max_val = (abs_d135 > abs_d45) ? abs_d135 : abs_d45;
        min_val = (abs_d135 > abs_d45) ? abs_d45 : abs_d135;
        value_135 <= (max_val * 15 + min_val * 5) >> 4;
    end

// ========== 投票机制边缘检测 ==========
always @(posedge sclk or negedge rst_n)
    if (!rst_n) begin
        edge_count <= 0;
        value <= 0;
    end else begin
        // 重置计数器
        edge_count <= 0;
        
        // 计算有多少个方向超过阈值
        if (value_0 >= 40) edge_count <= edge_count + 1;
        if (value_45 >= 40) edge_count <= edge_count + 1;
        if (value_90 >= 40) edge_count <= edge_count + 1;
        if (value_135 >= 40) edge_count <= edge_count + 1;
        
        // 至少2个方向检测到才认为是边缘
        if (edge_count >= 2)
            value <= {10{1'b1}};  // 最大值
        else
            value <= 0;
    end

// ========== 边缘检测输出 ==========
always @(posedge sclk or negedge rst_n)
    if (!rst_n)
        rgb <= 0;
    else if (value >= 40)
        rgb <= 8'b1111_1111;
    else
        rgb <= 8'b0000_0000;

// FIFO例化
fifo_200x8 U1_fifo (
  .clk(sclk),
  .din(data_in1),
  .wr_en(wr_en1),
  .rd_en(rd_en1),
  .dout(dout1),
  .full(full1),
  .empty(empty1)
);

fifo_200x8 U2_fifo (
  .clk(sclk),
  .din(data_in2),
  .wr_en(wr_en2),
  .rd_en(rd_en2),
  .dout(dout2),
  .full(full2),
  .empty(empty2)
);

endmodule