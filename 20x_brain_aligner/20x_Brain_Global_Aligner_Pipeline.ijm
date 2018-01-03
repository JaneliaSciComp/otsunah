//Pre-Image processing for VNC before CMTK operation
//Wrote by Hideo Otsuna, July 27, 2017
run("Set Measurements...", "area centroid center perimeter fit shape redirect=None decimal=2");
MIPsave=1;
templateBR="JFRC2010";//JFRC2010 OR JFRC2013 for voxel size adjustment
ShapeAnalysis=1;//perform shape analysis and kick strange sample
CLAHEwithMASK=1;
Batch=1;
BWd=0; //BW decision at 793 line
PrintSkip=0;
templateBr="JFRC2010";
ForceUSE=false;
nrrdEx=true;
revstack=false;

cropWidth=1260;
cropHeight=700;
ChannelInfo = "01 02 nrrd files";
blockposition=1;
totalblock=1;
Frontal50pxPath=0;
MCFOYN=false;
TwentyMore=20;
nc82decision="Color base";
DecidedColor="Red";
ShapeMatchingMaskPath=0;
JFRC2010AveProPath=0;
Slice50pxPath=0;
LateralMIPPath=0;
dir=0;
savedir=0;
saveOK=0;
lsmOK=0;
rotationYN="No";

shiftY=15;
DesireX=512;

setBatchMode(true);



args = split(getArgument(),",");
savedir = args[0];// save dir
filename = args[1];//file name
path = args[2];// full file path for inport LSM
Frontal50pxPath = args[3];// full file path for "JFRC2010_50pxMIP.tif"
LateralMIPPath = args[4];//  full file path for "Lateral_JFRC2010_5time_smallerMIP.tif"
Slice50pxPath = args[5];//  full file path for "JFRC2010_50pxSlice.tif"
ShapeMatchingMaskPath = args[6];//"JFRC2010_ShapeMatchingMask.tif";
JFRC2010AveProPath = args[7]; //"JFRC2010_AvePro.png"

widthVx = args[8];// X voxel size
depth = args[9];// slice depth
widthVx=parseFloat(widthVx);//Chaneg string to number
depth=parseFloat(depth);//Chaneg string to number

heightVx=widthVx;

numCPU=args[10];
numCPU= parseFloat(numCPU);//Chaneg string to number

print("path;"+path);
print("savedir; "+savedir);
print("X resolution; "+widthVx+" micron");
print("Frontal50pxPath; "+Frontal50pxPath);
print("LateralMIPPath; "+LateralMIPPath);
print("Slice50pxPath; "+Slice50pxPath);
print("ShapeMatchingMaskPath; "+ShapeMatchingMaskPath);
print("JFRC2010AveProPath; "+JFRC2010AveProPath);
print("numCPU; "+numCPU);


savedirext=File.exists(savedir);
if(savedirext!=1)
File.makeDirectory(savedir);

String.resetBuffer;
n3 = lengthOf(savedir);
for (si=0; si<n3; si++) {
	c = charCodeAt(savedir, si);
	if(c==32){// if there is a space
		print("There is a space, please eliminate the space from saving directory.");
		exit();
	}
	//	String.append(fromCharCode(c));
	//	filename = String.buffer;
}
String.resetBuffer;

myDir0 = savedir+"Shape_problem"+File.separator;
File.makeDirectory(myDir0);

myDir4 = savedir+"High_background_cannot_segment_VNC"+File.separator;
File.makeDirectory(myDir4);

logsum=getInfo("log");
filepath=savedir+"20x_brain_pre_aligner_log.txt";
File.saveString(logsum, filepath);

mask=savedir+"Mask"+File.separator;
File.makeDirectory(mask);

ID20xMIP=0;

FilePathArray=newArray(Frontal50pxPath, "JFRC2010_50pxMIP.tif");
fileOpen(FilePathArray);
Frontal50pxPath=FilePathArray[0];

FilePathArray=newArray(LateralMIPPath, "Lateral_JFRC2010_5time_smallerMIP.tif");
fileOpen(FilePathArray);
LateralMIPPath=FilePathArray[0];

FilePathArray=newArray(Slice50pxPath, "JFRC2010_50pxSlice.tif");
fileOpen(FilePathArray);
Slice50pxPath=FilePathArray[0];

FilePathArray=newArray(ShapeMatchingMaskPath, "JFRC2010_ShapeMatchingMask.tif");
fileOpen(FilePathArray);
ShapeMatchingMaskPath=FilePathArray[0];

FilePathArray=newArray(JFRC2010AveProPath, "JFRC2010_AvePro.png");
fileOpen(FilePathArray);
JFRC2010AveProPath=FilePathArray[0];

noext2=0;


///// Duplication check //////////////////////////////////////////////////////////////

filepathcolor=0; NRRD_02_ext=0; Nrrdnumber=0;


List.clear();

beforeopen=getTime();
open(path);// for tif, comp nrrd, lsm", am, v3dpbd, mha
afteropen=getTime();

fileopentime=(afteropen-beforeopen)/1000;
print("file open time; "+fileopentime+" sec");

starta=getTime();

setVoxelSize(1, 1, 1, "pixels");
print(bitDepth+" bit");

noext = "PreAligned";

getDimensions(width, height, channels, slices, frames);

if(width<height)
longlength=height;
else
longlength=width;

if(channels==2 || channels==3 || channels==4)
run("Split Channels");

print("channels; "+channels);

logsum=getInfo("log");
File.saveString(logsum, filepath);

titlelist=getList("image.titles");
signal_count = 0;
neuron=newArray(titlelist.length);
UnknownChannel=newArray(titlelist.length);
posicolor=newArray(titlelist.length);
Original3D=newArray(titlelist.length);

posicolorNum=0;

if(channels==1){
	print("titlelist length; "+titlelist.length);
	selectWindow(titlelist[1]);
	neuron=getImageID();
	print("single channel, slice number; "+ nSlices());
}

for (iCh=0; iCh<titlelist.length; iCh++) {
	selectWindow(titlelist[iCh]);
	
	if(nSlices>1){
		//	cc = substring(chanspec,iCh,iCh+1);
		print("titlelist[iCh]; "+titlelist[iCh]);
		UnknownChannel[posicolorNum]=getImageID();
		posicolorNum=posicolorNum+1;
	}
}//for (i=0; i<lengthOf(chanspec); i++) {

logsum=getInfo("log");
File.saveString(logsum, filepath);

if(channels==2){
	
	selectImage(UnknownChannel[1]);//ch2
	nc82=getImageID();//White
	
	selectImage(UnknownChannel[0]);//ch1
	neuron=getImageID();
	
}//if(channels==2){

if(channels==3){
	
	selectImage(UnknownChannel[2]);//ch3
	nc82=getImageID();
	
	selectImage(UnknownChannel[0]);//ch1
	neuron=getImageID();
	
	selectImage(UnknownChannel[1]);//ch2
	neuron2=getImageID();
}//if(posicolor0=="Red" && posicolor1=="White"){


if(channels==4){
	selectImage(UnknownChannel[3]);
	nc82=getImageID();
	
	selectImage(UnknownChannel[0]);
	neuron=getImageID();
	
	selectImage(UnknownChannel[1]);
	neuron2=getImageID();	
	
	selectImage(UnknownChannel[2]);
	neuron3=getImageID();	
}//if(channels==4){


maxvalue0=255;

if(channels!=1){
	selectImage(nc82);
	NC82SliceNum=nSlices();
}

if(bitDepth==16)
maxvalue0=65535;

maxsizeData=0; SizeM=0;

ID20xMIP=0; positiveAR=0; lowerM=3; threTry=0; prelower=0; finalMIP=0; ABSMaxARShape=0; ABSmaxSize=0;
maxARshape=1.7; ABSmaxCirc=0; MaxOBJScore=0; MaxRot=0; angle=400;

elipsoidArea = 0;//area of mask
elipsoldAngle = 0;//angle of mask
numberResults=0; mask1st=0; invertON=0; shortARshapeGap=0;

selectImage(nc82);
rename("nc82.tif");

oriwidth=getWidth(); oriheight=getHeight(); orislice=nSlices();

newImage("mask.tif", "8-bit white", oriwidth, oriheight, orislice);
run("Mask Median Subtraction", "mask=mask.tif data=nc82.tif %=90 histogram=100");

selectWindow("mask.tif");
close();

selectImage(nc82);

run("Z Project...", "start=10 stop="+nSlices-10+" projection=[Average Intensity]");// imageID is AR
rename("OriginalProjection.tif");

xcenter=round(getWidth/2); ycenter=round(getHeight/2);

ZoomratioSmall=widthVx/6.2243;
Zoomratio=widthVx/0.62243;
run("Duplicate...", "title=DUPaveP.tif");
//getMinAndMax(min, max);
//if(min!=0 && max!=255)
//run("Apply LUT");

//run("Gamma ", "gamma=2.1 in=InMacro cpu=7");
//gammaup=getTitle();

//selectWindow("DUPaveP.tif");
//close();

//selectWindow(gammaup);
//rename("DUPaveP.tif");

run("Enhance Contrast", "saturated=0.35");
getMinAndMax(min, max);

bitd=bitDepth();
if(bitd==8)
run("16-bit");

newImage("mask.tif", "8-bit white", oriwidth, oriheight, 1);
run("Mask Median Subtraction", "mask=mask.tif data=nc82.tif %=100 histogram=100");

selectWindow("mask.tif");
close();

selectWindow("DUPaveP.tif");

setMinAndMax(min, max);
run("Apply LUT");

print("ZoomratioSmall; "+ZoomratioSmall+"   widthVx; "+widthVx+"  round(getWidth*ZoomratioSmall); "+round(getWidth*ZoomratioSmall));
run("Size...", "width="+round(getWidth*ZoomratioSmall)+" height="+round(getHeight*ZoomratioSmall)+" depth=1 constrain interpolation=None");
run("Canvas Size...", "width=102 height=102 position=Center zero");


//	setBatchMode(false);
//		updateDisplay();
//		"do"
//		exit();


rotSearch=60;
ImageCarray=newArray(0, 0, 0, 0);
ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,90,numCPU);

OBJScoreOri=ImageCarray[0];
OriginalRot=ImageCarray[1];
OriginalYshift=ImageCarray[2];
OriginalXshift=ImageCarray[3];

maxX=OriginalXshift/2;
maxY=OriginalYshift/2;

BrainShape="Intact";
MaxZoom=1;
print("772 BrainShape; "+BrainShape+"   OBJScore; "+OBJScoreOri+"  OriginalRot; "+OriginalRot);

