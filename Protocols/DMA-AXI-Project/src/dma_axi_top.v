

module dma_axi_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter MEM_WORDS  = 4096
) (
    input wire clk,
    input wire rst_n,

    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [ 7:0] paddr,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pready,

    output wire irq
);

  localparam STRB_WIDTH = DATA_WIDTH / 8;

  wire [ADDR_WIDTH-1:0] awaddr;
  wire [7:0] awlen;
  wire [2:0] awsize;
  wire [1:0] awburst;
  wire [ID_WIDTH-1:0] awid;
  wire awvalid, awready;

  wire [DATA_WIDTH-1:0] wdata;
  wire [STRB_WIDTH-1:0] wstrb;
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

  wire [DATA_WIDTH-1:0] rdata;
  wire [1:0] rresp;
  wire [ID_WIDTH-1:0] rid;
  wire rlast, rvalid, rready;

  dma_controller #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH  (ID_WIDTH)
  ) u_dma (
      .clk(clk),
      .rst_n(rst_n),
      .psel(psel),
      .penable(penable),
      .pwrite(pwrite),
      .paddr(paddr),
      .pwdata(pwdata),
      .prdata(prdata),
      .pready(pready),
      .irq(irq),
      .m_axi_awaddr(awaddr),
      .m_axi_awlen(awlen),
      .m_axi_awsize(awsize),
      .m_axi_awburst(awburst),
      .m_axi_awid(awid),
      .m_axi_awvalid(awvalid),
      .m_axi_awready(awready),
      .m_axi_wdata(wdata),
      .m_axi_wstrb(wstrb),
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
      .m_axi_rdata(rdata),
      .m_axi_rresp(rresp),
      .m_axi_rlast(rlast),
      .m_axi_rvalid(rvalid),
      .m_axi_rready(rready)
  );

  axi_full_slave #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH  (ID_WIDTH),
      .MEM_WORDS (MEM_WORDS)
  ) u_mem (
      .clk(clk),
      .rst_n(rst_n),
      .s_axi_awaddr(awaddr),
      .s_axi_awlen(awlen),
      .s_axi_awsize(awsize),
      .s_axi_awburst(awburst),
      .s_axi_awid(awid),
      .s_axi_awvalid(awvalid),
      .s_axi_awready(awready),
      .s_axi_wdata(wdata),
      .s_axi_wstrb(wstrb),
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
      .s_axi_rdata(rdata),
      .s_axi_rresp(rresp),
      .s_axi_rid(rid),
      .s_axi_rlast(rlast),
      .s_axi_rvalid(rvalid),
      .s_axi_rready(rready)
  );

endmodule
