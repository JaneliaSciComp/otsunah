//Wrote by Hideo Otsuna (HHMI Janelia Research Campus), Aug 17, 2015

autothre=0;//1 is FIJI'S threshold, 0 is DSLT thresholding
multiDSLT=1;// 1 is multi step DSLT for better thresholding sensitivity

//argstr="/test/C2-GMR_29H12_AE_01_02-fA01v_C081118_20081118115219609.tif,GMR_29H12,/test/GMR/"//for test

argstr = getArgument();//Argument
args = split(argstr,",");

if (lengthOf(args)>1) {
    Path = args[0];// full file path for Open
    DataName = args[1];//Name for save
    saveplace = args[2];//save directory
}

setBatchMode(true);
run("Close All");

open(Path);

colorcoding=1;//color depth MIP
AutoBRV=1;//auto-brightness adjustment
CLAHE=1;//CLAHE
blockmode=0;//block mode for larger number of files
colorscale=1;//adding color depth scale bar
reverse0=0;//reverse color for front back inverted signal

usingLUT = "royal";//LUT, "PsychedelicRainBow2" is for Color MIP mask search, "royal" is for better looiking
//usingLUT="PsychedelicRainBow2";// for Mask searchable color depth MIP
lowthreM = "Peak Histogram";//background thresholding
startMIP=0;//MIP starting slice
endMIP=1000;//MIP ending slice

desiredmean=150;
lowerweight=0.8;
MIPbasedThreshold=0;//0 is lower thresholding with 3D stack, 1 is based on MIP

if(AutoBRV==1)
//print("Desired mean; "+desiredmean);


origi=getTitle();

files=files+1;

print(origi);

bitd=bitDepth();
totalslice=nSlices();

getDimensions(width, height, channels, slices, frames);
stack=getImageID();

BasicMIP=newArray(bitd,0,stack);
basicoperation(BasicMIP);//rename MIP.tif

DefMaxValue=BasicMIP[1];
			
if(AutoBRV==1){//to get brightness value from MIP
	selectWindow("MIP.tif");
	MIP=getImageID();
	briadj=newArray(desiredmean, 0, 0, 0,lowerweight,lowthreM,autothre,DefMaxValue,MIP,stack);
	autobradjustment(briadj);
	applyV=briadj[2];
	sigsize=briadj[1];
	sigsizethre=briadj[3];
	sigsizethre=round(sigsizethre);
	sigsize=round(sigsize);
}//	if(AutoBRV==1){
			
			
selectWindow(origi);
brightnessapply(applyV, bitd,lowerweight,MIPbasedThreshold,stack);
				
				
if(usingLUT=="royal")
stackconcatinate();
			
if(AutoBRV==0){
	applyV=255;
	if(bitd==16){
		setMinAndMax(0, 65535);
		run("8-bit");
	}
}
			
TimeLapseColorCoder(slices, applyV, width, AutoBRV, bitd, CLAHE, colorscale, reverse0, colorcoding, usingLUT,DefMaxValue,startMIP,endMIP);
			

saveAs("PNG", saveplace+DataName+"_royal.png");
			

run("Close All");

