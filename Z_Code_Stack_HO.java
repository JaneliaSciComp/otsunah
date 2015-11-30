import ij.*;
import ij.plugin.filter.*;
//import ij.plugin.PlugIn;
import ij.process.*;
import ij.gui.*;
import ij.process.ImageConverter;
//import java.math.*;
//import java.io.*;
//import java.util.*;
//import java.net.*;
import ij.Macro.*;
//import java.awt.*;
//import ij.macro.*;
//import ij.plugin.*;
import ij.measure.Calibration;
import ij.gui.NewImage.*;

public class Z_Code_Stack_HO implements PlugInFilter {
	
	ImageProcessor ip2, ip3;
	ImagePlus imp, imp2, newimp;

	public int setup(String arg, ImagePlus imp) {
		
		IJ.register (Z_Code_Stack_HO.class);
		if (IJ.versionLessThan("1.32c")){
			IJ.showMessage("Error", "Please Update ImageJ.");
			return 0;
		}
		
		//	IJ.log(" wList;"+String.valueOf(wList));
		
		this.imp = imp;
		this.imp2 = imp2;
		if(imp.getType()!=imp.GRAY8){
			IJ.showMessage("Error", "Plugin requires 8-bit image");
			return 0;
		}
		return DOES_8G;
	}
	
	public void run(ImageProcessor ip1){
		
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
		
		int stacklut=(int)Prefs.get("stacklut.int",1);
		
		if(stacklut > imageno){
			stacklut=imageno-1;
		}
		//IJ.log(" stacklut;"+String.valueOf(stacklut));
		
		GenericDialog gd = new GenericDialog("Mask Brightness adjustment");
		gd.addChoice("Data for color depth", titles, titles[0]); //Mask
		gd.addChoice("1px hight lut image", titles, titles[stacklut]); //Data

		
		gd.showDialog();
		if(gd.wasCanceled()){
			return;
		}
		
		int Mask = gd.getNextChoiceIndex(); //original 8bit
		int datafile = gd.getNextChoiceIndex(); //lut table
		
		imp = WindowManager.getImage(wList[Mask]);
	//	titles[Mask] = imp.getTitle();//original 8bit
		
		imp2 = WindowManager.getImage(wList[datafile]);//lut table
		
		Prefs.set("stacklut.int",stacklut);
		
		if (imp==null) {
			IJ.noImage();
			return;
		}
		
		int width = imp.getWidth();
		int height = imp.getHeight();
		int stackSize = imp.getStackSize();
		
		if (stackSize<2) {
			IJ.error("", "Stack required");
			return;
		}

		ip1 = imp.getProcessor();
		ImageStack st1 = imp.getStack();
		int sumpx = ip1.getPixelCount();
		//	Calibration cal = imp.getCalibration();
		
		if(IJ.escapePressed()){
			return;
		}
		
	//	ImagePlus newimp = IJ.createHyperStack("Depth Coded Stack", width, height, 1, imageD, nFrame, 24);
		
		//ImagePlus newimp =NewImage.createRGBImage("Depth Coded Stack", width, height, imageD, NewImage.FILL_BLACK );
	//	ImageStack dcStack = newimp.getStack();
		//	ImagePlus newimp =IJ.createImage("Depth Coded Stack", width, height, imageD, 24);
		
		IJ.showStatus("Depth color coding");
		IJ.showProgress(0.0);

		int rgb1 = 0;
		int pix = 0;
		ColorProcessor ipc2 =  (ColorProcessor) imp2.getProcessor();//lut table
		int R=0; 
		int G=0; 
		int B=0;
		int colorpix=0;
		
		int red1=0; int green1=0; int blue1=0;
		ImageStack dcStack = new ImageStack (width,height);
		
		for(int lateral=0; lateral<stackSize; lateral++){
			IJ.showProgress((double)lateral/(double)stackSize);
			
			ip1 = st1.getProcessor(lateral+1);//original image
			
			ColorProcessor ip2=  new ColorProcessor(width, height);//RGB.tif
			
			colorpix=ipc2.get(lateral);// lut table
			
			int red = (colorpix>>>16) & 0xff;
			int green = (colorpix>>>8) & 0xff;
			int blue = colorpix & 0xff;
			
			for(int kk=0; kk<sumpx; kk++){
				pix=ip1.get(kk);
				
				red1 = (pix>>>16) & 0xff;//data
				green1 = (pix>>>8) & 0xff;//data
				blue1 = pix & 0xff;//data
				
				if(red1>1 || green1>1 || blue1>1){
					R=(int)(((double)pix/(double)255)*(double)red);
					G=(int)(((double)pix/(double)255)*(double)green);
					B=(int)(((double)pix/(double)255)*(double)blue);
					
					rgb1 = R;
					rgb1 = (rgb1 << 8) + G;
					rgb1 = (rgb1 << 8) + B;
					
					ip2.set(kk, rgb1);
				}
			}//	for(int kk=0; kk<sumpx; kk++){

			dcStack.addSlice("depth coded", ip2);
		}//	for(int lateral=0; lateral<stackSize; lateral++){
		
		newimp = new ImagePlus("Depth_color_RGB.tif", dcStack);
		newimp.show();
		
	//	System.gc();
	//	WindowManager.setCurrentWindow(winD);
	}
}
