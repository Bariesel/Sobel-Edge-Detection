`timescale 1ns / 1ps
module controller(
	input logic clk,
	input logic reset_n,
	input logic start,                      //from the regfile
	input logic buffer_full,				//from the line_buffer
	input logic thr_done,					//from the threshold
	output logic enable_lb,
	output logic enable_conv,
	output logic done
);

	typedef enum logic [1:0] {
		IDLE,
		LOAD_LINE_BUFFER,
		PROCESSING,
		FINISH
	} state_t;

	state_t current_state, next_state;
   

	always_ff @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			current_state <= IDLE;
		end else begin
			current_state <= next_state;
		end
	end

	always_comb begin
		// Default signal values
		next_state = current_state;
		enable_lb = 1'b0;
		enable_conv = 1'b0;
		done = 1'b0;

		case (current_state)
			IDLE: begin
				if (start) begin
					next_state = LOAD_LINE_BUFFER;
				end
			end

			LOAD_LINE_BUFFER: begin
				enable_lb = 1'b1;
				if (buffer_full) begin
					next_state = PROCESSING;
				end
			end
			
			PROCESSING: begin
				enable_conv = 1'b1;
				if (thr_done) begin
					next_state = FINISH;
				end
			end
			
			FINISH: begin
				done = 1'b1;
				next_state = IDLE;
			end
		endcase
	end

endmodule

