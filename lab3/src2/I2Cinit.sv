module I2Cinit (
    input i_clk,
    input i_start,
    input i_rst,
    output o_scl,
    output o_finished,
    inout io_sda
);

	localparam IDLE = 1;
	localparam SEND = 2;
	localparam DONE = 3;
    localparam I2C_PACKET_COUNT  = 10;

	parameter bit [23:0] CONFIG_DATA [9:0] = '{
	24'b0011010_0_000_0000_0_1001_0111, //Left Line In
	24'b0011010_0_000_0001_0_1001_0111, //Right Line In
	24'b0011010_0_000_0010_0_0111_1001, //Left Headphone out
	24'b0011010_0_000_0011_0_0111_1001, //Right Headphone out
	24'b0011010_0_000_0100_0_0001_0101, //Analog Audio Path Ctrl
	24'b0011010_0_000_0101_0_0000_0000, //Digital Audio Path Ctrl
	24'b0011010_0_000_0110_0_0000_0000, //Power Down Ctrl
	24'b0011010_0_000_0111_0_0100_0010, //Digital Audio Format
	24'b0011010_0_000_1000_0_0001_1001, //Sampling Ctrl
	24'b0011010_0_000_1001_0_0000_0001  //Active Ctrl
	};



	logic [1:0]  state_r, state_w;
	logic        send_start_r, send_start_w;
	logic        finished_r, finished_w;
	logic [23:0] data_r, data_w;
	logic [3:0]  count_r, count_w;
	logic        send_finished, send_scl;
	wire         send_sda;
	assign o_scl = send_scl;
	assign o_finished = finished_r;
	assign io_sda = send_sda;

	I2Csend I2Csend(
		.i_clk(i_clk),
		.i_start(send_start_r),
		.i_rst(i_rst),
		.i_data(data_r),
		.o_finished(send_finished),
		.o_scl(send_scl),
		.io_sda(send_sda)
	);
	
	always_comb begin
		state_w      = state_r;
		send_start_w = send_start_r;
		finished_w   = finished_r;
		data_w       = data_r;
		count_w      = count_r;
		case(state_r)
			IDLE:
			begin
				if (i_start) begin
					state_w = SEND;
					data_w = CONFIG_DATA[count_r];
					count_w = count_r + 1;
					send_start_w = 1'b1;
				end
			end
			SEND:
				begin
					if (count_r < I2C_PACKET_COUNT) begin
						if (send_finished) begin
							data_w = CONFIG_DATA[count_r];
							count_w = count_r + 1;
						end
					end
					if (count_r == I2C_PACKET_COUNT-1) begin
						state_w = DONE;
						finished_w = 1'b1;
						count_w = 0;
					end
				end
			DONE:
			begin
				finished_w = 1'b1;
			end
		endcase // state_r
	end




	always_ff @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			state_r     <= IDLE;
			count_r     <= 0;
			finished_r  <= 0;
			send_start_r <= 0;
			data_r      <= 0;
		end
		else begin
			state_r     <= state_w;
			count_r     <= count_w;
			finished_r  <= finished_w;
			send_start_r <= send_start_w;
			data_r      <= data_w;
		end
	end
endmodule // I2Cinit