logsum=getInfo("log");
File.saveString(logsum, filepath);

	
	ImageCorrelationArray=newArray(nc82, 0,0,0,0,0,0);
	ImageCorrelation(ImageCorrelationArray,widthVx,numCPU);// with zoom adjustment
	
	//		OriginalRot=ImageCorrelationArray[4];
	//		OBJScoreOri=ImageCorrelationArray[5];
	MaxZoom=ImageCorrelationArray[6];
	//		OriginalXshift = ImageCorrelationArray[2];
	//		OriginalYshift = ImageCorrelationArray[3];
	
	if(MaxZoom!=1){
		
		widthVx=widthVx*MaxZoom; heightVx=heightVx*MaxZoom;
	}
	
	//	if(OBJScoreOri<500){
	print("  Optic lobe checking!!  OBJScoreOri; "+OBJScoreOri);
	selectWindow("JFRC2010_AvePro.png");
	run("Duplicate...", "title=JFRC2010_AvePro-Rop.png");
	makePolygon(82,34,74,52,66,65,69,76,90,80,99,72,101,58,100,34);// elimination of the R-Op
	setForegroundColor(0, 0, 0);
	run("Fill", "slice");
	
	ImageCarray=newArray(0, 0, 0, 0);
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro-Rop.png", rotSearch,ImageCarray,80,numCPU);
	
	OBJScoreR=ImageCarray[0];
	RotR=ImageCarray[1];
	ShiftYR = ImageCarray[2];
	ShiftXR = ImageCarray[3];
	selectWindow("JFRC2010_AvePro-Rop.png");
	close();//"JFRC2010_AvePro-Rop.png"
	print("OBJScoreR; "+OBJScoreR);
	
	selectWindow("JFRC2010_AvePro.png");
	makePolygon(17,31,22,42,31,51,37,65,31,79,14,79,2,74,2,54,1,38);//L-OP elimination
	run("Fill", "slice");
	ImageCarray=newArray(0, 0, 0, 0);
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,80,numCPU);
	
	OBJScoreL=ImageCarray[0];
	RotL=ImageCarray[1];
	ShiftYL = ImageCarray[2];
	ShiftXL = ImageCarray[3];
	print("OBJScoreL; "+OBJScoreL);
	
	selectWindow("JFRC2010_AvePro.png");
	makePolygon(82,34,74,52,66,65,69,76,90,80,99,72,101,58,100,34);// elimination of the R-Op
	run("Fill", "slice");
	ImageCarray=newArray(0, 0, 0, 0);
	ImageCorrelation2 ("DUPaveP.tif", "JFRC2010_AvePro.png", rotSearch,ImageCarray,80,numCPU);
	
	OBJScoreBoth=ImageCarray[0];
	RotBoth=ImageCarray[1];
	ShiftYboth = ImageCarray[2];
	ShiftXboth = ImageCarray[3];
	print("OBJScoreBoth; "+OBJScoreBoth);
	
	if(OBJScoreL>OBJScoreR && OBJScoreL>OBJScoreOri && OBJScoreL>OBJScoreBoth){
		OBJScoreOri = OBJScoreL;
		BrainShape="Left_OP_missing";
		OriginalRot=RotL;
		OriginalXshift = ShiftXL;
		OriginalYshift = ShiftYL;
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
		
	}
	if(OBJScoreR>OBJScoreL && OBJScoreR>OBJScoreOri && OBJScoreR>OBJScoreBoth){
		OBJScoreOri = OBJScoreR;
		BrainShape="Right_OP_missing";
		OriginalRot=RotR;
		OriginalXshift = ShiftXR;
		OriginalYshift = ShiftYR;
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
	}
	if(OBJScoreBoth>OBJScoreR && OBJScoreBoth>OBJScoreL && OBJScoreBoth>OBJScoreOri){
		OBJScoreOri = OBJScoreBoth;
		BrainShape="Both_OP_missing";
		OriginalRot=RotBoth;
		OriginalXshift = ShiftXboth;
		OriginalYshift = ShiftYboth;
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
	}
	//	}
	
	maxX=OriginalXshift;
	maxY=OriginalYshift;
//}//if(OBJScore<400){


selectWindow("JFRC2010_AvePro.png");
close();//"JFRC2010_AvePro.png"

selectWindow("DUPaveP.tif");
close();

elipsoidAngle=OriginalRot;
OBJScore=OBJScoreOri;

print("BrainShape; "+BrainShape+"   OBJScore; "+OBJScoreOri+"  OriginalRot; "+OriginalRot);
print("MaxZoom; "+MaxZoom+"   Zoomratio; "+Zoomratio);

logsum=getInfo("log");
File.saveString(logsum, filepath);

while(isOpen("OriginalProjection.tif")){
	selectWindow("OriginalProjection.tif");
	close();
}





