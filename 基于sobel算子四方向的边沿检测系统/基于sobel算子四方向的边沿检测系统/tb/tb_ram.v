`timescale 1ns/1ps

module tb_ram_ctrl();

reg  sclk;
reg  rst_n;
reg  vga_clk;
reg  pi_flag;
reg  [7:0] rgb;
reg  area2;
reg  area;
wire [7:0] dout;

ram_ctrl u_ram_ctrl(
    .sclk(sclk),
    .rst_n(rst_n),
    .vga_clk(vga_clk),
    .pi_flag(pi_flag),
    .rgb(rgb),
    .area2(area2),
    .area(area),
    .dout(dout)
);

// 系统时钟 50MHz
initial begin
    sclk = 0;
    forever #10 sclk = ~sclk;
end

// VGA时钟 25MHz  
initial begin
    vga_clk = 0;
    forever #20 vga_clk = ~vga_clk;
end

initial begin
    // 初始化
    rst_n = 0;
    pi_flag = 0;
    rgb = 0;
    area2 = 0;
    area = 0;
    #1000;
    rst_n = 1;
    #1000;
    
    $display("=== RAM Ctrl Test Start ===");
    $display("Time: %0t ns", $time);
end

// 主测试序列
initial begin
    // 等待复位完成
    #2000;
    
    // 测试1：写入数据到RAM
    $display("\n--- Test 1: Write Data to RAM ---");
    test_write_ram();
    
    // 测试2：从RAM读取数据
    #1000;
    $display("\n--- Test 2: Read Data from RAM ---");
    test_read_ram();
    
    #100000;
    $display("\n=== RAM Ctrl Test Completed ===");
    $display("Time: %0t ns", $time);
    $finish;
end

// 测试写入RAM
task test_write_ram;
    integer i;
    begin
        $display("Writing test data to RAM...");
        area2 = 1;
        
        for (i = 0; i < 100; i = i + 1) begin
            rgb = i[7:0];  // 写入递增数据
            pi_flag = 1;
            #20;
            pi_flag = 0;
            #80;
            
            if (i % 20 == 0) begin
                $display("  Written %0d data, wr_addr=%0d", i, u_ram_ctrl.wr_addr);
            end
        end
        
        area2 = 0;
        $display("Write test completed");
    end
endtask

// 测试读取RAM
task test_read_ram;
    integer i;
    begin
        $display("Reading data from RAM...");
        area = 1;
        
        for (i = 0; i < 50; i = i + 1) begin
            #40;  // 等待VGA时钟
            
            if (i % 10 == 0) begin
                $display("  Read data[%0d] = 0x%h, rd_addr=%0d", i, dout, u_ram_ctrl.rd_addr);
            end
        end
        
        area = 0;
        $display("Read test completed");
    end
endtask

// 监控写入操作
always @(posedge sclk) begin
    if (u_ram_ctrl.wr_en) begin
        $display("RAM_WR: addr=%0d, data=0x%h", u_ram_ctrl.wr_addr, rgb);
    end
end

// 监控读取操作
always @(posedge vga_clk) begin
    if (area) begin
        $display("RAM_RD: addr=%0d, data=0x%h", u_ram_ctrl.rd_addr, dout);
    end
end

// 波形保存
initial begin
    $dumpfile("ram_ctrl.vcd");
    $dumpvars(0, tb_ram_ctrl);
end

endmodule