///////////////////////////////////////////////////////////////
function autobradjustment(briadj){
	
	desiredmean=briadj[0];
	lowerweight=briadj[4];
	lowthreM=briadj[5];
	autothre=briadj[6];
	DefMaxValue=briadj[7];
	MIP=briadj[8];
	stack=briadj[9];
	
	if(autothre==1)//Fiji Original thresholding
	run("Duplicate...", "title=test.tif");
	run("Grays");
	bitd=bitDepth();
	run("Properties...", "channels=1 slices=1 frames=1 unit=px pixel_width=1 pixel_height=1 voxel_depth=1");
	getDimensions(width2, height2, channels, slices, frames);
	totalpix=width2*height2;
	
	run("Select All");
	if(bitd==8){
		run("Copy");
	}
	
	if(bitd==16){
		setMinAndMax(0, DefMaxValue);
		run("Copy");
	}
	/////////////////////signal size measurement/////////////////////
	selectImage(MIP);
	
	run("Duplicate...", "title=test2.tif");
	selectWindow("test2.tif");
	setAutoThreshold("Triangle dark");
	getThreshold(lower, upper);
	setThreshold(lower, DefMaxValue);
	
	run("Convert to Mask");
	if(bitd==16)
	run("8-bit");
	
	run("Create Selection");
	getStatistics(areathre, mean, min, max, std, histogram);
	if(areathre!=totalpix){
		if(mean<200){
		selectWindow("test2.tif");
		run("Make Inverse");
		}
	}
	getStatistics(areathre, mean, min, max, std, histogram);
	selectWindow("test2.tif");
	close();//test2.tif
	
	
	if(areathre/totalpix>0.4){

		selectImage(MIP);
		
		run("Duplicate...", "title=test2.tif");
		setAutoThreshold("Moments dark");
		getThreshold(lower, upper);
		setThreshold(lower, DefMaxValue);
		
		run("Convert to Mask");
		if(bitd==16)
		run("8-bit");
		
		run("Create Selection");
		getStatistics(areathre, mean, min, max, std, histogram);
		if(areathre!=totalpix){
			if(mean<200){
				selectWindow("test2.tif");
				run("Make Inverse");
			}
		}
		getStatistics(areathre, mean, min, max, std, histogram);
		close();//test2.tif
		
	}//if(area/totalpix>0.4){
	
	/////////////////////Fin signal size measurement/////////////////////
	
	selectImage(MIP);

	dsltarray=newArray(autothre, bitd, totalpix, desiredmean, 0,multiDSLT);
	DSLTfun(dsltarray);
	desiredmean=dsltarray[3];
	area2=dsltarray[4];
	//////////////////////

	selectImage(MIP);//MIP
	getMinAndMax(min, max);
	if(max>4095){//16bit
		minus=0;
		getMinAndMax(min, max1);
		while(max<65530){
			minus=minus+100;
			selectImage(MIP);//MIP
			run("Duplicate...", "title=MIPDUP.tif");
			
			
			//		print("premax; "+max+"premin; "+min);
			run("Histgram stretch", "lower="+min+" higher="+max1-minus+"");//histogram stretch	\
			getMinAndMax(min, max);
			//	print("postmax; "+max+"postmin; "+min);
			close();
		}
		
		//		print("minus; "+minus);
		
		selectImage(MIP);//MIP
		run("Histgram stretch", "lower="+min+" higher="+max1-minus-100+"");//histogram stretch	\
		getMinAndMax(min, max);
		//		print("after max; "+max);
		
		selectImage(stack);
		run("Histgram stretch", "lower="+min+" higher="+max1-minus-100+" 3d");//histogram stretch	
		selectImage(MIP);//MIP
	}
	
	run("Mask Brightness Measure", "mask=test.tif data=MIP.tif desired="+desiredmean+"");
	selectImage(MIP);//MIP
	
	fff=getTitle();
	
	applyvv=newArray(1,bitd,stack,MIP);
	applyVcalculation(applyvv);
	applyV=applyvv[0];
	
	selectImage(MIP);//MIP
	
	if(fff=="MIP.tif"){
		if(bitd==16)
		applyV=400;
		
		if(bitd==8)
		applyV=40;
		
	}
	
	rename("MIP.tif");//MIP
	
	selectWindow("test.tif");//new window from DSLT
	close();
	/////////////////2nd time DSLT for picking up dimmer neurons/////////////////////

	
	if(applyV>50 && applyV<220 && bitd==8){
		applyVpre=applyV;
		selectImage(MIP);
		
		setMinAndMax(0, applyV);

		run("Duplicate...", "title=MIPtest.tif");
					
		setMinAndMax(0, applyV);
		run("Apply LUT");
		maxcounts=0;  maxi=0;
		getHistogram(values, counts,  256);
		for(i=0; i<100; i++){
			Val=counts[i];
					
			if(Val>maxcounts){
				maxcounts=counts[i];
				maxi=i;
			}
		}
					
		changelower=maxi*lowerweight;
		if(changelower<1)
		changelower=1;
		
		selectWindow("MIPtest.tif");
		close();
					
		selectImage(MIP);
		setMinAndMax(0, applyV);
		run("Apply LUT");
					
		setMinAndMax(changelower, 255);
		run("Apply LUT");
		
		print("  Double DSLT");
		
		desiredmean=230;//230 for GMR
		
		dsltarray=newArray(autothre, bitd, totalpix, desiredmean, 0, multiDSLT);
		DSLTfun(dsltarray);//will generate test.tif DSLT thresholded mask
		desiredmean=dsltarray[3];
		area2=dsltarray[4];
	
		selectImage(MIP);//MIP
	
		run("Mask Brightness Measure", "mask=test.tif data=MIP.tif desired="+desiredmean+"");
		
		selectImage(MIP);//MIP
		
		applyvv=newArray(1,bitd,stack,MIP);
		applyVcalculation(applyvv);
		applyV=applyvv[0];
		
		if(applyVpre<applyV){
			applyV=applyVpre;
			print("  previous applyV is brighter");
		}
		
	//	rename("MIP.tif");//MIP
	//	close();
		
		selectWindow("test.tif");//new window from DSLT
		close();
	}//	if(applyV>25 && applyV<150 && bitd==8){
	
	
	sigsize=area2/totalpix;
	if(sigsize==1)
	sigsize=0;
	
	sigsizethre=areathre/totalpix;
	
	print("  Signal brightness; 	"+applyV+"	 Signal Size DSLT; 	"+sigsize+"	 Sig size threshold; 	"+sigsizethre);
	briadj[1]=(sigsize)*100;
	briadj[2]=applyV;
	briadj[3]=sigsizethre*100;
}//function autobradjustment

