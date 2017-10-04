#!/bin/bash
# Program locations: (assumes running this in vnc_align script directory)
#
# 20x brain alignment pipeline using CMTK, version 1.0, Sep 26, 2017
#

################################################################################
#
# The pipeline is developed for aligning 20x fly brain using CMTK
# The standard brain's resolution (0.62x0.62x1 um)
#
################################################################################

##################
# Basic Funcs
##################

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

##################
# Inputs
##################

parseParameters "$@"

CONFIGFILE=$CONFIG_FILE
TMPLDIR=$TEMPLATE_DIR
TOOLDIR=$TOOL_DIR
WORKDIR=$WORK_DIR

Frontal50pxPath=$DIR/"JFRC2010_50pxMIP.tif"
LateralMIPPath=$DIR/"Lateral_JFRC2010_5time_smallerMIP.tif"
Slice50pxPath=$DIR/"JFRC2010_50pxSlice.tif"
ShapeMatchingMaskPath=$DIR/"JFRC2010_ShapeMatchingMask.tif"
JFRC2010AveProPath=$DIR/"JFRC2010_AvePro.png"

numCPU=

SUBJFRC2010=$INPUT1_FILE
SUBREF=$INPUT1_REF
CONSLABEL=$INPUT1_NEURONS
CHN=$INPUT1_CHANNELS
#GENDER=$GENDER

#MP=$MOUNTING_PROTOCOL

RESX=$INPUT1_RESX
RESY=$INPUT1_RESY
RESZ=$INPUT1_RESZ

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
JBA=`readItemFromConf $CONFIGFILE "JBA"`
ANTS=`readItemFromConf $CONFIGFILE "ANTS"`
WARP=`readItemFromConf $CONFIGFILE "WARP"`
CMTK=`readItemFromConf $CONFIGFILE "CMTK"`
FIJI=`readItemFromConf $CONFIGFILE "Fiji"`
BrainScripts=`readItemFromConf $CONFIGFILE "BrainScripts"`
# add CMTK tools here

Vaa3D=${TOOLDIR}"/"${Vaa3D}
JBA=${TOOLDIR}"/"${JBA}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}
CMTK=${TOOLDIR}"/"${CMTK}
FIJI=${TOOLDIR}"/"${FIJI}
BrainScripts=${TOOLDIR}"/"${BrainScripts}"/"


# templates
ATLAS=`readItemFromConf $CONFIGFILE "atlasFBTX"`
TAR=`readItemFromConf $CONFIGFILE "tgtFBTX"`
TARMARKER=`readItemFromConf $CONFIGFILE "tgtFBTXmarkers"`
TARREF=`readItemFromConf $CONFIGFILE "REFNO"`
RESTX_X=`readItemFromConf $CONFIGFILE "VSZX_20X_IS"`
RESTX_Y=`readItemFromConf $CONFIGFILE "VSZY_20X_IS"`
RESTX_Z=`readItemFromConf $CONFIGFILE "VSZZ_20X_IS"`
LCRMASK=`readItemFromConf $CONFIGFILE "LCRMASK"`
CMPBND=`readItemFromConf $CONFIGFILE "CMPBND"`
JFRC2010temp=`readItemFromConf $CONFIGFILE "tgtJFRC2010temp"`
#JFRC2010TEMPLATEMALE=`readItemFromConf $CONFIGFILE "tgtJFRC201020xAMale"`

TAR=${TMPLDIR}"/"${TAR}
ATLAS=${TMPLDIR}"/"${ATLAS}
TARMARKER=${TMPLDIR}"/"${TARMARKER}
LCRMASK=${TMPLDIR}"/"${LCRMASK}
CMPBND=${TMPLDIR}"/"${CMPBND}

