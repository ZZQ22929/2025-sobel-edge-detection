`timescale 1ns/1ps

module tb_fifo_ctrl();

reg  sclk;
reg  rst_n;
reg  rx_flag;
reg  [7:0] rx_data;
wire area2;
wire wr_area;
wire [7:0] rgb;
wire tx_flag;
wire [7:0] tx_data;

// 文件读取变量
integer input_image_file;
integer edge_result_file;
reg [7:0] image_memory [0:39999]; // 200x200像素
integer i;

fifo_ctrl u_fifo_ctrl(
    .sclk(sclk),
    .rst_n(rst_n),
    .rx_flag(rx_flag),
    .rx_data(rx_data),
    .area2(area2),
    .wr_area(wr_area),
    .rgb(rgb),
    .tx_flag(tx_flag),
    .tx_data(tx_data)
);

// 时钟生成 - 50MHz
initial begin
    sclk = 0;
    forever #10 sclk = ~sclk;
end

// 初始化
initial begin
    rst_n = 0;
    rx_flag = 0;
    rx_data = 0;
    
    // 使用绝对路径读取输入图像文件
    $display("=== 加载输入图像 ===");
    input_image_file = $fopen("C:/Users/HP/PycharmProjects/PythonProject7/input_image.txt", "r");
    if (input_image_file == 0) begin
        $display("错误: 无法打开 input_image.txt");
        $display("请检查文件路径: C:/Users/HP/PycharmProjects/PythonProject7/input_image.txt");
        $finish;
    end
    
    // 读取所有像素到内存
    i = 0;
    while (!$feof(input_image_file)) begin
        if ($fscanf(input_image_file, "%d\n", image_memory[i]) == 1) begin
            i = i + 1;
            if (i % 1000 == 0) begin
                $display("已读取 %0d 个像素...", i);
            end
        end
    end
    $fclose(input_image_file);
    $display("成功加载 %0d 个像素", i);
    
    // 创建输出文件（也使用绝对路径）
    edge_result_file = $fopen("C:/Users/HP/PycharmProjects/PythonProject7/edge_result.txt", "w");
    if (edge_result_file == 0) begin
        $display("错误: 无法创建输出文件");
        $finish;
    end
    
    #1000;
    rst_n = 1;
    #1000;
    
    $display("=== Sobel边缘检测开始 ===");
end

// 主测试序列
initial begin
    // 等待复位完成
    #2000;
    
    // 发送图像数据
    send_image_data();
    
    #100000;
    
    $fclose(edge_result_file);
    $display("\n=== Sobel边缘检测完成 ===");
    $display("边缘检测结果已保存到: C:/Users/HP/PycharmProjects/PythonProject7/edge_result.txt");
    $finish;
end

// 发送图像数据任务
task send_image_data;
    integer x, y;
    begin
        $display("发送图像数据到Sobel处理器...");
        
        // 发送200行，每行200个像素
        for (y = 0; y < 200; y = y + 1) begin
            for (x = 0; x < 200; x = x + 1) begin
                rx_data = image_memory[y * 200 + x];
                rx_flag = 1;
                #20;
                rx_flag = 0;
                #80;
            end
            
            // 显示进度
            if (y < 5 || y % 40 == 0) begin
                $display("已处理第 %0d 行", y);
            end
        end
        
        $display("图像数据发送完成");
    end
endtask

// 记录边缘检测结果到文件
always @(posedge sclk) begin
    if (u_fifo_ctrl.rd_en1) begin
        // 写入边缘检测结果
        $fwrite(edge_result_file, "%0d\n", rgb);
    end
end

// 监控处理进度
reg [15:0] processed_pixels = 0;
always @(posedge sclk) begin
    if (u_fifo_ctrl.rd_en1) begin
        processed_pixels <= processed_pixels + 1;
        if (processed_pixels % 1000 == 0) begin
            $display("已生成 %0d 个边缘检测结果", processed_pixels);
        end
    end
end

endmodule