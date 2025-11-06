/*触发信号 → 波特率同步 → 并转串 → 帧封装 → TX引脚
   ↓           ↓          ↓        ↓       ↓  
tx_flag → 时序控制 → 位序列化 → 添加帧头尾 → 串行输出*/

module	uart_tx(
		input		wire				sclk				,
		input		wire				rst_n				,
		input		wire				po_flag			,
		input		wire[7:0]		    po_data			,
		input		wire				tx_bit_flag	,
		input		wire[3:0]		    tx_bit_cnt	,
		output	reg					   tx_flag		,
		output	reg					   tx_data				
);



//tx_flag定义，当po_flag为高时拉高，当数据传输完成后拉低
always@(posedge	sclk	or	negedge	rst_n)
		if(rst_n==0)
				tx_flag	<=	0;
		else	if(po_flag==1)
				tx_flag	<=	1;
		else	if(tx_bit_flag==1&&tx_bit_cnt==9)		//使能信号在检测到rx起始位的时候拉高电平
				tx_flag	<=	0;									//当八位数据采集完成后拉低电平	
				
//rx
always@(posedge	sclk	or	negedge	rst_n)
		if(rst_n==0)
				tx_data	<=	1'b1	;
		else	if(tx_bit_flag==1)
				case(tx_bit_cnt)
								0:	tx_data	<=	1'b0			;
								1:	tx_data	<=	po_data[0];
								2:	tx_data	<=	po_data[1];
								3:	tx_data	<=	po_data[2];
								4:	tx_data	<=	po_data[3];
								5:	tx_data	<=	po_data[4];
								6:	tx_data	<=	po_data[5];
								7:	tx_data	<=	po_data[6];
								8:	tx_data	<=	po_data[7];
								9:	tx_data	<=	1'b1			;		
					default:  tx_data	<=	1'b1			;	
				endcase
				
endmodule
				                            