#if [[ $GENDER =~ "m" ]]
#then
# male fly vnc
#Tfile=${TMPLDIR}"/"${JFRC2010TEMPLATEMALE}
#POSTSCOREMASK=$BrainScripts"20x_brain_aligner/For_Score/Mask_Male_JFRC2010.nrrd"
#else
# female fly vnc
Tfile=${TMPLDIR}"/"${JFRC2010temp}
POSTSCOREMASK=$BrainScripts"20xbrain_preImageProcessing_Plugins_pipeline/For_Score/JFRC2010_symmetric_mask.nrrd"
#fi

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUBJFRC2010: $SUBJFRC2010"
echo "SUBREF: $SUBREF"
echo "MountingProtocol: $MP"
echo "Gender: $GENDER"
echo "RESX: $RESX"
echo "RESY: $RESY"
echo "RESZ: $RESZ"
message "Vars..."
echo "Vaa3D: $Vaa3D"
echo "ANTS: $ANTS"
echo "WARP: $WARP"
echo "TAR: $TAR"
echo "TARMARKER: $TARMARKER"
echo "TARREF: $TARREF"
echo "ATLAS: $ATLAS"
echo "LCRMASK: $LCRMASK"
echo "CMPBND: $CMPBND"
echo "CMTK: $CMTK"
echo "FIJI: $FIJI"
echo "BrainScripts: $BrainScripts"
echo "TEMPLATE: $Tfile"
echo ""

OUTPUT=${WORKDIR}"/Outputs"
FINALOUTPUT=${WORKDIR}"/FinalOutputs"

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

if [ ! -d $FINALOUTPUT ]; then 
mkdir $FINALOUTPUT
fi

PREPROCIMG=$BrainScripts"20x_brain_aligner/20x_Brain_Global_Aligner_Pipeline.ijm"
POSTSCORE=$BrainScripts"20x_brain_aligner/For_Score/Score_For_Brain_pipeline.ijm"
RAWCONV=$BrainScripts"raw2nrrd.ijm"
#NRRDCONV=$BrainScripts"nrrd2raw.ijm"
NRRDCONV=$BrainScripts"nrrd2v3draw_MCFO.ijm" 
ZPROJECT=$BrainScripts"z_project.ijm"
PYTHON='/misc/local/python-2.7.3/bin/python'
PREPROC=$BrainScripts"PreProcess.py"
QUAL=$BrainScripts"OverlapCoeff.py"
QUAL2=$BrainScripts"ObjPearsonCoeff.py"
LSMR=$BrainScripts"lsm2nrrdR.ijm"

echo "Job started at" `date` "on" `hostname`
SAGE_IMAGE="$grammar{sage_image}"
echo "$sage_image"

# Shepherd JFRC2010 alignment
#preproc_result=$OUTPUT"/preprocResult.nrrd"
#unregistered_raw=$OUTPUT"/unregJFRC2010.v3draw"
#registered_pp_raw=$OUTPUT"/JFRC2010-PP.raw"
#registered_pp_c1_nrrd=$OUTPUT"/JFRC2010-PP_C1.nrrd"
#registered_pp_c2_nrrd=$OUTPUT"/JFRC2010-PP_C2.nrrd"

registered_pp_sg1_nrrd=$OUTPUT"/preprocResult_02.nrrd"
registered_pp_sg2_nrrd=$OUTPUT"/preprocResult_03.nrrd"
registered_pp_sg3_nrrd=$OUTPUT"/preprocResult_04.nrrd"

# Hideo output always sets reference as the first channel exported.
registered_pp_bg_nrrd=$OUTPUT"/preprocResult_01.nrrd"
registered_pp_initial_xform=$OUTPUT"/JFRC2010-PP-initial.xform"
registered_pp_affine_xform=$OUTPUT"/JFRC2010-PP-affine.xform"
registered_pp_warp_xform=$OUTPUT"/JFRC2010-PP-warp.xform"
registered_pp_bgwarp_nrrd=$OUTPUT"/JFRC2010-PP-BGwarp.nrrd"
registered_pp_warp_qual=$OUTPUT"/JFRC2010-PP-warp_qual.csv"
registered_pp_warp_qual_temp=$OUTPUT"/JFRC2010-PP-warp_qual.tmp"
registered_pp_sgwarp1_nrrd=$OUTPUT"/JFRC2010-PP-SGwarp1.nrrd"
registered_pp_sgwarp2_nrrd=$OUTPUT"/JFRC2010-PP-SGwarp2.nrrd"
registered_pp_sgwarp3_nrrd=$OUTPUT"/JFRC2010-PP-SGwarp3.nrrd"


