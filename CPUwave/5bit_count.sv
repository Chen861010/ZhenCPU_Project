module counter (
    input  logic [4:0] data,      // 5-bit input value to be loaded into the counter
    input  logic load,            // Load control signal (active high)
    input  logic enable,          // Enable signal to increment the counter (active high)
    input  logic clk,             // Clock signal (positive-edge triggered)
    input  logic rst_,            // Asynchronous reset, active low
    output logic [4:0] count      // 5-bit counter output
);

    // Sequential logic: asynchronous active-low reset, otherwise update on posedge clk
    always_ff @(posedge clk or negedge rst_) begin
        if (!rst_) begin
            // When reset is asserted (low), force counter to 0
            count <= 5'd0;
        end
        else if (load) begin
            // When load is asserted, load the 5-bit input data into the counter
            count <= data;
        end
        else if (enable) begin
            // When enable is asserted (and load is not), increment the counter by 1
            count <= count + 1'b1;
        end
        // If none of the above conditions are true:
        // The counter automatically retains its current value (no assignment needed)
    end

endmodule

