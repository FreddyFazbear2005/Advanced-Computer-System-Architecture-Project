
module data_array #
(
    parameter NUM_SETS   = 8,
    parameter NUM_WAYS   = 2,
    parameter DATA_WIDTH = 32,
    localparam INDEX_WIDTH = $clog2(NUM_SETS)
)
(
    input clk,
    input rst,

    //=========================================================
    // READ PORT
    //=========================================================

    input [INDEX_WIDTH-1:0] rd_index,

    output reg [DATA_WIDTH-1:0] data_way0,
    output reg [DATA_WIDTH-1:0] data_way1,

    //=========================================================
    // WRITE PORT
    //=========================================================

    input write_en,

    input write_way,

    input [INDEX_WIDTH-1:0] wr_index,

    input [DATA_WIDTH-1:0] wr_data
);

    //=========================================================
    // DATA STORAGE
    //=========================================================

    reg [DATA_WIDTH-1:0] data_mem
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

            for(i = 0; i < NUM_SETS; i = i + 1)
            begin

                for(j = 0; j < NUM_WAYS; j = j + 1)
                begin

                    data_mem[i][j] <= {DATA_WIDTH{1'b0}};

                end

            end

        end

        else
        begin

            if(write_en)
            begin

                data_mem[wr_index][write_way] <= wr_data;

            end

        end

    end

    //=========================================================
    // READ PORT
    //=========================================================

    always @(*)
    begin

        data_way0 = data_mem[rd_index][0];
        data_way1 = data_mem[rd_index][1];

    end

endmodule
