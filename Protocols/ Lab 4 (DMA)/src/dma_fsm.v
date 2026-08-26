
module dma_fsm (
    input wire        clk,
    input wire        rst,
    input wire        start_transfer,
    input wire [31:0] src_addr_init,
    input wire [31:0] dst_addr_init,
    input wire [31:0] length_init,
    input wire        bus_op_done,

    output reg [31:0] current_src_addr,
    output reg [31:0] current_dst_addr,
    output reg        bus_read_req,
    output reg        bus_write_req,
    output reg        transfer_done,
    output reg        transfer_active,

    input wire [31:0] read_data_buffer
);

  localparam STATE_IDLE       = 3'b000;
  localparam STATE_READ       = 3'b001;
  localparam STATE_WAIT_READ  = 3'b010;
  localparam STATE_WRITE      = 3'b011;
  localparam STATE_WAIT_WRITE = 3'b100;
  localparam STATE_INC_ADDR   = 3'b101;
  localparam STATE_DONE       = 3'b110;

  reg [ 2:0] state;
  reg [ 2:0] next_state;
  reg [31:0] transfer_count;


  always @(posedge clk or negedge rst) begin
    if (!rst) state <= STATE_IDLE;
    else state <= next_state;
  end

  always @(*) begin
    next_state = state;
    case (state)
      STATE_IDLE: begin
        if (start_transfer && (length_init > 0)) next_state = STATE_READ;
      end
      STATE_READ:       next_state = STATE_WAIT_READ;
      STATE_WAIT_READ:  if (bus_op_done) next_state = STATE_WRITE;
      STATE_WRITE:      next_state = STATE_WAIT_WRITE;
      STATE_WAIT_WRITE: if (bus_op_done) next_state = STATE_INC_ADDR;
      STATE_INC_ADDR: begin
        if (transfer_count == 0) next_state = STATE_DONE;
        else next_state = STATE_READ;
      end
      STATE_DONE:       next_state = STATE_IDLE;
      default:          next_state = STATE_IDLE;
    endcase
  end


  // ork on 3 signal. current_src_addr , current_dst_addr and transfer_count. 
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      //to do  
      current_src_addr <= 32'd0;
      current_dst_addr <= 32'd0;
      transfer_count   <= 32'd0;
    end else begin
      case (state)
        STATE_IDLE: begin
          if (start_transfer) begin
            // to do. Assign value
            current_src_addr <= src_addr_init;
            current_dst_addr <= dst_addr_init;
            transfer_count   <= length_init;
          end
        end

        STATE_INC_ADDR: begin
          //to do, current_src_addr , current_dst_addr and transfer_count. 
          current_src_addr <= current_src_addr + 32'd4;
          current_dst_addr <= current_dst_addr + 32'd4;
          transfer_count   <= transfer_count - 32'd1;
        end

        default: begin
          //skiping
        end
      endcase
    end
  end


  // Control / status outputs  (Output Control Signals Table)
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      bus_read_req    <= 1'b0;
      bus_write_req   <= 1'b0;
      transfer_done   <= 1'b0;
      transfer_active <= 1'b0;
    end else begin
      bus_read_req  <= 1'b0;
      bus_write_req <= 1'b0;
      transfer_done <= 1'b0;

      case (state)
        STATE_IDLE: begin
          // to do , transfer_active
          transfer_active <= 1'b0;
        end

        STATE_READ: begin
          // to do. bus_read_req , transfer_active.
          bus_read_req    <= 1'b1;
          transfer_active <= 1'b1;
        end

        STATE_WAIT_READ: begin
          //to do. transfer_active. 
          transfer_active <= 1'b1;
        end

        STATE_WRITE: begin
          //to do. bus_write_req , transfer_active 
          bus_write_req   <= 1'b1;
          transfer_active <= 1'b1;
        end

        STATE_WAIT_WRITE: begin
          //to do transfer_active. 
          transfer_active <= 1'b1;
        end

        STATE_INC_ADDR: begin
          //to do transfer_active. 
          transfer_active <= 1'b1;
        end

        STATE_DONE: begin
          //to do transfer_done , transfer_active. 
          transfer_done   <= 1'b1;
          transfer_active <= 1'b0;
        end

        default: begin
          transfer_active <= 1'b0;
        end
      endcase
    end
  end

endmodule
