#!/bin/bash 

# Prep: If you download from G-Portal, please make zip files with the name of ALOS2XXXXXXXX-YYMMDD 
# process setting           # please input ALOS-2 ScanSAR zip files and DEM(tif) into "input_files_orig"
part01_read="off"           # Step 1: Read in the original data
part02_makeslc="off"        # Step 2: Generation of SLC mosaic and MLI mosaic
part03_preparedem="off"      # Step 3: Prepare DEM *If you use not enough DEM tif file, you can check the SLC_corners.txt
part04_geocoding="off"      # Step 4: Geocoding reference MLI
part05_coreg="off"          # Step 5: Co-registration 
part06_interp="off"          # Step 6: Calculate the initial interferogram
part07_diff="off"           # Step 7: Calculate the differential interferogram
part08_filter="off"          # Step 8: filtering using adf and high-path
part09_unw="off"            # Step 9: unwrap
part10_ortho="off"          # Step 10: ortho
part11_demaux="off"          # Step 11: Create ls_map or other dem aux files
# part12_ionospherechk="off"

#* tool and directory setting
workdir="/mnt/disks/sdb/XXX/insar_scansar_alos2"
python="${workdir}/python"
shell="${workdir}/sh"
gamma_mod="${workdir}/gamma_mod"
# config="${gamma_mod}/makeslc.conf" # configuration file (please select satellite type)
dem_tiff="${workdir}/input_files_orig/COP30.tif" # "-" for automated DEM: SRTM 30m

#* Parameter Setting
ref_date="20161018" # registration master date
polar="HH" # target polarization (HH, HV, VV, VH)
sw_start_num="4" # first subswath to import (numbering from near to far range, start with 1)
swn_number="2" # number of subswaths to import (default: to last subswath)
dem_name="COP30_NZ"
rglks="3" # range look number for interferometry
azlks="15" # azimuth look number for interferometry
wavelength="3000" # hp_filter wavelength cutoff (if 0 is set, No hp filter)
adf_nfft="32" # filtering FFT window size, 2**N, 8 --> 512 (used by adf)
unw_method="MCF" # methods for unwrap (MCF or BC)
range_ref="1120" # phase reference point (used by mcf)
azimuth_ref="2517" # phase reference point (used by mcf)
cc_thres="0.3" # coherence threshold for masking (used by rascc_mask)
calfactor="0" # calibration factor

if [ "${part01_read}" = "on" ];then bash ${shell}/part01_read.sh ${workdir} ${ref_date} ${polar} ${sw_start_num} ${swn_number}; fi
if [ "${part02_makeslc}" = "on" ];then bash ${shell}/part02_makeslc.sh ${workdir} ${ref_date} ${polar} ${rglks} ${azlks}; fi
if [ "${part03_preparedem}" = "on" ];then bash ${shell}/part03_preparedem.sh ${workdir} ${ref_date} ${polar} ${rglks} ${azlks} ${dem_name} ${dem_tiff}; fi
if [ "${part04_geocoding}" = "on" ];then bash ${shell}/part04_geocoding.sh ${workdir} ${ref_date} ${polar} ${dem_name}; fi
if [ "${part05_coreg}" = "on" ];then bash ${shell}/part05_coreg.sh ${workdir} ${ref_date} ${polar} ${rglks} ${azlks}; fi
if [ "${part06_interp}" = "on" ];then bash ${shell}/part06_interp.sh ${workdir} ${rglks} ${azlks}; fi
if [ "${part07_diff}" = "on" ];then bash ${shell}/part07_diff.sh ${workdir} ${ref_date} ${rglks} ${azlks}; fi
if [ "${part08_filter}" = "on" ];then bash ${shell}/part08_filter.sh ${workdir} ${wavelength} ${adf_nfft} ${python}; fi
if [ "${part09_unw}" = "on" ];then bash ${shell}/part09_unw.sh ${workdir} ${wavelength} ${adf_nfft} ${range_ref} ${azimuth_ref} ${cc_thres} ${unw_method}; fi
if [ "${part10_ortho}" = "on" ];then bash ${shell}/part10_ortho.sh ${workdir} ${python} ${ref_date} ${dem_name} ${wavelength} ${adf_nfft} ${calfactor}; fi
if [ "${part11_demaux}" = "on" ];then bash ${shell}/part11_demaux.sh ${workdir} ${ref_date} ${python}; fi
# if [ "${part12_ionospherechk}" = "on" ];then bash ${shell}/part12_ionospherechk.sh ${workdir} ${ref_date}; fi 

