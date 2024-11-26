onbreak resume
onerror resume
vsim -voptargs=+acc work.Hlp_tb
add wave sim:/Hlp_tb/u_Hlp/clk
add wave sim:/Hlp_tb/u_Hlp/clk_en
add wave sim:/Hlp_tb/u_Hlp/rst
add wave sim:/Hlp_tb/u_Hlp/filter_in
add wave sim:/Hlp_tb/u_Hlp/filter_out
add wave sim:/Hlp_tb/filter_out_ref
run -all
