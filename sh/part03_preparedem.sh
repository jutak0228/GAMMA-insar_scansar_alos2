#!/bin/bash

# Step 3: Prepare DEM using Copernicus DEM

workdir="$1"
ref_date="$2"
polar="$3"
rglks="$4"
azlks="$5"
dem_name="$6"
dem_tiff="$7"

cd ${workdir}
if [ -e DEM_prep ];then rm -r DEM_prep; fi
mkdir -p DEM_prep

cd ${workdir}/input_files
# ref_dir=`cat fileIDs | head -n 1 | tail -n 1`
# cd ${workdir}/${ref_dir}

cp ${ref_date}.slc ${workdir}/DEM_prep/
cp ${ref_date}.slc.par ${workdir}/DEM_prep/

cd ${workdir}/DEM_prep

# estimate corber latitude and longitude
if [ -e SLC_corners.txt ]; then rm -f SLC_corners.txt; fi
SLC_corners ${ref_date}.slc.par > SLC_corners.txt

# setting variable for clipping dem data
# -->
# lower left  corner longitude, latitude (deg.): 139.06  35.15
# upper right corner longitude, latitude (deg.): 140.29  36.06

rm -f ${ref_date}.slc ${ref_date}.slc.par

lowleft_lat=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $8}' | tr -d [:space:]`
lowleft_lon=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $7}' | tr -d [:space:]`
uppright_lat=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $8}' | tr -d [:space:]`
uppright_lon=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $7}' | tr -d [:space:]`

# generate dem file: SRTM (auto) or other manually downloaded dem files
if [ ${dem_tiff} = "-" ]; then
    # download filled SRTM1 using elevation module
    eio clip -o ${workdir}/DEM_prep/SRTM.tif --bounds $lowleft_lon $lowleft_lat $uppright_lon $uppright_lat
    # DEM definition with manual processing
    dem="${workdir}/DEM_prep/SRTM.tif"
elif [ ${dem_tiff} != "-" ]; then
    dem="${dem_tiff}"
fi

# convert the GeoTIFF DEM into Gamma Software format, including geoid to ellipsoid height reference conversion
dem_import ${dem} ${dem_name}.dem ${dem_name}.dem_par 0 1 $DIFF_HOME/scripts/egm2008-5.dem $DIFF_HOME/scripts/egm2008-5.dem_par 0 - - 1
