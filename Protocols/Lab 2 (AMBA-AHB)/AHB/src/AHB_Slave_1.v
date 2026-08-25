
module AHB_Slave_1 #(
	parameter MEM_WIDTH = 8,
	parameter MEM_DEPTH = 1024
) (
	input HCLK,
	input HRESETn,

	input [31:0] HADDR,
	input [31:0] HWDATA,

	input [1:0] HSELx_slaves,

	input HWRITE,
	input [2:0] HSIZE,
	input [1:0] HTRANS,
	input [2:0] HBURST,
	input HREADY,

	output reg HREADYOUT,
	output reg HRESP,
	output reg [31:0] HRDATA
);

	reg [MEM_WIDTH-1:0] memory [MEM_DEPTH-1:0];

	reg [31:0] HADDR_reg;
	reg HWRITE_reg;
	reg [2:0] HSIZE_reg;
	reg [1:0] HTRANS_reg;
	reg [2:0] HBURST_reg;

	wire valid_transfer;

	assign valid_transfer =
		(HTRANS_reg == 2'b10) ||
		(HTRANS_reg == 2'b11);

	always @(posedge HCLK or negedge HRESETn) begin
		if (!HRESETn) begin

			HREADYOUT <= 1'b1;
			HRESP <= 1'b0;
			HRDATA <= 32'h00000000;

			HADDR_reg <= 32'h00000000;
			HWRITE_reg <= 1'b0;
			HSIZE_reg <= 3'b000;
			HTRANS_reg <= 2'b00;
			HBURST_reg <= 3'b000;

		end
		else begin

			HREADYOUT <= 1'b1;
			HRESP <= 1'b0;

			if (HREADY) begin

				if (HSELx_slaves == 2'b00 &&
					valid_transfer) begin

					if (HWRITE_reg) begin

						case (HSIZE_reg)

							3'b000: begin
								memory[HADDR_reg[9:0]] <= HWDATA[7:0];
							end

							3'b001: begin
								memory[HADDR_reg[9:0]] <= HWDATA[7:0];
								memory[HADDR_reg[9:0] + 10'd1] <= HWDATA[15:8];
							end

							3'b010: begin
								memory[HADDR_reg[9:0]] <= HWDATA[7:0];
								memory[HADDR_reg[9:0] + 10'd1] <= HWDATA[15:8];
								memory[HADDR_reg[9:0] + 10'd2] <= HWDATA[23:16];
								memory[HADDR_reg[9:0] + 10'd3] <= HWDATA[31:24];
							end

							default: begin
								HRESP <= 1'b1;
							end

						endcase

					end
					else begin

						case (HSIZE_reg)

							3'b000: begin

								HRDATA <= {
									24'h000000,
									memory[HADDR_reg[9:0]]
								};

							end

							3'b001: begin

								HRDATA <= {
									16'h0000,
									memory[HADDR_reg[9:0] + 10'd1],
									memory[HADDR_reg[9:0]]
								};

							end

							3'b010: begin

								HRDATA <= {
									memory[HADDR_reg[9:0] + 10'd3],
									memory[HADDR_reg[9:0] + 10'd2],
									memory[HADDR_reg[9:0] + 10'd1],
									memory[HADDR_reg[9:0]]
								};

							end

							default: begin
								HRDATA <= 32'h00000000;
								HRESP <= 1'b1;
							end

						endcase

					end

				end

				HADDR_reg <= HADDR;
				HWRITE_reg <= HWRITE;
				HSIZE_reg <= HSIZE;
				HTRANS_reg <= HTRANS;
				HBURST_reg <= HBURST;

			end

		end
	end

endmodule


























// we chose AHB slave 1 to be a memory slave 
module old_AHB_Slave_1 #(
    parameter MEM_WIDTH = 8 , parameter MEM_DEPTH = 1024 // I chose 128 bits for the width as 128 = 32*4 to enable transfers of 8 bits size 
) (
    // Global Signals
    input HCLK,
    input HRESETn,
    // input from master
    input [31:0] HADDR,
    input [31:0] HWDATA,
    // input from decoder
    input [1:0] HSELx_slaves,
    // control signals
    input HWRITE,
    input [2:0] HSIZE,
    input [1:0] HTRANS,
    input [2:0] HBURST,
    input HREADY,
    // output to MUX
    output reg HREADYOUT,
    output reg HRESP,
    output reg [31:0] HRDATA // Read data to master
);
    // we made this salve as a memory to test read and write operations
    reg [MEM_WIDTH-1:0] memory [MEM_DEPTH-1:0]; // Memory array

    // internal signlas
    reg [31:0] HADDR_Half; // address that incerements the HADDR by 1 to write 16 bits
    reg [31:0] HADDR_Full_1; // address that incerements the HADDR by 1 to write 32 bits
    reg [31:0] HADDR_Full_2; // address that incerements the HADDR by 2 to write 32 bits
    reg [31:0] HADDR_Full_3; // address that incerements the HADDR by 3 to write 32 bits


    // storing all control signals to use them in write states as control signals are sent first then data (address phase & data phase)
    reg [31:0] HADDR_reg; // to store the address value to use it in write states as control signals are sent first then data (address phase & data phase)
    reg HWRITE_reg; // to store write control signal value to use it in write states as control signals are sent first then data (address phase & data phase)
    reg [2:0] HSIZE_reg; // to store the size of the transfer to use it in write states as control signals are sent first then data (address phase & data phase)
    reg [1:0] HTRANS_reg; // to store the type of transfer to use it in write states as control signals are sent first then data (address phase & data phase)
    reg [2:0] HBURST_reg; // to store the burst type to use it in write states as control signals are sent first then data (address phase & data phase)



always @(posedge HCLK or negedge HRESETn) begin
	if (!HRESETn) begin
//		HREADYOUT <= 1'b1; // Initially ready
//		HRESP <= 1'b0; // No error response
		HRDATA <= 32'h00000000; // Default read data
//
//		HADDR_reg <= 32'h00000000;
//		HWRITE_reg <= 1'b0;
//		HSIZE_reg <= 3'b000;
//		HTRANS_reg <= 2'b00;
//		HBURST_reg <= 3'b000;
	end
//	else if (HREADY) begin 
//            HADDR_reg <= HADDR; // so if not ready the value of the prev. address will be stored in HADDR_reg (wait states)
//            HWRITE_reg <= HWRITE;
//            HSIZE_reg <= HSIZE;
//            HBURST_reg <= HBURST;
//            HTRANS_reg <= HTRANS;
//        end


//always @(posedge HCLK) begin
	// choose salve 1
	//else if (!HSELx_slaves && HREADY) begin // select Slave 1 if HSELx is 2'b00
	if (!HSELx_slaves && HREADY) begin

            // Write operation for both single and incermental burst transfers (HBURST = 0 or HBURST = 1)
            if (HWRITE_reg && (HTRANS_reg == 2'b10 || HTRANS_reg == 2'b11)) begin // as the state is NONSEQ or SEQ we can write
                // 8 bits transfer 
                if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b000) begin 
                    memory[HADDR_reg[29:0]] <= HWDATA[7:0]; // Write 8 bits to memory
                end 
                // 16 bits transfer 
                else if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b001) begin // 16 bits transfer
                    memory[HADDR_reg[29:0]] <= HWDATA[7:0]; // Write 8 bits to memory
                    memory[HADDR_Half] <= HWDATA[15:8]; // Write next 8 bits to memory
                end 
                // 32 bits transfer 
                else if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b010) begin // 32 bits transfer
                    memory[HADDR_reg[29:0]] <= HWDATA[7:0]; // Write first 8 bits to memory
                    memory[HADDR_Full_1] <= HWDATA[15:8]; // Write next 8 bits to memory
                    memory[HADDR_Full_2] <= HWDATA[23:16]; // Write next 8 bits to memory
                    memory[HADDR_Full_3] <= HWDATA[31:24]; // Write last 8 bits to memory
                end
            end
            // Read operation for both single and incermental burst transfers (HBURST = 0 or HBURST = 1) 
            //else if (!HWRITE && (HTRANS == 2'b10 || HTRANS == 2'b11)) begin // as the state is NONSEQ or SEQ we can read
	    else if (!HWRITE_reg && (HTRANS_reg == 2'b10 || HTRANS_reg == 2'b11)) begin
                // 8 bits transfer 
                //if ((HBURST == 3'b000 || HBURST == 3'b001) && HSIZE == 3'b000) begin 
                    //HRDATA <= {24'h000000, memory[HADDR[29:0]]}; // Read 8 bits from memory
		if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b000) begin
			HRDATA <= {24'h000000, memory[HADDR_reg[9:0]]};
                end 
                // 16 bits transfer 
                //else if ((HBURST == 3'b000 || HBURST == 3'b001) && HSIZE == 3'b001) begin // 16 bits transfer
                    //HRDATA <= {16'h0000, memory[HADDR_Half], memory[HADDR[29:0]]}; // Read 16 bits from memory
		else if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b001) begin
			HRDATA <= {16'h0000, memory[HADDR_Half[9:0]], memory[HADDR_reg[9:0]]};
                end 
                // 32 bits transfer 
                //else if ((HBURST == 3'b000 || HBURST == 3'b001) && HSIZE == 3'b010)  begin // 32 bits transfer
                    //HRDATA <= {memory[HADDR_Full_3], memory[HADDR_Full_2], memory[HADDR_Full_1], memory[HADDR[29:0]]}; // Read 32 bits from memory
		else if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001) && HSIZE_reg == 3'b010) begin
			HRDATA <= {
				memory[HADDR_Full_3[9:0]],
				memory[HADDR_Full_2[9:0]],
				memory[HADDR_Full_1[9:0]],
				memory[HADDR_reg[9:0]]
			};
                end
            end
        end
end



//// always block for address to respect address phase and data phase and to enable pipelining in the address
//always @(posedge HCLK) begin
always @(posedge HCLK or negedge HRESETn) begin
	if (!HRESETn) begin
		HREADYOUT <= 1'b1; // Initially ready
		HRESP <= 1'b0; // No error response
		HRDATA <= 32'h00000000; // Default read data

		HADDR_reg <= 32'h00000000;
		HWRITE_reg <= 1'b0;
		HSIZE_reg <= 3'b000;
		HTRANS_reg <= 2'b00;
		HBURST_reg <= 3'b000;
	end
	if (HREADY) begin 
		HADDR_reg <= HADDR; // so if not ready the value of the prev. address will be stored in HADDR_reg (wait states)
		HWRITE_reg <= HWRITE;
		HSIZE_reg <= HSIZE;
		HBURST_reg <= HBURST;
		HTRANS_reg <= HTRANS;
	end
end



// always block for address managing to respect wait states
always @(*) begin
	if (HREADY) begin
		// write transfer
		if (HWRITE) begin
			HADDR_Half = HADDR_reg[29:0] + 1; // Half address for 16 bits transfer, incerement by 1 
			HADDR_Full_1 =  HADDR_reg[29:0] + 1; // Full address for 32 bits transfer, incerement by 1
			HADDR_Full_2 =  HADDR_reg[29:0] + 2;  // Full address for 32 bits transfer incerement by 2
			HADDR_Full_3 =  HADDR_reg[29:0] + 3; // Full address for 32 bits transfer, incerement by 3
		end
		// read transfer
		else begin
                	HADDR_Half = HADDR[29:0] + 1; // Half address for 16 bits transfer, incerement by 1 
                	HADDR_Full_1 =  HADDR[29:0] + 1; // Full address for 32 bits transfer, incerement by 1
                	HADDR_Full_2 =  HADDR[29:0] + 2;  // Full address for 32 bits transfer incerement by 2
			HADDR_Full_3 =  HADDR[29:0] + 3; // Full address for 32 bits transfer, incerement by 3
		end
	end
end

endmodule