registered_pp_warp_png=$OUTPUT"/JFRC2010-PP-warp.png"
#registered_pp_warp_raw=$OUTPUT"/JFRC2010-PP-warp.raw"
registered_pp_warp_v3draw_filename="AlignedFlyJFRC2010.v3draw"
registered_pp_warp_v3draw=$OUTPUT"/"${registered_pp_warp_v3draw_filename}
registered_otsuna_qual=$OUTPUT"/Hideo_OBJPearsonCoeff.txt"

# Neuron separation definitions. Expecting consolidated label to be sibling of signal.
#Unaligned_Neuron_Separator_Dir=$(dirname "${CONSLABEL}")"/"
#Unaligned_Neuron_Separator_Result_V3DPBD=${Unaligned_Neuron_Separator_Dir}"ConsolidatedLabel.v3dpbd"
#Unaligned_Neuron_Separator_Result_RAW=${Unaligned_Neuron_Separator_Dir}"ConsolidatedLabel.v3draw"
#CONSLABEL_FN="ConsolidatedLabel.v3draw"
#Aligned_Consolidated_Label_V3DPBD=${OUTPUT}"/"${CONSLABEL_FN}

V3DPBD2NRRD=$BrainScripts"20x_brain_aligner/v3dpbd2nrrd.ijm"
#Reformatted_Separator_result_v3draw=$OUTPUT"/Reformatted_Separator_Result.v3draw"
#NRRD2V3DRAW_NS=$BrainScripts"20x_brain_aligner/nrrd2v3draw_N_separator_result.ijm"
#PREALIGNEDJFRC2010=${OUTPUT}"/PreAlignedJFRC2010.v3draw"

# Make sure the .lsm file exists
if [ -e $SUBJFRC2010 ]
then
echo "Input file exists: "$SUBJFRC2010
else
echo -e "Error: image $SUBJFRC2010 does not exist"
exit -1
fi

# Ensure existence of required inputs from unaligned neuron separation.
#UNSR_TO_DEL="sentinel_nonexistent_file"
#UNALIGNED_NEUSEP_EXISTS=1
#if [ ! -e $Unaligned_Neuron_Separator_Result_RAW ]
#then
#if [ -e $Unaligned_Neuron_Separator_Result_V3DPBD ]
#then
# Now I need to translate to raw version.
#$Vaa3D -cmd image-loader -convert $Unaligned_Neuron_Separator_Result_V3DPBD $Unaligned_Neuron_Separator_Result_RAW
#UNSR_TO_DEL=$Unaligned_Neuron_Separator_Result_RAW
#else
#echo -e "Warning: neither unaligned neuron separation result $Unaligned_Neuron_Separator_Result_V3DPBD nor $Unaligned_Neuron_Separator_Result_RAW exists. Perhaps user has deleted neuron separations?"
#UNALIGNED_NEUSEP_EXISTS=0
#fi
#fi