if(BrainShape=="Intact"){
	firstTime=0; 
	for(MIPstep=1; MIPstep<3; MIPstep++){// Segmentation of the brain
		endthre=0; lowestthre=100000; maxARshapeGap=100000; maxThreTry=100; MaxCirc=0.18; 
		for(ThreTry=0; ThreTry<=maxThreTry; ThreTry++){
			
			showStatus("Brain rotation");
			selectImage(nc82);
			
			//	setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//exit();
			
			if(ThreTry>0){
				selectImage(OriginalProjection);
				
				
			}else if(ThreTry==0){
				if(MIPstep==1)
				run("Z Project...", "start=10 stop="+nSlices-10+" projection=[Average Intensity]");// imageID is AR
				else if(MIPstep==2)
				run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
				
				//		run("Minimum...", "radius=5");
				//		run("Maximum...", "radius=5");
				
				rename("OriginalProjection.tif");
				OriginalProjection=getImageID();
			}
			
			selectWindow("OriginalProjection.tif");
			run("Duplicate...", "title=DUPprojection.tif");// for Masking
			DUPprojection=getImageID();
			
			//			setBatchMode(false);
			//			updateDisplay();
			//			aa
			
			if(ThreTry>3){
				
				
				if(bitDepth==16)
				lowestthre=lowestthre+increment16bit;
				else if(bitDepth==8)
				lowestthre=lowestthre+1;
				
				setThreshold(lowestthre, maxvalue0);
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0, 0, 0);
				run("Make Binary", "thresholded remaining");
				
				//	run("Fill Holes");
				
				if(firstTime==1)
				ThreTry=maxThreTry;;
				
			}else{
				
				if(ThreTry==0)
				setAutoThreshold("Triangle dark");
				else if(ThreTry==1)
				setAutoThreshold("Default dark");
				else if(ThreTry==2)
				setAutoThreshold("Huang dark");
				else if(ThreTry==3)
				setAutoThreshold("Percentile dark");
				
				getThreshold(lower, upper);
				setThreshold(lower, maxvalue0);
				
				//			setOption("BlackBackground", true);
				
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0, 0, 0);
				run("Make Binary", "thresholded remaining");
				
				//			run("Fill Holes");
				
				print("MIPstep; "+MIPstep+"   "+lower+"  lower");
				
				//		if(ThreTry==2){
				//			setBatchMode(false);
				//		updateDisplay();
				//		aa
				//	}
				
				if(lowestthre>lower)
				lowestthre=lower;
				
				if(endthre<lower)
				endthre=lower;
				
				if(ThreTry==3){
					maxThreTry=endthre;
					increment16bit=(maxThreTry-lowestthre)/100;
					increment16bit=round(increment16bit);
					
					if(increment16bit<1)
					increment16bit=1;
					
					print("MIPstep; "+MIPstep+"   Gap thresholding; from "+lowestthre+" to "+maxThreTry+" Gap; "+maxThreTry-lowestthre+"  increment16bit; "+increment16bit);
				}//	if(ThreTry==3){
			}//	if(ThreTry>3){
			//		run("Median...", "radius=2");
			
			run("Minimum...", "radius=5");
			run("Maximum...", "radius=5");
			
			//		setBatchMode(false);
			//		updateDisplay();
			//		aa
			
			
			run("Analyze Particles...", "size="+(130000/MaxZoom)/Zoomratio+"-Infinity display clear");
			
			updateResults();
			maxsizeData=0;
			
			if(getValue("results.count")>0){
				numberResults=getValue("results.count");	 ARshape=0;
				
				for(inn=0; inn<getValue("results.count"); inn++){
					maxsize0=getResult("Area", inn);
					
					if(maxsize0>maxsizeData){
						ARshape=getResult("AR", inn);// AR value from Triangle
						Anglemax=getResult("Angle", inn);
						Circ=getResult("Circ.", inn);
						Circ=parseFloat(Circ);//Chaneg string to number
						//		print(Circ+" Circ");
						maxsizeData=maxsize0;
						
						ixcenter=getResult("X", inn);
						iycenter=getResult("Y", inn);
						
						//					print("maxsizeData; "+maxsizeData+"   ARshape; "+ARshape);
					}
				}//for(inn=0; inn<nResults; inn++){
				
				if(ABSMaxARShape<ARshape){
					ABSMaxARShape=ARshape;
					
					ABSmaxSize=maxsizeData;
					ABSmaxCirc=Circ;
				}
				
				if(maxsizeData>(130000/MaxZoom)/Zoomratio && maxsizeData<(570000/MaxZoom)/Zoomratio && ARshape>1.3){
					
					selectWindow("DUPprojection.tif");// binary mask
					
					//			setBatchMode(false);
					//					updateDisplay();
					//					aa
					
					run("Size...", "width="+round(getWidth*ZoomratioSmall)+" height="+round(getHeight*ZoomratioSmall)+" depth=1 constrain interpolation=None");
					run("Canvas Size...", "width=102 height=102 position=Center zero");
					if(bitDepth==8)
					run("16-bit");
					if(OBJScoreOri>600){
						run("Rotation Hideo", "rotate="+OriginalRot+" in=InMacro");
						rotSearch=5;
					}else
					rotSearch=55;
					
					//					setBatchMode(false);
					//					updateDisplay();
					//					"do"
					//					exit();
					
					
					ImageCarray=newArray(0, 0, 0, 0);
					ImageCorrelation2 ("DUPprojection.tif", "JFRC2010_ShapeMatchingMask.tif", rotSearch,ImageCarray,90,numCPU);
					
					OBJScore=ImageCarray[0];
					Rot=ImageCarray[1];
					ShiftY=ImageCarray[2];
					ShiftX=ImageCarray[3];
					
					//		print("OBJScore from Image2; "+OBJScore+"   ARshape; "+ARshape +"   Circ; "+Circ);
					
					if(OBJScore>MaxOBJScore){
						MaxOBJScore=OBJScore;
						MaxRot=Rot;
						
						//		if(MaxOBJScore>680){
						//			print("Circ; "+Circ);
						//			print("ARshape; "+ARshape);
						
						//			setBatchMode(false);
						//			updateDisplay();
						//			aa
						//		}
						
						if(ARshape>maxARshape){//&& ARshape>1.7
							if(Circ>MaxCirc-0.04){//0.16 is min
								maxARshape=ARshape;
								
								if(MaxCirc<Circ)
								MaxCirc=Circ;
								
								print("MIPstep; "+MIPstep+"   lower; "+lower+"   maxARshape; "+maxARshape+"   Circ; "+Circ+"   ThreTry; "+ThreTry+"   maxsizeData; "+maxsizeData+"  MaxOBJScore; "+MaxOBJScore);
								
								ID20xMIP=1;
								numberResults=1;
								
								elipsoidAngle = Anglemax;
								
								if (elipsoidAngle>90) 
								elipsoidAngle = -(180 - elipsoidAngle);
								
								if (MIPstep==1)
								finalMIP="Ave projection";
								
								if (MIPstep==2)
								finalMIP="Max projection";
								
								positiveAR=0; firstTime=1;
								lowerM=lower; threTry=ThreTry; angle=elipsoidAngle; SizeM=maxsizeData;
								
								xcenter=ixcenter; ycenter=iycenter;
								//		if(MIPstep==2){
								//			setBatchMode(false);
								//			updateDisplay();
								//			"do"
								//			exit();
								//		}
								
							}else{
								positiveAR=positiveAR+1;
							}
						}//	if(ARshape>maxARshape){//&& ARshape>1.7
					}
				}else{
					
					positiveAR=positiveAR+1;
				}//if(maxsizeData>250000 && maxsizeData<470000){
			}else{
				positiveAR=positiveAR+1;
				
			}//if(nResults>0){
			
			if(positiveAR>=40){
				if(firstTime==1)
				ThreTry=maxThreTry;
			}
			
			if(firstTime==1 && ThreTry>3)
			ThreTry=maxThreTry;
			
			if(isOpen(DUPprojection)){
				selectImage(DUPprojection);
				close();
			}
			while(isOpen("DUPprojection.tif")){
				selectWindow("DUPprojection.tif");
				close();
			}
			
			//			titlelist=getList("image.titles");
			//			for(iImage=0; iImage<titlelist.length; iImage++){
			//				print("Opened; "+titlelist[iImage]);
			//			}
			
			
			//		if(titlelist.length>channels+2){
			//				for(iImage=0; iImage<titlelist.length; iImage++){
			//					if(channels==2){
			//						if(titlelist[iImage]!=Original3D[0] && titlelist[iImage]!=Original3D[1] && titlelist[iImage]!=Original3D[2] && titlelist[iImage]!="OriginalProjection.tif"){
			//							selectWindow(titlelist[iImage]);
			//							close();
			//						print("Closed; "+titlelist[iImage]);
			//					}
			//					}//if(channels==2){
			
			//					}
			//				}//	if(titlelist.length>channels){
		}//for(ThreTry=0; ThreTry<3; ThreTry++){
		
		if(lowerM!=3 && prelower!=lowerM){
			print("MIPstep; "+MIPstep+"   lowerM; "+lowerM+"   threTry; "+threTry+"   angle; "+angle+"   SizeM; "+SizeM+"   maxARshape; "+maxARshape+"  MaxCirc; "+MaxCirc+"   ID20xMIP; "+ID20xMIP);
			prelower=lowerM;
		}
		if(isOpen(OriginalProjection)){
			selectImage(OriginalProjection);
			close();
		}
	}//for(MIPstep=1; MIPstep<3; MIPstep++){
	
	if(OBJScoreOri>600 || angle==400)// angle ==400 is initial setting, could not detect the brain in the mask process
	elipsoidAngle=OriginalRot;
	else
	elipsoidAngle=angle;
	
	ImageAligned=0;
	
	print("MaxOBJScore; "+MaxOBJScore+"   MaxRot; "+angle);
}else{//if(BrainShape=="Intact"){ // if brain is not intact
	maxY = OriginalYshift/2;
	maxX = OriginalXshift/2;
	ID20xMIP=1;
	ImageAligned=1;// this means, xy shift + rotation are already known
	finalMIP="Max projection";
	SizeM=1; 
}
if(ID20xMIP==0){
	print("could not segment by normal method");
	/// rescue code with Image correlation ////////////////////////////
	ImageCorrelationArray=newArray(nc82, ImageAligned,0,0,0,0,0);
	ImageCorrelation (ImageCorrelationArray,widthVx,numCPU);
	ImageAligned=ImageCorrelationArray[1];
	//		maxX=ImageCorrelationArray[2];
	//		maxY=ImageCorrelationArray[3];
	//		elipsoidAngle=ImageCorrelationArray[4];
	OBJScore=ImageCorrelationArray[5];
	
	if(ImageAligned==1){// if rescued
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
		MIPstep=2;
	}else{
		print("AR shape/size is too low, might be no optic lobe; ABSMaxARShape; "+ABSMaxARShape+"  ABSmaxSize; "+ABSmaxSize+"  ABSmaxCirc; "+ABSmaxCirc);
		
		maxY = OriginalYshift/2;
		maxX = OriginalXshift/2;
		
		ID20xMIP=1;
		finalMIP="Max projection";
		SizeM=1; 
		MIPstep=2;
		
		selectImage(nc82);
		run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");
		run("Grays");
		resetMinAndMax();
		run("8-bit");
		saveAs("PNG", ""+myDir0+noext+"_MaxAR_"+ABSMaxARShape+"_Shape.png");//save 20x MIP mask
		saveAs("PNG", ""+mask+noext+"_MaxAR_"+ABSMaxARShape+"_Shape.png");//save 20x MIP mask
		saveAs("PNG", ""+savedir+noext+"_MaxAR_Shape.png");
		close();
	}
}
logsum=getInfo("log");
File.saveString(logsum, filepath);
if(NRRD_02_ext==1 || nrrdEx==true){
	ID20xMIP=1;
	SizeM=1;
}

