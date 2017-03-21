// v3dpbd to nrrd

args = split(getArgument(),",");

InputDir=args[0];
InFileName=args[1];
Outputpath=args[3];


open(InputDir+"preprocResult_01.nrrd");
getVoxelSize(VxWidth, VxHeight, VxDepth, VxUnit);
close();

open(InputDir+InFileName);
run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+VxWidth+" pixel_height="+VxHeight+" voxel_depth="+VxDepth+"");

run("Nrrd Writer", "compressed nrrd="+Outputpath);

run("Quit");