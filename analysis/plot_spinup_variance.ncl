;======================================================
; Plot time-series of spatial averages at differnt levels 
; for ensemble members, PM and ensemble average 
; The spatial averaging is defined by the extents
; COSMO and ParFlow files are read for one time step less (last file = first file (next cycle))
; CLM files are read for all times (because it does not print initial file)
; Usage: ncl plot_spinup_variance.ncl pmID=0 sID=0 fvar=0

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
 varnames    = (/"txx_cos", "qvx_cos", "tso_clm","shf_clm","lhf_clm","swx_pfl"/)
 varstrings  = (/"~F33~q~F21~~B~v~N~ (K)" , "QV (g/kg)","Ts (K)","SHF (Wm~S~-2~N~)","LHF (Wm~S~-2~N~)"," S~B~w~N~ (-)"/)
 scales      = (/1, 1000., 1, 1, 1, 1/)

 ;sID        = 5 
 ;pmID       = 1
 nstat       = 2
 nfreq       = 1
 fanomaly    = False                ;plot anomalies 

 ixs         = 10; 0                   ;xdomain
 ixe         = 10;23                   ;xdomain
 iys         = 6;0                    ;ydomain
 iye         = 6;13                   ;ydomain
 izz         = (/0,6/)            ;subsurface z-location
 nfreq       = 1                    ;model output frequency, hrs?
 pfreq       = 1                    ;plot frequency, hrs?
 ndim_clm    = 0

 pltyp           = "x11"           
 ;pltyp@wkWidth   = 1024*2           ;Always needs to be square
 ;pltyp@wkHeight  = 1024*2

;------------------------------------------------------------------------------
;USER SETTINGS END, Do not change below
;------------------------------------------------------------------------------
 varname  = varnames(sID)
 varstring = varstrings(sID)
 scale     = scales(sID)
 num_lev   = dimsizes(izz)

 fname    = systemfunc("ls " + path +"/tsmp_instance*")
 nens     = dimsizes(fname)
 ;
 ;-----------------
 ;Specify Colors
 ;-----------------
  colorL    = new(nens+nstat,"string")
  do ic       = 0, nens-1
    colorL(ic) = "grey" ;+ sprinti("%0.2i", ic+10)
  end do
  colorL(nens+nstat-2) = "red"
  colorL(nens+nstat-1) = "blue"

   do nf  = 0, nens-1                                 ;Ensemble loop
     tsmpF  = addfile(fname(nf)+".nc","r")
     if (nf.eq.0 ) then
       tsmpF0    = addfile(fname(nf)+".nc","r")
       ;
       tim_clm   = tsmpF->tim_clm
       nt_clm    = dimsizes(tim_clm)
       data_clm  = new((/nens+nstat,num_lev,nt_clm/), "float")
       time_clm  = new(nt_clm,"integer")
       ;
       tim_pfl   = tsmpF->tim_pfl
       nt_pfl    = dimsizes(tim_pfl)
       data_pfl  = new((/nens+nstat,num_lev,nt_pfl/), "double")
       time_pfl  = new(nt_pfl,"integer")
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
       xt = it 
       time_var(xt) = it*nfreq 
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
         data_var(nens+nstat-1,:,xt) = 0. 
       end if
       end if
       end if
     end do                             ;Local Time Loop
     delete(tsmpF)

   end do                               ;Ensemble loop

;
;---------------------------------------------------------------------------
;Add ensemble statistics here
;---------------------------------------------------------------------------

 do ip = 0, num_lev-1
   data_var(nens+nstat-2,ip,:) = dim_avg_n(data_var(0:nens-1,ip,:),0)
   data_var(nens+nstat-1,ip,:) = data_var(pmID,ip,:)
 end do


;
;---------------------------------------------------------------------------
;Plot spread 
;---------------------------------------------------------------------------

 fncps   = "~F21~"
 fncps_no = 21
 fncps_hgt = 0.032

 plot = new(num_lev,"graphic")

 wks = gsn_open_wks(pltyp,"Figure_" + varname)
 

 res                                     = True

 ;gsn Resources
 ;------------------------
 res@gsnDraw                             = False
 res@gsnFrame                            = False
 res@gsnLeftStringFontHeightF            = fncps_hgt
 res@gsnRightStringFontHeightF            = fncps_hgt
 res@gsnMaximize                         = True

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
 res@tiXAxisString                      = "Days"
 res@tiYAxisString                      = varstring ;"~F33~q~F21~~B~v~N~ (K)"

 ;vp Resources
 ;------------------------
 res@vpWidthF                            = 0.99
 res@vpHeightF                           = 0.4

 ;xy Resources
 ;------------------------
 res@xyLineColors                       = colorL ;"grey"
 res@xyLineThicknessF                   = 4.
 res@xyMarkLineMode                     = "Lines"
   
 ;tr Resources
 ;------------------------
 res@trXMaxF = 100.

 do ip = 0, num_lev-1
   if (fvar .eq. 0) then
     y_data             = (scale*(data_var(:,ip,:))) 
   else
     y_data             = dim_variance_n(scale*(data_var(:,ip,:)),0)
   end if
   x_data             = time_var

   if (ndim_clm.eq.3) then
     res@gsnRightString = " Surface Flux"
   else
     res@gsnRightString = hgt_mod@longname + " :" + sprintf("%4.0f",hgt_mod(ip)) + hgt_mod@units
   end if
   if (ip.eq.1) then
    ;res@tiYAxisString = ""
   end if
   plot(ip)           = gsn_csm_xy(wks,x_data, y_data,res)
   delete([/x_data, y_data/])
 end do

 panelres = True
 panelres@gsnFrame = False
 if (ndim_clm.eq.3) then
   gsn_panel(wks,plot,(/1,1/),panelres)
   YFleg = 0.5
 else
   gsn_panel(wks,plot,(/2,1/),panelres)
   YFleg = 0.75
 end if

 legend = create "Legend" legendClass wks 
    "vpXF" : 0.65 
    "vpYF" : YFleg 
    "vpWidthF" : 0.2 
    "vpHeightF" : 0.1 
    "lgPerimOn" : False 
    "lgItemCount" : 3 
    "lgLabelFontHeightF" : 0.02 ;fncps_hgt 
    "lgDashIndexes"  : (/1,1,1/)
    "lgLineThicknesses" : (/4,4,4/)
    "lgLineLabelStrings" : (/"", "", ""/) 
    "lgAutoManage" : "False"
    "lgLabelsOn" : True 
    "lgLabelStrings" : (/"Ensemble Mean", "Ensemble", "Perfect Model"/)
    "lgLineColors" : (/"red","grey","blue"/) 
  end create 
  draw(legend) 
  frame(wks) 

end
