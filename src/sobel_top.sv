`timescale 1ns / 1ps

module sobel_top (
	input logic clk,
	input logic reset_n,
	
	// APB Interface
	input logic PSEL,
	input logic PENABLE,
	input logic PWRITE,
	input logic [31:0] PADDR,
	input logic [31:0] PWDATA,
	output logic [31:0] PRDATA,
	output logic PREADY,
	output logic PSLVERR,
	
	// Pixel Data Input
	input logic [7:0] pixel_in,
	input logic valid_in,
	
	// Output Edge Detection Data
	output logic [7:0] pixel_out,
	output logic valid_out,
	output logic sobel_done
);

	// Internal Signals
	logic [7:0] threshold;
	logic [10:0] img_width, img_height;
	logic [20:0] total_pixel;
	logic [26:0] kernel1, kernel2, kernel3, kernel4;
	logic start;


	// APB Slave (Register File) Instance
	 regfile u_regfile(
		.clk(clk),
		.reset_n(reset_n),
		.PSEL(PSEL),
		.PENABLE(PENABLE),
		.PWRITE(PWRITE),
		.PADDR(PADDR),
		.PWDATA(PWDATA),
		.PRDATA(PRDATA),
		.PREADY(PREADY),
		.PSLVERR(PSLVERR),
		.threshold(threshold),
		.img_width(img_width),
		.img_height(img_height),
		.total_pixel(total_pixel),
		.kernel1(kernel1),
		.kernel2(kernel2),
		.kernel3(kernel3),
		.kernel4(kernel4),
		.start(start)
	);

	// Sobel Processing Core Instance
	core u_core (
		.clk(clk),
		.reset_n(reset_n),
		.enable(start),
		.pixel_in(pixel_in),
		.valid_in(valid_in),
		.image_width(img_width),
		.image_height(img_height),
		.threshold(threshold),
		.total_pixel(total_pixel),
		.kernel1(kernel1),
		.kernel2(kernel2),
		.kernel3(kernel3),
		.kernel4(kernel4),
		.pixel_out(pixel_out),
		.valid_out(valid_out),
		.sobel_done(sobel_done)
	);

endmodule
