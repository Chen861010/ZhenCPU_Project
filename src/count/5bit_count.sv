timeunit 1ns;
timeprecision 100ps;
module counter (
    input  logic [4:0] data,     // 5-bit
    input  logic load,
    input  logic enable,
    input  logic clk,
    input  logic rst_,           // active low async reset
    output logic [4:0] count     // 5-bit
);

    always_ff @(posedge clk or negedge rst_) begin
        if (!rst_)               // reset active low
            count <= 5'd0;       // reset to 0
        else if (load)
            count <= data;       // load data
        else if (enable)
            count <= count + 1'b1; // increment
        // else: 保持原值，自動完成
    end

endmodule
