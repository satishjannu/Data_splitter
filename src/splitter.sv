module slave_splitter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sample_valid,    // input sample valid
    input  logic [63:0] sample_in,       // input sample

    output logic        slave_ready,     // always ready for input
    output logic [31:0] port1_data,
    output logic        port1_valid,
    output logic [31:0] port2_data,
    output logic        port2_valid,

    // Debug signals
    output logic [63:0] dbg_mem_data,
    output int          dbg_sample_idx,
    output logic        dbg_active_phase
);

    // ------------------------------
    // Parameters
    // ------------------------------
    localparam int TOTAL_SAMPLES  = 733824;
    localparam int ACTIVE_SAMPLES = 3276;
    localparam int IDLE_SAMPLES   = 1176;

    // ------------------------------
    // Internal state
    // ------------------------------
    int unsigned rd_idx;   
    int unsigned wr_idx;   
    int          phase_count;
    logic        active_phase;

    logic [63:0] mem [0:TOTAL_SAMPLES-1];

    // ------------------------------
    // Sequential logic
    // ------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slave_ready      <= 0;
            port1_data       <= 32'h0;
            port2_data       <= 32'h0;
            port1_valid      <= 0;
            port2_valid      <= 0;
            rd_idx           <= 0;
            wr_idx           <= 0;
            phase_count      <= 0;
            active_phase     <= 1;
            dbg_mem_data     <= 0;
            dbg_sample_idx   <= 0;
            dbg_active_phase <= 0;
        end else begin
            // Always ready for input
            slave_ready      <= 1;
            dbg_active_phase <= active_phase;

            // ---------------------------
            // Write incoming sample to memory
            // ---------------------------
            if (sample_valid && slave_ready) begin
                mem[wr_idx] <= sample_in;
                if (wr_idx == TOTAL_SAMPLES-1)
                    wr_idx <= 0;
                else
                    wr_idx <= wr_idx + 1;
            end

            // ---------------------------
            // Active phase: output one sample per clock
            // ---------------------------
            if (active_phase) begin
                if (rd_idx != wr_idx) begin
                    // Valid sample available in memory
                    port1_data   <= mem[rd_idx][63:32];
                    port2_data   <= mem[rd_idx][31:0];
                    port1_valid  <= 1;
                    port2_valid  <= 1;
                    dbg_mem_data <= mem[rd_idx];
                    dbg_sample_idx <= rd_idx;

                    // Advance read pointer
                    if (rd_idx == TOTAL_SAMPLES-1)
                        rd_idx <= 0;
                    else
                        rd_idx <= rd_idx + 1;

                    // Phase counter increment
                    if (phase_count == ACTIVE_SAMPLES-1) begin
                        phase_count  <= 0;
                        active_phase <= 0; // switch to idle
                    end else begin
                        phase_count <= phase_count + 1;
                    end
                end else begin
                    // No data yet, valid low
                    port1_valid <= 0;
                    port2_valid <= 0;
                end
            end
            // ---------------------------
            // Idle phase: outputs low
            // ---------------------------
            else begin
                port1_data   <= 0;
                port2_data   <= 0;
                port1_valid  <= 0;
                port2_valid  <= 0;
                dbg_mem_data <= 64'h0;

                if (phase_count == IDLE_SAMPLES-1) begin
                    phase_count  <= 0;
                    active_phase <= 1; // switch to active
                end else begin
                    phase_count <= phase_count + 1;
                end
            end
        end
    end

endmodule
