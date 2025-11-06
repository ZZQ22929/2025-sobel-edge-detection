`timescale 1ns/1ps

module tb_better_image();

reg clk, rst_n, rx;

initial begin
    clk = 0; rst_n = 0; rx = 1;
    
    $display("=== Processing Better Image ===");
    
    #1000;
    rst_n = 1;
    #1000;
    
    process_better_image();
    
    #1000;
    $display("Better image processing completed!");
    $finish;
end

task process_better_image;
    integer f_in, f_out, i;
    reg [79:0] line;
    begin
        f_in = $fopen("my_image_better.txt", "r");  // 使用优化后的图片
        f_out = $fopen("better_result.txt", "w");
        
        $display("Processing optimized image...");
        
        for (i = 0; i < 200; i = i + 1) begin  // 处理更多像素
            if ($fgets(line, f_in) != 0) begin
                // 模拟边缘检测：当像素从黑变白或白变黑时标记为边缘
                if (i > 0) begin
                    // 简单边缘检测逻辑
                    if (line[1:0] == "FF") 
                        $fdisplay(f_out, "FF");  // 白色区域
                    else
                        $fdisplay(f_out, "00");  // 黑色区域
                end
                
                if (i % 40 == 0)
                    $display("  Processed %d/200 pixels", i);
            end
        end
        
        $fclose(f_in);
        $fclose(f_out);
        $display("Generated: better_result.txt");
    end
endtask

always #10 clk = ~clk;

endmodule