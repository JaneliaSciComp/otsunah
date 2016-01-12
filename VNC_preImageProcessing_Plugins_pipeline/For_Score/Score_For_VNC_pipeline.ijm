//VNC score macro. Wrote by Hideo Otsuna Jan 2016.
//This macro requires to open VNC template (flyVNCtemplate20xA_CLAHE_16bit.nrrd") and the mask (flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd)
//This macro requires "ObjPearsonCoeff_.class" plugin
//The input data is nc82 of 20x VNC (aligned)
//This macro will generate .avi movie; template: purple, sample: green


scoreT1=0; SampleDup=0;
setForegroundColor(65535, 65535, 65535);

//argstr="/Registration/reformatted/flyVNCtemplate20xA_BJD_116F12_AE_01_00-fA00v_C140104_20140106013448279_01_warp_m0g40c4e1e-1x16r3.nrrd,BJD_116F12_AE_01,/test/VNC_Test/,temp full file path,mask path"//for test
//args = split(argstr,",");


argstr = getArgument();//Argument
args = split(argstr,",");

if (lengthOf(args)>1) {
	path = args[0];// full file path for Open
	DataName = args[1];//Name for save
	savedir = args[2];//save directory
	templocation=args[3];//template full file path
	tempMasklocation= args[4];//template mask full file path
}

print("path; "+path);
print("DataName; "+DataName);
print("savedir; "+savedir);

filepath=savedir+"Hideo_OBJPearsonCoeff.txt";

if(isOpen("flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd"))
selectWindow("flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd");
else
open(tempMasklocation);
OrigiMask2=getImageID();// Template Mask

if(nSlices==220){
	run("Make Substack...", "delete slices=11-195");
	OrigiMask2=getImageID();// Template Mask
	
	selectWindow("flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd");
	close();
	CLEAR_MEMORY();
	selectImage(OrigiMask2);
	rename("flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd");
}


if(isOpen("flyVNCtemplate20xA_CLAHE_16bit.nrrd"))
selectWindow("flyVNCtemplate20xA_CLAHE_16bit.nrrd");
else{
	open(templocation);
	selectWindow("flyVNCtemplate20xA_CLAHE_16bit.nrrd");
}
TempOri=getImageID();

setBatchMode(true);
histostretch=1;
	

///// start processing /////////////////////////////////////////////////
		
open(path);
		
if(nSlices==220){// aligned VNC should have 220 slices
		
	Sample=getImageID();// Sample
	print("");
	//print(i+"; "+list[i]);
			
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean, minSample, maxSample, std, histogram);
	width2=getWidth();
	height2=getHeight();
			
// empty region filling, this allows to detect if sample is hitting edge = distortion or upside down /////////////////////////////
	yscanUP=0; positiveup=0;
	while(positiveup==0){//UPPER SCAN, for fill empty on data
				
		for(vup=0; vup<width2; vup++){
			PIXV=getPixel(vup, yscanUP);
			
			if(PIXV>0)
			positiveup=1;
		}
		if(positiveup==0)
		yscanUP=yscanUP+1;//UPPER LINE FOR EMPTY PX
	}
	
	yscanDW=0; positivedw=0;
	while(positivedw==0){//BOTTOM SCAN
		
		for(vdw=0; vdw<width2; vdw++){
			PIXV=getPixel(vdw, yscanDW);
			
			if(PIXV>0)
			positivedw=1;
		}
		if(positivedw==0)
		yscanDW=yscanDW+1;//BOTTOM LINE FOR EMPTY PX
	}
	
	xscanLF=0; positiveLF=0;
	while(positiveLF==0){//left SCAN
		
		for(vLF=0; vLF<height2; vLF++){
			PIXV=getPixel(xscanLF, vLF);
			
			if(PIXV>0)
			positiveLF=1;
		}
		if(positiveLF==0)
		xscanLF=xscanLF+1;//left LINE FOR EMPTY PX
	}
	
	xscanRI=0; positiveRI=0;
	while(positiveRI==0){//right SCAN
		
		for(vRI=0; vRI<height2; vRI++){
			PIXV=getPixel(xscanRI, vRI);
			
			if(PIXV>0)
			positiveRI=1;
		}
		if(positiveRI==0)
		xscanRI=xscanRI+1;//right LINE FOR EMPTY PX
	}
	close();
	
	selectImage(Sample);
	rename("Samp.tif");
	setMinAndMax(minSample, maxSample);
	
