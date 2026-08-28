
`timescale 1ns / 1ps

module tb_axi_full;

  localparam ADDR_WIDTH = 32;
  localparam DATA_WIDTH = 32;
  localparam ID_WIDTH   = 4;
  localparam STRB_WIDTH = DATA_WIDTH / 8;

  reg clk, rst_n;

  reg start_write, start_read;
  reg [ADDR_WIDTH-1:0] m_addr;
  reg [           7:0] m_len;
  wire write_done, read_done, m_error, master_busy;

  reg                   wdata_valid;
  reg  [DATA_WIDTH-1:0] wdata;
  reg  [STRB_WIDTH-1:0] wstrb;
  wire                  wdata_ready;

  wire                  rdata_valid;
  wire [DATA_WIDTH-1:0] rdata;
  wire                  rdata_last;
  reg                   rdata_ready;

  wire [ADDR_WIDTH-1:0] awaddr;
  wire [           7:0] awlen;
  wire [           2:0] awsize;
  wire [           1:0] awburst;
  wire [  ID_WIDTH-1:0] awid;
  wire awvalid, awready;

  wire [DATA_WIDTH-1:0] wdata_bus;
  wire [STRB_WIDTH-1:0] wstrb_bus;
  wire wlast, wvalid, wready;

  wire [1:0] bresp;
  wire [ID_WIDTH-1:0] bid;
  wire bvalid, bready;

  wire [ADDR_WIDTH-1:0] araddr;
  wire [7:0] arlen;
  wire [2:0] arsize;
  wire [1:0] arburst;
  wire [ID_WIDTH-1:0] arid;
  wire arvalid, arready;

  wire [DATA_WIDTH-1:0] rdata_bus;
  wire [1:0] rresp;
  wire [ID_WIDTH-1:0] rid;
  wire rlast, rvalid, rready;

  axi_full_master #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH  (ID_WIDTH)
  ) u_master (
      .clk(clk),
      .rst_n(rst_n),
      .start_write(start_write),
      .start_read(start_read),
      .m_addr(m_addr),
      .m_len(m_len),
      .write_done(write_done),
      .read_done(read_done),
      .m_error(m_error),
      .master_busy(master_busy),
      .wdata_valid(wdata_valid),
      .wdata(wdata),
      .wstrb(wstrb),
      .wdata_ready(wdata_ready),
      .rdata_valid(rdata_valid),
      .rdata(rdata),
      .rdata_last(rdata_last),
      .rdata_ready(rdata_ready),
      .m_axi_awaddr(awaddr),
      .m_axi_awlen(awlen),
      .m_axi_awsize(awsize),
      .m_axi_awburst(awburst),
      .m_axi_awid(awid),
      .m_axi_awvalid(awvalid),
      .m_axi_awready(awready),
      .m_axi_wdata(wdata_bus),
      .m_axi_wstrb(wstrb_bus),
      .m_axi_wlast(wlast),
      .m_axi_wvalid(wvalid),
      .m_axi_wready(wready),
      .m_axi_bresp(bresp),
      .m_axi_bvalid(bvalid),
      .m_axi_bready(bready),
      .m_axi_araddr(araddr),
      .m_axi_arlen(arlen),
      .m_axi_arsize(arsize),
      .m_axi_arburst(arburst),
      .m_axi_arid(arid),
      .m_axi_arvalid(arvalid),
      .m_axi_arready(arready),
      .m_axi_rdata(rdata_bus),
      .m_axi_rresp(rresp),
      .m_axi_rlast(rlast),
      .m_axi_rvalid(rvalid),
      .m_axi_rready(rready)
  );

  axi_full_slave #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH  (ID_WIDTH),
      .MEM_WORDS (1024)
  ) u_slave (
      .clk(clk),
      .rst_n(rst_n),
      .s_axi_awaddr(awaddr),
      .s_axi_awlen(awlen),
      .s_axi_awsize(awsize),
      .s_axi_awburst(awburst),
      .s_axi_awid(awid),
      .s_axi_awvalid(awvalid),
      .s_axi_awready(awready),
      .s_axi_wdata(wdata_bus),
      .s_axi_wstrb(wstrb_bus),
      .s_axi_wlast(wlast),
      .s_axi_wvalid(wvalid),
      .s_axi_wready(wready),
      .s_axi_bresp(bresp),
      .s_axi_bid(bid),
      .s_axi_bvalid(bvalid),
      .s_axi_bready(bready),
      .s_axi_araddr(araddr),
      .s_axi_arlen(arlen),
      .s_axi_arsize(arsize),
      .s_axi_arburst(arburst),
      .s_axi_arid(arid),
      .s_axi_arvalid(arvalid),
      .s_axi_arready(arready),
      .s_axi_rdata(rdata_bus),
      .s_axi_rresp(rresp),
      .s_axi_rid(rid),
      .s_axi_rlast(rlast),
      .s_axi_rvalid(rvalid),
      .s_axi_rready(rready)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  integer errors = 0;



  task automatic axi_write_burst(input [31:0] base_addr, input [7:0] len_beats,
                                 input [31:0] base_data);
    integer i;
    begin
      @(posedge clk);
      m_addr      = base_addr;
      m_len       = len_beats - 1;
      start_write = 1'b1;
      @(posedge clk);
      start_write = 1'b0;

      i = 0;
      while (i < len_beats) begin
        wdata_valid = 1'b1;
        wdata       = base_data + i;
        wstrb       = 4'hF;
        @(posedge clk);
        if (wdata_valid && wdata_ready) i = i + 1;
      end
      wdata_valid = 1'b0;

      wait (write_done == 1'b1);
      @(posedge clk);
    end
  endtask






  task automatic axi_read_burst(input [31:0] base_addr, input [7:0] len_beats,
                                input [31:0] base_data);
    integer i;
    reg [31:0] got;
    begin
      @(posedge clk);
      m_addr     = base_addr;
      m_len      = len_beats - 1;
      start_read = 1'b1;
      @(posedge clk);
      start_read = 1'b0;

      i = 0;
      rdata_ready = 1'b1;
      while (i < len_beats) begin
        @(posedge clk);
        if (rdata_valid && rdata_ready) begin
          got = rdata;
          if (got !== (base_data + i)) begin
            $display("MISMATCH burst %0d: got %h expected %h", i, got, base_data + i);
            errors = errors + 1;
          end else begin
            $display("MATCH burst %0d: got %h expected %h", i, got, base_data + i);
          end

          if ((i == len_beats - 1) && !rdata_last) begin
            $display("ERROR RLAST not asserted on final burst %0d", i);
            errors = errors + 1;
          end
          i = i + 1;
        end
      end
      rdata_ready = 1'b0;

      wait (read_done == 1'b1);
      @(posedge clk);
    end
  endtask




  initial begin
    rst_n = 0;
    start_write = 0;
    start_read = 0;
    m_addr = 0;
    m_len = 0;
    wdata_valid = 0;
    wdata = 0;
    wstrb = 4'hF;
    rdata_ready = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    $display("\nBurst length 1");
    axi_write_burst(32'h0000_0000, 8'd1, 32'hAAAA_0000);
    axi_read_burst(32'h0000_0000, 8'd1, 32'hAAAA_0000);

    $display("\nBurst length 4");
    axi_write_burst(32'h0000_0040, 8'd4, 32'hBBBB_0000);
    axi_read_burst(32'h0000_0040, 8'd4, 32'hBBBB_0000);

    $display("\nBurst length 16 (max)");
    axi_write_burst(32'h0000_0100, 8'd16, 32'hCCCC_0000);
    axi_read_burst(32'h0000_0100, 8'd16, 32'hCCCC_0000);

    if (errors == 0) $display("\nALL TESTS PASSED");
    else $display("\n%0d ERROR(S)", errors);

    $finish;
  end

  initial begin
    $dumpfile("tb_axi_full.vcd");
    $dumpvars(0, tb_axi_full);
  end

endmodule


// iverilog -o sim_axi_full axi_full_master.v axi_full_slave.v tb_axi_full.v; vvp sim_axi_full
