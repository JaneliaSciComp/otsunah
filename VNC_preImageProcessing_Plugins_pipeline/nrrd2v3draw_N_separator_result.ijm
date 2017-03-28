// v3dpbd to nrrd

OutDir = getArgument;//"/test/VNC_Test/AlignedFlyVNC.v3draw";
if (OutDir=="") exit ("No argument!");
setBatchMode(true);

ch1exi=File.exists(OutDir+"Reformatted_Separator_Result.nrrd");
if(ch1exi==1){
	print("Reformatted neuron separator result");
	run("Nrrd ...", "load=[" + OutDir+"Reformatted_Separator_Result_1.nrrd" + "]");
}

run("V3Draw...", "save=[" + OutDir +"Reformatted_Separator_Result.v3draw]");
print("saved v3draw; "+ OutDir +"Reformatted_Separator_Result.v3draw");
run("Close All");

logsum=getInfo("log");
filepath=OutDir+"v3draw_creation_neuron_separator_log.txt";
File.saveString(logsum, filepath);

run("Quit");