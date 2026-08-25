module AHB_Lite_Master (
    // Global Signals
    input HCLK,
    input HRESETn,
    // Processor signals (we will act as the Processor in the testbench)
    input [31:0] PADDR,
    input [31:0] PWDATA,
    input PWRITE,
    input [2:0] PSIZE,
    input [1:0] PTRANS,
    input [2:0] PBURST,
    // Transfer response (from mux)
    input HREADY,  // to indicate the completeness of the transfer
    input HRESP,
    // Data
    input [31:0] HRDATA,  // from slave
    // outputs
    output reg [31:0] HADDR, // note that the Most significant two bits are used to select which slave we will access
    output reg [31:0] HWDATA,
    output reg HWRITE,
    output reg [2:0] HSIZE,
    output reg [1:0] HTRANS,
    output reg [2:0] HBURST,
    output reg PDONE  // just a flag to indicate the transfer is done
);
  // next state logic, cuurent state
  //reg [1:0] cs, ns;

  parameter IDLE = 2'b00;
  parameter BUSY = 2'b01;
  parameter NONSEQ = 2'b10;
  parameter SEQ = 2'b11;

  reg [31:0] HWDATA_reg;  // to store the value of HWDATA_reg in case of wait state transfers

  reg [1:0] cs;
  reg [1:0] ns;

  // state memory
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) cs <= IDLE;
    else cs <= ns;
  end

  // next state logic
  always @(*) begin
    case (cs)
      IDLE: begin
        if (PTRANS == 2'b10)  // Non-sequential transfer
          ns = NONSEQ;  // start new transfer
        else ns = IDLE;
      end
      BUSY: begin
        if (PTRANS == 2'b11) ns = SEQ;  // Go to SEQ state if transfer is sequential
        else if (PTRANS == 2'b10) ns = NONSEQ;  // Non-sequential transfer
        else if (PTRANS == 2'b00) ns = IDLE;  // go to IDLE if no transfer
        else ns = BUSY;  // Stay in BUSY state
      end
      NONSEQ: begin
        if (PTRANS == 2'b11) ns = SEQ;  // Sequential transfer
        else if (PTRANS == 2'b00) ns = IDLE;  // go to IDLE if no transfer (single transfer)
        else if (PTRANS == 2'b10 && PBURST == 3'b000) // to enable multiple Non-sequential transfer with single burst every cycle
          ns = NONSEQ;  // Stay in NONSEQ state
        else ns = SEQ;  // Go to SEQ state
      end
      SEQ: begin
        if (PTRANS == 2'b00) ns = IDLE;  // go to IDLE if no transfer
        else if (PTRANS == 2'b10) ns = NONSEQ;  // Non-sequential transfer (start new transfer)
        else ns = SEQ;  // Stay in SEQ state
      end
      default: ns = IDLE;
    endcase
  end


// output logic
//always @(posedge HCLK or negedge HRESETn) begin
//	if (!HRESETn) begin
//		HADDR <= 32'd0;
//		HWDATA <= 32'd0;
//		HWDATA_reg <= 32'd0;
//		HWRITE <= 1'b0;
//		HSIZE <= 3'b000;  // 8-bit transfer
//		HTRANS <= 2'b00;  // IDLE state
//		HBURST <= 3'b000;  // Single transfer
//		PDONE <= 1'b0;
//	end else begin
//
//		PDONE <= 1'b0;
//
//		if (cs == IDLE) begin
//			HADDR <= 32'd0;
//			HWDATA_reg <= 32'd0;
//			//HWDATA <= 32'd0;
//			HWRITE <= 1'b0;
//			HSIZE <= 3'b000;
//			HTRANS <= 2'b00;
//		end 
//		else if (cs == BUSY) begin
//			HADDR <= PADDR;
//			HWDATA_reg <= PWDATA;
//			//HWDATA <= PWDATA;
//			HWRITE <= PWRITE;
//			HSIZE <= PSIZE;
//			HTRANS <= PTRANS;
//			HBURST <= PBURST;
//		end 
//		else if (cs == NONSEQ) begin
//			HADDR <= PADDR;
//			HWDATA_reg <= PWDATA;
//			//HWDATA <= PWDATA;
//			HWRITE <= PWRITE;
//			HSIZE <= PSIZE;
//			HTRANS <= PTRANS;
//			HBURST <= PBURST;
//		end 
//		else if (cs == SEQ) begin
//			if (PBURST == 3'b001 && !PSIZE) begin // INCREMENTAL burst, size is 8 bits so we will incerement address by 1
//				HADDR <= HADDR + 1;
//				HWDATA_reg <= {24'h000000, PWDATA[7:0]};
//				//HWDATA <= {24'h000000, PWDATA[7:0]};
//				HWRITE <= PWRITE;
//				HSIZE <= PSIZE;
//				HTRANS <= PTRANS;
//				HBURST <= PBURST;
//			end
//			else if (PBURST == 3'b001 && PSIZE == 3'b001) begin // INCREMENTAL burst, size is 16 bits so we will incerement address by 2
//				HADDR <= HADDR + 2;
//				HWDATA_reg <= {16'h0000, PWDATA[15:0]};
//				//HWDATA <= {16'h0000, PWDATA[15:0]};
//				HWRITE <= PWRITE;
//				HSIZE <= PSIZE;
//				HTRANS <= PTRANS;
//				HBURST <= PBURST;
//			end
//			else if (PBURST == 3'b001 && PSIZE == 3'b010) begin // INCREMENTAL burst, size is 32 bits so we will incerement address by 4
//				HADDR <= HADDR + 4;
//				HWDATA_reg <= PWDATA;
//				//HWDATA <= PWDATA;
//				HWRITE <= PWRITE;
//				HSIZE <= PSIZE;
//				HTRANS <= PTRANS;
//				HBURST <= PBURST;
//			end 
//			else if (!PBURST) begin  // SINGLE transfer
//				HADDR <= PADDR;
//				HWDATA_reg <= PWDATA;
//				//HWDATA <= PWDATA;
//				HWRITE <= PWRITE;
//				HSIZE <= PSIZE;
//				HTRANS <= PTRANS;
//				HBURST <= PBURST;
//			end
//		end
//	end
//end



always @(posedge HCLK or negedge HRESETn) begin
	if (!HRESETn) begin
		HADDR <= 32'h00000000;
		HWDATA <= 32'h00000000;
		HWDATA_reg <= 32'h00000000;
		HWRITE <= 1'b0;
		HSIZE <= 3'b000;
		HTRANS <= 2'b00;
		HBURST <= 3'b000;
		PDONE <= 1'b0;
	end
	else begin

		PDONE <= 1'b0;

		if (cs == IDLE) begin
			if (PTRANS == 2'b10) begin
				HADDR <= PADDR;
				HWDATA_reg <= PWDATA;
				HWRITE <= PWRITE;
				HSIZE <= PSIZE;
				HTRANS <= PTRANS;
				HBURST <= PBURST;
			end
			else begin
				HADDR <= 32'h00000000;
				HWRITE <= 1'b0;
				HSIZE <= 3'b000;
				HTRANS <= 2'b00;
				HBURST <= 3'b000;
			end
		end

		else if (cs == NONSEQ || cs == SEQ) begin

			if (HREADY) begin

				if (PTRANS == 2'b00) begin
					PDONE <= 1'b1;

					HTRANS <= 2'b00;
					HWRITE <= 1'b0;
				end
				else begin
					HADDR <= PADDR;
					HWDATA_reg <= PWDATA;
					HWRITE <= PWRITE;
					HSIZE <= PSIZE;
					HTRANS <= PTRANS;
					HBURST <= PBURST;
				end

			end

		end

	end
end


// special always block to respect the data phase as data should come after address phase by on clock
//always @(posedge HCLK) begin
//	if (HREADY) HWDATA <= HWDATA_reg;
//end
always @(posedge HCLK or negedge HRESETn) begin
	if (!HRESETn)	HWDATA <= 32'h00000000;
	else if (HREADY)	HWDATA <= HWDATA_reg;
end


// special always block for flag done
//always @(*) begin
//	//if ((cs == NONSEQ || cs == SEQ) && ns == IDLE) begin
//	if ((cs == NONSEQ || cs == SEQ) && ns == IDLE && HREADY) begin
//		PDONE = 1'b1;  // transfer is done
//	end else begin
//		PDONE = 1'b0;  // transfer is not done
//	end
//end


endmodule
