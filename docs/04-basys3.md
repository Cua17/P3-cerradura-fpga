# Basys3 — programación y demostración

## 1. Mapeo de pines

[`constraints/basys3.xdc`](../constraints/basys3.xdc) — cada pin lo verifiqué contra el
`Basys-3-Master.xdc` oficial de Digilent
([github.com/Digilent/digilent-xdc](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc)),
no de memoria.

| Señal de `top.sv` | Elemento físico de la Basys3 | Pin | Función |
|---|---|---|---|
| `clk100mhz` | Oscilador de la placa | W5 | Reloj de 100MHz |
| `btn_reset` | Botón central (`btnC`) | U18 | Reset asíncrono global |
| `btn_step` | Botón arriba (`btnU`) | T18 | Reloj manual de la FSM (con antirrebote) |
| `btn_l` | Botón abajo (`btnD`) | U17 | `L` — re-bloquear desde `Unlocked` |
| `sw_d` | Switch 0 (`sw[0]`) | V17 | `D` — dígito correcto (1) / incorrecto (0) |
| `led_unlock` | LED 0 | U16 | Pestillo abierto |
| `led_alarm` | LED 1 | E19 | Alarma |
| `led_locked` | LED 2 | U19 | Bloqueada |
| `led_match` | LED 3 | V19 | `match` (Mealy, PinChecker) |
| `led_wrong` | LED 4 | W18 | `wrong` (Mealy, PinChecker) |
| `led_mealy_state[1:0]` | LED 5–6 | U15, U14 | Bits de estado de `PinChecker` (Q1 Q0) |
| `led_moore_state[2:0]` | LED 7–9 | V14, V13, V3 | Bits de estado de `LockController` (Q2 Q1 Q0) |

## 2. Cómo probar

1. Conectar la Basys3 por USB y programarla (ver sección 3).
2. `Reset` (botón central) deja todo en `Locked0` / `S0` — LED `locked` prendido, el
   resto apagados.
3. Mover el switch `sw_d` a la posición del dígito (1 = correcto, 0 = incorrecto para
   esa posición) y apretar el botón `btnU` una vez por dígito — cada apretón avanza la
   FSM un paso (el antirrebote filtra el rebote mecánico del botón).
4. 4 dígitos correctos seguidos (switch en 1, 4 apretones) prenden `unlock` y apagan
   `locked`.
5. Un dígito incorrecto (switch en 0) en cualquier punto reinicia `PinChecker` a `S0` y
   avanza `LockController` un paso en la cadena de fallos; al tercer fallo entra en
   `Alarm` (solo `Reset` lo saca de ahí, ni siquiera un PIN correcto).
6. Con `unlock` prendido, apretar `btnD` (`L`) vuelve a `Locked0`.

## 3. Programar la placa

Con la Basys3 conectada y el bitstream generado (`bitstream/p3_cerradura.bit`, ver
[`03-vivado.md`](03-vivado.md)):

```tcl
# programar_basys3.tcl
open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {bitstream/p3_cerradura.bit} $dev
program_hw_devices $dev
close_hw_target
```

```
vivado -mode batch -source programar_basys3.tcl
```
