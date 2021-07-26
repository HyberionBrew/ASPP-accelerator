onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /psums_buffer_tb/clk
add wave -noupdate /psums_buffer_tb/psums_buffer_i/mode
add wave -noupdate /psums_buffer_tb/psums_buffer_i/out_buffer
add wave -noupdate /psums_buffer_tb/psums_buffer_i/douta
add wave -noupdate /psums_buffer_tb/psums_buffer_i/out_buffer_nxt
add wave -noupdate /psums_buffer_tb/psums_buffer_i/prepare_psums_state
add wave -noupdate /psums_buffer_tb/psums_buffer_i/ofm_counter
add wave -noupdate /psums_buffer_tb/psums_buffer_i/psums_reg_in
add wave -noupdate /psums_buffer_tb/psums_buffer_i/psum_out_counter
add wave -noupdate /psums_buffer_tb/psums_buffer_i/wait_counter
add wave -noupdate /psums_buffer_tb/psums_buffer_i/wait_counter_nxt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {53194 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 331
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
WaveRestoreZoom {0 ps} {157500 ps}
