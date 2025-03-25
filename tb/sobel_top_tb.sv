
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

/*
	// Define a 3x3 matrix with alternating 1 and -1 pattern (3-bit signed)
	localparam signed [2:0] K1_0 =  1, K1_1 = -1, K1_2 =  1;
	localparam signed [2:0] K1_3 = -1, K1_4 =  1, K1_5 = -1;
	localparam signed [2:0] K1_6 =  1, K1_7 = -1, K1_8 =  1;

	localparam signed [26:0] KERNEL1 = {
		K1_0, K1_1, K1_2,
		K1_3, K1_4, K1_5,
		K1_6, K1_7, K1_8
	};
	*/
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

	// 10x10 Test Image (from the provided image)
	reg [7:0] test_image [0:99];  // 10x10 = 100 pixels

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

		// Load Test Image into Memory (1 to 100)
		for (i = 0; i < 100; i++) begin
			test_image[i] = i + 1;
		end

		// -------------------- APB Configuration Writes --------------------
		// Write Threshold (Address 0x00) = 110
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h00; PWDATA = 8'd110;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;
		// Write Image Width (Address 0x04) = 512
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h04; PWDATA = 32'd573;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Image Height (Address 0x08) = 512
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h08; PWDATA = 32'd568;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Total Pixels (Address 0x0C) = 262144 (512x512)
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h0C; PWDATA = 32'd325464;
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Kernel1 (Address 0x10) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h10; PWDATA = 27'sd0; // Example Kernel1
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;
		
		// Write Kernel2 (Address 0x14) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h14; PWDATA = 27'sd0; // Example Kernel2
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;
		
		// Write Kernel3 (Address 0x18) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h18; PWDATA = 27'sd0; // Example Kernel3
		@(posedge clk);
		PENABLE = 1;
		@(posedge clk);
		PSEL = 0; PENABLE = 0;

		// Write Kernel4 (Address 0x1C) 
		@(posedge clk);
		PSEL = 1; PWRITE = 1; PADDR = 32'h1C; PWDATA = 27'sd0; // Example Kernel4
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
		// First pixel: Wait one extra clock cycle
		//@(posedge clk);
		//@(posedge clk);
		//pixel_in = test_image[0];  
		//valid_in = 1'b1;  
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

	// Print Edge Output Every Cycle
	always @(posedge clk) begin
		if (valid_out) begin
			$display("Pixel[%0d] = %d", j, pixel_out);  // Optional: also print to console
			$fdisplay(output_file, "%0d", pixel_out);  // Save to file
			j++;
		end
	end


endmodule


