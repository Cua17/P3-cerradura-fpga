# P3 — Cerradura electrónica con código PIN, de compuertas a FPGA

**Landing:** https://cua17.github.io/P3-cerradura-fpga/ · **Video:** https://youtu.be/9dUmtvlsK-4

Parcial 3 (parte práctica) de Arquitectura de Computadoras: tomo la FSM que diseñé para
el Parcial 2 ([C3](https://github.com/Cua17/C3-cerradura-fsm) — `PinChecker` Mealy y
`LockController` Moore) y la llevo por los tres pasos que pide el parcial: análisis de
timing con compuertas reales, migración a SystemVerilog con simulación en Vivado, y
programación real en una tarjeta Basys3.

José Daniel Cuá Fagiani — Carné 21200

## Contenido

1. [Timing — tramo FF a FF con compuertas reales de Digikey](docs/01-timing.md)
2. [HDL — jerarquía SystemVerilog, testbench y simulación](docs/02-hdl.md)
3. [Vivado — de RTL a bitstream, con mis datos reales](docs/03-vivado.md)
4. [Basys3 — programación y demostración](docs/04-basys3.md)
5. [Tabla de cumplimiento del parcial](docs/05-cumplimiento.md)

## Resultados principales

| Parte | Resultado |
|---|---|
| Timing discreto (2× AND3 + 2× OR2 + flip-flop, familia 74LVC a 1.8V) | Fc ≈ 15.0 MHz, hold cumple con 16.2 ns de margen |
| Testbench (`xvlog`/`xelab`/`xsim`, sin GUI) | 35/35 PASS, sin warnings |
| Síntesis e implementación (Vivado 2026.1, Artix-7 XC7A35T) | 29 LUTs, 35 FFs, WNS = 4.9 ns, WHS = 0.19 ns a 100MHz — [`docs/03-vivado.md`](docs/03-vivado.md) |
| Basys3 | Programada y probada en placa real (reset, PIN correcto, 3 fallos → alarma) — [`docs/04-basys3.md`](docs/04-basys3.md) |

## Estructura del repositorio

```
src/          mealy.sv, moore.sv, clk_divider.sv, debounce.sv, top.sv
sim/          testbench.sv (auto-verificable, 35 checks)
constraints/  basys3.xdc (pines verificados contra el master.xdc oficial de Digilent)
bitstream/    p3_cerradura.bit
docs/         timing, HDL, discusión de Vivado, Basys3, tabla de cumplimiento
img/          capturas de datasheets, diagramas, waveform de la simulación
```

## Cómo reproducir

- **Simulación** (sin Vivado GUI): `xvlog --sv src/*.sv sim/testbench.sv`, después
  `xelab testbench -s testbench_sim` y `xsim testbench_sim -runall`. Tiene que terminar
  en `TESTBENCH: PASS`.
- **Síntesis/implementación/bitstream**: `vivado -mode batch -source vivado_build/build.tcl`
  (ajustando las rutas del script a donde tengas el repo). Genera los reportes de
  utilización y timing y `bitstream/p3_cerradura.bit`.
- **Programar la Basys3**: con la placa conectada, ver las instrucciones en
  [`docs/04-basys3.md`](docs/04-basys3.md).

## Video

Explicación completa del parcial — timing, HDL, simulación, Vivado y demostración en la
Basys3: https://youtu.be/9dUmtvlsK-4

## Herramientas usadas

- **Vivado 2026.1** (AMD/Xilinx) para síntesis, implementación, simulación por línea de
  comandos (`xvlog`/`xelab`/`xsim`) y programación de la Basys3.
- **Python** (script independiente, no versionado) para verificar la aritmética de
  timing del punto 1, y para renderizar la waveform de la simulación a partir del VCD.
- Mismo criterio de la fase anterior ([C2](https://github.com/Cua17/C2-manejo-bases-datos)
  y [C3](https://github.com/Cua17/C3-cerradura-fsm)): datasheets reales de Digikey/TI,
  nada inventado.
