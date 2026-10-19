interface cache_interface #(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
)(input logic clk);

    logic rst;
    logic cpu_req;
    logic cpu_rw;
    logic  [ADDR_WIDTH-1:0] cpu_addr;
    logic  [DATA_WIDTH-1:0] cpu_wdata;
    logic [DATA_WIDTH-1:0] cpu_rdata;
    logic cpu_ready;


    clocking driver_cb @(posedge clk);
        output rst;
        output cpu_req;
        output cpu_rw;
        output cpu_addr;
        output cpu_wdata;
        input cpu_rdata;
        input cpu_ready;
    endclocking

    clocking monitor_cb @(posedge clk);
        input rst;
        input cpu_req;
        input cpu_rw;
        input cpu_addr;
        input cpu_wdata;
        input cpu_rdata;
        input cpu_ready;
    endclocking

endinterface
