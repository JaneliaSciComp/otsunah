// v3dpbd to nrrd
setBatchMode(true);
args = split(getArgument(),",");

InputDirSeparation=args[0];
InputDir=args[1];
print("InputDirSeparation; "+InputDirSeparation);
print("VNC_InputDir; "+InputDir);

open(InputDir+"preprocResult_01.nrrd");
getVoxelSize(VxWidth, VxHeight, VxDepth, VxUnit);
close();

open(InputDirSeparation+"ConsolidatedSignal.v3dpbd");
run("Properties...", "channels=1 slices="+nSlices+" frames=1 unit=microns pixel_width="+VxWidth+" pixel_height="+VxHeight+" voxel_depth="+VxDepth+"");

run("Nrrd Writer", "compressed nrrd="+InputDir+"ConsolidatedSignal.nrrd");
print("Done");
run("Quit");