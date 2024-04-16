#!/bin/bash

# Step 4: Geocoding reference

workdir="$1"
ref_date="$2"
polar="$3"
dem_name="$4"

cd ${workdir}
if [ -e "DEM" ];then rm -r DEM; fi
mkdir -p "DEM"
cd DEM

cd ${workdir}/input_files
# ref_dir=`cat fileIDs | head -n 1 | tail -n 1`

cp ${workdir}/input_files/${ref_date}.mli ${workdir}/DEM/
cp ${workdir}/input_files/${ref_date}.mli.par ${workdir}/DEM/

cd ${workdir}/DEM

dem="${workdir}/DEM_prep/${dem_name}.dem"
dem_par="${workdir}/DEM_prep/${dem_name}.dem_par"

# set parameters
range_samples=`cat ${ref_date}.mli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
azimuth_lines=`cat ${ref_date}.mli.par | grep "azimuth_lines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
range_pixel_spacing=`cat ${ref_date}.mli.par | grep "range_pixel_spacing"   | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`
azimuth_pixel_spacing=`cat ${ref_date}.mli.par | grep "azimuth_pixel_spacing" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

# We want to do the geocoding to a spatial sampling of about 30m. 
# So in latitude direction, the sampling is appropriate, while in longitude direction, 
# we apply a resampling factor of 0.75 to get a similar sampling (in meters on the ground).

# calculate geocoding lookup table using gc_map
# if [ -e EQA.dem_par ];then rm EQA.dem_par; fi #  (to assure that the output DEM parameter file does not exist)
# dem_trans $dem_par $dem EQA.dem_par EQA.dem 1.0 0.75 0 1

# calculate geocoding look-up table, layover-shadow maps and incidence angle map
gc_map2 ${ref_date}.mli.par $dem_par $dem EQA.dem_par EQA.dem ${ref_date}.lt 1 1 ${ref_date}.ls_map ${ref_date}.ls_map_rdc ${ref_date}.inc - - ${ref_date}.sim_sar - - - - - - 0 -

width=`cat EQA.dem_par | grep "width" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
nlines=`cat EQA.dem_par | grep "nlines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`

# do refinement of lookup table using a simulated backscatter image calculated using pixel_area program
pixel_area ${ref_date}.mli.par EQA.dem_par EQA.dem ${ref_date}.lt ${ref_date}.ls_map ${ref_date}.inc ${ref_date}.pix_sigma0 ${ref_date}.pix_gamma0 20
raspwr ${ref_date}.pix_gamma0 $range_samples - - - - - - - ${ref_date}.pix_gamma0.bmp

# --> many areas are in radar shadow (0 values), this could be an issue for the offset calculation
# --> replace 0 values by 1 (~30 dB lower than flat surfaces)
replace_values ${ref_date}.pix_gamma0 0.0 1.0 ${ref_date}.pix_gamma0_filled $range_samples 0 2 1

# determine geocoding refinement using offset_pwrm
create_diff_par ${ref_date}.mli.par - ${ref_date}.diff_par 1 0
offset_pwrm ${ref_date}.pix_sigma0 ${ref_date}.mli ${ref_date}.diff_par ${ref_date}.offs ${ref_date}.ccp 128 128 ${ref_date}.offsets 1 64 64 0.1
offset_fitm ${ref_date}.offs ${ref_date}.ccp ${ref_date}.diff_par ${ref_date}.coffs ${ref_date}.coffsets 0.1 1 > ${ref_date}.off.out

grep final ${ref_date}.off.out

# refine geocoding lookup table
gc_map_fine ${ref_date}.lt ${width} ${ref_date}.diff_par ${ref_date}.lt_fine 1

# apply again pixel_area using the refined lookup table to assure that the
# simulated image uses the refined geometry
pixel_area ${ref_date}.mli.par EQA.dem_par EQA.dem ${ref_date}.lt_fine ${ref_date}.ls_map ${ref_date}.inc - ${ref_date}.pix_gamma0_fine
raspwr ${ref_date}.pix_gamma0_fine $range_samples - - - - - - - ${ref_date}.pix_gamma0_fine.bmp

# resample the MLI data from the slant range to the map geometry and visualize it
geocode_back ${ref_date}.mli $range_samples ${ref_date}.lt_fine EQA.${ref_date}.mli $width $nlines 5 0 - - 3
# raspwr EQA.${ref_date}.mli $width - - - - - - - EQA.${ref_date}.mli.bmp
ras_dB EQA.${ref_date}.mli $width 1 0 1 1 -32. 3.5 gray.cm EQA.${ref_date}.mli.bmp 0 1

ras2png.py EQA.${ref_date}.mli.bmp -t
kml_map EQA.${ref_date}.mli.png EQA.dem_par EQA.${ref_date}.mli.kml

# resample the DEM heights to the slant range MLI geometry
geocode ${ref_date}.lt_fine EQA.dem ${width} ${ref_date}.hgt ${range_samples} ${azimuth_lines} 2 0
rasdt_pwr ${ref_date}.hgt ${ref_date}.mli $range_samples 1 $azimuth_lines 1 1 - - 2 terrain.cm ${ref_date}.hgt.bmp 1. .35 24
