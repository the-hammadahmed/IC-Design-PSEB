`include "AHB_TOP.v"

module tb_AHB_TOP ();
reg HCLK;
reg HRESETn;
reg [31:0] PADDR;
reg [31:0] PWDATA;
reg PWRITE;
reg [2:0] PSIZE;
reg [1:0] PTRANS;
reg [2:0] PBURST;
wire [31:0] HRDATA;

wire HREADY;
wire HRESP;
wire PDONE;

integer errors;

AHB_TOP dut (
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.PADDR(PADDR),
 	.PWDATA(PWDATA),
	.PWRITE(PWRITE),
	.PSIZE(PSIZE),
	.PTRANS(PTRANS),
	.PBURST(PBURST),
	.HRDATA(HRDATA),
	.HREADY(HREADY),
	.HRESP(HRESP),
	.PDONE(PDONE)
);



//RESET
task reset_dut;
begin
	HRESETn = 1'b0;

	PADDR  = 32'h00000000;
	PWDATA = 32'h00000000;
	PWRITE = 1'b0;
	PSIZE  = 3'b000;
	PTRANS = 2'b00;
	PBURST = 3'b000;
	#10;
	HRESETn = 1'b1;
end
endtask




task single_write;
	input [31:0] addr;
	input [31:0] data;
	integer timeout;
	begin
		@(negedge HCLK);
		PADDR = addr;
		PWDATA = data;
		PWRITE = 1'b1;
		PSIZE = 3'b010;
		PTRANS = 2'b10;
		PBURST = 3'b000;

		@(negedge HCLK);
		PTRANS = 2'b00;
		timeout = 0;

		while (PDONE !== 1'b1 && timeout < 20) begin
			@(posedge HCLK);
			timeout = timeout + 1;
		end

		if (timeout == 20) begin
			$display("ERROR: WRITE TIMEOUT");
			errors = errors + 1;
		end
		else begin
			$display("WRITE DONE");
		end

		@(negedge HCLK);
		PWRITE = 1'b0;
		PADDR = 32'h00000000;
		PWDATA = 32'h00000000;
	end
endtask




task single_read;
	input [31:0] addr;
	input [31:0] expected_data;
	integer timeout;
	begin
		@(negedge HCLK);
		PADDR = addr;
		PWDATA = 32'h00000000;
		PWRITE = 1'b0;
		PSIZE = 3'b010;
		PTRANS = 2'b10;
		PBURST = 3'b000;

		@(negedge HCLK);
		PTRANS = 2'b00;
		timeout = 0;

		while (PDONE !== 1'b1 && timeout < 20) begin
			@(posedge HCLK);
			timeout = timeout + 1;
		end
		#1;

		if (timeout == 20) begin
			$display("ERROR: READ TIMEOUT");
			errors = errors + 1;
		end
		else if (HRDATA === expected_data) begin
			$display("PASS: READ");
			$display("Address  = %h", addr);
			$display("Expected = %h", expected_data);
			$display("Actual   = %h", HRDATA);
		end
		else begin
			$display("FAIL: READ");
			$display("Address  = %h", addr);
			$display("Expected = %h", expected_data);
			$display("Actual   = %h", HRDATA);
			errors = errors + 1;
		end

		@(negedge HCLK);
		PADDR = 32'h00000000;
	end
endtask



task burst_write_incr4;
	input [31:0] start_addr;
	input [31:0] data0;
	input [31:0] data1;
	input [31:0] data2;
	input [31:0] data3;
begin
	@(negedge HCLK);
	PADDR = start_addr;
	PWDATA = data0;
	PWRITE = 1'b1;
	PSIZE = 3'b010;
	PTRANS = 2'b10;
	PBURST = 3'b011;

	@(negedge HCLK);
	PADDR = start_addr + 32'd4;
	PWDATA = data1;
	PTRANS = 2'b11;

	@(negedge HCLK);
	PADDR = start_addr + 32'd8;
	PWDATA = data2;
	PTRANS = 2'b11;

	@(negedge HCLK);
	PADDR = start_addr + 32'd12;
	PWDATA = data3;
	PTRANS = 2'b11;

	@(negedge HCLK);
	PTRANS = 2'b00;
	PWRITE = 1'b0;
	repeat (2)@(posedge HCLK);

	end
endtask



task check_invalid_address;
	input [31:0] addr;
begin
	@(negedge HCLK);
	PADDR = addr;
	PWDATA = 32'h00000000;
	PWRITE = 1'b0;
	PSIZE = 3'b010;
	PTRANS = 2'b10;
	PBURST = 3'b000;

	@(posedge HCLK);
	#1;
	if (HRESP == 1'b1) begin
		$display("PASS: Invalid address correctly generated error response");
	end
	else begin
		$display("FAIL: Invalid address did not generate error response");
		errors = errors + 1;
	end
		@(negedge HCLK);
		PTRANS = 2'b00;
	end
endtask



always #5 HCLK = ~HCLK;


initial begin

	HCLK = 1'b0;
	errors = 0;
	reset_dut;


	$display("TEST CASE 1: Single Write Transfer (No Wait-state)");
	single_write(32'h00000010,32'hAABBCCDD);
	$display("WRITE COMPLETED");
	$display("Address = %h", 32'h00000010);
	$display("Data    = %h", 32'hAABBCCDD);


	$display("TEST CASE 2: Single Read Transfer (No Wait-state)");
	single_read(32'h00000010,32'hAABBCCDD);


	$display("TEST CASE 3: Write with Wait-state Insertion");
	single_write(32'h00000020, 32'h11223344);
	single_read(32'h00000020,32'h11223344);



	$display("TEST CASE 4: Burst Transfer (INCR4 - 4 transfers)");
	burst_write_incr4(
		32'h00000040,
		32'h11111111,
		32'h22222222,
		32'h33333333,
		32'h44444444
	);
	single_read(32'h00000040,32'h11111111);
	single_read(32'h00000044,32'h22222222);
	single_read(32'h00000048,32'h33333333);
	single_read(32'h0000004C,32'h44444444);



	$display("TEST CASE 5: Invalid Address with Error Response");
	check_invalid_address(32'h80000000);



	if (errors == 0)$display("ALL TEST CASES PASSED");
	else		$display("TOTAL ERRORS = %0d", errors);

	$stop;

end



//always @(posedge HCLK) begin
//	$display(
//		"TIME=%0t PTRANS=%b HTRANS=%b HREADY=%b PDONE=%b HADDR=%h",
//		$time,
//		PTRANS,
//		dut.master.HTRANS,
//		HREADY,
//		PDONE,
//		dut.master.HADDR
//	);
//end

endmodule
