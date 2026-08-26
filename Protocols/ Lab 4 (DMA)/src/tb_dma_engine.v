
`timescale 1ns / 1ps

module tb_dma_engine;

  reg            clk;
  reg            rst_n;

  reg            start;
  reg     [31:0] src_addr;
  reg     [31:0] dst_addr;
  reg     [31:0] length_words;
  reg     [ 7:0] burst_size;

  wire           dma_busy;
  wire           dma_done;
  wire           dma_error;
  wire           irq;

  integer        i;

  dma_engine #(
      .MEM_WORDS(1024)
  ) uut (
      .clk         (clk),
      .rst_n       (rst_n),
      .start       (start),
      .src_addr    (src_addr),
      .dst_addr    (dst_addr),
      .length_words(length_words),
      .burst_size  (burst_size),
      .dma_busy    (dma_busy),
      .dma_done    (dma_done),
      .dma_error   (dma_error),
      .irq         (irq)
  );


  initial clk = 0;
  always #5 clk = ~clk;

  //first writing some values to memory, below i will copy these values from source to destination
  initial begin
    for (i = 0; i < 8; i = i + 1) begin
      uut.s_mem.memory[i] = 32'hA000_0000 + i;
    end
  end

  initial begin
    rst_n        = 0;
    start        = 0;
    src_addr     = 32'd0;
    dst_addr     = 32'd0;
    length_words = 32'd0;
    burst_size   = 8'd4;

    repeat (4) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);


    src_addr     = 32'd0;  //source addr
    dst_addr     = 32'd256;  //destination addr
    length_words = 32'd8;

    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    wait (dma_done == 1'b1);
    repeat (2) @(posedge clk);

    $display("Transfer completed!\nnow checking destination values to verify.");
    for (i = 0; i < 8; i = i + 1) begin
      $display("destination addr[%0d] = %h (expected value %h)", 64 + i, uut.s_mem.memory[64+i],
               32'hA000_0000 + i);
    end

    if (dma_error) $display("ERROR flag!");
    else $display("Test Pased!");

    $finish;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_dma_engine);
  end

endmodule


//to compile
// iverilog -o sim dma_fsm.v sync_fifo.v simple_memory.v dma_engine.v tb_dma_engine.v ; vvp sim
// 
