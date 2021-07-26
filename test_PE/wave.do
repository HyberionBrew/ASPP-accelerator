onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /pe_tb/clk
add wave -noupdate /pe_tb/bus_to_pe
add wave -noupdate /pe_tb/finished
add wave -noupdate /pe_tb/new_ifmaps
add wave -noupdate /pe_tb/new_kernels
add wave -noupdate /pe_tb/reset
add wave -noupdate /pe_tb/pe_i/index
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/counter
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/finished
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/state
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/valid
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/bitvec
add wave -noupdate -radix decimal /pe_tb/result
add wave -noupdate /pe_tb/valid_out
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/ifmap_bitvecs_reg
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/kernel_bitvecs_reg
add wave -noupdate /pe_tb/pe_i/fetch_unit_i/bitvec
add wave -noupdate /pe_tb/pe_i/mult_unit_i/ifmap_zero_reg
add wave -noupdate /pe_tb/pe_i/mult_unit_i/ifmap_value_reg
add wave -noupdate /pe_tb/pe_i/mult_unit_i/kernel_value_reg
add wave -noupdate /pe_tb/pe_i/mult_unit_i/valid_out
add wave -noupdate /pe_tb/pe_i/mult_unit_i/ifmap_reg_signed
add wave -noupdate /pe_tb/pe_i/result
add wave -noupdate /pe_tb/pe_i/mult_unit_i/weight_reg_signed
add wave -noupdate -radix decimal -childformat {{/pe_tb/pe_i/accum_unit_i/psum(0) -radix decimal} {/pe_tb/pe_i/accum_unit_i/psum(1) -radix decimal}} -expand -subitemconfig {/pe_tb/pe_i/accum_unit_i/psum(0) {-height 17 -radix decimal} /pe_tb/pe_i/accum_unit_i/psum(1) {-height 17 -radix decimal}} /pe_tb/pe_i/accum_unit_i/psum
add wave -noupdate /pe_tb/pe_i/psum
add wave -noupdate /pe_tb/pe_i/new_psum
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3576087 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 440
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {10500 ns}
