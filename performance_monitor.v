
module performance_monitor
(
    input clk,
    input rst,

    //=========================================================
    // EVENT INPUTS
    //=========================================================

    input read_event,
    input write_event,

    input hit_event,
    input miss_event,

    input eviction_event,
    input writeback_event,

    //=========================================================
    // PERFORMANCE COUNTERS
    //=========================================================

    output reg [31:0] read_count,
    output reg [31:0] write_count,

    output reg [31:0] hit_count,
    output reg [31:0] miss_count,

    output reg [31:0] eviction_count,
    output reg [31:0] writeback_count,

    output reg [31:0] transaction_count
);

    //---------------------------------------------------------
    // COUNTERS
    //---------------------------------------------------------

    always @(posedge clk)
    begin

        if(rst)
        begin

            read_count        <= 32'd0;
            write_count       <= 32'd0;

            hit_count         <= 32'd0;
            miss_count        <= 32'd0;

            eviction_count    <= 32'd0;
            writeback_count   <= 32'd0;

            transaction_count <= 32'd0;

        end

        else
        begin

            if(read_event)
            begin
                read_count <= read_count + 1'b1;
                transaction_count <= transaction_count + 1'b1;
            end

            if(write_event)
            begin
                write_count <= write_count + 1'b1;
                transaction_count <= transaction_count + 1'b1;
            end

            if(hit_event)
            begin
                hit_count <= hit_count + 1'b1;
            end

            if(miss_event)
            begin
                miss_count <= miss_count + 1'b1;
            end

            if(eviction_event)
            begin
                eviction_count <= eviction_count + 1'b1;
            end

            if(writeback_event)
            begin
                writeback_count <= writeback_count + 1'b1;
            end

        end

    end

endmodule
