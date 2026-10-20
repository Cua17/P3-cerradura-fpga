`timescale 1ns / 1ps

// PinChecker (FSM Mealy) - igual tabla de transicion y codificacion de estados
// que C3/docs/02-pin-checker-mealy.md (S0=00, S1=01, S2=10, S3=11)
module mealy(
    input  logic clk,
    input  logic reset,
    input  logic d,
    output logic match,
    output logic wrong,
    output logic [1:0] state_bits   // Q1 Q0, para los LEDs de debug en la Basys3
);

    typedef enum logic [1:0] {S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11} statetype;
    statetype state, nextstate;

    // registro de estado
    always_ff @(posedge clk, posedge reset)
        if (reset) state <= S0;
        else       state <= nextstate;

    // logica de siguiente estado
    always_comb
        case (state)
            S0: nextstate = d ? S1 : S0;
            S1: nextstate = d ? S2 : S0;
            S2: nextstate = d ? S3 : S0;
            S3: nextstate = d ? S0 : S0;
        endcase

    // logica de salida (Mealy: depende de estado Y entrada)
    assign match = d && (state == S3);
    assign wrong = ~d;
    assign state_bits = state;

endmodule
