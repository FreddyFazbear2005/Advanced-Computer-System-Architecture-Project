
module tag_array #
(
    parameter NUM_SETS   = 8,
    parameter NUM_WAYS   = 2,
    parameter TAG_WIDTH  = 7,
    localparam INDEX_WIDTH = $clog2(NUM_SETS)
)
(
    input clk,
    input rst,

    // Read Port
    input  [INDEX_WIDTH-1:0] rd_index,

    output reg [TAG_WIDTH-1:0] tag_way0,
    output reg [TAG_WIDTH-1:0] tag_way1,

    output reg valid_way0,
    output reg valid_way1,

    output reg dirty_way0,
    output reg dirty_way1,

    // Write Port
    input write_en,

    input write_way,

    input [INDEX_WIDTH-1:0] wr_index,

    input [TAG_WIDTH-1:0] wr_tag,

    input wr_valid,

    input wr_dirty
);

    //=========================================================
    // TAG STORAGE
    //=========================================================

    reg [TAG_WIDTH-1:0] tag_mem
        [0:NUM_SETS-1][0:NUM_WAYS-1];

    reg valid_mem
        [0:NUM_SETS-1][0:NUM_WAYS-1];

    reg dirty_mem
        [0:NUM_SETS-1][0:NUM_WAYS-1];

    integer i;
    integer j;

    //=========================================================
    // RESET + WRITE
    //=========================================================

    always @(posedge clk)
    begin

        if(rst)
        begin

            for(i=0;i<NUM_SETS;i=i+1)
            begin

                for(j=0;j<NUM_WAYS;j=j+1)
                begin

                    tag_mem[i][j]   <= 0;
                    valid_mem[i][j] <= 0;
                    dirty_mem[i][j] <= 0;

                end

            end

        end

        else
        begin

            if(write_en)
            begin

                tag_mem[wr_index][write_way]   <= wr_tag;

                valid_mem[wr_index][write_way] <= wr_valid;

                dirty_mem[wr_index][write_way] <= wr_dirty;

            end

        end

    end

    //=========================================================
    // READ PORT
    //=========================================================

    always @(*)
    begin

        tag_way0 = tag_mem[rd_index][0];
        tag_way1 = tag_mem[rd_index][1];

        valid_way0 = valid_mem[rd_index][0];
        valid_way1 = valid_mem[rd_index][1];

        dirty_way0 = dirty_mem[rd_index][0];
        dirty_way1 = dirty_mem[rd_index][1];

    end

endmodule
