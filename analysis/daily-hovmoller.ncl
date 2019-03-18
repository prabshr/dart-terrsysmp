;======================================================
; Plot daily time-scale hovmoller diagram for processed variables
; COSMO and ParFlow files are read for one time step less (last file = first file (next cycle))
; CLM files are read for all times (because it does not print initial file)

; fpath : Path of the netcdf files
; fname : Name of the netcdf files to be analyzed
; pltyp : x11, ng, pdf etc... 
;
; 14.09.2015 Created
;======================================================
; Prabhakar Shrestha
; E-mail: pshrestha@uni-bonn.de
;======================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "../functions/debugmessage.ncl"

begin

;------------------------------------------------------------------------------
;USER SETTINGS
;------------------------------------------------------------------------------

 path        = "/daten01/z4/database/dart/dartExperiments/" ;Path of terrsysmp grouped NC files
 assimMode   = (/"WCDA_cos","WCDA_clm","WCDA_pfl","OL"/)

 varname     = "pbl_cos" ;"qrn_cos"
 pmID        = 9                    ; -1 if single PM run

 ixs         = 11                 ;xdomain
 ixe         = 12                 ;xdomain
 iys         = 6                  ;ydomain
 iye         = 7                  ;ydomain
 iz          = 1                  ;atmosphere z-location
 izz         = 1                  ;subsurface z-location

 ;
 nMaxCycle = 90           ;default (do not change)
 scycle    = 1            ;scycle>=1 Start day (rundart_scycle)
 ecycle    = 90           ;ecycle<=nMaxCycle, End day (rundart_ecycle)

 pltyp       = "png"           

;------------------------------------------------------------------------------
;USER SETTINGS END, Do not change below
;------------------------------------------------------------------------------
;
;Debug Messages
 print("Usage: ncl plot_ensemble_ts.ncl ind_aM=X var_id=X nmax=X")
 dmsg = debugmessage("ind_aM :", assimMode)
 print(" " + dmsg)
 print("nmax <= 90")
 if (.not.isdefined("ind_aM") .or. .not.isdefined("varname") .or. .not.isdefined("nmax")) then
   exit
 end if
;Debug Messages

 sfx       = assimMode(ind_aM) + "/NC/rundart" 

;------------------------------------------------------------------------------
;Big Loop, ncycle depends on model restarts, where assimilation is done
;------------------------------------------------------------------------------
 ncycle = min((/ecycle-scycle+1,nMaxCycle/))

 do icycle = 0, ncycle -1     ;Big Loop

   ocycle   = icycle + scycle
   ;------------- 

   print(" Day " + ocycle)
   fname    = systemfunc("ls " + path + sfx + sprinti("%0.2i",ocycle) +"/tsmp_instance*")
   nens     = dimsizes(fname)
 ;

   if (pmID.ne.-1 .and. ind_aM.eq.3) then
     em1  = ispan(0,pmID-1,1)
     em2  = ispan(pmID+1,nens-1,1)
     em   = array_append_record (em1, em2, 0)
     nens = nens-1
   else
     em   = ispan(0,nens-1,1)
   end if

   do nf  = 0, nens-1                             ;Ensemble loop
     fname(nf) = path + sfx + sprinti("%0.2i",ocycle) +"/tsmp_instance_" + sprinti("%0.1i",em(nf)) + ".nc"
     print(nf + " " + fname(nf))
     tsmpF  = addfile(fname(nf)+".nc","r")
     if (nf.eq.0 .and. icycle.eq.0) then
       tsmpF0    = addfile(fname(nf)+".nc","r")
       tim_cos   = tsmpF->tim_cos
       nt_cos    = dimsizes(tim_cos) -1  ;last file = first file( next cycle)
       ;
       tim_clm   = tsmpF->tim_clm
       nt_clm    = dimsizes(tim_clm)
       ;
       tim_pfl   = tsmpF->tim_pfl
       nt_pfl    = dimsizes(tim_pfl)-1 ;last file = first file( next cycle)
       ;
       ;-------------------------------------
       ; Check clm or cos or pfl variable
       ;-------------------------------------
       tmpSuffix = tocharacter(varname)
       strpSuffix = tostring(tmpSuffix(4:6))
       data_var  = new((/nens,ncycle/), "float")
       time_var  = new(ncycle,"integer")
       if (strpSuffix.eq."cos") then
         nt_var   = nt_cos
       else if (strpSuffix.eq."clm") then
         nt_var   = nt_clm
       else if (strpSuffix.eq."pfl") then
         nt_var   = nt_pfl
       end if
       end if
       end if
       ;
     end if

    ;------------------------------
    ;Data Extraction
    ;------------------------------

    ;
    ; accum_rain        = (tsmpF->$(varname)$(nt_var-1,iys:iye,ixs:ixe)) - (tsmpF->$(varname)$(0,iys:iye,ixs:ixe)) 
    ;data_var(nf,icycle)   = avg(accum_rain)     ;Spatially averaging
     max_pbl           = dim_max_n((tsmpF->$(varname)$(:,iys:iye,ixs:ixe)),0)
     data_var(nf,icycle)   = avg(max_pbl)     ;Spatially averaging
     
     delete([/tsmpF/])

   end do                               ;Ensemble loop

 end do                                 ;Big Loop 


