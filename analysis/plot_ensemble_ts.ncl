;======================================================
; Plot time-series of spatial averages at differnt levels 
; for ensemble members, PM and ensemble average 
; There are two approaches to make PM run:
; 1) Independent single run   (set pmID=-1)
; 2) Nens + 1 Open Loop run and select 1 memeber as PM run   (0<pmID<Nens+1)
; The spatial averaging is defined by the extents
; COSMO and ParFlow files are read for one time step less (last file = first file (next cycle))
; CLM files are read for all times (because it does not print initial file)
; Usage: ncl plot_ensemble_ts.ncl ind_aM=3 var_id=3 

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

begin

;------------------------------------------------------------------------------
;USER SETTINGS
;------------------------------------------------------------------------------

 path        = "../" ;Path of terrsysmp grouped NC files
 assimMode   = (/"WCDA_cos","WCDA_clm","WCDA_pfl","OL"/)
 varnames    = (/"txx_cos", "qvx_cos", "tso_clm","swx_pfl", "qrn_cos"/)
 varstrings  = (/"T~B~a~N~ (K)" , "QV (g/kg)","Ts (K)"," S~B~w~N~ (-)", "Rain (mm)"/)
 scales      = (/1, 1000., 1, 1, 1/)

 pmID        = 9                    ; -1 if single PM run
 ind_aM      = 2                    ;select assimMode 
 ;; var_id      = 3 
 fanomaly    = False                ;plot anomalies 

 icycle_start= 0 
 nmaxcycle   = 90                  ;Number of restarts 

 ixs         = 11                  ;xdomain
 ixe         = 12                   ;xdomain
 iys         = 6                    ;ydomain
 iye         = 7                   ;ydomain
 iz          = (/1,7/)           ;atmosphere z-location
 izz         = (/0,3/)            ;subsurface z-location
 nfreq       = 3                    ;model output frequency, hrs?
 pfreq       = 3                    ;plot frequency, hrs?

 num_lev     = dimsizes(izz)        ;dimsizes(iz),dimsizes(izz),1

 nstat       = 2                    ;number of ensemble statistics

 pltyp           = "png"           
 ;pltyp@wkWidth   = 1024*2           ;Always needs to be square
 ;pltyp@wkHeight  = 1024*2

;------------------------------------------------------------------------------
;USER SETTINGS END, Do not change below
;------------------------------------------------------------------------------
 ncycle    = nmaxcycle - icycle_start + 1 
 scale     = scales(var_id)
 varname   = varnames(var_id)
 varstring = varstrings(var_id)
 
 sfx       = assimMode(ind_aM) + "/NC/rundart" 
 if (pmID.eq.-1) then
   sfx_pm    = "PM/../"
   sfx_pm    = "PM_run/perfectModel"
   sfx_pm    = "OL/NC/rundart"
 else
   sfx_pm    = sfx   
 end if

 
 do icycle = icycle_start, nmaxcycle -1          ;Big Loop

   print(" Day " + icycle)
   fname    = systemfunc("ls " + path + sfx + sprinti("%0.2i",icycle+1) +"/tsmp_instance*")
   nens     = dimsizes(fname)
 ;
   if (pmID.eq.-1) then
     fname_pm = path + sfx_pm + sprinti("%0.2i",icycle+1)     ; perfect model
     fname_pm = path + sfx_pm + sprinti("%0.2i",icycle+1) + "/tsmp_instance_9"
     tsmpF_pm = addfile(fname_pm + ".nc","r")
   else
     fname_pm = fname(pmID) 
     tsmpF_pm = addfile(fname_pm + ".nc","r")
   end if

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
     if (nf.eq.0 .and. icycle.eq.icycle_start) then
       tsmpF0    = addfile(fname(nf)+".nc","r")
       tim_cos   = tsmpF->tim_cos
       hhl       = tsmpF0->zxx_cos(iz,iys,ixs) -140.
       ;print("Height of COSMO at " + hhl)
       nt_cos    = dimsizes(tim_cos) -1  ;last file = first file( next cycle)
       data_cos  = new((/nens+nstat,num_lev,nt_cos*ncycle/), "float")
       time_cos  = new(nt_cos*ncycle,"integer")
       ;
       tim_clm   = tsmpF->tim_clm
       nt_clm    = dimsizes(tim_clm)
       data_clm  = new((/nens+nstat,num_lev,nt_clm*ncycle/), "float")
       time_clm  = new(nt_clm*ncycle,"integer")
       ;
       tim_pfl   = tsmpF->tim_pfl
       nt_pfl    = dimsizes(tim_pfl)-1 ;last file = first file( next cycle)
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
       xt = it + nt_var*(icycle - icycle_start)
       time_var(xt) = it*nfreq + nt_var*icycle*nfreq
       ;tempvar = scale*(tsmpF->$(varname)$)
       if (strpSuffix.eq."cos") then
         if (varname.eq."qrn_cos") then
            data_var(nf,:,xt)             = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,iys:iye,ixs:ixe),1),0)
            data_var(nens+nstat-1,:,xt)   = dim_avg_n(dim_avg_n(tsmpF_pm->$(varname)$(it,iys:iye,ixs:ixe),1),0)
            removeaccu = False
            if (removeaccu) then
            if (it.eq.0 .and. icycle.eq.icycle_start) then
             ndim               = dimsizes(tsmpF->$(varname)$(it,:,:))
             oldrain            = new((/nens,ndim(0),ndim(1)/),"float")
             nowrain            = new((/nens,ndim(0),ndim(1)/),"float")
             oldrain_pm         = new((/nens,ndim(0),ndim(1)/),"float")
             nowrain_pm         = new((/nens,ndim(0),ndim(1)/),"float")

             oldrain(nf,:,:)    = tsmpF->$(varname)$(it,:,:)
             oldrain_pm(nf,:,:) = tsmpF_pm->$(varname)$(it,:,:)
             data_var(nf,:,xt)             = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,iys:iye,ixs:ixe),1),0)
             data_var(nens+nstat-1,:,xt)   = dim_avg_n(dim_avg_n(tsmpF_pm->$(varname)$(it,iys:iye,ixs:ixe),1),0)
            else
             nowrain(nf,:,:) = tsmpF->$(varname)$(it,:,:) 
             nowrain_pm(nf,:,:) = tsmpF_pm->$(varname)$(it,:,:) 
             data_var(nf,:,xt)             = dim_avg_n(dim_avg_n(nowrain(nf,iys:iye,ixs:ixe)-0.*oldrain(nf,iys:iye,ixs:ixe),1),0)
             data_var(nens+nstat-1,:,xt)   = dim_avg_n(dim_avg_n(nowrain_pm(nf,iys:iye,ixs:ixe)-0.*oldrain_pm(nf,iys:iye,ixs:ixe),1),0)
             oldrain    = nowrain
             oldrain_pm = nowrain_pm 
            end if
            end if   ;removeaccu
         else
         data_var(nf,:,xt)             = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,iz,iys:iye,ixs:ixe),2),1)
         data_var(nens+nstat-1,:,xt)   = dim_avg_n(dim_avg_n(tsmpF_pm->$(varname)$(it,iz,iys:iye,ixs:ixe),2),1)
         end if
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
           data_var(nens+nstat-1,0,xt) = dim_avg_n(dim_avg_n(tsmpF_pm->$(varname)$(it,iys:iye,ixs:ixe),1),0)
         else
           data_var(nf,:,xt)           = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,izz,iys:iye,ixs:ixe),2),1)
           data_var(nens+nstat-1,:,xt) = dim_avg_n(dim_avg_n(tsmpF_pm->$(varname)$(it,izz,iys:iye,ixs:ixe),2),1)
         end if
       else if (strpSuffix.eq."pfl") then
         data_var(nf,:,xt)           = dim_avg_n(dim_avg_n(tsmpF->$(varname)$(it,izz,iys:iye,ixs:ixe),2),1)
         data_var(nens+nstat-1,:,xt) = dim_avg_n(dim_avg_n(tsmpF_pm->$(varname)$(it,izz,iys:iye,ixs:ixe),2),1)
       end if
       end if
       end if
     end do                             ;Local Time Loop
     delete(tsmpF)

   end do                               ;Ensemble loop

 end do                                 ;Big Loop 

