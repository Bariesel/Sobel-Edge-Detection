`timescale 1ns/1ps


module line_buffer (
	input  wire             clk,
	input  wire             reset_n,
	input  wire [7:0]       data_in,		 // 8 bits pixel in grayscale
	input  wire             valid_in,
	input  wire             enable_lb,
	input  wire [10:0]       image_width,   	 // Width of the image
	input wire  [10:0]       image_height,	 // Height of the image
	output reg              buffer_full,	 // indicate the buffer is ready for reading
	output reg              valid_out,		 // indicate the data is valid to move to the process state
	output reg  [71:0]      output_data
);

	parameter MAX_WIDTH = 1920;  // Standard Full HD width
	parameter MAX_HEIGHT = 1080; // Standard Full HD height


	// SRAM control signals
	reg [10:0] wrPntr;  										// Write pointer
	reg [10:0] rdPntr;  										// Read pointer
	reg [10:0] pntr;  
	
	
	reg[7:0] data0;
	reg[7:0] data1;
	reg[7:0] data2;
	reg[7:0] data0_tmp;
	reg[7:0] data1_tmp;
	reg[7:0] data2_tmp;
	
										// Data input to SRAM
	wire [7:0] sram_data_out0, sram_data_out1, sram_data_out2;  // Data output from SRAM
	reg        sram_write_en0, sram_write_en1, sram_write_en2;  // Write enable signals
	

	// Internal control signals
	reg [10:0] num_line; 			// count the line that insert
	reg [1:0] counter; 				// Output window selection
	reg [10:0] count_row; 			// count the nums of row that read
	reg done_write; 				// indicate we write all needed
	reg done_read;  				// indicate read all needed
	
	reg flag_start_r;
	reg [1:0] flag1;
	reg [7:0] tmpreg1; // save the first pixel in the first line
	reg [7:0] tmpreg2; // save the first pixel in the second line
	//reg start_read;
	reg start;
	
	

	///1 write, 2 read
	dpram2048x8_CB sram_line0(
		.A1(wrPntr),
		.A2(rdPntr),
		.CEB1(clk),
		.CEB2(clk),
		.WEB1(sram_write_en0),
		.WEB2(1'b1),
		.OEB1(1'b1),
		.OEB2(1'b0),
		.CSB1(1'b0),
		.CSB2(1'b0),
		.I1(data_in),
		.I2(8'b0),
		.O1(sram_data_out0),
		.O2(sram_data_out0));
	
	///1 write, 2 read
	dpram2048x8_CB sram_line1(
		.A1(wrPntr),
		.A2(rdPntr),
		.CEB1(clk),
		.CEB2(clk),
		.WEB1(sram_write_en1),
		.WEB2(1'b1),
		.OEB1(1'b1),
		.OEB2(1'b0),
		.CSB1(1'b0),
		.CSB2(1'b0),
		.I1(data_in),
		.I2(8'b0),
		.O1(sram_data_out1),
		.O2(sram_data_out1));

	///1 write, 2 read
	dpram2048x8_CB sram_line02(
		.A1(wrPntr),
		.A2(rdPntr),
		.CEB1(clk),
		.CEB2(clk),
		.WEB1(sram_write_en2),
		.WEB2(1'b1),
		.OEB1(1'b1),
		.OEB2(1'b0),
		.CSB1(1'b0),
		.CSB2(1'b0),
		.I1(data_in),
		.I2(8'b0),
		.O1(sram_data_out2),
		.O2(sram_data_out2));

	
	

	// Write Logic
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			//WRITE LOGIC
			buffer_full <= 0;
			num_line <= 0;
			sram_write_en0 <= 0;
			sram_write_en1 <= 0;
			sram_write_en2 <= 0;
			wrPntr<=0;
			flag1 <=0;
			tmpreg2<=0;
			tmpreg1<=0;
			done_write<=0;
			start<=0;
		end else if(valid_in && (enable_lb||start)) begin
				start<=1;
				if(flag1==0) begin
					tmpreg1<=data_in;
					flag1<=1;
					wrPntr <= 0;
				end else begin
					wrPntr <= (wrPntr == image_width-1) ? 0 : wrPntr + 1;
				end
					
				if (flag1==1 && num_line==1) begin
					tmpreg2<=data_in;
					flag1<=2;
				end
				// chose which line to write 
				case (num_line % 3)
					0: begin
						sram_write_en2 <= 0;
						sram_write_en1 <= 1;
						sram_write_en0 <= 1;
					end
					1: begin 
						sram_write_en1 <= 0;
						sram_write_en0 <= 1;
						sram_write_en2 <= 1;
					end
					2: begin 
						sram_write_en0 <= 0;
						sram_write_en1 <= 1;
						sram_write_en2 <= 1;	
					end
				endcase
				
				if(num_line==1 && wrPntr==2) begin
					buffer_full <= 1;
				end
				if (wrPntr == image_width-2) begin
					num_line <= num_line + 1;
				end
				
				
		end else if(!valid_in) begin
			sram_write_en0 <= 1;
			sram_write_en1 <= 1;
			sram_write_en2 <= 1;
			done_write<=1;
		end
	end
	
	

	always_comb begin
		case (counter)
			0: begin
						
				data0 = 0;
				data1 = sram_data_out2;  
				data2 = sram_data_out1;  
				
			end
			1: begin
				data0 = sram_data_out2;
				data1 = sram_data_out1;
				data2 = (count_row < image_height - 1) ? sram_data_out0 : 0;
			end
			2: begin
				data0 = sram_data_out1;
				data1 = sram_data_out0;
				data2 = (count_row < image_height - 1) ? sram_data_out2 : 0;
			end
			3: begin 
				data0 = sram_data_out0;
				data1 = sram_data_out2;
				data2 = (count_row < image_height - 1) ? sram_data_out1 : 0;
			end
		endcase
	end

	
	// Read Logic
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			valid_out <= 0;
			rdPntr <= 1; 
			pntr <=0;
			counter <= 0;
			count_row <= 0;
			flag_start_r <=0;
			done_read<=0;
			
			
	
		end else if (buffer_full && !done_read ) begin
			
			if(pntr==0 && !flag_start_r) begin
				output_data[7:0] <= 0;
				output_data[15:8] <= 0;
				output_data[23:16] <= 0;
				
				output_data[31:24] <= 0;
				output_data[39:32] <= tmpreg1;
				output_data[47:40] <= tmpreg2;
				
				output_data[55:48] <= 0;
				output_data[63:56] <= data1;;
				output_data[71:64] <= data2;
				
				flag_start_r <= 1;
				valid_out <= 1;
				
			end
			else if(pntr==image_width-1) begin
				output_data[7:0] <= output_data[31:24];
				output_data[15:8] <= output_data[39:32];
				output_data[23:16] <= output_data[47:40];
				output_data[31:24] <= output_data[55:48];
				output_data[39:32] <= output_data[63:56];
				output_data[47:40] <= output_data[71:64];
				output_data[55:48] <= 0;
				output_data[63:56] <= 0;
				output_data[71:64] <= 0;
				
				data0_tmp <=data0;
				data1_tmp <= data1;
				data2_tmp <= data2;
			
				valid_out <= 1;
			end
			
			
			else if(pntr==0) begin
				output_data[7:0] <= 0;
				output_data[15:8] <= 0;
				output_data[23:16] <= 0;
				output_data[31:24] <= data0_tmp;
				output_data[39:32] <= data1_tmp;
				output_data[47:40] <= data2_tmp;
				output_data[55:48] <= data0;
				output_data[63:56] <= data1;
				output_data[71:64] <= data2;
			
				valid_out <= 1;
			
			
			
			end else begin

				// Shift the values correctly
				output_data[7:0] <= output_data[31:24];
				output_data[15:8] <= output_data[39:32];
				output_data[23:16] <= output_data[47:40];

				output_data[31:24] <= output_data[55:48];
				output_data[39:32] <= output_data[63:56];
				output_data[47:40] <= output_data[71:64];

				// Insert new data into the last column
				output_data[55:48] <= data0;
				output_data[63:56] <= data1;
				output_data[71:64] <= data2;
				
				valid_out <= 1;
			end
			
			if (pntr == image_width-2) begin
				counter <= (counter == 3) ? 1 : counter + 1;
				count_row <= count_row+1;
			end	
			rdPntr <= (rdPntr == image_width -1) ? 0 : rdPntr + 1;
			pntr <= (pntr == image_width -1) ? 0 : pntr + 1;
			
			if(count_row==image_height && pntr== 0) begin
				done_read <=1;
				valid_out<=0;
			end if(done_read) begin
				valid_out <=0;
			end
		
		end else begin
			valid_out <=0;
		end
			
		
	
	end

endmodule
