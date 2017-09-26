#!/bin/bash


FIJI="/Applications/FijizOLD.app/Contents/MacOS/ImageJ-macosx"
PREPROCIMG="/Users/otsunah/Documents/otsunah/20x_brain_aligner/20x_Brain_Global_Aligner_Pipeline.ijm"
OUTPUT="/test/20x_brain_alignment"
preprocResult="Test.zip"
path="/test/20x_brain_alignment/Test.zip"

cd "/Users/otsunah/Documents/otsunah/20x_brain_aligner/"

Frontal50pxPath="/Users/otsunah/Documents/otsunah/20x_brain_aligner/JFRC2010_50pxMIP.tif"
LateralMIPPath="/Users/otsunah/Documents/otsunah/20x_brain_aligner/Lateral_JFRC2010_5time_smallerMIP.tif"
Slice50pxPath="/Users/otsunah/Documents/otsunah/20x_brain_aligner/JFRC2010_50pxSlice.tif"
ShapeMatchingMaskPath="/Users/otsunah/Documents/otsunah/20x_brain_aligner/JFRC2010_ShapeMatchingMask.tif"
JFRC2010AveProPath="/Users/otsunah/Documents/otsunah/20x_brain_aligner/JFRC2010_AvePro.png"

# X voxel size
widthVx=0.62

# slice depth
depth=1

#number of CPU
numCPU=7

$FIJI -macro $PREPROCIMG "$OUTPUT/,preprocResult,$path,$Frontal50pxPath,$LateralMIPPath,$Slice50pxPath,$ShapeMatchingMaskPath,$JFRC2010AveProPath,$widthVx,$depth,$numCPU"
