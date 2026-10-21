# Tabla de cumplimiento

Repaso del PDF (`Intro Bases de Datos P3.pdf`) punto por punto, con la evidencia real de
este repositorio para cada uno.

| Requisito del PDF | Evidencia |
|---|---|
| **1a.** Tramo FF a FF entre la FSM Mealy y la FSM Moore | [`docs/01-timing.md`](01-timing.md) §1 — tramo `FF_Q1`(PinChecker) → `match` → `N2` → `FF_Q2`(LockController) |
| **1b.** Compuertas lógicas reales de Digikey | [`docs/01-timing.md`](01-timing.md) §2 — SN74LVC1G11 (AND3), SN74LVC1G32 (OR2), SN74LVC1G74 (flip-flop D), familia 74LVC a 1.8V, datasheets reales citados |
| **1(i).** Setup constraint + Fc | [`docs/01-timing.md`](01-timing.md) §4 — Fc ≈ 15.0 MHz, verificado con script |
| **1(ii).** Hold constraint | [`docs/01-timing.md`](01-timing.md) §5 — cumple con 16.2 ns de margen |
| **2a.** Migrar a SystemVerilog, jerarquía `top`→`mealy`,`moore` | [`src/top.sv`](../src/top.sv), [`src/mealy.sv`](../src/mealy.sv), [`src/moore.sv`](../src/moore.sv) — mismas tablas y codificación que C3, ver [`docs/02-hdl.md`](02-hdl.md) |
| **2b.** Testbench + simulación en Vivado | [`sim/testbench.sv`](../sim/testbench.sv) — 35/35 PASS, sin warnings (`xvlog`/`xelab`/`xsim`), waveform real en [`docs/02-hdl.md`](02-hdl.md) |
| **2c.** Discusión RTL Analysis / Synthesis / Implementation | [`docs/03-vivado.md`](03-vivado.md) — con mis reportes reales (utilización, timing, DRC) |
| **2d.** Programar la Basys3 y demostrar | [`docs/04-basys3.md`](04-basys3.md) — bitstream programado y probado en placa real, 3 escenarios confirmados con fotos |
| **3.** Synopsys | El PDF dice literalmente "TODO" — documentado como pendiente de consultar con el profesor, sin publicar (ver nota interna, no versionada) |
| **Entregable.** Repo de GitHub con landing | [`index.html`](../index.html), repo público en GitHub Pages |
| **Entregable.** Video por inciso explicando el experimento | El profesor aclaró que es un solo video (<10 min) cubriendo todos los incisos — guion en `guiones/guion_video.md` (no publicado, fuera del repo) |

## Verificación final

- **Testbench:** `TESTBENCH: PASS`, 35/35, sin warnings de `xvlog`/`xelab`/`xsim`.
- **Síntesis e implementación:** 0 errores, 0 warnings, 0 critical warnings en ambas
  corridas (`synth_design`, `opt_design`/`place_design`/`phys_opt_design`/`route_design`).
- **Timing a 100 MHz:** `All user specified timing constraints are met.` — WNS = 4.901 ns,
  WHS = 0.190 ns (ambos positivos).
- **Bitstream:** generado sin errores (`bitstream/p3_cerradura.bit`), programado y
  verificado en una Basys3 real — reset, 4 dígitos correctos → `unlock`, 3 fallos →
  `alarm`, los tres coinciden con la simulación y con las tablas de C3.
- **Comportamiento HDL vs. C3:** mismas tablas de transición, misma codificación de
  estados, mismo reset asíncrono — confirmado por el testbench (35 checks contra las
  tablas de C3) y por las pruebas en hardware.
- **Timing recalculado:** el cálculo del punto 1 (Fc ≈ 15.0 MHz) se verificó con un
  script independiente antes de pasarlo al documento.
- **Landing y enlaces:** ver [`index.html`](../index.html); los enlaces a los documentos
  y al repositorio apuntan a rutas reales del repo.
