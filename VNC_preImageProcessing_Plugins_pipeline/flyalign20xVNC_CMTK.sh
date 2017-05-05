#!/bin/bash
# Program locations: (assumes running this in vnc_align script directory)
#
# 20x fly vnc alignment pipeline using CMTK, version 1.0, June 6, 2013
#

################################################################################
#
# The pipeline is developed for aligning 20x fly vnc using CMTK
# The standard brain's resolution (0.62x0.62x0.62 um)
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
LATTIF=$DIR/VNC_Lateral_F.tif

SUBVNC=$INPUT1_FILE
SUBREF=$INPUT1_REF
CONSLABEL=$INPUT1_NEURONS
CHN=$INPUT1_CHANNELS
GENDER=$GENDER

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
VNCScripts=`readItemFromConf $CONFIGFILE "VNCScripts"`
# add CMTK tools here

Vaa3D=${TOOLDIR}"/"${Vaa3D}
JBA=${TOOLDIR}"/"${JBA}
ANTS=${TOOLDIR}"/"${ANTS}
WARP=${TOOLDIR}"/"${WARP}
CMTK=${TOOLDIR}"/"${CMTK}
FIJI=${TOOLDIR}"/"${FIJI}
VNCScripts=${TOOLDIR}"/"${VNCScripts}"/"


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
VNCTEMPLATEFEMALE=`readItemFromConf $CONFIGFILE "tgtVNC20xAFemale"`
VNCTEMPLATEMALE=`readItemFromConf $CONFIGFILE "tgtVNC20xAMale"`

TAR=${TMPLDIR}"/"${TAR}
ATLAS=${TMPLDIR}"/"${ATLAS}
TARMARKER=${TMPLDIR}"/"${TARMARKER}
LCRMASK=${TMPLDIR}"/"${LCRMASK}
CMPBND=${TMPLDIR}"/"${CMPBND}

if [[ $GENDER =~ "m" ]]
then
# male fly vnc
Tfile=${TMPLDIR}"/"${VNCTEMPLATEMALE}
POSTSCOREMASK=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/For_Score/Mask_Male_VNC.nrrd"
else
# female fly vnc
Tfile=${TMPLDIR}"/"${VNCTEMPLATEFEMALE}
POSTSCOREMASK=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/For_Score/flyVNCtemplate20xA_CLAHE_MASK2nd.nrrd"
fi

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TMPLDIR: $TMPLDIR"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUBVNC: $SUBVNC"
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
echo "VNCScripts: $VNCScripts"
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

PREPROCIMG=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/VNC_preImageProcessing_Pipeline_02_02_2017.ijm"
POSTSCORE=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/For_Score/Score_For_VNC_pipeline.ijm"
RAWCONV=$VNCScripts"raw2nrrd.ijm"
#NRRDCONV=$VNCScripts"nrrd2raw.ijm"
NRRDCONV=$VNCScripts"nrrd2v3draw_MCFO.ijm" 
ZPROJECT=$VNCScripts"z_project.ijm"
PYTHON='/misc/local/python-2.7.3/bin/python'
PREPROC=$VNCScripts"PreProcess.py"
QUAL=$VNCScripts"OverlapCoeff.py"
QUAL2=$VNCScripts"ObjPearsonCoeff.py"
LSMR=$VNCScripts"lsm2nrrdR.ijm"

echo "Job started at" `date` "on" `hostname`
SAGE_IMAGE="$grammar{sage_image}"
echo "$sage_image"

# Shepherd VNC alignment
#preproc_result=$OUTPUT"/preprocResult.nrrd"
#unregistered_raw=$OUTPUT"/unregVNC.v3draw"
#registered_pp_raw=$OUTPUT"/VNC-PP.raw"
#registered_pp_c1_nrrd=$OUTPUT"/VNC-PP_C1.nrrd"
#registered_pp_c2_nrrd=$OUTPUT"/VNC-PP_C2.nrrd"

registered_pp_sg1_nrrd=$OUTPUT"/preprocResult_02.nrrd"
registered_pp_sg2_nrrd=$OUTPUT"/preprocResult_03.nrrd"
registered_pp_sg3_nrrd=$OUTPUT"/preprocResult_04.nrrd"

# Hideo output always sets reference as the first channel exported.
registered_pp_bg_nrrd=$OUTPUT"/preprocResult_01.nrrd"
registered_pp_initial_xform=$OUTPUT"/VNC-PP-initial.xform"
registered_pp_affine_xform=$OUTPUT"/VNC-PP-affine.xform"
registered_pp_warp_xform=$OUTPUT"/VNC-PP-warp.xform"
registered_pp_bgwarp_nrrd=$OUTPUT"/VNC-PP-BGwarp.nrrd"
registered_pp_warp_qual=$OUTPUT"/VNC-PP-warp_qual.csv"
registered_pp_warp_qual_temp=$OUTPUT"/VNC-PP-warp_qual.tmp"
registered_pp_sgwarp1_nrrd=$OUTPUT"/VNC-PP-SGwarp1.nrrd"
registered_pp_sgwarp2_nrrd=$OUTPUT"/VNC-PP-SGwarp2.nrrd"
registered_pp_sgwarp3_nrrd=$OUTPUT"/VNC-PP-SGwarp3.nrrd"


