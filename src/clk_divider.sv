`timescale 1ns / 1ps

// Divisor de reloj: genera un pulso "tick" de un ciclo cada COUNT ciclos de clk.
// Mismo principio que clck_psc.sv del profesor (contador libre + bit/condicion
// de recarga como salida), pero parametrizado: en la Basys3 (100MHz) COUNT da
// la tasa de muestreo del antirrebote; en simulacion se usa un COUNT chico para
// no tener que esperar milisegundos de tiempo simulado.
module clk_divider #(
    parameter integer COUNT = 100_000   // 100e6/100_000 = 1kHz de muestreo a 100MHz
) (
    input  logic clk,
    input  logic reset,
    output logic tick
);

    localparam integer WIDTH = (COUNT <= 1) ? 1 : $clog2(COUNT);
    logic [WIDTH-1:0] cnt;

    always_ff @(posedge clk, posedge reset)
        if (reset)
            cnt <= '0;
        else if (cnt == COUNT - 1)
            cnt <= '0;
        else
            cnt <= cnt + 1'b1;

    assign tick = (cnt == COUNT - 1);

endmodule