if(SizeM!=0){
	if(ID20xMIP!=0){// AR shape is more than 1.7
		
		if(NRRD_02_ext==0){
			MIPstep=1;
			if(finalMIP=="Max projection")
			MIPstep=2;
			
			print("   finalMIP; "+finalMIP+"   MIPstep; "+MIPstep+"   ImageAligned; "+ImageAligned);
			
			selectImage(nc82);
			
			
			if(MIPstep==1)
			run("Z Project...", "start=10 stop="+nSlices-10+" projection=[Average Intensity]");// imageID is AR
			else if(MIPstep==2)
			run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
			
			MIP2nd=getImageID();
			
			if(ImageAligned==0){
				print("lowerM; final "+lowerM);
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				setThreshold(lowerM, maxvalue0);
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0, 0, 0);
				run("Make Binary", "thresholded remaining");
				
				run("Minimum...", "radius=5");// previously size was 5, 5 gives me lower thresholding value than 2, then 2 can give OP connection this time
				run("Maximum...", "radius=5");
				
				//			setBatchMode(false);
				//			updateDisplay();
				//			"do"
				//			exit();
				
				//		setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
				
				
				run("Select All");
				run("Copy");
				
				run("Fill Holes");
				getStatistics(area, meanHole, minHole, maxHole, stdHole, histogramHole);
				
				if(meanHole==0){
					run("Paste");
					run("Grays");
					run("Fill Holes");
				}
				
				if(meanHole==255)
				run("Paste");
				
				
				run("Analyze Particles...", "size="+(130000/MaxZoom)/Zoomratio+"-Infinity show=Masks display clear");//run("Analyze Particles...", "size=200000-Infinity show=Masks display exclude clear");
				ID20xMIP=getImageID();//このマスクを元にしてローテーション、中心座標を得る
				
				run("Grays");
				
				//			setBatchMode(false);
				//						updateDisplay();
				//						"do"
				//						exit();
				
				run("Canvas Size...", "width="+cropWidth+300+" height="+cropWidth+300+" position=Center zero");
				//		run("Rotation Hideo", "rotate="+elipsoidAngle+" in=InMacro");
				run("Rotate... ", "angle="+elipsoidAngle+" grid=1 interpolation=None enlarge");//Rotate mask to horizontal
				
				AFxsize=getWidth();
				AFysize=getHeight();
				
				run("Size...", "width="+AFxsize*MaxZoom*Zoomratio+" height="+AFysize*MaxZoom*Zoomratio+" constrain interpolation=None");
				run("Canvas Size...", "width="+AFxsize+" height="+AFysize+" position=Center zero");
				run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width=1 pixel_height=1 voxel_depth=1");
				
				print("after rotation; AFxsize; "+AFxsize+"   AFysize; "+AFysize);
				
				ScanMakeBinary ();
				
				//		setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
				
				if(getValue("results.count")==0){
					"Could not detect brain mask in line 1306";
					exit();
				}else{
					
					AnalyzeCArray=newArray(SizeM, 0, 0);
					analyzeCenter(AnalyzeCArray);
					
					xcenter=AnalyzeCArray[1];
					ycenter=AnalyzeCArray[2];
					
					xcenter=round(xcenter);
					ycenter=round(ycenter);
					
					print("CX="+xcenter);
					print("CY="+ycenter);
					
					xgapleft=0;
					if(xcenter<=cropWidth/2)
					xgapleft=cropWidth/2-xcenter;
					
					//	setBatchMode(false);
					//	updateDisplay();
					//	"do"
					//	exit();
					
					selectImage(ID20xMIP);
					canvasenlarge(xcenter,cropWidth);
					xsize=getWidth();
					ysize=getHeight();
					
					
					print("803 xcenter; "+xcenter+" , xgapleft; "+xgapleft+" , xsize; "+xsize+"   ysize; "+ysize+"  cropWidth/2; "+cropWidth/2);
					makeRectangle(round(xcenter+xgapleft-cropWidth/2), round(ycenter-cropHeight/2-shiftY), cropWidth, cropHeight);//cropping brain Mask
					run("Crop");
					
					run("Duplicate...", "title=DupMask2D.tif");
					DupMask=getImageID();
					
				}
				//				setBatchMode(false);
				//				updateDisplay();
				//				"do"
				//				exit();
			}//ImageAligned==0
			resliceLongLength=round(sqrt(height*height+width*width));
			print("elipsoidAngle; "+elipsoidAngle);
			if(ImageAligned==1){
				ID20xMIP=getImageID();//Z projection.. may need threshold to be mask
				
				run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
				getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
				if(bitDepth==8)
				run("16-bit");
				run("Rotation Hideo", "rotate="+elipsoidAngle+" in=InMacro");
				
				run("Translate...", "x="+round(maxX*20*Zoomratio)+" y="+round(maxY*20*Zoomratio)+" interpolation=None");
				setVoxelSize(LVxWidth*MaxZoom, LVxHeight*MaxZoom, LVxDepth, LVxUnit);//reslice
				run("Canvas Size...", "width="+cropWidth+" height="+cropHeight+" position=Center zero");
				
				run("Duplicate...", "title=DupMask2D.tif");
				DupMask=getImageID();
				
				xsize=getWidth();
				ysize=getHeight();
			}//if(ImageAligned==1){
			
			
			//	setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//	exit();
			print("1404 shiftY; "+shiftY);
			ycenterCrop=cropHeight/2+shiftY-30;
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			//		setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//		exit();
			
			run("8-bit");
			setThreshold(1, 255);
			setForegroundColor(255, 255, 255);
			setBackgroundColor(0, 0, 0);
			run("Make Binary", "thresholded remaining");
			//// optic lobe detection //////////////////////////////////////////
			run("Watershed");// clip optic lobe out
			
			
			run("Analyze Particles...", "size=4000-Infinity display clear");
			
			//		setBatchMode(false);
			//		updateDisplay();
			//		"do"
			//		exit();
			
			sizeDiffOp= newArray(getValue("results.count")); sizediff1=300000; sizediff2=300000;
			minX1position=10000;
			
			xdistancearray=newArray(getValue("results.count")); ydistancearray=newArray(getValue("results.count")); AreaArray=newArray(getValue("results.count"));
			
			for(xdistance=0; xdistance<getValue("results.count"); xdistance++){// array creation for analyzed objects
				xdistancearray[xdistance]=getResult("X", xdistance);
				ydistancearray[xdistance]=getResult("Y", xdistance);
				AreaArray[xdistance]=getResult("Area", xdistance);
			}
			
			//// optic lobe detection and building OL from smaller segments ///////////////////////////////
			optic1_Xposition_sum=0; optic1_object=0; optic1_Area_sum=0; optic1_Yposition_sum=0;
			optic2_Xposition_sum=0; optic2_object=0; optic2_Area_sum=0; optic2_Yposition_sum=0;
			oticLobe2Area=0; oticLobe1Area=0; sizediff2=0; sizediff1=0;
			
			for(opticL1=0; opticL1<getValue("results.count"); opticL1++){
				
				opticlobe1Gap=abs(xdistancearray[opticL1]-((280/1200)*cropWidth));//  300 220 is average of left optic lobe central X
				opticlobe2Gap=abs(xdistancearray[opticL1]-((950/1200)*cropWidth));// 920 981 is average of left optic lobe central X
				
				if(opticlobe1Gap<120)
				optic1_Area_sum=optic1_Area_sum+AreaArray[opticL1];
				
				
				if(opticlobe2Gap<120)
				optic2_Area_sum=optic2_Area_sum+AreaArray[opticL1];
			}
			
			
			for(opticL=0; opticL<getValue("results.count"); opticL++){
				
				opticlobe1Gap=abs(xdistancearray[opticL]-((280/1200)*cropWidth));//  300 220 is average of left optic lobe central X
				opticlobe2Gap=abs(xdistancearray[opticL]-((950/1200)*cropWidth));// 920 981 is average of left optic lobe central X
				
				if(opticlobe1Gap<120){
					optic1_Xposition_sum=optic1_Xposition_sum+(xdistancearray[opticL]*(AreaArray[opticL]/optic1_Area_sum));
					
					optic1_Yposition_sum=optic1_Yposition_sum+(ydistancearray[opticL]*(AreaArray[opticL]/optic1_Area_sum));
					
					
					optic1_object=optic1_object+1;
				}
				
				if(opticlobe2Gap<120){
					print("opticlobe2Gap; "+opticlobe2Gap);
					optic2_Xposition_sum=optic2_Xposition_sum+(xdistancearray[opticL]*(AreaArray[opticL]/optic2_Area_sum));
					
					optic2_Yposition_sum=optic2_Yposition_sum+(ydistancearray[opticL]*(AreaArray[opticL]/optic2_Area_sum));
					
					
					optic2_object=optic2_object+1;
				}
			}//for(opticL=0; opticL<nResults; opticL++){
			
			x1_opl=optic1_Xposition_sum;
			y1_opl=optic1_Yposition_sum;
			sizediff1=abs(80000-optic1_Area_sum);
			
			x2_opl=optic2_Xposition_sum/optic2_object;
			y2_opl=optic2_Yposition_sum/optic2_object;
			sizediff2=abs(80000-optic2_Area_sum);
			
			print("oticLobe1Area; "+optic1_Area_sum+"  OL1 is "+optic1_object+" peaces. "+"  oticLobe2Area; "+optic2_Area_sum+"  optic2_Area_sum; "+optic2_Area_sum+"  OL2 is "+optic2_object+" peaces. ");
			ImageAligned2=0; 
			x1_opl=round(x1_opl); x2_opl=round(x2_opl); y1_opl=round(y1_opl); y2_opl=round(y2_opl);
			OpticLobeSizeGap=60000;
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			// if optioc lobe is not exist ///////////////////////////
			if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap){
				if(BrainShape=="Intact"){		
					print("Optic lobe shape / segmentation problem!!!!!!!!!");
					print("Opticlobe1 size gap; "+sizediff1+"  Opticlobe1 center X,Y; ("+x1_opl+" , "+y1_opl+") / "+ycenterCrop+"  Opticlobe2 size gap; "+sizediff2+"  Opticlobe2 center X,Y; ("+x2_opl+" , "+y2_opl+")");
					
					ImageCorrelationArray=newArray(nc82, ImageAligned2,0,0,0,0,0);
					ImageCorrelation (ImageCorrelationArray,widthVx,numCPU);
					ImageAligned2=ImageCorrelationArray[1];
					
					print("ImageAligned2; "+ImageAligned2);
					
					logsum=getInfo("log");
					File.saveString(logsum, filepath);
					
					maxX=ImageCorrelationArray[2];
					maxY=ImageCorrelationArray[3];
					//		elipsoidAngle=ImageCorrelationArray[4];
					ImageAligned=ImageAligned2;// obj score, if more than 0.6, will be 1
					OBJScore=ImageCorrelationArray[5];
					
					if(ImageAligned2==0){// if shape problem
						selectImage(DupMask);
						run("Grays");
						
						saveAs("PNG", ""+myDir0+noext+"_OP_Shape_MASK.png");//save 20x MIP mask
						saveAs("PNG", ""+savedir+noext+"_OP_Shape_MASK.png");
						
						selectImage(nc82);
						run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
						MIP2ID=getImageID();
						run("Enhance Contrast", "saturated=0.35");
						getMinAndMax(min, max);
						setMinAndMax(min, max);
						print("max; "+max);
						
						if(max!=maxvalue0 && max!=255)
						run("Apply LUT");
						
						run("8-bit");
						run("Grays");
						saveAs("PNG", ""+myDir0+noext+"_OP_Shape.png");//save 20x MIP mask
						
						selectImage(MIP2ID);
						close();
						
						y1_opl=cropHeight*2;
						y2_opl=cropHeight;
					}// if(ImageAligned2==0){// if shape problem
					//		selectImage(ID20xMIP);
					//		close();
				}
			}//if(sizediff2>50000 || sizediff1>50000){
			
			selectImage(DupMask);
			close();
			
			selectImage(MIP2nd);
			close();
			
			selectImage(ID20xMIP);
			
			if(y1_opl!=cropHeight*2)// if no shape problem
			print("Opticlobe1 size gap; "+sizediff1+"  Opticlobe1 center X,Y; ("+x1_opl+" , "+y1_opl+") / "+ycenterCrop+"  Opticlobe2 size gap; "+sizediff2+"  Opticlobe2 center X,Y; ("+x2_opl+" , "+y2_opl+")");
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			wait(100);
			call("java.lang.System.gc");
			
			/// if brain is upside down /////////////////////////////
			xcenter2=xcenter;
			if(y1_opl<ycenterCrop && y2_opl<ycenterCrop && ImageAligned==0){// if optic lobe is higer position, upside down
				if(bitDepth==8)
				run("16-bit");
				run("Rotation Hideo", "rotate=180 in=InMacro");
				//		run("Rotate... ", "angle=180 grid=1 interpolation=None");//Rotate mask to 180 degree
				print(" 180 rotated");
				ycenter=ysize-ycenter;
				xcenter2=xsize-xcenter;
				
				xgapleft=0;
				if(xcenter2 <= (cropWidth/2))
				xgapleft=(cropWidth/2)*Zoomratio-xcenter2;
				canvasenlarge(xcenter2,cropWidth);
				
				rotationYN="Yes";
				print("xcenter2; "+xcenter2+" , xgapleft; "+xgapleft+" , xsize; "+xsize+"  cropWidth/2; "+cropWidth/2);
				
				makeRectangle(round(xcenter2+xgapleft-(cropWidth/2)*Zoomratio), round(ycenter-round(cropHeight/2)*Zoomratio-shiftY), round(cropWidth*Zoomratio), round(cropHeight*Zoomratio));//cropping brain Mask
				run("Crop");
			}//if(y1_opl<ycenterCrop && y2_opl<ycenterCrop){// if optic lobe is higer position, upside down
			
			
			if(y1_opl!=cropHeight*2){// if no shape problem
				OBJV="";
				if(ImageAligned2==1){
					run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
					getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
					print("1600 Translated X; "+round(maxX*20*Zoomratio)+"  Y; "+round(maxY*20*Zoomratio)+", nc82, elipsoidAngle; "+elipsoidAngle);
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
					
					run("Translate...", "x="+round(maxX*20*Zoomratio)+" y="+round(maxY*20*Zoomratio)+" interpolation=None stack");
					
					setVoxelSize(LVxWidth*MaxZoom, LVxHeight*MaxZoom, LVxDepth, LVxUnit);//reslice
					run("Canvas Size...", "width="+round(cropWidth*Zoomratio)+" height="+round(cropHeight*Zoomratio)+" position=Center zero");
					OBJV="_"+OBJScore;
				}
				
				path20xmask=mask+noext;
				
				resetMinAndMax();
				run("8-bit");
				print("8bit");
				
				setThreshold(1, 255);
				setForegroundColor(255, 255, 255);
				setBackgroundColor(0, 0, 0);
				run("Make Binary", "thresholded remaining");
				
				run("Watershed");
				run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+heightVx+" voxel_depth="+depth+"");
				
				//		setVoxelSize(widthVx, heightVx, depth, unit);
				run("Grays");
				saveAs("PNG", ""+path20xmask+OBJV+".png");//save 20x MIP mask
			}
			close();// MIP
			//		setBatchMode(false);
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			selectImage(nc82);
			wait(100);
			call("java.lang.System.gc");
			if(ImageAligned==0){
				
				run("Canvas Size...", "width="+xsize+" height="+ysize+" position=Center zero");
				//		run("Rotate... ", "angle="+elipsoidAngle+" grid=1 interpolation=None enlarge");//Rotate mask to horizontal
				if(bitDepth==8)
				run("16-bit");
				run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
				canvasenlarge(xcenter,cropWidth);
				
				//		setBatchMode(false);
				//		updateDisplay();
				//		"do"
				//		exit();
				
				xsize=getWidth();
				ysize=getHeight();
				
				if(rotationYN=="Yes"){
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate=180 3d in=InMacro");
					canvasenlarge(xcenter2,cropWidth);
				}
				
				//		run("Canvas Size...", "width="+cropWidth+" height="+cropHeight+" position=Center zero");
				print("1003 xcenter2; "+xcenter2+" , xgapleft; "+xgapleft+" , xsize; "+xsize+"   ysize; "+ysize+"  cropWidth/2; "+cropWidth/2);
				makeRectangle(round(xcenter2+xgapleft-(cropWidth/2)/Zoomratio), round(ycenter-(cropHeight/2)/Zoomratio-shiftY), round(cropWidth/Zoomratio), round(cropHeight/Zoomratio));//cropping brain
				run("Crop");
			}
			
			//	setBatchMode(false);
			//	updateDisplay();
			//	"do"
			//	exit();
			
			if(ImageAligned==1){
				run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
				getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
				print("Translated X; "+round(maxX*20*Zoomratio)+"  Y; "+round(maxY*20*Zoomratio)+", nc82, elipsoidAngle; "+elipsoidAngle);
				if(bitDepth==8)
				run("16-bit");
				run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
				
				run("Translate...", "x="+round(maxX*20*Zoomratio)+" y="+round(maxY*20*Zoomratio)+" interpolation=None stack");
				
				setVoxelSize(LVxWidth*MaxZoom, LVxHeight*MaxZoom, LVxDepth, LVxUnit);//reslice
				run("Canvas Size...", "width="+round(cropWidth/Zoomratio)+" height="+round(cropHeight/Zoomratio)+" position=Center zero");
				
				sizediff2=OpticLobeSizeGap; sizediff1=OpticLobeSizeGap;
				//			setBatchMode(false);
				//			updateDisplay();
				//			"do"
				//			exit();
				
			}
			resetBrightness(maxvalue0);				
			
	//		for(slii=1; slii<=NC82SliceNum; slii++){
	//			setSlice(slii);
	//			if(bitDepth==16)
	//			run("Enhance Local Contrast (CLAHE)", "blocksize=125 histogram=4095 maximum=8 mask=*None* fast_(less_accurate)");
	//			else if (bitDepth==8)
	//			run("Enhance Local Contrast (CLAHE)", "blocksize=125 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
			//		}
			
		}//if(NRRD_02_ext==0){
		if(ChannelInfo=="01 02 nrrd files" || ChannelInfo=="Both formats"){
			//		setVoxelSize(widthVx, heightVx, incredepth, unit);
			
			run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+heightVx+" voxel_depth="+depth+"");
			print("run properties; 1630");
			
			logsum=getInfo("log");
			File.saveString(logsum, filepath);
			
			if(NRRD_02_ext==0){
			selectImage(nc82);
			lateralArray=newArray(0, 0,0,0,0,0);
			lateralDepthAdjustment(x1_opl,x2_opl,lateralArray,nc82,templateBr,numCPU);
			incredepth=lateralArray[0];
			nc82=lateralArray[1];
			maxrotation=lateralArray[2];
			LateralXtrans=lateralArray[3];
			LateralYtrans=lateralArray[4];
			OBJL=lateralArray[5];
			}
			
			if(widthVx==1 || ForceUSE==true){
				heightVx=DesireX;
				widthVx=DesireX;
				print("Voxel size changed from 1 to "+widthVx);
			}
			
			if(OBJL<500){
				if(templateBr=="JFRC2010" || templateBr=="JFRC2013"){
					incredepth=218/NC82SliceNum;//ADJUSTING sample depth size to template , z=1 micron template
					
					if(TwentyMore!=0)
					incredepth=incredepth*(1+TwentyMore/100);
					
					
				}else if(templateBr=="JFRC2014"){
					
					if(depth!=1){
						tempthinkness=151;
						sampthickness=depth*NC82SliceNum;
						
						incredepth=tempthinkness/sampthickness;//ADJUSTING sample depth size to template 
					}else
					incredepth=(218/NC82SliceNum)*0.69;
					
				}//	if(templateBr=="JFRC2010"){
			}//if(OBJL<700){
			
			
			
			String.resetBuffer;
			n3 = lengthOf(noext);
			for (si=0; si<n3; si++) {
				c = charCodeAt(noext, si);
				if(c==32){// if there is a space
					print("There is a space, replaced to _.");
					c=95;
				}
				if (c>=32 && c<=127)
				String.append(fromCharCode(c));
				
				noext3 = String.buffer;
			}//	for (si=0; si<n3; si++) {
			noext=noext3;
			String.resetBuffer;
			
			run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+heightVx+" voxel_depth="+incredepth+"");
			
			
			if(NRRD_02_ext==0){
				oriwindow=getTitle();
				
				run("Gamma ", "gamma=1.60 3d in=InMacro cpu="+numCPU+"");
				gumnc82=getImageID();
				
				selectWindow(oriwindow);
				close();
				
				selectImage(gumnc82);
				nc82=getImageID();
				rename("nc82.tif");
				
				if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap || y1_opl==cropHeight*2)
				run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_01.nrrd");
				else
				run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_01.nrrd");
				
				run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");
				run("Grays");
				run("8-bit");
				if(ImageAligned==1)
				saveAs("JPEG", ""+savedir+noext+"_obj"+OBJScore+".jpg");//save 20x MIP
				else
				saveAs("JPEG", ""+savedir+noext+".jpg");//save 20x MIP
				close();
			}//if(NRRD_02_ext==0){
			
			if(channels>1){
				selectImage(nc82);
				if(ChannelInfo!="Both formats"){
					close();
					if(isOpen("nc82.tif")){
						selectWindow("nc82.tif");
						close();
					}
				}
			}
			//			print("");
			//			titlelist=getList("image.titles");
			//			for(iImage=0; iImage<titlelist.length; iImage++){
			//				print("Opened; "+titlelist[iImage]);
			//			}
			
			if(NRRD_02_ext==0){
				startNeuronNum=1;
				AdjustingNum=-1;
				
				if(MCFOYN==false)
				maxvalue1=newArray(channels);
				else
				maxvalue1=newArray(5);
				
			}else if (channels>1){
				startNeuronNum=2;
				AdjustingNum=-1;
			}else if (channels==1){
				startNeuronNum=0;
				AdjustingNum=0;
			}
			
			
			for(neuronNum=startNeuronNum; neuronNum<channels+startNeuronNum+AdjustingNum; neuronNum++){
				if(neuronNum==startNeuronNum){
					selectImage(neuron);
					
				}else if (neuronNum==startNeuronNum+1)
				selectImage(neuron2);
				
				if(ImageAligned==0){//if shape problem
					run("Canvas Size...", "width="+xsize+" height="+ysize+" position=Center zero");
					
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
					canvasenlarge(xcenter,cropWidth);
					
					if(neuronNum==startNeuronNum)
					selectImage(neuron);
					else if (neuronNum==startNeuronNum+1)
					selectImage(neuron2);
					
					if(rotationYN=="Yes"){
						if(bitDepth==8)
						run("16-bit");
						run("Rotation Hideo", "rotate=180 3d in=InMacro");
						canvasenlarge(xcenter2,cropWidth);
					}
					if(neuronNum==startNeuronNum)
					selectImage(neuron);
					else if (neuronNum==startNeuronNum+1)
					selectImage(neuron2);
					makeRectangle(round(xcenter2+xgapleft-(cropWidth/2)/Zoomratio), round(ycenter-(cropHeight/2)/Zoomratio-shiftY), round(cropWidth/Zoomratio), round(cropHeight/Zoomratio));//cropping brain
					run("Crop");
				}else{
					run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
					getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
					print("Translated X; "+round(maxX*20*Zoomratio)+"  Y; "+round(maxY*20*Zoomratio)+", nc82, elipsoidAngle; "+elipsoidAngle);
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
					
					run("Translate...", "x="+round(maxX*20*Zoomratio)+" y="+round(maxY*20*Zoomratio)+" interpolation=None stack");
					run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+LVxWidth*MaxZoom+" pixel_height="+LVxHeight*MaxZoom+" voxel_depth="+incredepth+"");
					print("run properties; 1354");
					//				setVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
					run("Canvas Size...", "width="+round(cropWidth/Zoomratio)+" height="+round(cropHeight/Zoomratio)+" position=Center zero");
					
				}//if(ImageAligned==0){//if shape problem
				if(bitDepth==16){
					
					realresetArray=newArray(maxvalue1,0);
					RealReset(realresetArray);
					
					if(neuronNum==startNeuronNum)
					selectImage(neuron);
					else if (neuronNum==startNeuronNum+1)
					selectImage(neuron2);
					
					if(neuronNum!=0)
					maxvalue1[neuronNum-1]=realresetArray[0];
					else
					maxvalue1[neuronNum]=realresetArray[0];
				}
				print("run properties; 1426");
				rename("signalCH.tif");
				signalCH=getImageID();
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				//	if(nrrdindex!=-1){
				//		setBatchMode(false);
				//		updateDisplay();
				//		exit();
				//	}
				
				run("Reslice [/]...", "output=1.000 start=Left rotate avoid");
				rename("resliceN.tif");
				print("Reslice Done 1462");
				if(bitDepth==8)
				run("16-bit");
				
				run("Rotation Hideo", "rotate="+maxrotation+" 3d in=InMacro");
				run("Translate...", "x=0 y="+LateralYtrans+" interpolation=None stack");
				run("Reslice [/]...", "output=1 start=Left rotate avoid");
				rename("RealSignal.tif");
				RealSignal=getImageID();
				
				print("Neuron reslice & rotated; "+neuronNum);
				run("Properties...", "channels=1 slices="+NC82SliceNum+" frames=1 unit=microns pixel_width="+widthVx+" pixel_height="+heightVx+" voxel_depth="+incredepth+"");
				
				if(Nrrdnumber==0){
					
					if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap|| y1_opl==cropHeight*2)
					run("Nrrd Writer", "compressed nrrd="+myDir0+noext+"_0"+neuronNum+1+".nrrd");
					else
					run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_0"+neuronNum+1+".nrrd");
				}else{
					run("Nrrd Writer", "compressed nrrd="+savedir+noext+"_0"+Nrrdnumber+".nrrd");					
				}
				if(ChannelInfo!="Both formats"){
					close();//RealSignal
					while(isOpen("RealSignal.tif")){
						selectWindow("RealSignal.tif");
						close();
					}
				}
				
				selectImage(signalCH);
				close();
				
				while(isOpen("signalCH.tif")){
					selectWindow("signalCH.tif");
					close();
				}
				
				while(isOpen("resliceN.tif")){
					selectWindow("resliceN.tif");
					close();
				}
				if(isOpen(RealSignal))
				selectImage(RealSignal);
				
			}//for(neuronNum=1; neuronNum<channels; neuronNum++){
			
			if(ChannelInfo=="Both formats"){
				selectImage(nc82);
				run("Half purple");
				rename("nc82.tif");
				
				selectImage(neuron);
				rename("neuron.tif");
				
				if(channels==3){
					selectImage(neuron2);
					rename("neuron2.tif");
				}
				if(channels==4){
					selectImage(neuron3);
					rename("neuron3.tif");
				}
				
				MergeCH(channels,bitDepth,maxvalue0);
				
				if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap || y1_opl==cropHeight*2)
				saveAs("ZIP", ""+myDir0+noext+".zip");
				else
				saveAs("ZIP", ""+savedir+noext+".zip");
				close();
			}//	if(ChannelInfo=="Both formats"){
		}//	if(ChannelInfo=="01 02 nrrd files"){
		
		if(ChannelInfo=="multi-colors, single file .tif.zip"){
			selectImage(nc82);
			run("Half purple");
			rename("nc82.tif");
			
			for(neuronNum=1; neuronNum<channels; neuronNum++){
				if(neuronNum==1)
				selectImage(neuron);
				else if (neuronNum==2)
				selectImage(neuron2);
				else if (neuronNum==3)
				selectImage(neuron3);
				
				if(ImageAligned==0){
					run("Canvas Size...", "width="+cropWidth+300+" height="+cropWidth+300+" position=Center zero");
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
					//	run("Rotate... ", "angle="+elipsoidAngle+" grid=0 interpolation=None enlarge stack");//Rotate mask to horizontal
					canvasenlarge(xcenter,cropWidth);
					
					if(rotationYN=="Yes"){
						run("Rotation Hideo", "rotate=180 3d in=InMacro");
						//			run("Rotate... ", "angle=180 grid=1 interpolation=None stack");//Rotate mask to 180 degree
						canvasenlarge(xcenter2,cropWidth);
					}
					makeRectangle(round(xcenter2+xgapleft-(cropWidth/2)/Zoomratio), round(ycenter-(cropHeight/2)/Zoomratio-shiftY), round(cropWidth/Zoomratio), round(cropHeight/Zoomratio));//cropping brain
					run("Crop");
				}else{
					run("Canvas Size...", "width="+resliceLongLength+" height="+resliceLongLength+" position=Center zero");
					getVoxelSize(LVxWidth, LVxHeight, LVxDepth, LVxUnit);//reslice
					print("Translated X; "+round(maxX*20*Zoomratio)+"  Y; "+round(maxY*20*Zoomratio)+", nc82, elipsoidAngle; "+elipsoidAngle);
					if(bitDepth==8)
					run("16-bit");
					run("Rotation Hideo", "rotate="+elipsoidAngle+" 3d in=InMacro");
					
					run("Translate...", "x="+round(maxX*20*Zoomratio)+" y="+round(maxY*20*Zoomratio)+" interpolation=None stack");
					
					setVoxelSize(LVxWidth*MaxZoom, LVxHeight*MaxZoom, LVxDepth, LVxUnit);//reslice
					run("Canvas Size...", "width="+round(cropWidth/Zoomratio)+" height="+round(cropHeight/Zoomratio)+" position=Center zero");
				}
				
				logsum=getInfo("log");
				File.saveString(logsum, filepath);
				
				if(bitDepth==16){
					if(neuronNum==1)
					maxvalue1=newArray(channels);
					
					realresetArray=newArray(maxvalue1,0);
					RealReset(realresetArray);
					maxvalue1[neuronNum-1]=realresetArray[0];
				}
				
				if(neuronNum==1)
				rename("neuron.tif");
				else if (neuronNum==2)
				rename("neuron2.tif");
				else if (neuronNum==3)
				rename("neuron3.tif");
			}
			
			MergeCH(channels,bitDepth,maxvalue0);
			
			setVoxelSize(widthVx, heightVx, depth*incredepth, unit);
			rename(noext+".tif");
			
			if(sizediff2>OpticLobeSizeGap || sizediff1>OpticLobeSizeGap || y1_opl==cropHeight*2)
			saveAs("ZIP", ""+myDir0+noext+".zip");
			else
			saveAs("ZIP", ""+savedir+noext+".zip");
		}//if(ChannelInfo=="multi-colors, single file .tif.zip"){
	}//if(ID20xMIP!=0){
	if(channels>2)
	print(channels+" exist!! "+list[filen]+"; "+filen);
}else{//if(maxsizeData!=0){
	
	selectImage(nc82);
	run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");// imageID is AR
	MIP2ID=getImageID();
	run("Enhance Contrast", "saturated=0.35");
	getMinAndMax(min, max);
	setMinAndMax(min, max);
	print("max; "+max);
	
	if(max!=maxvalue0 && max!=255)
	run("Apply LUT");
	
	run("8-bit");
	run("Grays");
	saveAs("PNG", ""+myDir0+noext+"_OP_Shape.png");//save 20x MIP mask
	saveAs("PNG", ""+savedir+noext+"_OP_Shape_MASK.png");
}

