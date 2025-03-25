`timescale 1ns/1ps

module conv_calc (
	input wire clk,
	input wire reset_n,
	input wire enable_conv,          // Enable signal from the control module
	input wire [71:0] data,          // Single 72-bit input (3x3 pixel matrix)
	input wire valid_in,
	input wire [26:0] kernel1,
	input wire [26:0] kernel2,
	input wire [26:0] kernel3,
	input wire [26:0] kernel4,
	output reg [15:0] magnitude,    // Sum of absolute values
	output reg conv_done             // Convolution done signal
);


	// Unpack the 72-bit data explicitly for synthesis compatibility
	wire [7:0] matrix_00, matrix_01, matrix_02;
	wire [7:0] matrix_10, matrix_11, matrix_12;
	wire [7:0] matrix_20, matrix_21, matrix_22;
	
	assign matrix_00 = data[7:0];
	assign matrix_01 = data[31:24];
	assign matrix_02 = data[55:48];
	assign matrix_10 = data[15:8];
	assign matrix_11 = data[39:32];
	assign matrix_12 = data[63:56];
	assign matrix_20 = data[23:16];
	assign matrix_21 = data[47:40];
	assign matrix_22 = data[71:64];
	

	// Default Sobel Kernels (3x3 packed into 27 bits each)
	localparam signed [2:0] KERNEL1_0 = -1, KERNEL1_1 =  0, KERNEL1_2 =  1;
	localparam signed [2:0] KERNEL1_3 = -2, KERNEL1_4 =  0, KERNEL1_5 =  2;
	localparam signed [2:0] KERNEL1_6 = -1, KERNEL1_7 =  0, KERNEL1_8 =  1;

	localparam signed [26:0] DEFAULT_KERNEL_1 = {
		KERNEL1_0, KERNEL1_1, KERNEL1_2,
		KERNEL1_3, KERNEL1_4, KERNEL1_5,
		KERNEL1_6, KERNEL1_7, KERNEL1_8
	}; // Sobel X


	localparam signed [2:0] KERNEL2_0 = -1, KERNEL2_1 = -2, KERNEL2_2 = -1;
	localparam signed [2:0] KERNEL2_3 =  0, KERNEL2_4 =  0, KERNEL2_5 =  0;
	localparam signed [2:0] KERNEL2_6 =  1, KERNEL2_7 =  2, KERNEL2_8 =  1;

	localparam signed [26:0] DEFAULT_KERNEL_2 = {
		KERNEL2_0, KERNEL2_1, KERNEL2_2,
		KERNEL2_3, KERNEL2_4, KERNEL2_5,
		KERNEL2_6, KERNEL2_7, KERNEL2_8
	}; // Sobel Y


	localparam signed [2:0] KERNEL3_0 =  0, KERNEL3_1 =  1, KERNEL3_2 =  2;
	localparam signed [2:0] KERNEL3_3 = -1, KERNEL3_4 =  0, KERNEL3_5 =  1;
	localparam signed [2:0] KERNEL3_6 = -2, KERNEL3_7 = -1, KERNEL3_8 =  0;

	localparam signed [26:0] DEFAULT_KERNEL_3 = {
		KERNEL3_0, KERNEL3_1, KERNEL3_2,
		KERNEL3_3, KERNEL3_4, KERNEL3_5,
		KERNEL3_6, KERNEL3_7, KERNEL3_8
	}; // Right Diagonal


	localparam signed [2:0] KERNEL4_0 = -2, KERNEL4_1 = -1, KERNEL4_2 =  0;
	localparam signed [2:0] KERNEL4_3 = -1, KERNEL4_4 =  0, KERNEL4_5 =  1;
	localparam signed [2:0] KERNEL4_6 =  0, KERNEL4_7 =  1, KERNEL4_8 =  2;

	localparam signed [26:0] DEFAULT_KERNEL_4 = {
		KERNEL4_0, KERNEL4_1, KERNEL4_2,
		KERNEL4_3, KERNEL4_4, KERNEL4_5,
		KERNEL4_6, KERNEL4_7, KERNEL4_8
	}; // Left Diagonal


	// Select kernel (if zero, use default)
	wire signed [26:0] selected_kernel1 = (kernel1 == 27'd0) ? DEFAULT_KERNEL_1 : kernel1;
	wire signed [26:0] selected_kernel2 = (kernel2 == 27'd0) ? DEFAULT_KERNEL_2 : kernel2;
	wire signed [26:0] selected_kernel3 = (kernel3 == 27'd0) ? DEFAULT_KERNEL_3 : kernel3;
	wire signed [26:0] selected_kernel4 = (kernel4 == 27'd0) ? DEFAULT_KERNEL_4 : kernel4;
	



	// Internal registers for gradients
	reg signed [10:0] gx, gy, gdiag_right, gdiag_left;
	reg [10:0] abs_gx, abs_gy, abs_gdiag_right, abs_gdiag_left;
	reg flag;
	reg cycle;

	always_comb begin
		abs_gx = (gx < 0) ? -gx : gx;
		abs_gy = (gy < 0) ? -gy : gy;
		abs_gdiag_right = (gdiag_right < 0) ? -gdiag_right : gdiag_right;
		abs_gdiag_left = (gdiag_left < 0) ? -gdiag_left : gdiag_left;
	end
	
	
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			gx <= 0;
			gy <= 0;
			gdiag_right <= 0;
			gdiag_left <= 0;
			flag<=0;
			cycle <=0;
			
		//end else if (enable_conv && valid_in) begin
		 end else if (enable_conv && valid_in) begin
			// Compute gx (horizontal gradient)
			 // Compute gx (horizontal gradient)
			 gx <= ($signed(selected_kernel1[2:0])   * $signed({1'b0, matrix_00})) + 
				   ($signed(selected_kernel1[5:3])   * $signed({1'b0, matrix_01})) + 
				   ($signed(selected_kernel1[8:6])   * $signed({1'b0, matrix_02})) +
				   ($signed(selected_kernel1[11:9])  * $signed({1'b0, matrix_10})) +
				   ($signed(selected_kernel1[14:12]) * $signed({1'b0, matrix_11})) +
				   ($signed(selected_kernel1[17:15]) * $signed({1'b0, matrix_12})) +
				   ($signed(selected_kernel1[20:18]) * $signed({1'b0, matrix_20})) +
				   ($signed(selected_kernel1[23:21]) * $signed({1'b0, matrix_21})) +
				   ($signed(selected_kernel1[26:24]) * $signed({1'b0, matrix_22}));

			 // Compute gy (vertical gradient)
			 gy <= ($signed(selected_kernel2[2:0])   * $signed({1'b0, matrix_00})) + 
				   ($signed(selected_kernel2[5:3])   * $signed({1'b0, matrix_01})) + 
				   ($signed(selected_kernel2[8:6])   * $signed({1'b0, matrix_02})) +
				   ($signed(selected_kernel2[11:9])  * $signed({1'b0, matrix_10})) +
				   ($signed(selected_kernel2[14:12]) * $signed({1'b0, matrix_11})) +
				   ($signed(selected_kernel2[17:15]) * $signed({1'b0, matrix_12})) +
				   ($signed(selected_kernel2[20:18]) * $signed({1'b0, matrix_20})) +
				   ($signed(selected_kernel2[23:21]) * $signed({1'b0, matrix_21})) +
				   ($signed(selected_kernel2[26:24]) * $signed({1'b0, matrix_22}));

			 // Compute gdiag_right (gradient in right diagonal)
			 gdiag_right <= ($signed(selected_kernel3[2:0])   * $signed({1'b0, matrix_00})) + 
							($signed(selected_kernel3[5:3])   * $signed({1'b0, matrix_01})) + 
							($signed(selected_kernel3[8:6])   * $signed({1'b0, matrix_02})) +
							($signed(selected_kernel3[11:9])  * $signed({1'b0, matrix_10})) +
							($signed(selected_kernel3[14:12]) * $signed({1'b0, matrix_11})) +
							($signed(selected_kernel3[17:15]) * $signed({1'b0, matrix_12})) +
							($signed(selected_kernel3[20:18]) * $signed({1'b0, matrix_20})) +
							($signed(selected_kernel3[23:21]) * $signed({1'b0, matrix_21})) +
							($signed(selected_kernel3[26:24]) * $signed({1'b0, matrix_22}));

			 // Compute gdiag_left (gradient in left diagonal)
			 gdiag_left <= ($signed(selected_kernel4[2:0])   * $signed({1'b0, matrix_00})) + 
						   ($signed(selected_kernel4[5:3])   * $signed({1'b0, matrix_01})) + 
						   ($signed(selected_kernel4[8:6])   * $signed({1'b0, matrix_02})) +
						   ($signed(selected_kernel4[11:9])  * $signed({1'b0, matrix_10})) +
						   ($signed(selected_kernel4[14:12]) * $signed({1'b0, matrix_11})) +
						   ($signed(selected_kernel4[17:15]) * $signed({1'b0, matrix_12})) +
						   ($signed(selected_kernel4[20:18]) * $signed({1'b0, matrix_20})) +
						   ($signed(selected_kernel4[23:21]) * $signed({1'b0, matrix_21})) +
						   ($signed(selected_kernel4[26:24]) * $signed({1'b0, matrix_22}));

			
			flag <=1;
		 end else if(cycle==0)begin
			 cycle <=1;
		end else begin
			flag <=0;
		end
		
	end
	
	 always @(posedge clk or negedge reset_n) begin
		 if (!reset_n) begin
			 magnitude <=0;
			 conv_done <=0;
		 end else if (flag) begin
			magnitude <= abs_gx + abs_gy + abs_gdiag_right + abs_gdiag_left;
			conv_done <= 1;
		end else begin
			conv_done <= 0;
		end
	end

endmodule
