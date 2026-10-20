# Vivado — de RTL a bitstream, con mis datos reales

Vivado funciona como un compilador: a cada paso va acercando mi SystemVerilog a algo que
físicamente se puede grabar en la Artix-7. Corrí todo por línea de comandos en modo batch
(`vivado -mode batch -source vivado_build/build.tcl`), sin la GUI, y acá documento cada
etapa con los reportes reales que generó esa corrida — no con el comportamiento genérico
de la herramienta.

## 1. RTL Analysis — elaboración, sin tecnología todavía

Esta es la primera fase de `synth_design`: Vivado lee mi SystemVerilog y lo eleva a una
representación genérica — todavía no sabe nada de LUTs, flip-flops reales ni de la
Artix-7, solo ve "esto es un sumador", "esto es un registro", "esto es un mux". El
reporte de componentes RTL de mi propio `top` (antes de cualquier mapeo a tecnología):

```
+---Adders :
       2 Input   17 Bit       Adders := 1       (el contador de clk_divider)
       2 Input    4 Bit       Adders := 1       (el contador de debounce)
+---Registers :
                  17 Bit    Registers := 1       (cnt de clk_divider)
                   4 Bit    Registers := 1       (count de debounce)
                   1 Bit    Registers := 8        (sync_d_0/1, sync_l_0/1, debounced,
                                                     debounced_prev, y los bits de estado
                                                     de las FSM elaborados como registros
                                                     sueltos de 1 bit)
+---Muxes :
   5 Input    5 Bit        Muxes := 1             (case de LockController, 5 ramas)
   2 Input    5 Bit        Muxes := 7
   5 Input    3 Bit        Muxes := 1
   ...
```

Esto es exactamente lo que esperaba ver: Vivado reconoció mis dos `case` (el de 4 ramas de
`mealy` y el de 5 ramas de `moore`) como estructuras de mux genéricas, y mis dos
contadores (`clk_divider`, `debounce`) como sumadores genéricos — todavía sin decidir si
eso se va a implementar con LUTs, con la lógica de acarreo dedicada de la Artix-7, o de
otra forma. Esa decisión es el siguiente paso. (No me cuadra exactamente a qué señal
corresponde cada uno de esos 8 registros de 1 bit sin ver el netlist elaborado en la GUI —
lo dejo como lectura cualitativa de la etapa, no como un mapeo exacto señal por señal.)

## 2. Synthesis — mapeo a primitivas reales de la Artix-7

Acá Vivado traduce esa representación genérica a las primitivas que existen físicamente
en el XC7A35T: LUTs (de hasta 6 entradas), flip-flops, y la lógica de acarreo dedicada
(`CARRY4`) para los sumadores. Resultado real de mi diseño (`report_utilization` tras
`synth_design`, antes de optimizar para la implementación):

| Recurso | Usado | Disponible | % |
|---|---|---|---|
| Slice LUTs | 26 | 20800 | 0.13% |
| Slice Registers | 35 | 41600 | 0.08% |

Esos 35 registros son razonables: entre las dos FSM (2 + 3 bits de estado), los dos
contadores (17 bits de `clk_divider`, 4 bits de `debounce`), los flip-flops internos de
`debounce` (sincronizador, `debounced`, `debounced_prev`) y los sincronizadores de `D` y
`L` en `top` ya se explica casi todo el total — intenté cuadrar el conteo bit a bit contra
el reporte jerárquico (`report_utilization -hierarchical`), pero para un diseño tan chico
Vivado aplana la jerarquía al sintetizar (la tabla jerárquica solo distingue "top" de
"dentro de top", no cada submódulo por separado), así que no puedo verificar cuál registro
exacto explica la diferencia de uno — prefiero decir esto en vez de inventar un número
que cuadre.

Vivado también convirtió mis dos contadores en cadenas `CARRY4` (lógica de acarreo rápido
dedicada de la Artix-7) en vez de sumadores hechos con LUTs — una optimización automática
que yo no pedí explícitamente, y que es exactamente el tipo de decisión que distingue
"síntesis" de una simple traducción línea por línea.

## 3. Implementation — opt, place, route, bitstream

La implementación coloca cada LUT/flip-flop en un sitio físico del chip, rutea las
conexiones entre ellos, y verifica que el resultado cumple el reloj que le pedí (100MHz,
10ns de período, vía `create_clock` en `constraints/basys3.xdc`). Utilización final
después de rutear (`report_utilization`, estado `Routed`):

| Recurso | Usado | Disponible | % |
|---|---|---|---|
| Slice LUTs | 29 | 20800 | 0.14% |
| Slice Registers | 35 | 41600 | 0.08% |

(29 LUTs en vez de 26 — el rutado real terminó necesitando un par de LUTs extra para
resolver conexiones que en la síntesis inicial se habían optimizado de forma distinta;
es normal, el conteo final después de `place_design`/`route_design` es el que cuenta).

**Reporte de timing** (`report_timing_summary`, resumen de diseño):

| | WNS | TNS | WHS | THS |
|---|---|---|---|---|
| A 100MHz | **4.901 ns** | 0.000 ns | **0.190 ns** | 0.000 ns |

`All user specified timing constraints are met.` — WNS (worst negative setup slack) y WHS
(worst hold slack) **ambos positivos**, 0 endpoints fallando. El camino más ajustado real
no está en mis dos FSM — está en el contador de 17 bits de `clk_divider`
(`cnt_reg[15]` → `cnt_reg[9]`, 3 niveles de lógica, slack de 4.901 ns sobre un
requerimiento de 10 ns). Tiene sentido: mis FSM tienen 4 y 5 estados nada más, muy poca
lógica combinacional; el contador grande es lo único con algo de profundidad.

`report_drc`: **0 errores**. `write_bitstream`: completado sin warnings,
`bitstream/p3_cerradura.bit` generado.

## 4. Comparación con el cálculo discreto del punto 1

El punto 1 me había dado **Fc ≈ 15.0 MHz** (66.7 ns de período mínimo) para el mismo tipo
de lógica armada con 2× AND3 + 2× OR2 + un flip-flop 74LVC discretos. Acá, dentro de la
FPGA, el mismo tipo de camino (unos pocos niveles de lógica entre dos flip-flops) tiene
4.901 ns de margen sobre un reloj de **100 MHz** — muchísimo más rápido que el límite
discreto. La razón no es que la FPGA sea "mejor lógica": es que una LUT de la Artix-7
tiene un retardo de compuerta a compuerta bastante menor que compuertas comerciales
discretas montadas en una placa con pistas reales, y porque dentro del chip no hay que
cruzar paquetes SOT-23 ni pistas de PCB entre cada etapa — todo el camino vive en silicio
contiguo. Son dos tecnologías distintas resolviendo el mismo problema de temporización, y
por eso dan números tan diferentes.