registered_pp_warp_png=$OUTPUT"/VNC-PP-warp.png"
#registered_pp_warp_raw=$OUTPUT"/VNC-PP-warp.raw"
registered_pp_warp_v3draw_filename="AlignedFlyVNC.v3draw"
registered_pp_warp_v3draw=$OUTPUT"/"${registered_pp_warp_v3draw_filename}
registered_otsuna_qual=$OUTPUT"/Hideo_OBJPearsonCoeff.txt"

# Neuron separation definitions. Expecting consolidated label to be sibling of signal.
Unaligned_Neuron_Separator_Dir=$(dirname "${CONSLABEL}")"/"
Unaligned_Neuron_Separator_Result_V3DPBD=${Unaligned_Neuron_Separator_Dir}"ConsolidatedLabel.v3dpbd"
Unaligned_Neuron_Separator_Result_RAW=${Unaligned_Neuron_Separator_Dir}"ConsolidatedLabel.v3draw"
V3DPBD2NRRD=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/v3dpbd2nrrd.ijm"
Reformatted_Separator_result_v3draw=$OUTPUT"/Reformatted_Separator_Result.v3draw"
NRRD2V3DRAW_NS=$VNCScripts"VNC_preImageProcessing_Plugins_pipeline/nrrd2v3draw_N_separator_result.ijm"
PREALIGNEDVNC=${OUTPUT}"/PreAlignedVNC.v3draw"

# Make sure the .lsm file exists
if [ -e $SUBVNC ]
then
   echo "Input file exists: "$SUBVNC
else
  echo -e "Error: image $SUBVNC does not exist"
  exit -1
fi

# Ensure existence of required inputs from unaligned neuron separation.
UNSR_TO_DEL="sentinel_nonexistent_file"
if [ ! -e $Unaligned_Neuron_Separator_Result_RAW ]
then
  if [ -e $Unaligned_Neuron_Separator_Result_V3DPBD ]
  then
    # Now I need to translate to raw version.
    $Vaa3D -cmd image-loader -convert $Unaligned_Neuron_Separator_Result_V3DPBD $Unaligned_Neuron_Separator_Result_RAW
    UNSR_TO_DEL=$Unaligned_Neuron_Separator_Result_RAW
  else
    echo -e "Error: neither unaligned neuron separation result $Unaligned_Neuron_Separator_Result_V3DPBD nor $Unaligned_Neuron_Separator_Result_RAW exists."
    exit -1
  fi
fi

STARTDIR=`pwd`
cd $OUTPUT
# -------------------------------------------------------------------------------------------
echo "+---------------------------------------------------------------------------------------+"
echo "| Running Otsuna preprocessing step                                                     |"
echo "| $FIJI -macro $PREPROCIMG \"$OUTPUT/,preprocResult,$LATTIF,$SUBVNC,ssr,$RESX,$RESY,$GENDER,$Unaligned_Neuron_Separator_Result_V3DPBD\" |"
echo "+---------------------------------------------------------------------------------------+"
START=`date '+%F %T'`
# Expect to take far less than 1 hour
timeout --preserve-status 60m $FIJI -macro $PREPROCIMG "$OUTPUT/,preprocResult,$LATTIF,$SUBVNC,ssr,$RESX,$RESY,$GENDER,$Unaligned_Neuron_Separator_Result_V3DPBD"
STOP=`date '+%F %T'`
# -------------------------------------------------------------------------------------------
# NRRD conversion
#echo "+--------------------------------------------------------------------------------------+"
#echo "| Running raw -> NRRD conversion                                                       |"
#echo "| xvfb-run --auto-servernum --server-num=200 $FIJI -macro $LSMR $preproc_result -batch |"
#echo "+--------------------------------------------------------------------------------------+"
#START=`date '+%F %T'`
#xvfb-run --auto-servernum --server-num=200 $FIJI -macro $LSMR $preproc_result -batch
#STOP=`date '+%F %T'`
if [ ! -e $registered_pp_bg_nrrd ]
then
  echo -e "Error: Otsuna preprocessing step failed"
  exit -1
fi
#/usr/local/pipeline/bin/add_operation -operation raw_nrrd_conversion -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$FIJI" -version '1.47q' -parm imagej_macro="$LSMR"
sleep 2

#  This is added mainly to make it obvious that this output file was supposed to have been created.
if [ ! -e $PREALIGNEDVNC ]
then
  echo -e "Error: pre aligned image VNC raw file "${PREALIGNEDVNC}" not created."
  exit -1
fi

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