run("Close All");

List.clear();
"Done"

enda=getTime();
gaptime=(enda-starta)/1000;

print("processing time; "+gaptime/60+" min");

logsum=getInfo("log");
File.saveString(logsum, filepath);

run("Quit");

function TwoDfillHole (){// accept binary
	run("Select All");
	run("Copy");
	
	run("Fill Holes");
	
	for(ix=0; ix<getWidth; ix++){
		if(getPixel(ix, 0)!=0){
			posiSum=posiSum+1;
		}
	}
	
	if(posiSum>(getWidth/2)){
		run("Paste");
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		run("Fill Holes");
	}
	
}

function ScanMakeBinary (){
	
	run("Select All");
	run("Copy");
	
	setThreshold(1, 255);
	setForegroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
	run("Make Binary", "thresholded remaining");
	
	posiSum=0;
	for(ix=0; ix<getWidth; ix++){
		if(getPixel(ix, 0)!=0){
			posiSum=posiSum+1;
		}
	}
	
	if(posiSum>(getWidth*0.4)){
		run("Paste");
		run("Grays");
		setThreshold(1, 255);
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Make Binary", "thresholded remaining");
	}
	posiSum2=0;
	for(ix2=0; ix2<getWidth; ix2++){
		if(getPixel(ix2, 0)!=0){
			posiSum2=posiSum2+1;
		}
	}
	if(posiSum2>(getWidth/2)){
		run("Paste");
		setThreshold(1, 255);
		setForegroundColor(255, 255, 255);
		setBackgroundColor(0, 0, 0);
		run("Make Binary", "thresholded remaining");
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
	}
}

