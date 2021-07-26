onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /pe_array_tb/pe_array_i/clk
add wave -noupdate -expand -subitemconfig {/pe_array_tb/pe_array_i/psum(0) -expand /pe_array_tb/pe_array_i/psum(1) -expand /pe_array_tb/pe_array_i/psum(2) -expand} /pe_array_tb/pe_array_i/psum
add wave -noupdate /pe_array_tb/pe_array_i/PEs_rows(0)/PEs_columns(0)/pe_i/accum_unit_i/psum
add wave -noupdate /pe_array_tb/pe_array_i/new_ifmaps
add wave -noupdate -expand /pe_array_tb/pe_array_i/new_kernels
add wave -noupdate /pe_array_tb/pe_array_i/new_psum
add wave -noupdate /pe_array_tb/bus_pe_array
add wave -noupdate -expand -subitemconfig {/pe_array_tb/pe_array_i/psum_in(1) -expand} /pe_array_tb/pe_array_i/psum_in
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {103624 ps} 0}
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
WaveRestoreZoom {0 ps} {319556 ps}
