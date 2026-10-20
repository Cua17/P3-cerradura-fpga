`timescale 1ns / 1ps

// Testbench auto-verificable de "top": compara contra los escenarios de
// C3/tests (PIN correcto, 1/2/3 fallos hasta Alarm, Unlocked->Locked con L,
// Alarm solo sale con Reset) y cubre todas las transiciones de ambas FSM
// (las 8 filas de PinChecker y las 12 de LockController, ver C3/docs).
//
// Usa valores de DEBOUNCE chicos (via parametros de top) para no tener que
// simular milisegundos reales de antirrebote.
module testbench;

    localparam integer CLK_PERIOD   = 10;   // 100MHz
    localparam integer SAMPLE_COUNT = 10;   // tick de muestreo cada 10 ciclos
    localparam integer STABLE       = 4;    // 4 muestras estables para debounce
    localparam integer SETTLE       = SAMPLE_COUNT * (STABLE + 2);

    logic clk100mhz = 1'b0;
    logic btn_reset, btn_step, btn_l, sw_d;
    logic led_unlock, led_alarm, led_locked, led_match, led_wrong;
    logic [1:0] led_mealy_state;
    logic [2:0] led_moore_state;

    int pass_count = 0;
    int fail_count = 0;

    top #(
        .DEBOUNCE_SAMPLE_COUNT  (SAMPLE_COUNT),
        .DEBOUNCE_STABLE_SAMPLES(STABLE)
    ) dut (
        .clk100mhz       (clk100mhz),
        .btn_reset       (btn_reset),
        .btn_step        (btn_step),
        .btn_l           (btn_l),
        .sw_d            (sw_d),
        .led_unlock      (led_unlock),
        .led_alarm       (led_alarm),
        .led_locked      (led_locked),
        .led_match       (led_match),
        .led_wrong       (led_wrong),
        .led_mealy_state (led_mealy_state),
        .led_moore_state (led_moore_state)
    );

    always #(CLK_PERIOD / 2) clk100mhz = ~clk100mhz;

    task automatic wait_cycles(input int n);
        repeat (n) @(posedge clk100mhz);
    endtask

    task automatic do_reset();
        btn_reset = 1'b1;
        wait_cycles(5);
        btn_reset = 1'b0;
        wait_cycles(5);
    endtask

    // "aprieta" el boton de reloj manual el tiempo suficiente para que el
    // antirrebote lo registre y genere exactamente un pulso de fsm_clk,
    // despues lo suelta el tiempo suficiente para que el siguiente apriete
    // cuente como un flanco nuevo
    task automatic press_step(input logic d_val);
        sw_d = d_val;
        wait_cycles(5);          // margen para el sincronizador de D
        btn_step = 1'b1;
        wait_cycles(SETTLE);
        btn_step = 1'b0;
        wait_cycles(SETTLE);
    endtask

    task automatic check(input string label,
                          input logic exp_unlock, input logic exp_alarm, input logic exp_locked,
                          input logic [1:0] exp_mealy, input logic [2:0] exp_moore);
        if (led_unlock === exp_unlock && led_alarm === exp_alarm && led_locked === exp_locked &&
            led_mealy_state === exp_mealy && led_moore_state === exp_moore) begin
            $display("PASS - %s", label);
            pass_count++;
        end else begin
            $display("FAIL - %s | esperado unlock=%b alarm=%b locked=%b mealy=%b moore=%b | obtenido unlock=%b alarm=%b locked=%b mealy=%b moore=%b",
                      label, exp_unlock, exp_alarm, exp_locked, exp_mealy, exp_moore,
                      led_unlock, led_alarm, led_locked, led_mealy_state, led_moore_state);
            fail_count++;
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, testbench);
    end

    initial begin
        btn_reset = 1'b1;
        btn_step  = 1'b0;
        btn_l     = 1'b0;
        sw_d      = 1'b0;
        wait_cycles(5);

        // ------------------------------------------------------------
        // Escenario A: PIN correcto al primer intento (4 digitos OK)
        // ------------------------------------------------------------
        do_reset();
        check("A0 - reset: Locked0, S0", 0, 0, 1, 2'b00, 3'b000);
        press_step(1); check("A1 - D=1: S0->S1, Locked0 sin match/wrong", 0, 0, 1, 2'b01, 3'b000);
        press_step(1); check("A2 - D=1: S1->S2, Locked0 sin match/wrong", 0, 0, 1, 2'b10, 3'b000);
        press_step(1); check("A3 - D=1: S2->S3, Locked0 sin match/wrong", 0, 0, 1, 2'b11, 3'b000);
        press_step(1); check("A4 - D=1: S3->S0 match=1, Locked0->Unlocked", 1, 0, 0, 2'b00, 3'b100);

        // ------------------------------------------------------------
        // Escenario B: un fallo (en S1) y despues PIN correcto
        // ------------------------------------------------------------
        do_reset();
        press_step(1); check("B1 - D=1: S0->S1", 0, 0, 1, 2'b01, 3'b000);
        press_step(0); check("B2 - D=0 en S1: S1->S0 wrong=1, Locked0->Locked1", 0, 0, 1, 2'b00, 3'b001);
        press_step(1); check("B3 - D=1: S0->S1, Locked1 sin cambio", 0, 0, 1, 2'b01, 3'b001);
        press_step(1); check("B4 - D=1: S1->S2", 0, 0, 1, 2'b10, 3'b001);
        press_step(1); check("B5 - D=1: S2->S3", 0, 0, 1, 2'b11, 3'b001);
        press_step(1); check("B6 - D=1: S3->S0 match=1, Locked1->Unlocked", 1, 0, 0, 2'b00, 3'b100);

        // ------------------------------------------------------------
        // Escenario C: dos fallos (en S1 y en S2) y despues PIN correcto
        // ------------------------------------------------------------
        do_reset();
        press_step(1); check("C1 - D=1: S0->S1", 0, 0, 1, 2'b01, 3'b000);
        press_step(0); check("C2 - D=0 en S1: S1->S0 wrong=1, Locked0->Locked1", 0, 0, 1, 2'b00, 3'b001);
        press_step(1); check("C3 - D=1: S0->S1", 0, 0, 1, 2'b01, 3'b001);
        press_step(1); check("C4 - D=1: S1->S2", 0, 0, 1, 2'b10, 3'b001);
        press_step(0); check("C5 - D=0 en S2: S2->S0 wrong=1, Locked1->Locked2", 0, 0, 1, 2'b00, 3'b010);
        press_step(1); check("C6 - D=1: S0->S1", 0, 0, 1, 2'b01, 3'b010);
        press_step(1); check("C7 - D=1: S1->S2", 0, 0, 1, 2'b10, 3'b010);
        press_step(1); check("C8 - D=1: S2->S3", 0, 0, 1, 2'b11, 3'b010);
        press_step(1); check("C9 - D=1: S3->S0 match=1, Locked2->Unlocked", 1, 0, 0, 2'b00, 3'b100);

        // ------------------------------------------------------------
        // Escenario D: fallo justo antes de completar el PIN (en S3)
        // ------------------------------------------------------------
        do_reset();
        press_step(1); check("D1 - D=1: S0->S1", 0, 0, 1, 2'b01, 3'b000);
        press_step(1); check("D2 - D=1: S1->S2", 0, 0, 1, 2'b10, 3'b000);
        press_step(1); check("D3 - D=1: S2->S3", 0, 0, 1, 2'b11, 3'b000);
        press_step(0); check("D4 - D=0 en S3: S3->S0 wrong=1, Locked0->Locked1", 0, 0, 1, 2'b00, 3'b001);

        // ------------------------------------------------------------
        // Escenario E: tres fallos seguidos -> Alarm (igual tabla que
        // C3/docs/04-verificacion.md), despues un PIN "correcto" que
        // la alarma debe ignorar
        // ------------------------------------------------------------
        do_reset();
        press_step(0); check("E1 - D=0: Locked0->Locked1", 0, 0, 1, 2'b00, 3'b001);
        press_step(0); check("E2 - D=0: Locked1->Locked2", 0, 0, 1, 2'b00, 3'b010);
        press_step(0); check("E3 - D=0: Locked2->Alarm",   0, 1, 0, 2'b00, 3'b011);
        press_step(1); check("E4 - D=1 en Alarm: se ignora, sigue Alarm", 0, 1, 0, 2'b01, 3'b011);
        press_step(1); check("E5 - D=1 en Alarm: se ignora, sigue Alarm", 0, 1, 0, 2'b10, 3'b011);
        press_step(1); check("E6 - D=1 en Alarm: se ignora, sigue Alarm", 0, 1, 0, 2'b11, 3'b011);
        press_step(1); check("E7 - D=1 en Alarm: match=1 pero Alarm NO abre", 0, 1, 0, 2'b00, 3'b011);

        // ------------------------------------------------------------
        // Escenario F: el Reset global es lo unico que saca de Alarm
        // ------------------------------------------------------------
        do_reset();
        check("F1 - Reset saca de Alarm: vuelve a Locked0, S0", 0, 0, 1, 2'b00, 3'b000);

        // ------------------------------------------------------------
        // Escenario G: abre y se re-bloquea con L (no vuelve a Locked2,
        // cada intento nuevo empieza limpio)
        // ------------------------------------------------------------
        do_reset();
        press_step(1); press_step(1); press_step(1);
        press_step(1); check("G1 - PIN correcto: Unlocked", 1, 0, 0, 2'b00, 3'b100);
        btn_l = 1'b0;
        press_step(0); check("G2 - Unlocked, L=0: se queda Unlocked", 1, 0, 0, 2'b00, 3'b100);
        btn_l = 1'b1;
        press_step(0); check("G3 - Unlocked, L=1: vuelve a Locked0 (no Locked2)", 0, 0, 1, 2'b00, 3'b000);
        btn_l = 1'b0;

        // ------------------------------------------------------------
        $display("\n==================================================");
        $display("RESULTADO: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0) $display("TESTBENCH: PASS");
        else                 $display("TESTBENCH: FAIL");
        $display("==================================================");
        $finish;
    end

endmodule
