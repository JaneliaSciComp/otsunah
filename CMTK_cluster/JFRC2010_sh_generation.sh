#!/bin/sh

# developed by Yang Yu (yuy@janelia.hhmi.org) 03/23/2017
# genrate the alignment script
#

# Usages:
###
# Example 1 (for single brain): 
# $mkdir /nrs/scicompsoft/yuy/registration/images/VT005002_AE_01-20131024_33_I1
# $mkdir /nrs/scicompsoft/yuy/registration/images/VT005002_AE_01-20131024_33_I1/images
# $cp VT005002_AE_01-20131024_33_I1_*.nrrd /nrs/scicompsoft/yuy/registration/images/VT005002_AE_01-20131024_33_I1/images
# $sh genAlignScript.sh /nrs/scicompsoft/yuy/registration/images/VT005002_AE_01-20131024_33_I1 32
# $qsub -pe batch 32 -l broadwell=true -j y -b y -cwd -V /nrs/scicompsoft/yuy/registration/images/VT005002_AE_01-20131024_33_I1/alignCmd.sh
###
# Example 2 (for multiple brains):
# $for i in /nrs/scicompsoft/yuy/registration/images/*.nrrd; do j=${i%*_*}; mkdir $j; mkdir $j/images; done
# $for i in /nrs/scicompsoft/yuy/registration/images/*.nrrd; do j=${i%*_*}; mv $j* $j/images/; done
# $for i in /nrs/scicompsoft/yuy/registration/images/*; do sh genAlignScript.sh $i 32; done
# $for i in /nrs/scicompsoft/yuy/registration/images/*/alignCmd.sh; do qsub -pe batch 32 -l broadwell=true -j y -b y -cwd -V $i; done
# $qstat

#
INPUTDIR=$1
THREAD=$2
OUT=$3

#/nrs/scicompsoft/otsuna/Masayoshi_MCFO/images
RegFolder=$4

echo $INPUTDIR " ;INPUT"

	
if [[ -e $INPUTDIR ]]
	then 
	j=${INPUTDIR%_*d}
	OUT=$j/alignCmd.sh
	echo $OUT  "OUTTT"
	if [[ ! -e $j ]]
		then
		echo $j " ; j"
		
		mkdir $j
		mkdir $j/images
	fi
		
	if [[ ! -e $j/images/*.nrrd ]]
	then
#	echo $j/images/*.nrrd

		
		mv $INPUTDIR $j/images/
	
	fi
fi


#for i in $RegFolder/*.nrrd; do j=${i%*_*}; mv $j* $j/images/; done

if [ ! -e $RegFolder/Registration/ ]
then
	mkdir $RegFolder/Registration/
	mkdir $RegFolder/Registration/affine/
	mkdir $RegFolder/Registration/warp/
	mkdir $RegFolder/reformatted/
fi

echo "sh /nrs/scicompsoft/otsuna/JFRC2010_BrainAligner/JFRC2010_awr.sh $j $THREAD;" > $OUT
echo "mv $INPUTDIR/Registration/affine/* $RegFolder/Registration/affine/;" >> $OUT
echo "mv $INPUTDIR/Registration/warp/* $RegFolder/Registration/warp/;" >> $OUT
echo "mv $INPUTDIR/reformatted/* $RegFolder/reformatted/;" >> $OUT
echo "mv $INPUTDIR/images/*.nrrd $RegFolder/images/;" >> $OUT
echo "echo file moved *nrrd ;" >> $OUT


chmod 755 $OUT
