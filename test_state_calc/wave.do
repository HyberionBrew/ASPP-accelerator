onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /state_calc_tb/clk
add wave -noupdate /state_calc_tb/finished
add wave -noupdate /state_calc_tb/ifmap_address
add wave -noupdate /state_calc_tb/ifmap_address
add wave -noupdate /state_calc_tb/need_kernels
add wave -noupdate /state_calc_tb/new_ifmaps
add wave -noupdate /state_calc_tb/psum_address
add wave -noupdate /state_calc_tb/psum_prev_address
add wave -noupdate /state_calc_tb/reset
add wave -noupdate -expand /state_calc_tb/state_calc_i/ifmap_position
add wave -noupdate /state_calc_tb/state_calc_i/new_ifmaps
add wave -noupdate /state_calc_tb/state_calc_i/new_ifmaps_reg
add wave -noupdate /state_calc_tb/state_calc_i/new_ifmaps_reg_nxt
add wave -noupdate /state_calc_tb/state_calc_i/kernel
add wave -noupdate /state_calc_tb/state_calc_i/rate
add wave -noupdate /state_calc_tb/state_calc_i/ofm
add wave -noupdate /state_calc_tb/state_calc_i/finished
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {24913840000 ps} 0}
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
WaveRestoreZoom {10050 us} {31050 us}