function DSLTfun(dsltarray){
	
	autothre=dsltarray[0];
	bitd=dsltarray[1];
	totalpix=dsltarray[2];
	desiredmean=dsltarray[3];
	multiDSLT=dsltarray[5];
	
	if(autothre==0){//DSLT
		
		if(bitd==8)
		//	run("DSLT ", "radius_r_max=4 radius_r_min=2 radius_r_step=2 rotation=6 weight=14 filter=GAUSSIAN close=None noise=5px");
		run("DSLT ", "radius_r_max=4 radius_r_min=2 radius_r_step=2 rotation=6 weight=5 filter=GAUSSIAN close=None noise=5px");
		
		if(bitd==16){
			run("DSLT ", "radius_r_max=4 radius_r_min=2 radius_r_step=2 rotation=6 weight=150 filter=GAUSSIAN close=None noise=5px");
			
			run("16-bit");
			run("Mask255 to 4095");
		}
		rename("test.tif");//new window from DSLT
	}//if(autothre==0){//DSLT
	
	selectWindow("test.tif");
	
	run("Duplicate...", "title=test2.tif");
	selectWindow("test2.tif");
	run("Convert to Mask");
	if(bitd==16)
	run("8-bit");
	
	run("Create Selection");
	getStatistics(area, mean, min, max, std, histogram);
	if(area!=totalpix){
		if(mean<200){
			selectWindow("test2.tif");
			run("Make Inverse");
		}
	}
	getStatistics(area2, mean, min, max, std, histogram);
	close();//test2.tif
	
	presize=area2/totalpix;
	
	if(area==totalpix){
		presize=0.0001;
		print("Equal");
	}
	
	if(multiDSLT==1){
		if(presize<0.05){// set DSLT more sensitive, too dim images, less than 5%
			selectWindow("test.tif");//new window from DSLT
			close();
			
			if(isOpen("test.tif")){
				selectWindow("test.tif");
				close();
			}
			
			selectWindow("MIP.tif");//MIP
			if(bitd==8){
				//run("DSLT ", "radius_r_max=4 radius_r_min=2 radius_r_step=2 rotation=6 weight=5 filter=GAUSSIAN close=None noise=5px");
				run("DSLT ", "radius_r_max=6 radius_r_min=2 radius_r_step=2 rotation=6 weight=2 filter=GAUSSIAN close=None noise=5px");
				getStatistics(area2, mean, min, max, std, histogram);
			}
			if(bitd==16){
				run("DSLT ", "radius_r_max=6 radius_r_min=2 radius_r_step=2 rotation=6 weight=20 filter=GAUSSIAN close=None noise=5px");
				run("8-bit");
				run("Convert to Mask");
				run("Create Selection");
				getStatistics(area2, mean, min, max, std, histogram);
				if(area2!=totalpix){
					if(mean<200)
					run("Make Inverse");
				}
				getStatistics(area2, mean, min, max, std, histogram);
				run("16-bit");
				run("Mask255 to 4095");
			}//if(bitd==16){
			
			rename("test.tif");//new window from DSLT
			run("Select All");
			
			sizediff=(area2/totalpix)/presize;
			print("  2nd_sizediff; 	"+sizediff);
			if(bitd==16){
				if(sizediff>1.6){
					repeatnum=(sizediff-1)*10;
					oriss=1;
					
					for(rep=1; rep<=repeatnum+1; rep++){
						oriss=oriss+oriss*0.11;
					}
					weight=oriss/5;
					desiredmean=desiredmean+(desiredmean/5)*weight;
					desiredmean=round(desiredmean);
					
					if(desiredmean>220 || desiredmean==NaN)
					desiredmean=230;
					
					print("  desiredmean; 	"+desiredmean+"	 sizediff; "+sizediff+"	 weight *25%;"+(desiredmean/4)*weight);
				}
			}else if(bitd==8){
				if(sizediff>2){
					repeatnum=(sizediff-1);//*10
					oriss=1;
					
					for(rep=1; rep<=repeatnum+1; rep++){
						oriss=oriss+oriss*0.08;
					}
					weight=oriss/7;
					desiredmean=desiredmean+(desiredmean/7)*weight;
					desiredmean=round(desiredmean);
					
					if(desiredmean>225)
					desiredmean=235;
					
					print("  desiredmean; 	"+desiredmean+"	 sizediff; "+sizediff+"	 weight *25%;"+(desiredmean/4)*weight);
				}
			}
		}//if(area2/totalpix<0.01){
	}//	if(multiDSLT==1){
	dsltarray[3]=desiredmean;
	dsltarray[4]=area2;
} //function DSLTfun

