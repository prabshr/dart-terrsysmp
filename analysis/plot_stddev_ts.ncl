;======================================================
; Plot time-series of spatial averages at differnt levels 
; for ensemble members, PM and ensemble average 
; The spatial averaging is defined by the extents
; COSMO and ParFlow files are read for one time step less (last file = first file (next cycle))
; CLM files are read for all times (because it does not print initial file)
; Usage: ncl plot_stddev_ts.ncl ind_aM=3 var_id=3 

; fpath : Path of the netcdf files
; fname : Name of the netcdf files to be analyzed
; pltyp : x11, png, pdf etc... 
;
; 14.09.2015 Created
;======================================================
; Prabhakar Shrestha
; E-mail: pshrestha@uni-bonn.de
;======================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

;------------------------------------------------------------------------------
;USER SETTINGS
;------------------------------------------------------------------------------

 path        = "../"
 assimMode   = (/"WCDA_cos","WCDA_clm","WCDA_pfl","OL_run"/)
 varnames    = (/"txx_cos", "qvx_cos", "tso_clm","swx_pfl"/)
 varstrings  = (/"~F33~q~F21~~B~v~N~ (K)" , "QV (g/kg)","Ts (K)"," S~B~w~N~ (-)"/)
 scales      = (/1, 1000., 1, 1/)

 ;; ind_aM      = 0                    ;select assimMode 
 ;; var_id      = 3 
 fanomaly    = False                ;plot anomalies 

 ncycle      = 13                   ;Number of restarts 
 ixs         = 10                   ;xdomain
 ixe         = 10                   ;xdomain
 iys         = 6                    ;ydomain
 iye         = 6                   ;ydomain
 iz          = ispan(1,49,1)           ;atmosphere z-location
 izz         = ispan(1,7,1)             ;subsurface z-location
 nfreq       = 3                    ;model output frequency, hrs?
 pfreq       = 3                    ;plot frequency, hrs?

 nstat       = 2                    ;number of ensemble statistics

 pltyp           = "x11"           
 ;pltyp@wkWidth   = 1024*2           ;Always needs to be square
 ;pltyp@wkHeight  = 1024*2

;------------------------------------------------------------------------------
;USER SETTINGS END, Do not change below
;------------------------------------------------------------------------------
 scale     = scales(var_id)
 varname   = varnames(var_id)
 varstring = varstrings(var_id)
 
 sfx       = assimMode(ind_aM) + "/rundart" 
 sfx_pm    = "PM_run/perfectModel"

 do icycle = 0, ncycle -1          ;Big Loop

   fname    = systemfunc("ls " + path + sfx + sprinti("%0.2i",icycle+1) +"/tsmp_instance*")
   nens     = dimsizes(fname)
 ;
   do nf  = 0, nens-1                                 ;Ensemble loop
     tsmpF  = addfile(fname(nf)+".nc","r")
     if (nf.eq.0 .and. icycle.eq.0) then
       tsmpF0    = addfile(fname(nf)+".nc","r")
       tim_cos   = tsmpF->tim_cos
       hhl       = tsmpF0->zxx_cos(iz,iys,ixs) -140.
       ;print("Height of COSMO at " + hhl)
       nt_cos    = dimsizes(tim_cos) -1  ;last file = first file( next cycle)
       num_lev     = dimsizes(iz) 
       data_cos  = new((/nens+nstat,num_lev,nt_cos*ncycle/), "float")
       time_cos  = new(nt_cos*ncycle,"integer")
       ;
       tim_clm   = tsmpF->tim_clm
       nt_clm    = dimsizes(tim_clm)
       num_lev     = dimsizes(izz) 
       data_clm  = new((/nens+nstat,num_lev,nt_clm*ncycle/), "float")
       time_clm  = new(nt_clm*ncycle,"integer")
       ;
       tim_pfl   = tsmpF->tim_pfl
       nt_pfl    = dimsizes(tim_pfl)-1 ;last file = first file( next cycle)
       num_lev     = dimsizes(izz) 
       data_pfl  = new((/nens+nstat,num_lev,nt_pfl*ncycle/), "double")
       time_pfl  = new(nt_pfl*ncycle,"integer")
       ;
       ;-------------------------------------
       ; Check clm or cos or pfl variable
       ;-------------------------------------
       tmpSuffix = tocharacter(varname)
       strpSuffix = tostring(tmpSuffix(4:6))
       if (strpSuffix.eq."cos") then
         nt_var   = nt_cos
         time_var = time_cos
         data_var = data_cos
         hgt_mod  = hhl
         hgt_mod@longname = "Height"
         hgt_mod@units     = " m"
       else if (strpSuffix.eq."clm") then
         nt_var   = nt_clm
         time_var = time_clm
         data_var = data_clm
         hgt_mod  = izz
         hgt_mod@longname = "Model Level"
         hgt_mod@units     = " "
       else if (strpSuffix.eq."pfl") then
         hgt_mod  = izz
         nt_var   = nt_pfl
         time_var = time_pfl
         data_var = data_pfl
         hgt_mod@longname = "Model Level"
         hgt_mod@units     = " "
       end if
       end if
       end if
       ;
     end if

    ;------------------------------
    ;Data Extraction
    ;------------------------------

     do it = 0, nt_var-1                        ;Local Time Loop
       xt = it + nt_var*icycle
       time_var(xt) = it*nfreq + nt_var*icycle*nfreq
       ;tempvar = scale*(tsmpF->$(varname)$)
       if (strpSuffix.eq."cos") then
         data_var(nf,:,xt)             = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,iz,iys:iye,ixs:ixe),2),1)
       else if (strpSuffix.eq."clm") then
         if (it.eq.0) then
           ndim_clm = dimsizes(dimsizes(tsmpF->$(varname)$))
         end if
        
         ;------------------------------
         ;Check for 2d or 3d clm data
         ;------------------------------
         if (ndim_clm.eq.3) then  
           temp = tsmpF->$(varname)$(it,iys:iye,ixs:ixe)
           data_var(nf,0,xt)           = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,iys:iye,ixs:ixe),1),0)
         else
           data_var(nf,:,xt)           = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,izz,iys:iye,ixs:ixe),2),1)
         end if
       else if (strpSuffix.eq."pfl") then
         data_var(nf,:,xt)           = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,izz,iys:iye,ixs:ixe),2),1)
       end if
       end if
       end if
     end do                             ;Local Time Loop
     delete(tsmpF)

   end do                               ;Ensemble loop

 end do                                 ;Big Loop 