;---------------------------------------------------------------------------
;Plot at assimilation interval only
;---------------------------------------------------------------------------

 fncps   = "~F21~"
 fncps_no = 21
 fncps_hgt = 0.032

 wks = gsn_open_wks(pltyp,"Figure_"+assimMode(ind_aM)+"_" + varname)
 gsn_define_colormap(wks,"precip4_11lev")


 res                                     = True

 ;gsn Resources
 ;------------------------
 res@gsnDraw                             = False
 res@gsnFrame                            = False
 res@gsnLeftStringFontHeightF            = fncps_hgt
 res@gsnRightStringFontHeightF           = fncps_hgt
 res@gsnMaximize                         = True
 res@gsnLeftString                       = assimMode(ind_aM)
 res@gsnRightString                      = "PBL Height [m]" ;"Daily Rainfall [mm]"

 ;tm Resources
 ;------------------------
 res@tmXBLabelFont                       = fncps_no
 res@tmYLLabelFont                       = fncps_no
 res@tmYLLabelFontHeightF                = fncps_hgt
 res@tmXBLabelFontHeightF                = fncps_hgt
 res@tmYROn                              = False
 res@tmXTOn                              = False
 ;res@tmXBMode                            = "Manual"
 ;res@tmXBTickStartF                      = 0.
 ;res@tmXBTickSpacingF                    = 10.
 res@tmLabelAutoStride                   = True

 ;ti Resources
 ;------------------------
 res@tiXAxisFontHeightF                  = fncps_hgt
 res@tiYAxisFontHeightF                  = fncps_hgt
 res@tiXAxisString                      = "Time (Days)"
 res@tiYAxisString                      = "Ensemble Members" ;varstring ;"~F33~q~F21~~B~v~N~ (K)"

 ;vp Resources
 ;------------------------
 res@vpYF                                = 0.1
 res@vpWidthF                            = 0.9
 res@vpHeightF                           = 0.35

 ;cn Resources
 ;------------------------
 res@cnFillOn                            = True
 res@cnInfoLabelOn                       = False
 res@cnLinesOn                           = False
 res@cnFillMode                          = "RasterFill" 
 ;res@cnLevelSelectionMode                = "ExplicitLevels"
 ;res@cnLevels                            = ispan(2,20,2)*1.0
  
 plot = gsn_csm_contour(wks,data_var,res)

 resp = True
 tp   = (/12,22,40,50,65,78/)
 ep   = (/0 , 47/)
 dum  = new(dimsizes(tp),"graphic")
 do ip = 0, dimsizes(tp)-1 
   dum(ip)  = gsn_add_polyline(wks,plot,(/tp(ip),tp(ip)/),ep,resp)
 end do
 draw(plot)
 frame(wks) 

end
