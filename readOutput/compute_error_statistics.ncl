; Reads the processed outputs from ensemble runs and perfect model run
; Computes spatially averaged vertical profile of states at different time steps ...
; ... which depends on file output frequency for both runs.
; The states and the extent of spatial averaging can be specified.
; Computes MSE(time,level)  and Spread/Error(time,level) based on PM runs 
; CLM outputs will not have initial model output data, so one time step less
; Generates two netcdf outputs
; Prabhakar Shrestha
;=======================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "error_statistics.ncl"

begin

;------------------------------------------------------------------------------
;USER SETTINGS
;------------------------------------------------------------------------------
 path      = "../"
 assimMode = (/"WCDA_cos","WCDA_clm","WCDA_pfl","OL_run"/)
; ind_aM    = 3 ; Select the assimMode

 print(" ind_aM : " + assimMode)
 print("")
 print(" varname :" + "theta qvx_cos tso_clm swx_pfl")

; varname   = "thetaV"
; varname    = "theta" 
; varname   = "qvx_cos"
; varname   = "tso_clm"  
; varname   = "shf_clm"
; varname   = "swx_pfl"

;Extents for spatial averaging (take the entire domain)
;-2*nbdl for COSMO, but entire domain for clm and parflow, readclm=1 runs

 ixs = 0; 12 ;0
 iys = 0 ;7 ;0 
 ixe = 23 ;12 ;23
 iye = 13 ;7 ;13
;
;check statistics for observed location only : i-11, j-4
; ixs = 9 
; iys = 2 
; ixe = 13 
; iye = 6
;

; nz        = 10; 40; 10       ;do not use 10 for cosmo,domain extent in z, use 10 for LSM
 ncycle    = 13           ;Number of Restart Runs

;------------------------------------------------------------------------------
;USER SETTINGS END, DO NOT CHANGE BELOW
;------------------------------------------------------------------------------

 ;Perfect Model run
; sfx_pm    = "PM/CLUMA2_1.2.0MCT_clm-cos-pfl_idealRTD_perfectModel"
 sfx_pm    = "PM_run/perfectModel"
 ;Ensemble runs
 sfx       = assimMode(ind_aM) + "/rundart"