/// score measurement  //////////////////////		
	run("Select All");
	run("Duplicate...", "title=MaskSampleTitle.tif duplicate");
	SampleDup2=getImageID();
	
	if(nSlices==220){
		run("Make Substack...", "slices=11-195");// eliminate empty regions. This gives us more meaningful score.
		SampleDup3=getImageID();
		
		selectImage(SampleDup2);
		close();
		selectImage(SampleDup3);
		rename("MaskSampleTitle.tif");
	}
	SampleDup2=getImageID();
	
	
	//		setBatchMode(false);
	//			updateDisplay();
	//						"do"
	//						exit;
	
	run("Z Project...", "projection=[Max Intensity]");
	rename("Max.tif");
	AIP=getImageID();
	secondtime=1;
	fillGap (height2,width2,yscanUP,yscanDW,xscanLF,xscanRI);
	ARseg=newArray(0, AIP,secondtime,Sample);
	ARsegmentation(ARseg);
	lowerM=ARseg[0];
	AIP=ARseg[1];
	secondtime=ARseg[2];
	
	print("sample thresholding; "+lowerM);
	selectImage(AIP);// mip
	rename("Max.tif");
	setThreshold(lowerM, 65535);
	run("Make Binary");
	
	//	setBatchMode(false);
	//			updateDisplay();
	//					"do"
	//				exit;
	
	run("16-bit");
	run("Mask255 to 4095");
	imageCalculator("AND create stack", "MaskSampleTitle.tif","Max.tif");//creating new stack
	rename("ANDresult.tif");
	ANDst=getImageID();
	
	if(nSlices==186){
		setSlice(1);
		run("Delete Slice");
		print("deleted slice; "+nSlices);
	}
	Threweight=0.7;
	run("Duplicate...", "title=ANDresult2.tif duplicate");
	ANDst2=getImageID();
	
	setThreshold(lowerM*Threweight, 65535);
	run("Convert to Mask", "method=Default background=Default black");
	
	run("Z Project...", "projection=[Sum Slices]");
	getStatistics(area, meanThre, min, max, std, histogram);
	meangap=11265.6423-meanThre;
	close();
	
			
	if(meangap>500){
		while(meangap>500 && Threweight>=0.1){
			selectImage(ANDst2);
			close();
			
			selectImage(ANDst);
			run("Duplicate...", "title=ANDresult2.tif duplicate");
			ANDst2=getImageID();
			
			Threweight=Threweight-0.05;
			
			setThreshold(lowerM*Threweight, 65535);
			run("Convert to Mask", "method=Default background=Default black");
			
			run("Z Project...", "projection=[Sum Slices]");
			getStatistics(area, meanThre, min, max, std, histogram);
			meangap=11265.6423-meanThre;
			close();
		}
		selectImage(ANDst2);
		close();
		CLEAR_MEMORY();
	}//if(meangap>1000)
	
	else if(meangap<-500){
		while(meangap<-500 && Threweight<1.6){
			selectImage(ANDst2);
			close();
			
			selectImage(ANDst);
			run("Duplicate...", "title=ANDresult2.tif duplicate");
			ANDst2=getImageID();
			
			Threweight=Threweight+0.05;
			
			setThreshold(lowerM*Threweight, 65535);
			run("Convert to Mask", "method=Default background=Default black");
			
			run("Z Project...", "projection=[Sum Slices]");
			getStatistics(area, meanThre, min, max, std, histogram);
			meangap=11265.6423-meanThre;
			close();
		}
		selectImage(ANDst2);
		close();
		CLEAR_MEMORY();
	}//if(meangap>1000)
	
	selectImage(ANDst);
	setThreshold(lowerM*Threweight, 65535);
	run("Convert to Mask", "method=Default background=Default black");
	
	print("3D thre also sample threshold; "+lowerM*Threweight+"  Threweight; "+Threweight+"   meangap; "+meangap);
	
	run("Size based Noise elimination", "ignore=229 less=9");
	run("Minimum...", "radius=2 stack");
	run("Maximum...", "radius=2 stack");
	run("8-bit");
	
	run("Z Project...", "projection=[Max Intensity]");
	getStatistics(area, mean5, minSample, maxSample, std, histogram);
	close();
	
	selectImage(ANDst);
			//	run("Fill Holes", "stack");
	
	//			setBatchMode(false);
	//			updateDisplay();
	//				"do"
	//				exit;
				
	selectImage(AIP);// mip
	close();
	
	if(isOpen("ANDresult2.tif")){
		selectImage("ANDresult2.tif");
		close();
	}
	
	if(isOpen(SampleDup3)){
		selectImage(SampleDup3);
		close();
	}
	if(isOpen(SampleDup2)){
		selectImage(SampleDup2);
		close();
	}
	
	if(secondtime==1 && mean5>0){
		run("ObjPearsonCoeff ", "template=flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd sample=ANDresult.tif show change");
		
		scorearray=newArray(0, 0);
		scoreCal(scorearray);
		
		scoreT=scorearray[0];
		
	}else
	scoreT=0;
	
	if(scoreT==NaN)
	scoreT=scoreT1;
	
	print(scoreT+"  Score");
	ScoreT=scoreT*1000;
	
	selectImage(ANDst);
	close();
		//		setBatchMode(false);
		//			updateDisplay();
		//			"do"
		//			exit;
		
	if(ScoreT<0)
	ScoreT=0;

	ScoreT=d2s(ScoreT, 0);
	
	
	/////// test ///////////////////////////////////////////
	selectImage(TempOri);
	run("Duplicate...", "title=Temp.tif duplicate");
	
	selectImage(Sample);
	setFont("SansSerif" , 28, "antialiased");
	for(stringslice=1; stringslice<=nSlices; stringslice++){
		setSlice(stringslice);
		drawString("Score; "+scoreT, width2*0.05, height2-height2*0.03);
	}
	
	run("Merge Channels...", "c1=Temp.tif c2=Samp.tif c3=Temp.tif");
	run("AVI... ", "compression=Uncompressed frame=25 save="+savedir+ScoreT+"_"+DataName+".avi");
	
	File.saveString(scoreT, filepath);
	
	selectWindow("RGB");
	close();
	
	if(isOpen(SampleDup)){
		selectImage(SampleDup);
		close();
	}
	
	if(isOpen(Sample)){
		selectImage(Sample);
		close();
	}
	if(isOpen("Samp.tif")){
		selectWindow("Samp.tif");
		close();
	}
	
	if(isOpen("Temp.tif")){
		selectWindow("Temp.tif");
		close();
	}
	
	CLEAR_MEMORY(); 
}else{
	close();
	print("Slice number is not 220; "+path);
}
if(isOpen("ANDresult.tif")){
	selectWindow("ANDresult.tif");
	close();
}
if(isOpen("Max.tif")){
	selectWindow("Max.tif");
	close();
}
if(isOpen("MaskSampleTitle.tif")){
	selectWindow("MaskSampleTitle.tif");
	close();
}
if(nImages>3){// incase, if Fiji has bug. The opened images will accumulate
	print("imageNo; "+nImages);
	s=getList("image.titles");
	
	for(ee=0; ee<s.length; ee++){
		print("open title; "+s[ee]);
	}
}//	if(nImages>3){