function applyVcalculation(applyvv){
	bitd=applyvv[1];
	stack=applyvv[2];
	MIP=applyvv[3];
	
	selectImage(MIP);//MIP
	applyV=getTitle();
	
	if(applyV=="MIP.tif")
	applyV=200;
	
	applyV=round(applyV);
	run("Select All");
	getMinAndMax(min, max);
	
	
	if(bitd==8){
		applyV=255-applyV;
		
		if(applyV==0)
		applyV=255;
		else if(applyV<20)
		applyV=20;
	}else if(bitd==16){
		
		if(max<=4095)
		applyV=4095-applyV;
			
		if(max>4095)
		applyV=65535-applyV;
			
		if(applyV==0)
		applyV=max;
		else if(applyV<150)
		applyV=150;
	}
	applyvv[0]=applyV;
}
	
function stackconcatinate(){

	getDimensions(width2, height2, channels2, slices, frames);
	addingslices=slices/10;
	addingslices=round(addingslices);
	
	for(GG=1; GG<=addingslices; GG++){
		setSlice(nSlices);
		run("Add Slice");
	}
	run("Reverse");
	for(GG=1; GG<=addingslices; GG++){
		setSlice(nSlices);
		run("Add Slice");
	}
	run("Reverse");
}

function brightnessapply(applyV, bitd,lowerweight,MIPbasedThreshold,stack){
	stacktoApply=getTitle();
	
	run("Unsharp Mask...", "radius=1 mask=0.35 stack");
	
	if(bitd==8){//8bit
		if(applyV<255){
			setMinAndMax(0, applyV);
			
			if(applyV<220){
				run("Z Project...", "projection=[Max Intensity]");
				MIPapply=getTitle();
		
				setMinAndMax(0, applyV);
				run("Apply LUT");


//Background signal value detection
				if(lowthreM=="Peak Histogram"){
					maxcounts=0; maxi=0;
					getHistogram(values, counts,  256);
					for(i3=0; i3<200; i3++){
						
						sumave=0;
						for(peakave=i3; peakave<i3+5; peakave++){
							Val=counts[peakave];
							sumave=sumave+Val;
						}
						aveave=sumave/5;
						
						if(aveave>maxcounts){
							maxcounts=aveave;
							maxi=i3+2;
						}
					}//for(i3=0; i3<200; i3++){
					changelower=maxi*lowerweight;
					
				}else if(lowthreM=="Auto-threshold"){
					setAutoThreshold("Huang dark");
					getThreshold(lower, upper);
					resetThreshold();
					changelower=lower*lowerweight;
				}

		//		if(changelower>80)
				//		changelower=60;
				
				selectWindow(MIPapply);
				close();//MIPapply
				
				selectWindow(stacktoApply);
				setMinAndMax(0, applyV);//brightness adjustment
				run("Apply LUT", "stack");

				if(changelower<1)
				changelower=1;
				
				changelower=round(changelower);
				
				setMinAndMax(changelower, 255);//lowthre cut
				print("  lower threshold; 	"+changelower);
			}

		run("Apply LUT", "stack");
		}
	}//	if(bitd==8){
	if(bitd==16){
		
		applyV2=applyV;
		if(applyV==4095)
		applyV2=4094;
		
		selectImage(stack);
		run("Z Project...", "projection=[Max Intensity]");
		MIP2=getImageID();
		getMinAndMax(min, max);
		
		minus=0;
		while(max<65530){
			minus=minus+50;
			selectImage(MIP2);//MIP
			run("Duplicate...", "title=MIPDUP.tif");
			
			//		print("premax; "+max+"premin; "+min);
			run("Histgram stretch", "lower="+min+" higher="+applyV2-minus+"");//histogram stretch	
			getMinAndMax(min, max);
			//	print("postmax; "+max+"postmin; "+min);
			close();
		}
		selectImage(MIP2);//MIP
		close();
		selectImage(stack);
		
		run("Histgram stretch", "lower=0 higher="+applyV2-minus+" 3d");//histogram stretch
		
		countregion=65500;

		run("Z Project...", "projection=[Max Intensity]");
		
		maxi=0;
		
		maxcounts=0;
					getHistogram(values, counts,  65536);
		for(i3=5; i3<countregion; i3++){
			
			sumVal20=0; 
			if(i3<countregion-20){
				for(aveval=i3; aveval<i3+20; aveval++){
					Val20=counts[aveval];
					
					sumVal20=sumVal20+Val20;
				}
				AveVal20=sumVal20/20;
				
				if(AveVal20>maxcounts){
					maxcounts=AveVal20;
					maxi=i3+10;
				}
			}//if(i3<280){
		}
		changelower=maxi*lowerweight;
		close();
		selectWindow(stacktoApply);
		changelower=round(changelower);
		setMinAndMax(changelower, 65535);
		print("lower threshold; 	"+changelower);
		

		run("8-bit");
	}//if(bitd==16){
}//function brightnessapply(applyV, bitd){