;

;---------------------------------------------------------------------------
;Plot at assimilation interval only
;---------------------------------------------------------------------------

 fncps   = "~F21~"
 fncps_no = 21
 fncps_hgt = 0.032

 wks = gsn_open_wks(pltyp,"Figure_"+assimMode(ind_aM)+"_" + varname)
 

 res                                     = True

 ;gsn Resources
 ;------------------------
 res@gsnDraw                             = False
 res@gsnFrame                            = False
 res@gsnLeftStringFontHeightF            = fncps_hgt
 res@gsnRightStringFontHeightF            = fncps_hgt
 res@gsnMaximize                         = True
 if (fanomaly) then
   res@gsnLeftString                    = assimMode(ind_aM) + " - PM"
 else
   res@gsnLeftString                    = assimMode(ind_aM)
 end if
 res@gsnRightString                     = varstring ;"~F33~q~F21~~B~v~N~ (K)"



 ;tm Resources
 ;------------------------
 res@tmXBLabelFont                       = fncps_no
 res@tmYLLabelFont                       = fncps_no
 res@tmYLLabelFontHeightF                = fncps_hgt
 res@tmXBLabelFontHeightF                = fncps_hgt
 res@tmYROn                              = False
 res@tmXTOn                              = False
 res@tmXBMode                            = "Manual"
 res@tmXBTickStartF                      = 0.
 res@tmXBTickSpacingF                    = 24.
 res@tmLabelAutoStride                   = True

 ;ti Resources
 ;------------------------
 res@tiXAxisFontHeightF                  = fncps_hgt
 res@tiYAxisFontHeightF                  = fncps_hgt
 res@tiXAxisString                      = "Time (Hours)"
 res@tiYAxisString                       = "Height (m)"
 ;vp Resources
 ;------------------------
 res@vpYF                                = 0.9
 res@vpWidthF                            = 0.8
 res@vpHeightF                           = 0.5

 ;cn Resources
 ;------------------------
 res@cnFillOn                          = True
 res@cnInfoLabelOn                     = False
 res@cnLinesOn                         = False
 res@cnFillMode                        = "RasterFill"

 ;res@trXMaxF = 48 
 data_plot      = dim_stddev_n(data_var,0)
 data_plot!0    = "height"
 data_plot!1    = "time"
 data_plot&height = hgt_mod 

 data_plot(:,0) = data_plot@_FillValue

 plot           = gsn_csm_contour(wks,data_plot,res)


 draw(plot)
 frame(wks) 

end