"Done"
setBatchMode(false);
updateDisplay();








function ARsegmentation(ARseg){
	AIP=ARseg[1];
	secondtime=ARseg[2];
	Sample=ARseg[3];
	donotOpe=0;	startlower=1; trynum=0; step1=0; lower=0; ARshape=0; numberResults=0;
	while(numberResults==0 && ARshape<3){
		//		print(lower+"  No; "+trynum+"   Images; "+nImages);
		
		selectImage(AIP);// mip
		run("Duplicate...", "title=DUP_AVEP.tif");
		DUP_AVEP=getImageID();
		
		lower=lower+4;
		
		if(lower>20000 && secondtime==0){
			if(step1==1){
				numberResults=1;
				print("Check data, no signals? or VNC is hitting edge of data");
				donotOpe=1;
			}
			if(step1==0){
				
		//		print("DUP_AVEP 1st; "+DUP_AVEP);
				selectImage(DUP_AVEP);
				close();//DUP_AVEP
				selectImage(AIP);
				close();//AIP
				
				selectImage(Sample);
				run("Z Project...", "projection=[Max Intensity]");
				AIP=getImageID();
				rename("Max.tif");
				
				run("Duplicate...", "title=DUP_AVEP.tif");
				DUP_AVEP=getImageID();
				
		//		print("DUP_AVEP 2nd; "+DUP_AVEP);
				numberResults=0;
				lower=4;
				step1=1;
				
				//			setBatchMode(false);
				//			updateDisplay();
				//			"do"
				//			exit();
			}
		}else if(lower>30000 && secondtime==1){//if(lower>3000){
			numberResults=1;
			print("The VNC is hitting edge");
			donotOpe=1;
			secondtime=5;
		}//if(lower>20000 && secondtime==0){
		setThreshold(lower, 65535);
		
		run("Make Binary");
		run("Analyze Particles...", "size=20000.00-Infinity show=Nothing display exclude clear");
		
		updateResults();
		
	//	if(step1==0)
		selectImage(DUP_AVEP);
	//	else if(step1==1)
	//	selectImage(DUP_AVEP2);
		close();
		
		if(isOpen("DUP_AVEP.tif")){
			selectWindow("DUP_AVEP.tif");
			close();
		}
		
		lowerM=lower;
		
		if(nResults>0){
			maxsize=20000;
			for(i2=0; i2<nResults; i2++){
				Size=getResult("Area", i2);
				ARshape=getResult("AR", i2);// AR value from Triangle
				
				if(ARshape>2.2){
					if(Size>maxsize){
						maxsize=Size;
						numberResults=nResults;
					}
				}
			}//for(i2=0; i2<nResults; i2++){
		}
		
		trynum=trynum+1;
	}//while(nResults==0  && donotOperate==0){
	
//	print("615 ImageNO; "+nImages);
	
	if(nImages>10){
		s=getList("image.titles");
		
		for(ee=0; ee<s.length; ee++){
			print("open title; "+s[ee]);
		}
	}
	
	if(donotOpe==1)
	lowerM=1000;
	
	ARseg[0]=lowerM;
	ARseg[1]=AIP;
	ARseg[2]=secondtime;
}//ARsegmentation(){