function basicoperation(BasicMIP){
	run("Mean Thresholding", "-=30 thresholding=Subtraction");//new plugins
	stack=BasicMIP[2];
	
	
	if(bitd==16){
		run("Z Project...", "projection=[Max Intensity]");
		getMinAndMax(min, max);
		close();
		
		selectImage(stack);
		setMinAndMax(0, max);
	}
	if(bitd==8)
	max=255;
	
	run("Z Project...", "projection=[Max Intensity]");
	rename("MIP.tif");
	if(bitd==16)
	resetMinAndMax();
	
	BasicMIP[1]=max;
}


function TimeLapseColorCoder(slicesOri, applyV, width, AutoBRV, bitd, CLAHE, GFrameColorScaleCheck, reverse0, colorcoding, usingLUT,DefMaxValue,startMIP,endMIP) {//"Time-Lapse Color Coder" 
	
	if(usingLUT=="royal")
	var Glut = "royal";	//default LUT
	
	if(usingLUT=="PsychedelicRainBow2")
	var Glut = "PsychedelicRainBow2";	//default LUT
	
	var Gstartf = 1;var Gendf = 10;
	
	getDimensions(width, height, channels, slices, frames);
	origi=getTitle();
	
	if(frames>slices)
	slices=frames;
	
	newImage("lut_table.tif", "8-bit black", slices, 1, 1);
	for(xxx=0; xxx<slices; xxx++){
		per=xxx/slices;
		colv=255*per;
		colv=round(colv);
		setPixel(xxx, 0, colv);
	}
	
	run(Glut);
	run("RGB Color");
	
	selectWindow(origi);
	
	run("Z Code Stack HO", "data="+origi+" 1px=lut_table.tif");
	
	Depth_RGB=getImageID();
	
	if(endMIP>nSlices)
	endMIP=nSlices;
	
	if(usingLUT=="royal")
	run("Z Project...", "projection=[Max Intensity]");
	
		
	if(usingLUT=="PsychedelicRainBow2")
	run("MIP right color", "start="+startMIP+" end="+endMIP+"");
	
	max=getTitle();
	
	selectImage(Depth_RGB);
	close();
	
	selectWindow("lut_table.tif");
	close();
	
	selectWindow(max);
	rename("color.tif");
	if (GFrameColorScaleCheck==1){
		CreateScale(Glut, Gstartf, slicesOri, reverse0);
	
		selectWindow("color time scale");
		run("Select All");
		run("Copy");
		close();
	}
	
	selectWindow("color.tif");
	run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1.0000 pixel_height=1.0000 voxel_depth=0 global");
	if(CLAHE==1 && usingLUT=="royal" )
	run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=1.5 mask=*None*");
	
	if (GFrameColorScaleCheck==1){
		run("Canvas Size...", "width="+width+" height="+height+90+" position=Bottom-Left zero");
		makeRectangle(width-257, 1, 256, 48);
		run("Paste");
	
		if(AutoBRV==1){
			setFont("Arial", 20, " antialiased");
			setColor("white");
			if(applyV>99){
				if(bitd==8)
				drawString("Max: "+applyV+" /255", width-180, 78);
				
				if(bitd==16 && DefMaxValue>4095)
				drawString("Max: "+applyV+" /"+DefMaxValue+"", width-180, 78);
				
				if(bitd==16 && DefMaxValue<=4095)
				drawString("Max: "+applyV+" /4095", width-180, 78);
			}
			if(applyV<100){
				if(bitd==8)
				drawString("Max: 0"+applyV+" /255", width-180, 78);
				if(bitd==16 && DefMaxValue<=4095)
				drawString("Max: 0"+applyV+" /4095", width-180, 78);
				if(bitd==16 && DefMaxValue>4095)
				drawString("Max: 0"+applyV+" /"+DefMaxValue+"", width-180, 78);
			}
			setMetadata("Label", applyV+"	 DSLT; 	"+sigsize+"	Thre; 	"+sigsizethre);
		}//if(AutoBRV==1){
	}//if (GFrameColorScaleCheck==1){
	run("Select All");

}//function TimeLapseColorCoder(slicesOri, applyV, width, AutoBRV, bitd) {//"Time-Lapse Color Coder" 
	
