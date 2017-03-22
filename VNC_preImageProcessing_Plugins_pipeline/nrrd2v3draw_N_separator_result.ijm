// v3dpbd to nrrd

OutDir = getArgument;//"/test/VNC_Test/AlignedFlyVNC.v3draw";
if (OutDir=="") exit ("No argument!");
setBatchMode(true);

ch1exi=File.exists(OutDir+"Reformatted_Separator_Result_1.nrrd");
if(ch1exi==1){
	print("Reformatted neuron separator result: 1ch");
	run("Nrrd ...", "load=[" + OutDir+"Reformatted_Separator_Result_1.nrrd" + "]");
}

ch2exi=File.exists(OutDir+"Reformatted_Separator_Result_2.nrrd");
if(ch2exi==1){
	print("Reformatted neuron separator result: 2ch");
	run("Nrrd ...", "load=[" + OutDir+"Reformatted_Separator_Result_2.nrrd" + "]");
}

ch3exi=File.exists(OutDir+"Reformatted_Separator_Result_3.nrrd");
if(ch2exi==1){
	print("Reformatted neuron separator result: 3ch");
	run("Nrrd ...", "load=[" + OutDir+"Reformatted_Separator_Result_3.nrrd" + "]");
}


if(ch3exi==0 && ch2exi==1 && ch1exi==1)
run("Merge Channels...", "c1=Reformatted_Separator_Result_1.nrrd c2=Reformatted_Separator_Result_2.nrrd create ignore");
else if(ch3exi==1 && ch2exi==1 && ch1exi==1)
run("Merge Channels...", "c1=Reformatted_Separator_Result_1.nrrd c2=Reformatted_Separator_Result_2.nrrd c3=Reformatted_Separator_Result_3.nrrd create ignore");

run("V3Draw...", "save=[" + OutDir +"Reformatted_Separator_Result.v3draw""]");

run("Close All");


nc82Exi=File.exists(OutDir+"VNC-PP-SGwarp1.nrrd");
if(nc82Exi==1){
	open(OutDir+"VNC-PP-SGwarp1.nrrd");
	run("V3Draw...", "save=["+OutDir+"ConsolidatedLabel.v3draw""]");
}else{
	print("no VNC-PP-SGwarp1.nrrd exist");
	
}

logsum=getInfo("log");
filepath=OutDir+"v3draw_creation_neuron_separator_log.txt";
File.saveString(logsum, filepath);

run("Quit");