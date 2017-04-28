ScopeNum=0;

//for test
//63x
//argstr="/test/Dist_Correction_test/Scope1/GMR_75F10_AE_01-20161007_22_A3~63x/,GMR_75F10_AE_01-20161007_22_A3_Ch3_FLFL_20161125150205110_242445.lsm,/test/Dist_Correction_test/Scope1/GMR_75F10_AE_01-20161007_22_A3~63x/Output/,Scope #1,63x"//for test

//40x
//argstr="/test/Dist_Correction_test/Scope6_40x/,FLFL_20170411171458477_279354.lsm,/test/Dist_Correction_test/Scope6_40x/Output/,Scope #5,40x"//for test
//argstr="/test/Dist_Correction_test/40x_0/vnc/,FLFL_20170302124503877_268270_ch3.lsm,/test/Dist_Correction_test/40x_0/vnc/Output/,Scope #6,40x"//for test



//args = split(argstr,",");

//args will be like this; "dir,filename,outputdir,Scope #1,Objective"

dir=0; filename=0; outputdir=0; ScopeNumST=0; ObjectiveST=0;
args = split(getArgument(),",");
dir = args[0];// Imput directory of the LSM files
filename = args[1];// The name of the LSM file
outputdir = args[2];//output directory
ScopeNumST = args[3];// scope number, "Scope #1" "Scope #2" "Scope #3" "Scope #4"" Scope #5" "Scope #6"
ObjectiveST= args[4];
PluginsDir=getDirectory("plugins");

print("dir; "+dir);
print("filename; "+filename);
print("outputdir; "+outputdir);
print("ScopeNumST; "+ScopeNumST);
print("ObjectiveST; "+ObjectiveST);
print("PluginsDir; "+PluginsDir);

exi=File.exists(outputdir);
if(exi!=1){
	File.makeDirectory(outputdir);
	print("outputdir created!");
}
logsum=getInfo("log");
filepath=outputdir+"Distortion_Correction_log.txt";

if(File.exists(filepath)!=1)
File.saveString(logsum, filepath);

print("\\Clear");

exi2=File.exists(dir+filename);
if(exi2!=1){
	print("input file is not existing!  "+dir+filename);
	logsum=getInfo("log");
	filepath=outputdir+"Distortion_Correction_log_error+"+filename+".txt";
	File.saveString(logsum, filepath);
	
	run("Quit");
}



//items=newArray("scope1", "scope2", "scope3","scope4", "scope5", "scope6");

if(ScopeNumST=="Scope #1")
ScopeNum="scope1";

else if(ScopeNumST=="Scope #2")
ScopeNum="scope2";

else if(ScopeNumST=="Scope #3")
ScopeNum="scope3";

else if(ScopeNumST=="Scope #4")
ScopeNum="scope4";

else if(ScopeNumST=="Scope #5")
ScopeNum="scope5";

else if(ScopeNumST=="Scope #6")
ScopeNum="scope6";

if(ScopeNum==0){
	print("ScopeNumST; "+ScopeNumST+" is wrong string. It must be Scope #1,Scope #2,Scope #3,Scope #4,Scope #5,Scope #6");
	
	logsum=getInfo("log");
	filepath=outputdir+"Distortion_Correction_log_error Scope num; "+ScopeNumST+".txt";
	File.saveString(logsum, filepath);
	
	run("Quit");
}

JSONDIR=""+PluginsDir+"Chromatic_Aberration"+File.separator+ScopeNum+"_"+ObjectiveST+".json";
if(File.exists(JSONDIR)==1){
	
	if(endsWith(filename,".lsm")){
		
		imputdir=dir+filename;
		
		run("apply lens", "stack1=["+imputdir+"] transformations=["+PluginsDir+"Chromatic_Aberration"+File.separator+ScopeNum+"_"+ObjectiveST+".json] output=["+outputdir+"] crop_width=0 mip_step_slices=1");
		//	else if(CH3positive!=-1)
		//	run("apply lens", "stack1=["+imputdir+"] stack2=[] transformations=["+PluginsDir+"Chromatic_Aberration"+File.separator+ScopeNum+".json] output=["+mydir3+"] crop_width=0");
		
		dotindex=lastIndexOf(filename,".lsm");
		truname=substring(filename,0,dotindex);
		
		exi2ch=File.exists(outputdir+truname+"-1-2.tif");
		exi3ch=File.exists(outputdir+truname+"-1-3.tif");
		
		exi2ch0=File.exists(outputdir+truname+"-1-2-0.tif");
		exi3ch0=File.exists(outputdir+truname+"-1-3-0.tif");
		
		if(exi2ch==1)
		File.rename(outputdir+truname+"-1-2.tif", outputdir+truname+".tif"); // - Renames, or moves, a file or directory. Returns "1" (true) if successful. 
		
		if(exi3ch==1)
		File.rename(outputdir+truname+"-1-3.tif", outputdir+truname+".tif"); // - Renames, or moves, a file or directory. Returns "1" (true) if successful. 
		
		if(exi2ch0==1)
		File.rename(outputdir+truname+"-1-2-0.tif", outputdir+truname+".tif"); // - Renames, or moves, a file or directory. Returns "1" (true) if successful. 
		
		if(exi3ch0==1)
		File.rename(outputdir+truname+"-1-3-0.tif", outputdir+truname+".tif"); // - Renames, or moves, a file or directory. Returns "1" (true) if successful. 
		
	//	setBatchMode(true);
		
		open(outputdir+truname+".tif");
		getDimensions(width, height, channels, slices, frames);
		print("Opened tif"+truname +"  channels"+channels);
		
	
	//	if(channels==3){
	//		run("Split Channels");
	//		selectWindow("C1-"+truname+".tif");
	//		run("Grays");
			
	//		selectWindow("C2-"+truname+".tif");
		//	run("Blue");
			
		//	selectWindow("C3-"+truname+".tif");
	//		run("Green");
			
		//	run("Merge Channels...", "c1=C1-"+truname+".tif c2=C2-"+truname+".tif c3=C3-"+truname+".tif create");
		//	Stack.setDisplayMode("color");
	//	}
		run("V3Draw...", "save="+outputdir+truname+".v3draw");
		File.delete(outputdir+truname+".tif");
	
	}
}else{//if(File.exists(JSONDIR)==1){
	print("json file is not existing!!  "+JSONDIR);
}

"Done"
""
logsum=getInfo("log");
filepath=outputdir+"Distortion_Correction_log.txt";
File.append(logsum, filepath);
run("Quit");