// v3dpbd to nrrd

args = split(getArgument(),",");

InputDir=args[0];
Outputpath=args[1];//ConsolidatedSignal.nrrd


open(InputDir+"preprocResult_01.nrrd");
getVoxelSize(VxWidth, VxHeight, VxDepth, VxUnit);
close();

open(InputDir+"ConsolidatedSignal.v3dpbd");
run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+VxWidth+" pixel_height="+VxHeight+" voxel_depth="+VxDepth+"");

run("Nrrd Writer", "compressed nrrd="+Outputpath);

run("Quit");