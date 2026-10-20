class driver#(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);
    mailbox #(Transaction #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
    generator_to_driver_mailbox;
    virtual cache_interface #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) vif;

    function new(input mailbox #(Transaction #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
       generator_to_driver_mailbox, 
    input virtual cache_interface #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))
        vif);
        this.generator_to_driver_mailbox = generator_to_driver_mailbox;
        this.vif = vif;
    endfunction


    task reset_dut();
        begin
            vif.driver_cb.rst <= 1'b1;
            vif.driver_cb.cpu_req <= '0;
            vif.driver_cb.cpu_rw <= '0;
            vif.driver_cb.cpu_addr <= '0;
            vif.driver_cb.cpu_wdata <= '0;
            repeat(10) @(vif.driver_cb);

            vif.driver_cb.rst <= 1'b0;

            @(vif.driver_cb);
        end
    endtask


    task run();
        Transaction #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) tr;
        reset_dut();
        forever begin 
            generator_to_driver_mailbox.get(tr);

            vif.driver_cb.cpu_req   <= 1'b1;
            vif.driver_cb.cpu_rw    <= tr.cpu_rw;
            vif.driver_cb.cpu_addr  <= tr.cpu_addr;
            vif.driver_cb.cpu_wdata <= tr.cpu_wdata;
            @(vif.driver_cb);  

            vif.driver_cb.cpu_req   <= 1'b0;
            vif.driver_cb.cpu_rw    <= '0;
            vif.driver_cb.cpu_addr  <= '0;
            vif.driver_cb.cpu_wdata <= '0;

            do @(vif.driver_cb);
            while (vif.driver_cb.cpu_ready !== 1'b1);
        end
    endtask

endclass
