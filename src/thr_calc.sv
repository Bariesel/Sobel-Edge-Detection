`timescale 1ns / 1ps

module thr_calc (
	input wire clk,
	input wire reset_n,
	input wire enable_thr,           // Enable signal for threshold calculator
	input wire [15:0] magnitude,    
	input logic [10:0] image_width,			
	input logic [10:0] image_height,		
	input wire [7:0] threshold,      // Threshold value
	input wire [20:0] total_pixel,
	output reg [7:0] pixel_out,      // Edge result (from 0 to 255)
	output reg valid_out,            // Indicates valid output
	output reg thr_done              // Indicates threshold calculation is complete
);

	reg [20:0] counter_out_pixel;



	
	
	//always @(*) thr_done = (counter_out_pixel == total_pixels) ? 1 : 0;

	// Threshold comparison and output
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			pixel_out <= 0;
			valid_out <= 0;
			thr_done <= 0;
			counter_out_pixel <= 0;
		end else if (enable_thr) begin
			if(magnitude >= threshold) begin
					pixel_out <= (magnitude > 255) ? 8'd255 : magnitude[7:0]; // Clamp max at 255
					valid_out <= 1;
			end else begin
					pixel_out <= 0; // No edge detected
					valid_out <= 1;
			end
				/*
			if (counter_out_pixel == total_pixels-1) begin
				counter_out_pixel <= 0;
				thr_done <= 1;
			end else begin
			*/
			counter_out_pixel <= counter_out_pixel + 1;
			
			
		end else begin
			valid_out <= 0; // Reset valid output
			pixel_out <= 0;
			
			if (counter_out_pixel == total_pixel && total_pixel) begin
				counter_out_pixel <= 0;
				thr_done <= 1;
			end 
		end
	end

endmodule

