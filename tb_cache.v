
module tb_cache;

//=========================================================
// PARAMETERS
//=========================================================

parameter ADDR_WIDTH  = 10;
parameter DATA_WIDTH  = 32;

parameter NUM_SETS    = 8;
parameter NUM_WAYS    = 2;

parameter LATENCY   = 5;

//=========================================================
// CLOCK / RESET
//=========================================================

reg clk;
reg rst;

initial
begin
    clk = 0;
    forever #5 clk = ~clk;          // 100 MHz
end

//=========================================================
// CPU INTERFACE
//=========================================================

reg cpu_req;
reg cpu_rw;

reg [ADDR_WIDTH-1:0] cpu_addr;
reg [DATA_WIDTH-1:0] cpu_wdata;

wire [DATA_WIDTH-1:0] cpu_rdata;
wire cpu_ready;

//=========================================================
// TEST VARIABLES
//=========================================================

integer pass_count;
integer fail_count;

//=========================================================
// DUT
//=========================================================

cache_top
#(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .NUM_SETS   (NUM_SETS),
    .NUM_WAYS   (NUM_WAYS),
    .LATENCY(LATENCY)
)
DUT
(
    .clk(clk),
    .rst(rst),

    .cpu_req(cpu_req),
    .cpu_rw(cpu_rw),

    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),

    .cpu_rdata(cpu_rdata),
    .cpu_ready(cpu_ready)
);

//=========================================================
// RESET TASK
//=========================================================

task reset_dut;

begin

    rst       = 1'b1;

    cpu_req   = 1'b0;
    cpu_rw    = 1'b0;

    cpu_addr  = 32'd0;
    cpu_wdata = 32'd0;

    repeat(5) @(posedge clk);

    rst = 1'b0;

    repeat(5) @(posedge clk);

end

endtask

//=========================================================
// WAIT FOR CACHE RESPONSE
//=========================================================

task wait_for_ready;

