#!/bin/csh

# varname :theta qvx_cos tso_clm swx_pfl
ncl compute_error_statistics.ncl ind_aM=0 nz=40 'varname="theta"'
ncl compute_error_statistics.ncl ind_aM=1 nz=40 'varname="theta"'
ncl compute_error_statistics.ncl ind_aM=2 nz=40 'varname="theta"'
ncl compute_error_statistics.ncl ind_aM=3 nz=40 'varname="theta"'

#
ncl compute_error_statistics.ncl ind_aM=0 nz=40 'varname="qvx_cos"'
ncl compute_error_statistics.ncl ind_aM=1 nz=40 'varname="qvx_cos"'
ncl compute_error_statistics.ncl ind_aM=2 nz=40 'varname="qvx_cos"'
ncl compute_error_statistics.ncl ind_aM=3 nz=40 'varname="qvx_cos"'

#
ncl compute_error_statistics.ncl ind_aM=0 nz=10 'varname="tso_clm"'
ncl compute_error_statistics.ncl ind_aM=1 nz=10 'varname="tso_clm"'
ncl compute_error_statistics.ncl ind_aM=2 nz=10 'varname="tso_clm"'
ncl compute_error_statistics.ncl ind_aM=3 nz=10 'varname="tso_clm"'

#
ncl compute_error_statistics.ncl ind_aM=0 nz=10 'varname="swx_pfl"'
ncl compute_error_statistics.ncl ind_aM=1 nz=10 'varname="swx_pfl"'
ncl compute_error_statistics.ncl ind_aM=2 nz=10 'varname="swx_pfl"'
ncl compute_error_statistics.ncl ind_aM=3 nz=10 'varname="swx_pfl"'
