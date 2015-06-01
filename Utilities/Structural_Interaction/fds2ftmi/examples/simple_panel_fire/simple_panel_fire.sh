../../../../../FDS_Compilation/intel_linux_64/fds_intel_linux_64 simple_panel_fire.fds 
ansys150 -b nolist -j simple_panel_fire_ansys -i read_geometry_fire.ans
../../intel_linux_64/fds2ftmi_linux_64 simple_panel_fire 0.05 2 0 600 2 0 1 simple_panel_fire_to_ansys 
ansys150 -b nolist -j simple_panel_fire_ansys -i run_simple_panel_fire.ans 
ansys150 -b nolist -j simple_panel_fire_ansys -i plot_fire.ans 
export DISPLAY=localhost:0.0 #
display150 -d POSTSCRIPT -j simple_panel_fire_ansys #
epstopdf --outfile=simple_panel_fire_ansys.pdf pscr000.eps  # 
mv simple_panel_fire_ansys.pdf ../../scripts/SCRIPT_FIGURES/simple_panel_fire_ansys.pdf #
rm *.lock #
rm *.dat #
rm *_ansys* #
rm *.tmp #
rm *.eps #