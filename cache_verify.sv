module cache_verify;

    parameter ADDR_WIDTH  = 10;
    parameter DATA_WIDTH  = 32;
    parameter NUM_SETS    = 8;
    parameter LATENCY = 5;

    logic clk;
    initial begin 
        clk = 0;
        forever 
            #10 clk = ~clk;
    end

    environment env;
    
    cache_interface #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) cache_inf(clk);
    int number_of_transactions = 10000;


    cache_top
    #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .NUM_SETS   (NUM_SETS),
        .LATENCY(LATENCY)
    )
    DUT
    (
        .clk(clk),
        .rst(cache_inf.rst),

        .cpu_req(cache_inf.cpu_req),
        .cpu_rw(cache_inf.cpu_rw),

        .cpu_addr(cache_inf.cpu_addr),
        .cpu_wdata(cache_inf.cpu_wdata),

        .cpu_rdata(cache_inf.cpu_rdata),
        .cpu_ready(cache_inf.cpu_ready)
    );

    initial begin 
        env = new(cache_inf, number_of_transactions);
        env.run();
    end

endmodule
