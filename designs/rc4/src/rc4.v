`timescale 1ns/1ps

module rc4(
    input wire CLK_IN,
    input wire RESET_N_IN,
    input wire [7:0] KEY_SIZE_IN,
`timescale 1ns/1ps

module rc4(
    input wire CLK_IN,
    input wire RESET_N_IN,
    input wire [7:0] KEY_SIZE_IN,
    input wire [7:0] KEY_BYTE_IN,
    input wire [7:0] PLAIN_BYTE_IN,
    input wire START_IN,
    input wire STOP_IN,
    input wire HOLD_IN,
    output reg START_KEY_CPY_OUT,
    output reg BUSY_OUT,
    output reg READ_PLAINTEXT_OUT,
    output reg [7:0] ENC_BYTE_OUT
);

    localparam INIT  = 3'd0;
    localparam IDLE  = 3'd1;
    localparam COPY  = 3'd2;
    localparam KSA   = 3'd3;
    localparam PRGA  = 3'd4;

    reg [2:0] state;
    reg [7:0] S [0:255];
    reg [7:0] key [0:31];    input wire [7:0] KEY_BYTE_IN,
    input wire [7:0] PLAIN_BYTE_IN,
    input wire START_IN,
    input wire STOP_IN,
    input wire HOLD_IN,
    output reg START_KEY_CPY_OUT,
    output reg BUSY_OUT,
    output reg READ_PLAINTEXT_OUT,
    output reg [7:0] ENC_BYTE_OUT
);

    localparam INIT  = 3'd0;
    localparam IDLE  = 3'd1;
    localparam COPY  = 3'd2;
    localparam KSA   = 3'd3;
    localparam PRGA  = 3'd4;

    reg [2:0] state;
    reg [7:0] S [0:255];
    reg [7:0] key [0:31];

    reg [7:0] init_i;
    reg [7:0] copy_i;
    reg [7:0] key_len;
    reg [7:0] key_i;
    reg [7:0] ksa_i;
    reg [7:0] ksa_j;
    reg [7:0] prga_i;
    reg [7:0] prga_j;

    reg [7:0] next_i;
    reg [7:0] next_j;
    reg [7:0] value_i;
    reg [7:0] value_j;
    reg [7:0] output_index;

    always @(posedge CLK_IN) begin
        if (!RESET_N_IN || STOP_IN) begin
            state <= INIT;
            init_i <= 0;
            copy_i <= 0;
            key_len <= 1;
            key_i <= 0;
            ksa_i <= 0;
            ksa_j <= 0;
            prga_i <= 0;
            prga_j <= 0;

            START_KEY_CPY_OUT <= 0;
            BUSY_OUT <= 0;
            READ_PLAINTEXT_OUT <= 0;
            ENC_BYTE_OUT <= 0;
        end
        else begin
            case (state)

                INIT: begin
                    S[init_i] <= init_i;

                    if (init_i == 8'hff) begin
                        state <= IDLE;
                        init_i <= 0;
                    end
                    else begin
                        init_i <= init_i + 1;
                    end
                end

                IDLE: begin
                    BUSY_OUT <= 0;
                    READ_PLAINTEXT_OUT <= 0;

                    if (START_IN) begin
                       state <= COPY;
                        BUSY_OUT <= 1;
                        START_KEY_CPY_OUT <= 1;
                        copy_i <= 0;
                    end
                end
              COPY: begin
                    if (START_KEY_CPY_OUT) begin
                        START_KEY_CPY_OUT <= 0;

                        if (KEY_SIZE_IN == 0)
                            key_len <= 1;
                        else if (KEY_SIZE_IN > 32)
                            key_len <= 32;
                        else
                            key_len <= KEY_SIZE_IN;
                    end
                    else begin
                        key[copy_i] <= KEY_BYTE_IN;

                        if (copy_i == key_len - 1) begin
                            state <= KSA;
                            ksa_i <= 0;
                            ksa_j <= 0;
                            key_i <= 0;
                        end
                        else begin
                            copy_i <= copy_i + 1;
                        end
                    end
                end
               KSA: begin
                    next_j = ksa_j + S[ksa_i] + key[key_i];

                    value_i = S[ksa_i];
                    value_j = S[next_j];

                    S[ksa_i] <= value_j;
                    S[next_j] <= value_i;

                    ksa_j <= next_j;

                    if (key_i == key_len - 1)
                        key_i <= 0;
                    else
                        key_i <= key_i + 1;

                    if (ksa_i == 8'hff) begin
                        state <= PRGA;
                        prga_i <= 0;
                        prga_j <= 0;
                        READ_PLAINTEXT_OUT <= 1;
                    end
                    else begin
                        ksa_i <= ksa_i + 1;
                    end
                end

                PRGA: begin
                    if (!HOLD_IN) begin
                        next_i = prga_i + 1;
                        next_j = prga_j + S[next_i];
                        value_i = S[next_i];
                        value_j = S[next_j];

                        S[next_i] <= value_j;
                        S[next_j] <= value_i;

                        output_index = value_i + value_j;
                        ENC_BYTE_OUT <= S[output_index] ^ PLAIN_BYTE_IN;

                        prga_i <= next_i;
                        prga_j <= next_j;
                    end
                end

                default: begin
                    state <= INIT;
                end

            endcase
        end
    end

endmodule