;
;--------------------------------------------------------------------------- 
;Add ensemble statistics here
;---------------------------------------------------------------------------

 do ip = 0, num_lev-1
   data_var(nens+nstat-2,ip,:) = dim_avg_n(data_var(0:nt_var-1,ip,:),0)
 end do

 skk = pfreq/nfreq
 ind_assim = ispan(0, nt_var*ncycle-1, skk) ;
 if (fanomaly) then
   do kf = 0, nens+nstat-3
     data_var(kf,:,:) = data_var(kf,:,:) - data_var(nens+nstat-1,:,:)
   end do
   data_var(nens+nstat-2,:,:) = data_var(nens+nstat-2,:,:) - data_var(nens+nstat-1,:,:)
   data_var(nens+nstat-1,:,:) = 0.
 end if


;---------------------------------------------------------------------------
;Plot at assimilation interval only
;---------------------------------------------------------------------------

 fncps   = "~F21~"
 fncps_no = 21
 fncps_hgt = 0.032

 plot = new(num_lev,"graphic")

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
 res@tmXBTickSpacingF                    = 10.
 res@tmLabelAutoStride                   = True

 ;ti Resources
 ;------------------------
 res@tiXAxisFontHeightF                  = fncps_hgt
 res@tiYAxisFontHeightF                  = fncps_hgt
 res@tiXAxisString                      = "Time (Days)"
 res@tiYAxisString                      = varstring ;"~F33~q~F21~~B~v~N~ (K)"

 ;vp Resources
 ;------------------------
 res@vpYF                                = 0.1
 res@vpWidthF                            = 0.9
 res@vpHeightF                           = 0.4

 ;xy Resources
 ;------------------------
 res@xyLineColors                       = colorL ;"grey"
 res@xyLineThicknessF                   = 4.
 res@xyMarkLineMode                     = "Lines"
   
 ;tr Resources
 ;------------------------
 ;res@trXMaxF = 312.

 do ip = 0, num_lev-1
   y_data             = scale*(data_var(:,ip,ind_assim))
   x_data             = time_var(ind_assim)/ 24.0

   res@gsnRightString = hgt_mod@longname + " :" + sprintf("%4.0f",hgt_mod(ip)) + hgt_mod@units
   if (ip.eq.1) then
    res@tiYAxisString = ""
   end if
   plot(ip)           = gsn_csm_xy(wks,x_data, y_data,res)
   delete([/x_data, y_data/])
 end do

 panelres = True
 panelres@gsnFrame = False
; if (ndim_clm.eq.3) then
;   gsn_panel(wks,plot,(/1,1/),panelres)
; else
   gsn_panel(wks,plot,(/2,1/),panelres)
; end if

 legend = create "Legend" legendClass wks 
    "vpXF" : 0.65 
    "vpYF" : 0.7 
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