function fileOpen(FilePathArray){
	FilePath=FilePathArray[0];
	MIPname=FilePathArray[1];
	
	//	print(MIPname+"; "+FilePath);
	if(isOpen(MIPname)){
		selectWindow(MIPname);
		tempMask=getDirectory("image");
		FilePath=tempMask+MIPname;
	}else{
		if(FilePath==0){
			
			FilePath=getDirectory("plugins")+MIPname;
			
			tempmaskEXI=File.exists(FilePath);
			if(tempmaskEXI!=1)
			FilePath=getDirectory("plugins")+"Brain_Aligner_Plugins"+File.separator+MIPname;
			
			tempmaskEXI=File.exists(FilePath);
			
			if(tempmaskEXI==1){
				open(FilePath);
			}else{
				print("no file ; "+FilePath);
			}
		}else{
			tempmaskEXI=File.exists(FilePath);
			if(tempmaskEXI==1)
			open(FilePath);
			else{
				print("no file ; "+FilePath);
			}
		}
	}//if(isOpen("JFRC2013_63x_Tanya.nrrd")){
	
	FilePathArray[0]=FilePath;
}

function ImageCorrelation(ImageCorrelationArray,widthVx,numCPU){
	nc82=ImageCorrelationArray[0];
	ImageAligned=ImageCorrelationArray[1];
	
	selectImage(nc82);
	run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Max Intensity]");
	run("Grays");
	rename("SampMIP.tif");
	//	run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=4095 maximum=5 mask=*None* fast_(less_accurate)");
	
	newImage("Mask", "8-bit white", getWidth, getHeight, 1);
	run("Mask Median Subtraction", "mask=Mask data=SampMIP.tif %=90 histogram=100");
	selectWindow("Mask");
	close();
	
	Zoomratio=widthVx/0.62;
	print("1798 Zoomratio; "+Zoomratio+"   widthVx; "+widthVx);
	selectWindow("SampMIP.tif");
	run("Size...", "width="+round((getWidth/20)*Zoomratio)+" height="+round((getHeight/20)*Zoomratio)+" depth=1 constrain interpolation=None");
	run("Canvas Size...", "width=60 height=60 position=Center zero");
	
	//	setBatchMode(false);
	//		updateDisplay();
	//			"do"
	//		exit();
	
	run("Image Correlation Atomic", "samp=SampMIP.tif temp=JFRC2010_50pxMIP.tif +=179 -=180 overlap=80 parallel="+numCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
	
	OBJ=getResult("OBJ score", 0);
	OBJScore=parseFloat(OBJ);
	
	Rot=getResult("rotation", 0);
	Rot=parseFloat(Rot);
	elipsoidAngle=parseFloat(Rot);
	if (elipsoidAngle>90) 
	elipsoidAngle = -(180 - elipsoidAngle);
	
	ShiftY=getResult("shifty", 0);
	maxY=parseFloat(ShiftY);
	
	ShiftX=getResult("shiftx", 0);
	maxX=parseFloat(ShiftX);
	print("initial objectscore; "+OBJScore);
	
	MaxZoom=1;
	if(OBJScore<600){
		selectImage(nc82);
		run("Duplicate...", "title=Samp.tif, duplicate");
		run("16-bit");
		rename("Samp.tif");
		
		run("Size...", "width="+round((getWidth/20)*Zoomratio)+" height="+round((getHeight/20)*Zoomratio)+" depth="+round(nSlices/2)+" constrain interpolation=None");
		run("Canvas Size...", "width=60 height=60 position=Center zero");
		
		//		setBatchMode(false);
		//		updateDisplay();
		//		"do"
		//		exit();
		
		MaxOBJ3Dscan=0;
		print("resizd nSlices; "+nSlices);
		for(inSlice=6; inSlice<nSlices-10; inSlice++){
			selectWindow("Samp.tif");
			setSlice(inSlice);
			run("Duplicate...", "title=SingleSamp.tif");
			
			run("Image Correlation Atomic", "samp=SingleSamp.tif temp=JFRC2010_50pxSlice.tif +=55 -=55 overlap=90 parallel="+numCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
			
			OBJ=getResult("OBJ score", 0);
			OBJScore=parseFloat(OBJ);
			
			selectWindow("SingleSamp.tif");
			close();
			
			if(OBJScore>MaxOBJ3Dscan){
				
				MaxinSlice=inSlice;
				MaxOBJ3Dscan=OBJScore;
				Rot=getResult("rotation", 0);
				Rot=parseFloat(Rot);
				elipsoidAngle=parseFloat(Rot);
				if (elipsoidAngle>90) 
				elipsoidAngle = -(180 - elipsoidAngle);
				
				ShiftY=getResult("shifty", 0);
				maxY=parseFloat(ShiftY);
				
				ShiftX=getResult("shiftx", 0);
				maxX=parseFloat(ShiftX);
			}
		}
		print("MaxinSlice; "+MaxinSlice+"   MaxOBJ3Dscan; "+MaxOBJ3Dscan+"  elipsoidAngle; "+elipsoidAngle);
		OBJScore=MaxOBJ3Dscan;
		selectWindow("Samp.tif");
		close();
		
		if(OBJScore<600){
			PreMaxOBJ=OBJScore; PreOBJ=OBJScore;
			for(iZoom=0.8; iZoom<1.4; iZoom+=0.1){
				selectWindow("SampMIP.tif");
				run("Duplicate...", "title=ZOOM.tif");
				run("Size...", "width="+round(getWidth*iZoom)+" height="+round(getHeight*iZoom)+" depth=1 constrain interpolation=None");
				run("Canvas Size...", "width=60 height=60 position=Center zero");
				
				run("Image Correlation Atomic", "samp=ZOOM.tif temp=JFRC2010_50pxMIP.tif +=180 -=179 overlap=70 parallel="+numCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
				
				OBJ=getResult("OBJ score", 0);
				OBJScore=parseFloat(OBJ);
				
				if(OBJScore>PreMaxOBJ){
					PreMaxOBJ=OBJScore;
					Rot=getResult("rotation", 0);
					Rot=parseFloat(Rot);
					elipsoidAngle=parseFloat(Rot);
					if (elipsoidAngle>90) 
					elipsoidAngle = -(180 - elipsoidAngle);
					
					ShiftY=getResult("shifty", 0);
					maxY=parseFloat(ShiftY);
					
					ShiftX=getResult("shiftx", 0);
					maxX=parseFloat(ShiftX);
					
					MaxZoom=iZoom;
				}
				selectWindow("ZOOM.tif");
				close();
			}
			print("PreOBJ; "+PreOBJ+" NewOBJ; "+PreMaxOBJ+"   elipsoidAngle; "+elipsoidAngle+"   maxY; "+maxY+"   maxX; "+maxX+"   MaxZoom; "+MaxZoom);
			OBJScore=PreMaxOBJ;
		}
		
	}
	
	//setBatchMode(false);
	//updateDisplay();
	//"do"
	//exit();
	
	
	
	while(isOpen("SampMIP.tif")){
		selectWindow("SampMIP.tif");
		close();
	}
	
	if(OBJScore>600){
		ImageAligned=1;
		print("OBJScore; "+OBJScore);
	}
	
	ImageCorrelationArray[1]=ImageAligned;
	ImageCorrelationArray[2]=maxX;
	ImageCorrelationArray[3]=maxY;
	ImageCorrelationArray[4]=elipsoidAngle;
	ImageCorrelationArray[5]=OBJScore;
	ImageCorrelationArray[6]=MaxZoom;
}

function MergeCH(channels,bitDepth,maxvalue0){
	if(channels==3)
	run("Merge Channels...", "c1=nc82.tif c2=neuron.tif c3=neuron2.tif create");
	else if (channels==2)
	run("Merge Channels...", "c1=nc82.tif c2=neuron.tif create");
	else if (channels==4)
	run("Merge Channels...", "c1=nc82.tif c2=neuron.tif c3=neuron2.tif c4=neuron3.tif create");
	
	run("Make Composite");
	
	if(bitDepth==16){
		resetMax(maxvalue0);
		run("Next Slice [>]");
		setMinAndMax(0, maxvalue1[0]);
		
		if(channels==3){
			run("Next Slice [>]");
			setMinAndMax(0, maxvalue1[1]);
		}
		if(channels==4){
			run("Next Slice [>]");
			setMinAndMax(0, maxvalue1[2]);
		}
	}
}

function RealReset(realresetArray){
	run("Max value");
	logsum=getInfo("log");
	endlog=lengthOf(logsum);
	maxposition=lastIndexOf(logsum, "Maxvalue;");
	
	maxvalue1=substring(logsum, maxposition+10, endlog);
	maxvalue1=round(maxvalue1);
	setMinAndMax(0, maxvalue1);
	
	realresetArray[0]=maxvalue1;
}

function resetMax(maxvalue0){
	if(maxvalue0<4096)
	call("ij.ImagePlus.setDefault16bitRange", 12);
	else
	call("ij.ImagePlus.setDefault16bitRange", 16);
}

function canvasenlarge(xcenter,cropWidth){
	xsize3=getWidth();
	ysize3=getHeight();
	done=0;
	if(xcenter<=cropWidth/2){
		run("Canvas Size...", "width="+xsize3+cropWidth/2-xcenter+" height="+ysize3+" position=Top-Right zero");
		done=1;
	}
	xsize3=getWidth();
	if ((xsize3-xcenter)<=cropWidth/2 && xcenter>=cropWidth/2)
	run("Canvas Size...", "width="+cropWidth/2-(xsize3-xcenter)+xsize3+" height="+ysize3+" position=Top-Left zero");
	
	if(xcenter<cropWidth/2 && xsize3<=cropWidth && done==0)
	run("Canvas Size...", "width="+cropWidth+" height="+ysize3+" position=Top-Right zero");
	
	//	setBatchMode(false);
	//	updateDisplay();
	//	aa
}

function analyzeCenter(AnalyzeCArray){
	run("Analyze Particles...", "size="+AnalyzeCArray[0]/2+"-Infinity display clear");
	
	maxarea=0;
	for(maxdecide=0; maxdecide<nResults; maxdecide++){
		
		brainArea = getResult("Area", maxdecide);
		if(brainArea>maxarea){
			maxarea=brainArea;
			xcenterCrop=getResult("X", maxdecide);
			ycenterCrop=getResult("Y", maxdecide);
		}
	}//for(maxdecide=0; maxdecide<nResults; maxdecide++){
	
	AnalyzeCArray[1]=xcenterCrop;
	AnalyzeCArray[2]=ycenterCrop;
}//function analyzeCenter(AnalyzeC_Array){


function resetBrightness(maxvalue0){// resetting brightness if 16bit image
	if(maxvalue0<4096)
	call("ij.ImagePlus.setDefault16bitRange", 12);
	else
	call("ij.ImagePlus.setDefault16bitRange", 16);
}


function colordecision(colorarray){
	posicolor=colorarray[0];
	run("Z Project...", "projection=[Max Intensity]");
	setMinAndMax(0, 10);
	run("RGB Color");
	run("Size...", "width=5 height=5 constrain average interpolation=Bilinear");
	posicolor=0;
	for(colorsizeX=0; colorsizeX<5; colorsizeX++){
		for(colorsizeY=0; colorsizeY<5; colorsizeY++){
			
			Red=0; Green=0; Blue=0;
			colorpix=getPixel(colorsizeX, colorsizeY);
			
			Red = (colorpix>>16)&0xff;  
			Green = (colorpix>>8)&0xff; 
			Blue = colorpix&0xff;
			
			if(Red>0){
				posicolor="Red";
				
				if(Green>0 && Blue>0)
				posicolor="White";
				
				if(Blue>0 && Green==0)
				posicolor="Purple";
				
			}
			if(Green>0 && Red==0 && Blue==0)
			posicolor="Green";
			
			if(Green==0 && Red==0 && Blue>0)
			posicolor="Blue";
			
			if(Green>0 && Red==0 && Blue>0)
			posicolor="Green";
			
			if(Green>0 && Red>0 && Blue==0)
			posicolor="Yellow";
		}
	}
	close();
	
	colorarray[0]=posicolor;
}

function rotationF(rotation,unit,vxwidth,vxheight,depth,xTrue,yTrue){
	setBackgroundColor(0, 0, 0);
	run("Rotate... ", "angle="+rotation+" grid=1 interpolation=None fill enlarge stack");
	wait(1000);
	makeRectangle(xTrue-300, yTrue-465, 600, 1024);
	run("Crop");
	
	getDimensions(width, height, channels, slices, frames);
	if(height<1024 || width<600)
	run("Canvas Size...", "width=600 height=1024 position=Top-Left zero");
	run("Select All");
	run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+vxwidth+" pixel_height="+vxheight+" voxel_depth="+depth+"");
	run("Grays");
}//function


function ImageCorrelation2 (sample, templateImg, rotSearch,ImageCarray,overlap,numCPU){
	
	run("Image Correlation Atomic", "samp="+sample+" temp="+templateImg+" +="+rotSearch+" -="+rotSearch+" overlap="+overlap+" parallel="+numCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
	
	OBJ=getResult("OBJ score", 0);
	OBJScore=parseFloat(OBJ);
	
	Rot=getResult("rotation", 0);
	Rot=parseFloat(Rot);
	
	ShiftY=getResult("shifty", 0);
	ShiftY=parseFloat(ShiftY);
	
	ShiftX=getResult("shiftx", 0);
	ShiftX=parseFloat(ShiftX);
	
	ImageCarray[0]=OBJScore;
	ImageCarray[1]=Rot;
	ImageCarray[2]=ShiftY;
	ImageCarray[3]=ShiftX;
}

function C1C20102Takeout(takeout){// using
	origi=takeout[0];
	
	dotIndex = lastIndexOf(origi, "_C1.tif");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex); 
	
	dotIndex = lastIndexOf(origi, "_C2.tif");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex);
	
	dotIndex = lastIndexOf(origi, "_C1.nrrd");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex); 
	
	dotIndex = lastIndexOf(origi, "_C2.nrrd");
	if (dotIndex!=-1)
	origi = substring(origi, 0, dotIndex);
	
	dotposition=lastIndexOf(origi, "_01.tif");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_02.tif");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_01.nrrd");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_02.nrrd");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_01.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_02.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_R.mha");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_G.mha");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "_C1.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, "GMR");
	if (dotposition!=-1)
	origi=substring(origi, dotposition, lengthOf(origi));
	
	dotposition=lastIndexOf(origi, "VT");
	if (dotposition!=-1)
	origi=substring(origi, dotposition, lengthOf(origi));
	
	dotposition=lastIndexOf(origi, "_C2.zip");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	dotposition=lastIndexOf(origi, ".");
	if (dotposition!=-1)
	origi=substring(origi, 0, dotposition);
	
	takeout[0]=origi;
}