STARTDIR=`pwd`
cd $OUTPUT
# -------------------------------------------------------------------------------------------
echo "+---------------------------------------------------------------------------------------+"
echo "| Running Otsuna preprocessing step                                                     |"
echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,preprocResult,$path,$Frontal50pxPath,LateralMIPPath,$Slice50pxPath,$ShapeMatchingMaskPath,$JFRC2010AveProPath,$RESX,$RESZ,$numCPU\" |"
echo "+---------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
# Expect to take far less than 1 hour
if [ ! -e $Unaligned_Neuron_Separator_Result_RAW ]
then
#echo "Warning: $PREPROCIMG will be given a nonexistent $Unaligned_Neuron_Separator_Result_V3DPBD"
fi
timeout --preserve-status 40m $FIJI -macro $PREPROCIMG "$OUTPUT/,preprocResult,$path,$Frontal50pxPath,LateralMIPPath,$Slice50pxPath,$ShapeMatchingMaskPath,$JFRC2010AveProPath,$RESX,$RESZ,$numCPU"
STOP=`date '+%F %T'`
echo "Otsuna preprocessing start: $START"
echo "Otsuna preprocessing stop: $STOP"

if [ ! -e $registered_pp_bg_nrrd ]
then
echo -e "Error: Brain preprocessing step failed"
exit -1
fi
#/usr/local/pipeline/bin/add_operation -operation raw_nrrd_conversion -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$FIJI" -version '1.47q' -parm imagej_macro="$LSMR"
sleep 2

#
#  The preprocessing step reverses the order from what is
#  required elsewhere in the pipeline.
#  This cannot be done before the files are created.
#
if [ -e $registered_pp_sg3_nrrd ]
then
echo "+---------------------------------------------------------------------------------------+"
echo "| Reordering sgwarp3 nrrd wih sgwarp1 nrrd.                                             |"
echo "+---------------------------------------------------------------------------------------+"

# Switching ordering of channels between 3 and 1.
registered_pp_sg3_nrrd=$OUTPUT"/preprocResult_02.nrrd"
registered_pp_sg2_nrrd=$OUTPUT"/preprocResult_03.nrrd"
registered_pp_sg1_nrrd=$OUTPUT"/preprocResult_04.nrrd"
elif [ -e $registered_pp_sgwarp2_nrrd ]
then
echo "+---------------------------------------------------------------------------------------+"
echo "| Reordering sgwarp2 nrrd wih sgwarp1 nrrd.                                             |"
echo "+---------------------------------------------------------------------------------------+"

# Switching ordering of channels between 2 and 1.
registered_pp_sg2_nrrd=$OUTPUT"/preprocResult_02.nrrd"
registered_pp_sg1_nrrd=$OUTPUT"/preprocResult_03.nrrd"
fi


