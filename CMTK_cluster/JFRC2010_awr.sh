#!/bin/sh#!/bin/sh
#
# developed by Yang Yu (yuy@janelia.hhmi.org) 03/23/2017
# default input image folder will be used by cmtk "images"
# default temporary folder created by cmtk "Registration" and "reformatted"
# 
#
# env setting
CMTKALIGNER=/nrs/scicompsoft/otsuna/CMTK/bin/munger
CMTKDIR=/nrs/scicompsoft/otsuna/CMTK/bin
TEMPLATE=/nrs/scicompsoft/otsuna/JFRC2010_BrainAligner/JFRC2010_16bit.nrrd
#
# input
INPUTDIR=$1
THREADS=$2
#
# alignment
cd $INPUTDIR
$CMTKALIGNER -b $CMTKDIR -a -w -r 0102030405 -X 26 -C 8 -G 80 -R 4 -A '--accuracy 0.8' -W '--accuracy 0.8' -T $THREADS -s $TEMPLATE images