function CLEAR_MEMORY() {
	//	d=call("ij.IJ.maxMemory");
	//	e=call("ij.IJ.currentMemory");
	for (trials=0; trials<2; trials++) {
		call("java.lang.System.gc");
		wait(100);
	}
}

function FILL_HOLES(DD2, DD3) {
	
	if(DD3==1){
		MASKORI=getImageID();
		run("Duplicate...", "title=MaskBWtest.tif duplicate");
		MaskBWtest2=getImageID();
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		run("Fill Holes", "stack");
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		//	print(nSlices+"   2427");
		run("Z Project...", "start=15 stop="+nSlices-10+" projection=[Average Intensity]");
		getStatistics(area, MaskINV_AVEmean, min, max, std, histogram);
		close();
		
		if(MaskINV_AVEmean<5 || MaskINV_AVEmean>250){
			selectImage(MaskBWtest2);
			close();
			
			selectImage(MASKORI);
			run("Fill Holes", "stack");
		}else{
			selectImage(MASKORI);
			close();
			selectImage(MaskBWtest2);
		}
		
		
	}else if (DD2==1){
		MASKORI=getImageID();
		run("Duplicate...", "title=MaskBWtest.tif");
		MaskBWtest2=getImageID();
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		run("Fill Holes", "stack");
		
		run("Invert LUT");
		run("RGB Color");
		run("8-bit");
		
		getStatistics(area, MaskINV_AVEmean, min, max, std, histogram);
		
		if(MaskINV_AVEmean<20 || MaskINV_AVEmean>230){
			selectImage(MaskBWtest2);
			close();
			
			selectImage(MASKORI);
			run("Fill Holes", "stack");
		}else{
			selectImage(MASKORI);
			close();
			selectImage(MaskBWtest2);
		}
	}//if (2DD==1){
}