# CMTK make initial affine
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK make_initial_affine                                     |"
echo "| $CMTK/make_initial_affine --principal_axes $Tfile $registered_pp_bg_nrrd $registered_pp_initial_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/make_initial_affine --principal_axes $Tfile $registered_pp_bg_nrrd $registered_pp_initial_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_initial_xform ]
then
echo -e "Error: CMTK make initial affine failed"
exit -1
fi
echo "cmtk_initial_affine start: $START"
echo "cmtk_initial_affine stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_initial_affine -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/make_initial_affine" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK registration
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK registration                                            |"
echo "| $CMTK/registration --initial $registered_pp_initial_xform --dofs 6,9 --auto-multi-levels 4 --accuracy 0.8 -o $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/registration --initial $registered_pp_initial_xform --dofs 6,9 --auto-multi-levels 4 --accuracy 0.8 -o $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_affine_xform ]
then
echo -e "Error: CMTK registration failed"
exit -1
fi
echo "cmtk_registration start: $START"
echo "cmtk_registration stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_registration -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" - operator $USERID -program "$CMTK/registration" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK warping
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK warping                                                 |"
echo "| $CMTK/warp --threads $NSLOTS -o $registered_pp_warp_xform --grid-spacing 80 --exploration 30 --coarsest 4 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --initial $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/warp --threads $NSLOTS -o $registered_pp_warp_xform --grid-spacing 80 --exploration 30 --coarsest 4 --accuracy 0.8 --refine 4 --energy-weight 1e-1 --initial $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_warp_xform ]
then
echo -e "Error: CMTK warping failed"
exit -1
fi
echo "cmtk_warping start: $START"
echo "cmtk_warping stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_warping -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/warp" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK reformatting
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK reformatting                                            |"
echo "| $CMTK/reformatx -o $registered_pp_bgwarp_nrrd --floating $registered_pp_bg_nrrd $Tfile $registered_pp_warp_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/reformatx -o $registered_pp_bgwarp_nrrd --floating $registered_pp_bg_nrrd $Tfile $registered_pp_warp_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_bgwarp_nrrd ]
then
echo -e "Error: CMTK reformatting failed"
exit -1
fi
echo "cmtk_reformatting start: $START"
echo "cmtk_reformatting stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation cmtk_reformatting -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/reformatx" -version '2.2.6' -parm alignment_target="$Tfile"
# QC
echo "+----------------------------------------------------------------------+"
echo "| Running QC                                                           |"
echo "| $PYTHON $QUAL $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual |"
echo "| $PYTHON $QUAL2 $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$PYTHON $QUAL $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual
$PYTHON $QUAL2 $registered_pp_bgwarp_nrrd $Tfile $registered_pp_warp_qual
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_warp_qual ]
then
echo -e "Error: quality check failed"
exit -1
fi
echo "alignment_qc start: $START"
echo "alignment_qc stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
# -------------------------------------------------------------------------------------------                                                                                                                                                   
# CMTK reformatting
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK reformatting                                            |"
echo "| $CMTK/reformatx -o $registered_pp_sgwarp1_nrrd --floating $registered_pp_sg1_nrrd $Tfile $registered_pp_warp_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/reformatx -o $registered_pp_sgwarp1_nrrd --floating $registered_pp_sg1_nrrd $Tfile $registered_pp_warp_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_sgwarp1_nrrd ]
then
echo -e "Error: CMTK reformatting sg1 failed"
exit -1
fi
echo "cmtk_reformatting start: $START"
echo "cmtk_reformatting stop: $STOP"

if [ -e $registered_pp_sg2_nrrd ]
then
#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
# -------------------------------------------------------------------------------------------                                                                                                                                                   
# CMTK reformatting
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK reformatting                                            |"
echo "| $CMTK/reformatx -o $registered_pp_sgwarp2_nrrd --floating $registered_pp_sg2_nrrd $Tfile $registered_pp_warp_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/reformatx -o $registered_pp_sgwarp2_nrrd --floating $registered_pp_sg2_nrrd $Tfile $registered_pp_warp_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_sgwarp2_nrrd ]
then
echo -e "Error: CMTK reformatting sg2 failed"
exit -1
fi
echo "cmtk_reformatting start: $START"
echo "cmtk_reformatting stop: $STOP"
fi

if [ -e $registered_pp_sg3_nrrd ]
then
#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
# -------------------------------------------------------------------------------------------                                                                                                                                                   
# CMTK reformatting
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK reformatting                                            |"
echo "| $CMTK/reformatx -o $registered_pp_sgwarp3_nrrd --floating $registered_pp_sg3_nrrd $Tfile $registered_pp_warp_xform |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/reformatx -o $registered_pp_sgwarp3_nrrd --floating $registered_pp_sg3_nrrd $Tfile $registered_pp_warp_xform
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_sgwarp3_nrrd ]
then
echo -e "Error: CMTK reformatting3 failed"
exit -1
fi
echo "cmtk_reformatting start: $START"
echo "cmtk_reformatting stop: $STOP"
fi

if [ $UNALIGNED_NEUSEP_EXISTS == 1 ]
then
#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
# -------------------------------------------------------------------------------------------
# CMTK reformatting for neuron separator result

