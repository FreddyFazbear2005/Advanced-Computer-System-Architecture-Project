class environment #(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);
    
    virtual cache_interface #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) vif;
    int number_of_transactions;

    function new(input virtual cache_interface #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) vif
        , input int number_of_transactions);
        this.vif = vif;
        this.number_of_transactions = number_of_transactions;
    endfunction

    
    mailbox #(Transaction #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
    generator_to_driver_mailbox;
    mailbox #(SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
    monitor_to_scoreboard_mailbox;

    generator#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) gen;
    driver#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) drv;
    monitor#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) mon;
    scoreboard#(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) sco;
    task run();
        begin 
            generator_to_driver_mailbox = new();
            monitor_to_scoreboard_mailbox = new();
            gen = new(generator_to_driver_mailbox,number_of_transactions);
            drv = new(generator_to_driver_mailbox,vif);
            mon = new(monitor_to_scoreboard_mailbox, vif);
            sco = new(monitor_to_scoreboard_mailbox,number_of_transactions);
            fork 
                gen.run();
                drv.run();
                mon.run();
                sco.run();
            join
        end
    endtask

endclass
