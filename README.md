# GAMMA-insar_scansar_alos2

GAMMA RS script for Interferometric SAR analysis for ALOS-2 ScanSAR datasets

## Requirements

GAMMA Software Modules:

The GAMMA software is grouped into four main modules:
- Modular SAR Processor (MSP)
- Interferometry, Differential Interferometry and Geocoding (ISP/DIFF&GEO)
- Land Application Tools (LAT)
- Interferometric Point Target Analysis (IPTA)

The user need to install the GAMMA Remote Sensing software beforehand depending on your OS.

For more information: https://gamma-rs.ch/uploads/media/GAMMA_Software_information.pdf

## Process step

Pre-processing: if you download from G-Portal, please make zip files with the name of ALOS2XXXXXXXX-YYMMDD

Note: it should be processed orderly from the top (part_XX).

It needs to change the mark "off" to "on" when processing.
 
- process setting # please input ALOS-2 ScanSAR zip files and DEM(tif) into "input_files_orig"
- part01_read="off" # Step 1: Read in the original data
- part02_makeslc="off" # Step 2: Generation of SLC mosaic and MLI mosaic
- part03_preparedem="off" # Step 3: Prepare DEM *If you use not enough DEM tif file, you can check the SLC_corners.txt
- part04_geocoding="off" # Step 4: Geocoding reference MLI
- part05_coreg="off" # Step 5: Co-registration
- part06_interp="off" # Step 6: Calculate the initial interferogram
- part07_diff="off" # Step 7: Calculate the differential interferogram
- part08_filter="off" # Step 8: filtering using adf and high-path
- part09_unw="off" # Step 9: unwrap
- part10_ortho="off" # Step 10: ortho
- part11_demaux="off" # Step 11: Create ls_map or other dem aux files
