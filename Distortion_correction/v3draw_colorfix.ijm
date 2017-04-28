path=0; 
//path="/test/Dist_Correction_test/40x_0/vnc/Output/FLFL_20170302124503877_268270_ch3.v3draw"

args = split(getArgument(),",");
path = args[0];// full file path of the v3draw

open(path);

print("Opened v3draw"+path);

run("V3Draw...", "save="+path);