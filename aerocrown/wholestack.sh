#!/bin/bash

#set up directories
mkdir -p ./data/meters/ground
mkdir -p ./data/meters/highveg_and_ground
mkdir -p ./data/DSM
mkdir -p ./data/DTM
mkdir -p ./data/CHM

#transform .las files to meters because that's what pycrowne expects
wine /home/user/Aerotronic/LAStools/bin/las2las.exe -i ./data/raw_tiles/*.las -keep_class 2 -target_epsg 2809 -scale_z 0.3048 -odir ./data/meters/ground
wine /home/user/Aerotronic/LAStools/bin/las2las.exe -i ./data/raw_tiles/*.las -keep_class 2 -keep_class 5 -target_epsg 2809 -scale_z 0.3048 -odir ./data/meters/highveg_and_ground
#wine /home/user/Aerotronic/LAStools/bin/lasheight.exe -i ./data/*.las -keep_class 5 -replace_z -odir ./data/meters/highveg_normalized

#activate environment
echo Creating Canopy Height Model
eval "$(conda shell.bash hook)"
conda activate pdal-env

#create DSM from highveg_and_ground files
pdal pipeline ./gdal-DSM.json

#create DTM
pdal pipeline ./gdal-DTM.json

#fill any holes that may exist in the DTM
gdal_fillnodata.py -q -md 10 -b 1 -of GTiff ./data/DTM/DTM.tif ./data/DTM/DTM_filled.tif

#make sure the DSM has a smaller extent than the DTM
gdaltindex ./data/DTM/border.shp ./data/DTM/DTM_filled.tif
gdalwarp -cutline ./data/DTM/border.shp -crop_to_cutline ./data/DSM/DSM.tif ./data/DSM/DSM_clipped.tif

#Create new DSM and DTM that have perfect pairings of data and no-data locations for the raster calculator
gdal_calc.py --calc "logical_and(A,B) * A" --format GTiff --type Float32 --NoDataValue 0.0 -A ./data/DSM/DSM_clipped.tif --A_band 1 -B ./data/DTM/DTM_filled.tif --B_band 1 --outfile ./data/DSM/DSM_final.tif
gdal_calc.py --calc "logical_and(A,B) * B" --format GTiff --type Float32 --NoDataValue 0.0 -A ./data/DSM/DSM_clipped.tif --A_band 1 -B ./data/DTM/DTM_filled.tif --B_band 1 --outfile ./data/DTM/DTM_final.tif

#Calculate Canopy Height Model (CHM)
gdal_calc.py --calc "A - B" --format GTiff --type Float32 --NoDataValue 0.0 -A ./data/DSM/DSM_final.tif --A_band 1 -B ./data/DTM/DTM_final.tif --B_band 1 --outfile ./data/CHM/CHM.tif

#set geolocation (this is Michigan South METERS)
gdalwarp -q -t_srs EPSG:2809 ./data/CHM/CHM.tif ./data/CHM.tif
gdalwarp -q -t_srs EPSG:2809 ./data/DSM/DSM_final.tif ./data/DSM.tif
gdalwarp -q -t_srs EPSG:2809 ./data/DTM/DTM_final.tif ./data/DTM.tif


#cleanup files
#rm -r ./data/CHM
#rm -r ./data/DSM
#rm -r ./data/DTM 

echo Canopy Height Model Complete!

#deactivate environment
conda deactivate

#generate pycrown outputs from DEMs
echo Starting Aerocrown
eval "$(conda shell.bash hook)"
conda activate pycrown-env
python ./aerocrown.py

#cleanup
#rm -r ./data/meters
#rm ./data/CHM.tif
#rm ./data/DSM.tif
#rm ./data/DTM.tif


#add georeferencing info to new shapefile
ogr2ogr -s_srs EPSG:2809 -t_srs EPSG:2898 ./result/tile_001/tile_001_tree_crown.shp ./result/tree_crown_poly_raster.shp

#clean up old non-georeferenced files
rm /home/user/Aerotronic/pycrown/aerocrown/result/tree_crown_poly_raster.cpg
rm /home/user/Aerotronic/pycrown/aerocrown/result/tree_crown_poly_raster.dbf
rm /home/user/Aerotronic/pycrown/aerocrown/result/tree_crown_poly_raster.prj
rm /home/user/Aerotronic/pycrown/aerocrown/result/tree_crown_poly_raster.shp
rm /home/user/Aerotronic/pycrown/aerocrown/result/tree_crown_poly_raster.shx

conda deactivate
