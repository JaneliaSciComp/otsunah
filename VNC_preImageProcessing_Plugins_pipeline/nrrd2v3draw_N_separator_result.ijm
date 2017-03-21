// v3dpbd to nrrd

fullpath = getArgument;//"/test/VNC_Test/AlignedFlyVNC.v3draw";
if (fullpath=="") exit ("No argument!");
setBatchMode(true);

NS = replace(fullpath, "Reformatted_Separator_Result.v3draw", "Reformatted_Separator_Result.nrrd");

ch1exi=File.exists(NS);
if(ch1exi==1){
	print("Reformatted neuron separator result: "+NS);
	run("Nrrd ...", "load=[" + NS + "]");
	
	run("V3Draw...", "save=[" + fullpath +"]");
}

filesepIndex=lastIndexOf(fullpath,"/");
if(filesepIndex!=-1){
	INdir=substring(fullpath,0,filesepIndex+1);
//	filesepIndex2=lastIndexOf(INdir,"/");
//	if(filesepIndex2!=-1)
	//	INdir=substring(INdir,0,filesepIndex2+1);
	
	nc82Exi=File.exists(INdir+"VNC-PP-SGwarp1.nrrd");
	if(nc82Exi==1){
		open(INdir+"VNC-PP-SGwarp1.nrrd");
		run("V3Draw...", "save=["+INdir+"ConsolidatedLabel.v3draw""]");
	}else{
		print("no VNC-PP-SGwarp1.nrrd exist");
		
	}
}



	run("Quit");