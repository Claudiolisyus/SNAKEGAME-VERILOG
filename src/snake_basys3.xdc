# ============================================================
# snake_basys3.xdc
# Example pin constraints for a Digilent Basys3 (Artix-7).
# Adjust these to match YOUR board's schematic / master XDC file
# if you're using something else (Nexys, Cmod, Arty, etc.) --
# these exact pin numbers are Basys3-specific.
# ============================================================

# 100 MHz system clock
set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100mhz]

# Reset button (use any center/push button, e.g. BTNC)
set_property PACKAGE_PIN U18 [get_ports btn_reset]
set_property IOSTANDARD LVCMOS33 [get_ports btn_reset]

# PS/2 keyboard port
set_property PACKAGE_PIN C17 [get_ports ps2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_clk]
set_property PACKAGE_PIN B17 [get_ports ps2_data]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_data]
set_property PULLUP true [get_ports ps2_clk]
set_property PULLUP true [get_ports ps2_data]

# VGA output
set_property PACKAGE_PIN N19 [get_ports vga_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]
set_property PACKAGE_PIN P19 [get_ports vga_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]

set_property PACKAGE_PIN G19 [get_ports {vga_r[0]}]
set_property PACKAGE_PIN H19 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN J19 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN N19 [get_ports {vga_r[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*]}]

set_property PACKAGE_PIN J17 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN H17 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN G17 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN D17 [get_ports {vga_g[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[*]}]

set_property PACKAGE_PIN N18 [get_ports {vga_b[0]}]
set_property PACKAGE_PIN L18 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN K18 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[*]}]

# NOTE: these pin numbers are illustrative of a typical Basys3 constraint
# file layout. ALWAYS cross-check against the official Basys3 master XDC
# from Digilent before building, since revisions/pin maps can differ.