function CreateScale(lutstr, beginf, endf, reverse0){
	ww = 256;
	hh = 32;
	newImage("color time scale", "8-bit White", ww, hh, 1);
	if(reverse0==0){
		for (j = 0; j < hh; j++) {
			for (i = 0; i < ww; i++) {
				setPixel(i, j, i);
			}
		}
	}//	if(reverse0==0){
	
	if(reverse0==1){
		valw=ww;
		for (j = 0; j < hh; j++) {
			for (i = 0; i < ww; i++) {
				setPixel(i, j, valw);
				valw=ww-i;
			}
		}
	}//	if(reverse0==1){
	
	if(usingLUT=="royal"){
		makeRectangle(25, 0, 204, 32);
		run("Crop");
	}
	
	run(lutstr);
	run("RGB Color");
	op = "width=" + ww + " height=" + (hh + 16) + " position=Top-Center zero";
	run("Canvas Size...", op);
		setFont("SansSerif", 12, "antiliased");
	run("Colors...", "foreground=white background=black selection=yellow");
	drawString("Slices", round(ww / 2) - 12, hh + 16);
	
	if(usingLUT=="PsychedelicRainBow2"){
		drawString(leftPad(beginf, 3), 10, hh + 16);
		drawString(leftPad(endf, 3), ww - 30, hh + 16);
	}else{
		drawString(leftPad(beginf, 3), 24, hh + 16);
		drawString(leftPad(endf, 3), ww - 50, hh + 16);
	}
}
	
function leftPad(n, width) {
	s = "" + n;
	while (lengthOf(s) < width)
	s = "0" + s;
	return s;
}

function lowerThresholding (ThreArray){
	lowthreAveRange=ThreArray[0];
	lowthreMin=ThreArray[1];
	lowthreRange=ThreArray[2];
	maxV=ThreArray[3];
	
	for(step=1; step<=2; step++){
		maxisum=0;
		for(n=1; n<=nSlices; n++){
			setSlice(n);
			maxcounts=0; maxi=0;
			
			getHistogram(values, counts, maxV);
			for(i2=0; i2<maxV/2; i2++){
				Val2=0;
				for(iave=i2; iave<i2+lowthreAveRange; iave++){
					Val=counts[iave];
					Val2=Val2+Val;
				}
				ave=Val2/lowthreAveRange;
				if(step==1){
					if(ave>maxcounts && i2>lowthreMin){
						maxcounts=ave;
						maxi=i2+lowthreAveRange/2;
					}
				}else{
					if(ave>maxcounts && i2>avethre && i2<avethre+lowthreRange ){
						maxcounts=ave;
						maxi=i2+lowthreAveRange/2;
					}
					if(i2>=avethre+lowthreRange)
					maxi=avethre+lowthreRange;
					
					
				}//step==2
			}
			if(step==2)
			List.set("Slicen"+n, maxi);
			
			maxisum=maxisum+maxi;
		}//for(n=1; n<=nSlices; n++){
		avethre=maxisum/n;
	}//for(step=1; step<=2; step++){
	ThreArray[4]=avethre;
}//function

