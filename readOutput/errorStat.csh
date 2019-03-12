#!/bin/csh
ncl compute_error_statistics.ncl ind_aM=0 'varname="theta"' nz=40
ncl compute_error_statistics.ncl ind_aM=1 'varname="theta"' nz=40
ncl compute_error_statistics.ncl ind_aM=2 'varname="theta"' nz=40
ncl compute_error_statistics.ncl ind_aM=3 'varname="theta"' nz=40

ncl compute_error_statistics.ncl ind_aM=0 'varname="qvx_cos"' nz=40
ncl compute_error_statistics.ncl ind_aM=1 'varname="qvx_cos"' nz=40
ncl compute_error_statistics.ncl ind_aM=2 'varname="qvx_cos"' nz=40
ncl compute_error_statistics.ncl ind_aM=3 'varname="qvx_cos"' nz=40

ncl compute_error_statistics.ncl ind_aM=0 'varname="tso_clm"' nz=10
ncl compute_error_statistics.ncl ind_aM=1 'varname="tso_clm"' nz=10
ncl compute_error_statistics.ncl ind_aM=2 'varname="tso_clm"' nz=10
ncl compute_error_statistics.ncl ind_aM=3 'varname="tso_clm"' nz=10

ncl compute_error_statistics.ncl ind_aM=0 'varname="swx_pfl"' nz=10
ncl compute_error_statistics.ncl ind_aM=1 'varname="swx_pfl"' nz=10
ncl compute_error_statistics.ncl ind_aM=2 'varname="swx_pfl"' nz=10
ncl compute_error_statistics.ncl ind_aM=3 'varname="swx_pfl"' nz=10

mkdir nc_stat_data 
mv *.nc nc_stat_data
mv nc_stat_data ../
exit 0
