`timescale 1ns / 1ps

// Top level para la Basys3: instancia PinChecker (mealy) y LockController (moore),
// con el divisor de reloj + antirrebote generando el paso manual de la FSM a partir
// del boton de "reloj" fisico. D es un switch, L y Reset son botones.
//
// DEBOUNCE_SAMPLE_COUNT y DEBOUNCE_STABLE_SAMPLES quedan como parametros para poder
// usar valores chicos en el testbench (ver sim/testbench.sv) y los valores reales
// para la sintesis hacia la Basys3 (100MHz).
module top #(
    parameter integer DEBOUNCE_SAMPLE_COUNT   = 100_000,  // 1kHz de muestreo a 100MHz
    parameter integer DEBOUNCE_STABLE_SAMPLES = 8
) (
    input  logic clk100mhz,
    input  logic btn_reset,     // boton central: reset asincrono global
    input  logic btn_step,      // boton con antirrebote: reloj manual de ambas FSM
    input  logic btn_l,         // boton: L (re-bloquear desde Unlocked)
    input  logic sw_d,          // switch: D (digito correcto/incorrecto)

    output logic led_unlock,
    output logic led_alarm,
    output logic led_locked,
    output logic led_match,
    output logic led_wrong,
    output logic [1:0] led_mealy_state,
    output logic [2:0] led_moore_state
);

    logic sample_en;
    logic fsm_clk;

    logic sync_l_0, sync_l_1;
    logic sync_d_0, sync_d_1;

    logic match, wrong;

    // divisor de reloj: genera el tick de muestreo que usa el antirrebote
    clk_divider #(
        .COUNT(DEBOUNCE_SAMPLE_COUNT)
    ) u_clk_divider (
        .clk   (clk100mhz),
        .reset (btn_reset),
        .tick  (sample_en)
    );

    // antirrebote + detector de flanco del boton de "reloj manual"
    debounce #(
        .STABLE_SAMPLES(DEBOUNCE_STABLE_SAMPLES)
    ) u_debounce (
        .clk       (clk100mhz),
        .reset     (btn_reset),
        .sample_en (sample_en),
        .btn_raw   (btn_step),
        .pulse     (fsm_clk)
    );

    // sincronizadores simples (2 FF) para D y L: son niveles que solo se leen
    // en el flanco de fsm_clk, mucho mas lento que cualquier rebote humano, asi
    // que alcanza con protegerlos de metaestabilidad sin filtro adicional
    always_ff @(posedge clk100mhz, posedge btn_reset)
        if (btn_reset) begin
            sync_d_0 <= 1'b0;
            sync_d_1 <= 1'b0;
            sync_l_0 <= 1'b0;
            sync_l_1 <= 1'b0;
        end else begin
            sync_d_0 <= sw_d;
            sync_d_1 <= sync_d_0;
            sync_l_0 <= btn_l;
            sync_l_1 <= sync_l_0;
        end

    mealy u_mealy (
        .clk        (fsm_clk),
        .reset      (btn_reset),
        .d          (sync_d_1),
        .match      (match),
        .wrong      (wrong),
        .state_bits (led_mealy_state)
    );

    moore u_moore (
        .clk        (fsm_clk),
        .reset      (btn_reset),
        .match      (match),
        .wrong      (wrong),
        .l          (sync_l_1),
        .unlock     (led_unlock),
        .alarm      (led_alarm),
        .locked     (led_locked),
        .state_bits (led_moore_state)
    );

    assign led_match = match;
    assign led_wrong = wrong;

endmodule
