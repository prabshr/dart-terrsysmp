; MSE and Spread/Error aggregated statistics
; Includes four functions
; toTHETAV, MAE, ens_spread, file_out 
; Prabhakar Shrestha

function toTHETAV(Tin,QVin,Pin)
begin
 ;Tin (K), QVin(kg/kg), Pin (Pa)
 ;convert T to virtual potential temperature
  p00 = 1.E5
  k   = 0.2854
  Tv  = Tin*(1. + 0.6*QVin)*(p00/Pin)^k
  return(Tv)
end ;toTHETAV
;;
function toTHETA(Tin,Pin)
begin
 ;Tin (K), Pin (Pa)
 ;convert T to potential temperature
  p00 = 1.E5
  k   = 0.2854
  Tv  = Tin*(p00/Pin)^k
  return(Tv)
end ;toTHETA

;;
function MAE(varM,varO)
;varM(ens,time,level)
;varO(time,level)
begin
  ndim = dimsizes(varM)
  nM   = ndim(0)
  nT   = ndim(1)
  nZ   = ndim(2)
  delete(ndim)
  ndim = dimsizes(varO)
  nZO  = ndim(1)
  if (nZ.ne.nZO) then
    print(" Vertical Layers not the same between Ensembles and Observations ....")
    exit
  else
    mae = new((/nT,nZ/),"float")
    do iz = 0, nZ-1
      mae(:,iz)  = abs((1./nM)*dim_sum_n(varM(:,:,iz),0) - varO(:,iz))
    end do
  end if
  return(mae)
end    ;MAE

;;
function ens_spread(varM)
;varM(ens,time,level)
begin
  ndim = dimsizes(varM)
  nM   = ndim(0)
  nT   = ndim(1)
  nZ   = ndim(2)
  esprd = new((/nT,nZ/),"float")
  
  do iz = 0, nZ-1
  do im = 0, nM-1
    sd2eval  = (varM(im,:,iz) - dim_avg_n(varM(:,:,iz),0))^2.
    if (im.eq.0) then
       sd2      = sd2eval*0.
    end if
    sd2      = sd2 + sd2eval
  end do
  esprd(:,iz)  = abs((1./nM)*sd2)
  end do
  return(esprd)

end ;ens_spread

;;

function file_out(mae,mse,sprd,hhl,fname)
begin
;output netcdf file 
 mae!0 = "icycle"
 mae!1 = "time"
 mae!2 = "level"

 mse!0 = "icycle"
 mse!1 = "time"
 mse!2 = "level"

 sprd!0 = "icycle"
 sprd!1 = "time"
 sprd!2 = "level"
 
 system("rm "+ fname)
 fout = addfile(fname,"c")
 fout->MAE = mae
 fout->MSE = mse
 fout->ESPRD = sprd
 fout->hhl = hhl
 
 return(fout)
end
