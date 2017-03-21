// v3dpbd to nrrd

fullpath = getArgument;//"/test/VNC_Test/AlignedFlyVNC.v3draw";
if (fullpath=="") exit ("No argument!");
setBatchMode(true);

NS = replace(fullpath, "AlignedFlyVNC.v3draw", "VNC-PP-BGwarp.nrrd");

ch1exi=File.exists(NS);
if(ch1exi==1){
	print("Reformatted neuron separator result: "+NS);
	run("Nrrd ...", "load=[" + NS + "]");
	
	run("V3Draw...", "save=[" + fullpath +"]");
}

	run("Quit");