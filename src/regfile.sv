
`timescale 1ns / 1ps

module regfile(
	input logic clk,             // APB Clock signal
	input logic reset_n,         // Active-low reset signal
	input logic PSEL,            // Slave select signal from APB master
	input logic PENABLE,         // Enable signal for APB transaction
	input logic PWRITE,          // Write enable signal (1 = Write, 0 = Read)
	input logic [31:0] PADDR,    // Address bus for register selection
	input logic [31:0] PWDATA,   // Data bus for write operations
	output logic [31:0] PRDATA,  // Data bus for read operations
	output logic PREADY,         // Ready signal indicating transaction completion
	output logic PSLVERR,        // Error signal indicating invalid access
	output logic [7:0] threshold,  // Threshold register for Sobel processing
	output logic [10:0] img_width, // Image width register
	output logic [10:0] img_height,// Image height register
	output logic [20:0] total_pixel, // Total number of pixels (width \ufffd\ufffd\ufffd\ufffd height)
	output logic signed [26:0] kernel1, // Sobel Kernel 1
	output logic signed [26:0] kernel2, // Sobel Kernel 2
	output logic signed [26:0] kernel3, // Sobel Kernel 3
	output logic signed [26:0] kernel4,  // Sobel Kernel 4
	output logic start          // Start signal for processing  
);

	// Internal register to clear the start signal after one cycle
	logic start_internal;

	// APB Register Write & Read Logic
	always_ff @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			threshold  <= 8'd0; 
			img_width  <= 11'd0;  
			img_height <= 11'd0;  
			total_pixel <= 21'd0;
			kernel1    <= 27'd0;
			kernel2    <= 27'd0;
			kernel3    <= 27'd0;
			kernel4    <= 27'd0;
			start      <= 1'b0;
			start_internal <= 1'b0;
			PREADY     <= 1'b0;
			PSLVERR    <= 1'b0;
			PRDATA     <= 32'd0;
		end else begin
			PREADY  <= 1'b0;  // Reset after one cycle
			PSLVERR <= 1'b0;  // Reset error flag

			if (PSEL && PENABLE) begin
				PREADY <= 1'b1;  // Signal completion
				if (PWRITE) begin
					// Write Operation
					case (PADDR)
						32'h00: threshold  <= PWDATA[7:0];      // Configure threshold
						32'h04: img_width  <= PWDATA[10:0];     // Configure image width
						32'h08: img_height <= PWDATA[10:0];     // Configure image height
						32'h0C: total_pixel <= PWDATA[20:0];    // Set total pixel count
						32'h10: kernel1  <= PWDATA[26:0];       // Configure Kernel 1
						32'h14: kernel2  <= PWDATA[26:0];       // Configure Kernel 2
						32'h18: kernel3  <= PWDATA[26:0];       // Configure Kernel 3
						32'h1C: kernel4  <= PWDATA[26:0];       // Configure Kernel 4
						32'h20: start_internal <= PWDATA[0];    // Set start signal
						default: PSLVERR <= 1'b1;               // Invalid address access
					endcase
				end else begin
					// Read Operation
					case (PADDR)
						32'h00: PRDATA <= {24'd0, threshold};   // Read threshold
						32'h04: PRDATA <= {21'd0, img_width};   // Read image width
						32'h08: PRDATA <= {21'd0, img_height};  // Read image height
						32'h0C: PRDATA <= {14'd0, total_pixel}; // Read total pixels
						32'h10: PRDATA <= {5'd0, kernel1};      // Read Kernel 1
						32'h14: PRDATA <= {5'd0, kernel2};      // Read Kernel 2
						32'h18: PRDATA <= {5'd0, kernel3};      // Read Kernel 3
						32'h1C: PRDATA <= {5'd0, kernel4};      // Read Kernel 4
						32'h20: PRDATA <= {31'd0, start};       // Read start signal
						default: begin
							PRDATA  <= 32'hDEADBEEF;  // Invalid address response
							PSLVERR <= 1'b1;          // Set error flag for invalid read
						end
					endcase
				end
			end

			// Clear start signal after one cycle
			if (start_internal) begin
				start <= 1'b1;
				start_internal <= 1'b0;
			end else begin
				start <= 1'b0;
			end
		end
	end

endmodule

