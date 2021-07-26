onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ctrl_tb/clk
add wave -noupdate /ctrl_tb/ifmaps_loaded
add wave -noupdate /ctrl_tb/kernels_loaded
add wave -noupdate /ctrl_tb/load_ifmaps
add wave -noupdate /ctrl_tb/load_kernels
add wave -noupdate /ctrl_tb/PEs_finished
add wave -noupdate /ctrl_tb/reset
add wave -noupdate /ctrl_tb/new_ifmaps
add wave -noupdate /ctrl_tb/cntrl_unit_i/state
add wave -noupdate /ctrl_tb/cntrl_unit_i/ifmaps_prepared
add wave -noupdate /ctrl_tb/cntrl_unit_i/psum_state
add wave -noupdate /ctrl_tb/cntrl_unit_i/psum_mode
add wave -noupdate /ctrl_tb/cntrl_unit_i/psums_ready
add wave -noupdate /ctrl_tb/cntrl_unit_i/state_calc_i/psums_position
add wave -noupdate /ctrl_tb/iacts_values
add wave -noupdate /ctrl_tb/cntrl_unit_i/ifmap_out_buffer
add wave -noupdate /ctrl_tb/kernel_values_out
add wave -noupdate /ctrl_tb/new_kernels
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1676208 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 186
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
WaveRestoreZoom {1239197 ps} {3401065 ps}