# Pre-processing
#echo "+----------------------------------------------------------------------+"
#echo "| Running pre-processing                                               |"
#echo "| $PYTHON $PREPROC $registered_pp_c1_nrrd $registered_pp_c2_nrrd C 10  |"
#echo "+----------------------------------------------------------------------+"
#START=`date '+%F %T'`
#$PYTHON $PREPROC $registered_pp_c1_nrrd $registered_pp_c2_nrrd C 10
#STOP=`date '+%F %T'`
#RGB='GRB'
#echo "MIP order: $RGB"
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
#/usr/local/pipeline/bin/add_operation -operation cmtk_initial_affine -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$CMTK/make_initial_affine" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK registration
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK registration                                            |"
echo "| $CMTK/registration --initial $registered_pp_initial_xform --dofs 6,9 --auto-multi-levels 4 -o $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/registration --initial $registered_pp_initial_xform --dofs 6,9 --auto-multi-levels 4 -o $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_affine_xform ]
then
  echo -e "Error: CMTK registration failed"
  exit -1
fi
#/usr/local/pipeline/bin/add_operation -operation cmtk_registration -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" - operator $USERID -program "$CMTK/registration" -version '2.2.6' -parm alignment_target="$Tfile"
# CMTK warping
echo "+----------------------------------------------------------------------+"
echo "| Running CMTK warping                                                 |"
echo "| $CMTK/warp -o $registered_pp_warp_xform --grid-spacing 80 --exploration 30 --coarsest 4 --accuracy 0.2 --refine 4 --energy-weight 1e-1 --initial $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd |"
echo "+----------------------------------------------------------------------+"
START=`date '+%F %T'`
$CMTK/warp -o $registered_pp_warp_xform --grid-spacing 80 --exploration 30 --coarsest 4 --accuracy 0.2 --refine 4 --energy-weight 1e-1 --initial $registered_pp_affine_xform $Tfile $registered_pp_bg_nrrd
STOP=`date '+%F %T'`
if [ ! -e $registered_pp_warp_xform ]
then
  echo -e "Error: CMTK warping failed"
  exit -1
fi
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
fi

if [ -e $Unaligned_Neuron_Separator_Result_RAW || -e $Unaligned_Neuron_Separator_Result_V3DPBD ]
then
	#/usr/local/pipeline/bin/add_operation -operation alignment_qc -name "$SAGE_IMAGE" -start "$START" -stop "$STOP" -operator $USERID -program "$QUAL" -version '1.0' -parm alignment_target="$Tfile"
	# -------------------------------------------------------------------------------------------
	# CMTK reformatting for neuron separator result


	Neuron_Separator_ResultNRRD=${OUTPUT}"/ConsolidatedLabel.nrrd"
	if [ -e $Neuron_Separator_ResultNRRD ]
		then
		echo "+----------------------------------------------------------------------+"
		echo "| Running CMTK reformatting for Neuron separator result                |"
		echo "| $CMTK/reformatx --nn -o $Reformatted_Separator_result_nrrd --floating $Neuron_Separator_ResultNRRD $Tfile $registered_pp_warp_xform |"
		echo "+----------------------------------------------------------------------+"
		START=`date '+%F %T'`

		Reformatted_Separator_result_nrrd=${OUTPUT}"/Reformatted_Separator_Result.nrrd"

		$CMTK/reformatx --nn -o $Reformatted_Separator_result_nrrd --floating $Neuron_Separator_ResultNRRD $Tfile $registered_pp_warp_xform
		STOP=`date '+%F %T'`
		if [ ! -e $Reformatted_Separator_result_nrrd ]
			then
			echo -e "Error: CMTK reformatting Neuron separation failed"
			exit -1
		fi
		echo "+----------------------------------------------------------------------+"
		echo "| Running nrrd -> v3draw conversion                                    |"
		echo "| $FIJI -macro $NRRD2V3DRAW_NS $Reformatted_Separator_result_nrrd      |"
		echo "+----------------------------------------------------------------------+"
		START=`date '+%F %T'`
		$FIJI -macro $NRRD2V3DRAW_NS ${OUTPUT}"/"
		STOP=`date '+%F %T'`
		if [ ! -e $Reformatted_Separator_result_v3draw ]
			then
			echo -e "Error: nrrd -> v3draw conversion of Neuron separator failed"
			exit -1
		fi
	fi
fi



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

META=${FINALOUTPUT}"/AlignedFlyVNC.properties"
echo "alignment.stack.filename="${registered_pp_warp_v3draw_filename} >> $META
echo "alignment.image.channels=$INPUT1_CHANNELS" >> $META
echo "alignment.image.refchan=$INPUT1_REF" >> $META
if [[ $GENDER =~ "m" ]]
then
# male fly brain
echo "alignment.space.name=Male 20x VNC Alignment Space" >> $META
else
# female fly brain
echo "alignment.space.name=Female 20x VNC Alignment Space" >> $META
fi
echo "alignment.otsuna.object.pearson.coefficient=$OTSUNA_PEARSON_COEFF" >> $META
echo "alignment.overlap.coefficient=$OVERLAP_COEFF" >> $META
echo "alignment.object.pearson.coefficient=$PEARSON_COEFF" >> $META
echo "alignment.resolution.voxels=0.52x0.52x1.00" >> $META
echo "alignment.image.size=512x1024x185" >> $META
echo "alignment.objective=20x" >> $META
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
