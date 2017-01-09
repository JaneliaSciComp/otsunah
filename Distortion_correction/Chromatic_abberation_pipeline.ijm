ScopeNum=0;

//for test
//argstr="/test/Dist_Correction_test/Scope1/GMR_75F10_AE_01-20161007_22_A3~63x/,GMR_75F10_AE_01-20161007_22_A3_Ch2_FLFL_20161125145959698_242423.lsm,/test/Dist_Correction_test/Scope1/GMR_75F10_AE_01-20161007_22_A3~63x/Output/,Scope #1"//for test
//args = split(argstr,",");

//args will be like this; "dir,filename,outputdir,Scope #1"

dir=0; filename=0; outputdir=0; ScopeNumST=0;
args = split(getArgument(),",");
dir = args[0];// Imput directory of the LSM files
filename = args[1];// The name of the LSM file
outputdir = args[2];//output directory
ScopeNumST = args[3];// scope number, "Scope #1" "Scope #2" "Scope #3" "Scope #4"" Scope #5" "Scope #6"

print("dir; "+dir);
print("filename; "+filename);
print("outputdir; "+outputdir);
print("ScopeNumST; "+ScopeNumST);

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


PluginsDir=getDirectory("plugins");
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

if(endsWith(filename,".lsm")){
	
	imputdir=dir+filename;
	
	run("apply lens", "stack1=["+imputdir+"] stack2=[] transformations=["+PluginsDir+"Chromatic_Aberration"+File.separator+ScopeNum+".json] output=["+outputdir+"] crop_width=0");
	//	else if(CH3positive!=-1)
	//	run("apply lens", "stack1=["+imputdir+"] stack2=[] transformations=["+PluginsDir+"Chromatic_Aberration"+File.separator+ScopeNum+".json] output=["+mydir3+"] crop_width=0");
	
	dotindex=lastIndexOf(filename,".lsm");
	truname=substring(filename,0,dotindex);
	
	exi2ch=File.exists(outputdir+truname+"-1-2.tif");
	exi3ch=File.exists(outputdir+truname+"-1-3.tif");
	
	if(exi2ch==1)
	File.rename(outputdir+truname+"-1-2.tif", outputdir+truname+".tif"); // - Renames, or moves, a file or directory. Returns "1" (true) if successful. 
	
	if(exi3ch==1)
	File.rename(outputdir+truname+"-1-3.tif", outputdir+truname+".tif"); // - Renames, or moves, a file or directory. Returns "1" (true) if successful. 
	
	open(outputdir+truname+".tif");
	run("V3Draw...", "save="+outputdir+truname+".v3draw");
	File.delete(outputdir+truname+".tif");
	
}



"Done"
""
logsum=getInfo("log");
filepath=outputdir+"Distortion_Correction_log.txt";
File.append(logsum, filepath);
run("Quit");