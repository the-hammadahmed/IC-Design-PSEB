
`timescale 1ns / 1ps

module tb_dma_axi_top;

  localparam ADDR_R   = 8'h00;
  localparam DST_R    = 8'h04;
  localparam LEN_R    = 8'h08;
  localparam BURST_R  = 8'h0C;
  localparam CTRL_R   = 8'h10;
  localparam STATUS_R = 8'h14;

  reg clk, rst_n;
  reg psel, penable, pwrite;
  reg  [ 7:0] paddr;
  reg  [31:0] pwdata;
  wire [31:0] prdata;
  wire        pready;
  wire        irq;

  integer i, errors;

  dma_axi_top #(
      .MEM_WORDS(4096)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .psel(psel),
      .penable(penable),
      .pwrite(pwrite),
      .paddr(paddr),
      .pwdata(pwdata),
      .prdata(prdata),
      .pready(pready),
      .irq(irq)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  //simple APB-lite write
  task automatic apb_write(input [7:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      psel    = 1'b1;
      penable = 1'b0;
      pwrite  = 1'b1;
      paddr   = addr;
      pwdata  = data;
      @(posedge clk);
      penable = 1'b1;
      @(posedge clk);
      psel    = 1'b0;
      penable = 1'b0;
    end
  endtask

  task automatic apb_read(input [7:0] addr, output [31:0] data);
    begin
      @(posedge clk);
      psel    = 1'b1;
      penable = 1'b0;
      pwrite  = 1'b0;
      paddr   = addr;
      @(posedge clk);
      penable = 1'b1;
      @(posedge clk);
      data    = prdata;
      psel    = 1'b0;
      penable = 1'b0;
    end
  endtask

  reg [31:0] status_rd;

  task automatic run_transfer(input [31:0] src, input [31:0] dst, input [31:0] length_words,
                              input [31:0] burst_beats, input [31:0] base_pattern);
    begin
      for (i = 0; i < length_words; i = i + 1) dut.u_mem.mem[(src>>2)+i] = base_pattern + i;

      apb_write(ADDR_R, src);
      apb_write(DST_R, dst);
      apb_write(LEN_R, length_words);
      apb_write(BURST_R, burst_beats);
      apb_write(CTRL_R, 32'h1);  // START

      wait (irq == 1'b1);
      repeat (2) @(posedge clk);

      apb_read(STATUS_R, status_rd);

      for (i = 0; i < length_words; i = i + 1) begin
        if (dut.u_mem.mem[(dst>>2)+i] !== (base_pattern + i)) begin
          $display("MISMATCH word %0d: got %h expected %h", i, dut.u_mem.mem[(dst>>2)+i],
                   base_pattern + i);
          errors = errors + 1;
        end
      end
      $display(
          "Transfer src = [%h] to dst = [%h] len = %0d burst = %0d -> status = %b {busy,done,error}",
          src, dst, length_words, burst_beats, status_rd[2:0]);
    end
  endtask

  initial begin
    rst_n = 0;
    psel = 0;
    penable = 0;
    pwrite = 0;
    paddr = 0;
    pwdata = 0;
    errors = 0;

    repeat (2) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    $display("\nTransfer 1: 16 words, burst=4 (4 whole bursts)");
    run_transfer(32'h0000_0000, 32'h0000_1000, 32'd16, 32'd4, 32'hD000_0000);

    $display("\nTransfer 2: 10 words, burst=4 (2 whole + 1 partial burst of 2)");
    run_transfer(32'h0000_2000, 32'h0000_3000, 32'd10, 32'd4, 32'hE000_0000);

    if (errors == 0) $display("\nALL TESTS PASSED");
    else $display("\n%0d ERROR(S)", errors);

    $finish;
  end

  initial begin
    $dumpfile("tb_dma_axi_top.vcd");
    $dumpvars(0, tb_dma_axi_top);
  end

endmodule


// iverilog -o sim_dma_axi axi_full_master.v axi_full_slave.v sync_fifo.v dma_controller.v dma_axi_top.v tb_dma_axi_top.v; vvp sim_dma_axi