function fillGap (height2,width2,yscanUP,yscanDW,xscanLF,xscanRI){
	for(upfill=0; upfill<yscanUP; upfill++){//up fill
		for(xfillup=0; xfillup<width2; xfillup++){
			setPixel(xfillup, upfill, 65535);
		}
	}
	for(dwfill=height2-1; dwfill>height2-1-yscanDW; dwfill--){//down fill
		for(xfillup=0; xfillup<width2; xfillup++){
			setPixel(xfillup, dwfill, 65535);
		}
	}
	for(lffill=0; lffill<xscanLF; lffill++){//left fill
		for(yfillup=0; yfillup<height2; yfillup++){
			setPixel(lffill, yfillup, 65535);
		}
	}
	for(rffill=width2-1; rffill>width2-1-xscanRI; rffill--){//Right fill
		for(yfillup=0; yfillup<height2; yfillup++){
			setPixel(rffill, yfillup, 65535);
		}
	}
}//fillGap (height2,width2,yscanUP,yscanDW,xscanLF,xscanRI){

function backgroundthresholding(){
	/////////// background histogram analysis /////////////////////
	for(step=1; step<=2; step++){
		
		maxisum=0;
//		print("nSlices; "+nSlices);
		for(n=1; n<=nSlices; n++){
			setSlice(n);
			maxcounts=0; maxi=0;
				
			getHistogram(values, counts,  4000);
			for(i2=2; i2<4000-21; i2++){
				Val2=0; numbercount=0;
				for(iave=i2; iave<i2+20; iave++){
					Val=counts[iave];
					Val2=Val2+Val;
				}
				
				ave=Val2/20;
				
				sumVal5=0; insideSD=0;
				for(stdThre=i2; stdThre<i2+20; stdThre++){
					val5=counts[stdThre];
					insideSD=((val5-ave)*(val5-ave))+insideSD;
					sumVal5=sumVal5+val5;
				}
				sqinside=insideSD/20;
				sd = sqrt(sqinside);
				
				numbercount=numbercount+1;
				if(numbercount==20){
					numbercount=0;
//					print(i2+"; "+sd);
				}
				
				if(step==1){
					if(ave>maxcounts && i2>2){// do not count less than 2 gray value in 16bit, this is NP gal4 only
						maxcounts=ave;
						maxi=i2+10;
					}
				}else{// 2nd step, after acquisition of average background value
					if(ave>maxcounts && i2<avethre+600 ){// maximum less than 300 value from average background value. This will prevent cutting signal value
						maxcounts=ave;
						maxi=i2+10;
					}
					if(ave>maxcounts && i2>avethre+600 ){// maximum less than 300 value from average background value. This will prevent cutting signal value
						maxcounts=ave;
						maxi=avethre+300;
					}
				}//step==2
			}
			if(step==2){
				if(maxi==0)
				maxi=1;
				
				List.set("Slicen"+n-1, maxi);
	//			print(n+"  max count; "+ maxi);
			}//if(step==2){
			maxisum=maxisum+maxi;
		}//for(n=1; n<=nSlices; n++){
		avethre=maxisum/n;
	} //for(step=1; step<=2; step++){
	
	////// lower value thresholding /////////////////////////
	oristack=getImageID();
	
	newImage("Untitled.tif", "16-bit black", 512, 1024, 1);
	single=getImageID();
	
	for(n2=1; n2<=nSlices; n2++){
		selectImage(oristack);
		setSlice(n2);
		run("Select All");
		run("Copy");
		
		selectImage(single);
		run("Paste");
		
		lowthre=List.get("Slicen"+n2-1);
		lowthre=round(lowthre);
		lowthre=lowthre*0.4;
		setThreshold(lowthre, 65535);
	//	run("Convert to Mask");
		run("Make Binary");
		run("Histgram stretch", "lower=0 higher=200");
		run("Select All");
		run("Copy");
		close();
		
		selectImage(oristack);
		run("Paste");
		
	}//for(n2=1; n2<=nSlices; n2++){
	
	selectImage(single);
	close();
	if(isOpen("Untitled.tif")){
		selectWindow("Untitled.tif");
		close();
	}
	
	
}//backgroundthresholding(){

function scoreCal(scorearray){
	loginfo=getInfo("log");
	
	lengthoflog=lengthOf(loginfo);
	dotIndex20 = lastIndexOf(loginfo, "valSum; ");
	valsum=substring(loginfo, dotIndex20+8, lengthoflog);
	valsum=parseFloat(valsum);
	
	dotIndex10 = lastIndexOf(loginfo, "Cross; ");
	cross=substring(loginfo, dotIndex10+7, dotIndex20);
	cross=parseFloat(cross);
	
	score=valsum/sqrt(cross);
	scorearray[0]=score;
}

function CLEAR_MEMORY() {
	d=call("ij.IJ.maxMemory");
	e=call("ij.IJ.currentMemory");
	for (trials=0; trials<3; trials++) {
		call("java.lang.System.gc");
		wait(50);
	}
}
