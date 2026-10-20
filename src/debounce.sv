`timescale 1ns / 1ps

// Antirrebote con detector de flanco para el boton de "reloj manual" de la FSM.
// 1) Sincronizador de 2 FF (el boton es una entrada asincrona externa).
// 2) Filtro antirrebote: solo acepta un cambio despues de STABLE_SAMPLES
//    muestras seguidas iguales, muestreadas al ritmo de "sample_en" (que viene
//    de clk_divider, no del reloj de 100MHz directo).
// 3) Detector de flanco de subida -> un pulso de exactamente un ciclo de clk,
//    que es el que uso como "reloj" manual de PinChecker/LockController.
module debounce #(
    parameter integer STABLE_SAMPLES = 8
) (
    input  logic clk,
    input  logic reset,
    input  logic sample_en,
    input  logic btn_raw,
    output logic pulse
);

    localparam integer CWIDTH = $clog2(STABLE_SAMPLES + 1);

    // 1) sincronizador
    logic sync0, sync1;
    always_ff @(posedge clk, posedge reset)
        if (reset) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
        end else begin
            sync0 <= btn_raw;
            sync1 <= sync0;
        end

    // 2) filtro antirrebote
    logic [CWIDTH-1:0] count;
    logic debounced;
    always_ff @(posedge clk, posedge reset)
        if (reset) begin
            count     <= '0;
            debounced <= 1'b0;
        end else if (sample_en) begin
            if (sync1 == debounced) begin
                count <= '0;
            end else if (count == STABLE_SAMPLES - 1) begin
                debounced <= sync1;
                count     <= '0;
            end else begin
                count <= count + 1'b1;
            end
        end

    // 3) detector de flanco de subida
    logic debounced_prev;
    always_ff @(posedge clk, posedge reset)
        if (reset) debounced_prev <= 1'b0;
        else       debounced_prev <= debounced;

    assign pulse = debounced && ~debounced_prev;

endmodule
