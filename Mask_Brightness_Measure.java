import ij.*;
import ij.plugin.filter.*;
import ij.plugin.PlugIn;
import ij.process.*;
import ij.gui.*;
import java.math.*;
import java.io.*;
import java.util.*;
import java.net.*;
import ij.Macro.*;
import java.awt.*;
//import ij.macro.*;
import ij.gui.GenericDialog.*;



public class Mask_Brightness_Measure implements PlugInFilter
	{
	ImagePlus imp, imp2;
	ImageProcessor ip1, ip2, ip3, ipnew;
	double maxvalue=0;
	int pix1=0;
	double pix3=0;
	int increment=0;
	int pixset=0;
	double totalmax=0;
	ImagePlus newimp;
	int twohun = 255;
	
	public int setup(String arg, ImagePlus imp)
	{
		IJ.register (Mask_Brightness_Measure.class);
		if (IJ.versionLessThan("1.32c")){
			IJ.showMessage("Error", "Please Update ImageJ.");
			return 0;
		}
		
	//	IJ.log(" wList;"+String.valueOf(wList));
		
		this.imp = imp;
		if(imp.getType()!=imp.GRAY8 && imp.getType()!=imp.GRAY16){
			IJ.showMessage("Error", "Plugin requires 8- or 16-bit image");
			return 0;
		}
		return DOES_8G+DOES_16;

	//	IJ.log(" noisemethod;"+String.valueOf(ff));
	}

	public void run(ImageProcessor ip){
		
		int wList [] = WindowManager.getIDList();
		if (wList==null || wList.length<2) {
			IJ.showMessage("There must be at least two windows open");
			return;
		}
		int imageno = 0;
		String titles [] = new String[wList.length];
		for (int i=0; i<wList.length; i++) {
			ImagePlus imp = WindowManager.getImage(wList[i]);
			if (imp!=null){
			titles[i] = imp.getTitle();//Mask.tif and Data.tif
			imageno = imageno +1;
			}else
			titles[i] = "";
		}
/////Dialog//////////////////////////////////////////////		

		int stack88=(int)Prefs.get("stack2.int",1);
		
		if(stack88 > imageno){
			stack88=imageno-1;
		}
	
		GenericDialog gd = new GenericDialog("Mask Brightness adjustment");
		gd.addChoice("Mask", titles, titles[0]); //Mask
		gd.addChoice("Data for the brightness measure", titles, titles[stack88]); //Data
		
		gd.addNumericField("Desired mean", 150,0);
		gd.showDialog();
		if(gd.wasCanceled()){
			return;
		}
		
		int Mask = gd.getNextChoiceIndex(); //Min projection
		int datafile = gd.getNextChoiceIndex(); //stack
		int desiremean1=(int)gd.getNextNumber();
		
		double desiremean=(double)desiremean1;

		
		if(imp.getType()==imp.GRAY16)
		desiremean=desiremean*16;
		
		
		imp = WindowManager.getImage(wList[Mask]);
		titles[Mask] = imp.getTitle();//Mask.tif and Data.tif
		
		imp2 = WindowManager.getImage(wList[datafile]);
		titles[datafile] = imp2.getTitle();//Mask.tif and Data.tif
		
		Prefs.set("stack2.int",stack88);
		
		newimp = imp2.duplicate();
		
///////		
		ImagePlus imask = WindowManager.getImage(wList[Mask]); //Mask
		ImagePlus idata = WindowManager.getImage(wList[datafile]); //Data
		
		ip1 = imask.getProcessor(); //Mask
		int sumpx = ip1.getPixelCount();
		
		BigDecimal sumVX = new BigDecimal("0.00");
		BigDecimal value1 = new BigDecimal("0.00");
		BigDecimal value2 = new BigDecimal("0.00");
		BigDecimal one1 = new BigDecimal("1.00");
		int value0 = 0;

		ip3 = idata.getProcessor(); //data
		
		if(IJ.escapePressed()){
			return;
		}
			
		IJ.showStatus("Mask_brightness_adjustment");
		
		//	IJ.log(" posipx;"+String.valueOf(posipx));
/////////////////////Start: signal detection///////////////////////////////
		
		for(int n=0; n<sumpx; n++){
			pix1= ip1.get(n);
			if(pix1>200){//Mask value
					
				sumVX = sumVX.add(one1);
					
				pix3= ip3.get(n);//double
				
				if(pix3>maxvalue)
				maxvalue=pix3;
				
			 value2 = BigDecimal.valueOf(pix3);
				
				if(pix3>0)
				value1 = value1.add(value2);//total sum brightness
			}//	if(pix1>200){
		}//for(int n=0; n<sumpx; n++){
		
		if(maxvalue>4096)
		desiremean=desiremean*16;;
		
		BigDecimal mean2=new BigDecimal("0.00");
		if(maxvalue>0){
			mean2=value1.divide(sumVX, 3, BigDecimal.ROUND_HALF_UP);
		}else{
			idata.setTitle(String.valueOf(0));
			IJ.log("No signal");
			return;
		}
		
		double mean3 = mean2.intValue();
		double maxvalue2=0;
		
	//	IJ.log(" mean3;"+String.valueOf(mean3));
		////////////////////////////////////////////////////////////////////////////////////
		if(mean3>=desiremean){
			if(imp.getType()==imp.GRAY8)
			idata.setTitle(String.valueOf(twohun));
			
			if(imp.getType()==imp.GRAY16)
			idata.setTitle(String.valueOf(maxvalue));
			
		}
		while(mean3<desiremean){
			BigDecimal value11 = new BigDecimal("0.00");
			BigDecimal mean22=new BigDecimal("0.00");
	//		IJ.log("value1; "+String.valueOf(value1));
			ipnew = newimp.getProcessor();
			
			double gap=desiremean-mean3;
			
			if(imp.getType()==imp.GRAY8){
				maxvalue2=1;
				if(gap>80)
				maxvalue2=maxvalue/6;
			}//if(imp.getType()==imp.GRAY8){
			if(imp.getType()==imp.GRAY16){
				
				maxvalue2=2;
				
				if(gap>500){
					maxvalue2=maxvalue*0.01;
				}
			}//if(bitd==16){
			maxvalue2=Math.round(maxvalue2);
			
			if(IJ.escapePressed()){
				return;
			}
			
	//		IJ.log("maxvalue; "+maxvalue2+"	 gap;	"+gap);
			totalmax=totalmax+maxvalue2;
			
			for(int n3=0; n3<sumpx; n3++){
				pix1= ip1.get(n3);// from mask
				if(pix1>200){//Mask value
					
					pix3= ip3.get(n3);
					pix3=pix3+totalmax;
					
					if(imp.getType()==imp.GRAY16 && maxvalue<4095){
						if(pix3>4095)
						pix3=4095;
						
					}else if(imp.getType()==imp.GRAY16 && maxvalue>4095){
						if(pix3>65535)
						pix3=65535;
						
					}else if(maxvalue<256){
						if(pix3>255)
						pix3=255;
					}
					
					pixset=(int)pix3;
					
					ipnew.set(n3, pixset);
					
					value2 = BigDecimal.valueOf(pix3);
					value11 = value11.add(value2);//total sum brightness
					
				}//	if(pix1>200){
			}//for(int n3=0; n3<sumpx; n3++){
			mean22=value11.divide(sumVX, 3, BigDecimal.ROUND_HALF_UP);
			mean3 = mean22.doubleValue();
			increment=increment+1;
			idata.setTitle(String.valueOf(totalmax));
		}//while(mean3<desiremean){
	} //public void run(ImageProcessor ip){
} //public class Two_windows_mask_search implements PlugInFilter{



























