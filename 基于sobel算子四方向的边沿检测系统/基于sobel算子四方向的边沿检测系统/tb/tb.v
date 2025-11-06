`timescale 1ns/1ps

module tb();

reg  sclk;
reg  rst_n;
reg  rx;
wire tx;
wire po_flag;
wire [7:0] po_data;

uart_top u_uart_top(
    .sclk(sclk),
    .rst_n(rst_n), 
    .rx(rx),
    .tx(tx),
    .po_flag(po_flag),
    .po_data(po_data)
);

initial begin
    sclk = 0;
    forever #10 sclk = ~sclk;
end

initial begin
    rst_n = 0;
    rx = 1;
    #1000;
    rst_n = 1;
    #1000;
    
    $display("UART Test Start");
    
    // 发送测试数据
    send_byte(8'h55);
    #100000;
    
    send_byte(8'hAA);
    #100000;
    
    send_byte(8'h12);
    #100000;
    
    $display("UART Test End");
    $finish;
end

task send_byte;
    input [7:0] data;
    integer i;
    begin
        $display("Send byte: 0x%h", data);
        
        // 起始位
        rx = 0;
        #8680;
        
        // 数据位
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #8680;
        end
        
        // 停止位
        rx = 1;
        #8680;
    end
endtask

// 监控po_flag
always @(posedge po_flag) begin
    $display("po_flag detected! Received data: 0x%h", po_data);
end

initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, tb);
end

endmodule