#Neuron_Separator_ResultNRRD=${OUTPUT}"/ConsolidatedLabel.nrrd"
#if [ -e $Neuron_Separator_ResultNRRD ]
#then
#echo "+----------------------------------------------------------------------+"
#echo "| Running CMTK reformatting for Neuron separator result                |"
#echo "| $CMTK/reformatx --nn -o $Reformatted_Separator_result_nrrd --floating $Neuron_Separator_ResultNRRD $Tfile $registered_pp_warp_xform |"
#echo "+----------------------------------------------------------------------+"
#START=`date '+%F %T'`

#Reformatted_Separator_result_nrrd=${OUTPUT}"/Reformatted_Separator_Result.nrrd"

#$CMTK/reformatx --nn -o $Reformatted_Separator_result_nrrd --floating $Neuron_Separator_ResultNRRD $Tfile $registered_pp_warp_xform
#STOP=`date '+%F %T'`
#echo "neuron_reformatting start: $START"
#echo "neuron_reformatting stop: $STOP"
#if [ ! -e $Reformatted_Separator_result_nrrd ]
#then
#echo -e "Error: CMTK reformatting Neuron separation failed"
#exit -1
#fi
#echo "+----------------------------------------------------------------------+"
#echo "| Running nrrd -> v3draw conversion                                    |"
#echo "| $FIJI -macro $NRRD2V3DRAW_NS ${OUTPUT}"/" |"
#echo "+----------------------------------------------------------------------+"
#START=`date '+%F %T'`
#$FIJI -macro $NRRD2V3DRAW_NS ${OUTPUT}"/"
#STOP=`date '+%F %T'`
#if [ ! -e $Aligned_Consolidated_Label_V3DPBD ]
#then
#echo -e "Error: nrrd -> v3draw conversion of Neuron separator failed"
#exit -1
#fi
#echo "neuron_conversion start: $START"
#echo "neuron_conversion stop: $STOP"

#fi
#fi


#/usr/local/pipeline/bin/add_operation -operation cmtk_reformatting -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/reformatx" -version '2.2.6' -parm alignment_target="$Tfile"
# NRRD conversion
echo "+----------------------------------------------------------------------+"
echo "| Running NRRD -> v3draw conversion                                    |"
echo "| $FIJI -macro $NRRDCONV $registered_pp_warp_v3draw                    |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$FIJI -macro $NRRDCONV $registered_pp_warp_v3draw
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_warp_v3draw ]
then
echo -e "Error: NRRD -> raw conversion failed"
exit -1
fi
echo "nrrd_raw_conversion start: $START"
echo "nrrd_raw_conversion stop: $STOP"
#/usr/local/pipeline/bin/add_operation -operation nrrd_raw_conversion -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$FIJI" -version '1.47q' -parm imagej_macro="$NRRDCONV"
sleep 2

# Z projection
echo "+----------------------------------------------------------------------+"
echo "| Running Z projection                                                 |"
echo "| $FIJI -macro $ZPROJECT "$registered_pp_warp_v3draw $RGB $registered_pp_warp_qual_temp" |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
awk -F"," '{print $3}' $registered_pp_warp_qual | head -1 | sed 's/^  *//' >$registered_pp_warp_qual_temp
awk -F"," '{print $1 $2}' $registered_pp_warp_qual >>$registered_pp_warp_qual_temp
$FIJI -macro $ZPROJECT "$registered_pp_warp_v3draw $RGB $registered_pp_warp_qual_temp"
#/bin/rm -f $registered_pp_warp_qual_temp
STOP=`date '+%F %T'`
echo "z_projection start: $START"
echo "z_projection stop: $STOP"

# -------------------------------------------------------------------------------------------                                                                                                                                                           
echo "+--------------------------------------------------------------------------------------------------------+"
echo "| Running Otsuna scoring step                                                                            |"
echo "| $FIJI -macro $POSTSCORE \"$registered_pp_bgwarp_nrrd,PostScore,$OUTPUT/,$Tfile,$POSTSCOREMASK,$GENDER\"|"
echo "+--------------------------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
$FIJI -macro $POSTSCORE "$registered_pp_bgwarp_nrrd,PostScore,$OUTPUT/,$Tfile,$POSTSCOREMASK,$GENDER"
STOP=`date '+%F %T'`
if [ ! -e $registered_otsuna_qual ]
then
echo -e "Error: Otsuna ObjPearsonCoeff score failed"
exit -1
fi
echo "Otsuna_scoring start: $START"
echo "Otsuna_scoring stop: $STOP"

