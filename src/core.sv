`timescale 1ns / 1ps

module core (
	input wire clk,
	input wire reset_n, // Active-low reset
	input wire enable,  // Enable signal for processing
	input wire [7:0] pixel_in, // Input pixel data (grayscale, 8-bit)
	input wire valid_in,       // Input valid signal
	input wire [10:0] image_width,  // Image width
	input wire [10:0] image_height, // Image height
	input wire [7:0] threshold, // Edge detection threshold
	input wire [20:0] total_pixel,
	input wire [26:0] kernel1,
	input wire [26:0] kernel2,
	input wire [26:0] kernel3,
	input wire [26:0] kernel4,
	output wire [7:0] pixel_out,  // Output edge-detected pixel
	output wire valid_out,       // Output valid signal
	output wire sobel_done       // Indicates full sobel process completion
);

	// Internal signals
	wire buffer_full, conv_done, thr_done;
	wire valid_lb, valid_conv;
	wire enable_lb;
	wire [71:0] lb_output_data;
	wire [15:0] gradient_magnitude;


	// Line Buffer Instance (Stores pixel rows for convolution)
	line_buffer u_line_buffer (
		.clk(clk),
		.reset_n(reset_n),
		.data_in(pixel_in),
		.valid_in(valid_in),
		.enable_lb(enable_lb),
		.image_width(image_width),
		.image_height(image_height),
		.buffer_full(buffer_full),
		.valid_out(valid_lb),
		.output_data(lb_output_data)
	);

	// Sobel Convolution Calculation Instance
	conv_calc u_conv_calc (
		.clk(clk),
		.reset_n(reset_n),
		.enable_conv(enable_conv),
		.data(lb_output_data),
		.valid_in(valid_lb),
		.magnitude(gradient_magnitude),
		.kernel1(kernel1),
		.kernel2(kernel2),
		.kernel3(kernel3),
		.kernel4(kernel4),
		.conv_done(conv_done)
	);

	// Sobel Threshold Calculation Instance
	thr_calc u_thr_calc (
		.clk(clk),
		.reset_n(reset_n),
		.enable_thr(conv_done),
		.magnitude(gradient_magnitude),
		.image_width(image_width),
		.image_height(image_height),
		.threshold(threshold),
		.total_pixel(total_pixel),
		.pixel_out(pixel_out),
		.valid_out(valid_out),
		.thr_done(thr_done)
	);

	 // Controller Instance
	controller u_controller (
		.clk(clk),
		.reset_n(reset_n),
		.start(enable),
		.buffer_full(buffer_full),
		.thr_done(thr_done),
		.enable_lb(enable_lb),
		.enable_conv(enable_conv),
		.done(sobel_done)
	);

	// Overall process completion signal
	//assign sobel_done = thr_done;

endmodule
