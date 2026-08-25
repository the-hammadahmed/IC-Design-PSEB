`include "AHB_TOP.v"

// in this testbench module we will verify the AHB TOP that incapsulates the AHB Master, Decoder, and MUX
module old_AHB_tb ();
    // Signals
    reg HCLK;
    reg HRESETn;
    reg [31:0] PADDR;
    reg [31:0] PWDATA;
    reg PWRITE;
    reg [2:0] PSIZE;
    reg [1:0] PTRANS;
    reg [2:0] PBURST;
    wire [31:0] HRDATA;
    wire PDONE;
    
    // instantiate the AHB_TOP module
    AHB_TOP top (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PSIZE(PSIZE),
        .PTRANS(PTRANS),
        .PBURST(PBURST),
	.HRDATA(HRDATA),
	.PDONE(PDONE)
    );


    // Clock generation
    initial begin
        HCLK = 0;
        forever #10 HCLK = ~HCLK; // 20 time units clock period
    end

    // we will act as the processor in the testbench sending and demanding data from the slaves 
    initial begin
        // reset the system
        HRESETn = 0;
        #20; // hold reset for 20 time units
        HRESETn = 1; // release reset

        //***********first we will write in several places using single transfer (HBURST = 0)*************\\
        // case 1: write 8 bits to several addresses
        PADDR = 32'h00000001; // address 0
        PWRITE = 1; // write operation
        PWDATA = 32'hAA; // data to write
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)

        PADDR = 32'h00000005; // address 5
        PWRITE = 1; // write operation
        PWDATA = 32'hBB; // data to write
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete
        
        // Making HTRANS to be IDLE to test separiting the transfers
        PTRANS = 2'b00; // IDLE state
        #20;

        PADDR = 32'h0000000A; // address 10
        PWRITE = 1; // write operation
        PWDATA = 32'hCC; // data to write
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)

        // Making HTRANS to be IDLE to seperate between the different types of transfers
        PTRANS = 2'b00; // IDLE state
        #20;

        // case 2: write 16 bits to several addresses
        PADDR = 32'h00000010; // address 16
        PWRITE = 1; // write operation
        PWDATA = 32'hABCD; // data to write
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)

        PADDR = 32'h00000012; // address 18
        PWRITE = 1; // write operation
        PWDATA = 32'hAABB; // data to write
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0
        #20; // wait for the transfer to complete

        // Making HTRANS to be IDLE to seperate between the different types of transfers
        PTRANS = 2'b00; // IDLE state
        #20;

        // case 3: write 32 bits to several addresses
        PADDR = 32'h00000020; // address 32
        PWRITE = 1; // write operation
        PWDATA = 32'hA0B0C0D0; // data to write
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)

        PADDR = 32'h00000024; // address 36
        PWRITE = 1; // write operation
        PWDATA = 32'hA1B1C1D1; // data to writ
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete

        // Making HTRANS to be IDLE to seperate between the different types of transfers
        PTRANS = 2'b00; // IDLE state
        #40; // increased amount of waiting time just to indicate the next test cases will be reading

        //*******************now we will read from the exact same addresses using single transfer (HBURST = 0)*************\\
        // case 1: read 8 bits from addresses with written data
        PADDR = 32'h00000001; // address 0
        PWRITE = 0; // read operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)

        PADDR = 32'h00000005; // address 5
        PWRITE = 0; // read operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete

        PADDR = 32'h0000000A; // address 10
        PWRITE = 0; // read operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete

        // case 2: read 16 bits from addresses with written data
        PADDR = 32'h00000010; // address 16
        PWRITE = 0; // read operation
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete

        PADDR = 32'h00000012; // address 18
        PWRITE = 0; // read operation
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete

        // case 3: read 32 bits from addresses with written data
        PADDR = 32'h00000020; // address 32
        PWRITE = 0; // read operation
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete

        PADDR = 32'h00000024; // address 36
        PWRITE = 0; // read operation
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0
        #20; // wait for the transfer to complete

        // Making HTRANS to be IDLE to seperate between the different types of transfers
        PTRANS = 2'b00; // IDLE state
        #40; // increased amount of waiting time just to indicate the next test cases will be writing

        //*******************second we will write in several places using INCREMENTAL burst transfer (HBURST = 1)*************\\
        // case 1: write 8 bits in five sequential addresses
        PADDR = 32'h00000030; // address 48
        PWRITE = 1; // write operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        PWDATA = 32'h69; // data to write
        #20; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 1 by itself (included in Master Code)      
        #100; // wait for five cycles to complete the burst transfer
        
        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;

        // case 2: write 16 bits in three sequential addresses
        PADDR = 32'h00000040; // address 64
        PWRITE = 1; // write operation
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        PWDATA = 32'hA001; // data to write
        #40; // wait for the transfer to complete
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 2 by itself (included in Master Code)
        PWDATA = 32'hB001; // new data to write
        #20; // wait for three cycles to complete the burst transfer
        PWDATA = 32'h5678; // new data to write
        #20; // wait for one cycle to complete the burst transfer


        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;

        // case 3: write 32 bits in two sequential addresses
        PADDR = 32'h00000050; // address 80
        PWRITE = 1; // write operation
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        PWDATA = 32'hA5B6C7D8; // write data
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 4 by itself (included in Master Code)
        #20; // wait for one cycle to complete the burst transfer

        // Making HTRANS to be IDLE to seperate between the different types of transfers
        PTRANS = 2'b00; // IDLE state
        #40; // increased amount of waiting time just to indicate the next test cases will be writing

        //*******************now we will read from the exact same addresses using INCREMENTAL burst transfer (HBURST = 1)*************\\
        // case 1: read 8 bits from addresses with written data
        PADDR = 32'h00000030; // address 48
        PWRITE = 0; // read operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        #20; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 1 by itself (included in Master Code)
        #100; // wait for five cycles to complete the burst transfer

        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;

        // case 2: read 16 bits from addresses with written data
        PADDR = 32'h00000040; // address 64
        PWRITE = 0; // read operation
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        #40; // wait for the transfer to complete
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 2 by itself (included in Master Code)
        #40; // wait for three cycles to complete the burst transfer

        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;
        
        // case 3: read 32 bits from addresses with written data
        PADDR = 32'h00000050; // address 80
        PWRITE = 0; // read operation
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        #40; // wait for the transfer to complete
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 4 by itself (included in Master Code)
        #40; // wait for one cycle to complete the burst transfer
        
        // Making HTRANS to be IDLE to end the testbench for first slave
        PTRANS = 2'b00; // IDLE state
        #40; 



        //**************************** begin testbench for the second slave ********************************\\
        // this testbench will be less exahustive than the one for the first slave as out second slave memory is small
        // we included a second slave to ensure our design can switch between slaves correctly 


        //***********first we will write in several places using single transfer (HBURST = 0)*************\\

        //  case 1: write 8 bits in a random address
        PADDR = 32'h40000003; // address 3, last two bits are the selection for slaves so if PADDR[31:310] = 2'b01, we are selecting the second slave
        PWRITE = 1; // write operation
        PWDATA = 32'hA5; // data to write
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)

        //  case 2: write 16 bits in a random address
        PADDR = 32'h40000010; // address 16
        PWRITE = 1; // write operation
        PWDATA = 32'hA5B6; // data to write
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete 

        //  case 3: write 32 bits in a random address
        PADDR = 32'h40000020; // address 32
        PWRITE = 1; // write operation
        PWDATA = 32'hA5B6C7D8; // data
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)


        //*******************now we will read from the exact same addresses using single transfer (HBURST = 0)*************\\
        //  case 1: read 8 bits from addresses with written data
        PADDR = 32'h40000003; // address 3
        PWRITE = 0; // read operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)

        //  case 2: read 16 bits from addresses with written data
        PADDR = 32'h40000010; // address 16
        PWRITE = 0; // read operation
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0
        #20; // wait for the transfer to complete

        //  case 3: read 32 bits from addresses with written data
        PADDR = 32'h40000020; // address 32
        PWRITE = 0; // read operation
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // byte transfer (NONSEQ)
        PBURST = 3'b000; // single transfer (HBURST = 0)
        #20; // wait for the transfer to complete


        //******************second we will write in several places using INCREMENTAL burst transfer (HBURST = 1)*************\\
        //  case 1: write 8 bits in two sequential addresses
        PADDR = 32'h40000028; // address 40
        PWRITE = 1; // write operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        PWDATA = 32'hA5; // data to write
        #20; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 1 by itself (included in Master Code)
        #20; // wait for two cycles to complete the burst transfer

        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;

        //  case 2: write 16 bits in two sequential addresses
        PADDR = 32'h40000032; // address 50
        PWRITE = 1; // write operation
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        PWDATA = 32'hA5A5; // data to write
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 2 by itself (included in Master Code)
        PWDATA = 32'hB6B6; // new data to write
        #20; // wait for two cycles to complete the burst transfer

        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;

        //  case 3: write 32 bits in two sequential addresses
        PADDR = 32'h40000038; // address 56
        PWRITE = 1; // write operation
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        PWDATA = 32'hA5B6C7D8; // data to write
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 4 by itself (included in Master Code)
        #40; // wait for one cycle to complete the burst transfer

        // Making HTRANS to be IDLE to seperate between the different types of transfers
        PTRANS = 2'b00; // IDLE state
        #20;


        //*******************now we will read from the exact same addresses using INCREMENTAL burst transfer (HBURST = 1)*************\\
        //  case 1: read 8 bits from addresses with written data
        PADDR = 32'h40000028; // address 40
        PWRITE = 0; // read operation
        PSIZE = 3'b000; // 8 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST =
        #20; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 1 by itself (included in Master Code)
        #40; // wait for two cycles to complete the burst transfer

        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;

        //  case 2: read 16 bits from addresses with written data
        PADDR = 32'h40000032; // address 50
        PWRITE = 0; // read operation
        PSIZE = 3'b001; // 16 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        #40; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 2 by itself (included in Master Code)
        #20; // wait for two cycles to complete the burst transfer

        // insert IDLE state
        PTRANS = 2'b00; // IDLE state
        #20;

        //  case 3: read 32 bits from addresses with written data
        PADDR = 32'h40000038; // address 56
        PWRITE = 0; // read operation
        PSIZE = 3'b010; // 32 bits transfer
        PTRANS = 2'b10; // first transfer will be (NONSEQ)
        PBURST = 3'b001; // INCREMENTAL burst (HBURST = 1)
        #20; // wait for the transfer to complete (20 ns delay overhead after each IDLE state to be sampled by the Slave)
        PTRANS = 2'b11; // next transfers will be SEQ, address will be incremented by 4 by itself (included in Master Code)
        #40; // wait for one cycle to complete the burst transfer

        // Making HTRANS to be IDLE to end the testbench for second slave
        PTRANS = 2'b00; // idle state
        #40;
        $stop; // stop the simulation
    end
endmodule //AHB_tb
/*
add wave -position insertpoint  \
sim:/AHB_tb/top/master/HCLK \
sim:/AHB_tb/top/master/HRESETn \
sim:/AHB_tb/top/master/PADDR \
sim:/AHB_tb/top/master/PWDATA \
sim:/AHB_tb/top/master/PWRITE \
sim:/AHB_tb/top/master/PSIZE \
sim:/AHB_tb/top/master/PTRANS \
sim:/AHB_tb/top/master/PBURST \
sim:/AHB_tb/top/master/HREADY \
sim:/AHB_tb/top/master/HRESP \
sim:/AHB_tb/top/master/HRDATA \
sim:/AHB_tb/top/master/HADDR \
sim:/AHB_tb/top/master/HWDATA \
sim:/AHB_tb/top/master/HWRITE \
sim:/AHB_tb/top/master/HSIZE \
sim:/AHB_tb/top/master/HTRANS \
sim:/AHB_tb/top/master/HBURST \
sim:/AHB_tb/top/master/HWDATA_reg \
sim:/AHB_tb/top/master/cs \
sim:/AHB_tb/top/master/ns \
add wave -position insertpoint  \
sim:/AHB_tb/top/slave1/HADDR \
sim:/AHB_tb/top/slave1/HWDATA \
sim:/AHB_tb/top/slave1/HSELx_slaves \
sim:/AHB_tb/top/slave1/HWRITE \
sim:/AHB_tb/top/slave1/HSIZE \
sim:/AHB_tb/top/slave1/HTRANS \
sim:/AHB_tb/top/slave1/HBURST \
sim:/AHB_tb/top/slave1/HREADY \
sim:/AHB_tb/top/slave1/HREADYOUT \
sim:/AHB_tb/top/slave1/HRESP \
sim:/AHB_tb/top/slave1/HRDATA \
sim:/AHB_tb/top/slave1/memory \
add wave -position insertpoint  \
sim:/AHB_tb/top/slave2/HADDR \
sim:/AHB_tb/top/slave2/HWDATA \
sim:/AHB_tb/top/slave2/HSELx_slaves \
sim:/AHB_tb/top/slave2/HWRITE \
sim:/AHB_tb/top/slave2/HSIZE \
sim:/AHB_tb/top/slave2/HTRANS \
sim:/AHB_tb/top/slave2/HBURST \
sim:/AHB_tb/top/slave2/HREADY \
sim:/AHB_tb/top/slave2/HREADYOUT \
sim:/AHB_tb/top/slave2/HRESP \
sim:/AHB_tb/top/slave2/HRDATA \
sim:/AHB_tb/top/slave2/curr_state \
sim:/AHB_tb/top/slave2/next_state \
sim:/AHB_tb/top/slave2/memory_2 \
run -all
*/