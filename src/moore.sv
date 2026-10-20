`timescale 1ns / 1ps

// LockController (FSM Moore) - igual tabla de transicion y codificacion de estados
// que C3/docs/03-lock-controller-moore.md
// (Locked0=000, Locked1=001, Locked2=010, Alarm=011, Unlocked=100)
module moore(
    input  logic clk,
    input  logic reset,
    input  logic match,
    input  logic wrong,
    input  logic l,
    output logic unlock,
    output logic alarm,
    output logic locked,
    output logic [2:0] state_bits   // Q2 Q1 Q0, para los LEDs de debug en la Basys3
);

    typedef enum logic [2:0] {
        LOCKED0  = 3'b000,
        LOCKED1  = 3'b001,
        LOCKED2  = 3'b010,
        ALARM    = 3'b011,
        UNLOCKED = 3'b100
    } statetype;
    statetype state, nextstate;

    // registro de estado
    always_ff @(posedge clk, posedge reset)
        if (reset) state <= LOCKED0;
        else       state <= nextstate;

    // logica de siguiente estado
    always_comb
        case (state)
            LOCKED0: if (match)      nextstate = UNLOCKED;
                     else if (wrong) nextstate = LOCKED1;
                     else            nextstate = LOCKED0;
            LOCKED1: if (match)      nextstate = UNLOCKED;
                     else if (wrong) nextstate = LOCKED2;
                     else            nextstate = LOCKED1;
            LOCKED2: if (match)      nextstate = UNLOCKED;
                     else if (wrong) nextstate = ALARM;
                     else            nextstate = LOCKED2;
            ALARM:   nextstate = ALARM;                  // solo el Reset global saca de aqui
            UNLOCKED: nextstate = l ? LOCKED0 : UNLOCKED;
            default: nextstate = LOCKED0;
        endcase

    // logica de salida (Moore: depende solo del estado)
    assign unlock = (state == UNLOCKED);
    assign alarm  = (state == ALARM);
    assign locked = (state == LOCKED0) || (state == LOCKED1) || (state == LOCKED2);
    assign state_bits = state;

endmodule