begin

    while(cpu_ready == 1'b0)
        @(posedge clk);

end

endtask

//=========================================================
// CPU READ
//=========================================================

task cpu_read;

input [ADDR_WIDTH-1:0] address;

begin

    @(posedge clk);

    cpu_req  <= 1'b1;
    cpu_rw   <= 1'b0;

    cpu_addr <= address;

    @(posedge clk);

    cpu_req <= 1'b0;

    wait_for_ready();

    $display("------------------------------------------");
    $display("READ");
    $display("Time    : %0t",$time);
    $display("Address : %h",address);
    $display("Data    : %h",cpu_rdata);
    $display("------------------------------------------");

end

endtask

//=========================================================
// CPU WRITE
//=========================================================

task cpu_write;

input [ADDR_WIDTH-1:0] address;
input [DATA_WIDTH-1:0] data;

begin

    @(posedge clk);

    cpu_req   <= 1'b1;
    cpu_rw    <= 1'b1;

    cpu_addr  <= address;
    cpu_wdata <= data;

    @(posedge clk);

    cpu_req <= 1'b0;

    wait_for_ready();

    $display("------------------------------------------");
    $display("WRITE");
    $display("Time    : %0t",$time);
    $display("Address : %h",address);
    $display("Data    : %h",data);
    $display("------------------------------------------");

end

endtask

//=========================================================
// DISPLAY CACHE CONTENTS
//=========================================================

task display_cache;

integer s;

begin

    $display("");
    $display("============= CACHE CONTENTS =============");

    for(s=0; s<NUM_SETS; s=s+1)
    begin

        $display("SET=%0d",s);

    end

    $display("==========================================");
    $display("");

end

endtask

//=========================================================
// MAIN TEST SEQUENCE
//=========================================================

initial
begin

    pass_count = 0;
    fail_count = 0;

    //------------------------------------------------------
    // Reset
    //------------------------------------------------------

    reset_dut();

    $display("");
    $display("==========================================");
    $display(" CACHE SUBSYSTEM VERIFICATION");
    $display("==========================================");
    $display("");

    //------------------------------------------------------
    // TEST 1 : READ MISS
    //------------------------------------------------------

    $display("TEST 1 : READ MISS");

    cpu_read(32'h00000020);

    if(cpu_rdata == 32'h00000008)
    begin
        $display("PASS");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("FAIL");
        $display("cpu read data should be 0x00000008, it is %0h",cpu_rdata);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------
    // TEST 2 : READ HIT
    //------------------------------------------------------

    $display("");
    $display("TEST 2 : READ HIT");

    cpu_read(32'h00000020);

    if(cpu_rdata == 32'h00000008)
    begin
        $display("PASS");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("FAIL");
        $display("cpu read data should be 0x00000008, it is %0h",cpu_rdata);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------
    // TEST 3 : WRITE HIT
    //------------------------------------------------------

    $display("");
    $display("TEST 3 : WRITE HIT");

    cpu_write(32'h00000020,32'hDEADBEEF);

    cpu_read(32'h00000020);

    if(cpu_rdata == 32'hDEADBEEF)
    begin
        $display("PASS");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("FAIL");
        $display("cpu read data should be 0xDEADBEEF, it is %0h",cpu_rdata);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------
    // TEST 4 : WRITE MISS
    //------------------------------------------------------

    $display("");
    $display("TEST 4 : WRITE MISS");

    cpu_write(32'h00000120,32'hAAAAAAAA);

    cpu_read(32'h00000120);

    if(cpu_rdata == 32'hAAAAAAAA)
    begin
        $display("PASS");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("FAIL");
        $display("cpu read data should be 0xAAAAAAAA, it is %0h",cpu_rdata);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------
    // TEST 5 : READ AFTER WRITE
    //------------------------------------------------------

    $display("");
    $display("TEST 5 : READ AFTER WRITE");

    cpu_read(32'h00000120);

    if(cpu_rdata == 32'hAAAAAAAA)
    begin
        $display("PASS");
        pass_count = pass_count + 1;
    end
    else
    begin
        $display("FAIL");
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------
    // TEST 6 : LRU REPLACEMENT
    //------------------------------------------------------

    $display("");
    $display("TEST 6 : LRU REPLACEMENT");

    cpu_read(32'h00000220);

    cpu_read(32'h00000320);

    cpu_read(32'h00000420);

    display_cache();

    pass_count = pass_count + 1;

    //------------------------------------------------------
    // TEST 7 : DIRTY WRITEBACK
    //------------------------------------------------------

    $display("");
    $display("TEST 7 : DIRTY WRITEBACK");

    cpu_write(32'h00000520,32'h12345678);

    cpu_read(32'h00000620);

    cpu_read(32'h00000720);

    display_cache();

    pass_count = pass_count + 1;

    //------------------------------------------------------
    // TEST 8 : RANDOM ACCESS
    //------------------------------------------------------

    $display("");
    $display("TEST 8 : RANDOM ACCESSES");

    cpu_read(32'h000000A0);
    cpu_write(32'h000000C0,32'hCAFEBABE);
    cpu_read(32'h000000C0);
    cpu_read(32'h00000040);

    pass_count = pass_count + 1;

    //------------------------------------------------------
    // TEST COMPLETE
    //------------------------------------------------------

#100;

$display("");
$display("Simulation Finished");

$display("");
$display("==========================================");
$display(" FINAL RESULTS");
$display("==========================================");

$display("PASS : %0d", pass_count);
$display("FAIL : %0d", fail_count);

$display("");

$display("READS        : %0d", DUT.MONITOR.read_count);
$display("WRITES       : %0d", DUT.MONITOR.write_count);
$display("HITS         : %0d", DUT.MONITOR.hit_count);
$display("MISSES       : %0d", DUT.MONITOR.miss_count);
$display("EVICTIONS    : %0d", DUT.MONITOR.eviction_count);
$display("WRITEBACKS   : %0d", DUT.MONITOR.writeback_count);
$display("TRANSACTIONS : %0d", DUT.MONITOR.transaction_count);

$display("==========================================");

$finish;


end

endmodule
