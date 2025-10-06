`timescale 1ps/1ps

module tb_slave_splitter;

    localparam int TOTAL_SAMPLES  = 733824;

    logic clk;
    logic rst_n;

    logic [63:0] all_samples [0:TOTAL_SAMPLES-1];
    logic [63:0] sample_in;
    logic        sample_valid;

    logic        slave_ready;
    logic [31:0] port1_data;
    logic        port1_valid;
    logic [31:0] port2_data;
    logic        port2_valid;

    logic [63:0] dbg_mem_data;
    int          dbg_sample_idx;
    logic        dbg_active_phase;

    slave_splitter dut (
        .clk(clk),
        .rst_n(rst_n),
        .sample_valid(sample_valid),
        .sample_in(sample_in),
        .slave_ready(slave_ready),
        .port1_data(port1_data),
        .port1_valid(port1_valid),
        .port2_data(port2_data),
        .port2_valid(port2_valid),
        .dbg_mem_data(dbg_mem_data),
        .dbg_sample_idx(dbg_sample_idx),
        .dbg_active_phase(dbg_active_phase)
    );

    initial clk = 0;
    always #1 clk = ~clk; // 100 MHz clock

    initial begin
        $display("Loading input samples...");
        $readmemh("C:/Users/Satish/task on data splitter/input_data.txt", all_samples);
        $display("Finished loading samples.");
    end

    initial begin
        rst_n = 0;
        sample_in = 0;
        sample_valid = 0;
        #1;
        rst_n = 1;

        // Feed samples continuously
        fork
            feed_samples();
        join

        $display("Simulation finished.");
        $stop;
    end

    task feed_samples;
        int i;
        begin
            wait(rst_n);
            @(posedge clk);
            for (i = 0; i < TOTAL_SAMPLES; i++) begin
                @(posedge clk);
                sample_in <= all_samples[i];
                sample_valid <= 1;
            end
            sample_valid <= 0;
        end
    endtask

endmodule
