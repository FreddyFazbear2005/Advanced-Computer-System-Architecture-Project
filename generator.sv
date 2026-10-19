class generator#(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);


    int number_of_transactions;

    mailbox #(Transaction #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
    generator_to_driver_mailbox;

    function new(input mailbox #(Transaction #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
            generator_to_driver_mailbox, input int number_of_transactions);
            if(generator_to_driver_mailbox == null) begin 
                $fatal(1,"Generator to driver mailbox is null");
            end
        this.generator_to_driver_mailbox = generator_to_driver_mailbox;
        this.number_of_transactions = number_of_transactions;
    endfunction


    task run();
        Transaction #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) tr;
        repeat(number_of_transactions) begin 
            tr = new();
            assert(tr.randomize()) else $fatal(1,"Could not randomize transaction");
            generator_to_driver_mailbox.put(tr);
        end
    endtask


endclass