# -------------------------------------------------------------------------------------------                                                                 
# raw to v3draw                                                                                                                                               
#echo "+----------------------------------------------------------------------+"                                                                              
#echo "| Running raw -> v3draw conversion                                     |"                                                                              
#echo "| $Vaa3D -cmd image-loader -convert $registered_pp_warp_raw $registered_pp_warp_v3draw |"                                                              
#echo "+----------------------------------------------------------------------+"                                                                            
#$Vaa3D -cmd image-loader -convert $registered_pp_warp_raw $registered_pp_warp_v3draw                                                     

# -------------------------------------------------------------------------------------------                                                                                                                                                                                                    
if [ ! -e $registered_pp_warp_v3draw ]
then
echo -e "Error: Final v3draw conversion failed"
exit -1
fi
echo "+----------------------------------------------------------------------+"
echo "| Copying file to final destination                                    |"
echo "| cp -R $OUTPUT/* $FINALOUTPUT/.                                       |"
echo "+----------------------------------------------------------------------+"
cp -R $OUTPUT/* $FINALOUTPUT/.

if [[ -f "$registered_pp_warp_v3draw" ]]; then
OVERLAP_COEFF=`grep Overlap $registered_pp_warp_qual | awk -F"," '{print $1}'`
PEARSON_COEFF=`grep Pearson $registered_pp_warp_qual | awk -F"," '{print $1}'`

# Check for Hideo score file
OTSUNA_PEARSON_COEFF=`cat $registered_otsuna_qual | awk '{print $1}'`

META=${FINALOUTPUT}"/AlignedFlyJFRC2010.properties"
echo "alignment.stack.filename="${registered_pp_warp_v3draw_filename} >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
if [[ $GENDER =~ "m" ]]
then
# male fly brain
echo "alignment.space.name=MaleJFRC20102016_20x" >> $META
else
# female fly brain
echo "alignment.space.name=FemaleJFRC2010Symmetric2017_20x" >> $META
fi
echo "alignment.otsuna.object.pearson.coefficient=$OTSUNA_PEARSON_COEFF" >> $META
echo "alignment.overlap.coefficient=$OVERLAP_COEFF" >> $META
echo "alignment.object.pearson.coefficient=$PEARSON_COEFF" >> $META
echo "alignment.resolution.voxels=0.52x0.52x1.00" >> $META
echo "alignment.image.size=512x1024x185" >> $META
echo "alignment.objective=20x" >> $META
if [ -e $Aligned_Consolidated_Label_V3DPBD ]
then
	echo "neuron.masks.filename=$CONSLABEL_FN" >> $META
	else
	echo "WARNING: No $CONSLABEL_FN produced.  Not picked up by warped-result alignment step."
	fi
	echo "default=true" >> $META
	fi
	
	# Cleanup
	# tar -zcf $registered_pp_warp_xform.tar.gz $registered_pp_warp_xform                                                                                                                                                                                
	#x/bin/rm -rf $lsmname*-PP-*.xform $lsmname*-PP.raw $lsmname*.nrrd                                                                                                                                                                                    
	#x/bin/rm -rf *-PP-*.xform *-PP.raw $registered_pp_sgwarp_nrrd $registered_pp_sg_nrrd $registered_pp_bgwarp_nrrd
	
	# Check whether a temp file needs to be deleted.
	if [ -e $UNSR_TO_DEL ]
	then
	rm -rf $UNSR_TO_DEL
	fi
	echo "Job completed at "`date`
	#xtrap "rm -f $0" 