function lateralDepthAdjustment(op1center,op2center,lateralArray,nc82,templateBr,numCPU){
	
	nc82ID=getImageID();
	orizslice=nSlices();
	
	run("Reslice [/]...", "output=1.000 start=Left rotate avoid");
	resliceW=getWidth(); resliceH=getHeight();
	
	rename("reslice.tif");
	Resliced=getImageID();
	
	if(op1center!=0 && op2center!=0){
		
	}else if(op1center==0 && op2center!=0){
		op1center=280;
	}else if(op1center!=0 && op2center==0){
		op2center=921;
	}else{
		op1center=280; op2center=921;
	}
	
	gapop=op2center-op1center;
	centerpoint=op1center+round(gapop/2);
	
	run("Z Project...", "start="+op1center+120+" stop="+centerpoint+" projection=[Max Intensity]");
	
	getVoxelSize(VxWidthF, VxHeightF, VxDepthF, VxUnitF);
	getDimensions(widthF, heightF, channelsF, slicesF, frames);
	rename("smallMIP.tif");
	
	newImage("mask1.tif", "8-bit white", widthF, heightF, 1);
	run("Mask Median Subtraction", "mask=mask1.tif data=smallMIP.tif %=100 histogram=100");
	
	selectWindow("mask1.tif");
	close();
	
	selectWindow("smallMIP.tif");
	
	run("Enhance Contrast", "saturated=0.35");
	getMinAndMax(a,b);
	
	if(a!=0 && b!=65535 && b!=255)
	run("Apply LUT");
	
	print("VxWidthF; "+VxWidthF+"   VxHeightF; "+VxHeightF+"  VxDepthF; "+VxDepthF);
	
	xyRatio=5.0196078/VxWidthF;// just 5 time smaller, 5 micron vx width
	yRatio=3.1122/VxHeightF;
	
	FinalHsize=round(heightF/yRatio);
	FinalWsize=round(widthF/xyRatio);
	
	print("xyRatio; "+xyRatio+"   FinalHsize; "+FinalHsize+"  FinalWsize; "+FinalWsize);
	
	run("Size...", "width="+round(FinalWsize)+" height="+round(FinalHsize)+" interpolation=None");
	
	run("Canvas Size...", "width=65 height=110 position=Center zero");
	run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width="+VxWidthF*xyRatio+" pixel_height="+VxHeightF*xyRatio+" voxel_depth="+VxDepthF+"");
	run("Select All");
	run("Copy");
	MaxOBJL=0; MaxWidth=0; negativeOBJ=0;
	run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width="+VxWidthF*xyRatio+" pixel_height="+VxHeightF*xyRatio+" voxel_depth="+VxDepthF+"");
	
	for(iWidth=65; iWidth<180; iWidth++){
		run("Properties...", "channels=1 slices=1 frames=1 unit=microns pixel_width="+VxWidthF*xyRatio+" pixel_height="+VxHeightF*xyRatio+" voxel_depth="+VxDepthF+"");
		
		selectWindow("smallMIP.tif");
		run("Size...", "width="+iWidth+" height=110 interpolation=None");
		
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Fill Holes");
		
		run("Canvas Size...", "width=65 height=110 position=Center zero");
		
		
		
		//	setBatchMode(false);
		//			updateDisplay();
		//		"do"
		//		exit();
		
		run("Image Correlation Atomic", "samp=smallMIP.tif temp=Lateral_JFRC2010_5time_smallerMIP.tif +=10 -=10 overlap=90 parallel="+numCPU+" rotation=1 result calculation=[OBJ peasonCoeff] weight=[Equal weight (temp and sample)]");
		
		OBJ=getResult("OBJ score", 0);
		OBJScoreL=parseFloat(OBJ);
		
		if(OBJScoreL>MaxOBJL){
			//		print(OBJScoreL);
			MaxOBJL=OBJScoreL;
			Rot=getResult("rotation", 0);
			Rot=parseFloat(Rot);
			elipsoidAngle=parseFloat(Rot);
			if (elipsoidAngle>90) 
			elipsoidAngle = -(180 - elipsoidAngle);
			
			ShiftY=getResult("shifty", 0);
			maxY=parseFloat(ShiftY);
			
			ShiftX=getResult("shiftx", 0);
			maxX=parseFloat(ShiftX);
			
			MaxWidth=iWidth;
			negativeOBJ=0;
		}else{
			negativeOBJ=negativeOBJ+1;
		}
		
		//	if(negativeOBJ==20)
		//	iWidth=350;
		
		run("Paste");
	}
	
	while(isOpen("smallMIP.tif")){
		selectWindow("smallMIP.tif");
		close();
	}
	
	if(templateBr=="JFRC2010" || templateBr=="JFRC2013")
	Zsize=190;
	else
	Zsize=151;
	
	realzMicron=((MaxWidth*(29/65))*xyRatio);//39/102 is template brain size from 102px window
	
	Realvxdepth=(FinalWsize+MaxWidth-65)/FinalWsize;
	Realvxdepth2=(Zsize/realzMicron)*Realvxdepth;
	maxrotation=elipsoidAngle/(Realvxdepth2/VxWidthF);
	
	//	if(realzMicron>210 && orizslice>110)
	//	Realvxdepth=Realvxdepth*(200/realzMicron);
	
	
	print("MaxOBJL Lateral; "+MaxOBJL+"   BestiW; "+MaxWidth+"  Actual z "+realzMicron+"  Yshift; "+maxY+"  maxX; "+maxX+"  lateral rotation; "+maxrotation+"   Realvxdepth; "+Realvxdepth2);
	
	selectImage(nc82);
	close();
	
	if(isOpen(nc82ID)){
		selectImage(nc82ID);
		close();
	}
	if(isOpen("nc82.tif")){
		selectWindow("nc82.tif");
		close();
	}
	
	//titlelist=getList("image.titles");
	//for(iImage=0; iImage<titlelist.length; iImage++){
	//	print("Opened; "+titlelist[iImage]);
	//}
	
	
	selectWindow("reslice.tif");
	if(bitDepth==8)
	run("16-bit");
	run("Rotation Hideo", "rotate="+maxrotation+" 3d in=InMacro");
	run("Translate...", "x=0 y="+maxY*yRatio+" interpolation=None stack");
	run("Reslice [/]...", "output=1 start=Left rotate avoid");
	rename("nc82.tif");
	nc82=getImageID();
	
	while(isOpen("reslice.tif")){
		selectWindow("reslice.tif");
		close();
	}
	
	CLEAR_MEMORY();
	
	
	//	setBatchMode(false);
	//				updateDisplay();
	//				"do"
	//				exit();
	
	
	lateralArray[0]=Realvxdepth2;
	lateralArray[1]=nc82;
	lateralArray[2]=maxrotation;
	lateralArray[3]=round((maxX*xyRatio)/2);
	lateralArray[4]=maxY*xyRatio;
	lateralArray[5]=MaxOBJL;
}















