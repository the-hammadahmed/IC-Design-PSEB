
`timescale 1ns / 1ps

module tb_DMA_Copy_Check;

  localparam        ADDR_R      = 8'h00;
  localparam        DST_R       = 8'h04;
  localparam        LEN_R       = 8'h08;
  localparam        BURST_R     = 8'h0C;
  localparam        CTRL_R      = 8'h10;
  localparam        STATUS_R    = 8'h14;

  localparam [31:0] SRC_BASE    = 32'h0000_0000;
  localparam [31:0] DST_BASE    = 32'h0000_2000;
  localparam        NUM_WORDS   = 8;
  localparam        BURST_BEATS = 4;

  reg clk, rst_n;
  reg psel, penable, pwrite;
  reg     [ 7:0] paddr;
  reg     [31:0] pwdata;
  wire    [31:0] prdata;
  wire           pready;
  wire           irq;

  integer        i;
  integer        mismatches;
  reg     [31:0] status_rd;

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

  initial begin
    rst_n = 0;
    psel = 0;
    penable = 0;
    pwrite = 0;
    paddr = 0;
    pwdata = 0;
    mismatches = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    //manually writing some data into memory at source addr to copy it to different location using DMA
    $display("\nmanually writing some data into memory at source addr");
    for (i = 0; i < NUM_WORDS; i = i + 1) begin
      dut.u_mem.mem[(SRC_BASE>>2)+i] = 32'hABCD_EF00 + i;
      $display(">  src[%0d].addr[%h] = %h", i, SRC_BASE + (i * 4), dut.u_mem.mem[(SRC_BASE>>2)+i]);
    end

    //now DMA copy
    $display("\nstarting DMA copy: \n source = [%h] destination = [%h] \n length = %0d burst = %0d",
             SRC_BASE, DST_BASE, NUM_WORDS, BURST_BEATS);

    apb_write(ADDR_R, SRC_BASE);
    apb_write(DST_R, DST_BASE);
    apb_write(LEN_R, NUM_WORDS);
    apb_write(BURST_R, BURST_BEATS);
    apb_write(CTRL_R, 32'h1);  // START

    wait (irq == 1'b1);
    repeat (2) @(posedge clk);

    apb_read(STATUS_R, status_rd);
    $display("DMA done, status=%b {busy,done,error}", status_rd[2:0]);

    $display("\nReading destination data after copying");
    for (i = 0; i < NUM_WORDS; i = i + 1) begin
      $display(">  dst[%0d].addr[%h] = %h", i, DST_BASE + (i * 4), dut.u_mem.mem[(DST_BASE>>2)+i]);
    end

    //comparision check
    $display("\ncomparing src data vs dst data");
    for (i = 0; i < NUM_WORDS; i = i + 1) begin
      if (dut.u_mem.mem[(DST_BASE>>2)+i] === dut.u_mem.mem[(SRC_BASE>>2)+i]) begin
        $display(">   DATA MATCHED addr[%0d]: %h", i, dut.u_mem.mem[(DST_BASE>>2)+i]);
      end else begin
        $display(">---DATA MISMATCH addr[%0d]: got %h expected %h", i,
                 dut.u_mem.mem[(DST_BASE>>2)+i], dut.u_mem.mem[(SRC_BASE>>2)+i]);
        mismatches = mismatches + 1;
      end
    end

    if (mismatches == 0) $display("COPY VERIFIED - ALL %0d WORDS MATCHED", NUM_WORDS);
    else $display("COPY FAILED - %0d MISMATCH(ES)", mismatches);

    $finish;
  end


  initial begin
    $dumpfile("tb_DMA_Copy_Check.vcd");
    $dumpvars(0, tb_DMA_Copy_Check);
  end

endmodule


// to run is vscode with i verilog
// iverilog -o sim_tb_DMA_Copy_Check axi_full_master.v axi_full_slave.v sync_fifo.v dma_controller.v dma_axi_top.v tb_DMA_Copy_Check.v; vvp sim_tb_DMA_Copy_Check
