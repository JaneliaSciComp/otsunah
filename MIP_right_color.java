import ij.*;
import ij.plugin.filter.*;
//import ij.plugin.PlugIn;
import ij.process.*;
import ij.gui.*;
import ij.process.ImageConverter;
//import java.math.*;
//import java.io.*;
//import java.net.*;
import ij.Macro.*;

//import ij.plugin.*;
//import ij.measure.Calibration;
//import ij.gui.NewImage.*;

public class MIP_right_color implements PlugInFilter {
	
	ImageProcessor ip2, ip3;
	ImagePlus imp, imp2, newimp;
	
	String MIPtwoST="";

	public int setup(String arg, ImagePlus imp) {
		
		IJ.register (MIP_right_color.class);
		if (IJ.versionLessThan("1.32c")){
			IJ.showMessage("Error", "Please Update ImageJ.");
			return 0;
		}
		
		this.imp = imp;
	//	this.imp2 = imp2;
		if(imp.getType()!=imp.COLOR_RGB){
			IJ.showMessage("Error", "Plugin requires RGB image");
			return 0;
		}
		return DOES_RGB;
	}
	
	public void run(ImageProcessor ip1){
		
		int startMIP = (int)Prefs.get("startMIP.int",0);
		int endMIP = (int)Prefs.get("endMIP.int",1000);
		
		GenericDialog gd = new GenericDialog("DSLT parameter");
		gd.addNumericField("Start slice",  startMIP, 0);
		gd.addNumericField("End slice",  endMIP, 0);
		gd.showDialog();
		startMIP = (int)gd.getNextNumber();
		endMIP = (int)gd.getNextNumber();
		
		Prefs.set("startMIP.int", startMIP);
		Prefs.set("endMIP.int", endMIP);
		
		imp = WindowManager.getCurrentImage();
	//	titles[Mask] = imp.getTitle();//original 8bit
		
		if (imp==null) {
			IJ.noImage();
			return;
		}
		
		int width = imp.getWidth();
		int height = imp.getHeight();
		int stackSize = imp.getStackSize();
		
		if(endMIP>stackSize)
		endMIP=stackSize;
		
		if(startMIP==0)
		startMIP=1;

		if (stackSize<2) {
			IJ.error("", "Stack required");
			return;
		}

		ip1 = imp.getProcessor();
		ImageStack st1 = imp.getStack();
		int sumpx = ip1.getPixelCount();
		//	Calibration cal = imp.getCalibration();
		
		IJ.showStatus("Color MIP creation");
		IJ.showProgress(0.0);

		int rgb1 = 0;
		int pix = 0;
		int max1=0;
		int max2=0;

		int red1=0; int green1=0; int blue1=0; int red2=0; int green2=0; int blue2=0;
		
		ColorProcessor ip2=  new ColorProcessor(width, height);//MIP.tif
		
		for(int lateral=startMIP-1; lateral<endMIP; lateral++){
			IJ.showProgress((double)lateral/(double)stackSize);
			if(IJ.escapePressed()){
				return;
			}
			ip1 = st1.getProcessor(lateral+1);//original image
			for(int kk=0; kk<sumpx; kk++){
				
				int RG1=0; int BG1=0; int GR1=0; int GB1=0; int RB1=0; int BR1=0;
				int RG2=0; int BG2=0; int GR2=0; int GB2=0; int RB2=0; int BR2=0;
				
				pix=ip1.get(kk);
				
				red1 = (pix>>>16) & 0xff;//stack
				green1 = (pix>>>8) & 0xff;//stack
				blue1 = pix & 0xff;//stack
				
					
				if(red1>blue1 && red1>green1){//RB1 & RG1
					max1=red1;
					if(blue1>green1){
						RB1=red1+blue1;//1
					}else{
						RG1=red1+green1;//2
					}
				}else if(green1>blue1 && green1>red1){
					max1=green1;
					if(blue1>red1)
					GB1=green1+blue1;//3
					else
					GR1=green1+red1;//4
				}else if(blue1>red1 && blue1>green1){
					max1=blue1;
					if(red1>green1)
					BR1=blue1+red1;//5
					else
					BG1=blue1+green1;//6
				}
				
				int pix2=ip2.get(kk);
				
				red2 = (pix2>>>16) & 0xff;//MIP
				green2 = (pix2>>>8) & 0xff;//MIP
				blue2 = pix2 & 0xff;//MIP
				
				int MIPtwo=0;
				
				if(red2>0 || green2>0 || blue2>0){
					if(red2>blue2 && red2>green2){
						max2=red2;
						if(blue2>green2){//1
							RB2=red2+blue2;
							MIPtwo=RB2;
							MIPtwoST="RB2";
						}else{//2
							RG2=red2+green2;
							MIPtwo=RG2;
							MIPtwoST="RG2";
						}
					}else if(green2>blue2 && green2>red2){
						max2=green2;
						if(blue2>red2){//3
							GB2=green2+blue2;
							MIPtwo=GB2;
							MIPtwoST="GB2";
						}else{//4
							GR2=green2+red2;
							MIPtwo=GR2;
							MIPtwoST="GR2";
						}
					}else if(blue2>red2 && blue2>green2){
						max2=blue2;
						if(red2>green2){//5
							BR2=blue2+red2;
							MIPtwo=BR2;
							MIPtwoST="BR2";
						}else{//6
							BG2=blue2+green2;
							MIPtwo=BG2;
							MIPtwoST="BG2";
						}
					}//if(red2>=blue2 && red2>=green2){
					
					if(max1==255 & max2==255){
					}else{
					
						if(RB1>0){//data1 > 0
							if(max1>max2){//1
								rgb1=red1;
								
								if(green2<green1)
								rgb1 = (rgb1 << 8) + green1;
								else{//green2>green1
									if(green2<blue1)
									rgb1 = (rgb1 << 8) + green2;
									else//if(green2>=blue1)
									rgb1 = (rgb1 << 8) + green1;
								}
								
								rgb1 = (rgb1 << 8) + blue1;
								ip2.set(kk, rgb1);
							}else{
								
								MIPpix (ip2, red1, red2, green1, green2, blue1, blue2, kk, MIPtwoST);
							}//if(RB1<=MIPtwo){
							
						}else if(RG1>0){//2
							
							if(max1>max2){
								rgb1=red1;
								rgb1 = (rgb1 << 8) + green1;
								
								if(blue2<blue1)
								rgb1 = (rgb1 << 8) + blue1;
								else{//blue2>blue1
									if(blue2<green1)
									rgb1 = (rgb1 << 8) + blue2;
									else//(blue2>=green1)
									rgb1 = (rgb1 << 8) + blue1;
								}
	
								ip2.set(kk, rgb1);
								
							}else{
								
								MIPpix (ip2, red1, red2, green1, green2, blue1, blue2, kk, MIPtwoST);
							}//if(RG1>MIPtwo){
							
						}else if(GB1>0){//3
							
							if(max1>max2){
								
								if(red2<red1)
								rgb1 = red1;
								else{//red2>red1
									if(red2<blue1)
									rgb1 = red2;
									else//(red2>=blue1)
									rgb1 =  red1;
								}
								
								rgb1 = (rgb1 << 8) + green1;
								rgb1 = (rgb1 << 8) + blue1;
	
								ip2.set(kk, rgb1);
							}else{
								
								MIPpix (ip2, red1, red2, green1, green2, blue1, blue2, kk, MIPtwoST);
							}//if(RG1>MIPtwo){
							
						}else if(GR1>0){//4
							
							if(max1>max2){
								
								rgb1 =  red1;
								rgb1 = (rgb1 << 8) + green1;
								
								if(blue2<blue1)
								rgb1 = (rgb1 << 8) + blue1;
								else{//blue2>blue1
									if(blue2<red1)
									rgb1 = (rgb1 << 8) + blue2;
									else//(blue2>=red1)
									rgb1 =  (rgb1 << 8) + blue1;
								}
								
								ip2.set(kk, rgb1);
							}else{
								
								MIPpix (ip2, red1, red2, green1, green2, blue1, blue2, kk, MIPtwoST);
							}//if(RG1>MIPtwo){
							
						}else if(BR1>0){//5
							
							if(max1>max2){
								
								rgb1 =  red1;
								
								if(green2<green1)
								rgb1 = (rgb1 << 8) + green1;
								else{//green2>green1
									if(green2<red1)
									rgb1 = (rgb1 << 8) + green2;
									else//(green2>=red1)
									rgb1 =  (rgb1 << 8) + green1;
								}
								
								rgb1 =  (rgb1 << 8) + blue1;
								ip2.set(kk, rgb1);
							}else{
								
								MIPpix (ip2, red1, red2, green1, green2, blue1, blue2, kk, MIPtwoST);
							}//if(RG1>MIPtwo){
							
						}else if(BG1>0){//6
							
							if(max1>max2){
								
								if(red2<red1)
								rgb1 = red1;
								else{//red2>red1
									if(red2<green1)
									rgb1 = red2;
									else//(red2>=green1)
									rgb1 = red1;
								}
								
								rgb1 =  (rgb1 << 8) + green1;
								rgb1 =  (rgb1 << 8) + blue1;
								ip2.set(kk, rgb1);
							}else{
								
								MIPpix (ip2, red1, red2, green1, green2, blue1, blue2, kk, MIPtwoST);
							}//if(RG1>MIPtwo){
						}//if data1 > 0
					}//if(max1=255 & max2=255){
					
				}else{
					if(red2==0 && green2==0 && blue2==0 )
					ip2.set(kk, pix);
				}
			}//	for(int kk=0; kk<sumpx; kk++){
		//	IJ.log("MIPtwoST: " + MIPtwoST);
		}//	for(int lateral=0; lateral<stackSize; lateral++){
		
		newimp = new ImagePlus("RGB_MIP.tif", ip2);
		newimp.show();
		//	impD.setCalibration(cal);
		
	//	imp2.changes = false;
		//	winimp2.close();
		
	//	System.gc();
		//	WindowManager.setCurrentWindow(winD);
		

		
	}
	public void MIPpix (ColorProcessor ip3, int red1, int red2, int green1, int green2, int blue1, int blue2, int kk, String MIPtwoST2){
		
		int rgb1 = 0;
		
		if(MIPtwoST2=="RB2"){//RB2だからgreen2はblue2より小さい
			
			rgb1 = red2;
			
			if(green2>green1)
			rgb1 = (rgb1 << 8) + green2;
			else{//green2<green1
				if(green1<blue2)
				rgb1 = (rgb1 << 8) + green1;
				else//(green1>=blue2)
				rgb1 = (rgb1 << 8) + green2;
			}
			
			rgb1 = (rgb1 << 8) + blue2;
			ip3.set(kk, rgb1);
			
		}else if(MIPtwoST2=="RG2"){//2
			
			rgb1 = red2;
			rgb1 = (rgb1 << 8) + green2;
			
			if(blue2>blue1)
			rgb1 = (rgb1 << 8) + blue2;
			else{//blue2<blue1
				if(blue1<green2)
				rgb1 = (rgb1 << 8) + blue1;
				else//(blue1>=green2)
				rgb1 = (rgb1 << 8) + blue2;
			}
			
			//	IJ.log("RG2: " + red2 +"_"+green2);
			ip3.set(kk, rgb1);
			
		}else if(MIPtwoST2=="GB2"){//3, red2 is 最弱
			
			if(red2>red1)
			rgb1 = red2;
			else{//red2<red1
				if(red1<blue2)
				rgb1 = red1;
				else//(red1>=blue2){
				rgb1 = red2;
			}
			
			rgb1 = (rgb1 << 8) + green2;
			rgb1 = (rgb1 << 8) + blue2;
		
			ip3.set(kk, rgb1);
			
		}else if(MIPtwoST2=="GR2"){//4, red2 is 最弱
			
			rgb1 = red2;
			rgb1 = (rgb1 << 8) + green2;
			
			if(blue2>blue1)
			rgb1 = (rgb1 << 8) + blue2;
			else{//blue2<blue1
				if(blue1<red2)
				rgb1 = (rgb1 << 8) + blue1;
				else//(blue1>=red2)
				rgb1 = (rgb1 << 8) + blue2;
			}
			
			ip3.set(kk, rgb1);
			
		}else if(MIPtwoST2=="BR2"){//5, green2 is 最弱
			
			rgb1 = red2;
			
			if(green2>green1)
			rgb1 = (rgb1 << 8) + green2;
			else{//green2<green1
				if(green1<red2)
				rgb1 = (rgb1 << 8) + green1;
				else//(green1>=red2)
				rgb1 = (rgb1 << 8) + green2;
			}
			
			rgb1 = (rgb1 << 8) + blue2;
			
			ip3.set(kk, rgb1);
			
		}else if(MIPtwoST2=="BG2"){//6, red2 is 最弱
			
			if(red2>red1)
			rgb1 = red2;
			else{//red2<red1
				if(red1<green2)
				rgb1 = red1;
				else//(red1>=green2)
				rgb1 = red2;
			}
			
			rgb1 = (rgb1 << 8) + green2;
			rgb1 = (rgb1 << 8) + blue2;
			
			ip3.set(kk, rgb1);
		}
	}//function
}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
