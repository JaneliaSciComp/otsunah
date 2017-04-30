path=0; 
//path="/test/Dist_Correction_test/40x_0/vnc/Output/FLFL_20170302124503877_268270_ch4.v3draw"


path = getArgument();//args[0];// full file path of the v3draw
print("path; "+path);
directorypath=0;
if(File.exists(path)){
	
	open(path);
	
	print("Opened v3draw"+path);
	truname=0;
	
	directoryIndex=lastIndexOf(path,"/");
	if(directoryIndex!=-1){
		truname=substring(path,directoryIndex+1,lengthOf(path));
		directorypath=substring(path,0,directoryIndex+1);
	}
	
	getDimensions(width, height, channels, slices, frames);
	if(channels==4 && truname!=0){
		run("Split Channels");
		
		run("Merge Channels...", "c1=C3-"+truname+" c2=C2-"+truname+" c3=C1-"+truname+" c4=C4-"+truname+" create");
	}
	
	run("V3Draw...", "save="+path);
}else
print("There is no merging file.v3draw");

logsum=getInfo("log");
if(directorypath!=0)
File.saveString(logsum, directorypath+"ColorChanging_log.txt");

run("Quit");

