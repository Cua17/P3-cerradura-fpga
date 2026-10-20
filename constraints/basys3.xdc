# Basys3 (Artix-7 XC7A35T-1CPG236C) - cerradura PIN (PinChecker + LockController)
# Pines verificados contra el Basys3_Master.xdc oficial de Digilent
# (https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc)

## Reloj del sistema (100MHz)
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk100mhz]

## Botones
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports btn_reset]  ;# btnC - reset asincrono global
set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports btn_step]   ;# btnU - reloj manual (con antirrebote)
set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports btn_l]      ;# btnD - L (re-bloquear)

## Switch
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports sw_d]       ;# sw[0] - D (digito correcto/incorrecto)

## LEDs
set_property -dict { PACKAGE_PIN U16  IOSTANDARD LVCMOS33 } [get_ports led_unlock]          ;# led[0]
set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports led_alarm]           ;# led[1]
set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports led_locked]          ;# led[2]
set_property -dict { PACKAGE_PIN V19  IOSTANDARD LVCMOS33 } [get_ports led_match]           ;# led[3]
set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports led_wrong]           ;# led[4]
set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports {led_mealy_state[0]}] ;# led[5]
set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports {led_mealy_state[1]}] ;# led[6]
set_property -dict { PACKAGE_PIN V14  IOSTANDARD LVCMOS33 } [get_ports {led_moore_state[0]}] ;# led[7]
set_property -dict { PACKAGE_PIN V13  IOSTANDARD LVCMOS33 } [get_ports {led_moore_state[1]}] ;# led[8]
set_property -dict { PACKAGE_PIN V3   IOSTANDARD LVCMOS33 } [get_ports {led_moore_state[2]}] ;# led[9]

## Opciones de configuracion (igual que en el master.xdc)
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
