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
OneNrrdOnly=0

if [[ $OneNrrdOnly -ne 1 ]]
then
	for i in $RegFolder/images/*_01.nrrd;
    do
    echo $i
	if [[ -e $i ]]
    then 
        j=${i%_*d}; 
		if [[ ! -e $j ]]
		then
			echo $j
			OUT=$j/alignCmd.sh
			echo $OUT  "OUTTT"
			mkdir $j; 
			mkdir $j/images;
		fi
		if [[ ! -e $j/images/*_01.nrrd ]]
		then
			echo $j
			echo $j/images/*._01nrrd
			mv $i $j/images/;
		fi
	fi
 done
fi

if [[ $OneNrrdOnly -eq 1 ]]
then
G=$RegFolder/images/*_01.nrrd
echo $G G is here
#	if [[ -e $i ]]
#then 
echo exist
		j=${G%_*d}; 
		if [[ ! -e $j ]]
			then
			echo $j
OUT=$j/alignCmd.sh
echo $OUT  "OUTTT"
			mkdir $j
			mkdir $j/images
		fi
		if [[ ! -e $j/images/*_01.nrrd ]]
		then
			echo $j
			echo $j/images/*._01nrrd
			mv $G $j/images/
		fi
#	fi
fi

#for i in $RegFolder/*.nrrd; do j=${i%*_*}; mv $j* $j/images/; done

if [ ! -e $RegFolder/Registration/ ]
then
	mkdir $RegFolder/Registration/
	mkdir $RegFolder/Registration/affine/
	mkdir $RegFolder/Registration/warp/
fi

echo "sh /nrs/scicompsoft/otsuna/MCFO_20x_Project/Masayoshi_MCFO/brainAlignerJfrc2010Cmtk.sh $INPUTDIR $THREAD;" > $OUT
echo "mv $INPUTDIR/Registration/affine/* $RegFolder/Registration/affine/;" >> $OUT
echo "mv $INPUTDIR/Registration/warp/* $RegFolder/Registration/warp/;" >> $OUT
#echo "for i in $INPUTDIR/images/*.nrrd; do mv ${i%*/*}/*/images/*.nrrd $RegFolder/images/; done" >> $OUT
echo "mv $INPUTDIR/images/*.nrrd $RegFolder/images/;" >> $OUT
echo "echo file moved *nrrd ;" >> $OUT
#echo "mv $INPUTDIR/images/*.nrrd; $RegFolder/images/;" >> $OUT
#echo "mv $INPUTDIR/images/*.nrrd; $RegFolder/images/;" >> $OUT
#echo "mv $INPUTDIR/images/*.nrrd; $RegFolder/images/;" >> $OUT
chmod 755 $OUT
