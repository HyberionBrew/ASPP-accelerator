onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ofm_tb/clk
add wave -noupdate /ofm_tb/ofm
add wave -noupdate /ofm_tb/ofms_in
add wave -noupdate -radix decimal /ofm_tb/ofms_unit_i/scale
add wave -noupdate /ofm_tb/ofms_unit_i/addr_ofm
add wave -noupdate /ofm_tb/ofms_unit_i/counter
add wave -noupdate /ofm_tb/ofms_unit_i/rams_sdp_record_i/mem
add wave -noupdate /ofm_tb/enable
add wave -noupdate /ofm_tb/ofms_unit_i/rams_sdp_record_i/din
add wave -noupdate /ofm_tb/ofms_unit_i/rams_sdp_record_i/waddr
add wave -noupdate /ofm_tb/ofms_unit_i/rams_sdp_record_i/raddr
add wave -noupdate /ofm_tb/ofms_unit_i/rams_sdp_record_i/we
add wave -noupdate /ofm_tb/ofms_unit_i/shift
add wave -noupdate -radix unsigned /ofm_tb/ofms_unit_i/dout_shift
add wave -noupdate /ofm_tb/ofms_unit_i/result_valid
add wave -noupdate -radix decimal /ofm_tb/ofms_unit_i/result_mult
add wave -noupdate -radix decimal /ofm_tb/ofms_unit_i/result_mult_nxt
add wave -noupdate /ofm_tb/ofms_unit_i/result_mult_valid
add wave -noupdate /ofm_tb/ofms_unit_i/result_mult_valid_nxt
add wave -noupdate /ofm_tb/ofms_unit_i/result_nxt
add wave -noupdate /ofm_tb/ofms_unit_i/result_valid
add wave -noupdate -radix unsigned /ofm_tb/ofms_unit_i/waddr
add wave -noupdate -radix unsigned /ofm_tb/ofms_unit_i/debug
add wave -noupdate /ofm_tb/ofms_unit_i/din
add wave -noupdate /ofm_tb/ofms_unit_i/from_uart
add wave -noupdate -radix unsigned /ofm_tb/ofms_unit_i/to_uart
add wave -noupdate /ofm_tb/ofms_unit_i/data_counter
add wave -noupdate /ofm_tb/ofms_unit_i/data_counter_nxt
add wave -noupdate /ofm_tb/ofms_unit_i/uart_buffer
add wave -noupdate /ofm_tb/ofms_unit_i/uart_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1506341 ps} 0}
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
WaveRestoreZoom {0 ps} {16111944 ps}
