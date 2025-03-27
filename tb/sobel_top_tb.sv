
`timescale 1ns / 1ps

module sobel_top_tb;

	// Clock and Reset
	reg clk;
	reg reset_n;

	// APB Signals
	reg PSEL, PENABLE, PWRITE;
	reg [31:0] PADDR, PWDATA;
	wire [31:0] PRDATA;
	wire PREADY, PSLVERR;

	integer pixel_file, status;
	reg [7:0] pixel_data;
	// Pixel Data Input
	reg [7:0] pixel_in;
	reg valid_in;

	// Output Edge Detection Data
	wire [7:0] pixel_out;
	wire valid_out;
	wire sobel_done;
	integer output_file;

	integer j=0;

	// Instantiate the Sobel Top Module
	sobel_top dut (
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
		.pixel_in(pixel_in),
		.valid_in(valid_in),
		.pixel_out(pixel_out),
		.valid_out(valid_out),
		.sobel_done(sobel_done)
	);

	// Clock Generation (10ns period => 100 MHz)
	always #5 clk = ~clk;

	

	// Initialize Testbench
	initial begin
		integer i;
		
		// Initialize clock and reset
		clk = 0;
		reset_n = 0;
		PSEL = 0;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = 0;
		PWDATA = 0;
		pixel_in = 0;
		valid_in = 0;

		// Reset sequence
		#20 reset_n = 1;

		
		// -------------------- APB Configuration Writes --------------------
		// Read Configuration Parameters from config.txt
		integer config_file;
		integer threshold, width, height, total_pixels;
		integer kernel1, kernel2, kernel3, kernel4;
	
		config_file = $fopen("config.txt", "r");
		if (config_file == 0) begin
			$display("ERROR: Cannot open config.txt");
			$finish;
		end
	
		// Read 8 values from the file
		$fscanf(config_file, "%d\n", threshold);
		$fscanf(config_file, "%d\n", width);
		$fscanf(config_file, "%d\n", height);
		$fscanf(config_file, "%d\n", total_pixels);
		$fscanf(config_file, "%d\n", kernel1);
		$fscanf(config_file, "%d\n", kernel2);
		$fscanf(config_file, "%d\n", kernel3);
		$fscanf(config_file, "%d\n", kernel4);
		$fclose(config_file);
	


		
		// Write Threshold (Address 0x00)
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h00; PWDATA = threshold;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;
		// Write Image Width  (Address 0x04)
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h04; PWDATA = width;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Image Height (Address 0x08) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h08; PWDATA = height;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Total Pixels (Address 0x0C) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h0C; PWDATA = total_pixels;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Kernel1 (Address 0x10) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h10; PWDATA = kernel1;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;
		
		// Write Kernel2 (Address 0x14) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h14; PWDATA = kernel2;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;
		
		// Write Kernel3 (Address 0x18) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h18; PWDATA = kernel3;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Kernel4 (Address 0x1C) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h1C; PWDATA = kernel4;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Start Processing (Address 0x20) = 1
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h20; PWDATA = 1'b1;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// -------------------- Send Pixel Data --------------------
		
		@(posedge clk);  // Extra delay before sending the next pixel

		pixel_file = $fopen("pixel_data.txt", "r");
		if (pixel_file == 0) begin
			$display("ERROR: Cannot open pixel_data.txt");
			$finish;
		end
		output_file = $fopen("edge_output.txt", "w");
		if (output_file == 0) begin
			$display("ERROR: Cannot open edge_output.txt");
			$finish;
		end


		while (!$feof(pixel_file)) begin
			status = $fscanf(pixel_file, "%d\n", pixel_data);
			@(posedge clk);
			pixel_in = pixel_data;
			valid_in = 1'b1;
		end

		@(posedge clk);
		valid_in = 1'b0;
		$fclose(pixel_file);

		wait (sobel_done);
		
		#100;
		$fclose(output_file);
		$stop;
	end
/*
	// Print Edge Output Every Cycle
	always @(posedge clk) begin
		if (valid_out) begin
			$display("Pixel[%0d] = %d", j, pixel_out);  // Optional: also print to console
			$fdisplay(output_file, "%0d", pixel_out);  // Save to file
			j++;
		end
	end
 */


endmodule