;------------------------------------------------------------------------------
;Big Loop, ncycle depends on model restarts, where assimilation is done
;------------------------------------------------------------------------------
 do icycle = 0, ncycle -1
 
   ;-------------
   ;Ensemble runs
   ;-------------
   fname    = systemfunc("ls " + path + sfx + sprinti("%0.2i",icycle+1) +"/tsmp_instance*")
   nens     = dimsizes(fname)

   do nf  = 0, nens-1                                  ;Ensemble Loop
     tsmpF  = addfile(fname(nf)+".nc","r")
     if (nf.eq.0 .and. icycle.eq.0) then
       tempV   = tsmpF->txx_cos
       hhl     = tsmpF->zxx_cos(0:nz-1,iys,ixs) -140.
       ndim    = dimsizes(tempV)
       if (varname.eq."tso_clm") then
         ntime = ndim(0)-1
       else
         ntime = ndim(0)
       end if
       var_ens  = new((/nens,ntime,nz/),"float")      ;(/nens,ntime,nz/)
       mae      = new((/ncycle,ntime,nz/),"float")
       mse      = new((/ncycle,ntime,nz/),"float")
       sprd     = new((/ncycle,ntime,nz/),"float")
       statevar = new((/ncycle,ntime,nz/),"float")
       stateobs = new((/ncycle,ntime,nz/),"float")
     end if

     if (varname.eq."thetaV") then
       Tin    = tsmpF->txx_cos(:,0:nz-1,iys:iye,ixs:ixe) ;K
       QVin   = tsmpF->qvx_cos(:,0:nz-1,iys:iye,ixs:ixe) ;kg/kg
       Pin    = tsmpF->pxx_cos(:,0:nz-1,iys:iye,ixs:ixe) ;Pascal
       ;
       temp_var  = toTHETAV(Tin, QVin, Pin)              ;K
     else if (varname.eq."theta") then
       Tin    = tsmpF->txx_cos(:,0:nz-1,iys:iye,ixs:ixe) ;K
       Pin    = tsmpF->pxx_cos(:,0:nz-1,iys:iye,ixs:ixe) ;Pascal
       ;
       temp_var  = toTHETA(Tin, Pin)              ;K
     else 
       temp_var = tsmpF->$(varname)$(:,0:nz-1,iys:iye,ixs:ixe)
       if (varname.eq."qvx_cos") then
          temp_var = temp_var*1000. ;g/kg
       else
          delete(hhl)
          hhl      = (/ 0.01, 0.035, 0.075, 0.135, 0.235, 0.40, 0.65, 1.05, 1.65, 2.5/)
       end if 
     
     end if
     end if
     ;--------------------------------------
     ;Spatial Averaging for vertical profile
     ;--------------------------------------

     var_ens(nf,:,:) = tofloat(dim_avg_n(dim_avg_n(temp_var,3),2)) 
     
   end do                                                        ;Ensemble Loop

   ;------------- 
   ;Perfect Model
   ;-------------
   fname_pm = path + sfx_pm + sprinti("%0.2i",icycle+1)  
   tsmpF_pm = addfile(fname_pm + ".nc","r")
   
   var_obs = new((/ntime,nz/),"float")                    ;;(/ntime,nz/)
 
   if (varname.eq."thetaV") then
     Tin    = tsmpF_pm->txx_cos(:,0:nz-1,iys:iye,ixs:ixe)   ;K
     QVin   = tsmpF_pm->qvx_cos(:,0:nz-1,iys:iye,ixs:ixe)   ;kg/kg
     Pin    = tsmpF_pm->pxx_cos(:,0:nz-1,iys:iye,ixs:ixe)   ;Pascal
     temp_var = toTHETAV(Tin, QVin, Pin)                    ;K
   else if (varname.eq."theta") then
     Tin    = tsmpF_pm->txx_cos(:,0:nz-1,iys:iye,ixs:ixe)   ;K
     QVin   = tsmpF_pm->qvx_cos(:,0:nz-1,iys:iye,ixs:ixe)   ;kg/kg
     Pin    = tsmpF_pm->pxx_cos(:,0:nz-1,iys:iye,ixs:ixe)   ;Pascal
     temp_var = toTHETA(Tin, Pin)
   else
     temp_var = tsmpF_pm->$(varname)$(:,0:nz-1,iys:iye,ixs:ixe)
     if (varname.eq."qvx_cos") then
       temp_var = temp_var*1000.   ;g/kg
     end if
   end if
   end if
   ;--------------------------------------
   ;Spatial Averaging for vertical profile
   ;--------------------------------------
   var_obs  = tofloat(dim_avg_n(dim_avg_n(temp_var,3),2))

   ;------------------------
   ;Compute the statistics
   ;------------------------
   mae(icycle,:,:)      = MAE(var_ens,var_obs)              ;Mean Absoulute Error
   sprd(icycle,:,:)     = ens_spread(var_ens)               ;Ensemble Spread
   mse(icycle,:,:)      = mae(icycle,:,:)*mae(icycle,:,:)   ;Mean Square Error
   statevar(icycle,:,:) = dim_avg_n(var_ens,0)              ;Ensemble Average
   stateobs(icycle,:,:) = var_obs                           ;Observation

 end do

;------------------------------------------------------------------------------
;First netcdf file output
;------------------------------------------------------------------------------

 filedebug = assimMode(ind_aM) + "_" + varname + ".nc"
 if (fileexists(filedebug)) then
   system("rm " + filedebug)
 end if
 fout = addfile(filedebug,"c")
 fout->ens = statevar
 fout->obs = stateobs
 fout->hhl = hhl

;------------------------------------------------------------------------------
;Second netcdf file output
;------------------------------------------------------------------------------

 foutname = "statistics_"+assimMode(ind_aM)+"_" + varname+".nc"
 if (fileexists(foutname)) then
   system("rm " + foutname)
 end if
 tout = file_out(mae, mse, sprd, hhl, foutname)  

end
